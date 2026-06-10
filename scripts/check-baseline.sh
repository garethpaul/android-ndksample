#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CHECKSUM_PATH_PLAN="docs/plans/2026-06-09-ndk-checksum-path-hygiene.md"
TEARDOWN_PLAN="docs/plans/2026-06-09-ndk-render-after-teardown.md"
JAVA_LIFECYCLE_PLAN="docs/plans/2026-06-09-ndk-java-lifecycle-view-guard.md"
CI_PLAN="docs/plans/2026-06-10-ci-baseline.md"

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
  ".github/workflows/check.yml" \
  "docs/plans/2026-06-08-ndk-provenance-baseline.md" \
  "$CHECKSUM_PATH_PLAN" \
  "$TEARDOWN_PLAN" \
  "$JAVA_LIFECYCLE_PLAN" \
  "$CI_PLAN" \
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
require_contains "README.md" "tools/bin/lint" "README must document the SDK-backed lint tool path."
require_contains "README.md" 'lint" --exitcode .' "README must document lint failure propagation."
require_contains "project.properties" "target=Google Inc.:Google APIs:21" "project.properties must preserve the Google APIs 21 target."
require_contains "jni/Android.mk" "LOCAL_MODULE := sanangeles" "NDK module name must remain documented in Android.mk."
require_contains "jni/Application.mk" "APP_ABI := all" "Application.mk must preserve current ABI baseline."
require_contains "AndroidManifest.xml" 'android:allowBackup="false"' "Manifest must make backup behavior explicit."
require_contains "src/com/example/SanAngeles/DemoActivity.java" "public boolean performClick()" "GLSurfaceView touch handling must expose performClick."
if ! grep -A6 "protected void onPause()" "$ROOT_DIR/src/com/example/SanAngeles/DemoActivity.java" | grep -Fq "if (mGLView != null)"; then
  printf '%s\n' "Activity pause path must guard missing GLSurfaceView instances." >&2
  exit 1
fi
if ! grep -A6 "protected void onResume()" "$ROOT_DIR/src/com/example/SanAngeles/DemoActivity.java" | grep -Fq "if (mGLView != null)"; then
  printf '%s\n' "Activity resume path must guard missing GLSurfaceView instances." >&2
  exit 1
fi
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
require_contains "jni/app-android.c" "if (!importGLInit())" "Native initialization must stop when OpenGL imports fail."
require_contains "jni/app-android.c" "OpenGL ES imports are unavailable" "Native initialization failure must use a generic diagnostic."
require_contains "jni/app-android.c" "importGLDeinit();" "Failed OpenGL imports must be cleaned up."
require_contains "jni/app-android.c" "gAppAlive = 0;" "Failed native initialization must mark the app inactive."
require_contains "jni/app-android.c" "if (w <= 0 || h <= 0)" "JNI resize must reject invalid surface dimensions."
require_contains "jni/app-android.c" "Ignoring invalid surface dimensions" "Invalid surface dimensions must use a generic warning."
require_contains "jni/app-android.c" "sWindowWidth <= 0 || sWindowHeight <= 0" "JNI render must reject invalid stored dimensions."
require_contains "jni/demo.c" "width <= 0 || height <= 0" "Portable renderer must reject invalid dimensions before projection math."

NATIVE_DONE=$(awk '/Java_com_example_SanAngeles_DemoRenderer_nativeDone/,/^}/' "$ROOT_DIR/jni/app-android.c")
if printf '%s\n' "$NATIVE_DONE" | grep -Fq "sWindowWidth"; then
  printf '%s\n' "Native teardown must not depend on surface dimensions." >&2
  exit 1
fi

NATIVE_RENDER=$(awk '/Java_com_example_SanAngeles_DemoRenderer_nativeRender/,/^}/' "$ROOT_DIR/jni/app-android.c")
if ! printf '%s\n' "$NATIVE_RENDER" | grep -Fq "sWindowWidth <= 0 || sWindowHeight <= 0"; then
  printf '%s\n' "Native render must own the stored-dimension guard." >&2
  exit 1
