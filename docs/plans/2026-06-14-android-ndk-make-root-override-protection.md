# Android NDK Make Root Override Protection

Status: Completed

## Problem

The Makefile derives its repository root from its own location, but GNU Make
command-line variables override an ordinary assignment. A hostile `ROOT` value
can redirect baseline, ELF, native-size, lint, and NDK build commands away from
the reviewed checkout.

## Requirements

1. Protect the Makefile-derived root with GNU Make's `override` directive.
2. Preserve configurable Android SDK variables, lint tool, NDK build command,
   targets, skip conditions, and all existing native verification commands.
3. Require exact protected-root and tool-override semantics plus complete
   rooted baseline, ELF, size-test, lint, and NDK build contracts.
4. Pass local, external-directory, and hostile-root `make check` gates.
5. Reject focused root, tool, path, command, and completed-plan mutations.

## Verification

- Run shell syntax and the dependency-free baseline checker first.
- Run bounded local, external-directory, and hostile command-line `ROOT`
  `make check` gates, recording whether Android lint and `ndk-build` execute or
  truthfully skip.
- Run focused mutations plus workflow YAML, Android XML, SVG XML, native
  artifact, conflict-marker, whitespace, and changed-line credential audits.

## Scope Boundaries

- Do not change JNI, ImportGL, application lifecycle, checked-in libraries,
  ABI support, dependencies, workflows, resources, or deployment behavior.
- Do not weaken wrapper, ELF, checksum, export, or compiler test contracts.
- Do not create local SDK/NDK placeholders or claim device verification.
- Do not merge or close any pull request without explicit owner authorization.

## Work Completed

- Protected the Makefile-derived root while preserving SDK, lint-tool, and NDK
  command configurability, every target, and every skip condition.
- Added dependency-free contracts for exact variables and complete rooted
  baseline, ELF, native-size, lint, NDK build, and completed-plan behavior.

## Verification Results

- The focused baseline checker and shell syntax checks passed.
- Local, external-directory, and hostile command-line `ROOT` `make check`
  gates each passed both baseline executions, seven-ABI ELF verification, and
  native size guard compiler tests while remaining anchored to this checkout.
- No Android lint tool or `ndk-build` command was available, so those two gates
  truthfully reported their designed skips in all three contexts; no rebuilt
  library, emulator, or device result is claimed.
- All thirteen focused mutations were rejected: missing `override`, `CURDIR`,
  recursive root assignment, `firstword`, eager SDK assignment, eager lint-tool
  assignment, eager NDK assignment, unrooted baseline, ELF, size-test, or NDK
  commands, missing lint SDK-root propagation, and reopened plan status.
- Workflow YAML, Android XML, SVG XML, shell syntax, conflict-marker,
  whitespace, native-artifact, exact-diff, and changed-line credential audits
  passed; only the three intended files changed and no generated artifacts
  remained.
