#!/usr/bin/env bash

set -e

BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"

FEATURE="$1"
VERSION="$2"

error_namenotset() {
    echo "ERROR: The \$NAME and \$EMAIL variables need to be set to create a new changelog entry"
    exit 1
}

# Check if the variables for dch are set
if [ -z "$NAME" ] || [ -z "$EMAIL" ]; then
    error_namenotset
fi

if [ -z "${VERSION}" ]; then
    echo "The version argument can't be empty"
    exit 1
fi

GEAR_PACKAGES="
apps/kasts
apps/plasma-dialer
apps/kweather
apps/alligator
apps/kclock
apps/koko
apps/spacebar
apps/plasma-phonebook
apps/audiotube
apps/kalk
apps/qmlkonsole
apps/plasmatube
plasma-mobile/plasma-settings"

function update() {
    for app in ${GEAR_PACKAGES}; do
        echo "I: Updating ${app}"
        cd "${BUILD_ROOT}/packages/${app}"
        origtargz --clean
        if [ -f .git/hooks/pre-commit ]; then
            rm .git/hooks/pre-commit                    # Some buildsystems install anoying hooks here that break the script
        fi
        echo "Pulling in upstream changes…"
        git pull

        if dpkg-parsechangelog -SVersion | grep ${VERSION} >/dev/null; then
            echo "${app} is already up to date"
            continue
        fi

        mkdir -p "debian/upstream/"
        cp "${BUILD_ROOT}/packages/apps/plasma-angelfish/debian/upstream/signing-key.asc" "debian/upstream/signing-key.asc"

        dch -v "${VERSION}-1" "New upstream release"
        origtargz
        git add debian/changelog debian/upstream/signing-key.asc
        git commit -m "New upstream release ${VERSION}"
        git show HEAD
        echo "I'm going to push this commit, press Ctrl + C to abort or enter to continue"
        read
        git push
    done
}

function release() {
    echo "Are all ci badges green? Press enter if so, else Ctrl + C"

    for app in ${GEAR_PACKAGES}; do
        echo "I: Releasing ${app}"
        cd "${BUILD_ROOT}/packages/${app}"
        if [ -f .git/hooks/pre-commit ]; then
            rm .git/hooks/pre-commit                    # Some buildsystems install anoying hooks here that break the script
        fi

        if dpkg-parsechangelog -SDistribution | grep -v UNRELEASED >/dev/null; then
            echo "Skipping ${app}, as the current changelog entry is already released"
            continue
        fi

        dch --release

        git add debian/changelog
        git commit -m "Release ${VERSION}-1"
        git show HEAD
        echo "I'm going to push this commit, press Ctrl+C to abort or enter to continue"
        read
        git push
    done
}

${FEATURE}
