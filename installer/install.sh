#!/usr/bin/env bash
# Installer for ii Settings Rework and its add-ons, for end-4's dots-hyprland (Quickshell "ii" config).
# The same script ships in every package; the files beside it say which package it is.
# Usage:  bash install.sh             install (backs up the files it replaces first)
#         bash install.sh --force     install even if your files differ from the version this was built for
#         bash install.sh --uninstall put the backed-up files back and remove the added ones
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${II_DIR:-$HOME/.config/quickshell/ii}"
share="${XDG_DATA_HOME:-$HOME/.local/share}"
name="$(cat "$here/NAME" 2>/dev/null || echo ii-settings-rework)"       # also the name of the state folder
title="$(cat "$here/TITLE" 2>/dev/null || echo "ii Settings Rework")"
requires="$(cat "$here/REQUIRES" 2>/dev/null || true)"                   # set for add-ons: the package they sit on
state="$share/$name"
backup="$state/backup"
mode="${1:-install}"

if [ ! -f "$target/settings.qml" ]; then
    echo "No illogical-impulse Quickshell config found at $target"
    echo "Install end-4's dots-hyprland first, or set II_DIR to your config folder."
    exit 1
fi

mapfile -t files < <(cd "$here/files" && find . -type f | sed 's|^\./||' | sort)

# Add-ons replace files of the package they sit on, so they come off before that package is
# installed or removed, and go back on after an install. Their state folders are "<name>-<add-on>".
addons=()
detach_addons() {
    [ -z "$requires" ] || return 0
    local package copy
    for package in "$share/$name"-*/package; do
        [ -f "$package/install.sh" ] || continue
        if [ "$1" = keep ]; then
            copy="$(mktemp -d)"
            cp -a "$package/." "$copy/"
            addons+=("$copy")
        fi
        bash "$package/install.sh" --uninstall >/dev/null
    done
}
attach_addons() {
    local copy
    for copy in "${addons[@]}"; do
        echo
        bash "$copy/install.sh" || echo "The add-on \"$(cat "$copy/TITLE")\" was taken off and not put back. Download its current version and install it again."
        rm -rf "$copy"
    done
    addons=()
}

if [ "$mode" = "--uninstall" ]; then
    if [ ! -d "$backup" ]; then
        echo "Nothing to uninstall: no backup found in $backup"
        exit 1
    fi
    detach_addons drop
    installed="$state/package/files"
    [ -d "$installed" ] || installed="$here/files"
    for f in "${files[@]}"; do
        # An add-on comes off on its own when the mod is re-applied after a dotfiles update. A file the
        # update has replaced with upstream's new version must then stay, not go back to the old backup.
        # Its own files (even ones edited since) name the mod; upstream's do not.
        if [ -n "$requires" ] && [ -f "$target/$f" ] && ! cmp -s "$target/$f" "$installed/$f" \
            && ! grep -q "ii Settings Rework" "$target/$f"; then
            echo "Left as it is (replaced since $title was installed): $f"
            continue
        fi
        if [ -f "$backup/$f" ]; then
            cp -a "$backup/$f" "$target/$f"
        else
            rm -f "$target/$f"   # a file this package added
            rmdir -p --ignore-fail-on-non-empty "$(dirname "$target/$f")" 2>/dev/null || true
        fi
    done
    rm -rf "$state"
    echo "Uninstalled $title. Close and reopen Settings."
    exit 0
fi

if [ -n "$requires" ] && [ ! -d "$share/$requires/package" ]; then
    echo "$title is an add-on: install ii Settings Rework first, then run this again."
    exit 1
fi

detach_addons keep
trap attach_addons EXIT

# Refuse to overwrite files that differ from the version this was built against
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
    echo "These files in your config differ from the version $title was built for:"
    printf '  %s\n' "${changed[@]}"
    if [ -n "$requires" ]; then
        echo "An add-on has to match both your dots-hyprland version and your ii Settings Rework version."
        echo "Under modules/settings: download the current ii Settings Rework and this add-on together and"
        echo "install them in that order. Elsewhere: a dotfiles update changed a file this add-on patches,"
        echo "so it needs a new build for your dots-hyprland version."
    else
        echo "Installing would replace them and may hide newer options or break the settings app."
    fi
    echo "Run again with --force to install anyway (a backup is still made)."
    exit 1
fi

# Back up every file that is about to be replaced. Files that already are this package's
# (a re-install) are skipped, so the backup always holds the latest version that is not ours.
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

# Files this package adds go in first, then a pause, then the files it replaces. The running shell
# reloads when the content of a file it uses changes, and does not notice new files. A reload that
# is already under way (from the steps above) must be over before the replaced files change, so
# that the reload they cause finds everything they refer to.
added=0
for f in "${files[@]}"; do
    if [ ! -e "$target/$f" ]; then
        mkdir -p "$target/$(dirname "$f")"
        cp -a "$here/files/$f" "$target/$f"
        added=$((added + 1))
    fi
done
[ "$added" -gt 0 ] && sleep 2
cp -a "$here/files/." "$target/"

# Keep a copy of this package so it can be re-applied after a dotfiles update
# (Settings > About > Update dotfiles does that) and uninstalled without the download.
if [ "$here" != "$state/package" ]; then
    rm -rf "$state/package"
    mkdir -p "$state/package"
    cp -a "$here/install.sh" "$here/stock.sha256" "$here/files" "$state/package/"
    for extra in NAME TITLE REQUIRES; do
        [ -f "$here/$extra" ] && cp -a "$here/$extra" "$state/package/"
    done
fi
echo "Installed $title: ${#files[@]} files into $target"
echo "Close and reopen Settings to see it. To undo: bash $state/package/install.sh --uninstall"
