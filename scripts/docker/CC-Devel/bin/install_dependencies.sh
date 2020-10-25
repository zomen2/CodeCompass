#!/usr/bin/env bash

declare -a packages_to_install
packages_to_install=(                                                          \
    "ant"                                                                      \
    "autoconf"                                                                 \
    "automake"                                                                 \
    "bison"                                                                    \
    "clang-10"                                                                 \
    "cmake"                                                                    \
    "ctags"                                                                    \
    "default-jdk-headless"                                                     \
    "flex"                                                                     \
    "git"                                                                      \
    "libboost-filesystem-dev"                                                  \
    "libboost-log-dev"                                                         \
    "libboost-program-options-dev"                                             \
    "libboost-regex-dev"                                                       \
    "libclang-10-dev"                                                          \
    "libcutl-dev"                                                              \
    "libevent-dev"                                                             \
    "libexpat1-dev"                                                            \
    "libgit2-dev"                                                              \
    "libgraphviz-dev"                                                          \
    "libgtest-dev"                                                             \
    "llvm-10-dev"                                                              \
    "libmagic-dev"                                                             \
    "libodb-pgsql-dev"                                                         \
    "libodb-sqlite-dev"                                                        \
    "libpq-dev"                                                                \
    "libsqlite3-dev"                                                           \
    "libtool"                                                                  \
    "make"                                                                     \
    "nodejs"                                                                   \
    "npm"                                                                      \
    "pkg-config"                                                               \
    "wget"                                                                     \
    "xz-utils"                                                                 \
    "zlib1g-dev"                                                               \
)

declare running_ubuntu_codename
running_ubuntu_codename="$(lsb_release --codename --short)"
if [[ "${running_ubuntu_codename}" == "focal" ]]; then
    packages_to_install+=(
        "libssl-dev"                                                           \
        "g++-9"                                                                \
        "gcc-9"                                                                \
        "gcc-9-plugin-dev"                                                     \
        "libodb-dev"                                                           \
        "odb"                                                                  \
        "postgresql-server-dev-12"                                             \
    )
elif [[ "${running_ubuntu_codename}" == "bionic" ]]; then
    packages_to_install+=(
        "libssl1.0-dev"                                                        \
        "g++-7"                                                                \
        "gcc-7"                                                                \
        "gcc-7-plugin-dev"                                                     \
        "postgresql-server-dev-10"
    )
else
    echo "Unsupported ubuntu release" 2>&1
    exit 1
fi

# Install packages that necessary for build CodeCompass.
DEBIAN_FRONTEND=noninteractive apt-get install --yes "${packages_to_install[@]}"

# Workaround. This single step prevent unwanted remove of npm.
#apt-get install --yes "npm"
