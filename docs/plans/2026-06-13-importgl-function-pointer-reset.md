# Reset Imported GL Function Pointers

Status: Completed

## Context

The portable OpenGL loader now closes platform library handles idempotently,
but successful teardown leaves imported EGL/GL function pointers populated.
Those addresses refer to an unloaded module and can be accidentally reused
after cleanup or partial initialization failure.

## Requirements

- R1. Reset every dynamically imported EGL and GL function pointer to `NULL`
  after a successful platform library close.
- R2. Keep function pointers intact when `FreeLibrary` or `dlclose` fails and
  the corresponding handle remains live.
- R3. Require exact set parity between imported and reset function names,
  including the non-Android EGL subset.
- R4. Preserve import ordering, platform fallbacks, Android `DISABLE_IMPORTGL`
  behavior, JNI lifecycle, checked-in libraries, checksums, and ABIs.
- R5. Do not rebuild or modify historical `.so` artifacts.

## Verification

Verification: Completed

- `make check` covers canonical, external-directory, and isolated
  SDK/NDK-disabled execution.
- The baseline compares the exact 40-name import and reset symbol sets.
- `sha256sum -c libs/SHA256SUMS` verifies that all historical libraries remain
  unchanged.
- `sh -n scripts/check-baseline.sh` and `git diff --check` verify the shell and
  patch shape.
- `cc -std=c99 -Wall -Wextra -Werror -DLINUX` compiles `jni/importgl.c` with
  temporary type-only GLES/EGL headers; this checks portable source syntax but
  does not claim dynamic-loader runtime coverage.
- Eight focused hostile mutations cover a missing GL reset, missing EGL reset,
  additive reset, reset before close success, missing Windows helper call,
  missing Linux helper call, stale plan status, and missing verification
  evidence. Every mutation is rejected by the baseline checker.
- Exact-base binary, artifact, and credential-shaped added-line inspection is
  part of the pre-push audit.
- Exact-head hosted checks and code-scanning state are recorded after push.

## Work Completed

- Added one teardown helper whose reset names must exactly match every
  `IMPORT_FUNC(...)` name.
- Called the helper only after `FreeLibrary` or `dlclose` reports success and
  after the matching module handle is cleared.
- Kept failed-close behavior unchanged so pointers remain available while the
  module handle remains live.
- Preserved the Android `DISABLE_IMPORTGL` path and all checked-in libraries.

## Scope Boundaries

- Do not claim Windows or dynamic Linux loader execution on this host.
- Do not change the imported API surface or introduce a compatible NDK rebuild
  claim.
