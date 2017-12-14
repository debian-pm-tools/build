#!/bin/bash

# Everything important happens in the packages folder
if ! [ -d packages ]; then
    mkdir packages
fi

if ! [ -d repo ]; then
    mkdir -p repo
fi

# Start up repository server
sudo  busybox httpd -h repo

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

        # Check if we need a tarball
        if grep quilt debian/source/format >/dev/null 2>&1; then
            # Download not-yet existing tarballs
            if ! [ -f ${PKG_SOURCE_NAME}_${PKG_VERSION_UPSTREAM}.orig.tar.xz ]; then
                wget \
                -O ../${PKG_SOURCE_NAME}_${PKG_VERSION_UPSTREAM}.orig.tar.xz \
                https://raw.githubusercontent.com/debian-pm/orig-tar-xzs/master/${PKG_SOURCE_NAME}_${PKG_VERSION_UPSTREAM}.orig.tar.xz >/dev/null 2>&1
            fi

            if [ -f ../${PKG_SOURCE_NAME}_${PKG_VERSION_UPSTREAM}.orig.tar.xz ]; then
                tar -xf ../${PKG_SOURCE_NAME}_${PKG_VERSION_UPSTREAM}.orig.tar.xz
            fi
        fi

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

function setup_pbuilder() {
    sudo pbuilder create --basetgz ../buster.tar.gz --mirror http://deb.debian.org/debian --distribution buster

    gpg --export --armor > ../repo/key.pub

    sudo pbuilder execute --save-after-login --save-after-exec --basetgz ../buster.tar.gz -- ../pbuilder-setup.sh
}

function build() {
    for name in $(cat ${list}); do
        if [ -d $name ]; then
            cd $name
            export PKG_VERSION=$(dpkg-parsechangelog -SVersion)
            export PKG_NAME=$(dpkg-parsechangelog -SSource)
            export PKG_VERSION_UPSTREAM_REVISION=$(echo ${PKG_VERSION} | sed -e 's/^[0-9]*://')
            cd ..

            scanpackages

            sudo pbuilder update --basetgz ../buster.tar.gz
            sudo pbuilder build --basetgz ../buster.tar.gz --buildresult ../repo ${PKG_NAME}_${PKG_VERSION_UPSTREAM_REVISION}.dsc
        fi
    done
}

function scanpackages() {
    cd ../repo

    echo "I: Indexing built packages"
    dpkg-scanpackages . /dev/null | tee Packages | xz > Packages.xz
    apt-ftparchive release . > Release
    gpg --yes --armor --output Release.gpg --detach-sig Release

    cd ../packages
}

init
sync
gendsc

if ! [ -f ../buster.tar.gz ]; then
    setup_pbuilder
fi

build
