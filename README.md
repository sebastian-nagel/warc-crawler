# warc-crawler -- Let StormCrawler “Crawl” WARC Files

See DigitalPebble/storm-crawler#755.

WARNING: development code, not ready for production.


## Build Project

- install Apache Storm
- build StormCrawler (dev snapshot) and deploy it locally
- build this project:
  ``` sh
  mvn clean package
  ```

## Run the Crawler

before submitting the topology using the storm command:

``` sh
storm jar target/warc-crawler-1.0-SNAPSHOT.jar org.commoncrawl.stormcrawler.CrawlTopology -conf crawler-conf.yaml -local
```

This will run the topology in local mode. Simply remove the '-local' to run the topology in distributed mode.

You can also use Flux to do the same:

``` sh
storm jar target/warc-crawler-1.0-SNAPSHOT.jar  org.apache.storm.flux.Flux --local crawler.flux --sleep 86400000
```

Note that in local mode, Flux uses a default TTL for the topology of 60 secs. The command above runs the topology for 24 hours.

It is best to run the topology with `--remote` to benefit from the Storm UI and logging. In that case, the topology runs continuously, as intended.


## Alternative Topologies
