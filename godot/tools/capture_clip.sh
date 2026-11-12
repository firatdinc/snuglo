#!/bin/bash
# Reklam için sesli oynanış kaydı; ekranı ele geçirmez, hoparlörden ses vermez.
# Kullanım: tools/capture_clip.sh <çıktı.mp4> <saniye> [ENV=değer ...]
# Örnek:    tools/capture_clip.sh out.mp4 8 SNUG_DEMO=40 SNUG_LEVEL=cozy-beginnings:3 SNUG_PLAY=2 SNUG_PLAY_MISS=1
# Dev.gd kancaları yalnız debug yapıda çalışır. Geçici AVI silinir, kayıt ayrı dosyaya gider.
# CAPTURE_RES=1080x1920 çözünürlüğü değiştirir.
set -u
[ $# -ge 2 ] || { sed -n 2,6p "$0"; exit 2; }
out=$1; secs=$2; shift 2
case $out in /*) ;; *) out="$PWD/$out";; esac
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RES=${CAPTURE_RES:-1080x1920}
TMP="$(mktemp -d)"
OVERRIDE="$ROOT/override.cfg"
[ -e "$OVERRIDE" ] && { echo "override.cfg zaten var, dur"; exit 1; }
trap 'rm -rf "$TMP" "$OVERRIDE"' EXIT
# Movie Maker --resolution'ı yok sayar; proje dosyasına dokunmadan boyutu çekim süresince değiştirir.
printf '[display]\nwindow/size/window_width_override=%s\nwindow/size/window_height_override=%s\n' "${RES%x*}" "${RES#*x}" > "$OVERRIDE"
frames=$(awk "BEGIN{print int($secs*30)}")

envs=(--env "SNUG_SAVE=$TMP/save.json" --env SNUG_NOTCH=0 --env SNUG_NOPOPUP=1)
for a in "$@"; do envs+=(--env "$a"); done

# open -g: odak çalmaz. Pencere ekran dışında; Movie Maker gizli pencerede de render eder ve sesi dosyaya yazar.
open -g -n -W -a /Applications/Godot.app "${envs[@]}" --args \
  --path "$ROOT" --resolution "$RES" --position -4000,-4000 \
  --write-movie "$TMP/raw.avi" --fixed-fps 30 --quit-after "$frames" \
  --log-file "$TMP/log.txt" &
pid=$!
limit=$(( frames / 5 + 120 ))
for _ in $(seq 1 "$limit"); do sleep 1; kill -0 "$pid" 2>/dev/null || break; done
if kill -0 "$pid" 2>/dev/null; then
  pkill -f -- "--log-file $TMP/log.txt"; echo "ZAMAN AŞIMI"; exit 1
fi
[ -s "$TMP/raw.avi" ] || { echo "KAYIT YOK"; tail -20 "$TMP/log.txt" 2>/dev/null; exit 1; }

ffmpeg -y -v error -i "$TMP/raw.avi" -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -crf 17 -preset medium -pix_fmt yuv420p \
  -c:a aac -b:a 192k -movflags +faststart "$out" || exit 1
grep -E "SCRIPT ERROR|^ERROR" "$TMP/log.txt" | head -5
ffprobe -v error -show_entries stream=codec_type,width,height,r_frame_rate:format=duration,size -of compact "$out"
