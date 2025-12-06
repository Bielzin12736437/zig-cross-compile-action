# Verified Reference Architecture: Go (CGO) → aarch64-linux-musl

This example demonstrates how to cross-compile a Go application using CGO suitable for minimal Linux environments (like Alpine).

- **Status:** Tier 1 (Verified in CI)
- **Host:** `ubuntu-latest`
- **Target:** `aarch64-linux-musl` (Alias: `linux-arm64`)

## Configuration

The action automatically sets `CGO_ENABLED=1`, `GOOS=linux`, and `GOARCH=arm64`.

```yaml
jobs:
  build-go:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.23'

      - name: Build Go (CGO)
        uses: Rul1an/zig-cross-compile-action@v2
        with:
          target: linux-arm64
          project-type: go
          cmd: go build -o dist/app-linux-arm64 .
```
