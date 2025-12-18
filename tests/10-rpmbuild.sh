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

# Use current supported distributions for RPM building
declare -A RPM_CONTAINERS=(
  ["alma8"]="almalinux:8"
  ["alma9"]="almalinux:9"
  ["alma10"]="almalinux:10"
  ["fedora41"]="fedora:41"
)

# Allow filtering builds via environment variable
# Usage: BUILD_ONLY="alma9,fedora41" ./tests/10-rpmbuild.sh
if [[ -n "${BUILD_ONLY:-}" ]]; then
    declare -A FILTERED_CONTAINERS
    IFS=',' read -ra BUILDS <<< "$BUILD_ONLY"
    for build in "${BUILDS[@]}"; do
        if [[ -n "${RPM_CONTAINERS[$build]:-}" ]]; then
            FILTERED_CONTAINERS["$build"]="${RPM_CONTAINERS[$build]}"
        fi
    done
    RPM_CONTAINERS=()
    for key in "${!FILTERED_CONTAINERS[@]}"; do
        RPM_CONTAINERS["$key"]="${FILTERED_CONTAINERS[$key]}"
    done
fi

# Global flag to prevent duplicate cleanup
BUILD_CLEANUP_DONE=false

# Cleanup function for signal handling
cleanup_build_containers() {
    # Prevent duplicate cleanup
    if [[ "$BUILD_CLEANUP_DONE" == "true" ]]; then
        return
    fi
    BUILD_CLEANUP_DONE=true
    
    local exit_code=$?
    log_info "Cleaning up RPM build containers..."
    for release in "${!RPM_CONTAINERS[@]}"; do
        if container_cmd ps -q -f name="auter-rpmbuild-$release" | grep -q .; then
            container_cmd stop "auter-rpmbuild-$release" >/dev/null 2>&1 || true
        fi
    done
    exit $exit_code
}

# Set up signal traps
trap cleanup_build_containers EXIT
trap 'log_info "Received interrupt signal, cleaning up..."; cleanup_build_containers' INT TERM

for RELEASE in "${!RPM_CONTAINERS[@]}"; do
  IMAGE="${RPM_CONTAINERS[$RELEASE]}"
  
  # Clean up any existing container with the same name
  if container_cmd ps -aq -f name="auter-rpmbuild-$RELEASE" | grep -q .; then
    log_info "Removing existing container: auter-rpmbuild-$RELEASE"
    container_cmd rm -f "auter-rpmbuild-$RELEASE" >/dev/null 2>&1 || true
  fi

  # Build the container
  run_cmd "Start $RELEASE container" \
    container_cmd run -td --rm=true --name auter-rpmbuild-"$RELEASE" \
    --security-opt label=disable \
    -e VERSION="$VERSION" \
    -v "$AUTERDIR":/root/auter \
    "$IMAGE"

  # Core packages required for building
  PACKAGELIST=("gcc" "rpm-build" "rpm-devel")
  PACKAGELIST+=("make" "python3" "python3-pip" "bash" "coreutils" "gawk")
  PACKAGELIST+=("diffutils" "patch" "rpmdevtools" "util-linux")

  run_cmd "Install ${PACKAGELIST[*]}" \
    container_cmd exec "auter-rpmbuild-$RELEASE" dnf -y -q install --allowerasing "${PACKAGELIST[@]}"

  # Try to install rpmlint separately (optional, not available on all distributions)
  log_info "Attempting to install rpmlint (optional)..."
  if container_cmd exec "auter-rpmbuild-$RELEASE" dnf -y -q install rpmlint 2>/dev/null; then
    log_info "rpmlint installed successfully"
  else
    log_info "rpmlint not available on $RELEASE, skipping..."
  fi

  log_info "Handing over to container to build rpm package"
  run_cmd "Executed 11-container-rpmbuild.sh" \
    container_cmd exec "auter-rpmbuild-$RELEASE" /root/auter/tests/11-container-rpmbuild.sh

  # Copy built RPM packages out of container
  run_cmd "Copy RPM packages from $RELEASE container" \
    container_cmd exec "auter-rpmbuild-$RELEASE" bash -c "
      mkdir -p /root/auter/packages
      find /home/builduser/rpmbuild/RPMS -name '*.rpm' -exec cp {} /root/auter/packages/ \;
      ls -la /root/auter/packages/
    "

  run_cmd "Stopping $RELEASE container" \
    container_cmd stop "auter-rpmbuild-$RELEASE"
done
