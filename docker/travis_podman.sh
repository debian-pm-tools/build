#!/usr/bin/env bash
CONTAINER_ROOT="$(dirname "$(readlink -f "${0}")")"
GITLAB_USERNAME="jbbgameich"
BASE_IMAGE="registry.gitlab.com/debian-pm/tools/build/debian"
cd $CONTAINER_ROOT

build() {
		case "$ARCH" in
				amd64)
						CONTAINER_BASE="${BASE_IMAGE}:testing-amd64"
						;;
				i386)
						CONTAINER_BASE="${BASE_IMAGE}:testing-i386"
						;;
				armhf)
						CONTAINER_BASE="${BASE_IMAGE}:testing-armhf"
						;;
				arm64)
						CONTAINER_BASE="${BASE_IMAGE}:testing-arm64"
						;;
				*)
						CONTAINER_BASE="${BASE_IMAGE}:testing-amd64"
						;;
		esac

	sed -i "/FROM/c\FROM ${CONTAINER_BASE}" Dockerfile
	podman build --storage-driver vfs -t "registry.gitlab.com/debian-pm/tools/build:latest-${ARCH}" .
}

push() {
	echo $GITLAB_TOKEN | podman login registry.gitlab.com --password-stdin -u $GITLAB_USERNAME

	podman push --storage-driver vfs \
		"registry.gitlab.com/debian-pm/tools/build:latest-${ARCH}" \
		"docker://registry.gitlab.com/debian-pm/tools/build:latest-${ARCH}"
}

$1
