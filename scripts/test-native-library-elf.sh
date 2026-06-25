#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/android-ndksample-elf-contract.XXXXXX")
trap 'rm -rf "$TMP_DIR"' 0 HUP INT TERM

mkdir -p "$TMP_DIR/repo/scripts" "$TMP_DIR/repo/libs"
cp "$ROOT_DIR/scripts/check-native-library-elf.sh" "$TMP_DIR/repo/scripts/"
for abi in arm64-v8a armeabi-v7a armeabi mips64 mips x86_64 x86; do
  mkdir -p "$TMP_DIR/repo/libs/$abi"
  : > "$TMP_DIR/repo/libs/$abi/libsanangeles.so"
done

cat > "$TMP_DIR/fake-readelf" <<'EOF'
#!/usr/bin/env sh
set -eu

operation=$1
library=${3:-}
abi=$(basename "$(dirname "$library")")

case "$abi" in
  arm64-v8a) class=ELF64; machine=AArch64 ;;
  armeabi-v7a|armeabi) class=ELF32; machine=ARM ;;
  mips64) class=ELF64; machine='MIPS R3000' ;;
  mips) class=ELF32; machine='MIPS R3000' ;;
  x86_64) class=ELF64; machine='Advanced Micro Devices X86-64' ;;
  x86) class=ELF32; machine='Intel 80386' ;;
  *) exit 2 ;;
esac

case "$operation" in
  --file-header)
    cat <<HEADER
  Class:                             $class
  Data:                              2's complement, little endian
  Type:                              DYN (Shared object file)
  Machine:                           $machine
HEADER
    ;;
  --dynamic)
    for dependency in libGLESv1_CM.so libdl.so liblog.so libstdc++.so libm.so libc.so; do
      printf ' 0x00000001 (NEEDED) Shared library: [%s]\n' "$dependency"
    done
    printf ' 0x0000000e (SONAME) Library soname: [libsanangeles.so]\n'
    if [ "${ELF_TEST_MODE:-valid}" = unexpected-dependency ]; then
      printf ' 0x00000001 (NEEDED) Shared library: [libhostile.so]\n'
    fi
    if [ "${ELF_TEST_MODE:-valid}" = text-relocation ]; then
      printf ' 0x00000016 (TEXTREL) 0x0\n'
    fi
    if [ "${ELF_TEST_MODE:-valid}" = rpath ]; then
      printf ' 0x0000000f (RPATH) Library rpath: [/data/local/tmp]\n'
    fi
    if [ "${ELF_TEST_MODE:-valid}" = runpath ]; then
      printf ' 0x0000001d (RUNPATH) Library runpath: [\$ORIGIN]\n'
    fi
    ;;
  --dyn-syms)
    for symbol in \
      Java_com_example_SanAngeles_DemoGLSurfaceView_nativePause \
      Java_com_example_SanAngeles_DemoGLSurfaceView_nativeResume \
      Java_com_example_SanAngeles_DemoGLSurfaceView_nativeTogglePauseResume \
      Java_com_example_SanAngeles_DemoRenderer_nativeDone \
      Java_com_example_SanAngeles_DemoRenderer_nativeInit \
      Java_com_example_SanAngeles_DemoRenderer_nativeRender \
      Java_com_example_SanAngeles_DemoRenderer_nativeResize; do
      printf '  1: 00000000 0 FUNC GLOBAL DEFAULT 1 %s\n' "$symbol"
    done
    ;;
  --program-headers)
    if [ "${ELF_TEST_MODE:-valid}" = executable-stack ]; then
      printf '  GNU_STACK 0x0 0x0 0x0 0x0 0x0 RWE 0x10\n'
    else
      printf '  GNU_STACK 0x0 0x0 0x0 0x0 0x0 RW 0x10\n'
    fi
    ;;
  *) exit 2 ;;
esac
EOF
chmod +x "$TMP_DIR/fake-readelf" "$TMP_DIR/repo/scripts/check-native-library-elf.sh"

run_checker() {
  ELF_TEST_MODE=$1 READELF="$TMP_DIR/fake-readelf" \
    "$TMP_DIR/repo/scripts/check-native-library-elf.sh" >/dev/null 2>&1
}

run_checker valid
for mode in unexpected-dependency text-relocation executable-stack rpath runpath; do
  if run_checker "$mode"; then
    printf '%s\n' "FAIL: ELF checker accepted $mode" >&2
    exit 1
  fi
done

printf '%s\n' "Native library ELF checker tests passed."
