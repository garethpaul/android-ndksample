#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/android-ndksample-review-mutations.XXXXXX")
trap 'rm -rf "$TMP_DIR"' 0 HUP INT TERM

copy_repo() {
  destination=$1
  mkdir -p "$destination"
  tar -C "$ROOT_DIR" --exclude=.git -cf - . | tar -C "$destination" -xf -
}

expect_failure() {
  name=$1
  shift
  if "$@" >/dev/null 2>&1; then
    printf '%s\n' "FAIL: mutation survived: $name" >&2
    exit 1
  fi
}

copy_repo "$TMP_DIR/import-owner"
perl -0pi -e 's/if \(sGLESSO != NULL\)/if (0)/' \
  "$TMP_DIR/import-owner/jni/importgl.c"
expect_failure import-owner \
  "$TMP_DIR/import-owner/scripts/test-importgl-ownership.sh"

copy_repo "$TMP_DIR/timeline-reset"
perl -0pi -e 's/demoTimelineReset\(&sTimeline\);/(void)0;/' \
  "$TMP_DIR/timeline-reset/jni/demo.c"
expect_failure timeline-reset \
  "$TMP_DIR/timeline-reset/scripts/check-baseline.sh"

copy_repo "$TMP_DIR/track-count"
perl -0pi -e 's/sizeof\(sCamTracks\)/sizeof(camTracks)/' \
  "$TMP_DIR/track-count/jni/cams.h"
expect_failure track-count \
  "$TMP_DIR/track-count/scripts/check-baseline.sh"

for mode in dependency textrel stack search-path; do
  copy_repo "$TMP_DIR/elf-$mode"
done
perl -0pi -e 's/if \[ "\$actual_dependencies" != "\$expected_dependencies" \]; then/if false; then/' \
  "$TMP_DIR/elf-dependency/scripts/check-native-library-elf.sh"
expect_failure elf-dependency \
  "$TMP_DIR/elf-dependency/scripts/test-native-library-elf.sh"
perl -0pi -e 's/if printf '\''%s\\n'\'' "\$dynamic" \| grep -Fq TEXTREL; then/if false; then/' \
  "$TMP_DIR/elf-textrel/scripts/check-native-library-elf.sh"
expect_failure elf-textrel \
  "$TMP_DIR/elf-textrel/scripts/test-native-library-elf.sh"
perl -0pi -e 's/if \[ "\$stack_flags" != "RW" \]; then/if false; then/' \
  "$TMP_DIR/elf-stack/scripts/check-native-library-elf.sh"
expect_failure elf-stack \
  "$TMP_DIR/elf-stack/scripts/test-native-library-elf.sh"
perl -0pi -e 's/if printf '\''%s\\n'\'' "\$dynamic" \| grep -Eq '\''\\\(\(RPATH\|RUNPATH\)\\\)'\''; then/if false; then/' \
  "$TMP_DIR/elf-search-path/scripts/check-native-library-elf.sh"
expect_failure elf-search-path \
  "$TMP_DIR/elf-search-path/scripts/test-native-library-elf.sh"

printf '%s\n' "Native review mutation tests passed."
