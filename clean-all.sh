#!/bin/bash

BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"

# Check if list is supplied as argument
if [ "$#" -lt 1 ]; then
    echo "Required argument: packages list name"
    exit 1
fi

# Set package list from command line argument (if exists)
if [ -e "$1".list ]; then
    export list="$1".list
else
    echo "Package list $1 does not exist!"
    exit 1
fi

for PKG_PATH in $(cat ${list}); do
	source "$BUILD_ROOT/functions/package-common.sh"
	cd $BUILD_ROOT/packages/$PKG_PATH

	echo "Cleaning packages/$PKG_PATH"
	origtargz --clean

	version=$(dpkg-parsechangelog -S Version | sed -e 's/^[0-9]*://')

	if [ -f ../${PACKAGE}_${PKG_VERSION}.orig.tar.* ]; then
		echo "Deleting ../${PACKAGE}_${PKG_VERSION}.orig.tar.*"
		rm ../${PACKAGE}_${PKG_VERSION}.orig.tar.*
	fi

	cd $BUILD_ROOT
done
