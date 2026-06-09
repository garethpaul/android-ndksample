---
title: NDK Checksum Path Hygiene
type: supply-chain
status: completed
date: 2026-06-09
---

# NDK Checksum Path Hygiene

## Problem Frame

`libs/SHA256SUMS` validates the checked-in native libraries, but the baseline
should also constrain the shape of manifest entries. A future edit should not be
able to add absolute paths, parent traversal, uppercase or malformed digests, or
paths outside the expected ABI runtime libraries.

## Scope Boundaries

- Do not regenerate or replace native binaries.
- Do not change ABI targets, native source, Ant project configuration, or lint
  policy in this pass.
- Keep verification SDK-free and NDK-free.

## Implementation Units

### U1: Validate Checksum Entry Shape

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Require each checksum manifest entry to contain exactly a digest and a path.
- Require lowercase 64-character SHA-256 digests.
- Reject absolute, parent-traversal, or backslash paths.
- Restrict paths to the expected `libs/<abi>/libsanangeles.so` runtime library
  set.

### U2: Document The Manifest Contract

Files:

- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Make checksum path hygiene explicit beside the existing provenance and
  checksum validation guidance.
- Keep future binary rebuild documentation tied to exact ABI paths and
  checksums.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
