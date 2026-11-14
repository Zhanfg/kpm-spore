#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUT=${1:-"$ROOT/dist/bbr3-pjz110-kpm"}
JOBS=${BBR3_KPM_JOBS:-$(nproc)}

ONEPLUS_REPO=https://github.com/OnePlusOSS/android_kernel_common_oneplus_sm8750.git
ONEPLUS_REV=e1b346b6b4f4096eb342ae3684838a942fd6f6c4
BBR_REPO=https://github.com/hrimfaxi/tcp_bbr_modules.git
BBR_REV=c5c557584175b5fed8939bf91ec249aed158597d

WORK=$(mktemp -d)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

KERNEL="$WORK/kernel"
BBR="$WORK/bbr"
CORE="$WORK/core"

git init -q "$KERNEL"
git -C "$KERNEL" remote add origin "$ONEPLUS_REPO"
git -C "$KERNEL" fetch -q --depth=1 origin "$ONEPLUS_REV"
git -C "$KERNEL" checkout -q --detach FETCH_HEAD

git init -q "$BBR"
git -C "$BBR" remote add origin "$BBR_REPO"
git -C "$BBR" fetch -q --depth=1 origin "$BBR_REV"
git -C "$BBR" checkout -q --detach FETCH_HEAD

test "$(git -C "$KERNEL" rev-parse HEAD)" = "$ONEPLUS_REV"
test "$(git -C "$BBR" rev-parse HEAD)" = "$BBR_REV"

KBUILD=(ARCH=arm64 LLVM=-18 LLVM_IAS=1)
make -C "$KERNEL" "${KBUILD[@]}" gki_defconfig
"$KERNEL/scripts/config" --file "$KERNEL/.config" --disable LOCALVERSION_AUTO
"$KERNEL/scripts/config" --file "$KERNEL/.config" --enable MODULES
"$KERNEL/scripts/config" --file "$KERNEL/.config" --enable CFI_CLANG
"$KERNEL/scripts/config" --file "$KERNEL/.config" --enable TCP_CONG_ADVANCED
"$KERNEL/scripts/config" --file "$KERNEL/.config" --enable TCP_CONG_BBR
make -C "$KERNEL" "${KBUILD[@]}" olddefconfig
make -C "$KERNEL" -j"$JOBS" "${KBUILD[@]}" modules_prepare

mkdir -p "$CORE"
cp "$BBR/bbr_compat.h" "$CORE/"
cp "$ROOT/modules/bbr3_pjz110/kernel_config.h" "$CORE/"
python3 "$ROOT/scripts/patch-bbr3-pjz110-kpm.py" \
  "$BBR/tcp_bbr3.c" "$CORE/bbr3_pjz110_kpm.c"

cat > "$CORE/Makefile" <<'EOF'
obj-m := bbr3_pjz110_kpm.o
ccflags-y += -I$(src)
EOF

# Build only the relocatable object. KPM is not a Linux .ko and must not pass
# through modpost/module signing. Keep Kbuild's arm64/KCFI ABI flags.
make -C "$KERNEL" -j"$JOBS" "${KBUILD[@]}" \
  KCFLAGS="-fno-stack-protector" \
  M="$CORE" bbr3_pjz110_kpm.o

OBJ="$CORE/bbr3_pjz110_kpm.o"
test -s "$OBJ"

NM=$(command -v llvm-nm-18 || command -v llvm-nm)
READELF=$(command -v llvm-readelf-18 || command -v llvm-readelf)
STRIP=$(command -v llvm-strip-18 || command -v llvm-strip)
test -n "$NM" -a -n "$READELF" -a -n "$STRIP"

mapfile -t UNDEF < <("$NM" -u "$OBJ" | awk '{print $NF}' | sort -u)
printf '%s\n' "${UNDEF[@]}" > "$WORK/undefined.txt"

# KernelPatch-export allow-list. Anything else means a kernel dependency leaked
# past the runtime bridge and the KPM must not ship.
ALLOW_RE='^(kallsyms_lookup_name|compat_copy_to_user|memset|memcpy|memmove|memcmp|strlen|strncmp|strcmp|strstr|snprintf|vsnprintf)$'
BAD=0
for sym in "${UNDEF[@]}"; do
  [ -z "$sym" ] && continue
  if ! [[ "$sym" =~ $ALLOW_RE ]]; then
    echo "unsafe unresolved symbol: $sym" >&2
    BAD=1
  fi
done
[ "$BAD" -eq 0 ]

rm -rf "$OUT"
mkdir -p "$OUT"
cp "$OBJ" "$OUT/bbr3_pjz110.kpm"
"$STRIP" --strip-debug "$OUT/bbr3_pjz110.kpm"

"$READELF" -h "$OUT/bbr3_pjz110.kpm" | grep -F 'AArch64'
for sec in .kpm.info .kpm.init .kpm.ctl0 .kpm.exit; do
  "$READELF" -S "$OUT/bbr3_pjz110.kpm" | grep -F "$sec" >/dev/null
done

strings "$OUT/bbr3_pjz110.kpm" | grep -qx 'bbr3'
strings "$OUT/bbr3_pjz110.kpm" | grep -q 'kpm-bbr3-pjz110'

cp "$WORK/undefined.txt" "$OUT/undefined-symbols.txt"
cat > "$OUT/manifest.txt" <<EOF
name=kpm-bbr3-pjz110
version=1.0.0-alpha1
device=PJZ110
arch=arm64
kernel_family=6.6-android15
oneplus_source=$ONEPLUS_REV
bbr3_source=$BBR_REV
lifecycle=reboot-only
EOF

(
  cd "$OUT"
  sha256sum bbr3_pjz110.kpm > SHA256SUMS
)

echo "Built: $OUT/bbr3_pjz110.kpm"
cat "$OUT/manifest.txt"
