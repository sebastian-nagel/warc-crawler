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
    className: "org.apache.stormcrawler.warc.WARCSpout"
    parallelism: 1
    constructorArgs:
      - "/data/input/"
      - "*.{paths,txt}"

bolts:
  - id: "status"
    className: "org.apache.stormcrawler.persistence.StdOutStatusUpdater"
    parallelism: 1
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
    className: "org.apache.stormcrawler.indexing.StdOutIndexer"
    parallelism: 1

streams:
  - from: "spout"
    to: "jsoup"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "spout"
    to: "status"
    grouping:
      type: LOCAL_OR_SHUFFLE
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
      type: LOCAL_OR_SHUFFLE
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
      type: LOCAL_OR_SHUFFLE
      streamId: "status"
