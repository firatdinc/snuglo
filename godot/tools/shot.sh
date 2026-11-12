#!/bin/bash
# Kullanım: tools/shot.sh <çıktı.png> <saniye> [ENV=değer ...]
# Oyunu pencereli açar, <saniye> sonra ekran görüntüsü alıp kapanır.
# SNUG_RES=590x1278 → pencere çözünürlüğü (uzun telefon oranı); yoksa project.godot (450x975).
# Kayıt varsayılan olarak ayrı geçici dosyaya gider (SNUG_SAVE ile değiştir; SNUG_KEEP=1 silme).
out=$1; t=$2; shift 2
cd "$(dirname "$0")/.."
res=""
for a in "$@"; do case $a in SNUG_RES=*) res="--resolution ${a#SNUG_RES=}";; SNUG_SAVE=*) save=${a#SNUG_SAVE=};; esac; done
[ -n "$SNUG_RES" ] && res="--resolution $SNUG_RES"
save=${save:-${SNUG_SAVE:-${TMPDIR:-/tmp}/snuglo_shot_save_$$.json}}
[ -z "$SNUG_KEEP" ] && rm -f "$save"
env SNUG_MUTE=1 SNUG_SAVE="$save" SNUG_SHOT="$t:$out" "$@" /Applications/Godot.app/Contents/MacOS/Godot --path . $res 2>&1 &
pid=$!
( sleep $(( ${t%.*} + 15 )); kill $pid 2>/dev/null ) &
wait $pid
[ -z "$SNUG_KEEP" ] && rm -f "$save" "$save.tmp"
exit 0
