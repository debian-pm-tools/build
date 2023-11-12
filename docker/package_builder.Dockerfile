FROM docker.io/debian:testing
MAINTAINER Jonah Brüchert <jbb@kaidan.im>

# Initial build essentials
# Speed up builds, install deployment dependencies
RUN apt update && \
    apt full-upgrade -y && \
    apt install -y \
        --no-install-recommends \
        ca-certificates \
        devscripts \
        debhelper \
        sudo \
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
        distcc \
        # For distcc
        libnss-mdns \
        iproute2 \
        iputils-ping \
        python3-pip \
        python3-debian \
        # For pip to work with modules that compile stuff
        python3-dev \
        # for ci-build
        libdistro-info-perl \
        lsb-release && \
    rm /usr/share/doc /usr/share/man /usr/share/pixmaps -r && \
    pip3 install --break-system-packages aiohttp && \
    # configure apt
    echo "deb-src https://deb.debian.org/debian $(lsb_release -cs) main" >> /etc/apt/sources.list && \
    echo "deb https://jbb.ghsq.de/debpm $(lsb_release -cs) main" > /etc/apt/sources.list.d/debian-pm.list && \
    echo "deb-src https://jbb.ghsq.de/debpm $(lsb_release -cs) main" >> /etc/apt/sources.list.d/debian-pm.list && \
    wget https://jbb.ghsq.de/debpm/pool/main/d/debian-pm-repository/debian-pm-archive-keyring_20210819_all.deb && \
    sudo dpkg -i debian-pm-archive-keyring_20210819_all.deb && \
    rm debian-pm-archive-keyring_20210819_all.deb && \
    apt-get update && \
    apt-get install debian-pm-archive-keyring && \
    # Clean up to slim down the image
    apt-get purge python3-dev g++ libgcc*-dev gcc --auto-remove -y

# Add CI tooling
COPY ci-build.sh /usr/local/bin/ci-build
COPY ci-config.sh /usr/local/bin/ci-config
COPY dpmput.py /usr/local/bin/dpmput

# Add eatmydata
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+"$LD_LIBRARY_PATH:"}/usr/lib/libeatmydata \
    LD_PRELOAD=${LD_PRELOAD:+"$LD_PRELOAD "}libeatmydata.so \
