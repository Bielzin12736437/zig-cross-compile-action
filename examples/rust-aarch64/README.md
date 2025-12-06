# Verified Reference Architecture: Rust → aarch64-unknown-linux-gnu

This example demonstrates how to cross-compile a Rust application for Linux ARM64 (glibc).
The action acts as the **linker** for Cargo, preventing the need for an external GCC toolchain.

- **Status:** Tier 1 (Verified in CI)
- **Host:** `ubuntu-latest`
- **Target:** `aarch64-unknown-linux-gnu`

## Configuration

The action configures Cargo to use `zig cc` as the linker for the requested target.

```yaml
jobs:
  build-rust:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          targets: aarch64-unknown-linux-gnu

      - name: Build Rust (Release)
        uses: Rul1an/zig-cross-compile-action@v2
        with:
          target: aarch64-unknown-linux-gnu
          project-type: rust
          # Note: No 'rust-musl-mode' needed for GNU targets
          cmd: cargo build --release --target aarch64-unknown-linux-gnu
```
