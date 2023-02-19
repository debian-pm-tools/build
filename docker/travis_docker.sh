#!/usr/bin/env bash

CONTAINER_ROOT="$(dirname "$(readlink -f "${0}")")"
GITLAB_USERNAME="jbbgameich"
ARCH="${ARCH:-amd64}"
DISTRIBUTION="${DISTRIBUTION:-testing}"
DOCKERFILE="package_builder.Dockerfile"

cd $CONTAINER_ROOT

build() {
	case "$ARCH" in
		amd64)
			CONTAINER_BASE="docker.io/debian:${DISTRIBUTION}"
			;;
		i386)
			CONTAINER_BASE="docker.io/i386/debian:${DISTRIBUTION}"
			;;
		armhf)
			CONTAINER_BASE="docker.io/arm32v7/debian:${DISTRIBUTION}"
			;;
		arm64)
			CONTAINER_BASE="docker.io/arm64v8/debian:${DISTRIBUTION}"
			;;
		*)
			CONTAINER_BASE="docker.io/debian:${DISTRIBUTION}"
			;;
	esac

	sed -i "/FROM/c\FROM ${CONTAINER_BASE}" "${DOCKERFILE}"

	podman build -t "registry.gitlab.com/debian-pm/tools/build:${DISTRIBUTION}-${ARCH}" . -f "${DOCKERFILE}"
}

push() {
	podman push "registry.gitlab.com/debian-pm/tools/build:${DISTRIBUTION}-${ARCH}"
}

$1
