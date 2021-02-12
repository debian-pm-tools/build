#!/usr/bin/env bash

for arch in armhf arm64 i386 amd64; do
	export ARCH=$arch
	./travis_docker.sh build
	./travis_docker.sh push
done
