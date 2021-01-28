package org.apache.solr.handler.admin;

import com.google.common.collect.Maps;
import org.apache.solr.SolrTestCaseJ4;
import org.apache.solr.api.Api;
import org.apache.solr.api.ApiBag;
import org.apache.solr.common.params.CollectionAdminParams;
import org.apache.solr.common.params.CollectionParams;
import org.apache.solr.common.params.CommonParams;
import org.apache.solr.common.params.SolrParams;
import org.apache.solr.common.util.CommandOperation;
import org.apache.solr.common.util.ContentStreamBase;
import org.apache.solr.handler.CollectionsAPI;
import org.apache.solr.request.LocalSolrQueryRequest;
import org.apache.solr.request.SolrQueryRequest;
import org.apache.solr.response.SolrQueryResponse;
import org.junit.Before;
import org.junit.Test;
import org.mockito.ArgumentCaptor;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.apache.solr.common.params.CommonParams.ACTION;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

/**
 * Unit tests for the API mappings found in {@link org.apache.solr.handler.CollectionsAPI}.
 *
 * This test bears many similarities to {@link TestCollectionAPIs} which appears to test the mappings indirectly by
 * checking message sent to the ZK overseer (which is similar, but not identical to the v1 param list).  If there's no
 * particular benefit to testing the mappings in this way (there very well may be), then we should combine these two
 * test classes at some point in the future using the simpler approach here.
 *
 * Note that the V2 requests made by these tests are not necessarily semantically valid.  They shouldn't be taken as
 * examples. In several instances, mutually exclusive JSON parameters are provided.  This is done to exercise conversion
 * of all parameters, even if particular combinations are never expected in the same request.
 */
public class V2CollectionsAPIMappingTest extends SolrTestCaseJ4 {

    private ApiBag apiBag;

    private ArgumentCaptor<SolrQueryRequest> queryRequestCaptor;
    private CollectionsHandler mockCollectionsHandler;

    @Before
    public void setupApiBag() throws Exception {
        mockCollectionsHandler = mock(CollectionsHandler.class);
        queryRequestCaptor = ArgumentCaptor.forClass(SolrQueryRequest.class);

        apiBag = new ApiBag(false);
        final CollectionsAPI collectionsAPI = new CollectionsAPI(mockCollectionsHandler);
        apiBag.registerObject(collectionsAPI);
        apiBag.registerObject(collectionsAPI.collectionsCommands);
    }

    @Test
    public void testCreateCollectionAllProperties() throws Exception {
        final SolrParams v1Params = captureConvertedV1Params("/collections", "POST",
                "{'create': {" +
                        "'name': 'techproducts', " +
                        "'config':'_default', " +
                        "'router': {'name': 'composite', 'field': 'routeField'}, " +
                        "'shards': 'customShardName,anotherCustomShardName', " +
                        "'replicationFactor': 3," +
                        "'nrtReplicas': 1, " +
                        "'tlogReplicas': 1, " +
                        "'pullReplicas': 1, " +
                        "'maxShardsPerNode': 5, " +
                        "'nodeSet': ['localhost:8983_solr', 'localhost:7574_solr']," +
                        "'shuffleNodes': true," +
                        "'properties': {'foo': 'bar', 'foo2': 'bar2'}, " +
                        "'async': 'requestTrackingId', " +
                        "'waitForFinalState': false, " +
                        "'perReplicaState': false," +
                        "'numShards': 1}}");

        assertEquals(CollectionParams.CollectionAction.CREATE.lowerName, v1Params.get(ACTION));
        assertEquals("techproducts", v1Params.get(CommonParams.NAME));
        assertEquals("_default", v1Params.get(CollectionAdminParams.COLL_CONF));
        assertEquals("composite", v1Params.get("router.name"));
        assertEquals("routeField", v1Params.get("router.field"));
        assertEquals("customShardName,anotherCustomShardName", v1Params.get("shards"));
        assertEquals(3, v1Params.getPrimitiveInt("replicationFactor"));
        assertEquals(1, v1Params.getPrimitiveInt("nrtReplicas"));
        assertEquals(1, v1Params.getPrimitiveInt("tlogReplicas"));
        assertEquals(1, v1Params.getPrimitiveInt("pullReplicas"));
        assertEquals(5, v1Params.getPrimitiveInt("maxShardsPerNode"));
        assertEquals("localhost:8983_solr,localhost:7574_solr", v1Params.get("createNodeSet"));
        assertEquals(true, v1Params.getPrimitiveBool("createNodeSet.shuffle"));
        assertEquals("bar", v1Params.get("property.foo"));
        assertEquals("bar2", v1Params.get("property.foo2"));
        assertEquals("requestTrackingId", v1Params.get("async"));
        assertEquals(false, v1Params.getPrimitiveBool("waitForFinalState"));
        assertEquals(false, v1Params.getPrimitiveBool("perReplicaState"));
        assertEquals(1, v1Params.getPrimitiveInt(CollectionAdminParams.NUM_SHARDS));
    }

