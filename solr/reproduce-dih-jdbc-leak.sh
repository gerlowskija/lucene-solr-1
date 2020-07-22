#!/bin/bash -x

set -eu

ZOO_CFG_LOCATION="server/solr/zoo.cfg"
SOLR_XML_LOCATION="server/solr/solr.xml"
COLLECTION_CONFIG_LOCATION="example/example-DIH/solr/db"
NODE1_HOME="example/cloud-dih/node1/solr"
NODE2_HOME="example/cloud-dih/node2/solr"
CAUSE_DIH_IO_ERROR="true"

bin/solr stop -all || true
ant server

rm -rf example/cloud-dih/
mkdir -p $NODE1_HOME
mkdir -p $NODE2_HOME

cp $ZOO_CFG_LOCATION $NODE1_HOME
cp $SOLR_XML_LOCATION $NODE1_HOME
cp $SOLR_XML_LOCATION $NODE2_HOME

bin/solr start -cloud -p 8983 -s $NODE1_HOME -DcauseDIHIOerror=$CAUSE_DIH_IO_ERROR
bin/solr start -cloud -p 7574 -s $NODE2_HOME -z localhost:9983 -DcauseDIHIOerror=$CAUSE_DIH_IO_ERROR

bin/solr create -c db -s 2 -d $COLLECTION_CONFIG_LOCATION
sleep 3

# Kick off DIH run
curl -ilk -X GET "http://localhost:8983/solr/db/dataimport?core=db&commit=true&name=dataimport&clean=true&wt=json&command=full-import&entity=item&verbose=true"
