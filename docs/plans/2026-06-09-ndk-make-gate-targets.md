---
title: NDK Make Gate Targets
type: tooling
status: completed
date: 2026-06-09
---

# NDK Make Gate Targets

## Problem Frame

The legacy Ant/NDK sample had an SDK-free `make check` wrapper, but it did not
expose the standard lint, test, and build gate names from the repository root.
That made the pre-push workflow less explicit for a repository that cannot
always rebuild native libraries on every workstation.

## Scope Boundaries

- Preserve the existing SDK-free provenance and checksum baseline.
- Do not replace checked-in runtime `.so` files.
- Do not require `ndk-build` on hosts where it is unavailable.
- Keep Android lint optional and tied to the legacy SDK lint tool.

## Implementation Units

### U1: Add Root Gate Targets

Files:

- Modify `Makefile`

Approach:

- Add `make lint` to run the SDK-free baseline and Android lint when available.
- Add `make test` as the SDK-free provenance and checksum check.
- Add `make build` to run `ndk-build` when available and otherwise report a
  clear skip.
- Keep `make check` as the aggregate wrapper through `make verify`.

### U2: Protect The Gate Names

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Require the root Makefile to expose `lint`, `test`, and `build`.
- Require `verify` to aggregate those gates.

### U3: Document The Workflow

Files:

- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Record the root gate commands and the guarded native rebuild behavior.

## Verification

- `make lint`
- `make test`
- `make build`
- `make check`
- `make verify`
- `git diff --check`
