# Supported Targets

This document describes which targets are explicitly supported and tested by `zig-cross-compile-action`, and the level of support provided.

We categorize targets into three “tiers”:

- **Tier 1 – Verified:**
  Automatically tested in the E2E workflow. These combinations are expected to work reliably.
- **Tier 2 – Expected:**
  Not tested in every commit but are known, common Zig targets that work well in practice. Issues are possible; PRs welcome.
- **Tier 3 – Best effort / exotic:**
  Supported by Zig but not actively tested by this Action. Use at your own risk.

> Note: This Action supports **only Linux and macOS as hosts**.
> Windows is supported only as a *target*, not as a *runner*.

---

## Tier 1 – Verified in CI

These targets are validated in the `.github/workflows/e2e-test.yml` workflow.

| Target triple                 | Alias          | Host runner     | Language / Use case        | Status      |
| ---------------------------- | -------------- | --------------- | -------------------------- | ----------- |
| `aarch64-linux-musl`         | `linux-arm64`  | `ubuntu-latest` | Go (CGO) cross-build       | ✅ Verified |
| `aarch64-unknown-linux-gnu`  | —              | `ubuntu-latest` | Rust cross-build           | ✅ Verified |
| `x86_64-windows-gnu`         | `windows-x64`  | `ubuntu-latest` | C → Windows PE64           | ✅ Verified |
| `aarch64-macos`              | `macos-arm64`  | `macos-latest`  | C → macOS ARM64 (Mach-O)   | ✅ Verified |

**Guarantees:**

- These combinations are built in the E2E workflow and verified via `file` for correct architecture/binary type.
- Regressions on these targets are considered **bugs** and preferably resolved in a patch release.

---

## Tier 2 – Expected to work

Targets that closely resemble Tier 1, or are well-supported by Zig, but are not explicitly in the E2E matrix.

| Target triple                 | Possible alias      | Expected host        | Notes                                                         |
| ---------------------------- | ------------------- | -------------------- | ------------------------------------------------------------- |
| `x86_64-linux-musl`          | `linux-x64`         | `ubuntu-latest`      | Static Linux x64, ideal for “glue-free” distributables.      |
| `x86_64-linux-gnu`           | —                   | `ubuntu-latest`      | Glibc Linux x64, for classic distro compatibility.           |
| `x86_64-macos`               | `macos-x64`         | `macos-latest`       | macOS Intel, similar to `aarch64-macos`.                     |
| `armv7-linux-gnueabihf`      | —                   | `ubuntu-latest`      | 32-bit ARM (older Pi / embedded).                            |
| `riscv64-linux-gnu`          | —                   | `ubuntu-latest`      | RISC-V 64-bit, up-and-coming architecture.                   |

**Guideline:**

- If the target resembles a Tier-1 target and is supported by Zig, you can reasonably expect the Action to work.
- If you encounter issues on these targets, please open an issue with:
  - Host OS
  - Zig version
  - Target triple
  - Build command + full linker error

---

## Tier 3 – Best effort / exotic

Examples of more exotic Zig targets that *theoretically* should work, but are not automatically tested in this repo:

| Target triple                 | Type               |
| ---------------------------- | ------------------ |
| `powerpc64le-linux-gnu`      | IBM POWER          |
| `s390x-linux-gnu`            | IBM Z / mainframe  |
| …                            | …                  |

Use-case: niche deployments, HPC, mainframe. The rule here is: if Zig supports the target, the Action will *only* ensure `CC` / `CXX` and relevant env vars are set correctly. Issues related to extra toolchains or sysroots are out of scope.

---

## Target aliasing

The Action supports several human-friendly aliases, which match to Zig targets:

| Alias          | Zig target triple      |
| -------------- | ---------------------- |
| `linux-arm64`  | `aarch64-linux-musl`   |
| `linux-aarch64`| `aarch64-linux-musl`   |
| `linux-x64`    | `x86_64-linux-musl`    |
| `linux-amd64`  | `x86_64-linux-musl`    |
| `macos-arm64`  | `aarch64-macos`        |
| `darwin-arm64` | `aarch64-macos`        |
| `macos-x64`    | `x86_64-macos`         |
| `darwin-amd64` | `x86_64-macos`         |
| `windows-x64`  | `x86_64-windows-gnu`   |
| `windows-amd64`| `x86_64-windows-gnu`   |

If you want to be very specific (e.g., a specific glibc version), use the full Zig target triple, such as `x86_64-linux-gnu.2.31`. Note: Rust integration is automatically configured only for targets **without** a version suffix.

---

## Host OS support

- ✅ **Ubuntu (Linux) runners** – fully supported
- ✅ **macOS runners** – fully supported
- ❌ **Windows runners** – actively rejected as host (`RUNNER_OS == Windows` → hard fail)

Windows is supported solely as a *target* (via `x86_64-windows-gnu`), not as a platform to run the Action on.
