# C on Linux (musl, static) – Verified Reference Architecture

**Target:** `x86_64-linux-musl`
**Host runner:** `ubuntu-latest`
**Tier:** 1 (see `TARGETS.md`)

This example shows how to cross compile a simple C program for **Linux x86_64 with musl**, producing a **statically linked** binary. The build runs on a standard GitHub Actions Linux runner and uses Zig as the compiler via [`Rul1an/zig-cross-compile-action`](https://github.com/Rul1an/zig-cross-compile-action).

The resulting binary is:

- `ELF 64 bit LSB`,
- statically linked against musl,
- suitable for running on a wide range of Linux distributions without glibc compatibility concerns.

---

## Files

- `main.c`
  Small C program that prints a line to stdout. It is only there to verify the toolchain and static linking.

- `README.md`
  This document.

---

## How this is used in CI

The `e2e-test.yml` workflow contains a matrix job that builds and verifies this example as part of the Tier 1 coverage for static Linux:

```yaml
jobs:
  test-c-linux:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - name: linux-musl
            target: x86_64-linux-musl
            example-dir: c-linux-musl
          # other entries omitted

    steps:
      - uses: actions/checkout@v4

      - name: Build C for Linux (musl, static)
        uses: Rul1an/zig-cross-compile-action@v2
        with:
          target: x86_64-linux-musl
          project-type: c
          cmd: |
            cd examples/c-linux-musl
            mkdir -p dist
            $CC main.c -o dist/app

      - name: Inspect binary
        run: |
          file examples/c-linux-musl/dist/app
          ./examples/c-linux-musl/dist/app
```

## When to use this pattern

Use this target when you want:

*   portable Linux CLI tools that run on many distributions without a matching glibc,
*   minimal external runtime dependencies,
*   to keep your existing C build logic and only swap the compiler.

Typical use cases include:

*   small utilities shipped as part of larger systems,
*   tools that run on older or mixed Linux environments,
*   CI pipelines that build "one static binary per target" without container orchestration.
