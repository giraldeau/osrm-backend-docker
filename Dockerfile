FROM ubuntu:xenial
MAINTAINER Alex Newman <alex@newman.pro>

# Let the container know that there is no TTY
ENV DEBIAN_FRONTEND noninteractive

# Install necessary packages for proper system state
RUN apt-get -y update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    git \
    libboost-all-dev \
    libbz2-dev \
    libstxxl-dev \
    libstxxl-doc \
    libstxxl1v5 \
    libtbb-dev \
    libxml2-dev \
    libzip-dev \
    lua5.1 \
    liblua5.1-0-dev \
    libluabind-dev \
    libluajit-5.1-dev \
    pkg-config

RUN mkdir -p /osrm-build \
 && mkdir -p /osrm-data

WORKDIR /osrm-build

RUN curl --silent -L https://github.com/Project-OSRM/osrm-backend/archive/v5.2.6.tar.gz -o v5.2.6.tar.gz \
 && tar xzf v5.2.6.tar.gz \
 && mv osrm-backend-5.2.6 /osrm-src \
 && cmake /osrm-src \
 && make \
 && make install \
 && ldconfig \
 && mv /osrm-src/profiles/car.lua profile.lua \
 && mv /osrm-src/profiles/lib/ lib \
 && echo "disk=/tmp/stxxl,25000,syscall" > .stxxl \
 && rm -rf /osrm-src

RUN apt-get -y update && apt-get install -y \
    build-essential \
    qt5-qmake \
    qtbase5-dev

WORKDIR /tufao-build

RUN git clone --depth 1 --single-branch -b 1.3.8 https://github.com/vinipsmaker/tufao.git
RUN mv tufao tufao-src
RUN cmake -DCMAKE_BUILD_TYPE=Release tufao-src/
RUN make \
 && make install \
 && ldconfig

WORKDIR /evnav-build

RUN git clone --depth 1 --single-branch -b v0.2 https://github.com/giraldeau/evnav.git \
 && mv evnav evnav-src \
 && qmake -qt=qt5 evnav-src \
 && make \
 && make install

# Cleanup --------------------------------

RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Publish --------------------------------

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5000
