#!/usr/bin/env bash

set -e

function usage() {
    cat <<EOF
${0}
    Options:
        <Directory of CodeCompass source>
        <Output directory>
        <Build type>
        <Database type>
        <Verbose build>
EOF
}

if [[ -z "${5}" ]]; then
    echo "Mandatory options is not specified." >&2
    usage >&2
    exit 1
fi

if [[ -n "${6}" ]]; then
    echo "Too many options." >&2
    usage >&2
    exit 2
fi

CODE_COMPASS_SRC_DIR=$(readlink --canonicalize-existing --verbose "${1}")
CODE_COMPASS_OUTPUT_DIR=$(readlink --canonicalize-existing --verbose "${2}")
CODE_COMPASS_BUILD_TYPE="${3}"
CODE_COMPASS_DATABASE_TYPE="${4}"
LET_THE_BUILD_VERBOSE="${5}"

CODE_COMPASS_BUILD_DIR="${CODE_COMPASS_OUTPUT_DIR}/build"
CODE_COMPASS_INSTALL_DIR="${CODE_COMPASS_OUTPUT_DIR}/install"

mkdir "${CODE_COMPASS_BUILD_DIR}"
mkdir "${CODE_COMPASS_INSTALL_DIR}"

SCRIPT_DIR=$(readlink --canonicalize-existing --verbose                        \
    "$(dirname "$(command -v "${0}")")")
source "${SCRIPT_DIR}/builder_config.sh"

cd "${CODE_COMPASS_BUILD_DIR}"

cmake "${CODE_COMPASS_SRC_DIR}"                                                \
  "-DCMAKE_INSTALL_PREFIX=${CODE_COMPASS_INSTALL_DIR}"                         \
  "-DDATABASE=${CODE_COMPASS_DATABASE_TYPE}"                                   \
  "-DCMAKE_BUILD_TYPE=${CODE_COMPASS_BUILD_TYPE}"                              \
  "-DLLVM_DIR=/usr/lib/llvm-10/cmake"                                          \
  "-DClang_DIR=/usr/lib/cmake/clang-10"                                        \
  "-DCMAKE_VERBOSE_MAKEFILE:BOOL=${LET_THE_BUILD_VERBOSE}"

# TODO: Later the CodeCompass should be compiled with clang.
#  "-DCMAKE_C_COMPILER_ID=Clang" \
#  "-DCMAKE_CXX_COMPILER_ID=Clang" \
#  "-DCMAKE_C_COMPILER=clang" \
#  "-DCMAKE_CXX_COMPILER=clang++"
