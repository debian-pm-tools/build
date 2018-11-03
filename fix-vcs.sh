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
	if ! grep "Vcs" packages/$package/debian/control; then
		echo "$package is missing Vcs urls!"
	fi

	GIT="git -C packages/${package}"

	VCS_GIT=$(${GIT} remote get-url origin)
	VCS_BROWSER=${VCS_GIT::-4}
	sed -i "/Vcs-Git/c\Vcs-Git: $VCS_GIT" \
		packages/${package}/debian/control
        sed -i "/Vcs-Browser/c\Vcs-Browser: $VCS_BROWSER" \
		packages/$package/debian/control
done
