#!/usr/bin/env bash
# Re-apply the customised settings app after an end-4 dots update has overwritten it.
# Copies patched/ over ~/.config/quickshell/ii. Refuses if the update changed a stock file
# (then the patch must be redone against the new version) unless --force is given.
#   --addons   also apply the add-ons in addons/*/patched (same check against their stock files)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
live="$HOME/.config/quickshell/ii"
force=0 addons=0
for arg in "$@"; do
    case "$arg" in
        --force) force=1 ;;
        --addons) addons=1 ;;
        *) echo "usage: restore.sh [--force] [--addons]"; exit 1 ;;
    esac
done
sets=("$here")
if [ "$addons" = 1 ]; then
    for addon in "$here"/addons/*/; do sets+=("${addon%/}"); done
fi
changed=0
for set in "${sets[@]}"; do
    while IFS= read -r -d '' f; do
        rel="${f#"$set/backup-original/"}"
        # Fine if it is still the stock file, or already ours (the mod's, or an add-on's on top of it)
        if [ -f "$live/$rel" ] && ! cmp -s "$live/$rel" "$f" && ! cmp -s "$live/$rel" "$set/patched/$rel" \
            && ! cmp -s "$live/$rel" "$here/patched/$rel"; then
            echo "upstream changed: $rel"
            changed=1
        fi
    done < <(find "$set/backup-original" -type f -print0)
done
if [ "$changed" = 1 ] && [ "$force" != 1 ]; then
    echo "The dots update changed the files above; restoring would discard those changes."
    echo "Re-run with --force to overwrite anyway."
    exit 1
fi
for set in "${sets[@]}"; do
    cp -a "$set/patched/." "$live/"
done
echo "Restored the customised settings app$([ "$addons" = 1 ] && echo " and add-ons"). Close and reopen Settings to see it."
