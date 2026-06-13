# AGENTS.md

## Repository purpose

Legacy Android NDK sample for the San Angeles Observation OpenGL ES demo.

## Project structure

- `Makefile` - repository verification targets
- `scripts` - baseline checks and helper scripts
- `docs` - plans, notes, and generated README assets
- `src` - primary source code
- `jni` - Android NDK native source
- `libs` - checked-in runtime libraries or binary assets
- `AndroidManifest.xml` - legacy Android manifest

## Development commands

- Install dependencies: no repository-specific install command is documented.
- Full baseline: `make check`
- Combined verification: `make verify`
- Lint/static checks: `make lint`
- Tests: `make test`
- Build: `make build`
- If a command above skips because a platform toolchain is missing, verify on a machine with that SDK before claiming platform behavior is tested.
- Portable GL loader cleanup must guard and clear Windows/Linux dynamic-library
  handles, then reset imported GL function pointers only after a successful
  close so repeated teardown remains a no-op.
- Portable GL partial symbol imports self-clean before failure returns.

## Coding conventions

- This is a legacy Android layout without a Gradle wrapper; do not assume modern Gradle tasks exist.

## Testing guidance

- No dedicated test files were detected; treat `make check` as the minimum baseline.
- Start with the narrowest relevant test or Make target, then run `make check` before handing off if the change is not documentation-only.
- Keep README verification notes in sync when commands, fixtures, or supported toolchains change.

## PR / change guidance

- Keep diffs focused on the requested repository and avoid unrelated modernization or formatting churn.
- Preserve public APIs, sample behavior, file formats, and documented environment variables unless the task explicitly changes them.
- Update tests, README notes, or docs/plans when behavior, security posture, or validation commands change.
- Call out skipped platform validation, legacy toolchain assumptions, and any risky files touched in the final summary.

## Safety and gotchas

- Before replacing native libraries, document the Android NDK version, exact rebuild command, target ABI list, resulting checksums, and runtime smoke-test evidence.
- Confirm every checked-in `.so` file is listed in `libs/SHA256SUMS`.
- Checked-in binary libraries are present; do not replace them without documenting toolchain and checksums.
- Keep `libs/SHA256SUMS` synchronized with checked-in native libraries and use lowercase SHA-256 digests.
- Native/NDK changes need toolchain, ABI list, and smoke-test notes before replacing runtime libraries.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
