#!/usr/bin/env bash

set -e

function usage() {
    cat <<EOF
${0}
    Options:
        <Output directory of CodeCompass build>
EOF
}

if [[ -z "${1}" ]]; then
    echo "Mandatory options is not specified." >&2
    usage >&2
    exit 1
fi

if [[ -n "${2}" ]]; then
    echo "Too many options." >&2
    usage >&2
    exit 2
fi

CODE_COMPASS_OUTPUT_DIR=$(readlink --canonicalize-existing --verbose "${1}")
CODE_COMPASS_BUILD_DIR="${CODE_COMPASS_OUTPUT_DIR}/build"

SCRIPT_DIR=$(readlink --canonicalize-existing --verbose                        \
    "$(dirname "$(command -v "${0}")")")
source "${SCRIPT_DIR}/builder_config.sh"

cd "${CODE_COMPASS_BUILD_DIR}"
cmake --build . -- --jobs "$(nproc)"
make install
