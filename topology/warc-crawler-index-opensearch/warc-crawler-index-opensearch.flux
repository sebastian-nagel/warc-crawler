name: "warc-crawler-index-opensearch"

# - read WARC files, parse the content and index it
# - uses WARCSpout followed by standard StormCrawler bolts
#   for parsing and indexing

includes:
  - resource: true
    file: "/crawler-default.yaml"
    override: false

  - resource: false
    file: "topology/warc-crawler-index-opensearch/warc-crawler-index-opensearch-conf.yaml"
    override: true

  - resource: false
    file: "topology/warc-crawler-index-opensearch/opensearch-conf.yaml"
    override: true

spouts:
  - id: "spout"
    className: "org.apache.stormcrawler.warc.WARCSpout"
    parallelism: 1
    constructorArgs:
      - "/data/input/"
      - "*.{paths,txt}"

bolts:
  - id: "jsoup"
    className: "org.apache.stormcrawler.bolt.JSoupParserBolt"
    parallelism: 2
  - id: "shunt"
    className: "org.apache.stormcrawler.tika.RedirectionBolt"
    parallelism: 2
  - id: "tika"
    className: "org.apache.stormcrawler.tika.ParserBolt"
    parallelism: 2
  - id: "index"
    className: "org.apache.stormcrawler.opensearch.bolt.IndexerBolt"
    parallelism: 1
  - id: "status"
    className: "org.apache.stormcrawler.opensearch.persistence.StatusUpdaterBolt"
    parallelism: 1
  - id: "status_metrics"
    className: "org.apache.stormcrawler.opensearch.metrics.StatusMetricsBolt"
    parallelism: 1

streams:
  - from: "spout"
    to: "jsoup"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "__system"
    to: "status_metrics"
    grouping:
      type: SHUFFLE
      streamId: "__tick"

  - from: "spout"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "jsoup"
    to: "shunt"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "shunt"
    to: "tika"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "tika"

  - from: "tika"
    to: "index"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "shunt"
    to: "index"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "jsoup"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "tika"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "index"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"
