#!/bin/bash

BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"
PACKAGES_ROOT="$BUILD_ROOT/packages/"

# Everything important happens in the packages folder
if ! [ -d $PACKAGES_ROOT ]; then
    mkdir $PACKAGES_ROOT
fi

if ! [ -d "$BUILD_ROOT/repo" ]; then
    mkdir -p "$BUILD_ROOT/repo"
fi

if [ -e "$BUILD_ROOT/packages.list".list ]; then
    export list="$BUILD_ROOT/packages.list".list
else
    echo "Package list packages.list does not exist!"
    exit 1
fi

# Perform self-upgrade
echo "I: Running self upgrade"
git -C $BUILD_ROOT fetch origin
git -C $BUILD_ROOT merge origin/master

# Main functions
function init() {
    echo "I: Initializing packages"

    for name in $(cat ${list}); do
        # Print status
        echo -n $name

        if ! [ -d "${PACKAGES_ROOT}/${name}" ]; then
            git clone https://gitlab.com/debian-pm/${name}.git "$PACKAGES_ROOT/${name}" >/dev/null 2>&1
        elif [ -d "${PACKAGES_ROOT}/${name}" ]; then
            git -C "${PACKAGES_ROOT}/${name}" remote set-url origin https://gitlab.com/debian-pm/${name}.git
	fi

        echo " [Done]"
    done

    echo
}

function sync() {
    echo "I: Syncing packages"

    echo "* Updating tarball submodule ..."
    git submodule update --recursive --remote --init --checkout | sed "s/^/* /"

    for name in $(cat ${list}); do
        # Print status
        echo $name

        # Look if folders exist
        if ! [ -d "$PACKAGES_ROOT/$name" ]; then
            echo "WARN: The packages folder is not yet initialized!"
            break
        fi

        echo "* Fetching packaging ..."

        git -C "${PACKAGES_ROOT}/${name}" fetch origin >/dev/null 2>&1
        git -C "${PACKAGES_ROOT}/${name}" pull origin >/dev/null 2>&1

        cd "${PACKAGES_ROOT}/${name}"

        # Check if we need a tarball
        if grep quilt debian/source/format >/dev/null 2>&1; then
            # Unpack tarball
            origtargz --clean
            origtargz --tar-only --path $BUILD_ROOT/sources/ | sed "s/^/* /"
        fi

	cd ${BUILD_ROOT}
    done

    echo
}

function gendsc() {
    echo "I: Generating debian source packages"

    for name in $(cat ${list}); do
        if [ -d "$PACKAGES_ROOT/$name" ]; then
            cd "$PACKAGES_ROOT/$name"

            echo -n $name
            dpkg-buildpackage -S -d --no-sign >/dev/null 2>&1 && \
		echo " [DSC]" || \
		echo " [FAILED]"

            cd ${BUILD_ROOT}
        fi
    done

    echo
}

init
sync
gendsc
