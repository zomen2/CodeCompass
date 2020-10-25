#!/usr/bin/env bash

function cleanup() {
    echo "Cleaning up Odb temporaries."
    if [[ -n "${odb_build_dir}" ]]; then
        rm --recursive --force "${odb_build_dir}"
    fi
}

trap cleanup EXIT

set -e

function usage() {
    cat <<EOF
${0} [-h] [-d <install dir>]
  -h  Print this usage information. Optional.
  -d  Install directory of ODB. Optional. "/opt/odb" is the default.
      On Ubuntu 20.04 and newer, ODB packages are part of distribution, so
      on these versions this parameter has no effect.
EOF
}

function installOdbBuildTool() {
    mkdir --parents "${odb_build_dir}"
    pushd "${odb_build_dir}"
    wget https://download.build2.org/0.13.0/build2-install-0.13.0.sh
    sh build2-install-0.13.0.sh --yes --trust yes "${build_toolchain_dir}"
    popd
}

function makeAndInstallOdbDevel() {
    export PATH="${build_toolchain_dir}/bin:${PATH}"
    mkdir --parents "${build_dir}"
    pushd "${build_dir}"
    # Configuring the build
    bpkg create --quiet --jobs $(nproc) cc                                     \
        config.cxx=g++                                                         \
        config.cc.coptions=-O3                                                 \
        config.bin.rpath="${odb_install_dir}/lib"                              \
        config.install.root="${odb_install_dir}"
        
    # Getting the source
    bpkg add https://pkg.cppget.org/1/beta --trust-yes
    bpkg fetch --trust-yes

    # Building odb
    bpkg build odb --yes
    bpkg build libodb --yes
    bpkg build libodb-sqlite --yes
    bpkg build libodb-pgsql --yes
    bpkg install --all --recursive
    popd
}

declare odb_install_dir="/opt/odb"
while getopts "hd:" OPTION; do
    case ${OPTION} in
        h)
            usage
            exit 0
            ;;
        d)
            odb_install_dir="${OPTARG}"
            ;;
        *)
            usage >&2
            exit 1
            ;;
    esac
done


declare running_ubuntu_codename
running_ubuntu_codename="$(lsb_release --codename --short)"
if [[ "${running_ubuntu_codename}" == "focal" ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get install --yes                       \
        "libodb-dev" "odb"
elif [[ "${running_ubuntu_codename}" == "bionic" ]]; then
    declare odb_build_dir
    odb_build_dir=$(mktemp -d -t "odbbuild_XXXXXXXX")
    build_toolchain_dir="${odb_build_dir}/build2"
    build_dir="${odb_build_dir}/odb"

    installOdbBuildTool
    makeAndInstallOdbDevel
else
    echo "Unsupported ubuntu release" 2>&1
    exit 1
fi
