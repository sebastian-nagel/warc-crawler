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
storm jar target/warc-crawler-1.18-SNAPSHOT.jar  org.apache.storm.flux.Flux --local topology/warc-crawler-stdout/warc-crawler-stdout.flux --sleep 86400000
```

This will run the topology in local mode.

Replace `--local` by `--remote` to run the topology in distributed mode:
``` sh
storm jar target/warc-crawler-1.18-SNAPSHOT.jar  org.apache.storm.flux.Flux --remote topology/warc-crawler-stdout/warc-crawler-stdout.flux
```

It is best to run the topology in distributed mode to benefit from the Storm UI and logging. In that case, the topology runs continuously, as intended.

Note that in local mode, Flux uses a default TTL for the topology of 60 secs. The command above runs the topology for 24 hours (`24*60*60*1000` milliseconds). In distributed mode, the topology is run forever (until it is killed).


### Run a Java Topology

A Java topology class using the storm command:

``` sh
storm jar target/warc-crawler-1.18-SNAPSHOT.jar org.commoncrawl.stormcrawler.CrawlTopology -conf topology/warc-crawler-stdout/warc-crawler-stdout-conf.yaml -local
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
- initialize Eleasticsearch indices by [ES_IndexInit.sh](topology/warc-crawler-index-elasticsearch/ES_IndexInit.sh)

See also the documentation of [StormCrawler's Elasticsearch module](https://github.com/DigitalPebble/storm-crawler/tree/master/external/elasticsearch).



## Run Topology from Docker Container

See the [news-crawl Dockerfile](https://github.com/commoncrawl/news-crawl/blob/master/Dockerfile) and the [instructions to run it](https://github.com/commoncrawl/news-crawl#run-crawl-from-docker-container) as an example.



