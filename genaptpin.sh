#!/usr/bin/env bash
apt-cache showsrc $@ | grep Binary | sed 's/Binary://g;s/,//g' | tr " " "\n" | sort | uniq | xargs
