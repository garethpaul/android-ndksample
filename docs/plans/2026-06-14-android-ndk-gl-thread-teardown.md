# Android NDK GL-Thread Teardown

Status: Completed

## Problem

The activity called native OpenGL cleanup directly from `onDestroy`, after the
`GLSurfaceView` render thread had already paused. That can release renderer-owned
resources from the UI thread without its current GL context.

## Requirements

1. Queue native renderer teardown on the `GLSurfaceView` render thread.
2. Queue teardown before `super.onPause()` pauses that thread.
3. Remove the direct activity-destruction cleanup call.
4. Preserve idempotent native cleanup, pause timing, and resume reinitialization.

## Verification

- Root and external-directory `make check` passed portable source, native, ABI,
  documentation, and completed-plan contracts.
- Six hostile mutations were rejected for bypassing the render queue, changing
  pause ordering, restoring UI-thread destruction cleanup, documentation drift,
  and reopened plan status.
- Android runtime, GPU, emulator, and physical-device execution were unavailable.
