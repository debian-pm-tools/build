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
	podman build --storage-driver vfs -t "registry.gitlab.com/debian-pm/tools/build:latest-${ARCH}" .
}

push() {
	echo $GITLAB_TOKEN | podman login registry.gitlab.com --password-stdin -u $GITLAB_USERNAME

	podman push --storage-driver vfs \
		"registry.gitlab.com/debian-pm/tools/build:latest-${ARCH}" \
		"docker://registry.gitlab.com/debian-pm/tools/build:latest-${ARCH}"

       if [ $DIST = "testing" ]; then
		podman push --storage-driver vfs \
		        "registry.gitlab.com/debian-pm/tools/build:latest-${ARCH}" \
			"docker://registry.gitlab.com/debian-pm/tools/build:latest-${ARCH}"
       else
		podman push --storage-driver vfs \
			"registry.gitlab.com/debian-pm/tools/build:${DIST}-${ARCH}" \
			"docker://registry.gitlab.com/debian-pm/tools/build:${DIST}-${ARCH}"

       fi

}

$1
