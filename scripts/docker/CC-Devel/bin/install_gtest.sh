#!/usr/bin/env bash
set -e

declare build_dir
build_dir=$(mktemp -d -t "gtestbuild_XXXXXXXX")

function cleanup() {
    rm --recursive --force "${build_dir}" 
}

trap cleanup EXIT

declare source_dir="/usr/src/googletest"

cp --recursive --target-directory="${build_dir}" "${source_dir}/"*
cd "${build_dir}"

cmake "." -DCMAKE_INSTALL_PREFIX="/usr/lib"
make --jobs="$(nproc)" install
