#!/bin/sh
# Son 2*TX*TY Chrome ekran görüntüsünden (karo karo; her karo önce beyaz sonra siyah zemin)
# alfalı tam görsel kurar. Kullanım: tools/grab.sh <çıktı.png> [TX TY CW CH]   (varsayılan 2 2 627 627)
set -e
cd "$(dirname "$0")/.."
P="$HOME/jellybusters/.venv/bin/python"
T=$(ls -td /var/folders/*/*/T/claude-chrome-screenshots-* | head -1)
OUT=$1; TX=${2:-2}; TY=${3:-2}; CW=${4:-627}; CH=${5:-627}
# OPAQUE=1: karo başına tek (beyaz) görüntü; matte'e aynı dosya iki kez verilir.
if [ -n "$OPAQUE" ]; then N=$((TX * TY)); else N=$((TX * TY * 2)); fi
FILES=$(ls "$T"/screenshot-* | awk -F- '{print $NF, $0}' | sort -n | tail -$N | cut -d" " -f2)
if [ -n "$OPAQUE" ]; then FILES=$(for f in $FILES; do echo "$f $f"; done); fi
"$P" tools/capture_import.py "$OUT" $TX $TY $CW $CH $FILES
