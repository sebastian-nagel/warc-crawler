name: "warc-crawler-rewrite-warc"

includes:
  - resource: true
    file: "/crawler-default.yaml"
    override: false

  - resource: false
    file: "/data/install/crawler-conf.yaml"
    override: true

config:
  # use RawLocalFileSystem (instead of ChecksumFileSystem) to avoid that
  # WARC files are truncated if the topology is stopped because of a
  # delayed sync of the default ChecksumFileSystem
  warc: {"fs.file.impl": "org.apache.hadoop.fs.RawLocalFileSystem"}

components:
  - id: "WARCFileNameFormat"
    className: "com.digitalpebble.stormcrawler.warc.WARCFileNameFormat"
    configMethods:
      - name: "withPath"
        args:
          - "/data/warc"
      - name: "withPrefix"
        args:
          - "CC-NEWS"
  - id: "WARCFileRotationPolicy"
    className: "com.digitalpebble.stormcrawler.warc.FileTimeSizeRotationPolicy"
    constructorArgs:
      - 1024
      - MB
    configMethods:
      - name: "setTimeRotationInterval"
        args:
          - 1440
          - MINUTES
  - id: "WARCInfo"
    className: "java.util.LinkedHashMap"
    configMethods:
      - name: "put"
        args:
         - "software"
         - "StormCrawler 1.16 http://stormcrawler.net/"
      - name: "put"
        args:
         - "description"
         - "News crawl for Common Crawl"
      - name: "put"
        args:
         - "http-header-user-agent"
         - "... Please insert your user-agent name"
      - name: "put"
        args:
         - "http-header-from"
         - "..."
      - name: "put"
        args:
         - "operator"
         - "..."
      - name: "put"
        args:
         - "robots"
         - "..."
      - name: "put"
        args:
         - "format"
         - "WARC File Format 1.1"
      - name: "put"
        args:
         - "conformsTo"
         - "https://iipc.github.io/warc-specifications/specifications/warc-format/warc-1.1/"

spouts:
  - id: "spout"
    className: "com.digitalpebble.stormcrawler.warc.WARCSpout"
    parallelism: 1
    constructorArgs:
      - "/data/install/input/"
      - "*.{paths,txt}"

bolts:
  - id: "warc"
    className: "com.digitalpebble.stormcrawler.warc.WARCHdfsBolt"
    parallelism: 1
    configMethods:
      - name: "withFileNameFormat"
        args:
          - ref: "WARCFileNameFormat"
      - name: "withRotationPolicy"
        args:
          - ref: "WARCFileRotationPolicy"
      - name: "withRequestRecords"
      - name: "withHeader"
        args:
          - ref: "WARCInfo"
      - name: "withConfigKey"
        args:
          - "warc"
  - id: "devnull"
    className: "org.apache.storm.perf.bolt.DevNullBolt"
    parallelism: 1
  # - id: "status"
  #   className: "com.digitalpebble.stormcrawler.persistence.StdOutStatusUpdater"
  #   parallelism: 1
  # - id: "ssbolt"
  #   className: "com.digitalpebble.stormcrawler.indexing.DummyIndexer"
  #   parallelism: 1


streams:
  - from: "spout"
    to: "warc"
    grouping:
      type: LOCAL_OR_SHUFFLE

  # - from: "spout"
  #   to: "ssbolt"
  #   grouping:
  #     type: LOCAL_OR_SHUFFLE

  # - from: "spout"
  #   to: "status"
  #   grouping:
  #     type: LOCAL_OR_SHUFFLE
  #     streamId: "status"
  - from: "spout"
    to: "devnull"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"

  # - from: "ssbolt"
  #   to: "status"
  #   grouping:
  #     type: LOCAL_OR_SHUFFLE
  #     streamId: "status"
