FROM storm:2.8.8

RUN apt-get update -qq && \
	apt-get install -yq --no-install-recommends \
		curl \
		jq \
		less \
		vim

#
# Storm crawler / WARC crawler
#
ENV CRAWLER_VERSION=3.6.0
RUN mkdir /warc-crawler && \
    chmod -R a+rx /warc-crawler

# add the WARC crawler uber-jar
COPY target/warc-crawler-$CRAWLER_VERSION.jar /warc-crawler/warc-crawler.jar

# and topology configuration files
COPY topology/       /warc-crawler/topology/

RUN chown -R "storm:storm" /warc-crawler/

USER storm
WORKDIR /warc-crawler/

