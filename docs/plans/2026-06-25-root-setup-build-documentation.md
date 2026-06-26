# Root Setup and Build Documentation

Status: Completed

## Context

The repository had detailed verification and native-library cautions but no
single root-level setup sequence. It is a legacy Ant/NDK layout with no Gradle
wrapper, no generated `build.xml`, no pinned NDK version, and checked-in runtime
libraries whose source-to-binary reproducibility is not established.

## Decision

Document three separate paths:

1. an SDK-free quick start using the maintained `make check` gate;
2. optional legacy Android SDK lint when the old `tools/bin/lint` command and
   Google APIs 21 target are available;
3. an explicit `NDK_BUILD` native-only invocation that must not be treated as a
   reproducible binary replacement without version, ABI, checksum, and device
   evidence.

No APK assembly claim is made because the clean checkout provides neither a
Gradle wrapper nor generated Ant build files.

## Verification

- Red baseline rejected the missing setup plan and guidance.
- Repository-root and external-directory `make check` passed.
- hostile setup-documentation mutations were rejected for the quick start,
  legacy target, absent build systems, native override, ABI policy, NDK-version
  non-claim, skip semantics, device matrix, plan status, and roadmap state.
- `git diff --check` passed.

## Residual Risk

`APP_ABI := all` is interpreted by the selected NDK and does not itself prove
that modern tooling can regenerate the seven historical checked-in ABIs. Before
replacing libraries, record the exact NDK, command, resulting ABI set and
checksums, ELF contracts, and authorized emulator/device smoke-test evidence.
