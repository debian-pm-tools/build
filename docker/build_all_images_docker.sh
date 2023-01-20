#!/usr/bin/env bash

for arch in arm64 i386 amd64; do
	export ARCH=$arch
	./travis_podman.sh build
	./travis_podman.sh push
done
