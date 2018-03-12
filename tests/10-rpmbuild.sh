#!/bin/bash

for RELEASE in 6 7; do
  # Build the docker container
  docker run --rm=true --name auter-rpmbuild-test-${RELEASE} -td centos:${RELEASE}
  
  # Install the rpmbuild dependencies, add the user and create the ENV
  docker exec auter-rpmbuild-test-${RELEASE} yum -y install rpm-build elfutils-libelf rpm-libs rpm-pythoni gcc make help2man sudo
  docker exec auter-rpmbuild-test-${RELEASE} useradd builduser
  docker exec auter-rpmbuild-test-${RELEASE} mkdir -p /home/builduser/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
  echo '%_topdir %(echo $HOME)/rpmbuild' > /tmp.rpmmacros
  
  # Create the tarball for rpmbuild
  tar -czvf ../auter-"$(grep Version auter.spec | awk '{print $2}')"-rpmbuild.tar.gz ../auter
  
  # Copy the rpmbuild config and tarball to the builduser homedir
  docker cp /tmp/.rpmmacros auter-rpmbuild-test-${RELEASE}:/home/builduser/.rpmmacros
  docker cp ../auter-*.tar.gz auter-rpmbuild-test-${RELEASE}:/home/builduser/
  docker cp auter.spec auter-rpmbuild-test-${RELEASE}:/home/builduser/rpmbuild/SPECS
  
  # Copy the build test script to the container
  docker cp tests/11-container-rpmbuild.sh auter-rpmbuild-test-${RELEASE}:/home/builduser
  docker exec auter-rpmbuild-test-${RELEASE} chown -R builduser.builduser /home/builduser
  docker exec auter-rpmbuild-test-${RELEASE} /home/builduser/11-container-rpmbuild.sh
  docker cp auter-rpmbuild-test-${RELEASE}:/home/builduser/auter.rpm.tar.gz ./
  tar -xzf auter.rpm.tar.gz
  rm -f auter.rpm.tar.gz
  docker stop auter-rpmbuild-test-${RELEASE}
done


