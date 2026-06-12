# NDK Allocation Failure Recovery

Status: Completed

## Context

Native object allocation helpers return `NULL` when memory allocation fails,
but `appInit` asserts that every generated object is non-null. Resource pressure
therefore aborts the process instead of releasing partial state. The Android
JNI initializer also marks the demo initialized after `appInit` without a
failure check.

## Changes

- Replace allocation assertions in `appInit` with recoverable failure checks.
- Release all partially initialized demo objects on allocation failure.
- Mark the existing `gAppAlive` signal false when demo initialization fails.
- Have Android JNI initialization detect that failure, release imported OpenGL
  symbols, and leave native rendering disabled.
- Extend the SDK-free baseline and README with the recovery contract.

## Verification

- `make check`
- Static mutations for restoring allocation assertions and removing the JNI
  failure branch
- `git diff --check`

The Android NDK is unavailable on this host, so forced allocation failure and
native binary regeneration still require a compatible NDK environment.
