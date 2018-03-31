#!/bin/bash

if ! [ -z "$2" ]; then
	ARCH="$2"
else
	ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)
fi

error() {
	echo $1
	exit 1
}

if [ -e "$1".list ]; then
	export list="$1".list
else
	echo "Package list $1 does not exist!"
	exit 1
fi

for name in $(cat ${list}); do
	echo
	echo "I: Building $name"
	echo

	cd packages/$name/

	sudo apt build-dep . || error "E: Could not install the build dependencies"

	dpkg-buildpackage --host-arch $ARCH || error "E: Building the package failed"

	cd ../../
done
