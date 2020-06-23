name: "warc-crawler-stdout"

includes:
  - resource: true
    file: "/crawler-default.yaml"
    override: false

  - resource: false
    file: "/data/install/crawler-conf.yaml"
    override: true

spouts:
  - id: "spout"
    className: "com.digitalpebble.stormcrawler.warc.WARCSpout"
    parallelism: 1
    constructorArgs:
      - "/data/install/input/"
      - "*.{paths,txt}"

bolts:
  - id: "status"
    className: "com.digitalpebble.stormcrawler.persistence.StdOutStatusUpdater"
    parallelism: 1
  - id: "ssbolt"
    className: "com.digitalpebble.stormcrawler.indexing.DummyIndexer"
    parallelism: 1

streams:
  - from: "spout"
    to: "ssbolt"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "spout"
    to: "status"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"

  - from: "ssbolt"
    to: "status"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"
