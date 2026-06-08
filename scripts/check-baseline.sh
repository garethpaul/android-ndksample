#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

require_file() {
  path=$1
  message=$2

  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

require_contains() {
  path=$1
  pattern=$2
  message=$3

  if ! grep -Fq "$pattern" "$ROOT_DIR/$path"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

for path in \
  "README.md" \
  "docs/plans/2026-06-08-ndk-provenance-baseline.md" \
  "AndroidManifest.xml" \
  "project.properties" \
  "jni/Android.mk" \
  "jni/Application.mk" \
  "jni/app-android.c" \
  "jni/demo.c" \
  "jni/importgl.c" \
  "jni/license.txt" \
  "jni/license-BSD.txt" \
  "jni/license-LGPL.txt" \
  "lint.xml"; do
  require_file "$path" "Required baseline file is missing: $path"
done

for abi in arm64-v8a armeabi-v7a armeabi mips mips64 x86 x86_64; do
  require_file "libs/$abi/libsanangeles.so" "Runtime native library is missing for ABI: $abi"
done

require_contains ".gitignore" "obj/" "Generated obj/ directory must be ignored."
require_contains "README.md" "Ant/NDK Android project" "README must document the legacy Ant/NDK shape."
require_contains "README.md" "libs/*/libsanangeles.so" "README must document checked-in runtime libraries."
require_contains "README.md" "Do not replace checked-in \`.so\` files" "README must document binary replacement rules."
require_contains "README.md" "lint --exitcode ." "README must document SDK-backed lint verification."
require_contains "project.properties" "target=Google Inc.:Google APIs:21" "project.properties must preserve the Google APIs 21 target."
require_contains "jni/Android.mk" "LOCAL_MODULE := sanangeles" "NDK module name must remain documented in Android.mk."
require_contains "jni/Application.mk" "APP_ABI := all" "Application.mk must preserve current ABI baseline."
require_contains "AndroidManifest.xml" 'android:allowBackup="false"' "Manifest must make backup behavior explicit."
require_contains "src/com/example/SanAngeles/DemoActivity.java" "public boolean performClick()" "GLSurfaceView touch handling must expose performClick."
require_contains "lint.xml" "LintError" "lint.xml must document the no-classfiles lint limitation."
require_contains "lint.xml" "UsesMinSdkAttributes" "lint.xml must document the deferred target SDK policy."

if [ ! -f "$ROOT_DIR/CHANGES.md" ]; then
  printf '%s\n' "CHANGES.md is required for repository maintenance history." >&2
  exit 1
fi

if [ -f "$ROOT_DIR/res/layout/main.xml" ]; then
  printf '%s\n' "Unused starter layout must not be restored." >&2
  exit 1
fi

if git -C "$ROOT_DIR" ls-files 'obj/*' | grep -q .; then
  printf '%s\n' "Generated obj/ artifacts must not be tracked." >&2
  exit 1
fi

printf '%s\n' "Android NDK sample provenance checks passed."
