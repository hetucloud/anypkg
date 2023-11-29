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
etc_default=${INSTALL_PATH}/etc/default
usr_lib_hadoop=${INSTALL_PATH}/${PKG_NAME}
usr_lib_hdfs=${INSTALL_PATH}/${PKG_NAME}-hdfs
usr_lib_yarn=${INSTALL_PATH}/${PKG_NAME}-yarn
usr_lib_mapreduce=${INSTALL_PATH}/${PKG_NAME}-mapreduce
var_lib_hdfs=${INSTALL_PATH}/${PKG_NAME}-hdfs
var_lib_mapreduce=${INSTALL_PATH}/${PKG_NAME}-mapreduce
var_lib_httpfs=${INSTALL_PATH}/${PKG_NAME}-httpfs
var_lib_kms=${INSTALL_PATH}/${PKG_NAME}-kms
etc_hadoop_conf_dist=${INSTALL_PATH}/etc/${PKG_NAME}/conf.dist

usr_lib_zookeeper=${INSTALL_PATH}/zookeeper

bin_dir="${usr_lib_hadoop}/bin"
man_dir="${usr_lib_hadoop}/man"
doc_dir="${usr_lib_hadoop}/doc"
include_dir="${INSTALL_PATH}/include"
lib_dir="${INSTALL_PATH}/lib"
doc_hadoop="${doc_dir}"

# No prefix directory
np_var_log_yarn=/var/log/${PKG_NAME}-yarn
np_var_log_hdfs=/var/log/${PKG_NAME}-hdfs
np_var_log_httpfs=/var/log/${PKG_NAME}-httpfs
np_var_log_kms=/var/log/${PKG_NAME}-kms
np_var_log_mapreduce=/var/log/${PKG_NAME}-mapreduce
np_var_run_yarn=/var/run/${PKG_NAME}-yarn
np_var_run_hdfs=/var/run/${PKG_NAME}-hdfs
np_var_run_httpfs=/var/run/${PKG_NAME}-httpfs
np_var_run_kms=/var/run/${PKG_NAME}-kms
np_var_run_mapreduce=/var/run/${PKG_NAME}-mapreduce
np_etc_hadoop=/etc/${PKG_NAME}

# For examples: ROOT_DIR = /ws/anypkg/build/hadoop/parcel
PARCELS_DIR="${ROOT_DIR}/PARCELS"
SPARCELS_DIR="${ROOT_DIR}/SPARCELS"
PARCEL_SOURCE_DIR="${ROOT_DIR}/SOURCES"
PARCEL_BUILD_ROOT="${ROOT_DIR}/BUILD"
PARCEL_INSTALL_PREFX="${ROOT_DIR}/INSTALL"

# Build
tar -zxvf $SPARCELS_DIR/${PKG_NAME}*-$PKG_VERSION.$STACK_VERSION-$BUILD_NUMBER.src.parcel -C $PARCEL_BUILD_ROOT  
file_name=$PKG_NAME-$PKG_VERSION.tar.gz
tar -zxvf $PARCEL_BUILD_ROOT/$file_name -C $PARCEL_BUILD_ROOT 

pushd $PARCEL_BUILD_ROOT/$PKG_NAME-$PKG_VERSION-src 
## Prep: patch
cp -r ../patch*.diff . 
#BIGTOP_PATCH_COMMANDS

## Compile
bash ../do-component-build
popd

# Install
rm -rf $PARCEL_INSTALL_PREFX/*
pushd $PARCEL_BUILD_ROOT/$PKG_NAME-$PKG_VERSION-src 
bash ../install_hadoop.sh \
  --distro-dir=$PARCEL_SOURCE_DIR \
  --build-dir=$PWD/build \
  --prefix=$PARCEL_INSTALL_PREFX \
  --doc-dir=${doc_hadoop} \
  --bin-dir=${bin_dir} \
  --man-dir=${man_dir} \
  --etc-default=${etc_default} \
  --hadoop-dir=${usr_lib_hadoop} \
  --hdfs-dir=${usr_lib_hdfs} \
  --yarn-dir=${usr_lib_yarn} \
  --mapreduce-dir=${usr_lib_mapreduce} \
  --var-hdfs=${var_lib_hdfs} \
  --var-yarn=${var_lib_uarn} \
  --var-mapreduce=${var_lib_mapreduce} \
  --var-httpfs=${var_lib_httpfs} \
  --var-kms=${var_lib_kms} \
  --system-include-dir=${include_dir} \
  --system-lib-dir=${lib_dir} \
  --etc-hadoop=${etc_hadoop}
popd

# Forcing Zookeeper dependency to be on the packaged jar
# TODO ln -s ${usr_lib_zookeeper}/zookeeper.jar $PARCEL_BUILD_ROOT/${usr_lib_hadoop}/lib/zookeeper-[[:digit:]]*.jar

PARCEL_VERSION=$PKG_VERSION-$STACK_VERSION-$BUILD_NUMBER

# Generate parcel pkg
tar -czvf $PARCELS_DIR/hadoop_$PARCEL_VERSION.parcel  -C $PARCEL_INSTALL_PREFX .

# Docker build image