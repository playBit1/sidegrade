#!/usr/bin/env bash
# ii Settings Rework - installer for end-4's dots-hyprland (Quickshell "ii" config).
# Usage:  bash install.sh             install (backs up the files it replaces first)
#         bash install.sh --force     install even if your dots version differs from the tested one
#         bash install.sh --uninstall put the backed-up files back and remove the added ones
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${II_DIR:-$HOME/.config/quickshell/ii}"
state="${XDG_DATA_HOME:-$HOME/.local/share}/ii-settings-rework"
backup="$state/backup"
mode="${1:-install}"

if [ ! -f "$target/settings.qml" ]; then
    echo "No illogical-impulse Quickshell config found at $target"
    echo "Install end-4's dots-hyprland first, or set II_DIR to your config folder."
    exit 1
fi

mapfile -t files < <(cd "$here/files" && find . -type f | sed 's|^\./||' | sort)

if [ "$mode" = "--uninstall" ]; then
    if [ ! -d "$backup" ]; then
        echo "Nothing to uninstall: no backup found in $backup"
        exit 1
    fi
    for f in "${files[@]}"; do
        if [ -f "$backup/$f" ]; then
            cp -a "$backup/$f" "$target/$f"
        else
            rm -f "$target/$f"   # a file this mod added
            rmdir -p --ignore-fail-on-non-empty "$(dirname "$target/$f")" 2>/dev/null || true
        fi
    done
    rm -rf "$state"
    echo "Uninstalled. Your original settings app is back. Close and reopen Settings."
    exit 0
fi

# Refuse to overwrite stock files that differ from the version this was built against
changed=()
while read -r sum f; do
    f="${f#./}"
    [ -f "$target/$f" ] || continue
    have="$(sha256sum "$target/$f" | cut -d' ' -f1)"
    if [ "$have" != "$sum" ] && ! cmp -s "$target/$f" "$here/files/$f"; then
        changed+=("$f")
    fi
done < "$here/stock.sha256"

if [ "${#changed[@]}" -gt 0 ] && [ "$mode" != "--force" ]; then
    echo "These files in your config differ from the dots-hyprland version this mod was built for:"
    printf '  %s\n' "${changed[@]}"
    echo "Installing would replace them and may hide newer options or break the settings app."
    echo "Run again with --force to install anyway (a backup is still made)."
    exit 1
fi

# Back up every file that is about to be replaced. Files that already are this mod's
# (a re-install) are skipped, so the backup always holds the latest non-mod version.
saved=0
for f in "${files[@]}"; do
    if [ -f "$target/$f" ] && ! cmp -s "$target/$f" "$here/files/$f"; then
        mkdir -p "$backup/$(dirname "$f")"
        cp -a "$target/$f" "$backup/$f"
        saved=$((saved + 1))
    fi
done
[ "$saved" -gt 0 ] && echo "Backed up $saved of your current files to $backup"
mkdir -p "$backup"

cp -a "$here/files/." "$target/"

# Keep a copy of this package so the mod can be re-applied after a dotfiles update
# (Settings > About > Update dotfiles does that) and uninstalled without the download.
if [ "$here" != "$state/package" ]; then
    rm -rf "$state/package"
    mkdir -p "$state/package"
    cp -a "$here/install.sh" "$here/stock.sha256" "$here/files" "$state/package/"
fi
echo "Installed ${#files[@]} files into $target"
echo "Close and reopen Settings to see it. To undo: bash $state/package/install.sh --uninstall"
