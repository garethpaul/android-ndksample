#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LC_ALL=C
export LC_ALL

if [ -n "${READELF:-}" ]; then
  if ! command -v "$READELF" >/dev/null 2>&1; then
    printf '%s\n' "Configured ELF reader is unavailable: $READELF" >&2
    exit 1
  fi
elif command -v readelf >/dev/null 2>&1; then
  READELF=readelf
elif command -v llvm-readelf >/dev/null 2>&1; then
  READELF=llvm-readelf
else
  printf '%s\n' "readelf or llvm-readelf is required for native library verification." >&2
  exit 1
fi

expected_jni_symbols='Java_com_example_SanAngeles_DemoGLSurfaceView_nativePause
Java_com_example_SanAngeles_DemoGLSurfaceView_nativeResume
Java_com_example_SanAngeles_DemoGLSurfaceView_nativeTogglePauseResume
Java_com_example_SanAngeles_DemoRenderer_nativeDone
Java_com_example_SanAngeles_DemoRenderer_nativeInit
Java_com_example_SanAngeles_DemoRenderer_nativeRender
Java_com_example_SanAngeles_DemoRenderer_nativeResize'
expected_dependencies='libGLESv1_CM.so
libc.so
libdl.so
liblog.so
libm.so
libstdc++.so'

verify_library() {
  abi=$1
  expected_class=$2
  expected_machine=$3
  library="$ROOT_DIR/libs/$abi/libsanangeles.so"

  if [ ! -f "$library" ]; then
    printf '%s\n' "Missing native library for ELF verification: libs/$abi/libsanangeles.so" >&2
    exit 1
  fi

  header=$("$READELF" --file-header --wide "$library")
  actual_class=$(printf '%s\n' "$header" | awk -F: '/^[[:space:]]*Class:/ {sub(/^[[:space:]]*/, "", $2); print $2}')
  actual_data=$(printf '%s\n' "$header" | awk -F: '/^[[:space:]]*Data:/ {sub(/^[[:space:]]*/, "", $2); print $2}')
  actual_type=$(printf '%s\n' "$header" | awk -F: '/^[[:space:]]*Type:/ {sub(/^[[:space:]]*/, "", $2); print $2}')
  actual_machine=$(printf '%s\n' "$header" | awk -F: '/^[[:space:]]*Machine:/ {sub(/^[[:space:]]*/, "", $2); print $2}')

  if [ "$actual_class" != "$expected_class" ]; then
    printf '%s\n' "Unexpected ELF class for $abi: $actual_class" >&2
    exit 1
  fi
  if [ "$actual_data" != "2's complement, little endian" ]; then
    printf '%s\n' "Unexpected ELF data encoding for $abi: $actual_data" >&2
    exit 1
  fi
  if [ "$actual_type" != "DYN (Shared object file)" ]; then
    printf '%s\n' "Unexpected ELF type for $abi: $actual_type" >&2
    exit 1
  fi
  if [ "$actual_machine" != "$expected_machine" ]; then
    printf '%s\n' "Unexpected ELF machine for $abi: $actual_machine" >&2
    exit 1
  fi

  dynamic=$("$READELF" --dynamic --wide "$library")
  if [ "$(printf '%s\n' "$dynamic" | grep -Fc 'Library soname: [libsanangeles.so]' || true)" -ne 1 ]; then
    printf '%s\n' "Native library $abi must declare SONAME libsanangeles.so exactly once." >&2
    exit 1
  fi
  actual_dependencies=$(printf '%s\n' "$dynamic" | sed -n \
    's/.*Shared library: \[\([^]]*\)\].*/\1/p' | sort)
  if [ "$actual_dependencies" != "$expected_dependencies" ]; then
    printf '%s\n' "Unexpected native dependency set for $abi." >&2
    printf '%s\n' "$actual_dependencies" >&2
    exit 1
  fi
  if printf '%s\n' "$dynamic" | grep -Fq TEXTREL; then
    printf '%s\n' "Native library $abi must not require text relocations." >&2
    exit 1
  fi
  if printf '%s\n' "$dynamic" | grep -Eq '\((RPATH|RUNPATH)\)'; then
    printf '%s\n' "Native library $abi must not embed a dynamic library search path." >&2
    exit 1
  fi

  program_headers=$("$READELF" --program-headers --wide "$library")
  stack_flags=$(printf '%s\n' "$program_headers" | \
    awk '$1 == "GNU_STACK" {print $(NF - 1)}')
  if [ "$stack_flags" != "RW" ]; then
    printf '%s\n' "Native library $abi must declare one non-executable GNU stack." >&2
    exit 1
  fi

  symbols=$("$READELF" --dyn-syms --wide "$library")
  invalid_jni_symbols=$(printf '%s\n' "$symbols" | awk \
    '$8 ~ /^Java_com_example_SanAngeles_/ && !($4 == "FUNC" && $5 == "GLOBAL" && $7 != "UND") {print $8}')
  if [ -n "$invalid_jni_symbols" ]; then
    printf '%s\n' "Invalid JNI dynamic exports for $abi." >&2
    printf '%s\n' "$invalid_jni_symbols" >&2
    exit 1
  fi
  actual_jni_symbols=$(printf '%s\n' "$symbols" | awk \
    '$4 == "FUNC" && $5 == "GLOBAL" && $7 != "UND" && $8 ~ /^Java_com_example_SanAngeles_/ {print $8}' | \
    sort)
  if [ "$actual_jni_symbols" != "$expected_jni_symbols" ]; then
    printf '%s\n' "Unexpected JNI dynamic export set for $abi." >&2
    printf '%s\n' "$actual_jni_symbols" >&2
    exit 1
  fi
}

verify_library arm64-v8a ELF64 AArch64
verify_library armeabi-v7a ELF32 ARM
verify_library armeabi ELF32 ARM
verify_library mips64 ELF64 "MIPS R3000"
verify_library mips ELF32 "MIPS R3000"
verify_library x86_64 ELF64 "Advanced Micro Devices X86-64"
verify_library x86 ELF32 "Intel 80386"

printf '%s\n' "Native library ELF contracts passed for seven ABIs."
