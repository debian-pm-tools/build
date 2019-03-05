#!/bin/bash

BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"

# Set package list from command line argument (if exists)
if [ -e "$BUILD_ROOT/packages.list" ]; then
    export list="$BUILD_ROOT/packages.list"
else
    echo "Package list packages.list does not exist!"
    exit 1
fi

for PKG_PATH in $(cat ${list}); do
	if ! grep "Vcs" packages/${PKG_PATH}/debian/control; then
		echo "$package is missing Vcs urls!"
	fi

	GIT="git -C packages/${PKG_PATH}"

	VCS_GIT=$(${GIT} remote get-url origin)
	VCS_BROWSER=${VCS_GIT::-4}
	sed -i "/Vcs-Git/c\Vcs-Git: $VCS_GIT" \
		packages/${PKG_PATH}/debian/control
        sed -i "/Vcs-Browser/c\Vcs-Browser: $VCS_BROWSER" \
		packages/${PKG_PATH}/debian/control
done
