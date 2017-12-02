#!/bin/bash

apt install curl software-properties-common ca-certificates gnupg -y

echo "deb http://localhost ./" >> /etc/apt/sources.list
curl http://localhost/key.pub | apt-key add -

apt update
