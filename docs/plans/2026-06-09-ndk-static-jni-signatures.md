---
title: NDK Static JNI Signatures
type: reliability
status: completed
date: 2026-06-09
---

# NDK Static JNI Signatures

## Problem Frame

The Java wrapper declares the San Angeles native methods as `static native`,
but several source-level JNI bindings omitted the required `jclass` argument.
That leaves future rebuilds dependent on forgiving calling conventions instead
of matching JNI's static-method signature contract.

## Scope Boundaries

- Do not replace checked-in runtime `.so` files in this pass.
- Preserve existing Java native method names and behavior.
- Keep the legacy Ant/NDK project shape and ABI checksum baseline unchanged.
- Keep verification available without an installed NDK.

## Implementation Units

### U1: Align Static JNI Bindings

Files:

- Modify `jni/app-android.c`

Approach:

- Add the `jclass` argument to each binding for a Java `static native` method.
- Preserve the existing native function names so future rebuilds still match
  the Java declarations.
- Leave runtime library regeneration to a separate documented NDK pass.

### U2: Cover And Document The Contract

Files:

- Modify `scripts/check-baseline.sh`
- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Add SDK-free checks for the static JNI signatures.
- Document the signature requirement as part of future native rebuild review.

## Verification

- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `make verify`
- `git diff --check`
