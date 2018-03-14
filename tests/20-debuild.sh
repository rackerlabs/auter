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

#for RELEASE in 16.04 17.04 17.10; do
for RELEASE in 16.04; do
  function EVALSUCCESS {
    RC=$?
    if [[ $RC -ne 0 ]]; then
      [[ -z $OUTPUT ]] && echo "$OUTPUT"
      echo -e " [ FAILED ] ABORTING - RC=$RC - $1"
      FAILEDTESTS+="Ubuntu ${RELEASE}"
      continue
    else
      echo " [ PASSED ] $1"
      return 0
    fi
  }

  # build the container
  DOCKERCONTAINERS+=" $(docker run --rm=true --name auter-debuild-test-${RELEASE} -e DEBIAN_FRONTEND=noninteractive -td ubuntu:${RELEASE})"
  EVALSUCCESS "Created ${RELEASE} docker image"

  # install the debuild packages
  # problem with:
  #  -  debhelper
  #  -  devscripts
  #  -  dh-make
  #  -  build-essential
  docker exec auter-debuild-test-"${RELEASE}" apt-get -qq update
  EVALSUCCESS "Updated apt cache in docker image"

  for PACKAGE in apt-utils sudo git make help2man; do
    OUTPUT=""
    OUTPUT=$(docker exec auter-debuild-test-"${RELEASE}" apt-get -qq install -y ${PACKAGE})
    EVALSUCCESS "Installed ${PACKAGE}"
  done

  docker exec auter-debuild-test-"${RELEASE}" useradd builduser -s /bin/bash -m
  EVALSUCCESS "Added build user"

  # Create the tarball for debbuild
  # Manually changing directory due to tar -C not working too well
  CURRENTDIR="$(pwd)"
  cd "${AUTERPARENTDIR}"
  tar -czf "auter-${VERSION}-debuild.tar.gz" auter
  EVALSUCCESS "Created source tarball from travis container"
  sleep 2

  mv "auter-${VERSION}-debuild.tar.gz" "${AUTERDIR}"
  EVALSUCCESS "Moved sources tarball from $(pwd) to ${AUTERDIR}"
  cd "${CURRENTDIR}"

  # Copy the build test script to the container
  docker cp "${AUTERDIR}/auter-${VERSION}-debuild.tar.gz" auter-debuild-test-${RELEASE}:/home/builduser/
  EVALSUCCESS "Copied sources to docker container"

  docker cp "${AUTERDIR}/tests/21-container-debuild.sh" "auter-debuild-test-${RELEASE}":/home/builduser
  EVALSUCCESS "Copied build script to container"

  docker exec auter-debuild-test-${RELEASE} chown -R builduser.builduser /home/builduser
  docker exec auter-debuild-test-${RELEASE} /home/builduser/21-container-debuild.sh
  EVALSUCCESS "Executed /home/builduser/21-container-debuild.sh"

#  docker cp auter-debuild-test-${RELEASE}:/home/builduser/auter.deb.tar.gz ./
#  tar -xzf auter.deb.tar.gz
#  rm -f auter.deb.tar.gz
  docker stop auter-debuild-test-${RELEASE}
done
