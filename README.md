# Let StormCrawler “Crawl” WARC Files

WARNING: This project is based on a development version of StormCrawler.

For more information about processing (and creating) WARC archives using StormCrawler, see
- related StormCrawler issues: /DigitalPebble/storm-crawler#755
- StormCrawler's [WARC module README](https://github.com/DigitalPebble/storm-crawler/blob/master/external/warc/README.md)
- StormCrawler's [WARCSpout](https://github.com/DigitalPebble/storm-crawler/blob/master/external/warc/src/main/java/com/digitalpebble/stormcrawler/warc/WARCSpout.java)


## Build the Project

- install Apache Storm 1.2.3 - see [Storm setup](https://storm.apache.org/releases/1.2.3/index.html#setup-and-deploying) or use Docker (instructions below)
- clone and compile [StormCrawler](https://github.com/DigitalPebble/storm-crawler)
  ``` sh
  git clone https://github.com/DigitalPebble/storm-crawler.git
  cd storm-crawler
  mvn clean install
  cd ..
  ```
  Maven will deploy the StormCrawler jars into your local Maven repository.
- build this project:
  ``` sh
  mvn clean package
  ```


## Create List of WARC Files To Process

All topologies expect that WARC files to be processed are listed in text files line by line using
- either a local file system path (ideally absolute, relative paths may not work in distributed mode)
- or a http:// or https:// URL

Text files are expected in the folder `/data/input/`. The input folder is defined in the Flux files. Please change this location at your needs.

### Create Sample Input from Common Crawl

TODO


## Run the Crawler


### Run a Flux Topology

To submit a [Flux](https://storm.apache.org/releases/1.2.3/flux.html) to do the same:

``` sh
storm jar target/warc-crawler-1.18.jar  org.apache.storm.flux.Flux --local topology/warc-crawler-stdout/warc-crawler-stdout.flux --sleep 86400000
```

This will run the topology in local mode.

Replace `--local` by `--remote` to run the topology in distributed mode:
``` sh
storm jar target/warc-crawler-1.18.jar org.apache.storm.flux.Flux --remote topology/warc-crawler-stdout/warc-crawler-stdout.flux
```

It is best to run the topology in distributed mode to benefit from the Storm UI and logging. In that case, the topology runs continuously, as intended.

Note that in local mode, Flux uses a default TTL for the topology of 60 secs. The command above runs the topology for 24 hours (`24*60*60*1000` milliseconds). In distributed mode, the topology is run forever (until it is killed).


### Run a Java Topology

A Java topology class using the storm command:

``` sh
storm jar target/warc-crawler-1.18.jar org.commoncrawl.stormcrawler.CrawlTopology -conf topology/warc-crawler-stdout/warc-crawler-stdout-conf.yaml -local
```
Simply remove the `-local` argument to run the topology in distributed mode.


## Alternative Topologies

Several Flux topologies are provided to test and evaluate crawling of WARC archives. Each Flux file is accompanied by a configuration file which fits the requirements of the topology run on a single host. You need to modify Flux file and configuration if you want to scale up and run the topology on a distributed Storm cluster.

### DevNull Topology

[warc-crawler-dev-null](topology/warc-crawler-dev-null/) runs a single WARCSpout which sends the page captures to [DevNullBolt](https://storm.apache.org/releases/1.2.3/javadocs/org/apache/storm/perf/bolt/DevNullBolt.html) which (you guess it) only ack's and discards each tuple. Useful to measure the performance of the WARCSpout.

### Stdout Topology

[warc-crawler-stdout](topology/warc-crawler-stdout/) reads WARC files, parse the content payload, maps content and metadata fields to index fields and writes fields (shortened) to the log output:
```
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] pagetype      article
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] pageimage     169 chars
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] keywords      Coronavirus
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] keywords      NHS
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] keywords      Politics
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] keywords      Boris Johnson
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] keywords      Matt Hancock
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] keywords      Rishi Sunak
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] keywords      Sunderland
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] capturetime   1601983220000
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] description   114 chars
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] title Coronavirus LIVE updates: Boris Johnson Tory conference ...
2020-10-08 14:30:30.113 STDIO Thread-4-index-executor[2 2] [INFO] publicationdate       2020-10-06T11:05:33Z
```

This topology can be used to test parsers and extractors without the need to setup any indexer backend. The Java topology class ([CrawlTopology](src/main/java/org/commoncrawl/stormcrawler/CrawlTopology.java)) runs an equivalent topology.


### Rewrite WARC files

[warc-crawler-warc-rewrite](topology/warc-crawler-warc-rewrite/) reads WARC files and sends the content to a WARC writer bolt which stores it again in WARC files. Could be extended by additional bolts to filter and/or enrich the WARC records.

### Index into Elasticsearch

[warc-crawler-index-elasticsearch](topology/warc-crawler-index-elasticsearch/) reads WARC files, parses HTML pages, extracts text and metadata and sends documents into Elasticsearch for indexing.

This topology requires that Elasticsearch is running:
- install Elasticsearch (and Kibana) 7.5.0 - also higher versions of 7.x might work
- start Elasticsearch
- initialize Eleasticsearch indices by running [ES_IndexInit.sh](topology/warc-crawler-index-elasticsearch/ES_IndexInit.sh)
- adapt the [es-conf.yaml](topology/warc-crawler-index-elasticsearch/es-conf.yaml) file, so that Elasticsearch is reachable from the Storm workers – the host name `elasticsearch` is used in the [Docker setup](#run-topology-on-docker), change the host name to `localhost` when running in local mode with a local Elasticsearch installation.

See also the documentation of [StormCrawler's Elasticsearch module](https://github.com/DigitalPebble/storm-crawler/tree/master/external/elasticsearch).

### Index into Solr

[warc-crawler-index-solr](topology/warc-crawler-index-solr/) reads WARC files, parses HTML pages, extracts text and metadata and sends documents into Solr for indexing.

As a requirement Solr must be installed and running:
- install [Solr](https://lucene.apache.org/solr/) 8.8.0
- start Solr
- initialize the cores using [StormCrawler's Solr core config](https://github.com/DigitalPebble/storm-crawler/tree/master/external/solr/cores)
  ```
  bin/solr create -c status  -d storm-crawler/external/solr/cores/status/
  bin/solr create -c metrics -d storm-crawler/external/solr/cores/metrics/
  bin/solr create -c docs    -d storm-crawler/external/solr/cores/docs/
  ```
- adapt [solr-conf.yaml](topology/warc-crawler-index-solr/solr-conf.yaml) file, so that Solr is reachable from the Storm workers – the host name `solr` is used in the [Docker setup](#run-topology-on-docker), change the host name to `localhost` when running in local mode with a local Solr installation.

See also the documentation of [StormCrawler's Solr module](https://github.com/DigitalPebble/storm-crawler/tree/master/external/solr).


## Run Topology on Docker

A configuration to run the topologies via [docker-compose](https://docs.docker.com/compose/) is provided. The file [docker-compose.yaml](./docker-compose.yaml) puts every component (Storm Nimbus, Supervisor and UI, but also Elasticsearch and Solr) into its own container. The topology is launched from a separate container which is linked to container of Storm Nimbus.

WARC input is per default read from the folder `warcdata` in the current directory. Another location can be defined by setting the environment variable `WARCINPUT`:
```sh
WARCINPUT=/my/warc/data/path/
export WARCINPUT
```

First we launch all components:

```
docker-compose -f docker-compose.yaml up --build --renew-anon-volumes --remove-orphans
```

Now we can launch the container `storm-crawler`
```
docker-compose run --rm storm-crawler
```

and in the running container our topology:
```
$warc-crawler/> storm jar warc-crawler.jar org.apache.storm.flux.Flux --remote topology/warc-crawler-dev-null/warc-crawler-dev-null.flux
```

Let's check whether topology is running:
```
$warc-crawler/> storm list
Topology_name        Status     Num_tasks  Num_workers  Uptime_secs
-------------------------------------------------------------------
warc-crawler-dev-null ACTIVE    6          1            240
```

Also the [Storm UI on localhost](http://localhost:8080/) is available and will provide metrics about the running topology.

To inspect the worker log files we need to attach to the container running Storm Supervisor
```
docker exec -it storm-supervisor /bin/bash
```
then find the log file and read it:
```
$> ls /logs/workers-artifacts/*/*/worker.log
/logs/workers-artifacts/warc-crawler-dev-null-1-1603368933/6700/worker.log

$> more /logs/workers-artifacts/warc-crawler-dev-null-1-1603368933/6700/worker.log
```


If done we kill the topology
```
$warc-crawler/> storm kill warc-crawler-dev-null -w 10
1636 [main] INFO  o.a.s.c.kill-topology - Killed topology: warc-crawler-dev-null
```
leave the container (`exit`) and shut down all running containers:
```
docker-compose down
```


Of course, the topology could be also launched in a single command:
```
docker-compose run --rm storm-crawler storm jar warc-crawler.jar org.apache.storm.flux.Flux --remote topology/warc-crawler-dev-null/warc-crawler-dev-null.flux
```

#### Run Elasticsearch Topologies on Docker

First, the Elasticsearch indices need to be initialized by running [ES_IndexInit.sh](topology/warc-crawler-index-elasticsearch/ES_IndexInit.sh).

Then the Elasticsearch topology can be launched via
```
docker-compose run --rm storm-crawler storm jar warc-crawler.jar org.apache.storm.flux.Flux \
   --remote topology/warc-crawler-index-elasticsearch/warc-crawler-index-elasticsearch.flux
```

#### Run Solr Topologies on Docker

To create the Solr cores, the "solr" container needs access to [StormCrawler's Solr core config](https://github.com/DigitalPebble/storm-crawler/tree/master/external/solr/cores):
- because Solr will write into the core folders, it's recommended to create a copy first and assign the necessary file permissions:
  ```sh
  cp .../storm-crawler/external/solr/cores /tmp/storm-crawler-solr-conf
  chmod a+rwx -R /tmp/storm-crawler-solr-conf/
  ```
- point the environment variable `STORM_CRAWLER_SOLR_CONF` to this folder:
  ```sh
  STORM_CRAWLER_SOLR_CONF=/tmp/storm-crawler-solr-conf
  export STORM_CRAWLER_SOLR_CONF
  ```
- after all docker-compose services are running, create the Solr cores by
  ```
  docker exec -it solr /opt/solr/bin/solr create -c status  -d /storm-crawler-solr-conf/status/
  docker exec -it solr /opt/solr/bin/solr create -c metrics -d /storm-crawler-solr-conf/metrics/
  docker exec -it solr /opt/solr/bin/solr create -c docs    -d /storm-crawler-solr-conf/docs/
  ```
- finally launch the Solr topology
  ```
  docker-compose run --rm storm-crawler storm jar warc-crawler.jar org.apache.storm.flux.Flux \
     --remote topology/warc-crawler-index-solr/warc-crawler-index-solr.flux
  ```
