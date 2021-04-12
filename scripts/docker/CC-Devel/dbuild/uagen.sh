#!/usr/bin/env bash

set -e

function print_usage()
{
    cat <<_END_
Clang/Llvm alternatives generator program.

It collects installed Clang/Llvm components and generates shell script what
registers components into the "alternatives system".

Usage:
$(basename "$0") -h
$(basename "$0") [-p <priority in system>] -v <clang version>
_END_
}

while getopts "hp:v:" Option; do
    case "$Option" in
    h)
        print_usage
        exit 0
        ;;
    p)
        priority="${OPTARG}"
        ;;
    v)
        clang_version="${OPTARG}"
        ;;
    *)
        print_usage >&2
        exit 1
    esac
done
shift "$((OPTIND - 1))"

if [[ -z ${clang_version} ]]; then
    echo "Missing Clang/Llvm version number." >&2
    print_usage >&2
    exit 1
fi

if [[ -z "${priority}" ]]; then
    priority=50
fi

declare script_dir
script_dir=$(readlink --canonicalize-existing --verbose                        \
    "$(dirname "$(command -v "$0")")")
readonly script_dir

# Identify all clang files
declare -r clang_filter='^.\+clang+*-.*'${clang_version}'.*$'
declare clang_files
clang_files=$(find /usr/bin -maxdepth 1 -regextype sed                         \
    -regex "${clang_filter}" | sort)

# Choose clang program, because it gives name of the alternative group
declare -r group_pattern="clang-${clang_version}"
declare clang_prog
clang_prog=$(grep "${group_pattern}" <<<"${clang_files}")
readonly clang_prog

# Remove clang from the list of clang group
clang_files=$(grep --invert-match "${group_pattern}" <<<"${clang_files}")
readonly clang_files

# Identify all files of llvm
declare -r llvm_filter='llvm-*'${clang_version}'*'
declare llvm_files
llvm_files=$(find /usr/bin -maxdepth 1 -name "${llvm_filter}" | sort)
readonly llvm_files

# Generate clang group registrator script
declare -r clang_registrator_prog="${script_dir}/reg-clang.sh"
# All clang related program is in the list. clang is at the top of the list.
echo -e "${clang_prog}\n${clang_files}\n${llvm_files}" |                       \
    awk -v priority=${priority} -f "${script_dir}/uagen.awk"  >                \
        "${clang_registrator_prog}"
chmod +x "${clang_registrator_prog}"

echo "'${clang_registrator_prog}' generated."
