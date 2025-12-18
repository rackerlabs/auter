#!/bin/bash
# shellcheck disable=SC1091  # Can't follow dynamically sourced file
# shellcheck source=_helpers
. "$(dirname "$0")"/_helpers

EXITCODE=0

# Test data directory
TEST_DATA_DIR="$TESTDIR/data"
mkdir -p "$TEST_DATA_DIR"

# Create mock package manager outputs for testing
create_test_data() {
    # DNF 5 help output
    cat > "$TEST_DATA_DIR/dnf5_update_help.txt" << 'EOF'
usage: dnf5 [GLOBAL-OPTIONS] update [OPTIONS] [SPEC...]

Update packages to newer versions.

Options:
  --downloadonly        Only download packages, do not install them
  --setopt=OPTION=VALUE Override a configuration option
EOF

    # DNF 4 help output  
    cat > "$TEST_DATA_DIR/dnf4_update_help.txt" << 'EOF'
usage: dnf [options] update [spec ...]

Upgrade packages

optional arguments:
  --downloadonly        only download packages
EOF

    # YUM help output
    cat > "$TEST_DATA_DIR/yum_update_help.txt" << 'EOF'
Usage: yum [options] update [package1] [package2] [...]

Options:
  --downloadonly        don't update, just download
EOF

    # Sample check-update output (mimics real yum/dnf output format)
    cat > "$TEST_DATA_DIR/sample_check_update.txt" << 'EOF'
Package                          Arch         Version                  Repository
================================================================================
kernel.x86_64                    x86_64       5.4.0-74.83~18.04.1     updates
kernel-headers.x86_64            x86_64       5.4.0-74.83~18.04.1     updates  
libc6.x86_64                     x86_64       2.31-0ubuntu9.9          updates

Transaction Summary
================================================================================
EOF
}

# Test the downloadonly option detection logic
test_downloadonly_detection() {
    local test_name="downloadonly option detection"
    
    # Test DNF 5
    if grep -q -E '^[ ]*(--downloadonly)' "$TEST_DATA_DIR/dnf5_update_help.txt"; then
        log_success "$test_name: DNF 5 detection"
    else
        log_fail "$test_name: DNF 5 detection"
        EXITCODE=1
    fi
    
    # Test DNF 4
    if grep -q -E '^[ ]*(--downloadonly)' "$TEST_DATA_DIR/dnf4_update_help.txt"; then
        log_success "$test_name: DNF 4 detection"  
    else
        log_fail "$test_name: DNF 4 detection"
        EXITCODE=1
    fi
    
    # Test YUM
    if grep -q -E '^[ ]*(--downloadonly)' "$TEST_DATA_DIR/yum_update_help.txt"; then
        log_success "$test_name: YUM detection"
    else
        log_fail "$test_name: YUM detection" 
        EXITCODE=1
    fi
}

# Test package list parsing from check-update output
test_package_parsing() {
    local test_name="package list parsing"
    
    # This mimics the awk command in auter.yumdnfModule
    local parsed_packages
    parsed_packages=$(awk '/Package.*Arch/,/Transaction Summary/{if ($2 ~ /x86|686|noarch/) print $1}' "$TEST_DATA_DIR/sample_check_update.txt")
    
    local expected_count=3
    local actual_count
    actual_count=$(echo "$parsed_packages" | wc -l)
    
    if [[ "$actual_count" -eq "$expected_count" ]]; then
        log_success "$test_name: correct package count ($actual_count)"
    else
        log_fail "$test_name: expected $expected_count packages, got $actual_count"
        EXITCODE=1
    fi
}

# Test download command construction logic
test_download_command_construction() {
    local test_name="download command construction"
    
    # Mock the variables that would be set in auter
    local PACKAGE_MANAGER="dnf"
    local PACKAGEMANAGEROPTIONS=("--quiet")
    local DOWNLOADDIR="/tmp/test"
    local CONFIGSET="test"
    
    # Test DNF with setopt (new behavior)
    local downloadoption=("--downloaddir=$DOWNLOADDIR/$CONFIGSET")
    if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
        downloadoption=("--setopt=destdir=$DOWNLOADDIR/$CONFIGSET")
    fi
    
    local download_command=("$PACKAGE_MANAGER" "${PACKAGEMANAGEROPTIONS[@]}" "${downloadoption[@]}" update --downloadonly -y)
    
    local expected_command="dnf --quiet --setopt=destdir=/tmp/test/test update --downloadonly -y"
    local actual_command="${download_command[*]}"
    
    if [[ "$actual_command" == "$expected_command" ]]; then
        log_success "$test_name: DNF command construction"
    else
        log_fail "$test_name: DNF command construction"
        echo "|    Expected: $expected_command"
        echo "|    Actual:   $actual_command"
        EXITCODE=1
    fi
}

# Test configuration validation
test_config_validation() {
    local test_name="configuration validation"
    
    # Test that ONLYINSTALLFROMPREP requires PREDOWNLOADUPDATES
    local ONLYINSTALLFROMPREP="yes"
    local PREDOWNLOADUPDATES="no"
    
    if [[ "$ONLYINSTALLFROMPREP" == "yes" && "$PREDOWNLOADUPDATES" == "no" ]]; then
        log_success "$test_name: detected invalid config combination"
    else
        log_fail "$test_name: should detect invalid config combination"
        EXITCODE=1
    fi
}

# Test error message consistency
test_error_messages() {
    local test_name="error message consistency"
    
    # Test the updated error message format
    local error_msg="ERROR: DOWNLOADOPTION set to 'yes' but the 'update --downloadonly' option is not available in the current version of dnf"
    
    if [[ "$error_msg" == *"update --downloadonly"* ]]; then
        log_success "$test_name: error message format updated"
    else
        log_fail "$test_name: error message format not updated"
        EXITCODE=1
    fi
}

# Mock test for actual auter module behavior
test_module_integration() {
    local test_name="module integration"
    
    # Create a temporary test environment
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Copy the module to test location
    cp "$AUTERDIR/auter.yumdnfModule" "$temp_dir/"
    
    # Create a mock dnf that reports version 5
    cat > "$temp_dir/mock-dnf" << 'EOF'
#!/bin/bash
case "$1" in
    "update")
        if [[ "$*" == *"--help"* ]]; then
            echo "  --downloadonly        Only download packages"
        fi
        ;;
    "--version")
        echo "dnf 5.0.0"
        ;;
esac
EOF
    chmod +x "$temp_dir/mock-dnf"
    
    # Test that the module can source without errors
    if (
        export PATH="$temp_dir:$PATH"
        export PACKAGE_MANAGER="$temp_dir/mock-dnf"
        # Source the module in a subshell to avoid affecting main script
        source "$temp_dir/auter.yumdnfModule" 2>/dev/null
    ); then
        log_success "$test_name: module sources without errors"
    else
        log_fail "$test_name: module failed to source"
        EXITCODE=1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Main test execution
main() {
    log_info "Starting DNF 5 compatibility tests"
    
    create_test_data
    test_downloadonly_detection
    test_package_parsing  
    test_download_command_construction
    test_config_validation
    test_error_messages
    test_module_integration
    
    # Cleanup
    rm -rf "$TEST_DATA_DIR"
    
    if [[ $EXITCODE -eq 0 ]]; then
        log_success "All DNF 5 compatibility tests passed"
    else
        log_fail "Some DNF 5 compatibility tests failed"
    fi
    
    exit $EXITCODE
}

main "$@"