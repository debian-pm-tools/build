#!/usr/bin/env bash

CONTAINER_ROOT="$(dirname "$(readlink -f "${0}")")"
GITLAB_USERNAME="jbbgameich"
BASE_IMAGE="registry.gitlab.com/debian-pm/tools/build/debian"
DIST="${DIST:-testing}"
ARCH="${ARCH:-amd64}"

cd $CONTAINER_ROOT

build() {
	CONTAINER_BASE="${BASE_IMAGE}:${DIST}-${ARCH}"

	sed -i "/FROM/c\FROM ${CONTAINER_BASE}" Dockerfile
	sudo docker build -t "registry.gitlab.com/debian-pm/tools/build:latest-${ARCH}" .
}

push() {
	echo "$GITLAB_TOKEN" | sudo docker login -u "$GITLAB_USERNAME" --password-stdin registry.gitlab.com

	if [ $DIST = "testing" ]; then
		sudo docker push "registry.gitlab.com/debian-pm/tools/build:latest-${ARCH}"
	else
		sudo docker push "registry.gitlab.com/debian-pm/tools/build:${DIST}-${ARCH}"
	fi
}

$1
