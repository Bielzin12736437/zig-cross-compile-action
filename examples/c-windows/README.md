# Verified Reference Architecture: C → x86_64-windows-gnu

This example demonstrates how to cross-compile a C application for Windows (x64) from a Linux runner.

- **Status:** Tier 1 (Verified in CI)
- **Host:** `ubuntu-latest`
- **Target:** `x86_64-windows-gnu` (Alias: `windows-x64`)

## Configuration

The key is simply using `$CC` which the action configures to `zig cc -target x86_64-windows-gnu`.

```yaml
jobs:
  build-win:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Cross-compile C for Windows
        uses: Rul1an/zig-cross-compile-action@v2
        with:
          target: windows-x64
          project-type: c
          cmd: $CC main.c -o dist/app.exe
```
