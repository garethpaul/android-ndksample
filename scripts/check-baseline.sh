#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CHECKSUM_PATH_PLAN="docs/plans/2026-06-09-ndk-checksum-path-hygiene.md"
TEARDOWN_PLAN="docs/plans/2026-06-09-ndk-render-after-teardown.md"
JAVA_LIFECYCLE_PLAN="docs/plans/2026-06-09-ndk-java-lifecycle-view-guard.md"
CI_WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"
CODEOWNERS="$ROOT_DIR/.github/CODEOWNERS"
CI_PLAN="docs/plans/2026-06-10-ci-baseline.md"
ALLOCATION_FAILURE_PLAN="docs/plans/2026-06-12-ndk-allocation-failure-recovery.md"
SIZE_OVERFLOW_PLAN="docs/plans/2026-06-12-native-size-overflow-guards.md"
ELF_CONTRACT_PLAN="docs/plans/2026-06-13-native-library-elf-contract.md"
IMPORTGL_DEINIT_PLAN="docs/plans/2026-06-13-importgl-idempotent-deinit.md"
IMPORTGL_POINTER_RESET_PLAN="docs/plans/2026-06-13-importgl-function-pointer-reset.md"
IMPORTGL_INIT_FAILURE_PLAN="docs/plans/2026-06-13-importgl-init-failure-cleanup.md"

expected_ci_workflow() {
  cat <<'EOF'
name: Check

on:
  push:
    branches:
      - master
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: check-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  check:
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - name: Check out repository
        uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
        with:
          persist-credentials: false

      - name: Run baseline
        run: make check
        env:
          ANDROID_HOME: ""
          ANDROID_SDK_ROOT: ""
          NDK_BUILD: "__disabled_ndk_build__"
EOF
}

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
  "$ALLOCATION_FAILURE_PLAN" \
  "$SIZE_OVERFLOW_PLAN" \
  "$ELF_CONTRACT_PLAN" \
  "AndroidManifest.xml" \
  "project.properties" \
  "jni/Android.mk" \
  "jni/Application.mk" \
  "jni/app-android.c" \
  "jni/checked-size.h" \
  "jni/demo.c" \
  "jni/importgl.c" \
  "jni/license.txt" \
  "jni/license-BSD.txt" \
  "jni/license-LGPL.txt" \
  "libs/SHA256SUMS" \
  "scripts/test-native-size-guards.c" \
  "scripts/test-native-size-guards.sh" \
  "scripts/check-native-library-elf.sh" \
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
require_contains "Makefile" '$(ROOT)scripts/check-native-library-elf.sh' "make test must run the native library ELF verifier."
require_contains "scripts/check-native-library-elf.sh" "verify_library arm64-v8a ELF64 AArch64" "ELF verifier must bind arm64-v8a to AArch64 ELF64."
require_contains "scripts/check-native-library-elf.sh" "verify_library armeabi-v7a ELF32 ARM" "ELF verifier must bind armeabi-v7a to ARM ELF32."
require_contains "scripts/check-native-library-elf.sh" "verify_library armeabi ELF32 ARM" "ELF verifier must bind armeabi to ARM ELF32."
require_contains "scripts/check-native-library-elf.sh" "verify_library mips64 ELF64 \"MIPS R3000\"" "ELF verifier must bind mips64 to MIPS ELF64."
require_contains "scripts/check-native-library-elf.sh" "verify_library mips ELF32 \"MIPS R3000\"" "ELF verifier must bind mips to MIPS ELF32."
require_contains "scripts/check-native-library-elf.sh" "verify_library x86_64 ELF64 \"Advanced Micro Devices X86-64\"" "ELF verifier must bind x86_64 to ELF64."
require_contains "scripts/check-native-library-elf.sh" "verify_library x86 ELF32 \"Intel 80386\"" "ELF verifier must bind x86 to ELF32."
if [ "$(grep -c '^verify_library ' "$ROOT_DIR/scripts/check-native-library-elf.sh" || true)" -ne 7 ]; then
  printf '%s\n' "ELF verifier must check exactly seven ABI libraries." >&2
  exit 1
