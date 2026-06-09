# Changes

## 2026-06-08

- Added `libs/SHA256SUMS` and a baseline checksum validation gate for the
  checked-in `libsanangeles.so` ABI runtime libraries.
- Added a repository changelog and documented the SDK-backed lint gate for the
  legacy Ant/NDK project.
- Cleaned lint findings by making backup behavior explicit, exposing
  `performClick()` for the touch-driven GLSurfaceView, moving `<uses-sdk>` ahead
  of the application element, and removing the unused starter layout.
- Added a narrow lint baseline for findings deferred until a reproducible NDK
  rebuild, launcher icon, and target SDK policy exist.
- Added a `make check` wrapper for the SDK-free NDK provenance baseline.
- Added `libs/SHA256SUMS` to record checksums for checked-in runtime native
  libraries.
- Extended the SDK-free check to reject checked-in native libraries that are not
  covered by `libs/SHA256SUMS`.
