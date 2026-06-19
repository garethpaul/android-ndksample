# Android NDK Device Verification Matrix

Use this matrix only for an exact implementation commit. Record the commit SHA and pull request
before testing so evidence cannot be transferred between different native
binaries or lifecycle implementations.

## Evidence Rules

- Record the Android SDK and NDK versions, Android API level, ABI, GPU model, renderer string,
  device or emulator class, and whether checked-in or rebuilt native libraries
  were exercised.
- Use only synthetic interaction with the San Angeles demo. Do not include
  device serials, account names, notifications, unrelated screen content,
  absolute workstation paths, or raw diagnostic dumps.
- Store durable evidence outside git. Link a sanitized run, screenshot, or log
  excerpt by stable identifier and include the exact command or action used.
- Record each result as `pass`, `fail`, `blocked`, or `not run`, with an owner
  and follow-up for every result other than `pass`.
- Do not convert `not run` into passing evidence.

## Run Identity

| Field | Value |
| --- | --- |
| Commit SHA | `not run` |
| Pull request | `not run` |
| Android SDK / NDK | `not run` |
| API level / ABI | `not run` |
| Device or emulator | `not run` |
| GPU / renderer | `not run` |
| Native library provenance | `not run` |
| Evidence location | `not run` |

## Verification Matrix

| Scenario | Expected evidence | Result | Evidence |
| --- | --- | --- | --- |
| First launch | Activity starts, surface initializes, and the demo renders without a crash or native loader error. | `not run` | `not run` |
| Continuous rendering | Animation remains visible and responsive for an agreed smoke interval without corruption, ANR, or tombstone. | `not run` | `not run` |
| Surface resize | Rotation or emulator resize recreates valid dimensions and resumes rendering without a stale viewport. | `not run` | `not run` |
| Background/foreground | Pausing and resuming preserves a nonnegative, nondecreasing animation timeline. | `not run` | `not run` |
| Rapid pause/resume | Repeated lifecycle transitions do not double-count paused time, crash, or render after teardown. | `not run` | `not run` |
| Context loss | A forced or naturally observed GL context loss reinitializes safely or fails closed without stale imported pointers. | `not run` | `not run` |
| Render-thread teardown | Native cleanup executes on the GL render thread before the view pauses and does not race a late frame. | `not run` | `not run` |
| Process recreation | Process death and relaunch create fresh native state without reusing freed demo objects. | `not run` | `not run` |
| Repeated finish/relaunch | Multiple activity finish and relaunch cycles remain crash-free and do not accumulate native resources. | `not run` | `not run` |
| Unsupported or failed GL import | Initialization fails before demo setup and leaves no partially initialized native state. | `not run` | `not run` |
| ABI coverage | Each claimed ABI loads the expected library and reports the tested binary provenance. | `not run` | `not run` |
| Interruption evidence | Failure, ANR, tombstone, or interruption evidence is sanitized and linked without being committed. | `not run` | `not run` |

## Current Status

No Android SDK, NDK rebuild, emulator, GPU, physical device, or live OpenGL ES
scenario was executed for this checklist. Treat every Android, GPU, and lifecycle row as unexecuted
until evidence is attached to the exact commit.
