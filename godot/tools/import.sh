#!/bin/bash
# Kilitli yeniden içe aktarma (çeviri CSV'si, yeni class_name, yeni görseller). Eşzamanlı çağrılar sıraya girer.
cd "$(dirname "$0")/.."
lock=.godot/import.lock
for i in $(seq 1 240); do mkdir "$lock" 2>/dev/null && break; sleep 0.5; done
trap 'rmdir "$lock" 2>/dev/null' EXIT
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import 2>&1 | grep -E "ERROR|SCRIPT ERROR|Parse Error" | grep -v "^\s*$" | head -30
exit 0
