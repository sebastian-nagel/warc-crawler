name: "warc-crawler-dev-null"

# read WARC files but discard all content
# using WARCSpout and DevNullBolt

includes:
  - resource: true
    file: "/crawler-default.yaml"
    override: false

  - resource: false
    file: "topology/warc-crawler-dev-null/warc-crawler-dev-null-conf.yaml"
    override: true

spouts:
  - id: "spout"
    className: "com.digitalpebble.stormcrawler.warc.WARCSpout"
    parallelism: 1
    constructorArgs:
      - "/data/input/"
      - "*.{paths,txt}"

bolts:
  - id: "devnull"
    className: "org.apache.storm.perf.bolt.DevNullBolt"
    parallelism: 4

streams:
  # default stream: content and metadata of successfully fetched pages
  - from: "spout"
    to: "devnull"
    grouping:
      type: LOCAL_OR_SHUFFLE

  # status stream: fetch status and metadata of 404s, redirects, etc.
  - from: "spout"
    to: "devnull"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"
