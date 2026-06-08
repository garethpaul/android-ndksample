---
title: NDK Check Wrapper
status: completed
date: 2026-06-08
origin: user-requested continuous engineering quality loop
execution: code
---

# NDK Check Wrapper

## Problem Frame

The repository has a useful SDK-free provenance check, but no root-level command
that matches the local verification convention used across the Android repos in
this maintenance loop. The generated README also drifted away from the
NDK-specific provenance baseline.

## Scope Boundaries

- Do not regenerate or replace checked-in native `.so` libraries.
- Do not migrate Ant/project.properties to Gradle or CMake.
- Do not change Java or native rendering behavior.

## Implementation Units

### U1: Root Wrapper

Files:

- `Makefile`
- `scripts/check-baseline.sh`

Approach:

- Add `make check` as the root verification command.
- Keep `scripts/check-baseline.sh` as the underlying provenance gate.
- Require the wrapper from the baseline script.

### U2: Documentation

Files:

- `README.md`
- `CHANGES.md`

Approach:

- Restore the NDK provenance README.
- Document `make check` before the underlying script.
- Document and commit the `libs/SHA256SUMS` runtime library checksum manifest.
- Record the wrapper in the changelog.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
