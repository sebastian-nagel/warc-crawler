name: "warc-crawler-stdout"

# read WARC files and write status and indexed fields to stdout
# using WARCSpout, StdOutStatusUpdater and StdOutIndexer

includes:
  - resource: true
    file: "/crawler-default.yaml"
    override: false

  - resource: false
    file: "topology/warc-crawler-stdout/warc-crawler-stdout-conf.yaml"
    override: true

spouts:
  - id: "spout"
    className: "com.digitalpebble.stormcrawler.warc.WARCSpout"
    parallelism: 1
    constructorArgs:
      - "/data/input/"
      - "*.{paths,txt}"

bolts:
  - id: "status"
    className: "com.digitalpebble.stormcrawler.persistence.StdOutStatusUpdater"
    parallelism: 1
  - id: "parse"
    className: "com.digitalpebble.stormcrawler.bolt.JSoupParserBolt"
    parallelism: 2
  - id: "index"
    className: "com.digitalpebble.stormcrawler.indexing.StdOutIndexer"
    parallelism: 1

streams:
  - from: "spout"
    to: "parse"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "spout"
    to: "status"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"

  - from: "parse"
    to: "index"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "parse"
    to: "status"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"

  - from: "index"
    to: "status"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"
