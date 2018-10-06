#!/bin/bash -e

SOURCE_BASE_URL="https://raw.githubusercontent.com/debian-pm-tools/orig-tar-xzs/master"

# Set up architecture variables
export $(dpkg-architecture)

# Detect variables for use later in this script
# Adapted from /usr/share/dpkg/*.mk
DEB_SOURCE=$(dpkg-parsechangelog -SSource)
DEB_VERSION=$(dpkg-parsechangelog -SVersion)
DEB_VERSION_EPOCH_UPSTREAM=$(echo "${DEB_VERSION}" | sed -e 's/-[^-]*$$//')
DEB_VERSION_UPSTREAM_REVISION=$(echo "${DEB_VERSION}" | sed -e 's/^[0-9]*://')
DEB_VERSION_UPSTREAM="${DEB_VERSION_UPSTREAM_REVISION%%-*}"
DEB_DISTRIBUTION=$(dpkg-parsechangelog -SDistribution)

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

	origtargz --clean
	origtargz --tar-only
}

install_build_deps() {
	sudo apt build-dep . -y
}

build_source() {
	dpkg-buildpackage -sa --build=source
}

build_binary() {
	dpkg-buildpackage -sa --build=binary
}

add_to_repository() {
	REPO_URL=github.com/debian-pm-tools/incoming-apt-repo
	REPO_BRANCH="${REPO_BRANCH:master}"

	git clone https://${REPO_URL} -b ${REPO_BRANCH}
		reprepro \
		--outdir $PWD/incoming-apt-repo \
		--confdir $PWD/incoming-apt-repo/conf \
		update

	# Checks
	REPO_VERSION=$(reprepro \
			--outdir $PWD/incoming-apt-repo \
			--confdir $PWD/incoming-apt-repo/conf \
			list buster ${DEB_SOURCE} | grep ${REPO_ARCH} | sed 's/^.*\ //')

	if [[ ${REPO_VERSION} == ${DEB_VERSION} ]]; then
		echo "##########################################"
		echo "The version of this package in the repository (${REPO_VERSION})"
		echo "matches the version of this build."
		echo "To release a new build, create a new changelog entry."
		echo "Warning: Will not deploy this build!"
		echo "#########################################"
	else
                sleep $[ ( $RANDOM % 20 + 1 ) ]
                git -C incoming-apt-repo pull

		reprepro \
			--ignore=wrongdistribution \
			--outdir $PWD/incoming-apt-repo \
			--confdir $PWD/incoming-apt-repo/conf \
			include buster \
			../${DEB_SOURCE}_${DEB_VERSION}_${DEB_BUILD_ARCH}.changes

		git config --global user.email "debian-pm-tools@users.noreply.github.com"
		git config --global user.name "CI builder"

		git -C incoming-apt-repo add dists pool
		git -C incoming-apt-repo commit -m "${DEB_BUILD_ARCH}: Add CI build of ${DEB_SOURCE} ${DEB_VERSION}"
		git -C incoming-apt-repo push https://JBBgameich:${GITHUB_TOKEN}@${REPO_URL} ${REPO_BRANCH}
	fi
}


get_source
install_build_deps
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
	[[ ${CI_COMMIT_REF_NAME} == "debian" ]]; then
	add_to_repository
fi
