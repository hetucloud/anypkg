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
PKG_NAME="ranger"

usr_lib_ranger=${INSTALL_PATH}/${PKG_NAME}
var_lib_ranger=${INSTALL_PATH}/${PKG_NAME}
etc_ranger=${INSTALL_PATH}/etc/${PKG_NAME}
np_etc_ranger=${INSTALL_PATH}/etc/${PKG_NAME}


usr_lib_hadoop=${INSTALL_PATH}/hadoop
usr_lib_hive=${INSTALL_PATH}/hive
usr_lib_knox=${INSTALL_PATH}/knox
usr_lib_storm=${INSTALL_PATH}/storm
usr_lib_hbase=${INSTALL_PATH}/hbase
usr_lib_kafka=${INSTALL_PATH}/kafka
usr_lib_atlas=${INSTALL_PATH}/atlas
usr_lib_solr=${INSTALL_PATH}/solr
usr_lib_sqoop=${INSTALL_PATH}/sqoop
usr_lib_kylin=${INSTALL_PATH}/kylin
usr_lib_elasticsearch=${INSTALL_PATH}/elasticsearch
usr_lib_presto=${INSTALL_PATH}/presto

doc_dir="${usr_lib_ranger}/doc"

# No prefix directory
np_var_run_ranger=${INSTALL_PATH}/var/run/${PKG_NAME}

doc_ranger=${doc_dir}/${PKG_NAME}-${PKG_VERSION}

ranger_dist=build

# For
PARCELS_DIR="${ROOT_DIR}/PARCELS"
SPARCELS_DIR="${ROOT_DIR}/SPARCELS"
PARCEL_SOURCE_DIR="${ROOT_DIR}/SOURCES"
PARCEL_SPACES_DIR="${ROOT_DIR}/SPACES"
PARCEL_BUILD_ROOT="${ROOT_DIR}/BUILD"
PARCEL_INSTALL_PREFX="${ROOT_DIR}/INSTALL"

# Build
tar -zxvf $SPARCELS_DIR/${PKG_NAME}*-$PKG_VERSION.$STACK_VERSION-$BUILD_NUMBER.src.parcel -C $PARCEL_BUILD_ROOT  
file_name=$PKG_NAME-$PKG_VERSION.tar.gz
tar -zxvf $PARCEL_BUILD_ROOT/$file_name -C $PARCEL_BUILD_ROOT 

pushd $PARCEL_BUILD_ROOT/$PKG_NAME-$PKG_VERSION
## Prep: patch
#cp -r ../patch*.diff . 
#BIGTOP_PATCH_COMMANDS

## Compile
bash ../do-component-build
popd

# Install
rm -rf "$PARCEL_INSTALL_PREFX/*"
pushd $PARCEL_BUILD_ROOT/$PKG_NAME-$PKG_VERSION
for comp in admin usersync kms tagsync hdfs-plugin yarn-plugin hive-plugin hbase-plugin knox-plugin storm-plugin kafka-plugin atlas-plugin sqoop-plugin solr-plugin kylin-plugin elasticsearch-plugin presto-plugin
do
	env RANGER_VERSION=${PKG_VERSION} /bin/bash ../ranger_install.sh \
  		--prefix=$PARCEL_INSTALL_PREFX \
  		--build-dir=${ranger_dist} \
  		--component=${comp} \
        --comp-dir=${usr_lib_ranger}-${comp} \
        --var-ranger=${var_lib_ranger} \
        --etc-ranger=${etc_ranger} \
  		--doc-dir=$PARCEL_INSTALL_PREFX/${doc_ranger}
done
popd

# Generate parcel pkg
PARCEL_VERSION=$PKG_VERSION-$STACK_VERSION-$BUILD_NUMBER
tar -czvf $PARCELS_DIR/ranger_$PARCEL_VERSION.parcel  -C $PARCEL_INSTALL_PREFX .

# Docker build image
# Note: That docker needs to be run as a root user
pushd "$PARCEL_INSTALL_PREFX"
if [ -n "$DOCKER_CREDENTIALS" ]; then
  docker build -t hetudb/ranger:$PARCEL_VERSION -f $PARCEL_SPACES_DIR/Dockerfile .
  echo ${DOCKER_CREDENTIALS} | docker login -u ${DOCKER_USER} --password-stdin
  docker push hetudb/ranger:$PARCEL_VERSION
fi
popd

# Clean build generate temp dir.
rm -rf $PARCEL_BUILD_ROOT/$PKG_NAME-$PKG_VERSION
rm -rf $PARCEL_INSTALL_PREFX/* 