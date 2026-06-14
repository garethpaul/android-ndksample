# Android NDK Pause Timeline Saturation

Status: Completed

## Problem

Android elapsed time is now relative and saturated, but pause/resume still
updates `sTimeOffset` with unchecked signed subtraction and rendering adds that
offset with unchecked signed addition. Repeated long pauses or a saturated
elapsed clock can underflow the offset or produce an invalid negative/overflowed
render tick, which is undefined behavior in C.

## Requirements

1. Preserve the public `long` tick contract, pause semantics, render cadence,
   and desktop implementations.
2. Add portable helpers that accumulate paused duration without signed
   overflow and derive a nonnegative render timeline.
3. Saturate accumulated paused duration at `LONG_MAX` and clamp render time to
   zero when paused duration is greater than elapsed time.
4. Preserve same-frame rendering while paused and reset all timeline state on
   each native initialization attempt.
5. Extend strict GCC, Clang, and UBSan tests for normal pauses, repeated pause
   accumulation, saturation, elapsed-before-paused clamps, and maximum values.
6. Add mutation-sensitive source, test, documentation, and completed-plan
   contracts.

## Implementation Units

### U1: Add Checked Timeline Helpers

**Files:** `jni/elapsed-time.h`, `scripts/test-native-size-guards.c`

Add dependency-free saturated pause accumulation and nonnegative render-time
derivation alongside the existing relative-time helper.

### U2: Replace Offset Arithmetic

**File:** `jni/app-android.c`

Track accumulated paused milliseconds, use checked helpers on resume and render,
and reset the state during native initialization.

### U3: Protect And Document

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `CHANGES.md`, this plan

Require helper use, reset and callback ordering, boundary tests, generic
documentation, and truthful verification.

## Scope Boundaries

- Do not change desktop timing, JNI signatures, demo duration, camera tracks,
  rendering, dependencies, ABI support, checked-in libraries, or workflows.
- Do not claim emulator, physical-device, GPU, or long-duration behavior.
- Do not merge or close any pull request without explicit authorization.

## Verification

- Strict GCC, Clang, and UBSan native tests passed through bounded local and
  external-directory `make check` gates. Seven-ABI ELF contracts also passed;
  Android lint and `ndk-build` truthfully skipped because those tools are not
  configured.
- Eight hostile mutations were rejected: removed saturation, removed render
  clamp, unchecked resume, unchecked render, missing reset, removed boundary
  test, removed security guidance, and reopened plan status.
- Final verification includes exact diff, native artifacts, whitespace,
  conflict markers, and credential-shaped added-line audits.
- Emulator, physical-device, GPU, and long-duration pause behavior were not
  exercised.
