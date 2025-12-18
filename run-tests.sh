#!/bin/bash

# Test runner for auter
# Runs all available tests in order

# Note: Don't use set -e here as we want to continue running tests even if some fail
# Enable job control for better signal handling
set -m

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
TEST_DIR="$SCRIPT_DIR/tests"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -f "auter" ]] || [[ ! -d "tests" ]]; then
        log_error "Please run this script from the auter project root directory"
        exit 1
    fi
    
    # Check for container runtime (prefer Podman, fallback to Docker)
    if command -v podman >/dev/null 2>&1; then
        log_info "Podman found - using Podman for container tests"
        CONTAINER_CMD="podman"
        DOCKER_AVAILABLE=true
    elif command -v docker >/dev/null 2>&1; then
        log_info "Docker found - using Docker for container tests"
        CONTAINER_CMD="docker"
        DOCKER_AVAILABLE=true
    else
        log_info "Neither Podman nor Docker found - container tests will be skipped"
        CONTAINER_CMD=""
        DOCKER_AVAILABLE=false
    fi
}

# Run a single test file
run_test() {
    local test_file="$1"
    local test_name
    test_name="$(basename "$test_file" .sh)"
    
    log_info "Running $test_name..."
    
    # Run test in background to make it interruptible
    # Use longer timeout for build tests (RPM/DEB building can be slow)
    if [[ "$test_name" == *"build"* ]]; then
        timeout 1200 "$test_file" &
    else
        timeout 600 "$test_file" &
    fi
    local test_pid=$!
    
    # Wait for the test, but allow interruption
    if wait $test_pid; then
        log_success "$test_name passed"
        return 0
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_error "$test_name timed out after 10 minutes"
        elif [[ $exit_code -eq 130 ]]; then
            log_info "$test_name interrupted by user"
            return 130
        else
            log_error "$test_name failed (exit code: $exit_code)"
        fi
        return 1
    fi
}

# Global flag to prevent duplicate cleanup
CLEANUP_DONE=false

# Cleanup function for signal handling (used by trap handlers)
# shellcheck disable=SC2329  # Function used indirectly via trap
cleanup_on_exit() {
    # Prevent duplicate cleanup
    if [[ "$CLEANUP_DONE" == "true" ]]; then
        return
    fi
    CLEANUP_DONE=true
    
    local exit_code=$?
    log_info "Cleaning up test containers..."
    
    # Kill any background test processes first
    jobs -p | xargs -r kill 2>/dev/null || true
    
    # Stop any running test containers
    if [[ -n "$CONTAINER_CMD" ]] && command -v "$CONTAINER_CMD" >/dev/null 2>&1; then
        # List of container name patterns used by tests
        local container_patterns=(
            "auter-test-*"
            "auter-rpmbuild-*" 
            "auter-debuild-*"
        )
        
        for pattern in "${container_patterns[@]}"; do
            local containers
            containers=$("$CONTAINER_CMD" ps -q -f name="$pattern" 2>/dev/null || true)
            if [[ -n "$containers" ]]; then
                log_info "Stopping containers matching $pattern"
                # Use kill first, then stop if that doesn't work
                echo "$containers" | xargs "$CONTAINER_CMD" kill >/dev/null 2>&1 || true
                echo "$containers" | xargs "$CONTAINER_CMD" stop >/dev/null 2>&1 || true
            fi
        done
    fi
    
    exit "$exit_code"
}

# Set up signal traps
trap cleanup_on_exit EXIT
trap 'log_info "Received interrupt signal, cleaning up..."; cleanup_on_exit' INT TERM

