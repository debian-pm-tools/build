#!/usr/bin/env bash

LIBHYBRIS_PLATFORM="$1"

echo "Adding repository for libhybris platform ${LIBHYBRIS_PLATFORM}"
echo "deb [trusted=yes] https://raw.githubusercontent.com/debian-pm-tools/incoming-apt-repo/${LIBHYBRIS_PLATFORM} buster main" > \
	/etc/apt/sources.list.d/${LIBHYBRIS_PLATFORM}.list

apt update
