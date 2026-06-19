#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CC=${CC:-cc}
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/android-ndksample-importgl.XXXXXX")
trap 'rm -rf "$TMP_DIR"' 0 HUP INT TERM

"$CC" -std=c89 -pedantic -Wall -Wextra -Werror -Wno-strict-prototypes \
  -I"$ROOT_DIR/scripts/fake-gl" \
  "$ROOT_DIR/scripts/test-importgl-ownership.c" \
  -o "$TMP_DIR/test-importgl-ownership"
"$TMP_DIR/test-importgl-ownership"
