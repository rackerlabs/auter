#!/bin/bash
# shellcheck disable=SC1091  # Can't follow dynamically sourced file
# shellcheck source=_helpers

. "$(dirname "$0")"/_helpers

# Container command wrapper (will be set to podman or docker)
container_cmd() {
    "${CONTAINER_CMD:-docker}" "$@"
}

# Test containers for DNF compatibility testing
declare -A DNF_CONTAINERS=(
    ["alma8"]="almalinux:8"         # DNF 4 (RHEL 8 clone - backward compatibility)
    ["alma9"]="almalinux:9"         # DNF 5 (RHEL 9 clone - current enterprise)
    ["alma10"]="almalinux:10"       # DNF 5 (RHEL 10 clone - latest enterprise)
    ["fedora41"]="fedora:41"        # DNF 5 (current stable)
)

# Test scenarios to run in each container
TEST_SCENARIOS=(
    "basic_prep"
    "basic_apply" 
    "prep_and_apply"
    "prep_only_mode"
    "no_updates_available"
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
    
    # Install DNF 5 dependencies
    run_cmd "Install DNF 5 dependencies in $name" \
        container_cmd exec "auter-test-$name" dnf install -y --allowerasing bash coreutils findutils util-linux
    
    # Install auter from RPM package
    local rpm_package
    rpm_package=$(find "$AUTERDIR/packages" -name "auter-*.rpm" | head -1)
    
    if [[ -n "$rpm_package" && -f "$rpm_package" ]]; then
        run_cmd "Install auter RPM package in $name" \
            container_cmd exec "auter-test-$name" dnf install -y "/auter/packages/$(basename "$rpm_package")"
        
        # Disable random delays for testing
        run_cmd "Configure auter for testing in $name" \
            container_cmd exec "auter-test-$name" bash -c "echo 'MAXDELAY=1' >> /etc/auter/auter.conf"
    else
        log_info "No RPM package found, falling back to manual setup"
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
        
        # Setup YUM/DNF module
        run_cmd "Setup YUM/DNF module in $name" \
            container_cmd exec "auter-test-$name" cp /auter/auter.yumdnfModule /usr/lib/auter/auter.module
    fi
}

debug_container_state() {
    local container="$1"
    log_info "Debug: Checking container state for $container"
    
    # Check if DNF is running
    if container_cmd exec "auter-test-$container" pgrep -f dnf >/dev/null 2>&1; then
        log_info "Debug: DNF process is running"
    else
        log_info "Debug: No DNF process running"
    fi
    
    # Check for lock files
    if container_cmd exec "auter-test-$container" test -f /var/run/yum.pid 2>/dev/null; then
        log_info "Debug: YUM lock file exists"
    else
        log_info "Debug: No YUM lock file"
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
    if container_cmd exec "auter-test-$container" timeout 10 dnf repolist >/dev/null 2>&1; then
        log_info "Debug: Repository connectivity OK"
    else
        log_info "Debug: Repository connectivity issues"
    fi
}

test_basic_prep() {
    local container="$1"
    local test_name="basic_prep in $container"
    
    # Enable auter first
    run_cmd "Enable auter in $container" \
        container_cmd exec "auter-test-$container" /usr/bin/auter --enable
    
    # Test prep operation with timeout and debugging
    log_info "Running prep test (may take a while for repository updates)..."
    
    # First check what dnf check-update returns
    log_info "Debug: Testing dnf check-update directly..."
    local dnf_check_result
    dnf_check_result=$(container_cmd exec "auter-test-$container" timeout 60 dnf check-update 2>&1 || echo "dnf check failed or no updates")
    log_info "Debug: DNF check-update result: $dnf_check_result"
    
    # Now run auter prep with more verbose output
    local output
    if output=$(timeout 90 container_cmd exec "auter-test-$container" /usr/bin/auter --prep --stdout --maxdelay=1 2>&1); then
        log_success "$test_name: prep completed"
        
        # Check if prep output file was created
        if container_cmd exec "auter-test-$container" test -f /var/lib/auter/last-prep-output-default; then
            log_success "$test_name: prep output file created"
        else
            log_fail "$test_name: prep output file not created"
            return 1
        fi
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_fail "$test_name: prep timed out after 90 seconds"
            debug_container_state "$container"
        else
            log_fail "$test_name: prep failed (exit code: $exit_code)"
        fi
        echo "|    Output: $output"
        return 1
    fi
}

