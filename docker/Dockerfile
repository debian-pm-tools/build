FROM debian:testing
MAINTAINER Jonah Brüchert <jbb@kaidan.im>

# Initial build essentials
RUN apt update && \
    apt install -y \
        --no-install-recommends \
        ca-certificates \
        devscripts \
        build-essential \
        debhelper \
        sudo \
        software-properties-common \
        wget \
        gnupg \
        git \
        quilt \
        libwww-perl \
        libmoo-perl \
        libipc-run-perl

# Speed up builds
RUN apt install eatmydata ccache -y

# Deployment dependencies
RUN apt install rsync openssh-client -y

# Add debian-pm repository
RUN echo "deb-src https://deb.debian.org/debian testing main" >> /etc/apt/sources.list && \
    echo "deb https://repo.kaidan.im/debpm buster main" > /etc/apt/sources.list.d/debian-pm.list && \
    echo "deb-src https://repo.kaidan.im/debpm buster main" >> /etc/apt/sources.list.d/debian-pm.list && \
    wget -qO - https://gitlab.com/debian-pm/debian-pm-keyring/raw/master/jbb.asc | apt-key add - && \
    wget -qO - https://gitlab.com/debian-pm/debian-pm-keyring/raw/master/repo.kaidan.im.asc | apt-key add - && \
    apt update

# Pin packages we need to replace for GL es
ENV PIN_PACKAGES="libqt5core5a libqt5gui5 qt5-gtk-platformtheme qt5-flatpak-platformtheme libqt5network5 libqt5opengl5 libqt5sql5 libqt5sql5-mysql libqt5sql5-odbc libqt5sql5-psql libqt5sql5-sqlite libqt5sql5-tds libqt5sql5-ibase libqt5xml5 libqt5dbus5 libqt5test5 libqt5concurrent5 libqt5widgets5 libqt5printsupport5 qtbase5-dev qtbase5-private-dev libqt5opengl5-dev qtbase5-dev-tools qt5-qmake-bin qt5-qmake qtbase5-examples qt5-default qtbase5-doc qtbase5-doc-html libqt5multimedia5 libqt5multimedia5-plugins libqt5multimediaquick5 libqt5multimediawidgets5 qml-module-qtmultimedia qml-module-qtaudioengine libqt5multimediagsttools5 qtmultimedia5-examples qtmultimedia5-devqtmultimedia5-doc qtmultimedia5-doc-html qtwebengine5-dev qtwebengine5-private-dev libqt5webengine5 libqt5webenginecore5 libqt5webenginewidgets5 libqt5webengine-data qml-module-qtwebengine qtwebengine5-dev-tools qtwebengine5-examples qtwebengine5-doc qtwebengine5-doc-html kwin-common kwin-dev kwin-wayland kwin-wayland-backend-drm kwin-wayland-backend-fbdev kwin-wayland-backend-hwcomposer kwin-wayland-backend-virtual kwin-wayland-backend-wayland kwin-wayland-backend-x11 kwin-x11 libkwin4-effect-builtins1 libkwineffects11 libkwinglutils11 libkwinxrenderutils11"

RUN for package in $PIN_PACKAGES; do \
    echo "Package: $package" >>/etc/apt/prefences && \
    echo "Pin: origin repo.kaidan.im" >>/etc/apt/prefences && \
    echo "Pin-Priority: 2000" >>/etc/apt/prefences && \
    echo >>/etc/apt/prefences; \
    done

COPY ci-build.sh /usr/bin/ci-build
COPY ci-config.sh /usr/bin/ci-config

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+"$LD_LIBRARY_PATH:"}/usr/lib/libeatmydata \
    LD_PRELOAD=${LD_PRELOAD:+"$LD_PRELOAD "}libeatmydata.so \
    PATH=/usr/lib/ccache/:$PATH