    @Test
    public void testCreateAliasAllProperties() throws Exception {
        final SolrParams v1Params = captureConvertedV1Params("/collections", "POST",
                "{'create-alias': {" +
                        "'name': 'aliasName', " +
                        "'collections': ['techproducts1', 'techproducts2'], " +
                        "'tz': 'someTimeZone', " +
                        "'async': 'requestTrackingId', " +
                        "'router': {" +
                        "    'name': 'time', " +
                        "    'field': 'date_dt', " +
                        "    'interval': '+1HOUR', " +
                        "     'maxFutureMs': 3600, " +
                        "     'preemptiveCreateMath': 'somePreemptiveCreateMathString', " +
                        "     'autoDeleteAge': 'someAutoDeleteAgeExpression', " +
                        "     'maxCardinality': 36, " +
                        "     'mustMatch': 'someRegex', " +
                        "}, " +
                        "'create-collection': {" +
                        "     'numShards': 1, " +
                        "     'properties': {'foo': 'bar', 'foo2': 'bar2'}, " +
                        "     'replicationFactor': 3 " +
                        "}" +
                        "}}");

        assertEquals(CollectionParams.CollectionAction.CREATEALIAS.lowerName, v1Params.get(ACTION));
        assertEquals("aliasName", v1Params.get(CommonParams.NAME));
        assertEquals("techproducts1,techproducts2", v1Params.get("collections"));
        assertEquals("someTimeZone", v1Params.get("tz"));
        assertEquals("requestTrackingId", v1Params.get("async"));
        assertEquals("time", v1Params.get("router.name"));
        assertEquals("date_dt", v1Params.get("router.field"));
        assertEquals("+1HOUR", v1Params.get("router.interval"));
        assertEquals(3600, v1Params.getPrimitiveInt("router.maxFutureMs"));
        assertEquals("somePreemptiveCreateMathString", v1Params.get("router.preemptiveCreateMath"));
        assertEquals("someAutoDeleteAgeExpression", v1Params.get("router.autoDeleteAge"));
        assertEquals(36, v1Params.getPrimitiveInt("router.maxCardinality"));
        assertEquals("someRegex", v1Params.get("router.mustMatch"));
        assertEquals(1, v1Params.getPrimitiveInt("create-collection.numShards"));
        assertEquals("bar", v1Params.get("create-collection.property.foo"));
        assertEquals("bar2", v1Params.get("create-collection.property.foo2"));
        assertEquals(3, v1Params.getPrimitiveInt("create-collection.replicationFactor"));
    }

    @Test
    public void testDeleteAliasAllProperties() throws Exception {
        final SolrParams v1Params = captureConvertedV1Params("/collections", "POST",
                "{'delete-alias': {" +
                        "'name': 'aliasName', " +
                        "'async': 'requestTrackingId'" +
                        "}}");

        assertEquals(CollectionParams.CollectionAction.DELETEALIAS.lowerName, v1Params.get(ACTION));
        assertEquals("aliasName", v1Params.get(CommonParams.NAME));
        assertEquals("requestTrackingId", v1Params.get("async"));
    }

