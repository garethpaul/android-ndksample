# NDK OpenGL Import Guard

Status: Completed

## Goal

Stop native demo initialization before OpenGL calls when the runtime import
table cannot be loaded.

## Requirements

- Check `importGLInit()` before calling `appInit()`.
- Clean partial GL imports and mark the app inactive on failure.
- Keep native rendering disabled after failed initialization.
- Reset pause and timing state before each successful demo initialization.
- Keep diagnostics generic and free of local paths or runtime data.
- Enforce initialization order with the SDK-free baseline.
- Make root checks location-independent and accept either Android SDK variable.
- Keep hosted verification fixed and free from ambient SDK/NDK rebuilds.

## Implementation

- Guard the OpenGL import result in `nativeInit` and return after cleanup on
  failure.
- Reset native pause/timing fields before `appInit()` after successful imports.
- Extend `scripts/check-baseline.sh` with import-order, rooted `Makefile`, CI,
  and portable documentation contracts.
- Pin GitHub Actions to Ubuntu 24.04 with workflow concurrency.

## Verification

- `make check`
- `make -f /absolute/path/to/Makefile check` from outside the repository
- native-init and automation mutation checks
- `sh -n scripts/check-baseline.sh`
- `git diff --check`

The Android SDK, NDK, and OpenGL runtime are unavailable on this host, so a
native rebuild and launch smoke test remain required before replacing binaries.
