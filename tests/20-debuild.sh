#!/bin/bash
# shellcheck disable=SC1091  # Can't follow dynamically sourced file
# shellcheck source=_helpers
. "$(dirname "$0")"/_helpers

# Container command wrapper (will be set to podman or docker)
container_cmd() {
    "${CONTAINER_CMD:-docker}" "$@"
}

log_info "AUTERDIR: $AUTERDIR"
log_info "AUTERPARENTDIR: $AUTERPARENTDIR"
log_info "VERSION: $VERSION"

# Use current supported distributions for DEB building
declare -A DEB_CONTAINERS=(
  ["ubuntu22"]="ubuntu:22.04"
  ["ubuntu24"]="ubuntu:24.04"
)

# Allow filtering builds via environment variable
# Usage: BUILD_ONLY="ubuntu22" ./tests/20-debuild.sh
if [[ -n "${BUILD_ONLY:-}" ]]; then
    declare -A FILTERED_CONTAINERS
    IFS=',' read -ra BUILDS <<< "$BUILD_ONLY"
    for build in "${BUILDS[@]}"; do
        if [[ -n "${DEB_CONTAINERS[$build]:-}" ]]; then
            FILTERED_CONTAINERS["$build"]="${DEB_CONTAINERS[$build]}"
        fi
    done
    DEB_CONTAINERS=()
    for key in "${!FILTERED_CONTAINERS[@]}"; do
        DEB_CONTAINERS["$key"]="${FILTERED_CONTAINERS[$key]}"
    done
fi

# Check if any containers are selected for building
if [[ ${#DEB_CONTAINERS[@]} -eq 0 ]]; then
    log_info "No DEB containers selected for building, skipping..."
    exit 0
fi

# Global flag to prevent duplicate cleanup
DEB_CLEANUP_DONE=false

# Cleanup function for signal handling
cleanup_deb_containers() {
    # Prevent duplicate cleanup
    if [[ "$DEB_CLEANUP_DONE" == "true" ]]; then
        return
    fi
    DEB_CLEANUP_DONE=true
    
    local exit_code=$?
    log_info "Cleaning up DEB build containers..."
    for release in "${!DEB_CONTAINERS[@]}"; do
        if container_cmd ps -q -f name="auter-debuild-$release" | grep -q .; then
            container_cmd stop "auter-debuild-$release" >/dev/null 2>&1 || true
        fi
    done
    exit $exit_code
}

# Set up signal traps
trap cleanup_deb_containers EXIT
trap 'log_info "Received interrupt signal, cleaning up..."; cleanup_deb_containers' INT TERM

for RELEASE in "${!DEB_CONTAINERS[@]}"; do
  IMAGE="${DEB_CONTAINERS[$RELEASE]}"
  
  # Clean up any existing container with the same name
  if container_cmd ps -aq -f name="auter-debuild-$RELEASE" | grep -q .; then
    log_info "Removing existing container: auter-debuild-$RELEASE"
    container_cmd rm -f "auter-debuild-$RELEASE" >/dev/null 2>&1 || true
  fi

  # Build the container
  run_cmd "Start $IMAGE container" \
    container_cmd run -td --rm=true --name auter-debuild-"$RELEASE" \
    --security-opt label=disable \
    -e DEBIAN_FRONTEND=noninteractive \
    -v "$AUTERDIR":/root/auter \
    "$IMAGE"

  PACKAGELIST=("sudo" "git" "make" "help2man" "gawk" "python3-pip")
  PACKAGELIST+=("lsb-release" "lintian" "devscripts" "debhelper")

  run_cmd "Update package info" \
    container_cmd exec auter-debuild-"$RELEASE" apt-get update -qq

    container_cmd exec auter-debuild-"$RELEASE" apt-get install -qq "${PACKAGELIST[@]}"

  run_cmd "Check for /usr/bin/python link" \
    container_cmd exec auter-debuild-"$RELEASE" ln -s /usr/bin/python3 /usr/bin/python &>/dev/null|| true

  log_info "Handing over to container to build deb package"
  run_cmd "Executed /root/auter/tests/21-container-debuild.sh" \
    container_cmd exec auter-debuild-"$RELEASE" /root/auter/tests/21-container-debuild.sh

  # Copy built DEB packages out of container
  run_cmd "Copy DEB packages from $RELEASE container" \
    container_cmd exec auter-debuild-"$RELEASE" bash -c "
      mkdir -p /root/auter/packages
      find /root -name '*.deb' -exec cp {} /root/auter/packages/ \;
      ls -la /root/auter/packages/
    "

  run_cmd "Stopping $RELEASE container" \
    container_cmd stop auter-debuild-"$RELEASE"
done

run_cmd "Stop Ubuntu $RELEASE container" \
  container_cmd stop auter-debuild-test-"$RELEASE"
