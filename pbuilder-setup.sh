#!/bin/bash

apt install curl software-properties-common ca-certificates gnupg -y

echo "deb http://localhost:8080 ./" >> /etc/apt/sources.list
echo "deb http://debian-pm.github.io/debian-mobile buster main" >> /etc/apt/sources.list
curl http://localhost:8080/key.pub | apt-key add -
curl https://raw.githubusercontent.com/JBBgameich/debian-mobile/master/key.pub | apt-key add -

apt update
