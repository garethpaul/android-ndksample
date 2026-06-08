---
title: Android NDK Sample Provenance Baseline
type: docs
status: completed
date: 2026-06-08
---

# Android NDK Sample Provenance Baseline

## Summary

Raise the baseline for the legacy San Angeles Android NDK sample by documenting its preserved native artifact state and adding an SDK-free check that protects source, license, ABI, and Android target metadata.

---

## Problem Frame

The repository contains C sources, Android NDK makefiles, checked-in `libs/*.so` binaries, and checked-in `obj/` build outputs. This environment does not provide `ndk-build` or `ant`, so removing or regenerating native artifacts would be speculative. The safer first step is to make artifact provenance explicit and guard the current recoverable baseline.

---

## Requirements

- R1. The repository must document that checked-in `.so` files and `obj/` files are legacy artifacts that should not be replaced without provenance.
- R2. The repository must document the missing local `ndk-build` and `ant` tool prerequisites for full rebuilds.
- R3. The repository must include a source/provenance check that runs without Android SDK, NDK, or Ant.
- R4. The check must verify required native source, makefiles, license files, ABI libraries, and Android target metadata are present.
- R5. The plan must avoid deleting generated native artifacts until they can be regenerated with a documented NDK version.

---

## Key Technical Decisions

- **Preserve checked-in binaries for now:** Without `ndk-build`, removing `.so` files would make the sample harder to run or inspect.
- **Guard provenance instead of modernizing:** The first baseline is documentation and integrity checks, not a migration to Gradle/CMake or newer NDK APIs.
- **Use SDK-free checks:** Shell checks can verify source and metadata before native toolchains are installed.
- **Keep licenses visible:** The sample includes LGPL and BSD license files that must stay with the native sources.

---

## Scope Boundaries

- This pass does not remove `obj/` or `libs/` artifacts.
- This pass does not regenerate `.so` libraries.
- This pass does not migrate to Gradle, CMake, or a modern Android project layout.
- This pass does not change C, Java, manifest, or resource behavior.

---

## Implementation Units

### U1. Document Native Artifact Provenance

- **Goal:** Make the repository's legacy NDK state explicit for future maintainers.
- **Files:** `README.md`
- **Patterns:** Short sections for purpose, artifact policy, toolchain prerequisites, and verification.
- **Test Scenarios:**
  - README names checked-in `libs/*.so` and `obj/` outputs as legacy artifacts.
  - README states that binary replacements require source, command, NDK version, and ABI documentation.
  - README documents that `ndk-build` and `ant` are unavailable in this environment.
- **Verification:** `scripts/check-baseline.sh`

### U2. Add SDK-Free Provenance Check

- **Goal:** Guard source, license, ABI, and target metadata without native tooling.
- **Files:** `scripts/check-baseline.sh`
- **Patterns:** POSIX shell with repo-root detection and clear missing-file failures.
- **Test Scenarios:**
  - The script fails if required `jni/*.c` or `jni/Android.mk` files are missing.
  - The script fails if license files are missing.
  - The script fails if expected ABI `.so` files are missing.
  - The script fails if `project.properties` no longer targets `Google APIs:21`.
- **Verification:** `scripts/check-baseline.sh`

---

## Risks & Dependencies

- The checked-in binaries have no fresh build provenance yet; future work should install a known NDK and regenerate or validate them.
- `project.properties` targets the old Ant project format and Google APIs 21; modern Android builds need a separate migration plan.
- Runtime verification still requires an Android device or emulator capable of running the OpenGL ES demo.

---

## Sources / Research

- `jni/Android.mk`, `jni/Application.mk`, and `jni/*.c` define the native build.
- `libs/*/libsanangeles.so` contains prebuilt ABI libraries.
- `obj/` contains checked-in native build outputs.
- `project.properties` targets `Google Inc.:Google APIs:21`.
- `command -v ndk-build` and `command -v ant` both fail in this environment.
