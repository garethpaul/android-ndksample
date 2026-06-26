# Changes

## 2026-06-26 10:20 PDT - P3 - Re-audit native lifecycle boundaries

### Summary

Re-audited the Android-owned JNI lifecycle, render-thread teardown, timeline
arithmetic, allocation guards, dynamic loader ownership, and checked-in ELF
contracts. No new Android correctness or security change was justified.

### Work completed

- Confirmed pause, resume, render, and teardown remain serialized through the
  GLSurfaceView render thread.
- Confirmed failed or partial OpenGL imports retain fail-closed ownership and
  cannot overwrite a live dynamic-library handle.
- Reviewed the unused desktop Linux source separately and declined to mix its
  unaudited display-initialization path into the Android sample maintenance scope.

### Threads

- Started: native lifecycle re-audit — inspect recent ownership and timing work.
- Continued: checked-in binary provenance — reran checksum and ELF contracts.
- Stopped: desktop Linux initialization change — inactive in the Android build
  and not supported by current repository verification.

### Files changed

- `CHANGES.md` — records the audit evidence and no-change decision.

### Validation

- `make check` — passed provenance, seven-ABI ELF, size, timeline, ImportGL,
  AddressSanitizer/UBSan, and hostile mutation gates.
- Android SDK lint and `ndk-build` rebuild skipped because those tools are not
  configured locally.

### Bugs / findings

- No new Android-owned defect established.
- The legacy desktop Linux path remains outside the active Android build and
  should only change with dedicated desktop build/runtime coverage.

### Blockers

- Physical-device rendering and a reproducible legacy NDK rebuild remain
  external verification boundaries.

### Next action

- Preserve the current native ownership contracts until device evidence or a
  reproducible NDK toolchain establishes a specific failing boundary.

## 2026-06-25 23:48 PDT - P2 - Add root setup and build boundaries

### Summary

Added a single root-level quick start that separates supported SDK-free
verification from optional legacy lint/native commands and unproven APK or
binary-reproduction claims.

### Work completed

- Documented portable prerequisites, clone/setup, and `make check` behavior.
- Recorded the Google APIs 21 target and the absence of a Gradle wrapper and
  generated Ant `build.xml`.
- Documented explicit SDK lint and `NDK_BUILD` overrides, `APP_ABI := all`
  interpretation, build-skip semantics, and device-evidence requirements.
- Added a completed plan, fail-closed documentation contracts, and advanced the
  roadmap to documented NDK regeneration.

### Threads

- None; repository manifests, makefiles, binary contracts, and plans were
  reviewed directly.

### Files changed

- `README.md` — SDK-free quick start and optional legacy build boundaries.
- `docs/plans/2026-06-25-root-setup-build-documentation.md` — decision and
  residual-risk record.
- `scripts/check-baseline.sh` — durable setup, non-claim, plan, and roadmap
  contracts.
- `VISION.md` — removed the completed root documentation priority.
- `CHANGES.md` — this cycle record.

### Validation

- Red `sh scripts/check-baseline.sh` — rejected the missing setup plan.
- `make check` — passed provenance, seven-ABI ELF, native boundary, hostile
  parser, and ASan/UBSan tests; SDK lint and `ndk-build` skipped explicitly.
- External-directory `make -f /absolute/path/Makefile check` — passed.
- Twelve hostile setup-documentation mutations — rejected missing quick-start,
  target, build-system, native-command, ABI, non-claim, plan, and roadmap
  contracts.
- `git diff --check` — passed.

### Bugs / findings

- P2 developer workflow: existing verification details were comprehensive but
  lacked one setup sequence and did not plainly state that the checkout cannot
  assemble an APK.

### Blockers

- No Android SDK, pinned NDK, generated Ant project, emulator, or device is
  available; no APK, binary reproducibility, or runtime claim is made.

### Next action

- Select and document an NDK version, then regenerate libraries only with ABI,
  checksum, ELF, and device evidence.

## 2026-06-25 07:36:49 PDT

- ELF runtime-shape checks reject embedded RPATH and RUNPATH search paths.
- Added hostile fake-ELF coverage and a verifier-bypass mutation so checked-in
  libraries cannot acquire runtime loader search paths without failing review.

## 2026-06-19

- Made portable GL initialization idempotent and preserved ownership of a
  retained partial dynamic-library handle when cleanup fails.
- Reset the full demo camera/tick timeline on native resource initialization,
  preserved zero as a valid first tick, rejected negative origin ticks, and
  advanced across delayed camera boundaries without indexing past the track
  table.
- Tightened all seven checked-in ELF contracts to require the exact dependency
  set, no text relocations, and one non-executable GNU stack.
