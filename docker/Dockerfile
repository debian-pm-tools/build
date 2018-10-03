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
        reprepro \
        libwww-perl

# Add debian-pm repository
RUN echo "deb https://debian-pm-tools.github.io/apt-repo buster main" > /etc/apt/sources.list.d/debian-pm.list && \
    echo "deb-src https://debian-pm-tools.github.io/apt-repo buster main" >> /etc/apt/sources.list.d/debian-pm.list && \
    wget -qO - https://gitlab.com/debian-pm/debian-pm-keyring/raw/master/jbb.asc | apt-key add - && \
    apt update

COPY ci-build.sh /usr/bin/ci-build