# Main test execution
main() {
    local failed_tests=0
    local total_tests=0
    
    log_info "Starting auter test suite"
    check_prerequisites
    
    # Build test list based on phases and skip flags
    local tests=()
    
    # Process each phase in order
    for phase in static unit build integration; do
        local skip_var="SKIP_${phase^^}"
        
        if [[ "${!skip_var:-}" == "1" ]]; then
            log_info "Skipping ${phase} tests (--skip-${phase} specified)"
            continue
        fi
        
        # Check Docker requirement
        if [[ "${PHASE_REQUIRES_DOCKER[$phase]}" == "true" ]] && [[ "$DOCKER_AVAILABLE" != "true" ]]; then
            log_info "Skipping ${phase} tests (require Docker)"
            continue
        fi
        
        # Add tests for this phase
        local tests_str="${TEST_PHASES[$phase]}"
        read -ra phase_tests <<< "$tests_str"
        tests+=("${phase_tests[@]}")
    done
    
    # Run each test
    log_info "Found ${#tests[@]} tests to run"
    for test_file in "${tests[@]}"; do
        log_info "Checking test: $test_file"
        if [[ -x "$test_file" ]]; then
            ((total_tests++))
            if ! run_test "$test_file"; then
                local test_exit=$?
                if [[ $test_exit -eq 130 ]]; then
                    log_info "Test suite interrupted by user"
                    exit 130
                fi
                ((failed_tests++))
            fi
            echo "----------------------------------------"
        else
            log_info "Skipping $test_file (not executable or not found)"
        fi
    done
    
    # Summary
    echo
    log_info "Test Summary:"
    echo "  Total tests: $total_tests"
    echo "  Passed: $((total_tests - failed_tests))"
    echo "  Failed: $failed_tests"
    
    if [[ $failed_tests -eq 0 ]]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "$failed_tests test(s) failed"
        exit 1
    fi
}

# Define test phases
declare -A TEST_PHASES=(
    ["static"]="$TEST_DIR/01-spellcheck.sh $TEST_DIR/05-shellcheck.sh"
    ["unit"]="$TEST_DIR/30-dnf5-compatibility.sh"
    ["build"]="$TEST_DIR/10-rpmbuild.sh $TEST_DIR/20-debuild.sh"
    ["integration"]="$TEST_DIR/35-container-dnf-integration.sh $TEST_DIR/36-container-apt-integration.sh"
)

declare -A PHASE_DESCRIPTIONS=(
    ["static"]="Static Analysis: spellcheck, shellcheck"
    ["unit"]="Unit Tests: DNF5 compatibility unit tests"
    ["build"]="Build Tests: RPM and DEB package creation"
    ["integration"]="Integration Tests: Container-based functional tests"
)

declare -A PHASE_REQUIRES_DOCKER=(
    ["static"]="false"
    ["unit"]="false"
    ["build"]="true"
    ["integration"]="true"
)

# Run tests for a specific phase
run_phase() {
    local phase="$1"
    local tests_str="${TEST_PHASES[$phase]}"
    read -ra tests <<< "$tests_str"
    
    log_info "Running ${phase} tests only"
    
    # Check Docker requirement
    if [[ "${PHASE_REQUIRES_DOCKER[$phase]}" == "true" ]] && ! command -v docker >/dev/null 2>&1; then
        log_error "Docker not available, cannot run ${phase} tests"
        exit 1
    fi
    
    local failed=0
    for test in "${tests[@]}"; do
        if [[ -x "$test" ]]; then
            if ! run_test "$test"; then
                failed=1
            fi
        fi
    done
    exit $failed
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Run the auter test suite"
    echo ""
    echo "Phase Options:"
    for phase in static unit build integration; do
        echo "  --${phase}-only        Run only ${phase} tests"
    done
    echo ""
    for phase in static unit build integration; do
        echo "  --skip-${phase}        Skip ${phase} tests"
    done
    echo ""
    echo "Other Options:"
    echo "  --help, -h             Show this help message"
    echo ""
    echo "Test Phases:"
    for phase in static unit build integration; do
        echo "  ${PHASE_DESCRIPTIONS[$phase]}"
    done
    echo ""
    echo "Individual tests can be run directly:"
    echo "  ./tests/30-dnf5-compatibility.sh"
    echo "  ./tests/35-container-dnf-integration.sh"
    echo "  ./tests/36-container-apt-integration.sh"
}

# Parse command line arguments
for arg in "$@"; do
    case "$arg" in
        "--help"|"-h")
            show_help
            exit 0
            ;;
        "--static-only")
            run_phase "static"
            ;;
        "--unit-only")
            run_phase "unit"
            ;;
        "--build-only")
            run_phase "build"
            ;;
        "--integration-only")
            run_phase "integration"
            ;;
        "--skip-static")
            export SKIP_STATIC=1
            ;;
        "--skip-unit")
            export SKIP_UNIT=1
            ;;
        "--skip-build")
            export SKIP_BUILD=1
            ;;
        "--skip-integration")
            export SKIP_INTEGRATION=1
            ;;
        *)
            log_error "Unknown option: $arg"
            show_help
            exit 1
            ;;
    esac
done

main "$@"