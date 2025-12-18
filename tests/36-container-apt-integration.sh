#!/bin/bash
# shellcheck disable=SC1091  # Can't follow dynamically sourced file
# shellcheck source=_helpers
. "$(dirname "$0")"/_helpers

# Container command wrapper (will be set to podman or docker)
container_cmd() {
    "${CONTAINER_CMD:-docker}" "$@"
}

# Test containers for APT functionality testing
declare -A APT_CONTAINERS=(
    ["ubuntu22"]="ubuntu:22.04"     # APT (current LTS)
    ["ubuntu24"]="ubuntu:24.04"     # APT (latest LTS)
)

# Test scenarios to run in each container (APT-focused)
TEST_SCENARIOS=(
    "basic_apply"
    "basic_status_check"
    "config_validation"
)

setup_container() {
    local name="$1"
    local image="$2"
    
    log_info "Setting up container: $name ($image)"
    
    # Clean up any existing container with the same name
    if container_cmd ps -aq -f name="auter-test-$name" | grep -q .; then
        log_info "Removing existing container: auter-test-$name"
        container_cmd rm -f "auter-test-$name" >/dev/null 2>&1 || true
    fi
    
    # Start container
    run_cmd "Start $name container" \
        container_cmd run -td --rm=true --name "auter-test-$name" \
        --security-opt label=disable \
        -v "$AUTERDIR":/auter \
        -e DEBIAN_FRONTEND=noninteractive \
        "$image"
    
    # Install APT dependencies
    run_cmd "Install APT dependencies in $name" \
        container_cmd exec "auter-test-$name" bash -c "apt-get update && apt-get install -y bash coreutils findutils"
    
    # Install auter from DEB package
    local deb_package
    deb_package=$(find "$AUTERDIR/packages" -name "auter_*.deb" | head -1)
    
    if [[ -n "$deb_package" && -f "$deb_package" ]]; then
        run_cmd "Install auter DEB package in $name" \
            container_cmd exec "auter-test-$name" dpkg -i "/auter/packages/$(basename "$deb_package")"
        
        # Fix any dependency issues
        run_cmd "Fix dependencies in $name" \
            container_cmd exec "auter-test-$name" apt-get install -f -y
        
        # Disable random delays for testing
        run_cmd "Configure auter for testing in $name" \
            container_cmd exec "auter-test-$name" bash -c "echo 'MAXDELAY=1' >> /etc/auter/auter.conf"
    else
        log_info "No DEB package found, falling back to manual setup"
        # Fallback to manual setup if no package available
        run_cmd "Setup auter directories in $name" \
            container_cmd exec "auter-test-$name" bash -c "
                mkdir -p /etc/auter /var/lib/auter /var/cache/auter /usr/lib/auter
                cp /auter/auter /usr/bin/auter
                cp /auter/auter.conf /etc/auter/
                chmod +x /usr/bin/auter
                # Disable random delays for testing
                echo 'MAXDELAY=1' >> /etc/auter/auter.conf
            "
        
        # Setup APT module
        run_cmd "Setup APT module in $name" \
            container_cmd exec "auter-test-$name" cp /auter/auter.aptModule /usr/lib/auter/auter.module
    fi
}

debug_container_state() {
    local container="$1"
    log_info "Debug: Checking container state for $container"
    
    # Check if APT is running
    if container_cmd exec "auter-test-$container" pgrep -f apt >/dev/null 2>&1; then
        log_info "Debug: APT process is running"
    else
        log_info "Debug: No APT process running"
    fi
    
    # Check for lock files
    if container_cmd exec "auter-test-$container" test -f /var/lib/dpkg/lock 2>/dev/null; then
        log_info "Debug: DPKG lock file exists"
    else
        log_info "Debug: No DPKG lock file"
    fi
    
    # Check auter processes
    if container_cmd exec "auter-test-$container" pgrep -f auter >/dev/null 2>&1; then
        log_info "Debug: Auter process is running"
    else
        log_info "Debug: No auter process running"
    fi
    
    # Check auter status
    local auter_status
    auter_status=$(container_cmd exec "auter-test-$container" /usr/bin/auter --status 2>&1 || echo "status check failed")
    log_info "Debug: Auter status: $auter_status"
    
    # Check if we can reach repositories
    log_info "Debug: Testing repository connectivity..."
    if container_cmd exec "auter-test-$container" timeout 10 apt-get update >/dev/null 2>&1; then
        log_info "Debug: Repository connectivity OK"
    else
        log_info "Debug: Repository connectivity issues"
    fi
}

test_basic_apply() {
    local container="$1"
    local test_name="basic_apply in $container"
    
    # Enable auter first
    run_cmd "Enable auter in $container" \
        container_cmd exec "auter-test-$container" /usr/bin/auter --enable
    
    # Test apply operation with timeout (should handle no updates gracefully)
    log_info "Running apply test (may take a while)..."
    local output
    if output=$(timeout 120 container_cmd exec "auter-test-$container" /usr/bin/auter --apply --stdout --maxdelay=1 2>&1); then
        log_success "$test_name: apply completed"
        
        # Check if apply output file was created
        if container_cmd exec "auter-test-$container" test -f /var/lib/auter/last-apply-output-default; then
            log_success "$test_name: apply output file created"
        else
            log_fail "$test_name: apply output file not created"
            return 1
        fi
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_fail "$test_name: apply timed out after 2 minutes"
            debug_container_state "$container"
        else
            log_fail "$test_name: apply failed (exit code: $exit_code)"
        fi
        echo "|    Output: $output"
        return 1
    fi
}

