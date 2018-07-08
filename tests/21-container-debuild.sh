#!/bin/bash

if [[ $(whoami) == "root" ]]; then
  echo "I am root... Handing over to builduser"
  sudo -u builduser /home/builduser/21-container-debuild.sh
else
  echo "I am builduser... I am building"
  cd /home/builduser || (echo "Failed to cd to /home/builduser" && exit 1)
  tar -xzf /home/builduser/auter-*-debuild.tar.gz || (echo "Failed to extract tar.gz" && exit 1)
  VERSION=$(grep Version auter/auter.spec | awk '{print $2}')

  mv /home/builduser/auter /home/builduser/auter-"${VERSION}" || (echo "Failed to rename working directory" && exit 1)

  tar -czf "${VERSION}".tar.gz auter-"${VERSION}"
  cd auter-"${VERSION}" || (echo "Failed to cd to $(pwd)/auter-${VERSION}" && exit 1)
  make deb
  cd "$(find . -maxdepth 1 -type d | grep auter | grep -v orig)" || (echo "Failed to cd to auter directory created by Makefile" && exit 1)
  debuild -us -uc >/dev/null
  cd ../ || (echo "Failed to cd" && exit 1)
  tar -czf /home/builduser/auter.deb.tar.gz auter*deb || (echo "Failed to compress new .deb file." && exit 1)
fi
