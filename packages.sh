#!/bin/bash

# Everything important happens in the packages folder
if ! [ -d packages ]; then
    mkdir packages
fi

cd packages

# Set default packages list
export list=../"$1".list

function init() {
    echo "I: Initializing packages"

    for name in $(cat ${list}); do
        # Print status
        echo -n $name

        if ! [ -d ${name} ]; then
            git clone https://github.com/debian-pm/${name}-packaging ${name} >/dev/null 2>&1
        fi
        
        echo " [Done]"
    done
    
    echo
}

function sync() {
    echo "I: Syncing up packages"

    for name in $(cat ${list}); do
        # Print status
        echo -n $name

        # Look if folders exist
        if ! [ -d $name ]; then
            echo "WARN: The packages folder is not yet initialized!"
            break
        fi

        cd ${name}
        git fetch origin >/dev/null 2>&1
        git pull origin >/dev/null 2>&1

        echo -n " [Packaging]"

        # Find out upstream version and download correct tarball
        export PKG_SOURCE_NAME=$(dpkg-parsechangelog -SSource)
        export PKG_VERSION=$(dpkg-parsechangelog -SVersion)
        export PKG_VERSION_EPOCH_UPSTREAM=$(echo ${PKG_VERSION} | sed -e 's/-[^-]*$$//')
        export PKG_VERSION_UPSTREAM_REVISION=$(echo ${PKG_VERSION} | sed -e 's/^[0-9]*://')
        export PKG_VERSION_UPSTREAM=${PKG_VERSION_UPSTREAM_REVISION%%-*}

        # Download not-yet existing tarballs
        if ! [ -f ${PKG_SOURCE_NAME}_${PKG_VERSION_UPSTREAM}.orig.tar.xz ]; then
            wget \
            -O ../${PKG_SOURCE_NAME}_${PKG_VERSION_UPSTREAM}.orig.tar.xz \
            https://raw.githubusercontent.com/debian-pm/orig-tar-xzs/master/${PKG_SOURCE_NAME}_${PKG_VERSION_UPSTREAM}.orig.tar.xz >/dev/null 2>&1
        fi

        tar -xf ../${PKG_SOURCE_NAME}_${PKG_VERSION_UPSTREAM}.orig.tar.xz
        echo " [Tarball]"

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
