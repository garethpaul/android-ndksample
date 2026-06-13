# Reset Imported GL Function Pointers

Status: Planned

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

- Canonical, external-directory, and isolated SDK/NDK-disabled `make check`.
- Exact import/reset symbol-set comparison.
- `sha256sum -c libs/SHA256SUMS`.
- `sh -n scripts/check-baseline.sh` and `git diff --check`.
- Focused hostile mutations for missing GL/EGL reset, additive reset, reset
  before close success, missing helper call, stale plan status, and evidence.
- Exact-base binary, artifact, and credential-shaped added-line inspection.
- Exact-head hosted check and code-scanning snapshot after push.

## Scope Boundaries

- Do not claim Windows or dynamic Linux loader execution on this host.
- Do not change the imported API surface or introduce a compatible NDK rebuild
  claim.
