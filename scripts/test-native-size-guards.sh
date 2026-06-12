#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CC=${CC:-cc}
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/android-ndksample-size-guards.XXXXXX")
trap 'rm -rf "$TMP_DIR"' 0 HUP INT TERM

"$CC" -std=c89 -pedantic -Wall -Wextra -Werror \
  "$ROOT_DIR/scripts/test-native-size-guards.c" \
  -o "$TMP_DIR/test-native-size-guards"
"$TMP_DIR/test-native-size-guards"
