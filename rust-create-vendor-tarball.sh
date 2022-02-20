#!/usr/bin/env bash

PKG_PATH="$1"
BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"

if [ -z ${PKG_PATH} ]; then
	echo "Missing package directory path"
	exit 1
fi

source "${BUILD_ROOT}/functions/package-common.sh"

cd "${PACKAGES_ROOT}"/"${PKG_PATH}"

cargo vendor

VENDOR_TAR_NAME="${PACKAGE}"_"${PKG_VERSION}".orig-vendor.tar.xz

echo
echo "Compressing vendor directory to ${VENDOR_TAR_NAME}…"
tar cfJ "${VENDOR_TAR_NAME}" vendor/
cp "${VENDOR_TAR_NAME}" ../
mv "${VENDOR_TAR_NAME}" "${BUILD_ROOT}"/sources/
