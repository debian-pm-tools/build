#!/bin/bash

# Check if list is supplied as argument
if [ "$#" -lt 1 ]; then
    echo "Required argument: packages list name"
    exit 1
fi

# Set package list from command line argument (if exists)
if [ -e "$1".list ]; then
    export list="$1".list
else
    echo "Package list $1 does not exist!"
    exit 1
fi

for package in $(cat ${list}); do
	cd packages/$package

	echo "Cleaning packages/$package"
	origtargz --clean

	source=$(dpkg-parsechangelog -S Source)
	version=$(dpkg-parsechangelog -S Version | sed -e 's/^[0-9]*://')

	if [ -f ../${source}_${version%%-*}.orig.tar.* ]; then
		echo "Deleting ../${source}_${version%%-*}.orig.tar.*"
		rm ../${source}_${version%%-*}.orig.tar.*
	fi

	cd ../../
done
