# ImportGL Idempotent Deinitialization

Status: Completed

## Priority

The portable OpenGL loader stores handles returned by `LoadLibrary()` or
`dlopen()`, but `importGLDeinit()` unconditionally closes those variables and
does not clear them. Cleanup after a failed load or repeated cleanup can
therefore pass a null or already-closed opaque handle to platform loader APIs.
POSIX requires `dlclose()` to receive an open symbol-table handle.

## Requirements

- **R1:** Close the Windows library only when `sGLESDLL` is non-null, then set
  it to null only when `FreeLibrary()` reports success.
- **R2:** Close the Linux shared-object handle only when `sGLESSO` is non-null,
  then set it to null only when `dlclose()` reports success.
- **R3:** Preserve `DISABLE_IMPORTGL`, import ordering, symbol loading, Android
  NDK linkage, JNI lifecycle, checked-in native libraries, and checksums.
- **R4:** Add fail-closed source contracts, documentation, hostile mutations,
  and truthful verification evidence.

## Implementation Units

### U1: Make Loader Cleanup Idempotent

**File:** `jni/importgl.c`

Guard each platform close call with its corresponding handle and clear the
handle immediately after a successful close request.

### U2: Protect The Teardown Contract

**File:** `scripts/check-baseline.sh`

Require platform-specific null guards, close calls, resets, ordering, completed
plan evidence, and documentation.

### U3: Document And Verify

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
`docs/plans/2026-06-13-importgl-idempotent-deinit.md`

Document the portable loader teardown boundary and validation limitations.

## Test Scenarios

- A null Windows or Linux loader handle skips the close call.
- A live handle is closed and reset, so a second cleanup is a no-op.
- Removing either guard, close, reset, or ordering constraint fails.
- Existing native size, allocation, lifecycle, ELF, checksum, workflow, and
  source contracts remain green.

## Scope Boundaries

- Do not rebuild or replace checked-in `.so` files.
- Do not change OpenGL imports, Android runtime behavior, JNI signatures,
  allocation logic, ABIs, dependencies, or SDK/NDK versions.
- Do not claim Windows or dynamic-loader runtime execution when those platform
  toolchains are unavailable.

## Verification

- An isolated tracked repository copy passed `make check`, covering the SDK-free
  provenance baseline, all seven checked-in ELF runtime-shape contracts, strict
  C89 native size tests, and the guarded native-build skip because `ndk-build`
  is unavailable. Legacy Android lint was skipped because no matching SDK is
  configured.
- Nine hostile mutations were rejected: both platform guards, close calls, and
  resets; close/reset ordering; README guidance; and plan-status rollback.
- Canonical and external-directory `make check` both passed against the exact
  completed implementation with the same provenance, ELF, strict C89 size-test,
  and guarded platform-toolchain boundaries.

## Sources

- POSIX `dlclose()` specification:
  https://www.man7.org/linux/man-pages/man3/dlclose.3p.html
- Microsoft `FreeLibrary()` API:
  https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-freelibrary
