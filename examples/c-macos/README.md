# Verified Reference Architecture: C → aarch64-macos

This example demonstrates how to cross-compile a C application for macOS (Apple Silicon) from a macOS runner.
*Note: Cross-compiling for macOS from Linux is technically possible but often requires complex SDK setup. We verify this on `macos-latest`.*

- **Status:** Tier 1 (Verified in CI)
- **Host:** `macos-latest`
- **Target:** `aarch64-macos` (Alias: `macos-arm64`)

## Configuration

Uses `$CC` (`zig cc`) to target Apple Silicon.

```yaml
jobs:
  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Compile C for macOS ARM64
        uses: Rul1an/zig-cross-compile-action@v2
        with:
          target: macos-arm64
          project-type: c
          cmd: $CC main.c -o dist/app-macos
```
