#!/bin/bash -e

PACKAGE_ROOT="${PWD}"
SOURCE_BASE_URL="https://raw.githubusercontent.com/debian-pm-tools/orig-tar-xzs/master"

# Set up architecture variables
export $(dpkg-architecture)

# If needed, append string to version number
if [ $REPO_BRANCH == "caf" ]; then
	dch -lcaf "Rebuild against caf headers"
	sed -i 's/Section: /Section: caf\//g' debian/control
fi

# Detect whether a rebuild is wanted
if [ ! -z $REBUILD ]; then
	echo "I: Preparing changelog for a no-change rebuild"
	dch --rebuild "No-change rebuild"
fi

# Detect variables for use later in this script
# Adapted from /usr/share/dpkg/*.mk
DEB_SOURCE=$(dpkg-parsechangelog -SSource)
DEB_VERSION=$(dpkg-parsechangelog -SVersion)
DEB_VERSION_EPOCH_UPSTREAM=$(echo "${DEB_VERSION}" | sed -e 's/-[^-]*$$//')
DEB_VERSION_UPSTREAM_REVISION=$(echo "${DEB_VERSION}" | sed -e 's/^[0-9]*://')
DEB_VERSION_UPSTREAM="${DEB_VERSION_UPSTREAM_REVISION%%-*}"
DEB_DISTRIBUTION=$(dpkg-parsechangelog -SDistribution)

echo "======================================"
echo "Package: $DEB_SOURCE"
echo "Repository: $(git remote get-url origin)"
echo "Version: $DEB_VERSION"
echo "======================================"

# From https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command
urlencode() {
	local string="${1}"
	local strlen=${#string}
	local encoded=""
	local pos c o

	for ((pos = 0; pos < strlen; pos++)); do
		c=${string:$pos:1}
		case "$c" in
			[-_.~a-zA-Z0-9]) o="${c}"
			;;
		*)
			printf -v o '%%%02X' "'$c"
			;;
		esac
		encoded+="${o}"
	done

	echo "${encoded}"  # You can either set a return variable (FASTER)
	REPLY="${encoded}" #+or echo the result (EASIER)... or both... :p
}

get_source() {
	ORIG_TAR_NAME="${DEB_SOURCE}_${DEB_VERSION_UPSTREAM}.orig.tar.xz"
	ORIG_TAR_NAME_ENCODED=$(urlencode "${ORIG_TAR_NAME}")

	# Try to download source
	wget --continue -O "../${ORIG_TAR_NAME}" "${SOURCE_BASE_URL}/${ORIG_TAR_NAME}" || \
		rm "../${ORIG_TAR_NAME}"

	rm ../*.orig.*.asc >/dev/null 2>&1 || true
	uscan -d --download-current-version --skip-signature || echo "Package doesn't seem to use uscan"
	origtargz --clean
	origtargz --tar-only
}

install_build_deps() {
	sudo apt build-dep . -y
}

setup_ccache() {
	export PATH=/usr/lib/ccache:$PATH
	export CCACHE_DIR=${PACKAGE_ROOT}/debian/ccache
	mkdir -p ${CCACHE_DIR}
}

build_source() {
	dpkg-buildpackage -sa --build=source
}

build_binary() {
	dpkg-buildpackage -sa --build=binary
}

add_to_repository() {
	# Check wether a package with the same version number is already in the repository to prevent failures
	BINARY_PACKAGES=$(cat debian/control | grep Package | sed -e 's/Package: //')

	echo "I: Checking repository version..."
	sudo apt -o Dir::Etc::SourceList=/etc/apt/sources.list.d/debian-pm.list update >/dev/null

	for binary_package in ${BINARY_PACKAGES}; do
		if apt -o Dir::Etc::SourceList=/etc/apt/sources.list.d/debian-pm.list list | grep $binary_package | grep ${DEB_VERSION}; then
			echo "##########################################"
			echo "The version of this package in the repository"
			echo "matches the version of this build. (${DEB_VERSION})"
			echo "To release a new build, create a new changelog entry."
			echo "Warning: This build will likely not land in the repository!"
			echo "#########################################"
		fi
	done

	# Install deploy keys from environment variabless
	mkdir -p ~/.ssh/
	echo ${DEPLOY_KEY_PRIVATE} | base64 -d | xz -d > ~/.ssh/id_rsa
	echo ${DEPLOY_KEY_PUBLIC} | base64 -d | xz -d > ~/.ssh/id_rsa.pub
	chmod 400 ~/.ssh/id_rsa

	ARTIFACTS=$(ls ${PACKAGE_ROOT}/../*.{dsc,deb,orig*,debian*,xz,gz,tar*,buildinfo,changes} 2>/dev/null | uniq || true)

	rsync -avzp -e \
		"ssh -o StrictHostKeyChecking=no -p ${DEPLOY_PORT}" \
		${ARTIFACTS} \
		"${DEPLOY_ACCOUNT}:/var/opt/repo-debpm-incoming/"
}


get_source
install_build_deps
setup_ccache
case $1 in
	source)
		REPO_ARCH="source"
		build_source
		;;
	binary)
		REPO_ARCH=${DEB_BUILD_ARCH}
		build_binary
		;;
esac
if [[ ${CI_COMMIT_REF_NAME} == "master" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "Netrunner/mobile" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "debian" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "halium-7.1" ]]; then
	add_to_repository
fi
