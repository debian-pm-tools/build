#!/usr/bin/env bash
set -e

for dist in bookworm testing; do
	for arch in armhf arm64 amd64 i386; do
		bash -c "DISTRIBUTION=$dist ARCH=$arch ./travis_docker.sh build && DISTRIBUTION=$dist ARCH=$arch ./travis_docker.sh push" &
	done
done