test_basic_apply() {
    local container="$1"
    local test_name="basic_apply in $container"
    
    # Enable auter first (in case it's not already enabled)
    run_cmd "Enable auter in $container" \
        container_cmd exec "auter-test-$container" /usr/bin/auter --enable
    
    # Test apply operation with timeout (should handle no updates gracefully)
    log_info "Running apply test (may take a while)..."
    local output
    if output=$(timeout 90 container_cmd exec "auter-test-$container" /usr/bin/auter --apply --stdout --maxdelay=1 2>&1); then
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
            log_fail "$test_name: apply timed out after 90 seconds"
            debug_container_state "$container"
        else
            log_fail "$test_name: apply failed (exit code: $exit_code)"
        fi
        echo "|    Output: $output"
        return 1
    fi
}

test_prep_and_apply() {
    local container="$1"
    local test_name="prep_and_apply in $container"
    
    # Enable auter first (in case it's not already enabled)
    run_cmd "Enable auter in $container" \
        container_cmd exec "auter-test-$container" /usr/bin/auter --enable
    
    # Test full cycle with timeout
    log_info "Running full prep+apply cycle (may take several minutes)..."
    local output
    if output=$(timeout 180 container_cmd exec "auter-test-$container" bash -c "/usr/bin/auter --prep --stdout --maxdelay=1 && /usr/bin/auter --apply --stdout --maxdelay=1" 2>&1); then
        log_success "$test_name: full cycle completed"
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_fail "$test_name: full cycle timed out after 3 minutes"
            debug_container_state "$container"
        else
            log_fail "$test_name: full cycle failed (exit code: $exit_code)"
        fi
        echo "|    Output: $output"
        return 1
    fi
}

test_prep_only_mode() {
    local container="$1"
    local test_name="prep_only_mode in $container"
    
    # Enable auter first (in case it's not already enabled)
    run_cmd "Enable auter in $container" \
        container_cmd exec "auter-test-$container" /usr/bin/auter --enable
    
    # Configure for prep-only mode (need both settings for it to work)
    run_cmd "Configure prep-only mode in $container" \
        container_cmd exec "auter-test-$container" bash -c "
            echo 'ONLYINSTALLFROMPREP=\"yes\"' >> /etc/auter/auter.conf
            echo 'PREDOWNLOADUPDATES=\"yes\"' >> /etc/auter/auter.conf
        "
    
    # First run prep to download packages
    log_info "Running initial prep for prep-only mode..."
    container_cmd exec "auter-test-$container" /usr/bin/auter --prep --stdout --maxdelay=1 >/dev/null 2>&1 || true
    
    # Test prep in prep-only mode with timeout
    log_info "Running prep-only mode test..."
    local output
    output=$(timeout 90 container_cmd exec "auter-test-$container" /usr/bin/auter --prep --stdout --maxdelay=1 2>&1 || true)
    
    # Check for acceptable outcomes
    if echo "$output" | grep -q -E "(No updates|prep completed|Updates downloaded|download complete|SUCCESS)"; then
        log_success "$test_name: prep-only mode works"
    elif echo "$output" | grep -q "timed out"; then
        log_fail "$test_name: prep-only mode timed out"
        debug_container_state "$container"
        return 1
    else
        log_fail "$test_name: prep-only mode failed"
        echo "|    Output: $output"
        return 1
    fi
}

