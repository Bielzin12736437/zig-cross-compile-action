# Contributing

Thanks for your interest in contributing to `zig-cross-compile-action`!

This action is designed as **infrastructure**, not orchestration: it configures Zig and the cross-compilation environment, but leaves build commands (`go build`, `cargo build`, `make`, …) entirely under your control.

This document explains how to work on the action itself and how to run the same validation workflows locally that CI runs on GitHub Actions.

---

## Local Development & Local CI (`act`)

We strongly recommend running the CI workflows locally before pushing changes. This keeps the repo fast and healthy and avoids back-and-forth on failing workflows.

We use [`act`](https://github.com/nektos/act) to run GitHub Actions workflows locally inside Docker containers.

### Requirements

- **act** ≥ `0.2.81`
  (matrix and job handling have seen important fixes in recent versions)
- **Docker**
  - Docker Desktop / OrbStack on macOS
  - Docker Engine on Linux

> Note
> Local CI only simulates **Linux** runners (`ubuntu-latest`).
> macOS jobs still require real GitHub-hosted runners.

### Scripts

There is a helper script that wraps `act`:

```bash
./scripts/local-ci.sh [job-name|all]
```

**Examples:**

Fast smoke test (Go + CGO):
```bash
./scripts/local-ci.sh
# or:
./scripts/local-ci.sh validate-go
```

Rust cross-compilation path:
```bash
./scripts/local-ci.sh validate-rust-gnu
```

C / Windows verification:
```bash
./scripts/local-ci.sh validate-c
```

Run all jobs from all workflows:
```bash
./scripts/local-ci.sh all
```

The script will:
*   Check that act and docker are installed.
*   Map `ubuntu-latest` to a full runner image: `ghcr.io/catthehacker/ubuntu:act-latest`
*   On macOS/arm64, force `linux/amd64` containers so your builds behave like GitHub’s `ubuntu-latest` runners.
*   Run the requested job (or everything, when you pass `all`).

### Which jobs can I run?

The repo contains two categories of workflows:
1.  End-to-End examples in `.github/workflows/e2e-test.yml`
2.  Validation Suite in `.github/workflows/verify-action.yml`

Typical jobs you’ll want to run:
*   `validate-go` – Go + CGO cross-compilation (Linux → Linux/ARM)
*   `validate-rust-gnu` – Rust cross-compilation (Linux → aarch64-unknown-linux-gnu)
*   `validate-c` – C cross-compilation to Windows PE

You can see all job IDs by running:
```bash
act -l
```

### Design constraints for workflows

To keep local CI usable:
*   Validation workflows must not depend on GitHub secrets.
*   They should run purely with:
    *   `actions/checkout`
    *   toolchain setup (Go, Rust, Zig)
    *   this action itself
*   macOS-only behavior is validated in GitHub Actions, not locally. The act environment always uses Linux containers, even for macOS jobs.

## Local Development Checklist

Before you open a PR, please verify the basics:

1.  **Build Examples:**
    *   **Go (CGO):** `cd examples/go-cgo && go build -o /tmp/app-go-arm64 .`
    *   **Rust (aarch64-gnu):** `cd examples/rust-aarch64 && cargo build --release --target aarch64-unknown-linux-gnu`
    *   **C (host check):** `cd examples/c-linux-gnu && cc main.c -o /tmp/app-gnu && /tmp/app-gnu`

2.  **Run Local CI (Recommended):**
    Use the helper script to run the validation suite via `act`:
    ```bash
    # Go Smoke Test
    ./scripts/local-ci.sh validate-go

    # Rust Cross-Compile
    ./scripts/local-ci.sh validate-rust-gnu
    ```

## Making Changes

1.  Fork the repository and create a feature branch:
    ```bash
    git checkout -b feature/my-change
    ```

2.  Make your changes to:
    *   `action.yml`
    *   `setup-env.sh`
    *   docs (`README.md`, `ARCHITECTURE.md`, `TARGETS.md`)
    *   workflows (`.github/workflows/*.yml`)

3.  Run local CI:
    ```bash
    ./scripts/local-ci.sh validate-go
    ./scripts/local-ci.sh validate-rust-gnu
    ./scripts/local-ci.sh validate-c
    # or:
    ./scripts/local-ci.sh all
    ```

4.  Push your branch and open a Pull Request with:
    *   A short description of the change
    *   Why it’s needed (bugfix / new target / DX improvement)
    *   Links to relevant issues or discussions if applicable

We’ll review PRs with a focus on:
*   Keeping the action stateless and focused on environment setup.
*   Clear error messages and fail-fast behavior.
*   Not breaking existing Tier 1 targets without a migration plan.
*   Documentation staying in sync with behavior.

Thanks again for contributing!
