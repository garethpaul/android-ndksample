---
title: Android NDK Demo Explicit Launcher Export Boundary
type: security
status: planned
date: 2026-06-15
---

# Android NDK Demo Explicit Launcher Export Boundary

## Problem Frame

The native demo's `.DemoActivity` owns its sole `MAIN`/`LAUNCHER` filter but
omits `android:exported`. Legacy Android infers external reachability, leaving
the component boundary implicit and blocking a future Android 12 target upgrade
without a manifest correction.

## Priorities

1. P0: Preserve demo launch behavior while explicitly declaring the existing
   launcher boundary.
2. P1: Add a mutation-sensitive structural checker for exactly one true export
   declaration on the named launcher block.
3. P1: Keep maintained guidance and completion evidence aligned without
   changing native rendering or timing behavior.

## Requirements

- Set `android:exported="true"` only on `.DemoActivity`.
- Preserve package/version metadata, minimum SDK, backup policy, labels,
  launcher filter, JNI bindings, native build files, rendering, and timing.
- Reject missing, false, duplicate, unrelated, or filter-detached declarations.
- Keep repository and external-directory verification equivalent.
- Separate SDK/NDK-backed validation from unexecuted emulator, device, and GPU
  runtime behavior.

## Implementation Units

### 1. Declare launcher reachability

**File:** `AndroidManifest.xml`

Add the explicit true attribute to the existing demo activity only.

### 2. Enforce the boundary

**File:** `scripts/check-baseline.sh`

Count exported occurrences and require the sole declaration in the
`.DemoActivity` block containing both launcher filter entries.

### 3. Synchronize guidance

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
and this plan.

Document the intentional boundary and completed validation evidence.

## Verification

- Run POSIX syntax and the focused baseline checker.
- Run repository and external-directory `make check` with the configured Java,
  Android SDK, and NDK environment when supported by the existing gate.
- Reject missing, false, unrelated, filter-detached, same-line duplicate,
  missing-guidance, and incomplete-plan mutations.
- Audit generated artifacts, exact paths, file modes, whitespace, conflict
  markers, dependency/workflow drift, and credential-shaped additions.

## Risks And Mitigations

- **Launch regression:** require the activity name and both launcher entries in
  the same structural contract as the exported value.
- **Overexposure:** allow exactly one exported occurrence and reject unrelated
  declarations.
- **Native regression:** do not modify C/C++, JNI, makefiles, timing, or drawing
  code.
- **Stacked delivery:** base this PR on the smoothed-tick overflow branch and
  preserve base-first merge ordering.

## Out Of Scope

- SDK, NDK, Gradle, build-system, compiler, or dependency upgrades.
- New Android components, permissions, deep links, or intent filters.
- JNI ownership, native timeline logic, tick smoothing, OpenGL rendering, or
  frame pacing.
