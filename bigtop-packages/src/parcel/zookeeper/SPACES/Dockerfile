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
FROM centos:7.9.2009

ARG STACK_VERSION
ARG BUILD_NUMBER
ARG PARCEL_VERSION

RUN echo "PARCEL_VERSION --> ${PARCEL_VERSION}"

RUN yum install java-11-openjdk-devel -y

# set java env
ENV JAVA_HOME /usr/lib/jvm/default-jvm
RUN ln -s /usr/lib/jvm/java-11-openjdk /usr/lib/jvm/default-jvm
COPY etc /etc
COPY opt /opt
COPY var /var
COPY opt/anyscale/${STACK_VERSION}-${BUILD_NUMBER}/etc/zookeeper/conf.dist /etc/zookeeper/conf

## require anyscale select && utils
COPY --from=hetudb/anyscale-select:3.3.0-3.3.0.1-1 /opt/anyscale /opt/anyscale
RUN cp -R -p /etc/zookeeper/conf /etc/zookeeper/conf.backup && rm -rf /etc/zookeeper/conf
RUN ln -s /opt/anyscale/${STACK_VERSION}-${BUILD_NUMBER}/lib/distro-select /usr/bin/anyscale-select
RUN ln -s /opt/anyscale/${STACK_VERSION}-${BUILD_NUMBER}/lib/conf-select /usr/bin/conf-select
RUN /usr/bin/anyscale-select set zookeeper-client ${STACK_VERSION}-${BUILD_NUMBER} && /usr/bin/anyscale-select set zookeeper-server ${STACK_VERSION}-${BUILD_NUMBER}
RUN /usr/bin/conf-select dry-run-create --package zookeeper --stack-version ${STACK_VERSION}-${BUILD_NUMBER} --conf-version 0 && /usr/bin/conf-select create-conf-dir --package zookeeper --stack-version ${STACK_VERSION}-${BUILD_NUMBER} --conf-version 0
RUN /usr/bin/conf-select set-conf-dir --package zookeeper --stack-version ${STACK_VERSION}-${BUILD_NUMBER} --conf-version 0
RUN ln -s /opt/anyscale/current/zookeeper-client/conf /etc/zookeeper/conf && cp -R -p /etc/zookeeper/conf.backup/* /etc/zookeeper/conf