#!/usr/bin/env bash

BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"

PKG_PATH=$1
DEBIAN_GLES_ARCHITECTURES="armel armhf"
NEW_GLES_ARCHITECTURES="armel armhf arm64 i386"

sed -i "s/(arch=${DEBIAN_GLES_ARCHITECTURES})/(arch=${NEW_GLES_ARCHITECTURES})/g" $(find ${BUILD_ROOT}/packages/${PKG_PATH}/debian/ -type f)
sed -i "s/\[${DEBIAN_GLES_ARCHITECTURES}\]/\[${NEW_GLES_ARCHITECTURES}\]/g" $(find ${BUILD_ROOT}/packages/${PKG_PATH}/debian/ -type f)

old_expression=""
for i in ${DEBIAN_GLES_ARCHITECTURES}; do
    old_expression=$(echo "${old_expression} !${i}" | xargs)
done

new_expression=""
for i in ${NEW_GLES_ARCHITECTURES}; do
    new_expression=$(echo "${new_expression} !${i}" | xargs)
done

echo ${old_expression}
echo ${new_expression}

sed -i "s/${old_expression}/${new_expression}/g" $(find ${BUILD_ROOT}/packages/${PKG_PATH}/debian/ -type f)
