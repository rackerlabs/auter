#!/bin/bash

for RELEASE in 16.04 17.04 17.10; do
  # build the container
  docker run --rm=true --name auter-debuild-test-"${RELEASE}" -td ubuntu:"${RELEASE}"
  docker exec auter-debuild-test-"${RELEASE}" apt-get -qq update
  docker exec auter-debuild-test-"${RELEASE}" apt-get -qq install -y debhelper devscripts build-essential vim dh-make help2man sudo git
  docker exec auter-debuild-test-"${RELEASE}" useradd builduser -s /bin/bash -m
  
  # Create the tarball for deb build
  tar -czf ../auter-"$(grep Version auter.spec | awk '{print $2}')"-debbuild.tar.gz ../auter

  docker cp ../auter-*debbuild.tar.gz auter-debuild-test-${RELEASE}:/home/builduser/

  # Copy the build test script to the container
  docker cp tests/21-container-debuild.sh auter-debuild-test-${RELEASE}:/home/builduser
  docker exec auter-debuild-test-${RELEASE} chown -R builduser.builduser /home/builduser
  docker exec auter-debuild-test-${RELEASE} /home/builduser/21-container-debuild.sh
  docker cp auter-debuild-test-${RELEASE}:/home/builduser/auter.deb.tar.gz ./
  tar -xzf auter.deb.tar.gz
  rm -f auter.deb.tar.gz
  docker stop auter-debuild-test-${RELEASE}
done
