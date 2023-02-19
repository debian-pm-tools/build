#!/usr/bin/env bash
set -e

for dist in bullseye testing; do
	for arch in armhf arm64 amd64; do
		export DISTRIBUTION=$dist
		export ARCH=$arch
		./travis_docker.sh build
		./travis_docker.sh push
	done
done
