#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CHECKSUM_PATH_PLAN="docs/plans/2026-06-09-ndk-checksum-path-hygiene.md"
TEARDOWN_PLAN="docs/plans/2026-06-09-ndk-render-after-teardown.md"

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
  "$CHECKSUM_PATH_PLAN" \
  "$TEARDOWN_PLAN" \
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
  "libs/SHA256SUMS" \
  "lint.xml"; do
  require_file "$path" "Required baseline file is missing: $path"
done

expected_abi_count=0
for abi in arm64-v8a armeabi-v7a armeabi mips mips64 x86 x86_64; do
  expected_abi_count=$((expected_abi_count + 1))
  require_file "libs/$abi/libsanangeles.so" "Runtime native library is missing for ABI: $abi"
  require_contains "libs/SHA256SUMS" "libs/$abi/libsanangeles.so" "Checksum manifest must include ABI library: $abi"
done

while read -r checksum path extra; do
  if [ -z "$checksum" ]; then
    continue
  fi

  if [ "${#checksum}" -ne 64 ]; then
    printf '%s\n' "Checksum manifest entries must use lowercase SHA-256 digests." >&2
    exit 1
  fi
  case "$checksum" in
    *[!0123456789abcdef]*)
      printf '%s\n' "Checksum manifest entries must use lowercase SHA-256 digests." >&2
      exit 1
      ;;
  esac

  if [ -n "${extra:-}" ]; then
    printf '%s\n' "Checksum manifest entries must contain exactly a digest and a path." >&2
    exit 1
  fi

  case "$path" in
    /*|../*|*/../*|*\\*)
      printf '%s\n' "Checksum manifest paths must stay repo-relative: $path" >&2
      exit 1
      ;;
  esac

  case "$path" in
    libs/arm64-v8a/libsanangeles.so|\
libs/armeabi-v7a/libsanangeles.so|\
libs/armeabi/libsanangeles.so|\
libs/mips/libsanangeles.so|\
libs/mips64/libsanangeles.so|\
libs/x86/libsanangeles.so|\
libs/x86_64/libsanangeles.so)
      ;;
    *)
      printf '%s\n' "Checksum manifest path is outside the expected ABI set: $path" >&2
      exit 1
      ;;
  esac
done < "$ROOT_DIR/libs/SHA256SUMS"

checked_in_library_count=$(find "$ROOT_DIR/libs" -mindepth 2 -maxdepth 2 -name 'libsanangeles.so' | wc -l | tr -d ' ')
if [ "$checked_in_library_count" -ne "$expected_abi_count" ]; then
  printf '%s\n' "Checked-in libsanangeles.so ABI count must match the documented baseline." >&2
  exit 1
fi

unmanifested_libraries=$(find "$ROOT_DIR/libs" -type f -name '*.so' | sort | while IFS= read -r library; do
  relative_path=${library#"$ROOT_DIR/"}
  if ! grep -Fq "$relative_path" "$ROOT_DIR/libs/SHA256SUMS"; then
    printf '%s\n' "$relative_path"
  fi
done)
if [ -n "$unmanifested_libraries" ]; then
  printf '%s\n' "Checked-in native libraries must be listed in libs/SHA256SUMS:" >&2
  printf '%s\n' "$unmanifested_libraries" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  if ! (cd "$ROOT_DIR" && sha256sum -c libs/SHA256SUMS >/dev/null); then
    printf '%s\n' "Checked-in native library checksums must validate." >&2
    exit 1
  fi
fi

require_contains ".gitignore" "obj/" "Generated obj/ directory must be ignored."
require_contains "README.md" "Ant/NDK Android project" "README must document the legacy Ant/NDK shape."
require_contains "README.md" "libs/*/libsanangeles.so" "README must document checked-in runtime libraries."
require_contains "README.md" "libs/SHA256SUMS" "README must document the native library checksum manifest."
require_contains "README.md" "Do not replace checked-in \`.so\` files" "README must document binary replacement rules."
require_contains "README.md" "lint --exitcode ." "README must document SDK-backed lint verification."
require_contains "project.properties" "target=Google Inc.:Google APIs:21" "project.properties must preserve the Google APIs 21 target."
require_contains "jni/Android.mk" "LOCAL_MODULE := sanangeles" "NDK module name must remain documented in Android.mk."
require_contains "jni/Application.mk" "APP_ABI := all" "Application.mk must preserve current ABI baseline."
require_contains "AndroidManifest.xml" 'android:allowBackup="false"' "Manifest must make backup behavior explicit."
require_contains "src/com/example/SanAngeles/DemoActivity.java" "public boolean performClick()" "GLSurfaceView touch handling must expose performClick."
require_contains "src/com/example/SanAngeles/DemoActivity.java" "protected void onDestroy()" "Activity must release native resources during destruction."
require_contains "src/com/example/SanAngeles/DemoActivity.java" "mGLView.releaseNativeResources();" "Activity destroy path must release GLSurfaceView native resources."
require_contains "src/com/example/SanAngeles/DemoActivity.java" "public void releaseNativeResources()" "GLSurfaceView must expose native resource cleanup."
require_contains "src/com/example/SanAngeles/DemoActivity.java" "nativeDone();" "Renderer cleanup must call the native deinitializer."
require_contains "jni/app-android.c" "Java_com_example_SanAngeles_DemoRenderer_nativeDone" "JNI nativeDone binding must stay present."
require_contains "jni/app-android.c" "appDeinit();" "nativeDone must deinitialize demo objects."
require_contains "jni/app-android.c" "importGLDeinit();" "nativeDone must release imported GL bindings."
require_contains "jni/app-android.c" "Java_com_example_SanAngeles_DemoRenderer_nativeInit( JNIEnv*  env, jclass  clazz )" "static nativeInit JNI signature must include jclass."
require_contains "jni/app-android.c" "Java_com_example_SanAngeles_DemoRenderer_nativeResize( JNIEnv*  env, jclass  clazz, jint w, jint h )" "static nativeResize JNI signature must include jclass."
require_contains "jni/app-android.c" "Java_com_example_SanAngeles_DemoRenderer_nativeDone( JNIEnv*  env, jclass  clazz )" "static nativeDone JNI signature must include jclass."
require_contains "jni/app-android.c" "Java_com_example_SanAngeles_DemoRenderer_nativeRender( JNIEnv*  env, jclass  clazz )" "static nativeRender JNI signature must include jclass."
require_contains "jni/app-android.c" "Java_com_example_SanAngeles_DemoGLSurfaceView_nativeTogglePauseResume( JNIEnv*  env, jclass  clazz )" "static nativeTogglePauseResume JNI signature must include jclass."
require_contains "jni/app-android.c" "Java_com_example_SanAngeles_DemoGLSurfaceView_nativePause( JNIEnv*  env, jclass  clazz )" "static nativePause JNI signature must include jclass."
require_contains "jni/app-android.c" "Java_com_example_SanAngeles_DemoGLSurfaceView_nativeResume( JNIEnv*  env, jclass  clazz )" "static nativeResume JNI signature must include jclass."
require_contains "jni/app-android.c" "if (sDemoStopped) {" "Native pause must be idempotent when the demo is already stopped."
require_contains "jni/app-android.c" "if (!sDemoStopped) {" "Native resume must be idempotent when the demo is already running."
require_contains "jni/app-android.c" "_resume();" "Native toggle must route through resume helper."
require_contains "jni/app-android.c" "_pause();" "Native toggle must route through pause helper."
require_contains "jni/app-android.c" "static int  sNativeInitialized = 0;" "Android JNI layer must track initialized native resources."
require_contains "jni/app-android.c" "if (sNativeInitialized) {" "nativeInit must release an existing native resource set before reinitializing."
require_contains "jni/app-android.c" "sNativeInitialized = 1;" "nativeInit must mark native resources initialized after setup."
require_contains "jni/app-android.c" "if (!sNativeInitialized) {" "nativeDone and nativeRender must guard uninitialized native resources."
require_contains "jni/app-android.c" "sNativeInitialized = 0;" "nativeDone must clear initialized state after cleanup."
require_contains "jni/demo.c" "sSuperShapeObjects[a] = NULL;" "Native demo cleanup must null freed supershape pointers."
require_contains "jni/demo.c" "sGroundPlane = NULL;" "Native demo cleanup must null the freed ground-plane pointer."
require_contains "jni/demo.c" "static int appResourcesReady()" "Native render path must expose a resource-readiness guard."
require_contains "jni/demo.c" "!appResourcesReady()" "Native render path must skip drawing after resource teardown."
require_contains "lint.xml" "LintError" "lint.xml must document the no-classfiles lint limitation."
require_contains "lint.xml" "UsesMinSdkAttributes" "lint.xml must document the deferred target SDK policy."

