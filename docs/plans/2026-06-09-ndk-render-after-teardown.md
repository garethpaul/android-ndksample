# NDK Render After Teardown Guard

## Status: Completed

## Context

`DemoRenderer.nativeDone()` releases native demo objects and imported GL
bindings during activity destruction. A repeated teardown, repeated surface
creation, or late renderer callback could otherwise free the same pointers
twice or render through objects that have already been released.

## Objectives

- Preserve the existing Java lifecycle and touch toggle behavior.
- Track whether Android native resources are currently initialized.
- Make repeated `nativeInit()`, `nativeDone()`, and late `nativeRender()` calls
  safe around teardown.
- Null native demo object pointers after freeing them.
- Keep the contract covered by the SDK-free baseline checker.

## Work Completed

- Added Android JNI initialization state so repeated init tears down the old
  resource set before creating a replacement.
- Made `nativeDone()` a no-op when resources are not initialized and clear the
  initialized state after cleanup.
- Made `nativeRender()` return before entering the renderer once native
  resources have been torn down.
- Added a demo resource-readiness guard and nulled freed demo pointers.
- Extended `scripts/check-baseline.sh` to require the teardown/render contract.

## Verification

- `make check`
- `git diff --check`
