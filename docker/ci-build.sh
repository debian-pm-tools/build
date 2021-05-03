#!/bin/bash -e

PACKAGE_ROOT="${PWD}"
SOURCE_BASE_URL="https://raw.githubusercontent.com/debian-pm-tools/orig-tar-xzs/master"
BUILD_TYPE=$1

# Set up name and email for dch
export NAME="GitLab CI"
export EMAIL="https://gitlab.com/debian-pm/tools/build"

# Set up architecture variables
export $(dpkg-architecture)

# If needed, append string to version number
if [ ! -z "${DEB_BUILD_PROFILES}" ]; then
	DEB_DISTRIBUTION="$(lsb_release -cs)"
	dch -D ${DEB_DISTRIBUTION} --force-distribution -l"${DEB_BUILD_PROFILES}" "Rebuild with ${DEB_BUILD_PROFILES} profile"
fi

# Check whether we should upload to a non-default component of the repository
if [ ! -z "${REPO_COMPONENT}" ] && [ ! "${REPO_COMPONENT}" == "main" ]; then
	if ! cat debian/control | grep Section | grep "${REPO_COMPONENT}"; then
		sed -i "s/Section: /Section: ${REPO_COMPONENT}\//g" debian/control
	fi
fi

# Detect whether a rebuild is wanted
if [ ! -z ${REBUILD} ]; then
	DEB_DISTRIBUTION="$(lsb_release -cs)"
	dch -D ${DEB_DISTRIBUTION} --rebuild "No-change rebuild"
fi

# Detect variables for use later in this script
# Adapted from /usr/share/dpkg/*.mk
DEB_SOURCE=$(dpkg-parsechangelog -SSource)
DEB_VERSION=$(dpkg-parsechangelog -SVersion)
DEB_VERSION_EPOCH_UPSTREAM=$(echo "${DEB_VERSION}" | sed -e 's/-[^-]*$$//')
DEB_VERSION_UPSTREAM_REVISION=$(echo "${DEB_VERSION}" | sed -e 's/^[0-9]*://')
DEB_VERSION_UPSTREAM="${DEB_VERSION_UPSTREAM_REVISION%%-*}"
DEB_DISTRIBUTION=$(dpkg-parsechangelog -SDistribution)

NEW_CHANGELOG_ENTRY_MESSGE="[ci skip] Start new changelog entry after publishing"

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

setup_environment() {
	# Disable tests on architectures that we use qemu-user-static on
	# The xserver doesn't work there, so many tests would fail
	if [ ${DEB_HOST_ARCH} == "armhf" ] || [ ${DEB_HOST_ARCH} == "arm64" ]; then
		export DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS} nocheck"
	fi

	# Prefer to call compiler by its full name
	export CXX=${DEB_HOST_GNU_TYPE}-g++
	export CC=${DEB_HOST_GNU_TYPE}-gcc
}

print_info() {
	echo "Package: $DEB_SOURCE"
	echo "Repository: $(git remote get-url origin)"
	echo "Version: $DEB_VERSION"
	echo "Author of latest change: $(git log -1 --pretty=format:'%an')"
}

