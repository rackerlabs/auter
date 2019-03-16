#!/bin/bash

. "$(dirname "$0")"/_helpers

export RELEASE="18.04"
log_info "AUTERDIR: $AUTERDIR"
log_info "AUTERPARENTDIR: $AUTERPARENTDIR"
log_info "VERSION: $VERSION"

function quit() {
  docker stop "auter-debuild-test-$RELEASE"
  exit "${1:-1}"
}

function run_cmd ()
{
  local tag="$1"; shift
  if OUTPUT="$("${@}" 2>&1)"; then
    log_success "$tag"
    return 0
  else
    log_fail "$tag"
    awk '{printf "|    %s\n",$0}' <<< "$OUTPUT"
    echo "-----------------------------------------------------------------------"
    quit 1
  fi
}
export -f run_cmd

# build the container
#
run_cmd "Start Ubuntu $RELEASE container" docker run \
  --rm=true --name auter-debuild-test-"$RELEASE" \
  -e DEBIAN_FRONTEND=noninteractive \
  -v "$AUTERDIR":/root/auter \
  -td ubuntu:"$RELEASE"

PACKAGELIST=("sudo" "git" "make" "help2man")
PACKAGELIST+=("lsb-release" "lintian" "devscripts" "debhelper")
run_cmd "Update package info" \
  docker exec auter-debuild-test-"$RELEASE" apt-get update -qq

run_cmd "Install ${PACKAGELIST[*]}" \
  docker exec auter-debuild-test-"$RELEASE" apt-get install -qq "${PACKAGELIST[@]}"

docker exec auter-debuild-test-"$RELEASE" ln -s /usr/bin/python3 /usr/bin/python &>/dev/null|| true

log_info "Handing over to container to build deb package"
run_cmd "Executed /root/auter/tests/21-container-debuild.sh" \
  docker exec auter-debuild-test-"$RELEASE" /root/auter/tests/21-container-debuild.sh

run_cmd "Stop Ubuntu $RELEASE container" \
  docker stop auter-debuild-test-"$RELEASE"
