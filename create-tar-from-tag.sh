#!/bin/bash

BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"

usage() {
	echo "This script creates a new orig tar from a git tag"
	echo "Usage example: ./$0 gst-droid https://github.com/sailfishos/gst-droid 0.20180503.0"
	exit 1
}

error_namenotset() {
	echo "ERROR: The \$NAME and \$EMAIL variables need to be set to create a new changelog entry"
	exit 1
}

# Command line opts
PACKAGE=$1
GIT_REPO=$2
GIT_TAG=$3

[ -z $PACKAGE ] && usage
[ -z $GIT_REPO ] && usage
[ -z $GIT_TAG ] && usage

# Check if packaging is in place
! [ -d $BUILD_ROOT/packages/${PACKAGE} ] &&
	echo "ERROR: packaging doesn't exist. Did you forget to run './packages.sh packagelist'?" &&
	exit 1

# Extract version information
if [ -f $BUILD_ROOT/packages/$PACKAGE/debian/changelog ]; then
    PKG_VERSION=$(dpkg-parsechangelog -SVersion -l $BUILD_ROOT/packages/$PACKAGE/debian/changelog | sed "s/[-].*//")
else
    PKG_VERSION=0
fi

PKG_GIT_VERSION=$(echo $GIT_TAG | sed 's/v//g')

# Check if snapshot does already exists
[ -f $BUILD_ROOT/packages/${PACKAGE}_$PKG_GIT_VERSION.orig.tar.xz ] &&
	echo "ERROR: $BUILD_ROOT/packages/${PACKAGE}_$PKG_VERSION.orig.tar.xz already exists" &&
	exit 1

# Debug output
echo "I: package: $PACKAGE"
echo "I: packaged version: $PKG_VERSION"
echo "I: git repository: $GIT_REPO"
echo "I: git tag: $GIT_TAG"

# Update or clone git repository
if [ -d "$BUILD_ROOT/sources/$PACKAGE" ]; then
	echo "I: fetching from git repository ..."

	git -C "$BUILD_ROOT/sources/$PACKAGE" fetch --tags
else
	git clone --depth 1 $GIT_REPO "$BUILD_ROOT/sources/$PACKAGE" --recursive --tags
fi
git -C "$BUILD_ROOT/sources/$PACKAGE" checkout tags/$GIT_TAG

# Export repository into tar
(
cd "$BUILD_ROOT/sources/$PACKAGE"
bash "$BUILD_ROOT/git-archive-all.sh" \
	--prefix $PACKAGE-$PKG_VERSION/ \
	--format tar -- - | xz >"$BUILD_ROOT/sources/${PACKAGE}_$PKG_GIT_VERSION.orig.tar.xz"
)

# Unpack new tarball
(
	cd $BUILD_ROOT/packages/${PACKAGE}
	origtargz --clean
	origtargz --path $BUILD_ROOT/sources/
)
