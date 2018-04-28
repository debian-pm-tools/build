#!/bin/bash

LIST=$1
BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"
APT_CACHE_DIR="$BUILD_ROOT/apt_cache"

if [ -z $LIST ]; then
	echo "Please supply a package list as argument"
	exit 0
fi

if [ ! -d $APT_CACHE_DIR ]; then
	mkdir $APT_CACHE_DIR -p
fi

PREFIX="/build/"
CONTAINER="debian-pm:build"

function run_docker() {
	docker run -v $APT_CACHE_DIR:/var/cache/apt/ -v $BUILD_ROOT:$PREFIX $@
}

# Check if container exists, if not build it
if [ "$(docker images -q $CONTAINER 2>/dev/null)" == "" ]; then
	docker build -t $CONTAINER docker
fi

run_docker $CONTAINER "apt update"
run_docker $CONTAINER "apt -y full-upgrade"
run_docker $CONTAINER $PREFIX/packages.sh $LIST
run_docker $CONTAINER $PREFIX/build-native.sh $LIST
