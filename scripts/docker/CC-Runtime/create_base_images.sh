#!/usr/bin/env bash

set -e

function usage() {
cat << EOF
Create base Docker images of CodeCompass runtime. 

${0}
    -h  Print this usage information. Optional.
    Additional positional arguments for "docker build" command. For example:
        $(basename "$0") --build-arg "http_proxy=1.2.3.4"
EOF
}

function call_docker() {
    local command=("${@}")

    if [[ "$(id --name --groups)" == *"docker"* ]]                             \
       ||                                                                      \
       [[ ! -z ${DOCKER_HOST} ]]; then
        "${command[@]}"
    else
        sudo "${command[@]}"
    fi
}

if [[ ! -z "${1}" ]]; then
    if [[ "${1}" == "-h" ]]; then
        usage
        exit 0
    else
        additional_build_arguments=("$@")
    fi
fi

script_dir=$(readlink -ev "$(dirname "$(which "${0}")")")
docker_context_dir=$(cd ${script_dir} && git rev-parse --show-toplevel)
compass_docker_file="${script_dir}/codecompass/Dockerfile"
parser_docker_file="${script_dir}/ccparser/Dockerfile"
docker_command="$(which docker)"

# Create an ubuntu 16.04 container with installed CodeCompass software.
build_command=("${docker_command}" "build" "--tag" "codecompass")

if [[ ${#additional_build_arguments[@]} > 0 ]]; then
    build_command+=(${additional_build_arguments[@]})
fi

build_command+=("--file" "${compass_docker_file}" "${docker_context_dir}")

call_docker "${build_command[@]}"

# Create image as base image of CC parsers.
build_command=("${docker_command}" "build" "--tag" "ccparser")

if [[ ${#additional_build_arguments[@]} > 0 ]]; then
    build_command+=(${additional_build_arguments[@]})
fi

build_command+=("--file" "${parser_docker_file}" "${docker_context_dir}")

call_docker "${build_command[@]}"

# Create ".env" file for docker-compose command.
cat << EOF > "${script_dir}/.env"
user_id=$(id --user)
group_id=$(id --group)
EOF

compose_command="$(which docker-compose)"
yaml_file="${script_dir}/docker-compose.yaml"

cd "${script_dir}"
# Create whole leaf images of the networked application.
pull_command=("${compose_command}" "-f" "${yaml_file}" "pull" "db" "dbadmin")     
call_docker "${pull_command[@]}"

build_command=("${compose_command}" "-f" "${yaml_file}" "build")
call_docker "${build_command[@]}"

