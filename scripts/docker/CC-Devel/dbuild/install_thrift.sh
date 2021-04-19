#!/usr/bin/env bash

set -e

function cleanup() {
    echo "Cleaning up Thrift temporaries."
    if  [[ -n "${thrift_build_dir}" ]]; then
        rm --recursive --force "${thrift_build_dir}"
    fi
}

trap cleanup EXIT

function usage() {
    cat <<EOF
${0} [-h] -t <thrift version> [-d <install dir>]
  -h  Print this usage information. Optional.
  -d  Install directory of thrift. Optional. "/opt/thrift" is the default.
      On Ubuntu 20.04 and newer, thrift packages are part of distribution, so
      on these versions this parameter has no effect.
  -j  Directory where jar files of thrift-java will be installed. Optional.
     If not defined then Jars are placed in standard place of the distro.
     ("/usr/share/lib") as thrift-java would be a supported package.
      On older ubuntu release(s) the java jars are placed in
      "<thrift lib dir>/java". So the compass makefile will search them from
      it.
  -t  Thrift version. Mandatory. For example '0.13.0'.
EOF
}

function downloadThriftSource() {
    mkdir --parents "${thrift_src_dir}"
    wget --no-verbose --show-progress                                          \
      "http://xenia.sote.hu/ftp/mirrors/www.apache.org/thrift/\
${thrift_version}/${thrift_archive_dir}"                                       \
        --output-document="${thrift_build_dir}/${thrift_archive_dir}"
    tar --extract --gunzip --file="${thrift_build_dir}/${thrift_archive_dir}"  \
        --directory="${thrift_src_dir}" --strip-components=1
    rm "${thrift_build_dir}/${thrift_archive_dir}"

    # Workaround: Maven repository access allowed by https only.
    sed --expression='s,http://repo1.maven.org,https://repo1.maven.org,'       \
        --in-place "${thrift_src_dir}/lib/java/gradle.properties"
}

function configureThrift() {
    configure_cmd=("./configure" "--prefix=${thrift_install_dir}"              \
      "--enable-libtool-lock" "--enable-tutorial=no" "--enable-tests=no"       \
      "--with-libevent" "--with-zlib" "--without-nodejs" "--without-lua"       \
      "--without-ruby" "--without-csharp" "--without-erlang" "--without-perl"  \
      "--without-php" "--without-php_extension" "--without-dart"               \
      "--without-haskell" "--without-go" "--without-rs" "--without-haxe"       \
      "--without-dotnetcore" "--without-d" "--without-qt4" "--without-qt5"     \
      "--without-python" "--without-java")

    "${configure_cmd[@]}"
}

function makeAndInstallJavaJars() {
    pushd "${thrift_java_src_dir}"
    ./gradlew assemble
    # Install java components by hand
    mkdir --parents "${java_lib_install_dir}"
    # Why this strange name the build output has?
    mv "${thrift_java_src_dir}/build/libs/libthrift-${thrift_version}-\
SNAPSHOT.jar"                                                                  \
      "${java_lib_install_dir}/libthrift-${thrift_version}.jar"
    mv "${thrift_java_src_dir}/build/deps/"*.jar "${java_lib_install_dir}"
    popd
}

function makeAndInstallCppDevel() {
    pushd "${thrift_src_dir}"
    configureThrift
    make --jobs="$(nproc)" install
    popd
}

declare thrift_install_dir="/opt/thrift"
declare java_lib_install_dir
while getopts "hd:j:t:" OPTION; do
    case ${OPTION} in
        h)
            usage
            exit 0
            ;;
        d)
            thrift_install_dir="${OPTARG}"
            ;;
        j)
            java_lib_install_dir="${OPTARG}"
            ;;
        t)
            thrift_version="${OPTARG}"
            ;;
        *)
            usage >&2
            exit 1
            ;;
    esac
done

declare running_ubuntu_codename
running_ubuntu_codename="$(lsb_release --codename --short)"
readonly running_ubuntu_codename

if [[ "${running_ubuntu_codename}" != "focal" ]] && \
   [[ "${running_ubuntu_codename}" != "bionic" ]]; then
    echo "Unsupported ubuntu release" 2>&1
    exit 1
fi

if [[ -z "${thrift_version}" ]]; then
    echo "Thrift version should be defined." >&2
    usage
    exit 2
fi

if [[ -z "${java_lib_install_dir}" ]]; then
    if [[ "${running_ubuntu_codename}" == "bionic" ]]; then
	    java_lib_install_dir="${thrift_install_dir}/java"
    else
	    java_lib_install_dir="/usr/share/java"
    fi
fi
readonly java_lib_install_dir

declare -r thrift_archive_dir="thrift-${thrift_version}.tar.gz"

declare thrift_build_dir
thrift_build_dir=$(mktemp -d -t "thriftbuild_XXXXXXXX")
declare -r thrift_src_dir="${thrift_build_dir}/thrift"
declare -r thrift_java_src_dir="${thrift_src_dir}/lib/java"

downloadThriftSource

if [[ "${running_ubuntu_codename}" == "focal" ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get install --yes                       \
        "libthrift-dev" "thrift-compiler"
else
    makeAndInstallCppDevel
    java_lib_install_dir=$(PKG_CONFIG_PATH="${thrift_install_dir}"\
"/lib/pkgconfig" pkg-config --variable=libdir thrift)
fi

makeAndInstallJavaJars
