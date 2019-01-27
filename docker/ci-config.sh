#!/usr/bin/env bash

LIBHYBRIS_PLATFORM="$1"

echo "Adding repository for libhybris platform ${LIBHYBRIS_PLATFORM}"
echo "deb https://repo.kaidan.im/debpm buster ${LIBHYBRIS_PLATFORM}" > \
	/etc/apt/sources.list.d/debian-pm.list

apt update
