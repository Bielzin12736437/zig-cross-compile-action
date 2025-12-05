# Contributing

We welcome contributions!

## Pull Request Process

1.  **Fork** the repo and create your branch from `main`.
2.  **Test** your changes locally if possible.
3.  **Ensure** you do not break existing E2E workflows.
4.  **Submit** a PR.

## Development

*   **Logic:** `setup-env.sh` contains the core logic.
*   **Tests:** `examples/` contains sample projects used by `.github/workflows/e2e-test.yml`.

## Style Guide

*   Use `bash` for scripts (avoid sh-isms where bash is safer, but keep it portable enough for standard runners).
*   Prefer `die "message"` over `exit 1`.
*   Keep dependencies zero.
