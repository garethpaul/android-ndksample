# Native Size Overflow Guards

Status: Implementation Complete; Hosted Verification Pending

## Context

CodeQL alert 1 (`cpp/integer-multiplication-cast-to-long`) identifies the
supershape triangle count in `jni/demo.c`. `longitudeCount` and
`latitudeCount` are both `int`, so their product can overflow before the result
is assigned to `long`. The resulting vertex count also feeds three native
allocation-size calculations.

The current shape parameters are checked-in constants, but the allocation
helpers should reject invalid or unrepresentable dimensions rather than depend
on those inputs remaining small.

## Goal

Make native geometry and allocation size calculations fail closed before any
signed or `size_t` multiplication can overflow, without changing valid sample
geometry or replacing historical runtime libraries.

## Changes

- Add a portable checked-product helper for positive `long` values and native
  allocation byte counts.
- Use checked products for supershape and ground-plane triangle and vertex
  counts before allocating or iterating.
- Reject object counts that cannot be represented by the OpenGL draw-count
  boundary.
- Replace direct allocation-size products with checked byte counts.
- Add a host-compiled C boundary test and wire it into `make test`.
- Extend the baseline, README, CHANGES, and ownership contracts for the new
  helper and test.

## Verification

- Run the host C boundary test directly.
- Run `make check` from the repository and through an absolute Makefile path.
- Repeat `make check` from a fresh external clone.
- Reject focused arithmetic, allocation, test-wiring, documentation, plan, and
  ownership mutations.
- Pass exact-head push and pull-request hosted verification.

## Verification Evidence

- The portable C boundary test passed under GCC and Clang with strict C89
  warnings as errors, and under GCC undefined-behavior instrumentation.
- `make check` passed from the repository and through an absolute Makefile
  path; the unavailable Android SDK lint and NDK rebuild were truthfully
  skipped.
- The complete gate and all seven historical library checksums passed from a
  fresh external clone with the staged patch applied.
- All 29 focused arithmetic, allocation, geometry integration, test-wiring,
  ownership, documentation, and plan mutations were rejected.
- Exact-head hosted push and pull-request verification remains pending.

## Boundaries

- Do not change valid supershape or ground-plane geometry.
- Do not regenerate or replace checked-in `.so` files without a documented NDK
  version, exact rebuild command, ABI list, checksums, and runtime smoke test.
- Do not claim Android runtime or forced allocator-failure coverage from the
  host-only arithmetic test.
