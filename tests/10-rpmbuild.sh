#!/bin/bash


AUTERDIR="$(cd "$(dirname "$0")"; cd .. ; pwd -P)"
AUTERPARENTDIR="$(cd "$(dirname "$0")"; cd ../.. ; pwd -P)"
VERSION="$(grep "Version" "${AUTERDIR}"/auter.spec | awk '{print $2}')"
echo "AUTERDIR: ${AUTERDIR}"
echo "AUTERPARENTDIR: ${AUTERPARENTDIR}"
echo "VERSION: ${VERSION}"

function quit() {
  CONTAINERS=$(docker ps -a -q)
  # shellcheck disable=SC2086
  [[ -n $CONTAINERS ]] && echo "Stopping leftover containers" && docker stop ${DOCKERCONTAINERS}
  exit "$1"
}

for RELEASE in 6 7; do
  function EVALSUCCESS {
    RC=$?
    if [[ $RC -ne 0 ]]; then
      echo -e " [ FAILED ] ABORTING - RC=$RC - $1"
      FAILEDTESTS+="RHEL${RELEASE} / CentOS${RELEASE}"
      continue
    else
      echo " [ PASSED ] $1"
      return 0
    fi
  }

  # Build the docker container
  DOCKERCONTAINERS+=" $(docker run --rm=true --name auter-rpmbuild-test-${RELEASE} -td centos:${RELEASE})"
  EVALSUCCESS "Created ${RELEASE} docker image"
  
  # Install the rpmbuild dependencies, add the user and create the ENV
  docker exec auter-rpmbuild-test-${RELEASE} yum -y -q -e 0 install rpm-build elfutils-libelf rpm-libs rpm-pythoni gcc make help2man sudo 2>/dev/null 1>/dev/null
  EVALSUCCESS "Installed packages to docker image"

  docker exec auter-rpmbuild-test-${RELEASE} useradd builduser
  EVALSUCCESS "Added build user"

  docker exec auter-rpmbuild-test-${RELEASE} mkdir -p /home/builduser/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
  EVALSUCCESS "Created rpmbuild structure"

  # shellcheck disable=SC2016
  echo '%_topdir %(echo $HOME)/rpmbuild' > /tmp/.rpmmacros
  
  # Create the tarball for rpmbuild
  # Manually changing directory due to tar -C not working too well
  CURRENTDIR="$(pwd)"
  cd "${AUTERPARENTDIR}"
  tar -czf "auter-${VERSION}-rpmbuild.tar.gz" auter
  EVALSUCCESS "Created source tarball from travis container"
  sleep 2

  mv "auter-${VERSION}-rpmbuild.tar.gz" "${AUTERDIR}"
  EVALSUCCESS "Moved sources tarball from $(pwd) to ${AUTERDIR}"
  cd "${CURRENTDIR}"
  
  # Copy the rpmbuild config and tarball to the builduser homedir
  docker cp /tmp/.rpmmacros auter-rpmbuild-test-${RELEASE}:/home/builduser/.rpmmacros
  EVALSUCCESS "Copied /tmp/.rpmmacros to docker container"

  docker cp "${AUTERDIR}/auter-${VERSION}-rpmbuild.tar.gz" auter-rpmbuild-test-${RELEASE}:/home/builduser/
  EVALSUCCESS "Copied sources to docker container"

  docker cp "${AUTERDIR}/auter.spec" "auter-rpmbuild-test-${RELEASE}":/home/builduser/rpmbuild/SPECS
  EVALSUCCESS "Copied spec file to docker container"

  # Copy the build test script to the container
  docker cp "${AUTERDIR}/tests/11-container-rpmbuild.sh" "auter-rpmbuild-test-${RELEASE}":/home/builduser
  EVALSUCCESS "Copied build script to container"

  docker exec auter-rpmbuild-test-${RELEASE} chown -R builduser.builduser /home/builduser
  docker exec auter-rpmbuild-test-${RELEASE} /home/builduser/11-container-rpmbuild.sh
  EVALSUCCESS "Executed /home/builduser/11-container-rpmbuild.sh"

  docker cp auter-rpmbuild-test-${RELEASE}:/home/builduser/auter.rpm.tar.gz ./
  tar -xzf auter.rpm.tar.gz
  RPMORIGNAME="$(tar -tzvf auter.rpm.tar.gz | grep rpm | awk '{print $NF}')"
  RPMNEWNAME="${AUTERDIR}"/"${RPMORIGNAME//auter/auter-${RELEASE}}"
  mv "${RPMORIGNAME}" "${RPMNEWNAME}"
  EVALSUCCESS " ${RPMNEWNAME} file created in travis container"
  rm -f "${AUTERDIR}/auter-${VERSION}-rpmbuild.tar.gz"
  rm -f auter.rpm.tar.gz
done

if [[ -n "${FAILEDTESTS}" ]]; then
  echo " [ FAILED ] - The following builds failed:"
  echo "${FAILEDTESTS}"
  quit 1
else 
  echo " [ SUCCESS ] All builds were successfull"
  quit 0
fi
