# Native Lifecycle and Loader Review

Status: Completed

## Scope

Review the full PR #1-#13 stack across native allocation arithmetic, checked-in
ELF libraries, portable `ImportGL` ownership, Android render-thread lifecycle,
animation timing, JNI boundaries, and manifest exports.

## Findings

- Repeated successful `importGLInit()` calls overwrote the retained dynamic
  library handle, leaking one `dlopen`/`LoadLibrary` reference per call.
- A partial symbol import followed by a failed close left a retained handle that
  a later initialization overwrote, losing the only cleanup reference.
- Demo resource reinitialization reset Android elapsed time but retained the
  native camera/tick state, so context recreation could resume with stale
  animation ownership.
- A first render tick of zero was also used as an uninitialized sentinel,
  allowing the following frame to replace the real origin.
- A negative first tick could claim the origin and make all later valid ticks
  fail closed against that permanently invalid start value.
- The ELF verifier accepted arbitrary additional `DT_NEEDED` libraries and did
  not enforce the no-text-relocation and non-executable-stack boundaries.

## Fix

- Track whether portable imports are fully ready; make repeated initialization
  idempotent and refuse to overwrite a retained partial handle.
- Own all demo timing/camera fields in one resettable timeline structure with an
  explicit `started` bit and bounded multi-track advancement.
- Compare the complete native dependency set and reject `TEXTREL` or any stack
  other than exactly one `RW` `GNU_STACK` program header.

## Verification

- Red-first host tests reproduced the loader-reference leak, retained partial
  handle overwrite, zero-origin replacement, and missing lifecycle reset.
- Fake-`readelf` hostile tests proved the verifier accepted an extra dependency
  before the policy fix and now reject extra dependencies, text relocations,
  and executable stacks.
- Strict C89 tests run with warnings as errors. Linux CI uses AddressSanitizer
  plus UndefinedBehaviorSanitizer; macOS uses UndefinedBehaviorSanitizer because
  even a trivial Apple AddressSanitizer probe hangs in this host environment.
- `make check` validates the unchanged checked-in library hashes and all seven
  ABI contracts. No checked-in `.so` was rebuilt or replaced.

## Runtime limits

No Android SDK, NDK rebuild, emulator, physical device, context-loss event, or
live OpenGL ES driver was executed locally. `project.properties` targets the
legacy Google APIs 21 Ant toolchain, and the repository contains no Gradle wrapper.
Device/GPU evidence remains explicitly unexecuted in `DEVICE_VERIFICATION.md`.
