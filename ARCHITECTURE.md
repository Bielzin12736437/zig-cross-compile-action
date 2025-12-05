# Technical Design: Zig Cross-Compiler Action (v2.x)

**Status:** Production (v2.2.0)
**Philosophy:** Infrastructure, Not Helper.
**Core Toolchain:** Zig `cc` / `c++`.

## 0. Context & Goals
The `zig-cross-compile-action` is a rigorous, Docker-free toolchain injection for GitHub Actions. It replaces heavy containerized solutions (like `cross-rs`) with Zig's native ability to cross-compile C/C++ code, leveraging its bundled libc and linker.

**Current State (v2.2.0):**
*   **Zero Docker:** Runs directly on the host runner (Linux/macOS).
*   **Opinionated:** Unconditionally claims `$CC`, `$CXX`, `$AR`, `$RANLIB`.
*   **Strict Policies:** Hard fail on Windows hosts; opt-in only for Rust+Musl.
*   **Smart Automation:** Detects `Cargo.toml`/`go.mod` to apply correct environment policies.

**Goals:**
1.  **Transparency:** No hidden magic. Errors should be explicit and actionable.
2.  **Performance:** Zero container overhead.
3.  **Correctness:** Prefer explicit failure over "best effort" behavior that breaks silently.

## 1. Scope & Boundaries
To maintain maintainability and trust, we define strict boundaries.

### 1.1 In Scope
*   Cross-compiling C, C++, Rust, and Go binaries via Zig.
*   Mapping strict aliases (e.g., `linux-arm64`) to Zig triples (`aarch64-linux-musl`).
*   Injecting compiler environment variables into the GitHub Action job.

### 1.2 Non-Goals
*   **Build Orchestration:** We do not manage `go mod`, `cargo build`, or `make`. We provide the *compiler*; the user provides the *build command*.
*   **Toolchain Management:** We do not install Rust (rustup) or Go. That is the user's responsibility.
*   **Windows Host Support:** Bash on Windows (MSYS/Git Bash) is inconsistent. We only support Windows as a *target*, not a *host*.
*   **Project Mutation:** We never touch `Cargo.toml`, `.cargo/config`, or source files.

## 2. Architecture (v2.2.0)

### 2.1 Interface (`action.yml`)
The interface is minimal and typed.

| Input | Description | default |
| :--- | :--- | :--- |
| `version` | Zig version to install. | `0.13.0` |
| `target` | Compile target (alias or triple). | **Required** |
| `project-type` | `auto` (smart), `go`, `rust`, `c`, `custom`. | `auto` |
| `rust-musl-mode` | Policy for Rust+Musl conflicts (`deny`\|`warn`\|`allow`). | `deny` |

### 2.2 The Controller (`setup-env.sh`)
The core logic resides in a Bash script sourceable by the action.

**Key Mechanics:**
1.  **Platform Guard:** Hard `die` if `RUNNER_OS == Windows`.
2.  **Smart Auto-Detection:**
    *   If `project-type: auto`: Check for `Cargo.toml` -> Rust mode. Check for `go.mod` -> Go mode. Else -> C mode.
    *   *Rationale:* Prevents false positives where Rust policies block pure Go projects on Musl.
3.  **Target Normalization:**
    *   Maps naive CI targets (`linux-arm64`) to robust Zig defaults (`aarch64-linux-musl`).
    *   *Design Choice:* Musl is the default for Linux to ensure static compatibility across distros.
4.  **Environment Injection:**
    *   Sets `$CC`, `$CXX` to `zig cc -target ...`.
    *   Sets language-specific vars (`CGO_ENABLED`, `GOOS`, `CARGO_TARGET_..._LINKER`).
    *   *Concurrency:* Wrapper scripts use `mktemp` to support multiple architectural builds in the same job without file collisions.

### 2.3 Policy Enforcement
**Rust + Musl Policy:**
Zig bundles its own Musl libc, which often conflicts with Rust's bundled Musl CRT (duplicate symbols `_start`, `_init`).
*   **Deny (Default):** Fail fast. Advise user to use `gnu` target or `cargo-zigbuild`.
*   **Warn/Allow:** For adventurous users who want to link manually or rely on luck.

## 3. Technical Rationale

### 3.1 Why No Docker?
Traditional cross-compilation uses Docker (e.g., `cross-rs`).
*   **Problem:** Docker-in-Docker issues, slow volume mounts, permission hell, and poor support on macOS runners.
*   **Solution:** Zig is a self-contained cross-compiler. It needs no external system headers or sysroots.

### 3.2 The "Opinionated Environment"
We do not attempt to merge with existing environment variables. We overwrite them.
*   *Why?* If a user asks us to set up a cross-compiler, `CC` *must* be that cross-compiler. Merging behavior leads to debugging nightmares ("Which compiler did Make pick up?").
*   *Philosophy:* If you want "helper" behavior, write a shell script. If you want "infrastructure", use this action.

## 4. Future Roadmap (v3+)

### 4.1 Enhanced Language Presets (`project-type`)
Current presets are functional. Future iterations could interpret them more strictly:
*   `type: c`: Only sets `$CC`/`$CXX`. Unsets `$CGO_ENABLED` to prevent accidental bleed.
*   `type: rust`: Explicitly unsets Go-related vars.

### 4.2 Verification Levels
Currently, we verify basic file headers (ELF/PE/Mach-O).
*   **Proposal:** Add `verify-level: precise`.
*   *Mechanism:* Use `readelf`/`otool` to verify linked libc (ensure no glibc refs in static build) and architecture.

### 4.3 macOS Host Verification
We claim macOS support but primarily test on Linux.
*   **Action:** Add a `macos-latest` job to E2E matrix targeting `macos-arm64` via C.

### 4.4 Documentation as Spec
*   Document patterns for CMake (`-DCMAKE_C_COMPILER=$CC`) and Autotools (`./configure`).
*   Keep the action code simple; move complexity to documentation/examples.

---

**Summary:**
This action is designed to be the foundational block for cross-compilation pipelines. It favors correctness over convenience and explicit configuration over magic.
