#!/bin/bash

function EVALSUCCESS {
  RC=$?
  if [[ $RC -ne 0 ]]; then
    echo -e " [ FAILED ] ABORTING - RC=$RC - $1"
    FAILEDTESTS+="${RELEASE}"
    return 1
  else
    echo " [ PASSED ] $1"
    return 0
  fi
}

function quit() {
  CONTAINERS=$(docker ps -a -q)
  [[ -n $CONTAINERS ]] && echo "Stopping leftover containers" && docker ps -a -q | xargs docker stop 
  exit $1
}

AUTERDIR=$(cd $(dirname $0); cd .. ; pwd -P)
AUTERPARENTDIR=$(cd $(dirname $0); cd ../.. ; pwd -P)
VERSION=$(grep "Version" ${AUTERDIR}/auter.spec | awk '{print $2}')
echo "AUTERDIR: $AUTERDIR"
echo "AUTERPARENTDIR: $AUTERPARENTDIR"
echo "VERSION: $VERSION"

for RELEASE in 6 ; do
  # Build the docker container
  docker run --rm=true --name auter-rpmbuild-test-${RELEASE} -td centos:${RELEASE}
  EVALSUCCESS "Created ${RELEASE} docker image" || quit 1
  
  # Install the rpmbuild dependencies, add the user and create the ENV
  docker exec auter-rpmbuild-test-${RELEASE} yum -y -q -e 0 install rpm-build elfutils-libelf rpm-libs rpm-pythoni gcc make help2man sudo 2>/dev/null 1>/dev/null
  EVALSUCCESS "Installed packages to docker image" || quit 1

  docker exec auter-rpmbuild-test-${RELEASE} useradd builduser
  EVALSUCCESS "Added build user" || quit 1

  docker exec auter-rpmbuild-test-${RELEASE} mkdir -p /home/builduser/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
  EVALSUCCESS "Created rpmbuild structure" || quit 1

  echo '%_topdir %(echo $HOME)/rpmbuild' > /tmp/.rpmmacros
  
  # Create the tarball for rpmbuild
  tar -czf ${AUTERPARENTDIR}/auter-"${VERSION}"-rpmbuild.tar.gz -C ${AUTERPARENTDIR} auter
  EVALSUCCESS "Created source tarball from travis container" || quit 1
  sleep 2

  mv $(cd $(dirname $0); cd ../../ ; pwd -P)/auter-"${VERSION}"-rpmbuild.tar.gz $(cd $(dirname $0); cd ../ ; pwd -P)
  EVALSUCCESS "Moved sources tarball from travis container to docker container" || quit 1
  
  # Copy the rpmbuild config and tarball to the builduser homedir
  docker cp /tmp/.rpmmacros auter-rpmbuild-test-${RELEASE}:/home/builduser/.rpmmacros
  EVALSUCCESS "Copied /tmp/.rpmmacros to docker container" || quit 1

  docker cp ../auter-"${VERSION}"-rpmbuild.tar.gz auter-rpmbuild-test-${RELEASE}:/home/builduser/
  EVALSUCCESS "Copied sources to docker container" || quit 1

  docker cp ${AUTERDIR}/auter.spec auter-rpmbuild-test-${RELEASE}:/home/builduser/rpmbuild/SPECS
  EVALSUCCESS "Copied spec file to docker container" || quit 1

  # Copy the build test script to the container
  docker cp ${AUTERDIR}/tests/11-container-rpmbuild.sh auter-rpmbuild-test-${RELEASE}:/home/builduser
  EVALSUCCESS "Copied build script to container" || quit 1

  docker exec auter-rpmbuild-test-${RELEASE} chown -R builduser.builduser /home/builduser
  docker exec auter-rpmbuild-test-${RELEASE} /home/builduser/11-container-rpmbuild.sh
  EVALSUCCESS "Executed /home/builduser/11-container-rpmbuild.sh" || quit 1

  docker cp auter-rpmbuild-test-${RELEASE}:/home/builduser/auter.rpm.tar.gz ./
  tar -xzf auter.rpm.tar.gz
  RPMORIGNAME="$(tar -tzvf auter.rpm.tar.gz | grep rpm | awk '{print $NF}')"
  RPMNEWNAME="${AUTERDIR}/$(echo ${RPMORIGNAME} | sed 's/auter/auter-'$RELEASE'/g')"
  mv "${RPMORIGNAME}" "${RPMNEWNAME}"
  EVALSUCCESS " ${RPMNEWNAME} file created in travis container" || quit 1
  rm -f "${AUTERDIR}/auter-${VERSION}-rpmbuild.tar.gz"
  rm -f auter.rpm.tar.gz
  docker stop auter-rpmbuild-test-${RELEASE}
done
