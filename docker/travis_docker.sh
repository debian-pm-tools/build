#!/usr/bin/env bash

CONTAINER_ROOT="$(dirname "$(readlink -f "${0}")")"
GITLAB_USERNAME="jbbgameich"
ARCH="${ARCH:-amd64}"

cd $CONTAINER_ROOT

build() {
	case "$ARCH" in
		amd64)
			CONTAINER_BASE="debian:testing"
			;;
		i386)
			CONTAINER_BASE="i386/debian:testing"
			;;
		armhf)
			CONTAINER_BASE="arm32v7/debian:testing"
			;;
		arm64)
			CONTAINER_BASE="arm64v8/debian:testing"
			;;
		*)
			CONTAINER_BASE="d"
			;;
	esac

	sed -i "/FROM/c\FROM ${CONTAINER_BASE}" Dockerfile

	sudo docker build -t "registry.gitlab.com/debian-pm/tools/build:testing-${ARCH}" .
}

push() {
	echo "$GITLAB_TOKEN" | sudo docker login -u "$GITLAB_USERNAME" --password-stdin registry.gitlab.com

	sudo docker push "registry.gitlab.com/debian-pm/tools/build:testing-${ARCH}"
}

$1
