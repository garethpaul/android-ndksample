#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

require_file() {
  path=$1

  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "Missing required file: $path" >&2
    exit 1
  fi
}

for path in \
  jni/Android.mk \
  jni/Application.mk \
  jni/app-android.c \
  jni/demo.c \
  jni/importgl.c \
  jni/license.txt \
  jni/license-LGPL.txt \
  jni/license-BSD.txt \
  src/com/example/SanAngeles/DemoActivity.java \
  AndroidManifest.xml \
  project.properties \
  README.md \
  VISION.md; do
  require_file "$path"
done

for abi in arm64-v8a armeabi armeabi-v7a mips mips64 x86 x86_64; do
  require_file "libs/$abi/libsanangeles.so"
done

if ! grep -Fq "target=Google Inc.:Google APIs:21" "$ROOT_DIR/project.properties"; then
  printf '%s\n' "project.properties must preserve the Google APIs 21 target." >&2
  exit 1
fi

if ! grep -Fq "checked-in" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document checked-in native artifacts." >&2
  exit 1
fi

printf '%s\n' "Android NDK sample provenance checks passed."
