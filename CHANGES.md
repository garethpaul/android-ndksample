# Changes

## 2026-06-08

- Added a repository changelog and documented the SDK-backed lint gate for the
  legacy Ant/NDK project.
- Cleaned lint findings by making backup behavior explicit, exposing
  `performClick()` for the touch-driven GLSurfaceView, moving `<uses-sdk>` ahead
  of the application element, and removing the unused starter layout.
- Added a narrow lint baseline for findings deferred until a reproducible NDK
  rebuild, launcher icon, and target SDK policy exist.
