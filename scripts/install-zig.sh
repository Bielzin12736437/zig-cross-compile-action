#!/usr/bin/env bash
set -euo pipefail

# install-zig.sh
# Downloads and installs Zig with strict checksum verification.
#
# Inputs (Env Vars):
#   ZIG_VERSION:    Version to install (default: 0.13.0)
#   STRICT_VERSION: "true" to fail if version not in JSON, "false" to allow fallback (not implemented yet, fails safe)
#   RUNNER_TOOL_CACHE: GitHub Actions tool cache directory (optional)

ZIG_VERSION="${ZIG_VERSION:-0.13.0}"
STRICT_VERSION="${STRICT_VERSION:-true}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_FILE="$SCRIPT_DIR/zig-versions.json"

log() { echo "::notice::[install-zig] $1"; }
die() { echo "::error::[install-zig] $1"; exit 1; }

# 1. Platform Detection
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64)  ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    *) die "Unsupported architecture: $ARCH" ;;
esac

if [[ "$OS" == "darwin" ]]; then
    PLATFORM_KEY="${ARCH}-macos"
elif [[ "$OS" == "linux" ]]; then
    PLATFORM_KEY="${ARCH}-linux"
elif [[ "$OS" == *"mingw"* || "$OS" == *"cygwin"* || "$OS" == "windows_nt" ]]; then
    OS="windows"
    PLATFORM_KEY="${ARCH}-windows"
else
    # Fallback/Unknown
    PLATFORM_KEY="${ARCH}-${OS}"
    log "Warning: Unknown OS '$OS', trying key '$PLATFORM_KEY'"
fi

log "Resolving Zig $ZIG_VERSION for $PLATFORM_KEY..."

# 2. Lookup in JSON
if [[ ! -f "$JSON_FILE" ]]; then
    die "Version manifest not found at $JSON_FILE"
fi

# Use jq to extract data. Fail if jq not installed (standard on runners).
if ! command -v jq >/dev/null; then
    die "jq is required but not installed."
fi

URL=$(jq -r --arg v "$ZIG_VERSION" --arg p "$PLATFORM_KEY" '.[$v][$p].url // empty' "$JSON_FILE")
SHA=$(jq -r --arg v "$ZIG_VERSION" --arg p "$PLATFORM_KEY" '.[$v][$p].sha256 // empty' "$JSON_FILE")

if [[ -z "$URL" || -z "$SHA" ]]; then
    if [[ "$STRICT_VERSION" == "true" ]]; then
        die "Version '$ZIG_VERSION' for '$PLATFORM_KEY' not found in zig-versions.json (Strict Mode). Please update the manifest."
    else
        log "Version not found in manifest. Non-strict mode not fully implemented for dynamic download. Failing safe."
        exit 1
    fi
fi

# 3. Download & Verify
WORK_DIR="${RUNNER_TEMP:-/tmp}/zig-install-Process$$"
mkdir -p "$WORK_DIR"
ARCHIVE_NAME=$(basename "$URL")
ARCHIVE_PATH="$WORK_DIR/$ARCHIVE_NAME"

log "Downloading $URL..."
curl -sSfL "$URL" -o "$ARCHIVE_PATH"

log "Verifying checksum..."
# Calculate SHA256
if command -v sha256sum >/dev/null; then
    CALCULATED_SHA=$(sha256sum "$ARCHIVE_PATH" | cut -d' ' -f1)
elif command -v shasum >/dev/null; then
    CALCULATED_SHA=$(shasum -a 256 "$ARCHIVE_PATH" | cut -d' ' -f1)
else
    die "No sha256sum or shasum found."
fi

if [[ "$CALCULATED_SHA" != "$SHA" ]]; then
    die "Checksum mismatch! Expected $SHA, got $CALCULATED_SHA"
fi
log "Checksum ok."

# 4. Install
# Use RUNNER_TOOL_CACHE if available to persist between jobs if cache logic enabled (GitHub logic),
# but standard pattern is to extract to checks-in path or tool cache.
# We will use a dedicated path.
INSTALL_ROOT="${RUNNER_TOOL_CACHE:-$HOME/.local/bin}/zig/$ZIG_VERSION/$PLATFORM_KEY"
mkdir -p "$INSTALL_ROOT"

log "Extracting to $INSTALL_ROOT..."
if [[ "$ARCHIVE_NAME" == *.zip ]]; then
    unzip -q "$ARCHIVE_PATH" -d "$WORK_DIR/extracted"
else
    tar -xf "$ARCHIVE_PATH" -C "$WORK_DIR/extracted"
fi

# Zig archives usually have a top-level folder zig-{os}-{arch}-{version}/
# We want to move contents to INSTALL_ROOT so that $INSTALL_ROOT/zig exists.
SUBDIR=$(ls "$WORK_DIR/extracted" | head -n1)
mv "$WORK_DIR/extracted/$SUBDIR"/* "$INSTALL_ROOT/"

# Verify binary
ZIG_BIN="$INSTALL_ROOT/zig"
if [[ ! -x "$ZIG_BIN" ]]; then
    if [[ "$OS" == "windows" ]]; then
       # Windows .exe check?
       if [[ ! -f "$INSTALL_ROOT/zig.exe" ]]; then
           die "zig.exe not found after extraction."
       fi
       ZIG_BIN="$INSTALL_ROOT/zig.exe"
    else
       die "zig binary not found or not executable at $ZIG_BIN"
    fi
fi

# 5. Output / Path
log "Successfully installed Zig $($ZIG_BIN version) at $INSTALL_ROOT"

echo "$INSTALL_ROOT" >> "$GITHUB_PATH"
# Also set ZIG_PATH output for step reference if needed, but GITHUB_PATH is main mechanism.
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "zig_path=$ZIG_BIN" >> "$GITHUB_OUTPUT"
    echo "zig_version_resolved=$ZIG_VERSION" >> "$GITHUB_OUTPUT"
fi