test_basic_status_check() {
    local container="$1"
    local test_name="basic_status_check in $container"
    
    # Test status check (should work without enabling auter)
    log_info "Testing auter status check..."
    local output
    if output=$(timeout 30 container_cmd exec "auter-test-$container" /usr/bin/auter --status 2>&1); then
        log_success "$test_name: status check completed"
        
        # Check that status output contains expected information
        if echo "$output" | grep -q -E "(enabled|disabled)"; then
            log_success "$test_name: status output contains enable/disable state"
        else
            log_fail "$test_name: status output missing enable/disable state"
            echo "|    Output: $output"
            return 1
        fi
    else
        local exit_code=$?
        log_fail "$test_name: status check failed (exit code: $exit_code)"
        echo "|    Output: $output"
        return 1
    fi
}

test_config_validation() {
    local container="$1"
    local test_name="config_validation in $container"
    
    # Test that auter can read its configuration
    log_info "Testing configuration validation..."
    local output
    if output=$(timeout 30 container_cmd exec "auter-test-$container" /usr/bin/auter --help 2>&1); then
        log_success "$test_name: help command works (config readable)"
        
        # Check that help output contains expected sections
        if echo "$output" | grep -q -E "(USAGE|OPTIONS)"; then
            log_success "$test_name: help output contains expected sections"
        else
            log_fail "$test_name: help output missing expected sections"
            echo "|    Output: $output"
            return 1
        fi
    else
        local exit_code=$?
        log_fail "$test_name: help command failed (exit code: $exit_code)"
        echo "|    Output: $output"
        return 1
    fi
}

test_package_manager_detection() {
    local container="$1"
    local test_name="package_manager_detection in $container"
    
    # Test that APT is available
    if container_cmd exec "auter-test-$container" test -x /usr/bin/apt-get; then
        log_success "$test_name: APT is available"
    else
        log_fail "$test_name: APT should be available"
        return 1
    fi
}

run_scenario() {
    local container="$1"
    local scenario="$2"
    
    case "$scenario" in
        "basic_apply")
            test_basic_apply "$container"
            ;;
        "basic_status_check")
            test_basic_status_check "$container"
            ;;
        "config_validation")
            test_config_validation "$container"
            ;;
        "package_manager_detection")
            test_package_manager_detection "$container"
            ;;
    esac
}

cleanup_container() {
    local name="$1"
    
    if container_cmd ps -q -f name="auter-test-$name" | grep -q .; then
        run_cmd "Stop $name container" \
            container_cmd stop "auter-test-$name"
    fi
}

main() {
    local EXITCODE=0
    
    log_info "Starting APT integration tests"
    
    # Container runtime detection is handled by _helpers
    
    # Define test order
    local test_order=("ubuntu22" "ubuntu24")
    
    # Test APT containers with basic functionality
    for container_name in "${test_order[@]}"; do
        local container_image="${APT_CONTAINERS[$container_name]}"
        
        log_info "Testing basic APT functionality with $container_name ($container_image)"
        
        # Setup container
        if ! setup_container "$container_name" "$container_image"; then
            log_fail "Failed to setup $container_name container"
            EXITCODE=1
            continue
        fi
        
        # Run package manager detection test first
        if ! run_scenario "$container_name" "package_manager_detection"; then
            EXITCODE=1
        fi
        
        # Quick sanity check - can auter run at all?
        log_info "Quick sanity check for $container_name"
        if timeout 30 container_cmd exec "auter-test-$container_name" /usr/bin/auter --help >/dev/null 2>&1; then
            log_success "Auter help command works in $container_name"
        else
            log_fail "Auter help command failed/timed out in $container_name"
            EXITCODE=1
        fi
        
        # Test if we can run apt-get directly (to isolate auter vs apt issues)
        log_info "Testing APT directly in $container_name"
        if timeout 30 container_cmd exec "auter-test-$container_name" apt-get --version >/dev/null 2>&1; then
            log_success "APT command works in $container_name"
        else
            log_fail "APT command failed/timed out in $container_name"
        fi
        
        # Run test scenarios
        for scenario in "${TEST_SCENARIOS[@]}"; do
            if ! run_scenario "$container_name" "$scenario"; then
                EXITCODE=1
                # Continue with other tests even if one fails
                log_info "Continuing with remaining tests despite failure..."
            fi
        done
        
        # Cleanup
        cleanup_container "$container_name"
    done
    
    if [[ $EXITCODE -eq 0 ]]; then
        log_success "All APT integration tests passed"
    else
        log_fail "Some APT integration tests failed"
    fi
    
    exit $EXITCODE
}

# Global flag to prevent duplicate cleanup
APT_CLEANUP_DONE=false

# Cleanup function for signal handling
# shellcheck disable=SC2329  # Function used indirectly via trap
cleanup_all_containers() {
    # Prevent duplicate cleanup
    if [[ "$APT_CLEANUP_DONE" == "true" ]]; then
        return
    fi
    APT_CLEANUP_DONE=true
    
    local exit_code=$?
    log_info "Cleaning up APT test containers..."
    for name in "${!APT_CONTAINERS[@]}"; do
        cleanup_container "$name"
    done
    exit "$exit_code"
}

# Set up signal traps
trap cleanup_all_containers EXIT
trap 'log_info "Received interrupt signal, cleaning up..."; cleanup_all_containers' INT TERM

main "$@"