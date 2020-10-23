#/bin/bash

docker exec -it solr /opt/solr/bin/solr create -c status  -d /storm-crawler-solr-conf/status/
docker exec -it solr /opt/solr/bin/solr create -c metrics -d /storm-crawler-solr-conf/metrics/
docker exec -it solr /opt/solr/bin/solr create -c docs    -d /storm-crawler-solr-conf/docs/
