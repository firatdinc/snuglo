#!/bin/bash
# Kullanım: capture.sh <dil> [sahne...]  → raw/<dil>/<sahne>.png (686x1486)
L=$1; shift
G=~/snuglo/godot; OUT=$(cd "$(dirname "$0")" && pwd)/raw/$L; mkdir -p "$OUT"
COMMON="SNUG_RES=686x1486 SNUG_DEMO=30 SNUG_NOPOPUP=1 SNUG_NOTCH=0 SNUG_LANG=$L"
scene() {
  case $1 in
    s1) echo "6 SNUG_SCREEN=game:woodland-retreat-30 SNUG_AUTO=5";;
    s2) echo "6 SNUG_SCREEN=game:endless-12 SNUG_AUTO=3";;
    s3) echo "5 SNUG_SCREEN=achievements SNUG_DEMO=300";;
    s4) echo "6 SNUG_SCREEN=chest SNUG_CHEST_TIER=legendary SNUG_AUTOOPEN=1";;
    s5) echo "5 SNUG_SCREEN=menu";;
    s6) echo "5 SNUG_SCREEN=daily";;
    s7) echo "5 SNUG_SCREEN=nook_reveal";;
    s8) echo "5 SNUG_SCREEN=map SNUG_DEMO=700 SNUG_SCROLL=600";;
  esac
}
for s in ${@:-s1 s2 s3 s4 s5 s6 s7 s8}; do
  set -- $(scene $s); t=$1; shift
  $G/tools/shot.sh "$OUT/$s.png" $t $COMMON "$@" >/dev/null 2>&1
done
