#!/bin/zsh
# Renders an Open Graph card in the neetoKB style with headless Chrome.
#
#   render.sh "<site name>" "<title>" out.png
#
# Needs Google Chrome and network access for the Inter font.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
KICKER="$1"; TITLE="$2"; OUT="$3"
[ -n "$OUT" ] || { echo "usage: render.sh <site name> <title> <out.png>" >&2; exit 1; }
TMP=$(mktemp -d)
sed -e "s/BAR_HEIGHT/20/g" -e "s/KICKER_SIZE/39/g" -e "s/TITLE_SIZE/66/g" \
    -e "s|KICKER|$KICKER|" -e "s|TITLE|$TITLE|" "$HERE/template.html" > "$TMP/card.html"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu \
  --hide-scrollbars --force-device-scale-factor=1 --window-size=1200,630 \
  --virtual-time-budget=6000 --screenshot="$OUT" "file://$TMP/card.html" 2>/dev/null
rm -rf "$TMP"
echo "wrote $OUT"
