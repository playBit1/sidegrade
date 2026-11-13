#!/usr/bin/env bash
# Copies the current wallpaper (blurred) and shell colours to where the ii Login SDDM
# theme reads them. Runs as your user; a systemd path unit calls it when the colours change.
#   sync.sh [state-dir]      default state dir: /var/lib/ii-login
set -euo pipefail
state="${1:-/var/lib/ii-login}"
config="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
colors="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/colors.json"

[ -d "$state" ] && [ -w "$state" ] || { echo "ii-login: $state is missing or not writable; run install.sh first" >&2; exit 1; }
[ -f "$config" ] && [ -f "$colors" ] || { echo "ii-login: shell config or colours not found" >&2; exit 1; }

# theme.conf.user: colours, fonts, clock options. Written to a temp file and moved into
# place so SDDM never reads a half-written file.
tmp="$(mktemp "$state/.theme.conf.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
python3 - "$config" "$colors" "$state" > "$tmp" <<'PY'
import json, sys
config = json.load(open(sys.argv[1]))
colors = json.load(open(sys.argv[2]))
state = sys.argv[3]

def get(path, default):
    node = config
    for key in path.split("."):
        if not isinstance(node, dict) or key not in node:
            return default
        node = node[key]
    return node

def clean(value):  # one line, no characters that would break out of a quoted INI value
    return str(value).replace("\\", "").replace('"', "'").replace("\n", " ").replace("\r", " ").strip()

clock = "background.widgets.clock"
out = {
    "background": f"{state}/background.jpg",
    "blurZoom": get("lock.blur.extraZoom", 1.1) if get("lock.blur.enable", True) else 1,
    "fontMain": get("appearance.fonts.main", "Google Sans Flex"),
    "fontExpressive": get("appearance.fonts.expressive", "Space Grotesk"),
    "fontReading": get("appearance.fonts.reading", "Readex Pro"),
    "timeFormat": get("time.format", "hh:mm"),
    "dateFormat": get("time.dateFormat", "ddd, dd/MM"),
    "cookieSides": get(f"{clock}.cookie.sides", 14),
    "quote": get(f"{clock}.quote.text", "") if get(f"{clock}.quote.enable", False) else "",
    "showDate": "true",
}
for ours, theirs in {
    "background_color": "background", "surface_container": "surface_container",
    "surface_container_low": "surface_container_low", "surface_container_high": "surface_container_high",
    "on_surface": "on_surface", "on_surface_variant": "on_surface_variant", "outline": "outline",
    "primary": "primary", "on_primary": "on_primary", "primary_container": "primary_container",
    "secondary": "secondary", "secondary_container": "secondary_container",
    "on_secondary_container": "on_secondary_container", "tertiary": "tertiary",
    "tertiary_container": "tertiary_container", "on_tertiary_container": "on_tertiary_container",
    "error": "error",
}.items():
    if theirs in colors:
        out[ours] = colors[theirs]

print("[General]")
for key, value in out.items():
    print(f'{key}="{clean(value)}"')
PY
chmod 644 "$tmp"
mv -f "$tmp" "$state/theme.conf.user"
trap - EXIT

# background.jpg: the wallpaper at half resolution with the lockscreen's blur baked in,
# so the login screen needs no shaders.
wallpaper="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("background",{}).get("wallpaperPath",""))' "$config")"
radius="$(python3 -c 'import json,sys; l=json.load(open(sys.argv[1])).get("lock",{}).get("blur",{}); print(l.get("radius",100) if l.get("enable",True) else 0)' "$config")"
sigma="$(python3 -c 'import sys; print(round((float(sys.argv[1]) + 1) / 3.3333 / 2, 2))' "$radius")"
case "${wallpaper,,}" in
    *.jpg|*.jpeg|*.png|*.webp|*.avif|*.bmp)
        if [ -f "$wallpaper" ]; then
            magick "${wallpaper}[0]" -auto-orient -resize '1280x720^' -blur "0x$sigma" -strip -quality 88 "$state/.background.jpg"
            chmod 644 "$state/.background.jpg"
            mv -f "$state/.background.jpg" "$state/background.jpg"
        fi ;;
    *)  echo "ii-login: wallpaper is not a still image; keeping the previous background" >&2 ;;
esac
