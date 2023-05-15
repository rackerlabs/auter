#!/bin/bash

. "$(dirname "$0")"/_helpers

log_info "AUTERDIR: $AUTERDIR"
log_info "AUTERPARENTDIR: $AUTERPARENTDIR"
log_info "VERSION: $VERSION"

for RELEASE in 6 7; do
  # Build the docker container
  run_cmd "Start CentOS-$RELEASE container" \
    docker run -td --rm=true --name auter-rpmbuild-"$RELEASE" \
    -e VERSION="$VERSION" \
    -v "$AUTERDIR":/root/auter \
    centos:"$RELEASE"

  PACKAGELIST=("gcc" "rpm-build" "rpm-devel" "rpmlint")
  PACKAGELIST+=("make" "python" "bash" "coreutils")
  PACKAGELIST+=("diffutils" "patch" "rpmdevtools" "help2man")

  run_cmd "Install ${PACKAGELIST[*]}" \
    docker exec "auter-rpmbuild-$RELEASE" yum -y -q -e 0 install "${PACKAGELIST[@]}"

  log_info "Handing over to container to build rpm package"
  run_cmd "Executed 11-container-rpmbuild.sh" \
    docker exec "auter-rpmbuild-$RELEASE" /root/auter/tests/11-container-rpmbuild.sh

  run_cmd "Stopping CentOS-$RELEASE container" \
    docker stop "auter-rpmbuild-$RELEASE"
done
