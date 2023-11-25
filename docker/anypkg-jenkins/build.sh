#!/bin/bash -ex

# set params
POSTFIX=
ARCH=$(uname -m)

if [ "$ARCH" != "ppc64le" ]; then
  WORK_DIR=$(pwd)

  # Run docker, execute bigtop build command.
  docker run --rm \
    -e DOCKER_CREDENTIALS=${DOCKER_CREDENTIALS} \
    -e DOCKER_USER=${DOCKER_USER} \
    -v /usr/bin/docker:/usr/bin/docker \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v `pwd`:/ws \
    --workdir /ws \
    -v /home/jenkins/.m2:/var/lib/jenkins/.m2 \
    midtao/slaves:main-centos-7 \
    bash -c ". /etc/profile.d/bigtop.sh; ./gradlew ${COMPONENTS}-clean ${COMPONENTS}-pkg"
fi
