#!/bin/bash

. "$(dirname "$0")"/_helpers

export RELEASE="18.04"
log_info "AUTERDIR: $AUTERDIR"
log_info "AUTERPARENTDIR: $AUTERPARENTDIR"
log_info "VERSION: $VERSION"

# build the container
#
run_cmd "Start Ubuntu $RELEASE container" \
  docker run -td --rm=true --name auter-debuild-test-"$RELEASE" \
  -e DEBIAN_FRONTEND=noninteractive \
  -v "$AUTERDIR":/root/auter \
  ubuntu:"$RELEASE"

PACKAGELIST=("sudo" "git" "make" "help2man")
PACKAGELIST+=("lsb-release" "lintian" "devscripts" "debhelper")

run_cmd "Update package info" \
  docker exec auter-debuild-test-"$RELEASE" apt-get update -qq

run_cmd "Install ${PACKAGELIST[*]}" \
  docker exec auter-debuild-test-"$RELEASE" apt-get install -qq "${PACKAGELIST[@]}"

run_cmd "Check for /usr/bin/python link" \
  docker exec auter-debuild-test-"$RELEASE" ln -s /usr/bin/python3 /usr/bin/python &>/dev/null|| true

log_info "Handing over to container to build deb package"
run_cmd "Executed /root/auter/tests/21-container-debuild.sh" \
  docker exec auter-debuild-test-"$RELEASE" /root/auter/tests/21-container-debuild.sh

run_cmd "Stop Ubuntu $RELEASE container" \
  docker stop auter-debuild-test-"$RELEASE"
