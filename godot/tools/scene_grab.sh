#!/bin/sh
# Opak dikey sahne (1024x1536): son 6 ekran görüntüsü (2x3 karo, 512 px, satır satır) → art/scene/<ad>.jpg
set -e
cd "$(dirname "$0")/.."
mkdir -p art/scene
OPAQUE=1 tools/grab.sh "art/raw/scene_$1.png" 2 3 512 512 >/dev/null
"$HOME/jellybusters/.venv/bin/python" -c "
from PIL import Image
Image.open('art/raw/scene_$1.png').convert('RGB').save('art/scene/$1.jpg', quality=90)"
echo "art/scene/$1.jpg"
