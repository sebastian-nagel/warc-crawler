name: "warc-crawler-dev-null"

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
  - id: "devnull"
    className: "org.apache.storm.perf.bolt.DevNullBolt"
    parallelism: 1


streams:
  - from: "spout"
    to: "devnull"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "spout"
    to: "devnull"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"
