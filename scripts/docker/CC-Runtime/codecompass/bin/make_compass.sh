#!/usr/bin/env bash

COMPASS_INSTALL_DIR="/opt/CodeCompass"

set -e

function usage() {
cat << EOF
${0}
    -h Print this message.
EOF
}

if [[ ! -z "${1}" ]]; then
    if [[ "${1}" == "-h" ]]; then
        usage
        exit 0
    else
        echo "Unknown option(s)." >&2
        usage
        exit 1
    fi
fi

scriptdir=$(readlink -ev "$(dirname "$(which "$0")")")

COMPASS_SRC_DIR="/tmp/Compass.main"
COMPASS_OUTPUT_DIR="/tmp/Compass.build"

mkdir -p "${COMPASS_SRC_DIR}"
mkdir -p "${COMPASS_OUTPUT_DIR}"

configurecc.sh "${COMPASS_SRC_DIR}" "${COMPASS_OUTPUT_DIR}" "Release"
buildcc.sh "${COMPASS_SRC_DIR}" "${COMPASS_OUTPUT_DIR}"

mv "${COMPASS_OUTPUT_DIR}/install" "${COMPASS_INSTALL_DIR}"
