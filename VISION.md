## Android NDK Sample Vision

This document explains the current state and direction of the project.
Project overview and developer docs: [`README.md`](README.md)

Android NDK Sample is an Android port of the San Angeles Observation OpenGL ES
demo, with native C sources, Android NDK build files, and prebuilt shared
libraries for several ABIs.

The repository is useful as a preserved NDK/OpenGL ES sample that demonstrates
native rendering, portable demo code, and older Android project structure.
Additional source background lives in [`jni/README.txt`](jni/README.txt).

The goal is to keep the native demo understandable, license-compliant, and
recoverable for future NDK modernization work.

The current focus is:

Priority:

- Preserve the native source, ABI libraries, and Android manifest structure
- Keep original license and attribution files intact
- Make the demo's OpenGL ES 1.x assumptions clear
- Keep checked-in native libraries covered by checksum provenance
- Keep checksum manifests constrained to repo-relative expected ABI paths
- Keep Java lifecycle teardown wired to the native cleanup path
- Keep Java pause/resume lifecycle callbacks safe when the GL view is missing
- Keep native pause/resume lifecycle helpers idempotent across repeated calls
- Keep native rendering guarded after teardown and repeated initialization
- Keep native initialization fail-closed when OpenGL imports are unavailable
- Keep portable GL loader cleanup idempotent and imported GL function pointers
  invalidated only after successful teardown
- Native OpenGL teardown is queued on the render thread before GLSurfaceView pauses.
- Native timeline transitions share render-thread ownership with rendering and teardown
- Native animation tick smoothing uses overflow-free floor averaging after validated relative-time subtraction.
- The explicit launcher export boundary is limited to .DemoActivity and preserves its MAIN/LAUNCHER entry point.
- Make portable GL partial symbol imports self-clean before failure returns
- Keep surface dimensions valid before native projection and viewport math
- Keep JNI source signatures aligned with Java static native declarations
- Keep root lint, test, and guarded native build gates available
- Keep the SDK-free `make check` baseline running in GitHub Actions
- Keep exact-commit Android NDK device verification matrix evidence separate
  from portable checks, with unexecuted GPU and lifecycle rows explicit
- Avoid build changes that break older NDK sample behavior silently

Next priorities:

- Add root-level setup and build documentation
- Verify or regenerate native libraries with a documented NDK version
- Modernize project structure only after preserving a known-good baseline
- Add smoke-test or manual launch verification notes
- Execute the device verification matrix on an authorized emulator or device
  with privacy-safe GPU and lifecycle evidence

Contribution rules:

- One PR = one focused native, build, or documentation change.
- Preserve licenses and attribution when moving or editing native sources.
- Document the NDK version used for any regenerated binaries.
- Keep ABI and rendering changes reviewable in small steps.

## Security

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

Native binaries and generated libraries should be treated as build artifacts
that need clear provenance. Do not replace checked-in `.so` files without
documenting source, build command, and target ABI.

## What We Will Not Merge (For Now)

- Binary library replacements without source/build provenance
- License or attribution removals
- Rendering rewrites bundled with Android project migration
- Unverified NDK version jumps

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
