/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.solr.handler.component;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicLong;

import org.apache.solr.common.params.CommonParams;
import org.apache.solr.common.params.ModifiableSolrParams;
import org.apache.solr.common.util.SuppressForbidden;
import org.apache.solr.request.SolrQueryRequest;

public class TrackComponent extends SearchComponent {
  public static final String COMPONENT_NAME = "track";
  /**
   * A counter to ensure that no RID is equal, even if they fall in the same millisecond
   */
  private static final AtomicLong ridCounter = new AtomicLong();

  @Override
  public void prepare(ResponseBuilder rb) throws IOException {
      doDebugTrack(rb);
  }

  @Override
  public void process(ResponseBuilder rb) throws IOException {

  }

  @Override
  public String getDescription() {
    return "Tracking information for each end-user request";
  }

  public static String getRequestId(SolrQueryRequest req) {
    String rid = req.getParams().get(CommonParams.REQUEST_ID);
    if(rid == null || "".equals(rid)) {
      rid = generateRid(req);
      ModifiableSolrParams params = new ModifiableSolrParams(req.getParams());
      params.add(CommonParams.REQUEST_ID, rid);//add rid to the request so that shards see it
      req.setParams(params);
    }
    return rid;
  }

  private void doDebugTrack(ResponseBuilder rb) {
    String rid = getRequestId(rb.req);
    rb.addDebug(rid, "track", CommonParams.REQUEST_ID);//to see it in the response
    rb.rsp.addToLog(CommonParams.REQUEST_ID, rid); //to see it in the logs of the landing core
  }

  @SuppressForbidden(reason = "Need currentTimeMillis, only used for naming")
  private static String generateRid(SolrQueryRequest req) {
    String hostName = req.getCore().getCoreContainer().getHostName();
    return hostName + "-" + req.getCore().getName() + "-" + System.currentTimeMillis() + "-" + ridCounter.getAndIncrement();
  }
}
