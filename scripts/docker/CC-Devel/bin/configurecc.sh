#!/usr/bin/env bash

set -e

function usage() {
    cat <<EOF
${0} [-h]
${0} [-i <image>] [-d <db type>] [-o <output directory>] [-s <source directory>] [-t <build type>]
  -h  Print this usage information. Optional.
  -d  Database type. [sqlite | pgsql] Optional. If not specified then
      CC_DATABASE_TYPE will be used. If neither this option nor environment
      variable are specified then sqlite will be used as default.
  -i  Image name of the container that this script will be run. If not specified
      then "compass-devel" used as default.
  -o  Directory of generated output artifacts. If not specified then
      CC_BUILD environment variable will be used. Any of them
      is mandatory.
  -s  Directory of CodeCompass source. If not specified this option
      CC_SOURCE environment variable will be used. If any of them not specified,
      this script uses the root directory of this git repository as Compass
      source.
  -t  Build type. Optional.
      It can be: Debug; Release; RelWithDebInfo; MinSizeRel
      If not specified then CC_BUILD_TYPE environment variable will
      be used. If not defined then Release will be used.
  -v  Let the build verbose.
EOF
}

cc_source_dir="${CC_SOURCE}"
cc_output_dir="${CC_BUILD}"
cc_build_type="${CC_BUILD_TYPE}"
cc_database_type="${CC_DATABASE_TYPE}"
image_name="compass-devel"
verbose_build="OFF"
while getopts "hd:i:s:o:t:v" option; do
    case ${option} in
        h)
            usage
            exit 0
            ;;
        d)
            cc_database_type="${OPTARG}"
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
        t)
            cc_build_type="${OPTARG}"
            ;;
        v)
            verbose_build="ON"
            ;;            
        *)
            usage >&2
            exit 1
            ;;
    esac
done
readonly verbose_build

if [[ -z "${cc_build_type}" ]]; then
    cc_build_type="Release"
fi
readonly cc_build_type

if [[ "${cc_build_type}" != "Debug" ]]                                         \
   && [[ "${cc_build_type}" != "Release" ]]                                    \
   && [[ "${cc_build_type}" != "RelWithDebInfo" ]]                             \
   && [[ "${cc_build_type}" != "MinSizeRel" ]]; then
    echo "Unknown build type: '${cc_build_type}'." >&2
    usage >&2
    exit 2
fi

if [[ "${cc_database_type}" != "sqlite" ]]                                     \
   && [[ "${cc_database_type}" != "pgsql" ]]; then
    echo "Unknown database type: '${cc_database_type}'." >&2
    usage >&2
    exit 3
fi

declare script_dir
script_dir=$(readlink --canonicalize-existing --verbose                       \
    "$(dirname "$(command -v "${0}")")")
readonly script_dir
if [[ -z "${cc_source_dir}" ]]; then
    cc_source_dir=$(
        set +e
        cd "${script_dir}"
        git rev-parse --show-toplevel
    )

    if [[ ! $? ]]; then
        echo "CodeCompass source directory should be defined." >&2
        usage >&2
        exit 4
    fi
fi
cc_source_dir=$(readlink --canonicalize-existing --verbose "${cc_source_dir}")
readonly cc_source_dir

if [[ -z "${cc_output_dir}" ]]; then
    echo "Output directory of build should be defined." >&2
    usage >&2
    exit 5
fi
mkdir --parents "${cc_output_dir}"
cc_output_dir=$(readlink --canonicalize-existing --verbose "${cc_output_dir}")
readonly cc_output_dir

declare developer_id
developer_id="$(id --user)"
readonly developer_id
declare developer_group
developer_group="$(id --group)"
readonly developer_group

if [[ "${developer_id}" -eq 0 ]] || [[ "${developer_group}" -eq 0 ]]; then
    echo "'${0}' should not run as root." >&2
    exit 6
fi

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
  "${image_name}" "${cc_peer_target_dir}/configurecompass.sh"                  \
  "${cc_source_mounted}"                                                       \
  "${cc_output_mounted}" "${cc_build_type}" "${cc_database_type}"              \
  "${verbose_build}")
  
if [[ "$(id -nG "${USER}")" == *"docker"* ]] || [[ -n "${DOCKER_HOST}" ]]; then
    "${docker_command[@]}"
else
    sudo "${docker_command[@]}"
fi
