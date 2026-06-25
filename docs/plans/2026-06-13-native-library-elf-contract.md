# Native Library ELF Contract

Status: Completed

## Context

The seven checked-in `libsanangeles.so` files are protected by complete
SHA-256 coverage, but checksums establish byte identity rather than runtime
shape. The baseline does not independently prove that each ABI path contains a
little-endian ELF shared object for the expected machine, uses the expected
SONAME and platform dependencies, or exports every JNI method declared by the
Java renderer and surface view.

## Goals

- Verify every checked-in runtime library with SDK-free and NDK-free tooling.
- Bind each ABI directory to its expected ELF class and machine architecture.
- Require little-endian shared objects with SONAME `libsanangeles.so`.
- Require the Android/OpenGL dependency boundary declared by the native build.
- Require all seven JNI entry points used by `DemoRenderer` and
  `DemoGLSurfaceView` as global dynamic function exports.
- Preserve all native source, binary bytes, checksums, ABI inventory, Android
  behavior, and optional legacy rebuild behavior.

## Non-Goals

- Do not regenerate or modify checked-in `.so` files.
- Do not claim reproducible binary builds or source/binary equivalence.
- Do not remove historical ABIs or modernize the Android/NDK project in this
  unit.
- Do not require an Android SDK, NDK, emulator, or device.

## Implementation Units

### 1. Add A Portable ELF Verification Script

Files:

- Add `scripts/check-native-library-elf.sh`.

Approach:

- Select `readelf` or `llvm-readelf` explicitly and fail with a clear message
  when neither is available.
- Use locale-stable wide output and exact expected metadata for all seven ABI
  paths.
- Verify ELF class, little-endian data encoding, shared-object type, machine,
  SONAME, required Android/OpenGL dependencies, and the seven global dynamic
  JNI function exports.
- Reject missing, duplicate, undefined, local, non-function, renamed, or
  additive JNI exports under the application package prefix.

### 2. Integrate The Contract Into Repository Gates

Files:

- Modify `Makefile`.
- Modify `scripts/check-baseline.sh`.

Approach:

- Run ELF verification from the test gate so `make check` exercises it in CI
  and from external working directories.
- Protect the verifier, invocation, completed plan evidence, and documentation
  boundary from drift in the SDK-free baseline.
- Preserve checksum verification as a separate byte-integrity control.

### 3. Document The Stronger Binary Boundary

Files:

- Modify `README.md`.
- Modify `SECURITY.md`.
- Modify `CHANGES.md`.
- Complete this plan with actual verification evidence.

Approach:

- Distinguish ELF/runtime-shape verification from checksum integrity and from
  reproducible-build provenance.
- Keep the unresolved source-to-binary and compatible-rebuild risks explicit.

## Verification

- `scripts/check-native-library-elf.sh` passed for all seven unchanged ABI
  libraries.
- `make check` passed from the repository and an external working directory
  with SDK and NDK discovery disabled.
- Existing strict GCC, Clang, and UBSan native size tests passed.
- Fourteen hostile mutations were rejected after refreshing checksums for binary
  corruptions: ELF class, endianness, machine, type, SONAME, dependency, JNI
  symbol identity/binding/type, Make invocation, exact-set comparison, omitted
  ABI verification, security guidance, and plan evidence.
- Shell syntax, workflow YAML parsing, `git diff --check`, checksum validation,
  and a targeted secret scan passed.

## Follow-Up

`docs/plans/2026-06-25-native-elf-search-path-boundary.md` extends this runtime
shape contract to reject embedded `RPATH` and `RUNPATH` dynamic loader search
paths without changing the checked-in library bytes.

## Acceptance Criteria

- All seven unchanged historical libraries pass their exact ABI and ELF
  contracts.
- Every required JNI method is present exactly once as a defined global
  dynamic function, and no extra application JNI export is accepted.
- `make check` remains SDK-free/NDK-free by default and location-independent.
- The plan records completed, truthful evidence only after validation passes.