- Added strict host ownership/timeline tests, hostile fake-ELF mutations, and
  AddressSanitizer/UndefinedBehaviorSanitizer gates where supported.

## 2026-06-15

- The explicit launcher export boundary is limited to .DemoActivity and preserves its MAIN/LAUNCHER entry point.
- Native animation tick smoothing uses overflow-free floor averaging after validated relative-time subtraction.

## 2026-06-14

- Native timeline transitions share render-thread ownership with rendering and
  teardown, removing UI-thread races over native pause state.
- Added an exact-commit Android NDK device verification matrix for rendering,
  surface changes, lifecycle timing, context loss, render-thread teardown,
  process recreation, ABI identity, and privacy-safe evidence, with every runtime row explicitly unexecuted.
- Native OpenGL teardown is queued on the render thread before GLSurfaceView pauses.
- Replaced Android epoch-millisecond multiplication with validated relative
  elapsed timing that remains nondecreasing and saturates at `LONG_MAX`.
- Replaced unchecked pause offsets with saturated pause accumulation and a
  nonnegative checked render timeline.
- Added portable native boundary coverage for microsecond borrowing, backward
  clocks, invalid fields, and compiler-width `LONG_MAX` saturation.

## 2026-06-13

- Made portable GL loader cleanup guard and clear Windows/Linux dynamic-library
  handles, then reset imported GL function pointers after successful close so
  failed or repeated teardown does not reuse invalid state.
- Made portable GL partial symbol imports self-clean before failure returns for
  Linux and Windows callers.
- Added an SDK-free ELF runtime-shape contract for all seven historical ABI
  libraries, including architecture, SONAME, platform dependency, and exact JNI
  export verification.

## 2026-06-12

- Guarded native geometry and allocation-size products against signed and
  `size_t` overflow, with portable host boundary tests.
- Replaced native demo allocation assertions with recoverable cleanup and kept
  Android rendering disabled when object initialization cannot complete.

## 2026-06-10

- Made native initialization stop and clean up when OpenGL ES imports are
  unavailable, while resetting timing state before successful demo setup.
- Rejected non-positive surface dimensions at the JNI and portable render
  boundaries before viewport and projection calculations.
- Made root checks location-independent, accepted `ANDROID_SDK_ROOT`, removed
  a machine-local SDK path from docs, and pinned CI to Ubuntu 24.04 with
  superseded-run cancellation.
- Added pinned, read-only GitHub Actions that runs `make check` for the NDK
  provenance and lifecycle baseline with ambient SDK/NDK rebuilds disabled.
- Extended the SDK-free baseline to require the CI workflow and completed CI
  plan.
- Removed the maintainer-specific Android SDK path from the Makefile.
- Disabled persisted checkout credentials, added ownership for native and CI
  control paths, and replaced partial workflow checks with one canonical
  workflow contract.

## 2026-06-09

- Guarded Java pause/resume lifecycle callbacks when the GL view is unavailable.
- Guarded native rendering and repeated init/done calls after teardown so late
  renderer callbacks do not use freed demo objects.
- Made native pause/resume helpers idempotent so repeated Android lifecycle
  callbacks do not corrupt the demo time offset.
- Aligned JNI source signatures with the Java static native declarations and
  added an SDK-free contract for future native rebuilds.
- Added root `make lint`, `make test`, and guarded `make build` targets for the
  legacy Ant/NDK sample verification flow.
- Tightened `libs/SHA256SUMS` validation so checksum entries must use lowercase
  SHA-256 digests and repo-relative paths for the expected ABI libraries.
- Wired the Java activity destruction path to the existing JNI `nativeDone()`
  deinitializer so native demo objects and imported GL bindings are released.

## 2026-06-08

- Added `libs/SHA256SUMS` and a baseline checksum validation gate for the
  checked-in `libsanangeles.so` ABI runtime libraries.
- Added a repository changelog and documented the SDK-backed lint gate for the
  legacy Ant/NDK project.
- Cleaned lint findings by making backup behavior explicit, exposing
  `performClick()` for the touch-driven GLSurfaceView, moving `<uses-sdk>` ahead
  of the application element, and removing the unused starter layout.
- Added a narrow lint baseline for findings deferred until a reproducible NDK
  rebuild, launcher icon, and target SDK policy exist.
- Added a `make check` wrapper for the SDK-free NDK provenance baseline.
- Added `libs/SHA256SUMS` to record checksums for checked-in runtime native
  libraries.
- Extended the SDK-free check to reject checked-in native libraries that are not
  covered by `libs/SHA256SUMS`.