if [ ! -f "$ROOT_DIR/CHANGES.md" ]; then
  printf '%s\n' "CHANGES.md is required for repository maintenance history." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/Makefile" ]; then
  printf '%s\n' "Makefile is required for the repository check wrapper." >&2
  exit 1
fi

require_contains "Makefile" "scripts/check-baseline.sh" "Makefile must run the SDK-free baseline check."
require_contains "Makefile" "lint:" "Makefile must expose a lint gate."
require_contains "Makefile" "test:" "Makefile must expose a test gate."
require_contains "Makefile" "build:" "Makefile must expose a guarded build gate."
require_contains "Makefile" "verify: lint test build" "Makefile verify must run lint, test, and build gates."
require_contains "README.md" "make check" "README must document the make check wrapper."
require_contains "README.md" "JNI bindings use static native signatures" "README must document JNI static native signatures."
require_contains "$CHECKSUM_PATH_PLAN" "status: completed" "Checksum path hygiene plan must be completed."

if grep -Fq "nativeInit( JNIEnv*  env )" "$ROOT_DIR/jni/app-android.c"; then
  printf '%s\n' "static nativeInit JNI signature must not omit jclass." >&2
  exit 1
fi

if grep -Fq "sDemoStopped = !sDemoStopped;" "$ROOT_DIR/jni/app-android.c"; then
  printf '%s\n' "Native toggle must not flip state before pause/resume helpers run." >&2
  exit 1
fi

if ! grep -Fq "Native pause/resume helpers are idempotent" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document native pause/resume idempotence." >&2
  exit 1
fi

if ! grep -Fq "Native render calls are ignored after teardown" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document native render-after-teardown behavior." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/$TEARDOWN_PLAN"; then
  printf '%s\n' "NDK render-after-teardown plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-ndk-native-pause-resume-idempotence.md"; then
  printf '%s\n' "NDK native pause/resume idempotence plan must document make check verification." >&2
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
