# NDK Native Pause Resume Idempotence

## Status: Completed

## Context

The Java `GLSurfaceView` wrapper calls native pause and resume from Android
lifecycle callbacks. Those callbacks can repeat around activity transitions.
The native `_resume()` helper previously adjusted `sTimeOffset` even when the
demo was not paused, which could skew render timing on redundant resume calls.

## Objectives

- Preserve the existing touch toggle, pause, resume, and render behavior.
- Make `_pause()` a no-op when the demo is already stopped.
- Make `_resume()` a no-op when the demo is already running.
- Route touch toggles through the guarded helpers instead of flipping state
  before the helper runs.
- Do not rebuild or replace checked-in native binaries in this pass.

## Work Completed

- Added idempotence guards to native `_pause()` and `_resume()`.
- Updated `nativeTogglePauseResume` to choose the helper based on current state.
- Extended `scripts/check-baseline.sh` to require the source contract.
- Updated README, VISION, and CHANGES with the lifecycle contract.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`

## Follow-Up Candidates

- Rebuild checked-in native libraries with a documented NDK version after a
  reproducible native build environment is established.
- Add emulator or device smoke-test notes for touch toggling after rebuild.