fi
require_contains "jni/app-android.c" "sTimeOffsetInit = 0;" "Native initialization must reset timing state."
if grep -Fq "    importGLInit();" "$ROOT_DIR/jni/app-android.c"; then
  printf '%s\n' "Native initialization must not ignore the OpenGL import result." >&2
  exit 1
fi

IMPORT_FAILURE_GUARD=$(awk '/if \(!importGLInit\(\)\)/,/^    }/' "$ROOT_DIR/jni/app-android.c")
for failure_contract in \
  "OpenGL ES imports are unavailable" \
  "importGLDeinit();" \
  "gAppAlive = 0;" \
  "return;"; do
  if ! printf '%s\n' "$IMPORT_FAILURE_GUARD" | grep -Fq "$failure_contract"; then
    printf '%s\n' "OpenGL import failure guard is missing: $failure_contract" >&2
    exit 1
  fi
done

if ! awk '
  /if \(!importGLInit\(\)\)/ && !guard_line { guard_line = NR }
  $0 == "    sTimeOffsetInit = 0;" { reset_line = NR }
  /appInit\(\);/ && !app_line { app_line = NR }
  END { exit !(guard_line && reset_line && app_line && guard_line < reset_line && reset_line < app_line) }
' "$ROOT_DIR/jni/app-android.c"; then
  printf '%s\n' "Native init must validate GL imports, reset state, then initialize the demo." >&2
  exit 1
fi
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
require_contains "README.md" "GitHub Actions" "README must document the GitHub Actions check."
require_contains "README.md" "JNI bindings use static native signatures" "README must document JNI static native signatures."
require_contains ".github/workflows/check.yml" "permissions:" "CI workflow must declare permissions."
require_contains ".github/workflows/check.yml" "contents: read" "CI workflow permissions must be read-only."
require_contains ".github/workflows/check.yml" "runs-on: ubuntu-24.04" "CI workflow must use a fixed Ubuntu runner image."
require_contains ".github/workflows/check.yml" "cancel-in-progress: true" "CI workflow must cancel superseded runs."
require_contains ".github/workflows/check.yml" "timeout-minutes: 5" "CI workflow must have a bounded timeout."
require_contains ".github/workflows/check.yml" "workflow_dispatch:" "CI workflow must support manual dispatch."
require_contains ".github/workflows/check.yml" "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" "CI workflow must pin checkout."
require_contains ".github/workflows/check.yml" 'ANDROID_HOME: ""' "CI workflow must clear Android SDK discovery."
require_contains ".github/workflows/check.yml" 'ANDROID_SDK_ROOT: ""' "CI workflow must clear Android SDK root discovery."
require_contains ".github/workflows/check.yml" 'NDK_BUILD: "__disabled_ndk_build__"' "CI workflow must disable ambient NDK rebuilds."
require_contains "Makefile" 'ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' "Makefile must resolve repository paths from its own location."
require_contains "Makefile" 'ANDROID_SDK := $(if $(ANDROID_HOME),$(ANDROID_HOME),$(ANDROID_SDK_ROOT))' "Makefile must accept either Android SDK environment variable."

if grep -Fq "/home/gjones" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must not embed a maintainer-specific Android SDK path." >&2
  exit 1
fi
if grep -Fq "/home/gjones" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must not embed a maintainer-specific Android SDK path." >&2
  exit 1
fi
require_contains ".github/workflows/check.yml" "make check" "CI workflow must run make check."
require_contains "$CHECKSUM_PATH_PLAN" "status: completed" "Checksum path hygiene plan must be completed."
require_contains "$CI_PLAN" "status: completed" "CI baseline plan must be completed."
require_contains "$CI_PLAN" "make check" "CI baseline plan must document make check verification."

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

if ! grep -Fq "Native surface dimensions are rejected" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document native surface dimension guards." >&2
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

if ! grep -Fq "make check" "$ROOT_DIR/$JAVA_LIFECYCLE_PLAN"; then
  printf '%s\n' "NDK Java lifecycle view guard plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-10-ndk-surface-dimension-guards.md" || \
   ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-10-ndk-surface-dimension-guards.md"; then
  printf '%s\n' "NDK surface-dimension plan must record completed status and make check verification." >&2
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
