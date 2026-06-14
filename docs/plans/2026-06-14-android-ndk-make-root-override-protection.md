# Android NDK Make Root Override Protection

Status: Planned

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
