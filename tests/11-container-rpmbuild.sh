#!/bin/bash

if [[ $(whoami) == "root" ]]; then
  echo "I am root... Handing over to builduser"
  sudo -u builduser /home/builduser/11-container-rpmbuild.sh
else
  echo "I am builduser... I am building"
  cd /home/builduser
  tar -xzf /home/builduser/*.tar.gz || (echo "Failed to extract tar.gz" && exit 1)
  VERSION=$(grep Version auter/auter.spec | awk '{print $2}')

  mv /home/builduser/auter /home/builduser/auter-"${VERSION}" || (echo "Failed to rename working directory" && exit 1)
  tar -czf "${VERSION}".tar.gz auter-"${VERSION}" || (echo "Failed to create ${VERSION}.tar.gz" && exit 1)
  mv "${VERSION}".tar.gz rpmbuild/SOURCES  || (echo "Failed to extract ${VERSION}.tar.gz" && exit 1)
  cd /home/builduser/rpmbuild/SPECS
  OUTPUT="$(rpmbuild -ba auter.spec 2>&1)"
  if [[ $? -ne 0 ]]; then
    echo "${OUTPUT}"
    echo "FAILED to run 'rpmbuild -ba auter.spec'"
    exit 1
  fi
  cd /home/builduser/rpmbuild/RPMS/noarch
  tar -czf /home/builduser/auter.rpm.tar.gz auter*rpm || (echo "Failed to tar new .rpm" && exit 1)
fi
