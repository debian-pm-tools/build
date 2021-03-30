FROM registry.gitlab.com/debian-pm/tools/build/debian:testing-amd64
MAINTAINER Jonah Brüchert <jbb@kaidan.im>

# Initial build essentials
# Speed up builds, install deployment dependencies
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
        libipc-run-perl \
        lintian \
        eatmydata \
        rsync \
        openssh-client \
        distcc \
        # For distcc
        libnss-mdns \
        iproute2 \
        iputils-ping \
        python3-aiohttp \
        python3-debian && \
    rm /usr/share/doc /usr/share/man /usr/share/pixmaps -r

# configure apt
RUN echo "deb-src https://deb.debian.org/debian $(lsb_release -cs) main" >> /etc/apt/sources.list && \
    echo "deb https://repo.kaidan.im/debpm $(lsb_release -cs) main" > /etc/apt/sources.list.d/debian-pm.list && \
    echo "deb-src https://repo.kaidan.im/debpm $(lsb_release -cs) main" >> /etc/apt/sources.list.d/debian-pm.list && \
    wget -qO - https://gitlab.com/debian-pm/debian-pm-keyring/raw/master/repo.kaidan.im.asc | apt-key add - && \
    apt update && \
    apt install debian-pm-archive-keyring

# Add CI tooling
COPY ci-build.sh /usr/local/bin/ci-build
COPY ci-config.sh /usr/local/bin/ci-config
COPY dpmput.py /usr/local/bin/dpmput

# Add eatmydata
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+"$LD_LIBRARY_PATH:"}/usr/lib/libeatmydata \
    LD_PRELOAD=${LD_PRELOAD:+"$LD_PRELOAD "}libeatmydata.so \
