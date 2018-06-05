#!/bin/bash

BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"

# Everything important happens in the packages folder
if ! [ -d packages ]; then
    mkdir packages
fi

if ! [ -d repo ]; then
    mkdir -p repo
fi

cd packages

# Check if list is supplied as argument
if [ "$#" -lt 1 ]; then
    echo "Required argument: packages list name"
    exit 1
fi

# Set package list from command line argument (if exists)
if [ -e ../"$1".list ]; then
    export list=../"$1".list
else
    echo "Package list $1 does not exist!"
    exit 1
fi

# Main functions
function init() {
    echo "I: Initializing packages"

    for name in $(cat ${list}); do
        # Print status
        echo -n $name

        if ! [ -d ${name} ]; then
            git clone https://gitlab.com/debian-pm/${name}-packaging ${name} >/dev/null 2>&1
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
        if ! [ -d $name ]; then
            echo "WARN: The packages folder is not yet initialized!"
            break
        fi

        cd ${name}

        echo "* Fetching packaging ..."

        git fetch origin >/dev/null 2>&1
        git pull origin >/dev/null 2>&1

        # Find out upstream version and download correct tarball
        export PKG_SOURCE_NAME=$(dpkg-parsechangelog -SSource)
        export PKG_VERSION=$(dpkg-parsechangelog -SVersion)
        export PKG_VERSION_EPOCH_UPSTREAM=$(echo ${PKG_VERSION} | sed -e 's/-[^-]*$$//')
        export PKG_VERSION_UPSTREAM_REVISION=$(echo ${PKG_VERSION} | sed -e 's/^[0-9]*://')
        export PKG_VERSION_UPSTREAM=${PKG_VERSION_UPSTREAM_REVISION%%-*}

        # Check if we need a tarball
        if grep quilt debian/source/format >/dev/null 2>&1; then
            # Unpack tarball
            origtargz --clean
            origtargz --tar-only --path $BUILD_ROOT/sources/ | sed "s/^/* /"
        fi

        cd ..
    done

    echo
}

function gendsc() {
    echo "I: Generating debian source packages"

    for name in $(cat ${list}); do
        if [ -d $name ]; then
            cd $name

            echo -n $name
            dpkg-buildpackage -S -d --force-sign >/dev/null 2>&1

            echo " [DSC]"
            cd ..
        fi
    done

    echo
}

init
sync
gendsc
