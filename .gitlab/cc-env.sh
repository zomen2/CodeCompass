#!/bin/bash
# SOURCE THIS FILE!

PS1_ORIG=$PS1

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P)"
DEPS_INSTALL_DIR=$ROOT_DIR/deps-runtime
CC_INSTALL_DIR=$ROOT_DIR/cc-install

export LD_LIBRARY_PATH=$DEPS_INSTALL_DIR/libgit2-install/lib64\
:$DEPS_INSTALL_DIR/openssl-install/lib\
:$DEPS_INSTALL_DIR/graphviz-install/lib\
:$DEPS_INSTALL_DIR/libmagic-install/lib\
:$DEPS_INSTALL_DIR/boost-install/lib\
:$DEPS_INSTALL_DIR/odb-install/lib\
:$DEPS_INSTALL_DIR/thrift-install/lib\
:$DEPS_INSTALL_DIR/llvm-install/lib\
:$DEPS_INSTALL_DIR/libtool-install/lib\
:$DEPS_INSTALL_DIR/postgresql-install/lib\
:$LD_LIBRARY_PATH

export PATH=$DEPS_INSTALL_DIR/jdk-install/bin\
:$DEPS_INSTALL_DIR/ctags-install/bin\
:$DEPS_INSTALL_DIR/python-install/bin\
:$DEPS_INSTALL_DIR/node-install/bin\
:$CC_INSTALL_DIR/bin\
:$PATH

export MAGIC=$DEPS_INSTALL_DIR/libmagic-install/share/misc/magic.mgc
export JAVA_HOME=$DEPS_INSTALL_DIR/jdk-install

if [ -f $ROOT_DIR/ccdb-tool/venv/bin/activate ]; then
  source $ROOT_DIR/ccdb-tool/venv/bin/activate
else
  pushd $ROOT_DIR/ccdb-tool
  # install venv
  python3 -m pip install virtualenv
  # create venv
  make venv
  source venv/bin/activate
  # build ccdb-tool
  make package
  popd
fi

export PS1="(cc-env) $PS1_ORIG"
