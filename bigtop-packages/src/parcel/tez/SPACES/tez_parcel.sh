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
PKG_NAME="tez"

usr_lib_tez=${INSTALL_PATH}/${PKG_NAME}
etc_tez=${INSTALL_PATH}/etc/${PKG_NAME}

usr_lib_hadoop=${INSTALL_PATH}/hadoop

bin_dir="${usr_lib_tez}/bin"
man_dir="${usr_lib_tez}/man"
doc_dir="${usr_lib_tez}/doc"

# No prefix directory
np_var_log_tez=/var/log/${PKG_NAME}
np_var_run_tez=/var/run/${PKG_NAME}
np_etc_tez=/etc/${PKG_NAME}

doc_tez=${doc_dir}/${PKG_NAME}-${PKG_VERSION}

# For examples: ROOT_DIR = /ws/anypkg/build/hadoop/parcel
PARCELS_DIR="${ROOT_DIR}/PARCELS"
SPARCELS_DIR="${ROOT_DIR}/SPARCELS"
PARCEL_SOURCE_DIR="${ROOT_DIR}/SOURCES"
PARCEL_BUILD_ROOT="${ROOT_DIR}/BUILD"
PARCEL_INSTALL_PREFX="${ROOT_DIR}/INSTALL"

# Build
tar -zxvf $SPARCELS_DIR/${PKG_NAME}*-$PKG_VERSION.$STACK_VERSION-$BUILD_NUMBER.src.parcel -C $PARCEL_BUILD_ROOT  
file_name=apache-$PKG_NAME-$PKG_VERSION-src.tar.gz
tar -zxvf $PARCEL_BUILD_ROOT/$file_name -C $PARCEL_BUILD_ROOT 

pushd $PARCEL_BUILD_ROOT/apache-$PKG_NAME-$PKG_VERSION-src 
## Prep: patch
cp -r ../patch*.diff . 
#BIGTOP_PATCH_COMMANDS

## Compile
bash ../do-component-build
popd

# Install
rm -rf $PARCEL_INSTALL_PREFX/*
pushd $PARCEL_BUILD_ROOT/apache-$PKG_NAME-$PKG_VERSION-src 
cp -r $PARCEL_SOURCE_DIR/tez.1 $PARCEL_SOURCE_DIR/tez-site.xml .
bash ../install_tez.sh\
    --build-dir=. \
    --prefix=$PARCEL_INSTALL_PREFX \
    --man-dir=${man_dir} \
    --doc-dir=${doc_tez} \
    --lib-dir=${usr_lib_tez} \
    --etc-tez=${etc_tez}
popd

rm -f $PARCEL_BUILD_ROOT/${usr_lib_tez}/lib/slf4j-log4j12-*.jar
# TODO: move to docker build
#ln -s -f ${usr_lib_hadoop}/hadoop-annotations-*.jar $PARCEL_BUILD_ROOT/${usr_lib_tez}/lib/hadoop-annotations.jar
#ln -s -f ${usr_lib_hadoop}/hadoop-auth-*.jar $PARCEL_BUILD_ROOT/${usr_lib_tez}/lib/hadoop-auth.jar
#ln -s -f ${usr_lib_hadoop}-mapreduce/hadoop-mapreduce-client-common-*.jar $PARCEL_BUILD_ROOT/${usr_lib_tez}/lib/hadoop-mapreduce-client-common.jar
#ln -s -f ${usr_lib_hadoop}-mapreduce/hadoop-mapreduce-client-core-*.jar $PARCEL_BUILD_ROOT/${usr_lib_tez}/lib/hadoop-mapreduce-client-core.jar
#ln -s -f ${usr_lib_hadoop}-yarn/hadoop-yarn-server-web-proxy-*.jar $PARCEL_BUILD_ROOT/${usr_lib_tez}/lib/hadoop-yarn-server-web-proxy.jar

PARCEL_VERSION=$PKG_VERSION-$STACK_VERSION-$BUILD_NUMBER

# Generate parcel pkg
tar -czvf $PARCELS_DIR/tez_$PARCEL_VERSION.parcel  -C $PARCEL_INSTALL_PREFX .

# Docker build image