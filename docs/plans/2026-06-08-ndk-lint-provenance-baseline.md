---
title: NDK Lint Provenance Baseline
type: chore
status: completed
date: 2026-06-08
---

# NDK Lint Provenance Baseline

## Summary

Add an SDK-backed lint gate for the legacy Ant/NDK sample while preserving the
existing binary provenance baseline and deferring native rebuilds.

## Requirements

- R1. Preserve checked-in `libs/*/libsanangeles.so` runtime libraries.
- R2. Do not regenerate native binaries without a documented NDK version and
  smoke-test path.
- R3. Fix lint findings that do not require behavior or binary changes.
- R4. Document narrow lint suppressions for findings blocked by the current
  provenance baseline.
- R5. Keep the SDK-free provenance check runnable without Android SDK or NDK
  tooling.

## Verification

- `scripts/check-baseline.sh`
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk /home/gjones/android-sdk/tools/bin/lint --exitcode .`
