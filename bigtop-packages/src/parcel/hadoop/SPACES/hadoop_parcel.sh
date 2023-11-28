#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

usage() {
  echo "
usage: $0 <options>
  Required not-so-options:
     --install-path=INSTALL_PATH     path to install dir 
     --root-dir=ROOT_DIR             path to root dir 
     --stack-version=STACK_VERSION   stack version
     --build-number=BUILD_NUMBER     build number
     --pkg-version=PKG_VERSION       pkg version
  "
  exit 1
}

OPTS=$(getopt \
  -n $0 \
  -o '' \
  -l 'root-dir:' \
  -l 'stack-version:' \
  -l 'pkg-version:' \
  -l 'build-number:' \
  -l 'install-path:' -- "$@")

if [ $? != 0 ] ; then
    usage
fi

eval set -- "$OPTS"
while true ; do
    case "$1" in
        --install-path)
        INSTALL_PATH=$2 ; shift 2
        ;;
        --stack-version)
        STACK_VERSION=$2 ; shift 2
        ;;
        --pkg-version)
        PKG_VERSION=$2 ; shift 2
        ;;
        --build-number)
        BUILD_NUMBER=$2 ; shift 2
        ;;
        --root-dir)
        ROOT_DIR=$2 ; shift 2
        ;;
        --)
        shift ; break
        ;;
        *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
done

for var in ROOT_DIR INSTALL_PATH; do
  if [ -z "$(eval "echo \$$var")" ]; then
    echo Missing param: $var
    usage
  fi
done

# Parameter define
PKG_NAME="hadoop"
etc_default="/etc/default"
# TODO: hadoop home dir
usr_lib_hadoop="${INSTALL_PATH}/${PKG_NAME}"
etc_hadoop_conf_dist="${INSTALL_PATH}/etc/${PKG_NAME}/conf.dist"

bin_dir="${usr_lib_hadoop}/bin"
man_dir="${usr_lib_hadoop}/man"
doc_dir="${usr_lib_hadoop}/doc"
include_dir="/usr/include"
lib_dir="/usr/lib"
doc_hadoop="${doc_dir}"

# For examples: ROOT_DIR = /ws/bigtop/build/hadoop/parcel
PARCEL_SOURCE_DIR="${ROOT_DIR}/SOURCES"
SPARCE_TARGET_DIR="${ROOT_DIR}/PARCELS"
PARCEL_BUILD_ROOT="${ROOT_DIR}/BUILD"
PARCEL_INSTALL_PREFX="${ROOT_DIR}/INSTALL"

# Build
file_name=$PKG_NAME-$PKG_VERSION.tar.gz
tar -zxvf $PARCEL_SOURCE_DIR/$file_name -C $PARCEL_BUILD_ROOT 
pushd $PARCEL_BUILD_ROOT/$PKG_NAME-$PKG_VERSION-src 
bash $PARCEL_SOURCE_DIR/do-component-build
popd

# Install
rm -rf "$PARCEL_INSTALL_PREFX/*"
# pushd $PARCEL_BUILD_ROOT/$PKG_NAME-$PKG_VERSION-src 
# bash $PARCEL_SOURCE_DIR/install_hadoop.sh \
#           --build-dir=build \
#           --prefix=$PARCEL_INSTALL_PREFX \
#           --doc-dir=${doc_hadoop} \
#           --lib-dir=${usr_lib_hadoop} \
#           --bin-dir=${bin_dir} \
#           --man-dir=${man_dir} \
#           --conf-dist-dir=${etc_hadoop_conf_dist} \
#           --etc-default=${etc_default} \
#           --system-include-dir=${include_dir} \
#           --system-lib-dir=${lib_dir}
# popd

# Generate parcel pkg
# tar -czvf $SPARCE_TARGET_DIR/"$PKG_NAME"_"$PKG_VERSION"-"$STACK_VERSION".parcel  -C $PARCEL_INSTALL_PREFX .

# Docker build image
# Note: That podman needs to be run as a non-root user
# pushd "$PARCEL_INSTALL_PREFX"
# IMAGE_VERSION=$PKG_VERSION-$STACK_VERSION-$BUILD_NUMBER
# podman build -t midtao/hadoop:$PKG_VERSION.$STACK_VERSION -f $PARCEL_SOURCE_DIR/Dockerfile .
# podman push midtao/hadoop:$PKG_VERSION.$STACK_VERSION
# popd