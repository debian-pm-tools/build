#!/usr/bin/env bash

PACKAGES="crossbuild-essential-armhf crossbuild-essential-arm64 crossbuild-essential-amd64 crossbuild-essential-i386"
ARCHES="arm-linux-gnueabihf aarch64-linux-gnu x86_64-linux-gnu i686-linux-gnu"

echo -n "Checking whether cross-toolchains are installed... "
if ! dpkg -s ${PACKAGES} >/dev/null; then
	echo "no"
	sudo apt install ${PACKAGES} -y
else
	echo "yes"
fi

for arch in ${ARCHES}; do
	if [ -f /usr/lib/distcc/${arch}-gcc ] || [ -f /usr/lib/distcc/${arch}-g++ ]; then
		echo -n "Removing existing distcc symlinks... "
		sudo rm /usr/lib/distcc/${arch}-gcc /usr/lib/distcc/${arch}-g++ && echo "done"
	fi

	echo -n "Creating new symlinks for ${arch}... "
	sudo ln -s /usr/bin/distcc /usr/lib/distcc/${arch}-gcc
	sudo ln -s /usr/bin/distcc /usr/lib/distcc/${arch}-g++ && echo "done"
done
