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
        curl \
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

COPY ci-build.sh /usr/bin/ci-build
COPY ci-config.sh /usr/bin/ci-config

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+"$LD_LIBRARY_PATH:"}/usr/lib/libeatmydata \
    LD_PRELOAD=${LD_PRELOAD:+"$LD_PRELOAD "}libeatmydata.so \
    PATH=/usr/lib/ccache/:$PATH
