# NDK Java Lifecycle View Guard

Date: 2026-06-09
Status: Completed

## Problem

`DemoActivity.onDestroy()` already guarded the `GLSurfaceView` before releasing
native resources, but `onPause()` and `onResume()` still called the view
directly. If lifecycle callbacks run after a partial startup or future layout
change that leaves the view unavailable, the Java side could crash before the
native idempotence guards help.

## Scope

- Preserve the existing GLSurfaceView setup and renderer behavior.
- Keep native pause/resume idempotence unchanged.
- Do not rebuild or replace checked-in native libraries.
- Keep verification available through the SDK-free baseline check.

## Work Completed

- Added null guards around `mGLView.onPause()`.
- Added null guards around `mGLView.onResume()`.
- Extended the SDK-free baseline to keep pause/resume lifecycle view guards in
  place.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
