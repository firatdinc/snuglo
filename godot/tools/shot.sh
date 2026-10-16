#!/bin/bash
# Kullanım: tools/shot.sh <çıktı.png> <saniye> [ENV=değer ...]
# Oyunu pencereli açar, <saniye> sonra ekran görüntüsü alıp kapanır.
out=$1; t=$2; shift 2
cd "$(dirname "$0")/.."
env SNUG_MUTE=1 SNUG_SHOT="$t:$out" "$@" /Applications/Godot.app/Contents/MacOS/Godot --path . 2>&1 &
pid=$!
( sleep $(( ${t%.*} + 15 )); kill $pid 2>/dev/null ) &
wait $pid
