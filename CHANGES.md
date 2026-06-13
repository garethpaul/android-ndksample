# Changes

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
