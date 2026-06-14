# Android NDK Device Verification Checklist

Status: In Progress

## Problem

Portable contracts cover native library provenance, allocation boundaries,
relative timing, pause saturation, OpenGL import cleanup, and render-thread
teardown, but no checklist defines repeatable emulator or physical-device GPU
evidence for the exact implementation commit.

## Requirements

1. Add an exact-commit matrix for launch, rendering, resize, pause/resume,
   context loss, rapid lifecycle changes, teardown, and process recreation.
2. Require sanitized toolchain, device, ABI, result, and evidence fields.
3. Keep repository checks separate from unexecuted Android, GPU, and hardware
   scenarios.
4. Add mutation-sensitive contracts for the checklist and completion evidence.

## Scope Boundaries

- Do not replace checked-in native libraries or alter `libs/SHA256SUMS`.
- Do not modernize the Android SDK, NDK, Ant project, APIs, or dependencies.
- Do not add device identifiers, screenshots with notifications, logs, APKs,
  tombstones, traces, or keys to git.
- Do not claim emulator, GPU, or physical-device execution from portable checks.
- Do not merge or close stacked pull requests without explicit authorization.

## Verification

- Pending implementation and bounded repository validation.
