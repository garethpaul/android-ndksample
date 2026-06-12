---
title: Android NDK Sample CI Baseline
type: chore
status: completed
date: 2026-06-10
---

# Android NDK Sample CI Baseline

## Summary

Run the SDK-free NDK provenance baseline in GitHub Actions so binary
provenance, lifecycle, and JNI signature checks run before review.

## Work Completed

- Added `.github/workflows/check.yml` to run `make check` on pushes, pull
  requests, and manual dispatches.
- Pinned checkout to an immutable revision, limited permissions to repository
  reads, and bounded the job to five minutes.
- Kept the workflow host-neutral by relying on the existing guarded `make`
  targets, which skip unavailable Android lint or NDK rebuild tools with clear
  messages.
- Removed the maintainer-specific SDK path and explicitly disabled ambient
  hosted SDK/NDK discovery so CI remains a provenance and lifecycle gate.
- Extended `scripts/check-baseline.sh` to require the CI workflow and this
  completed maintenance plan.
- Updated README, VISION, SECURITY, and CHANGES with the CI baseline.
- Disabled persisted checkout credentials and replaced partial string matching
  with a canonical single-workflow contract.
- Added self-protecting CODEOWNERS coverage for CI controls, native source, and
  checked-in libraries; repository rules remain responsible for requiring owner
  approval.

## Verification

- `make check`
- `git diff --check`

## Follow-Up Candidates

- Add SDK/NDK-backed CI jobs after the exact Android SDK, NDK, and emulator or
  device smoke-test requirements are documented.
