# Zig Cross-Compile Action

A secure, performance-focused GitHub Action to setup the Zig toolchain and cross-compile C, C++, Rust, Go, and Zig projects.

## v3.0 Features
- **Strict Versioning**: Exact version pinning with checksum verification (SHA256).
- **Caching**: Built-in `~/.cache/zig` support to speed up builds.
- **Supply Chain Security**: Opt-in SBOM generation (Syft) and artifact signing (Cosign).
- **Presets**: Easy target aliases (`linux-x86_64-musl`, `macos-arm64`).
- **Polyglot**: Configures cross-compilation environment for C/Go/Rust automatically.

## Usage Profiles

### 1. Minimal Development
Just install Zig and set up the environment.

```yaml
- uses: Rul1an/zig-cross-compile-action@v3
  with:
    version: "0.13.0"
    target_preset: "linux-x86_64-musl"
    setup_only: "true"

- run: zig build -Dtarget=$ZIG_TARGET
```

### 2. Standard Release (Cached & Tested)
Run tests, benchmark, and build with caching enabled.

```yaml
- uses: Rul1an/zig-cross-compile-action@v3
  with:
    version: "0.13.0"
    target_preset: "linux-x86_64-musl"
    use_cache: "true"

    # Run tests before building. Fails job if tests fail.
    run_tests: "true"
    test_script: |
      zig build test
      zig build test-parity

    perf_command: "zig build bench"

    # Build command
    project-type: "zig"
    cmd: "-Doptimize=ReleaseSafe"
```

### 3. Hardened Release (SBOM + Signing)
Generate accurate SBOMs and sign artifacts (Linux runners only).

```yaml
- uses: Rul1an/zig-cross-compile-action@v3
  with:
    version: "0.13.0"
    target_preset: "linux-x86_64-musl"
    setup_only: "true"

    # Supply Chain
    sbom: "true"
    sbom_target: "zig-out/bin/my-app"

    sign: "true"
    sign_artifact: "zig-out/bin/my-app"
```

## Inputs

| Input | Description | Default |
| :--- | :--- | :--- |
| `version` | Zig version (e.g. `0.13.0`). Use `strict_version: true` (default) for exact matches. | `0.13.0` |
| `target_preset` | Alias for common targets (`linux-x86_64`, `linux-arm64`, `macos-arm64`, `windows-x86_64`). | |
| `target` | Explicit Zig target triple (e.g. `x86_64-linux-gnu`). **Supersedes** `target_preset`. | |
| `project-type` | `zig`, `custom`, `c`, `go`, `rust`. Sets up environment variables. | `custom` |
| `setup_only` | If `true`, installs toolchain and env but skips build command. | `false` |
| `use_cache` | Enable `~/.cache/zig` persistence. | `false` |
| `sbom` | Generate SBOM with Syft (Linux only). | `false` |
| `sign` | Sign artifact with Cosign Keyless (Linux only). | `false` |

### Polyglot Support
Setting `project-type` to `go`, `rust`, or `c` calculates the correct cross-compilation environment variables (e.g., `CC`, `CGO_ENABLED`, `CARGO_TARGET_..._LINKER`) but relies on you to provide the build command via `cmd` or a subsequent run step. The action acts as a "toolchain bootstrapper" for these languages.

### Caching Note
When `use_cache: true`, we cache `~/.cache/zig` and include `build.zig` / `go.mod` / `Cargo.lock` in the cache key.
> **Tip:** Zig caches can grow large. GitHub limits caches to 10GB. You may need to clear caches occasionally if testing many targets.

## Migration v2 -> v3
v3 is backwards compatible with v2 inputs (`version`, `target`, `cmd`, `project-type`).
- `verify-level` is deprecated (no-op).
- `project-type` now strictly means "setup environment"; for non-Zig projects, it functions identically to `custom` but with smarter env vars.

## Real-world Usage
This action is used to build and release [Rul1an/llm-cost](https://github.com/Rul1an/llm-cost) (a cross-platform Zig tool for LLM token estimation). Check that repository for a production-grade workflow example.
