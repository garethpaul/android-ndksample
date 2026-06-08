# NDK Library Checksums

## Status: Completed

## Goal

Record and validate checksums for the checked-in `libsanangeles.so` runtime
libraries so future binary replacements are intentional and reviewable.

## Red

- Extended `scripts/check-baseline.sh` to require `libs/SHA256SUMS`, require one
  checksum entry per ABI runtime library, and validate the manifest with
  `sha256sum -c` when available.
- Confirmed the baseline failed with `Required baseline file is missing:
  libs/SHA256SUMS`.

## Green

- Added `libs/SHA256SUMS` with the current SHA-256 checksum for each checked-in
  ABI library.
- Documented the checksum manifest and validation behavior in the README.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`

The SDK-backed `lint --exitcode .` gate remains documented in README and was
not run in this environment.
