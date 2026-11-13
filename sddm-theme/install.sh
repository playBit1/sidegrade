#!/usr/bin/env bash
# ii Login - installer for the SDDM theme that matches the illogical-impulse lockscreen.
#
#   bash install.sh                  install (asks for your sudo password once)
#   bash install.sh --rotate left    same, and turn a portrait monitor at the login screen
#                                    (left, right or inverted; see below)
#   bash install.sh --uninstall      remove everything and go back to the previous login screen
#
# --rotate is for a setup with a main monitor on DisplayPort and a rotated second monitor on
# HDMI: SDDM does not know about the rotation you set in Hyprland, so the installer adds a
# small script that rotates the HDMI output and puts it to the right of the main one. If it
# comes up upside down, run the installer again with the other direction.
#
# Run it as yourself, not with sudo. What needs root is done through sudo by this script:
#   /usr/share/sddm/themes/ii-login   the theme (root-owned)
#   /usr/local/lib/ii-login/          sync script and monitor layout script (root-owned)
#   /var/lib/ii-login/                wallpaper + colours the theme reads (owned by you)
#   /etc/sddm.conf.d/10-ii-login.conf selects the theme
# and for your user: a systemd path unit that re-syncs when the shell's colours change.
#
# If the login screen ever misbehaves: press Ctrl+Alt+F3, log in, and run
#   sudo rm /etc/sddm.conf.d/10-ii-login.conf && sudo systemctl restart sddm
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
theme_dir=/usr/share/sddm/themes/ii-login
lib_dir=/usr/local/lib/ii-login
state_dir=/var/lib/ii-login
conf=/etc/sddm.conf.d/10-ii-login.conf
unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

# ---------------------------------------------------------------- root steps
# Called as: sudo install.sh --root-install <user> <rotate> | --root-uninstall
# ROOT_PREFIX is for testing only: it redirects every path and skips ownership changes.
root_install() {
    local user="$1" rotate="$2" p="${ROOT_PREFIX:-}"
    [[ "$user" =~ ^[a-z_][a-z0-9_-]*$ ]] && id "$user" >/dev/null 2>&1 || { echo "Unknown user: $user" >&2; exit 1; }
    case "$rotate" in left|right|inverted|none) ;; *) echo "Bad rotation: $rotate" >&2; exit 1 ;; esac
    local home font
    home="$(getent passwd "$user" | cut -d: -f6)"

    # Theme: plain copies, root-owned, world-readable
    rm -rf "$p$theme_dir"
    install -d -m 755 "$p$theme_dir" "$p$theme_dir/fonts" "$p$lib_dir"
    install -m 644 "$here"/theme/*.qml "$here/theme/metadata.desktop" "$here/theme/theme.conf" "$p$theme_dir/"
    for font in "$home"/.local/share/fonts/illogical-impulse-google-sans-flex/GoogleSansFlex-*.ttf; do
        # Read as the user, so root never follows a path inside a home folder
        if [ -n "$p" ]; then cat "$font"; else runuser -u "$user" -- cat "$font"; fi > "$p$theme_dir/fonts/GoogleSansFlex.ttf" || true
        chmod 644 "$p$theme_dir/fonts/GoogleSansFlex.ttf"
        break
    done
    install -m 755 "$here/sync.sh" "$p$lib_dir/sync"

    # The only place your user can write: values and one image, never code
    install -d -m 755 "$p$state_dir"
    [ -n "$p" ] || chown "$user": "$state_dir"
    ln -sfn "$state_dir/theme.conf.user" "$p$theme_dir/theme.conf.user"

    # Monitor layout for the X11 greeter. Fixed content, reads nothing from any home folder.
    install -d -m 755 "$p$(dirname "$conf")"
    {
        echo "# Written by ii Login's install.sh. Delete this file to go back to the default login screen."
        echo "[Theme]"
        echo "Current=ii-login"
    } > "$p$conf"
    if [ "$rotate" != none ]; then
        cat > "$p$lib_dir/xsetup" <<XSETUP
#!/bin/sh
# Run by SDDM as root before the login screen appears (ii Login).
# Main monitor: first connected DisplayPort output. Rotated monitor: first connected HDMI output.
[ -x /usr/share/sddm/scripts/Xsetup ] && /usr/share/sddm/scripts/Xsetup
outputs="\$(/usr/bin/xrandr --query 2>/dev/null | /usr/bin/awk '\$2 == "connected" { print \$1 }')"
main="\$(echo "\$outputs" | /usr/bin/grep -m1 '^DP')"
side="\$(echo "\$outputs" | /usr/bin/grep -m1 '^HDMI')"
[ -n "\$main" ] && [ -n "\$side" ] || exit 0
/usr/bin/xrandr --output "\$main" --primary --auto \\
                --output "\$side" --auto --rotate $rotate --right-of "\$main" || true
XSETUP
        chmod 755 "$p$lib_dir/xsetup"
        printf '\n[X11]\nDisplayCommand=%s\n' "$lib_dir/xsetup" >> "$p$conf"
    else
        rm -f "$p$lib_dir/xsetup"
    fi
    chmod 644 "$p$conf"
}

root_uninstall() {
    local p="${ROOT_PREFIX:-}"
    rm -f "$p$conf"
    rm -rf "$p$theme_dir" "$p$lib_dir" "$p$state_dir"
}

case "${1:-}" in
    --root-install)   root_install "$2" "$3"; exit 0 ;;
    --root-uninstall) root_uninstall; exit 0 ;;
esac

# ---------------------------------------------------------------- user steps
[ "$(id -u)" -ne 0 ] || { echo "Run this as your normal user, not with sudo."; exit 1; }

rotate=none
mode=install
while [ $# -gt 0 ]; do
    case "$1" in
        --rotate)    rotate="${2:?--rotate needs left, right or inverted}"; shift ;;
        --uninstall) mode=uninstall ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

if [ "$mode" = uninstall ]; then
    systemctl --user disable --now ii-login-sync.path 2>/dev/null || true
    rm -f "$unit_dir/ii-login-sync.path" "$unit_dir/ii-login-sync.service"
    systemctl --user daemon-reload
    sudo bash "$here/install.sh" --root-uninstall
    echo "Removed. SDDM will use its previous login screen from the next boot."
    exit 0
fi

tools="sddm magick python3"
[ "$rotate" = none ] || tools="$tools xrandr"
for tool in $tools; do
    command -v "$tool" >/dev/null || { echo "Missing: $tool"; exit 1; }
done

sudo bash "$here/install.sh" --root-install "$USER" "$rotate"

# First sync, then keep it in step with the shell: colours are regenerated whenever the
# wallpaper changes, and config.json holds the quote and clock options.
"$lib_dir/sync"
mkdir -p "$unit_dir"
cat > "$unit_dir/ii-login-sync.service" <<EOF
[Unit]
Description=Copy wallpaper and shell colours to the ii Login SDDM theme

[Service]
Type=oneshot
ExecStart=$lib_dir/sync
EOF
cat > "$unit_dir/ii-login-sync.path" <<EOF
[Unit]
Description=Re-sync the ii Login SDDM theme when the shell's colours or options change

[Path]
PathChanged=%S/quickshell/user/generated/colors.json
PathChanged=%E/illogical-impulse/config.json

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now ii-login-sync.path

echo
echo "Installed. The new login screen appears at the next boot (or after: sudo systemctl restart sddm,"
echo "which ends your current session)."
[ "$rotate" = none ] || echo "Rotated monitor upside down at login?   run again with the other --rotate direction"
echo "Back to the old login screen:           bash $here/install.sh --uninstall"