test_no_updates_available() {
    local container="$1"
    local test_name="no_updates_available in $container"
    
    # Enable auter first (in case it's not already enabled)
    run_cmd "Enable auter in $container" \
        container_cmd exec "auter-test-$container" /usr/bin/auter --enable
    
    # This should complete successfully even with no updates
    log_info "Testing no-updates scenario..."
    local output
    output=$(timeout 60 container_cmd exec "auter-test-$container" /usr/bin/auter --prep --stdout --maxdelay=1 2>&1 || true)
    
    # Check for success indicators
    if echo "$output" | grep -q -E "(No updates are available|Updates downloaded|prep completed)"; then
        log_success "$test_name: handled update scenario correctly"
    elif echo "$output" | grep -q -E "(ERROR|FAILED)"; then
        log_fail "$test_name: prep failed with errors"
        echo "|    Output: $output"
        return 1
    elif echo "$output" | grep -q "timed out"; then
        log_fail "$test_name: prep timed out"
        debug_container_state "$container"
        return 1
    else
        log_success "$test_name: prep completed without obvious errors"
    fi
}

test_package_manager_detection() {
    local container="$1"
    local test_name="package_manager_detection in $container"
    
    # Test that DNF is available
    if container_cmd exec "auter-test-$container" test -x /usr/bin/dnf; then
        log_success "$test_name: DNF is available"
    else
        log_fail "$test_name: DNF should be available"
        return 1
    fi
}

run_scenario() {
    local container="$1"
    local scenario="$2"
    
    case "$scenario" in
        "basic_prep")
            test_basic_prep "$container"
            ;;
        "basic_apply")
            test_basic_apply "$container"
            ;;
        "prep_and_apply")
            test_prep_and_apply "$container"
            ;;
        "prep_only_mode")
            test_prep_only_mode "$container"
            ;;
        "no_updates_available")
            test_no_updates_available "$container"
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
    
    log_info "Starting DNF integration tests (DNF 4 & 5 compatibility)"
    
    # Container runtime detection is handled by _helpers
    
    # Define test order
    local test_order=("alma8" "alma9" "alma10" "fedora41")
    
    # Test DNF containers with full DNF 5 test suite
    for container_name in "${test_order[@]}"; do
        local container_image="${DNF_CONTAINERS[$container_name]}"
        
        log_info "Testing DNF compatibility with $container_name ($container_image)"
        
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
        
        # Test auter status (should work without network)
        log_info "Testing auter status in $container_name"
        local status_output
        status_output=$(container_cmd exec "auter-test-$container_name" /usr/bin/auter --status 2>&1 || true)
        log_info "Auter status: $status_output"
        
        # Test if we can run dnf directly (to isolate auter vs dnf issues)
        log_info "Testing DNF directly in $container_name"
        if timeout 30 container_cmd exec "auter-test-$container_name" dnf --version >/dev/null 2>&1; then
            log_success "DNF command works in $container_name"
        else
            log_fail "DNF command failed/timed out in $container_name"
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
        log_success "All DNF integration tests passed"
    else
        log_fail "Some DNF integration tests failed"
    fi
    
    exit $EXITCODE
}

# Global flag to prevent duplicate cleanup
DNF_CLEANUP_DONE=false

# Cleanup function for signal handling (used by trap handlers)
# shellcheck disable=SC2329  # Function used indirectly via trap
cleanup_all_containers() {
    # Prevent duplicate cleanup
    if [[ "$DNF_CLEANUP_DONE" == "true" ]]; then
        return
    fi
    DNF_CLEANUP_DONE=true
    
    local exit_code=$?
    log_info "Cleaning up DNF test containers..."
    for name in "${!DNF_CONTAINERS[@]}"; do
        cleanup_container "$name"
    done
    exit "$exit_code"
}

# Set up signal traps
trap cleanup_all_containers EXIT
trap 'log_info "Received interrupt signal, cleaning up..."; cleanup_all_containers' INT TERM

main "$@"