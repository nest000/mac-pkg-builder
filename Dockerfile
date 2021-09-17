FROM ubuntu:latest AS build

WORKDIR /opt/build

RUN echo "deb http://security.ubuntu.com/ubuntu bionic-security main" \
    > /etc/apt/sources.list.d/security.list

RUN apt-get -qq update && \
    apt-cache policy libssl1.0-dev && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -qq -y \
    build-essential \
    file \
    curl \
    cpio \
    libxml2-dev \
    libssl1.0-dev \
    zlib1g-dev

RUN curl -L https://github.com/hogliux/bomutils/archive/0.2.tar.gz > bomutils.tar.gz && \
    echo "fb1f4ae37045eaa034ddd921ef6e16fb961e95f0364e5d76c9867bc8b92eb8a4  bomutils.tar.gz" | sha256sum --check && \
    tar -xzf bomutils.tar.gz && \
    cd bomutils-0.2 && \
    LDFLAGS=-static make

RUN curl -L https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/xar/xar-1.5.2.tar.gz > xar.tar.gz && \
    tar -xzf xar.tar.gz && \
    cd xar-1.5.2 && \
   	./configure && \
    make && \
    make install

RUN cp -R /opt/build/bomutils-0.2/build/bin/* /usr/local/bin/

COPY ./docker/ /

WORKDIR /app

ENTRYPOINT ["/opt/build/build.sh"]