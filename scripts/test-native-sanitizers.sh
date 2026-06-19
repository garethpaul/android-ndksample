#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CC=${CC:-cc}
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/android-ndksample-sanitizers.XXXXXX")
trap 'rm -rf "$TMP_DIR"' 0 HUP INT TERM

sanitizers=undefined
if [ "$(uname -s)" = Linux ]; then
  sanitizers=address,undefined
fi

common_flags="-std=c89 -pedantic -Wall -Wextra -Werror -fno-omit-frame-pointer -fsanitize=$sanitizers"

# shellcheck disable=SC2086
"$CC" $common_flags -Wno-unused-function \
  "$ROOT_DIR/scripts/test-native-size-guards.c" \
  -o "$TMP_DIR/test-native-size-guards"
"$TMP_DIR/test-native-size-guards"

# shellcheck disable=SC2086
"$CC" $common_flags -Wno-unused-function \
  "$ROOT_DIR/scripts/test-demo-timeline.c" \
  -o "$TMP_DIR/test-demo-timeline"
"$TMP_DIR/test-demo-timeline"

# shellcheck disable=SC2086
"$CC" $common_flags -Wno-strict-prototypes \
  -I"$ROOT_DIR/scripts/fake-gl" \
  "$ROOT_DIR/scripts/test-importgl-ownership.c" \
  -o "$TMP_DIR/test-importgl-ownership"
"$TMP_DIR/test-importgl-ownership"

printf '%s\n' "Native sanitizer tests passed with $sanitizers."
