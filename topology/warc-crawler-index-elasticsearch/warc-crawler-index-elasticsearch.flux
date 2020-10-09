name: "warc-crawler-index-elasticsearch"

# - read WARC files, parse the content and index it
# - uses WARCSpout followed by standard StormCrawler bolts
#   for parsing and indexing

includes:
  - resource: true
    file: "/crawler-default.yaml"
    override: false

  - resource: false
    file: "topology/warc-crawler-index-elasticsearch/warc-crawler-index-elasticsearch-conf.yaml"
    override: true

  - resource: false
    file: "topology/warc-crawler-index-elasticsearch/es-conf.yaml"
    override: true

spouts:
  - id: "spout"
    className: "com.digitalpebble.stormcrawler.warc.WARCSpout"
    parallelism: 1
    constructorArgs:
      - "/data/input/"
      - "*.{paths,txt}"

bolts:
  - id: "parse"
    className: "com.digitalpebble.stormcrawler.bolt.JSoupParserBolt"
    parallelism: 2
  - id: "index"
    className: "com.digitalpebble.stormcrawler.elasticsearch.bolt.IndexerBolt"
    parallelism: 1
  - id: "status"
    className: "com.digitalpebble.stormcrawler.elasticsearch.persistence.StatusUpdaterBolt"
    parallelism: 1
  - id: "status_metrics"
    className: "com.digitalpebble.stormcrawler.elasticsearch.metrics.StatusMetricsBolt"
    parallelism: 1

streams:
  - from: "spout"
    to: "parse"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "spout"
    to: "status_metrics"
    grouping:
      type: SHUFFLE     

  - from: "spout"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "parse"
    to: "index"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "parse"
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
