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
ARG STACK_VERSION
ARG BUILD_NUMBER
ARG PARCEL_VERSION

FROM centos:7.9.2009

RUN yum install java-11-openjdk-devel -y

# set java env
ENV JAVA_HOME /usr/lib/jvm/default-jvm
RUN ln -s /usr/lib/jvm/java-11-openjdk /usr/lib/jvm/default-jvm
COPY etc /etc
COPY opt /opt
COPY var /var

## require anyscale select && utils
COPY --from=hetudb/anyscale-select:$PARCEL_VERSION /opt/anyscale/* /opt/anyscale/
RUN ls -s /opt/anyscale/$STACK_VERSION-$BUILD_NUMBER/lib/distro-select /usr/bin/anyscale-select
RUN ls -s /opt/anyscale/$STACK_VERSION-$BUILD_NUMBER/lib/conf-select /usr/bin/conf-select
RUN /usr/bin/anyscale-select set zookeeper-client $STACK_VERSION-$BUILD_NUMBER && /usr/bin/anyscale-select set zookeeper-server $STACK_VERSION-$BUILD_NUMBER
RUN /usr/bin/conf-select dry-run-create --package zookeeper --stack-version $STACK_VERSION-$BUILD_NUMBER --conf-version 0 && /usr/bin/conf-select create-conf-dir --package zookeeper --stack-version $STACK_VERSION-$BUILD_NUMBER --conf-version 0
RUN /usr/bin/conf-select set-conf-dir --package zookeeper --stack-version $STACK_VERSION-$BUILD_NUMBER --conf-version 0