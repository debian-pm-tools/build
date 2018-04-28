#!/bin/bash

LIST=$1
if ! [ -z $2 ]; then
	ARCH=$2
else
	ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)
fi

BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"
CONTAINER="debian-pm/build:$ARCH"

if [ -z $LIST ]; then
	echo "Please supply a package list as argument"
	exit 0
fi

PREFIX="/build/"

function run_docker_root() {
	docker run --rm -v $BUILD_ROOT:$PREFIX $@
}

function run_docker_user() {
        docker run --rm -u "$(id -u)" -v $BUILD_ROOT:$PREFIX $@
}


# Check if container exists, if not build it
if [ "$(docker images -q $CONTAINER 2>/dev/null)" == "" ]; then
	docker build -t $CONTAINER docker/$ARCH
fi

run_docker_root $CONTAINER "apt update"
run_docker_root $CONTAINER "apt -y full-upgrade"
run_docker_user $CONTAINER $PREFIX/packages.sh $LIST
run_docker_root $CONTAINER $PREFIX/build-native.sh $LIST
