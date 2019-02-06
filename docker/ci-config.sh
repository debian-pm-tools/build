#!/usr/bin/env bash

if ! [ -z $REPO_COMPONENT ]; then
        echo "Enabling ${REPO_COMPONENT} component"
        echo "deb https://repo.kaidan.im/debpm buster main ${REPO_COMPONENT}" > \
                /etc/apt/sources.list.d/debian-pm.list
fi
apt update