    @Test
    public void testSetAliasAllProperties() throws Exception {
        final SolrParams v1Params = captureConvertedV1Params("/collections", "POST",
                "{'set-alias-property': {" +
                        "'name': 'aliasName', " +
                        "'async': 'requestTrackingId', " +
                        "'properties': {'foo':'bar', 'foo2':'bar2'}" +
                        "}}");

        assertEquals(CollectionParams.CollectionAction.ALIASPROP.lowerName, v1Params.get(ACTION));
        assertEquals("aliasName", v1Params.get(CommonParams.NAME));
        assertEquals("requestTrackingId", v1Params.get("async"));
        assertEquals("bar", v1Params.get("property.foo"));
        assertEquals("bar2", v1Params.get("property.foo2"));
    }

    @Test
    public void testBackupAllProperties() throws Exception {
        final SolrParams v1Params = captureConvertedV1Params("/collections", "POST",
                "{'backup-collection': {" +
                        "'name': 'backupName', " +
                        "'collection': 'collectionName', " +
                        "'location': '/some/location/uri', " +
                        "'repository': 'someRepository', " +
                        "'followAliases': true, " +
                        "'indexBackup': 'copy-files', " +
                        "'commitName': 'someSnapshotName', " +
                        "'async': 'requestTrackingId' " +
                        "}}");

        assertEquals(CollectionParams.CollectionAction.BACKUP.lowerName, v1Params.get(ACTION));
        assertEquals("backupName", v1Params.get(CommonParams.NAME));
        assertEquals("collectionName", v1Params.get("collection"));
        assertEquals("/some/location/uri", v1Params.get("location"));
        assertEquals("someRepository", v1Params.get("repository"));
        assertEquals(true, v1Params.getPrimitiveBool("followAliases"));
        assertEquals("copy-files", v1Params.get("indexBackup"));
        assertEquals("someSnapshotName", v1Params.get("commitName"));
        assertEquals("requestTrackingId", v1Params.get("async"));
    }

    @Test
    public void testRestoreAllProperties() throws Exception {
        final SolrParams v1Params = captureConvertedV1Params("/collections", "POST",
                "{'restore-collection': {" +
                        "'name': 'backupName', " +
                        "'collection': 'collectionName', " +
                        "'location': '/some/location/uri', " +
                        "'repository': 'someRepository', " +
                        "'async': 'requestTrackingId', " +
                        "'create-collection': {" +
                        "     'numShards': 1, " +
                        "     'properties': {'foo': 'bar', 'foo2': 'bar2'}, " +
                        "     'replicationFactor': 3 " +
                        "}" +
                        "}}");

        assertEquals(CollectionParams.CollectionAction.RESTORE.lowerName, v1Params.get(ACTION));
        assertEquals("backupName", v1Params.get(CommonParams.NAME));
        assertEquals("collectionName", v1Params.get("collection"));
        assertEquals("/some/location/uri", v1Params.get("location"));
        assertEquals("someRepository", v1Params.get("repository"));
        assertEquals("requestTrackingId", v1Params.get("async"));
        // NOTE: Unlike other v2 APIs that have a nested object for collection-creation params, restore's v1 equivalent
        // for these properties doesn't have a "create-collection." prefix.
        assertEquals(1, v1Params.getPrimitiveInt("numShards"));
        assertEquals("bar", v1Params.get("property.foo"));
        assertEquals("bar2", v1Params.get("property.foo2"));
        assertEquals(3, v1Params.getPrimitiveInt("replicationFactor"));
    }

    private SolrParams captureConvertedV1Params(String path, String method, String v2RequestBody) throws Exception {
        final HashMap<String, String> parts = new HashMap<>();
        final Api api = apiBag.lookup(path, method, parts);
        final SolrQueryResponse rsp = new SolrQueryResponse();
        final LocalSolrQueryRequest req = new LocalSolrQueryRequest(null, Maps.newHashMap()) {
            @Override
            public List<CommandOperation> getCommands(boolean validateInput) {
                if (v2RequestBody == null) return Collections.emptyList();
                return ApiBag.getCommandOperations(new ContentStreamBase.StringStream(v2RequestBody), api.getCommandSchema(), true);
            }

            @Override
            public Map<String, String> getPathTemplateValues() {
                return parts;
            }

            @Override
            public String getHttpMethod() {
                return method;
            }
        };


        api.call(req, rsp);
        verify(mockCollectionsHandler).handleRequestBody(queryRequestCaptor.capture(), any());
        return queryRequestCaptor.getValue().getParams();
    }
}
