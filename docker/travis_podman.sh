#!/usr/bin/env bash
CONTAINER_ROOT="$(dirname "$(readlink -f "${0}")")"
DOCKER_USERNAME="jbbgameich"
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
			CONTAINER_BASE="debian:testing"
			;;
	esac

	sed -i "/FROM/c\FROM ${CONTAINER_BASE}" Dockerfile
	sudo podman build -t "$DOCKER_USERNAME/build:latest-${ARCH}" .
}

push() {
	sudo podman push \
		--creds="$DOCKER_USERNAME" \
		"localhost/$DOCKER_USERNAME/build:latest-${ARCH}" \
		"docker://docker.io/$DOCKER_USERNAME/build:latest-${ARCH}"
}

$1
