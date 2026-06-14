# Android NDK Relative Time

Status: In Progress

## Problem

The Android bridge computes epoch milliseconds as `now.tv_sec * 1000` and
returns the result as `long`. Every checked-in 32-bit Android ABI uses a
32-bit `long`, so current epoch milliseconds overflow before the animation
offset is applied. Signed overflow is undefined behavior and can corrupt
render, pause, or resume timing.

## Requirements

1. Preserve the public `long` tick contract and existing demo/render behavior.
2. Derive Android ticks from a relative `timeval` delta without multiplying
   epoch seconds into `long`.
3. Validate timeval components, reject backward/invalid samples by preserving
   the previous elapsed value, and saturate elapsed values at `LONG_MAX`.
4. Reset the Android time origin and previous elapsed value for each native
   initialization attempt.
5. Add portable compiler tests for normal deltas, microsecond borrowing,
   backward clocks, invalid fields, nondecreasing output, and saturation.
6. Preserve desktop timing, JNI signatures, pause/resume semantics, rendering,
   dependencies, ABI support, checked-in libraries, and workflows.

## Implementation Units

### U1: Add Portable Relative-Time Arithmetic

**Files:** `jni/elapsed-time.h`, `scripts/test-native-size-guards.c`

Add a dependency-free helper that converts validated origin/current seconds
and microseconds to a nondecreasing saturated `long` delta. Extend the existing
strict GCC, Clang, and UBSan native harness with boundary cases.

### U2: Use Relative Android Time

**File:** `jni/app-android.c`

Retain a `timeval` origin and last elapsed value, initialize them on the first
sample after native reset, and route later samples through the helper.

### U3: Protect And Document The Contract

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `CHANGES.md`,
this plan

Require helper use, reset ordering, hostile-mutation coverage, generic runtime
behavior, and truthful completed verification evidence.

## Verification

- Run shell syntax and the dependency-free baseline checker.
- Run the strict GCC, Clang, and UBSan native harness locally and through
  bounded local and external-working-directory `make check` gates.
- Reject focused mutations for restored epoch multiplication, missing origin
  reset, missing borrow, backward-clock regression, lost nondecreasing clamp,
  missing saturation, invalid microseconds, test removal, and stale plan state.
- Inspect exact diff, native artifacts, conflict markers, whitespace, and
  credential-shaped added lines before committing.

## Scope Boundaries

- Do not change desktop timing implementations or widen the public tick type.
- Do not change rendering cadence, run length, camera tracks, JNI names,
  Android permissions, dependencies, ABI selection, libraries, or workflows.
- Do not claim emulator, device, GPU, or long-duration runtime verification.
- Do not merge or close stacked pull requests without explicit authorization.
