#!/usr/bin/env bash -e
BUILD_ROOT="$(dirname "$(readlink -f "${0}")")"
source "$BUILD_ROOT/functions/list-common.sh"

# Check if list is supplied as argument
if [ "$#" -lt 1 ]; then
    echo "Required argument: packages list name"
    exit 1
fi

for package in $(cat ${list}); do
	git -C packages/${package} fetch
        git -C packages/${package} pull
	git -C packages/${package} rebase

	cat <<EOF > packages/${package}/.gitlab-ci.yml
include: 'https://gitlab.com/debian-pm/tools/build/raw/master/docker/gitlab-ci-base.yml'

image: jbbgameich/build
EOF

	git -C packages/${package} add .gitlab-ci.yml
	git -C packages/${package} commit -m "Add GitLab ci configuration"
done
