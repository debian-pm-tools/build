FROM i386/debian:testing-slim
MAINTAINER Jonah Brüchert <jbb@kaidan.im>

# Update Container
RUN apt update && \
        apt full-upgrade -y

# Initial build essentials
RUN apt install -y \
        --no-install-recommends \
        ca-certificates \
        devscripts \
        build-essential \
        debhelper \
        sudo \
        software-properties-common \
        curl \
        gnupg \
        git \
        quilt

# Add debian-pm repository
RUN     echo "deb https://debian-pm-tools.github.io/apt-repo buster main" > /etc/apt/sources.list.d/debian-pm.list && \
        echo "deb-src https://debian-pm-tools.github.io/apt-repo buster main" >> /etc/apt/sources.list.d/debian-pm.list && \
        echo "deb-src https://deb.debian.org/debian testing main" >> /etc/apt/sources.list && \
        curl https://raw.githubusercontent.com/JBBgameich/debian-mobile/master/key.pub | apt-key add - && \
        apt update

WORKDIR /build/

