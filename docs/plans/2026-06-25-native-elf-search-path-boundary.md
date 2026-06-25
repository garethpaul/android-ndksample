# Native ELF Search-Path Boundary

## Status: Completed

## Problem

The seven checked-in native libraries were verified for architecture, ELF type,
SONAME, exact platform dependencies, text relocations, stack permissions, and
JNI exports. The verifier did not reject `DT_RPATH` or `DT_RUNPATH`, so a future
binary replacement could embed an unexpected runtime library search path while
still satisfying every existing runtime-shape check.

## Decision

Reject both dynamic tags from locale-stable `readelf --dynamic --wide` output.
The policy is tag-based rather than path-value-based: checked-in application
libraries must not select alternate loader directories through either legacy
`RPATH` or newer `RUNPATH` metadata.

## Work Completed

- Added one verifier guard covering both `RPATH` and `RUNPATH` dynamic tags.
- Added fake-ELF cases for each tag to the executable checker test.
- Added a mutation that disables the verifier guard and proves the fake-ELF
  suite detects the bypass.
- Updated binary, security, roadmap, contributor, and timestamped change
  guidance while leaving every checked-in library unchanged.

## Verification

- The pre-fix fake-ELF test showed that an injected `RPATH` was accepted.
- `scripts/test-native-library-elf.sh` rejected injected `RPATH` and `RUNPATH`.
- `scripts/check-native-library-elf.sh` passed all seven unchanged ABI files.
- Repository-root and external-directory `make check` passed.
- Three hostile ELF search-path mutations were rejected: injected `RPATH`,
  injected `RUNPATH`, and a disabled verifier guard.
- Isolated hostile ELF search-path mutations were rejected while checksum,
  dependency, JNI export, text-relocation, and GNU-stack policies stayed green.
- No native library bytes were modified, and no Android SDK, NDK, emulator,
  GPU, or physical device was used.

## Scope Boundaries

- This does not prove source-to-binary reproducibility or modern loader
  hardening beyond the explicitly checked metadata.
- ABI inventory, hashes, dependencies, exports, native source, and build files
  remain unchanged.
