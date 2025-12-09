#!/usr/bin/env bash
set -u

# unit-env.sh - Tests for scripts/setup-env.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
SETUP_ENV="$ROOT_DIR/scripts/setup-env.sh"

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

# Mock GITHUB_ENV and GITHUB_OUTPUT
export GITHUB_ENV="/tmp/github_env_mock"
export GITHUB_OUTPUT="/tmp/github_output_mock"
touch "$GITHUB_ENV" "$GITHUB_OUTPUT"

echo "--- Test 1: Target Preset Resolution ---"
(
    export INPUT_TARGET_PRESET="linux-x86_64-gnu"
    source "$SETUP_ENV" || exit 1
    if [[ "$ZIG_TARGET" != "x86_64-linux-gnu" ]]; then
        fail "Expected x86_64-linux-gnu, got '$ZIG_TARGET'"
    fi
) && pass "Preset linux-x86_64-gnu resolved correctly"

echo "--- Test 2: Helper Functions (Go) ---"
(
    export INPUT_PROJECT_TYPE="go"
    export INPUT_ZIG_TARGET="aarch64-macos"
    source "$SETUP_ENV" || exit 1

    if [[ "$GOOS" != "darwin" ]]; then fail "Expected GOOS=darwin, got '$GOOS'"; fi
    if [[ "$GOARCH" != "arm64" ]]; then fail "Expected GOARCH=arm64, got '$GOARCH'"; fi
    if [[ "$CGO_ENABLED" != "1" ]]; then fail "Expected CGO_ENABLED=1"; fi
) && pass "Go env vars set correctly for aarch64-macos"

echo "--- Test 3: Legacy Rust Linker Logic ---"
(
    export INPUT_PROJECT_TYPE="rust"
    export INPUT_ZIG_TARGET="x86_64-unknown-linux-musl"
    export RUNNER_TEMP="/tmp"

    source "$SETUP_ENV" || exit 1

    EXPECTED_VAR="CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER"
    # Read from GITHUB_ENV to verification
    if ! grep -q "$EXPECTED_VAR=" "$GITHUB_ENV"; then
        fail "Expected $EXPECTED_VAR in GITHUB_ENV"
    fi
) && pass "Rust linker var created"

rm "$GITHUB_ENV" "$GITHUB_OUTPUT"
echo "All env tests passed."
