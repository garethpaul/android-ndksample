# Android NDK Render-Thread Timeline Ownership

Status: Planned

## Problem

Frame rendering and native OpenGL teardown run on the GLSurfaceView render
thread, but touch toggles and lifecycle pause/resume currently call native
timeline functions directly from the UI thread. Those functions read and write
the same native timing globals used by `nativeRender`, creating unsynchronized
cross-thread access and allowing pause state to race rendering or teardown.

## Requirements

1. Queue touch-driven pause/resume toggles on the GLSurfaceView render thread.
2. Queue lifecycle pause and native resource teardown in one render-thread
   operation, preserving pause-before-teardown ordering.
3. Queue lifecycle resume on the render thread after GLSurfaceView resumes.
4. Preserve native timing arithmetic, idempotent teardown, touch consumption,
   surface callbacks, checked-in binaries, dependencies, and UI behavior.
5. Add mutation-sensitive portable contracts, maintenance guidance, and
   truthful verification evidence.

## Implementation Units

### 1. Serialize native timeline transitions

Files:

- `src/com/example/SanAngeles/DemoActivity.java`

Route touch toggles, lifecycle pause, and lifecycle resume through
`queueEvent`. Keep native pause immediately before renderer-owned cleanup in
the same queued runnable.

### 2. Protect thread ownership

Files:

- `scripts/check-baseline.sh`
- `docs/plans/2026-06-14-android-ndk-render-thread-timeline.md`

Require all three timeline transitions inside queued render-thread operations,
reject direct lifecycle/touch native calls, and preserve pause-before-teardown
ordering.

### 3. Document the concurrency boundary

Files:

- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`

Record that native rendering, timeline transitions, and teardown share render-
thread ownership.

## Verification

To be recorded after implementation:

- POSIX shell syntax, portable source contracts, seven-ABI ELF verification,
  and native size-guard tests.
- Repository-root and external-directory `make check`.
- Isolated touch, pause, ordering, teardown, resume, direct-call,
  documentation, and completed-plan mutations.

## Scope Boundaries

- Do not alter native timing calculations, JNI signatures, GL initialization,
  rendering, resource ownership, or checked-in native libraries.
- Do not claim Android, GPU, context-loss, emulator, or device execution.
- Do not merge or close any pull request without explicit authorization.
