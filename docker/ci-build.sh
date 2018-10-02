#/usr/bin/env bash -e

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
	ORIG_TAR_NAME_ENCODED=$( urlencode "${ORIG_TAR_NAME}" )

	# Try to download source
	wget --continue -O "../${ORIG_TAR_NAME}" "${SOURCE_BASE_URL}/${ORIG_TAR_NAME}" || \
		rm "../${ORIG_TAR_NAME}"

	origtargz --clean
	origtargz --tar-only
}

install_build_deps() {
	sudo apt build-dep . -y
}

build_binary() {
	dpkg-buildpackage
}

get_source
install_build_deps
build_binary
