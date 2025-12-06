#!/usr/bin/env bash
# Local CI wrapper for zig-cross-compile-action
#
# This script wraps `act` so you can run GitHub Actions workflows locally.
#
# Usage:
#   ./scripts/local-ci.sh                # runs the default smoke test (validate-go)
#   ./scripts/local-ci.sh validate-go    # run only the validate-go job
#   ./scripts/local-ci.sh validate-rust-gnu
#   ./scripts/local-ci.sh validate-c
#   ./scripts/local-ci.sh all            # run all jobs in all workflows
#
# Requirements:
#   - act >= 0.2.81
#   - Docker (Docker Desktop, OrbStack, or Docker Engine)
#
# Notes:
#   - Only Linux-based jobs are realistically simulated (ubuntu-latest).
#   - macOS jobs still run only on real GitHub-hosted runners.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [job-name|all]

Examples:
  $(basename "$0")              # default: validate-go (fast smoke test)
  $(basename "$0") validate-go
  $(basename "$0") validate-rust-gnu
  $(basename "$0") validate-c
  $(basename "$0") all          # run all jobs in all workflows

Notes:
  - Requires 'act' (>= 0.2.81) and Docker.
  - Only Linux jobs are faithfully reproduced; macOS jobs still require GitHub Actions.
EOF
}

JOB_NAME="${1:-validate-go}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

echo "Launching Local CI"
echo "   repo:   $REPO_ROOT"
echo "   job:    ${JOB_NAME}"

# --- Dependency checks -------------------------------------------------------

if ! command -v act &>/dev/null; then
  echo "Error: 'act' not found."
  echo "   Install it, for example on macOS:"
  echo "     brew install nektos/tap/act"
  exit 1
fi

if ! command -v docker &>/dev/null; then
  echo "Error: 'docker' not found."
  echo "   Install Docker Desktop (macOS) or Docker Engine (Linux) first."
  exit 1
fi

# Optional: warn if act is too old. We don't enforce strictly, but we hint.
ACT_VERSION_RAW="$(act --version 2>/dev/null || echo "unknown")"
echo "act version: ${ACT_VERSION_RAW}"

# --- Runner image & architecture --------------------------------------------

# Use a full ubuntu-latest image that mimics GitHub Actions as closely as possible.
# You can override this via ACT_IMAGE env var if needed.
ACT_IMAGE="${ACT_IMAGE:-ghcr.io/catthehacker/ubuntu:act-latest}"

# On Apple Silicon (arm64), we usually want x86_64 containers so builds behave
# like GitHub's ubuntu-latest (amd64) runners.
ARCH_FLAG=()
UNAME_S="$(uname -s || echo "")"
UNAME_M="$(uname -m || echo "")"

if [[ "$UNAME_S" == "Darwin" && "$UNAME_M" == "arm64" ]]; then
  echo "Detected macOS arm64; forcing container-architecture linux/amd64"
  ARCH_FLAG=(--container-architecture linux/amd64)
else
  echo "Host: ${UNAME_S}/${UNAME_M} (no forced container architecture)"
fi

# --- Job selection -----------------------------------------------------------

ACT_ARGS=()
if [[ "$JOB_NAME" == "all" ]]; then
  echo "Running ALL jobs in all workflows"
else
  echo "Running single job: $JOB_NAME"
  ACT_ARGS+=(-j "$JOB_NAME")
fi

# --- Run act -----------------------------------------------------------------

cd "$REPO_ROOT"

echo "Using image mapping: ubuntu-latest=${ACT_IMAGE}"
echo

set -x
act \
  "${ACT_ARGS[@]}" \
  -P "ubuntu-latest=${ACT_IMAGE}" \
  "${ARCH_FLAG[@]}" \
  --rm
set +x

echo
echo "Local CI finished."
