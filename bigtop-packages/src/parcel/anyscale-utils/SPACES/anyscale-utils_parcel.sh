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

lib_dir=/usr/lib/bigtop-utils
plugins_dir=/var/lib/bigtop

# For
PARCELS_DIR="${ROOT_DIR}/PARCELS"
SPARCELS_DIR="${ROOT_DIR}/SPARCELS"
PARCEL_SOURCE_DIR="${ROOT_DIR}/SOURCES"
PARCEL_SPACES_DIR="${ROOT_DIR}/SPACES"
PARCEL_BUILD_ROOT="${ROOT_DIR}/BUILD"
PARCEL_INSTALL_PREFX="${ROOT_DIR}/INSTALL"

# Build
tar -zxvf $SPARCELS_DIR/${PKG_NAME}*-$PKG_VERSION.$STACK_VERSION-$BUILD_NUMBER.src.parcel -C $PARCEL_BUILD_ROOT  

# Install
pushd $PARCEL_BUILD_ROOT
install -d -p -m 755 $PARCEL_INSTALL_PREFX${plugins_dir}/
install -d -p -m 755 $PARCEL_INSTALL_PREFX${lib_dir}/
install -d -p -m 755 $PARCEL_INSTALL_PREFX/etc/default
install -p -m 755 bigtop-detect-javahome $PARCEL_INSTALL_PREFX${lib_dir}/
install -p -m 755 bigtop-detect-javalibs $PARCEL_INSTALL_PREFX${lib_dir}/
install -p -m 755 bigtop-detect-classpath $PARCEL_INSTALL_PREFX${lib_dir}/
install -p -m 755 bigtop-monitor-service $PARCEL_INSTALL_PREFX${lib_dir}/
install -p -m 644 bigtop-utils.default $PARCEL_INSTALL_PREFX/etc/default/bigtop-utils
popd

# Generate parcel pkg
PARCEL_VERSION=$PKG_VERSION-$STACK_VERSION-$BUILD_NUMBER
tar -czvf $PARCELS_DIR/anyscale-utils_$PARCEL_VERSION.parcel  -C $PARCEL_INSTALL_PREFX .

# Docker build image
# Note: That docker needs to be run as a root user
pushd "$PARCEL_INSTALL_PREFX"
if [ -n "$DOCKER_CREDENTIALS" ]; then
  docker build -t hetudb/anyscale-utils:$PARCEL_VERSION -f $PARCEL_SPACES_DIR/Dockerfile .
  echo ${DOCKER_CREDENTIALS} | docker login -u ${DOCKER_USER} --password-stdin
  docker push hetudb/anyscale-utils:$PARCEL_VERSION
fi
popd

# Clean build generate temp dir.
rm -rf $PARCEL_BUILD_ROOT/*
rm -rf $PARCEL_INSTALL_PREFX/* 