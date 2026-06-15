# Guard Android NDK Smoothed Tick Arithmetic

Status: Planned

## Problem

The Android JNI bridge now produces a validated, nondecreasing elapsed `long`
that saturates at `LONG_MAX`, but `demo.c` still computes its blurred animation
tick as `(sTick + tick - sStartTick) >> 1`. The intermediate signed addition
can overflow before the shift when the elapsed timeline is large or saturated,
which is undefined behavior in C and defeats the upstream timing guards.

## Priorities

1. Remove signed overflow from the final renderer tick smoothing step.
2. Preserve the existing floor-average result for normal nonnegative values,
   animation cadence, run length, camera tracks, and public `long` interface.
3. Keep desktop timing, JNI names, GL behavior, ABI inventory, checked-in
   libraries, dependencies, and workflows unchanged.

## Requirements

1. Add a dependency-free helper that validates current/start ordering, derives
   the relative tick without underflow, and averages two nonnegative `long`
   values without an overflowing intermediate sum.
2. Route `appRender` through the helper instead of direct signed arithmetic.
3. Cover ordinary even/odd results, zero, backward input, negative input, and
   `LONG_MAX` boundaries under strict GCC, Clang, and UBSan builds.
4. Add mutation-sensitive source, test, guidance, and completed-plan contracts.

## Implementation Units

### U1: Add checked smoothing arithmetic

**File:** `jni/elapsed-time.h`

Compute the relative tick only after validating `currentTick >= startTick`, then
form the floor average from halves and remainders so no addition exceeds
`LONG_MAX`.

### U2: Use and test the helper

**Files:** `jni/demo.c`, `scripts/test-native-size-guards.c`

Replace the direct expression and add portable boundary regressions to the
existing native arithmetic harness.

### U3: Protect and document the contract

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `VISION.md`,
`CHANGES.md`, and this plan.

Require helper structure, renderer integration, test identities, maintained
guidance, completed status, and verification evidence.

## Verification

- Run POSIX shell syntax, the focused native arithmetic harness under GCC,
  Clang, and Clang UBSan, and the SDK-free baseline.
- Run repository-root and external-directory `make check` with Android SDK and
  NDK discovery disabled, matching the canonical hosted portable gate.
- Reject isolated helper, integration, boundary-test, guidance, and
  plan-completion mutations.
- Audit exact intended paths, checked-in native library hashes, generated
  artifacts, conflict markers, dependency/workflow drift, whitespace, and
  credential-shaped additions.

## Risks

- No Android device, emulator, GPU, context-loss, or long-duration saturated
  timeline was exercised.
- PR #12 remains stacked on PR #11 and must retain base-first ordering.
