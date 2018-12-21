#!/usr/bin/env bash
CONTAINER_ROOT="$(dirname "$(readlink -f "${0}")")"
DOCKER_USERNAME="jbbgameich"
cd $CONTAINER_ROOT

build() {
	case "$ARCH" in
		amd64)
			CONTAINER_BASE="jbbgameich/minideb:testing-amd64"
			;;
		i386)
			CONTAINER_BASE="jbbgameich/minideb:testing-i386"
			;;
		armhf)
			CONTAINER_BASE="jbbgameich/minideb:testing-armhf"
			;;
		arm64)
			CONTAINER_BASE="jbbgameich/minideb:testing-arm64"
			;;
		*)
			CONTAINER_BASE="jbbgameich/minideb:testing-amd64"
			;;
	esac

	sed -i "/FROM/c\FROM ${CONTAINER_BASE}" Dockerfile
	sudo docker build -t "$DOCKER_USERNAME/build:latest-${ARCH}" .
}

push() {
	echo "$DOCKER_PASSWORD" | sudo docker login -u "$DOCKER_USERNAME" --password-stdin

	sudo docker push "$DOCKER_USERNAME/build:latest-${ARCH}"
}

$1
