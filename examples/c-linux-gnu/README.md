# C on Linux (glibc) – Verified Reference Architecture

**Target:** `x86_64-linux-gnu`
**Host runner:** `ubuntu-latest`
**Tier:** 1 (see `TARGETS.md`)

This example shows how to cross compile a simple C program for **Linux x86_64 with glibc** using Zig as the compiler, via [`Rul1an/zig-cross-compile-action`](https://github.com/Rul1an/zig-cross-compile-action).

The example is intentionally minimal:

- one `main.c` in this directory,
- compiled with `$CC` provided by the Action,
- producing a dynamically linked ELF binary for glibc based Linux systems.

---

## Files

- `main.c`
  Tiny C program that prints a line to stdout. It is only here to prove the toolchain works end to end.

- `README.md`
  This document.

---

## How this is used in CI

The `e2e-test.yml` workflow contains a matrix job that builds and verifies this example as part of the Tier 1 coverage for Linux:

```yaml
jobs:
  test-c-linux:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - name: linux-gnu
            target: x86_64-linux-gnu
            example-dir: c-linux-gnu
          # other entries omitted

    steps:
      - uses: actions/checkout@v4

      - name: Build C for Linux (glibc)
        uses: Rul1an/zig-cross-compile-action@v2
        with:
          target: x86_64-linux-gnu
          project-type: c
          cmd: |
            cd examples/c-linux-gnu
            mkdir -p dist
            $CC main.c -o dist/app

      - name: Inspect binary
        run: |
          file examples/c-linux-gnu/dist/app
          ./examples/c-linux-gnu/dist/app
```

## When to use this pattern

Reach for this setup when you want to:

*   build Linux x86_64 binaries that link against the system glibc,
*   avoid Docker images with pre installed cross compilers,
*   keep your C build system untouched and let the Action inject the right `$CC`.

If you need a fully static binary for maximum portability across distros, see the `c-linux-musl` example instead.
