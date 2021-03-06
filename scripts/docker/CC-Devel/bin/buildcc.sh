#!/usr/bin/env bash

set -e

function usage() {
    cat <<EOF
${0} [-h]
${0} [-i <image>] [-s <source directory>] [-o <output directory>]
  -h  Print this usage information. Optional.
  -i  Image name of the container that this script will be run. If not specified
      then "compass-devel" used as default.
  -s  Directory of CodeCompass source. If not specified this option
      CC_SOURCE environment variable will be used. If any of them not specified,
      this script uses the root directory of this git repository as Compass
      source.
  -o  Directory of generated output artifacts. If not specified then
      CC_BUILD environment variable will be used. Any of them
      is mandatory.
EOF
}

cc_source_dir="${CC_SOURCE}"
cc_output_dir="${CC_BUILD}"
image_name="compass-devel"
while getopts "hi:o:s:" option; do
    case ${option} in
        h)
            usage
            exit 0
            ;;
        i)
            image_name="${OPTARG}"
            ;;
        o)
            cc_output_dir="${OPTARG}"
            ;;
        s)
            cc_source_dir="${OPTARG}"
            ;;
        *)
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "${cc_source_dir}" ]]; then
    echo "CodeCompass source directory should be defined." >&2
    usage >&2
    exit 2
fi
declare cc_source_dir
cc_source_dir=$(readlink --canonicalize-existing --verbose "${cc_source_dir}")
readonly cc_source_dir

if [[ -z "${cc_output_dir}" ]]; then
    echo "Output directory of build should be defined." >&2
    usage >&2
    exit 3
fi
declare cc_output_dir
cc_output_dir=$(readlink --canonicalize-existing --verbose                     \
    "${cc_output_dir}")
readonly cc_output_dir

declare developer_id
developer_id="$(id --user)"
readonly developer_id
declare developer_group
developer_group="$(id --group)"
readonly developer_group

if [[ "${developer_id}" -eq 0 ]] || [[ "${developer_group}" -eq 0 ]]; then
    echo "'${0}' should not run as root." >&2
    exit 4
fi

declare script_dir
script_dir=$(readlink --canonicalize-existing --verbose                       \
    "$(dirname "$(command -v "${0}")")")
mkdir --parents "${cc_output_dir}"
declare -r cc_source_mounted="/mnt/cc_source"
declare -r cc_output_mounted="/mnt/cc_output"
declare -r cc_peer_target_dir="/opt/cc/bin"
declare cc_peer_source_dir
cc_peer_source_dir=$(readlink --canonicalize-existing                         \
    --verbose "${script_dir}/../peer")
readonly cc_peer_source_dir
docker_command=("docker" "run" "--rm"                                          \
  "--user=${developer_id}:${developer_group}"                                  \
  "--mount" "type=bind,source=${cc_source_dir},target=${cc_source_mounted}"    \
  "--mount" "type=bind,source=${cc_output_dir},target=${cc_output_mounted}"    \
  "--mount"                                                                    \
  "type=bind,source=${cc_peer_source_dir},target=${cc_peer_target_dir}"        \
  "${image_name}" "${cc_peer_target_dir}/buildcompass.sh"                      \
  "${cc_output_mounted}")

if [[ "$(id -nG "${USER}")" == *"docker"* ]] || [[ -n "${DOCKER_HOST}" ]]; then
    "${docker_command[@]}"
else
    sudo "${docker_command[@]}"
fi
