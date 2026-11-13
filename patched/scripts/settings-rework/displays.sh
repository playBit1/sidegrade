#!/usr/bin/env bash
# Used by Settings > Displays (ii Settings Rework). Display settings live in
# ~/.config/hypr/monitors.lua, which end-4's hyprland.lua loads when it exists.
#
#   state                  print what Hyprland reports, then what monitors.lua holds
#   apply <seconds> <lua>  write monitors.lua and reload; unless "keep" follows, the previous
#                          file comes back by itself (so a mode the screen cannot show, or a
#                          closed Settings window, never leaves you stuck)
#   keep                   keep what "apply" wrote
#   revert                 undo "apply" now
set -u
file="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/monitors.lua"
run="${XDG_RUNTIME_DIR:-/tmp}/ii-displays-$(id -u)"
mkdir -p "$run" && chmod 700 "$run" || exit 1

restore() {
    [ -f "$run/pending" ] || return 0
    if [ -f "$run/backup" ]; then
        cp "$run/backup" "$file.tmp" && mv "$file.tmp" "$file"
    else
        rm -f "$file"
    fi
    rm -f "$run/pending" "$run/backup"
    hyprctl reload >/dev/null
}

case "${1:-}" in
    state)
        hyprctl monitors all -j
        printf '\n@@monitors.lua@@\n'
        cat "$file" 2>/dev/null
        ;;
    apply)
        seconds="${2:-}" content="${3:-}"
        case "$seconds" in ''|*[!0-9]*) echo "apply needs a number of seconds" >&2; exit 1 ;; esac
        [ -n "$content" ] || { echo "apply needs the file content" >&2; exit 1; }
        if [ ! -f "$run/pending" ]; then # otherwise keep the backup of the last settings that were kept
            rm -f "$run/backup"
            [ -f "$file" ] && cp "$file" "$run/backup"
        fi
        token="$$-$RANDOM"
        printf '%s\n' "$token" > "$run/pending"
        printf '%s' "$content" > "$file.tmp" && mv "$file.tmp" "$file" || exit 1
        hyprctl reload >/dev/null
        setsid bash "$0" watchdog "$seconds" "$token" >/dev/null 2>&1 </dev/null &
        ;;
    watchdog)
        sleep "$2"
        [ "$(cat "$run/pending" 2>/dev/null)" = "$3" ] && restore
        ;;
    keep)
        rm -f "$run/pending" "$run/backup"
        ;;
    revert)
        restore
        ;;
    *)
        echo "usage: displays.sh state | apply <seconds> <lua> | keep | revert" >&2
        exit 1
        ;;
esac