get_source() {
	ORIG_TAR_NAME="${DEB_SOURCE}_${DEB_VERSION_UPSTREAM}.orig.tar.xz"
	ORIG_TAR_NAME_ENCODED=$(urlencode "${ORIG_TAR_NAME}")

	if [[ $(wget -S --spider "${SOURCE_BASE_URL}/${ORIG_TAR_NAME}" 2>&1 | grep 'HTTP/1.1 200 OK') ]] >/dev/null; then
		echo "Downloading source from mirror ..."
		wget --continue -O "../${ORIG_TAR_NAME}" "${SOURCE_BASE_URL}/${ORIG_TAR_NAME}"
	elif [ -f debian/watch ]; then
		echo "Downloading source from upstream using uscan"
		uscan --download-current-version --download || \
		echo "Downloading source using origtargz"
		origtargz --unpack=no --download-only --tar-only
	else
		echo "Downloading source using origtargz"
		origtargz --unpack=no --download-only --tar-only
	fi

	origtargz --clean
	# Delete asc files after they have been verified
	if [ -f ../*.asc ]; then
		rm ../*.asc
	fi
	origtargz --unpack=yes
}

install_build_deps() {
	apt-get build-dep . -y
}

setup_distcc() {
	if [ -z $(find . -maxdepth 1 -name "configure.ac") ]; then
		dpkg-reconfigure distcc

		COMPILERS_TO_REPLACE=$(ls /usr/lib/distcc/ | grep -v ${DEB_HOST_GNU_TYPE} | grep -v distccwrapper)
		for bin in ${COMPILERS_TO_REPLACE}; do
			rm /usr/lib/distcc/${bin};
		done

		# Create distcc wrapper
		echo '#!/usr/bin/env bash' > /usr/lib/distcc/distccwrapper
		echo "/usr/lib/distcc/${DEB_HOST_GNU_TYPE}-g"'${0:$[-2]} "$@"' >> /usr/lib/distcc/distccwrapper
		chmod +x /usr/lib/distcc/distccwrapper

		for bin in ${COMPILERS_TO_REPLACE}; do
			ln -s /usr/lib/distcc/distccwrapper /usr/lib/distcc/${bin}
		done

		distcc_ips="$(/sbin/ip route|awk '/default/ { print $3 }') 192.168.178.33 192.168.178.20"

		# Append actually available hosts to DISTCC_HOSTS
		for ip in $distcc_ips; do
			if ping -c 1 $ip; then
				export DISTCC_HOSTS="$DISTCC_HOSTS $ip"
			fi
		done

		export PATH="/usr/lib/distcc/:$PATH"
		distcc --show-hosts
	fi
}

build() {
	dpkg-buildpackage -sa --build=source,$BUILD_TYPE --jobs=$(distcc -j)
}

add_to_repository() {
	if # Check wether required variables aren't empty
		! [ -z ${DEPLOY_HOST} ] && \
		! [ -z ${DEPLOY_USER} ]  && \
		! [ -z ${DEPLOY_PASSWORD} ]; then

		# Check wether a package with the same version number is already in the repository to prevent failures
		BINARY_PACKAGES=$(cat debian/control | grep Package | sed -e 's/Package: //')

		# Detect codename, will be overriden by next command
		LSB_CODENAME=$(lsb_release -cs)

		echo "Checking repository version..."
		apt-get -o Dir::Etc::SourceList=/etc/apt/sources.list.d/debian-pm.list update >/dev/null

		for binary_package in ${BINARY_PACKAGES}; do
			if apt-cache -o Dir::Etc::SourceList=/etc/apt/sources.list.d/debian-pm.list show ${binary_package} | grep "Version: ${DEB_VERSION}" >/dev/null; then
				echo "#### ${binary_package} ###"
				echo "The version of this package in the repository"
				echo "matches the version of this build. (${DEB_VERSION})"
				echo "To release a new build, create a new changelog entry."
				echo "Warning: This build will likely not land in the repository!"
				echo "#########################################"
			fi
		done

		ARTIFACTS=$(ls ${PACKAGE_ROOT}/../*.{dsc,deb} 2>/dev/null | uniq || true)
		export DEPLOY_PASSWORD=$(echo ${DEPLOY_PASSWORD} | base64 -d)
		dpmput --host ${DEPLOY_HOST} --distribution ${LSB_CODENAME} --user ${DEPLOY_USER} --password ${DEPLOY_PASSWORD} --files ${ARTIFACTS}
	else
		echo "Can't publish package since no credentials were provided."
	fi
}

create_changelog_entry() {
	# Try to clean up the working directory
	git pull -f origin "${CI_COMMIT_BRANCH}"
	git checkout .

	if [ "$(git log -1 --pretty=%B)" == "${NEW_CHANGELOG_ENTRY_MESSGE}" ]; then
		return
	fi

	dch "New changelog entry"
	git config --global user.name "${NAME}"
	git config --global user.email "${EMAIL}"
	git add debian/changelog
	git commit -m "${NEW_CHANGELOG_ENTRY_MESSGE}"

	git push "https://jbbgameich:${GIT_PUSH_TOKEN}@${CI_REPOSITORY_URL#*@}" "HEAD:${CI_COMMIT_BRANCH}"
}

setup_environment

echo
echo "============= Package info ==========="
print_info

echo
echo "=========== Download sources ========="
get_source

echo
echo "===== Install build-dependencies ====="
install_build_deps

echo
echo "============ Set up distcc ==========="
setup_distcc

echo
echo "===== Build $BUILD_TYPE package ======="
build $BUILD_TYPE

if [[ ${CI_COMMIT_REF_NAME} == "master" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "Netrunner/mobile" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "debian" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "halium-7.1" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "halium-8.1" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "devkit" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "pinephone" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "buster" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "gemian" ]] || \
	[[ ${CI_COMMIT_REF_NAME} == "debian-unstable" ]]; then # For mesa

	if ! [ ${DEB_DISTRIBUTION} == "UNRELEASED" ]; then
		echo
		echo "===== Upload package to repository ======"
		add_to_repository
		echo "===== Beginning new changelog entry ====="
		create_changelog_entry
	else
		echo "Package isn't released yet, change UNRELEASED to unstable to add it to the repository"
	fi
fi
