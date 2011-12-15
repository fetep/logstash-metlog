#!/bin/sh
java -jar lib/logstash-jna.jar agent -vvv -f config/tagfilter.conf --pluginpath src
