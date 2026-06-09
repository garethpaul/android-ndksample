# NDK Native Cleanup Lifecycle

## Status: Completed

## Context

The Android wrapper declared `DemoRenderer.nativeDone()` and the JNI layer
implemented it by calling `appDeinit()` and `importGLDeinit()`, but the Java
activity never invoked the cleanup path. Native demo objects and imported GL
bindings could therefore outlive the activity lifecycle.

## Objectives

- Preserve the existing native initialization, pause, resume, and render flow.
- Call the existing native cleanup path during activity destruction.
- Keep the Java-to-JNI cleanup wiring covered by the SDK-free baseline checker.

## Work Completed

- Changed `mGLView` to the concrete `DemoGLSurfaceView` type so cleanup can be
  called from the activity.
- Added `DemoActivity.onDestroy()` to release native resources before the
  activity is destroyed.
- Added `releaseNativeResources()` wrappers on the GLSurfaceView and renderer.
- Extended `scripts/check-baseline.sh` to require the Java cleanup path and the
  existing JNI `nativeDone()` deinitializer.
- Updated README, VISION, and CHANGES notes for the native cleanup contract.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`

This remains SDK-free and NDK-free verification; rebuilding native binaries is
still deferred until a documented NDK version is available.
