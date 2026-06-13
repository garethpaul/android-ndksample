# ImportGL Initialization Failure Cleanup

Status: Planned

## Context

`importGLInit()` records a failed result when any GL/EGL symbol is missing but
returns without closing the opened library. Android callers currently invoke
`importGLDeinit()` after failure, while the Linux and Windows startup paths
return immediately, leaving partial loader state owned by the process.

## Requirements

- Make `importGLInit()` invoke `importGLDeinit()` when symbol import result is
  false before returning failure.
- Keep successful initialization unchanged.
- Reuse the existing platform close checks and clear function pointers only
  after a successful close.
- Preserve idempotent caller cleanup so Android's existing post-failure
  deinitialization remains harmless.
- Keep missing-library failures unchanged because no handle or symbols were
  acquired.
- Add mutation-sensitive static coverage, documentation, and truthful
  verification evidence without rebuilding historical ABI libraries.

## Implementation Units

### U1: Self-Clean Partial Imports

**File:** `jni/importgl.c`

Call `importGLDeinit()` in the shared post-import failure branch immediately
before returning `result`.

### U2: Extend Portable Contracts

**File:** `scripts/check-baseline.sh`

Require one failure-conditioned deinit call after the exact 40 imports and
before the result return, while preserving deinit close and pointer-reset
contracts.

### U3: Document And Verify

**Files:** `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`, this plan

Document caller-independent initialization cleanup. Run strict portable syntax
checks, existing host tests, hostile mutations, binary/checksum audits, and
exact-head hosted validation.

## Scope Boundaries

- Do not change library names, symbol lists, function-pointer types, platform
  selection, or Android's `DISABLE_IMPORTGL` path.
- Do not clear pointers when a platform close call fails.
- Do not rebuild or modify checked-in historical ABI libraries.
- Do not claim Windows or dynamic Linux loader runtime coverage without those
  matching environments.

## Verification Plan

- Run local and external-working-directory `make check` plus
  `sha256sum -c libs/SHA256SUMS`.
- Run portable `importgl.c` syntax checks with the repository's temporary
  GLES/EGL type headers.
- Prove hostile mutations for cleanup removal, unconditional cleanup, cleanup
  before imports, cleanup after return, result inversion, pointer-reset
  weakening, documentation drift, and incomplete-plan status fail.
- Run `git diff --check`, generated-artifact/binary inspection, and
  credential-shaped added-line scans.
- Record hosted evidence only after querying the exact pushed head.

## Sources

- POSIX `dlclose`:
  https://www.man7.org/linux/man-pages/man3/dlclose.3p.html
- Windows `FreeLibrary`:
  https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-freelibrary

## Verification

- Pending implementation.
