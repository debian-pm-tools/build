#!/bin/bash

BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"

if [ -e "$BUILD_ROOT/packages.list" ]; then
    export list="$BUILD_ROOT/packages.list"
else
    echo "Package list packages.list does not exist!"
    exit 1
fi

for PKG_PATH in $(cat ${list}); do
	source "$BUILD_ROOT/functions/package-common.sh"
	cd $BUILD_ROOT/packages/$PKG_PATH

	echo "Cleaning packages/$PKG_PATH"
	origtargz --clean
	dh_clean

	version=$(dpkg-parsechangelog -S Version | sed -e 's/^[0-9]*://')

	if [[ -f ../${PACKAGE}_${PKG_VERSION}.orig.tar.* ]]; then
		echo "Deleting ../${PACKAGE}_${PKG_VERSION}.orig.tar.*"
		rm ../${PACKAGE}_${PKG_VERSION}.orig.tar.*
	fi

	cd $BUILD_ROOT
done
