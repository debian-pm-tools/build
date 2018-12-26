#!/usr/bin/env bash

BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"
PACKAGES_ROOT="$BUILD_ROOT/packages/"

PACKAGE=$(dpkg-parsechangelog -SSource -l ${PACKAGES_ROOT}/${PKG_PATH}/debian/changelog)

DATE=$(date +%Y%m%d)
PKG_VERSION=$(dpkg-parsechangelog -SVersion -l ${PACKAGES_ROOT}/$PACKAGE/debian/changelog | cut -f1 -d"+" | sed "s/[-].*//" | sed -e 's/^[0-9]*://')

