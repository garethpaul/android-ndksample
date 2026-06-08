---
title: Android NDK Sample Provenance Baseline
type: chore
status: completed
date: 2026-06-08
---

# Android NDK Sample Provenance Baseline

## Summary

Raise the engineering baseline for the legacy San Angeles NDK sample by
documenting the Ant/NDK project shape, preserving source and license
expectations, removing tracked intermediate native build outputs, and adding a
source check that works without an installed Android NDK.

---

## Problem Frame

The repository is an old Android NDK sample with JNI C sources, Ant-style
Android project metadata, checked-in runtime `.so` files under `libs/`, and
checked-in debug/intermediate `.so` files under `obj/local/`. The documentation
baseline now needs to be strict about binary provenance, and `ndk-build` is not
installed on this host, so this pass should not regenerate binaries or migrate
the build system. The highest-value baseline is to make binary provenance and
expected future rebuild steps explicit while removing generated `obj/`
artifacts from version control.

---

## Requirements

- R1. The repository must document the legacy Ant/NDK project structure and current verification limits.
- R2. Runtime ABI libraries under `libs/` must remain present for the current sample.
- R3. Intermediate `obj/local` native build outputs must be removed from version control and ignored going forward.
- R4. License and attribution files under `jni/` must remain present.
- R5. A local SDK-free source check must verify README, plan, source, license, ABI library, and ignore-file expectations.
- R6. The plan must defer NDK rebuilds, Gradle migration, and binary replacement until an NDK version and verification path are documented.

---

## Key Technical Decisions

- **Keep runtime binaries, remove intermediates:** `libs/*/libsanangeles.so` are the deployable native libraries for this legacy project; `obj/local/*` are generated build artifacts and should not stay tracked.
- **Document before regenerating binaries:** Without `ndk-build` installed, replacing `.so` files would weaken provenance instead of improving it.
- **Use an SDK-free check:** POSIX shell checks can verify source/provenance structure without Android SDK or NDK setup.
- **Avoid build-system migration in this pass:** Moving from Ant/project.properties to Gradle/CMake should be planned with a verified NDK toolchain and runtime smoke test.

---

## Scope Boundaries

- This pass does not regenerate or replace any `.so` runtime library.
- This pass does not add a Gradle project, CMake build, CI, emulator test, or device smoke test.
- This pass does not edit native rendering code or Java activity behavior.
- This pass does not change Android manifest package names, SDK values, or app labels.

---

## Implementation Units

### U1. Document NDK Baseline

- **Goal:** Make the preserved sample understandable and explicit about build limits.
- **Files:** `README.md`
- **Patterns:** Short sections for project shape, binary provenance, verification, and deferred modernization.
- **Test Scenarios:**
  - README names the Ant/project.properties project shape.
  - README explains `libs/` runtime binaries versus ignored `obj/` intermediates.
  - README states that `ndk-build` is required before regenerating binaries.
- **Verification:** `scripts/check-baseline.sh`

### U2. Remove Tracked Native Intermediates

- **Goal:** Stop versioning generated debug/native intermediate artifacts.
- **Files:** `.gitignore`, `obj/local/*/libsanangeles.so`
- **Patterns:** Add `obj/` to `.gitignore`; remove tracked `obj/local` libraries while keeping `libs/` libraries.
- **Test Scenarios:**
  - `git ls-files 'obj/*'` returns no tracked files.
  - `.gitignore` includes `obj/`.
  - `libs/*/libsanangeles.so` still exists for each checked-in ABI.
- **Verification:** `scripts/check-baseline.sh`

### U3. Add SDK-Free Provenance Check

- **Goal:** Provide a repeatable baseline gate before Android SDK/NDK setup.
- **Files:** `scripts/check-baseline.sh`
- **Patterns:** POSIX shell with repo-root detection and clear failure messages.
- **Test Scenarios:**
  - The script fails if required JNI source or license files are missing.
  - The script fails if expected runtime ABI libraries are missing.
  - The script fails if `obj/` is not ignored or tracked `obj/` files return.
  - The script fails if README no longer documents the NDK/provenance baseline.
- **Verification:** `scripts/check-baseline.sh`

---

## Risks & Dependencies

- Runtime behavior is not exercised because no Android NDK, emulator, or device smoke test is configured here.
- Checked-in runtime `.so` files still need future provenance work: documented NDK version, reproducible rebuild command, checksums, and runtime launch verification.
- Ant/project.properties support is obsolete; a future migration should preserve a known-good native rebuild before moving to Gradle/CMake.

---

## Sources / Research

- `jni/Android.mk` builds the `sanangeles` shared library from `importgl.c`, `demo.c`, and `app-android.c`.
- `jni/Application.mk` currently declares `APP_ABI := all`.
- `jni/license.txt`, `jni/license-BSD.txt`, and `jni/license-LGPL.txt` preserve upstream licensing context.
- `libs/*/libsanangeles.so` contains deployable runtime binaries for multiple ABIs.
- `obj/local/*/libsanangeles.so` contains generated intermediate native build outputs with debug information.
- `project.properties` identifies the legacy Ant project target.
- `ndk-build` is not available on this host, so binary regeneration is deferred.
