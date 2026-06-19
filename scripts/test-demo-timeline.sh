#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CC=${CC:-cc}
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/android-ndksample-demo-timeline.XXXXXX")
trap 'rm -rf "$TMP_DIR"' 0 HUP INT TERM

"$CC" -std=c89 -pedantic -Wall -Wextra -Werror -Wno-unused-function \
  "$ROOT_DIR/scripts/test-demo-timeline.c" \
  -o "$TMP_DIR/test-demo-timeline"
"$TMP_DIR/test-demo-timeline"
