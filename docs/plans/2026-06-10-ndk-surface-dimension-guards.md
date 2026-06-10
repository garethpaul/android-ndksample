# NDK Surface Dimension Guards

Status: Completed

## Context

The JNI resize callback accepted zero or negative dimensions and stored them in
global render state. `prepareFrame()` later divided by `height` while building
the projection matrix, so a transient zero-height surface or malformed native
caller could trigger invalid floating-point projection state.

## Changes

- Ignore non-positive dimensions at the Android JNI resize boundary and retain
  the last valid surface size.
- Skip JNI rendering if stored dimensions are invalid.
- Guard the portable `appRender()` entry point before viewport or projection
  calculations so non-Android callers receive the same protection.
- Keep native teardown independent of surface dimensions.
- Extend the SDK-free baseline with both native boundary contracts.

## Verification

- `make check`
- Static mutations for removed JNI and portable dimension guards
- `git diff --check`

The Android SDK and NDK are unavailable on this host, so rebuilt native code and
runtime surface transitions still require verification with a documented NDK.
