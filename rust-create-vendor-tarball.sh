#!/usr/bin/env bash

PKG_PATH="$1"
BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"

source "${BUILD_ROOT}/functions/package-common.sh"

cd "${PACKAGES_ROOT}"/"${PKG_PATH}"

cargo vendor

VENDOR_TAR_NAME="${PACKAGE}"_"${PKG_VERSION}".orig-vendor.tar.xz

tar cfJ "${VENDOR_TAR_NAME}" vendor/
mv "${VENDOR_TAR_NAME}" "${BUILD_ROOT}"/sources/
