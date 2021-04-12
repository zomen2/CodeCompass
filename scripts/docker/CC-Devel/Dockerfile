ARG UBUNTU_VERSION=18.04

FROM ubuntu:${UBUNTU_VERSION}

ARG UBUNTU_VERSION

LABEL com.ericsson.codecompass.ubuntu.version="${UBUNTU_VERSION}"

RUN apt-get update                                                             \
  && DEBIAN_FRONTEND=noninteractive apt-get install --yes locales

RUN sed --in-place --expression='s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/'     \
    /etc/locale.gen                                                            \
  && dpkg-reconfigure --frontend=noninteractive locales                        \
  && update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8

RUN DEBIAN_FRONTEND=noninteractive apt-get install --yes                       \
    apt-utils                                                                  \
    gpgv                                                                       \
    lsb-release                                                                \
    wget

WORKDIR /root
COPY ./dbuild ./build
RUN chmod u+x \
    ./build/install_gtest.sh                                                   \
    ./build/install_dbaccess.sh                                                \
    ./build/install_thrift.sh                                                  \
    ./build/uagen.sh                                                           \
    ./build/install_dependencies.sh

RUN ./build/install_dependencies.sh

#TODO clang version? Maybe part of install dep?
RUN ./build/uagen.sh -v 10 -p 50 && ./build/reg-clang.sh

RUN ./build/install_gtest.sh                                                   \
  && ./build/install_dbaccess.sh                                               \
  && ./build/install_thrift.sh -t "0.13.0"

WORKDIR /tmp
