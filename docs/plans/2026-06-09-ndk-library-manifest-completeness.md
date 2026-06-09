---
title: NDK Library Manifest Completeness
type: supply-chain
status: completed
date: 2026-06-09
---

# NDK Library Manifest Completeness

## Problem Frame

The repository now records checksums for the checked-in `libsanangeles.so`
runtime libraries, but the baseline only verifies required ABI entries. It
should also fail if extra checked-in `.so` files appear without checksum
manifest coverage.

## Scope Boundaries

- Do not regenerate or replace native binaries.
- Do not change native source, ABI targets, Ant project configuration, or lint
  policy in this pass.
- Keep verification SDK-free and NDK-free.

## Implementation Units

### U1: Enforce Complete Library Manifest Coverage

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Keep the required ABI library checks.
- Count the expected checked-in `libsanangeles.so` libraries.
- Fail when any checked-in `.so` file under `libs/` is missing from
  `libs/SHA256SUMS`.

### U2: Document The Supply-Chain Contract

Files:

- Modify `README.md`
- Modify `CHANGES.md`
- Modify `VISION.md`

Approach:

- State that checksum coverage is complete for checked-in native libraries.
- Keep binary replacement guidance tied to documented rebuilds and smoke tests.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