fi
require_contains "scripts/check-native-library-elf.sh" "actual_jni_symbols" "ELF verifier must compare the exact JNI export set."
require_contains "scripts/check-native-library-elf.sh" "invalid_jni_symbols" "ELF verifier must reject invalid application JNI symbol metadata."
require_contains "scripts/check-native-library-elf.sh" 'if [ "$actual_jni_symbols" != "$expected_jni_symbols" ]; then' "ELF verifier must reject additive or missing application JNI exports."
require_contains "scripts/check-native-library-elf.sh" "Library soname: [libsanangeles.so]" "ELF verifier must require the sanangeles SONAME."
require_contains "scripts/check-native-library-elf.sh" "libGLESv1_CM.so libdl.so liblog.so" "ELF verifier must require Android and OpenGL dependencies."
if [ ! -x "$ROOT_DIR/scripts/check-native-library-elf.sh" ]; then
  printf '%s\n' "Native library ELF verifier must remain executable." >&2
  exit 1
fi
if [ ! -f "$ROOT_DIR/$ELF_CONTRACT_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$ROOT_DIR/$ELF_CONTRACT_PLAN" || \
   ! grep -Fq "make check" "$ROOT_DIR/$ELF_CONTRACT_PLAN" || \
   ! grep -Fq "hostile mutations" "$ROOT_DIR/$ELF_CONTRACT_PLAN"; then
  printf '%s\n' "Native library ELF contract plan must record completed verification." >&2
  exit 1
fi
for elf_contract_doc in README.md SECURITY.md CHANGES.md; do
  if ! tr '\n' ' ' < "$ROOT_DIR/$elf_contract_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "ELF runtime-shape contract"; then
    printf '%s\n' "$elf_contract_doc must document the ELF runtime-shape contract." >&2
    exit 1
  fi
done
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

IMPORTGL_DEINIT=$(awk '/^void importGLDeinit\(\)/,/^}/' "$ROOT_DIR/jni/importgl.c")
IMPORTGL_INIT=$(awk '/^int importGLInit\(\)/,/^}/' "$ROOT_DIR/jni/importgl.c")
IMPORTGL_POINTER_RESET=$(awk '/^static void clearImportedFunctions\(void\)/,/^}/' "$ROOT_DIR/jni/importgl.c")
IMPORTED_FUNCTIONS=$(printf '%s\n' "$IMPORTGL_INIT" | sed -n 's/^[[:space:]]*IMPORT_FUNC(\([A-Za-z0-9_]*\));[[:space:]]*$/\1/p' | sort)
RESET_FUNCTIONS=$(printf '%s\n' "$IMPORTGL_POINTER_RESET" | sed -n 's/^[[:space:]]*RESET_FUNC(\([A-Za-z0-9_]*\));[[:space:]]*$/\1/p' | sort)

if [ "$(printf '%s\n' "$IMPORTED_FUNCTIONS" | grep -c .)" -ne 40 ] || \
   [ "$IMPORTED_FUNCTIONS" != "$RESET_FUNCTIONS" ]; then
  printf '%s\n' "Portable GL loader cleanup must reset the exact 40-symbol import set." >&2
  exit 1
fi

IMPORTGL_DEINIT_COMPACT=$(printf '%s\n' "$IMPORTGL_DEINIT" | tr -d '[:space:]')
IMPORTGL_INIT_COMPACT=$(printf '%s\n' "$IMPORTGL_INIT" | tr -d '[:space:]')
if ! printf '%s\n' "$IMPORTGL_INIT_COMPACT" | grep -Fq \
    'IMPORT_FUNC(glViewport);if(!result)importGLDeinit();#endif/*DISABLE_IMPORTGL*/returnresult;'; then
  printf '%s\n' "Portable GL initialization must self-clean partial imports before returning failure." >&2
  exit 1
fi
if [ "$(printf '%s\n' "$IMPORTGL_INIT" | grep -Fc "importGLDeinit();")" -ne 1 ]; then
  printf '%s\n' "Portable GL initialization must keep exactly one failure-conditioned cleanup call." >&2
  exit 1
fi
for importgl_pointer_reset_contract in \
  "if(FreeLibrary(sGLESDLL)!=0){sGLESDLL=NULL;clearImportedFunctions();}" \
  "if(dlclose(sGLESSO)==0){sGLESSO=NULL;clearImportedFunctions();}"; do
  if ! printf '%s\n' "$IMPORTGL_DEINIT_COMPACT" | grep -Fq "$importgl_pointer_reset_contract"; then
    printf '%s\n' "Imported GL function pointers must clear only after successful close: $importgl_pointer_reset_contract" >&2
    exit 1
  fi
done

if [ "$(printf '%s\n' "$IMPORTGL_DEINIT" | grep -Fc "clearImportedFunctions();")" -ne 2 ]; then
  printf '%s\n' "Portable GL loader cleanup must clear imported functions once per platform close." >&2
  exit 1
fi

for importgl_deinit_contract in \
  "if (sGLESDLL != NULL)" \
  "if (FreeLibrary(sGLESDLL) != 0)" \
  "sGLESDLL = NULL;" \
  "if (sGLESSO != NULL)" \
  "if (dlclose(sGLESSO) == 0)" \
  "sGLESSO = NULL;"; do
  if ! printf '%s\n' "$IMPORTGL_DEINIT" | grep -Fq "$importgl_deinit_contract"; then
    printf '%s\n' "Portable GL loader cleanup must keep contract: $importgl_deinit_contract" >&2
    exit 1
  fi
done

if ! printf '%s\n' "$IMPORTGL_DEINIT" | awk '
  /if \(sGLESDLL != NULL\)/ { windows_guard = NR }
  /if \(FreeLibrary\(sGLESDLL\) != 0\)/ { windows_close = NR }
  /sGLESDLL = NULL;/ { windows_reset = NR }
  /if \(sGLESSO != NULL\)/ { linux_guard = NR }
  /if \(dlclose\(sGLESSO\) == 0\)/ { linux_close = NR }
  /sGLESSO = NULL;/ { linux_reset = NR }
  END {
    exit !(windows_guard < windows_close && windows_close < windows_reset &&
           linux_guard < linux_close && linux_close < linux_reset)
  }
'; then
  printf '%s\n' "Portable GL handles must be guarded, closed, then cleared." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/$IMPORTGL_DEINIT_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$ROOT_DIR/$IMPORTGL_DEINIT_PLAN" || \
   ! grep -Fq "make check" "$ROOT_DIR/$IMPORTGL_DEINIT_PLAN" || \
   ! grep -Fq "hostile mutations" "$ROOT_DIR/$IMPORTGL_DEINIT_PLAN"; then
  printf '%s\n' "ImportGL deinitialization plan must record completed verification." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/$IMPORTGL_POINTER_RESET_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$ROOT_DIR/$IMPORTGL_POINTER_RESET_PLAN" || \
   ! grep -Fq "Verification: Completed" "$ROOT_DIR/$IMPORTGL_POINTER_RESET_PLAN" || \
   ! grep -Fq "Eight focused hostile mutations" "$ROOT_DIR/$IMPORTGL_POINTER_RESET_PLAN" || \
   ! grep -Fq "sha256sum -c libs/SHA256SUMS" "$ROOT_DIR/$IMPORTGL_POINTER_RESET_PLAN"; then
  printf '%s\n' "ImportGL function-pointer reset plan must record completed verification." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/$IMPORTGL_INIT_FAILURE_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$ROOT_DIR/$IMPORTGL_INIT_FAILURE_PLAN" || \
   ! grep -Fq "make check" "$ROOT_DIR/$IMPORTGL_INIT_FAILURE_PLAN" || \
   ! grep -Fq "hostile mutations" "$ROOT_DIR/$IMPORTGL_INIT_FAILURE_PLAN"; then
  printf '%s\n' "ImportGL initialization failure plan must record completed verification." >&2
  exit 1
fi

for init_cleanup_doc in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq "partial symbol imports self-clean before failure returns" "$ROOT_DIR/$init_cleanup_doc"; then
    printf '%s\n' "$init_cleanup_doc must document ImportGL initialization cleanup." >&2
    exit 1
  fi
done

for importgl_doc in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! tr '\n' ' ' < "$ROOT_DIR/$importgl_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "portable GL loader cleanup"; then
    printf '%s\n' "$importgl_doc must document portable GL loader cleanup." >&2
    exit 1
  fi
  if ! tr '\n' ' ' < "$ROOT_DIR/$importgl_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "imported GL function pointers"; then
    printf '%s\n' "$importgl_doc must document imported GL function pointers." >&2
    exit 1
  fi
done
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

APP_INIT=$(awk '/^void appInit\(\)/,/^}/' "$ROOT_DIR/jni/demo.c")
if printf '%s\n' "$APP_INIT" | grep -Eq 'assert\(s(SuperShapeObjects\[a\]|GroundPlane) != NULL\)'; then
  printf '%s\n' "Native demo initialization must not abort on allocation failure." >&2
  exit 1
fi
SUPER_SHAPE_FAILURE=$(printf '%s\n' "$APP_INIT" | awk '/if \(sSuperShapeObjects\[a\] == NULL\)/,/^        }/')
GROUND_PLANE_FAILURE=$(printf '%s\n' "$APP_INIT" | awk '/if \(sGroundPlane == NULL\)/,/^    }/')
for allocation_failure in "$SUPER_SHAPE_FAILURE" "$GROUND_PLANE_FAILURE"; do
  for allocation_contract in \
    "gAppAlive = 0;" \
    "appDeinit();" \
    "return;"; do
    if ! printf '%s\n' "$allocation_failure" | grep -Fq "$allocation_contract"; then
      printf '%s\n' "Native allocation failure branch is missing: $allocation_contract" >&2
      exit 1
    fi
  done
done

NATIVE_INIT=$(awk '/Java_com_example_SanAngeles_DemoRenderer_nativeInit/,/^}/' "$ROOT_DIR/jni/app-android.c")
NATIVE_ALLOCATION_FAILURE=$(awk '/if \(!gAppAlive\)/,/^    }/' "$ROOT_DIR/jni/app-android.c")
for allocation_failure_contract in \
  "Demo resource initialization failed" \
  "appDeinit();" \
  "importGLDeinit();" \
  "return;"; do
  if ! printf '%s\n' "$NATIVE_ALLOCATION_FAILURE" | grep -Fq "$allocation_failure_contract"; then
    printf '%s\n' "Android JNI allocation failure handling is missing: $allocation_failure_contract" >&2
    exit 1
  fi
done

for native_init_milestone in \
  "gAppAlive = 1;" \
  "appInit();" \
  "if (!gAppAlive)" \
  "sNativeInitialized = 1;"; do
  if [ "$(printf '%s\n' "$NATIVE_INIT" | grep -Fc "$native_init_milestone")" -ne 1 ]; then
    printf '%s\n' "Android JNI initialization must contain exactly one milestone: $native_init_milestone" >&2
    exit 1
  fi
done

native_alive_line=$(printf '%s\n' "$NATIVE_INIT" | grep -nF "gAppAlive = 1;" | cut -d: -f1)
native_app_init_line=$(printf '%s\n' "$NATIVE_INIT" | grep -nF "appInit();" | cut -d: -f1)
native_failure_line=$(printf '%s\n' "$NATIVE_INIT" | grep -nF "if (!gAppAlive)" | cut -d: -f1)
native_ready_line=$(printf '%s\n' "$NATIVE_INIT" | grep -nF "sNativeInitialized = 1;" | cut -d: -f1)
if [ -z "$native_alive_line" ] || [ -z "$native_app_init_line" ] || \
  [ -z "$native_failure_line" ] || [ -z "$native_ready_line" ] || \
  [ "$native_alive_line" -ge "$native_app_init_line" ] || \
  [ "$native_app_init_line" -ge "$native_failure_line" ] || \
  [ "$native_failure_line" -ge "$native_ready_line" ]; then
  printf '%s\n' "Android JNI initialization must check allocation failure before marking native state ready." >&2
  exit 1
fi

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

workflow_paths=$(find "$ROOT_DIR/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print)
if [ "$workflow_paths" != "$CI_WORKFLOW" ]; then
  printf '%s\n' "check.yml must remain the only approved GitHub Actions workflow." >&2
  exit 1
fi

if [ "$(cat "$CI_WORKFLOW")" != "$(expected_ci_workflow)" ]; then
  printf '%s\n' "GitHub Actions check workflow must match the approved SDK-free NDK security baseline." >&2
  exit 1
fi

if [ ! -f "$CODEOWNERS" ] ||
  [ "$(wc -l < "$CODEOWNERS" | tr -d ' ')" -ne 6 ] ||
  ! grep -Fxq '/.github/CODEOWNERS @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/.github/workflows/ @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/Makefile @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/scripts/ @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/jni/ @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/libs/ @garethpaul' "$CODEOWNERS"; then
  printf '%s\n' "CODEOWNERS must protect CI controls, native source, and checked-in libraries." >&2
  exit 1
fi

for make_contract in \
  'override ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' \
  'ANDROID_HOME ?=' \
  'ANDROID_SDK_ROOT ?=' \
  'ANDROID_SDK := $(if $(ANDROID_HOME),$(ANDROID_HOME),$(ANDROID_SDK_ROOT))' \
  'ANDROID_LINT_TOOL ?= $(ANDROID_SDK)/tools/bin/lint' \
  'NDK_BUILD ?= ndk-build'; do
  if ! grep -Fxq "$make_contract" "$ROOT_DIR/Makefile"; then
    printf '%s\n' "Makefile must keep exact contract: $make_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc '$(ROOT)scripts/check-baseline.sh' "$ROOT_DIR/Makefile")" -ne 2 ] || \
   [ "$(grep -Fc '$(ROOT)scripts/check-native-library-elf.sh' "$ROOT_DIR/Makefile")" -ne 1 ] || \
   [ "$(grep -Fc '$(ROOT)scripts/test-native-size-guards.sh' "$ROOT_DIR/Makefile")" -ne 1 ]; then
  printf '%s\n' "All baseline, ELF, and native-size commands must use the protected root." >&2
  exit 1
fi

if [ "$(grep -Fc 'cd $(ROOT) && ANDROID_HOME="$(ANDROID_SDK)" ANDROID_SDK_ROOT="$(ANDROID_SDK)" "$(ANDROID_LINT_TOOL)" --exitcode .; \' "$ROOT_DIR/Makefile")" -ne 1 ]; then
  printf '%s\n' "Legacy Android lint must preserve its complete rooted command." >&2
  exit 1
fi

if [ "$(grep -Fc 'cd $(ROOT) && "$(NDK_BUILD)"; \' "$ROOT_DIR/Makefile")" -ne 1 ]; then
  printf '%s\n' "Legacy NDK build must preserve its complete rooted command." >&2
  exit 1
fi

if ! grep -Fxq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-14-android-ndk-make-root-override-protection.md"; then
  printf '%s\n' "Android NDK Make root protection plan must record completed status." >&2
  exit 1
fi

if grep -Fq "/home/gjones" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must not embed a maintainer-specific Android SDK path." >&2
  exit 1
fi
if grep -Fq "/home/gjones" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must not embed a maintainer-specific Android SDK path." >&2
  exit 1
fi
require_contains "$CHECKSUM_PATH_PLAN" "status: completed" "Checksum path hygiene plan must be completed."
require_contains "$CI_PLAN" "status: completed" "CI baseline plan must be completed."
require_contains "$CI_PLAN" "make check" "CI baseline plan must document make check verification."
require_contains "$ALLOCATION_FAILURE_PLAN" "Status: Completed" "NDK allocation failure recovery plan must be completed."
require_contains "$ALLOCATION_FAILURE_PLAN" "make check" "NDK allocation failure recovery plan must document make check verification."
require_contains "$SIZE_OVERFLOW_PLAN" "Status: Completed" "Native size overflow plan must record completed status."
require_contains "$SIZE_OVERFLOW_PLAN" "CodeQL alert 1" "Native size overflow plan must identify the source alert."
require_contains "$SIZE_OVERFLOW_PLAN" "fresh external clone" "Native size overflow plan must require fresh-clone verification."
require_contains "$SIZE_OVERFLOW_PLAN" "passed under GCC and Clang" "Native size overflow plan must record compiler verification."
require_contains "$SIZE_OVERFLOW_PLAN" "All 29 focused arithmetic" "Native size overflow plan must record mutation evidence."
require_contains "$SIZE_OVERFLOW_PLAN" "b04efd9ab28df9005adb82e5b76ebb64f7f62e9b" "Native size overflow plan must record the verified implementation SHA."
require_contains "$SIZE_OVERFLOW_PLAN" 'pull-request baseline run `27403851128` and CodeQL run `27403850106`' "Native size overflow plan must record exact hosted run evidence."
require_contains "$SIZE_OVERFLOW_PLAN" "zero open code-scanning alerts" "Native size overflow plan must record the PR-ref alert result."

require_contains "jni/checked-size.h" "left > LONG_MAX / right" "Checked product helper must reject signed long overflow before multiplication."
require_contains "jni/checked-size.h" "(unsigned long)count > (unsigned long)((size_t)-1)" "Checked allocation helper must reject counts wider than size_t."
require_contains "jni/checked-size.h" "elementCount > (size_t)-1 / (size_t)components" "Checked allocation helper must reject component-count overflow."
require_contains "jni/checked-size.h" "elementCount > (size_t)-1 / componentSize" "Checked allocation helper must reject byte-size overflow."
require_contains "jni/demo.c" "checkedPositiveLongProduct((long)longitudeCount" "Supershape counts must use checked long products."
require_contains "jni/demo.c" '#include "checked-size.h"' "Native geometry must include the checked-size helper."
require_contains "jni/demo.c" "checkedPositiveLongProduct((long)(yEnd - yBegin)" "Ground-plane counts must use checked long products."
require_contains "jni/demo.c" "checkedArrayByteSize(vertices, vertexComponents" "Vertex allocation must use checked byte counts."
require_contains "jni/demo.c" "checkedArrayByteSize(vertices, 4, sizeof(GLubyte), &colorBytes)" "Color allocation must use checked byte counts."
require_contains "jni/demo.c" "checkedArrayByteSize(vertices, 3, sizeof(GLfixed), &normalBytes)" "Normal allocation must use checked byte counts."
require_contains "jni/demo.c" "vertices > INT_MAX" "OpenGL draw counts must reject values outside the int boundary."
if grep -Eq 'const long triangleCount = longitudeCount \* latitudeCount' "$ROOT_DIR/jni/demo.c"; then
  printf '%s\n' "Supershape counts must not multiply ints before widening." >&2
  exit 1
fi
require_contains "Makefile" '$(ROOT)scripts/test-native-size-guards.sh' "Makefile test target must run native size boundary tests."
if [ ! -x "$ROOT_DIR/scripts/test-native-size-guards.sh" ]; then
  printf '%s\n' "Native size boundary test runner must be executable." >&2
  exit 1
fi
require_contains "scripts/test-native-size-guards.sh" '"$CC" -std=c89 -pedantic -Wall -Wextra -Werror' "Native size tests must compile under strict C89 warnings-as-errors."
require_contains "scripts/test-native-size-guards.c" "signed long overflow rejected" "Native size tests must cover signed product overflow."
require_contains "scripts/test-native-size-guards.c" "maximum signed long product accepted" "Native size tests must cover the valid signed product boundary."
require_contains "scripts/test-native-size-guards.c" "allocation byte overflow rejected" "Native size tests must cover allocation byte overflow."
require_contains "scripts/test-native-size-guards.c" "maximum allocation byte count accepted" "Native size tests must cover the valid allocation boundary."
require_contains "README.md" "allocation byte counts use checked products" "README must document native size overflow guards."
require_contains "CHANGES.md" "allocation-size products against signed" "CHANGES must record native size overflow guards."

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

if ! grep -Fq "Native allocation failures release partial demo objects" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document native allocation failure recovery." >&2
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
