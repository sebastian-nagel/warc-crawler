/**
 * Licensed to DigitalPebble Ltd under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * DigitalPebble licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.commoncrawl.stormcrawler;

import org.apache.storm.topology.TopologyBuilder;
import org.apache.storm.tuple.Fields;

import com.digitalpebble.stormcrawler.ConfigurableTopology;
import com.digitalpebble.stormcrawler.Constants;
import com.digitalpebble.stormcrawler.bolt.JSoupParserBolt;
import com.digitalpebble.stormcrawler.indexing.StdOutIndexer;
import com.digitalpebble.stormcrawler.persistence.StdOutStatusUpdater;
import com.digitalpebble.stormcrawler.tika.ParserBolt;
import com.digitalpebble.stormcrawler.tika.RedirectionBolt;
import com.digitalpebble.stormcrawler.warc.WARCSpout;

/**
 * Read WARC files and emit page captures as tuples into the topology
 */
public class CrawlTopology extends ConfigurableTopology {

    public static void main(String[] args) throws Exception {
        ConfigurableTopology.start(new CrawlTopology(), args);
    }

    @Override
    protected int run(String[] args) {
        TopologyBuilder builder = new TopologyBuilder();

        builder.setSpout("spout", new WARCSpout("/data/input/", "*.{paths,txt}"));

        builder.setBolt("jsoup", new JSoupParserBolt())
                .localOrShuffleGrouping("spout");

        builder.setBolt("shunt", new RedirectionBolt())
                .localOrShuffleGrouping("jsoup");

        builder.setBolt("tika", new ParserBolt())
                .localOrShuffleGrouping("shunt", "tika");

        builder.setBolt("index", new StdOutIndexer())
                .localOrShuffleGrouping("shunt").localOrShuffleGrouping("tika");

        Fields furl = new Fields("url");

        builder.setBolt("status", new StdOutStatusUpdater()) //
                .fieldsGrouping("spout", Constants.StatusStreamName, furl)
                .fieldsGrouping("jsoup", Constants.StatusStreamName, furl)
                .fieldsGrouping("tika", Constants.StatusStreamName, furl)
                .fieldsGrouping("index", Constants.StatusStreamName, furl);

        return submit("crawl", conf, builder);
    }
}
