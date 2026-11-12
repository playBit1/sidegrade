#!/usr/bin/env bash
# Re-apply the customised settings app after an end-4 dots update has overwritten it.
# Copies patched/ over ~/.config/quickshell/ii. Refuses if the update changed a stock file
# (then the patch must be redone against the new version) unless --force is given.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
live="$HOME/.config/quickshell/ii"
changed=0
while IFS= read -r -d '' f; do
    rel="${f#"$here/backup-original/"}"
    if [ -f "$live/$rel" ] && ! cmp -s "$live/$rel" "$f" && ! cmp -s "$live/$rel" "$here/patched/$rel"; then
        echo "upstream changed: $rel"
        changed=1
    fi
done < <(find "$here/backup-original" -type f -print0)
if [ "$changed" = 1 ] && [ "${1:-}" != "--force" ]; then
    echo "The dots update changed the files above; restoring would discard those changes."
    echo "Re-run with --force to overwrite anyway."
    exit 1
fi
cp -a "$here/patched/." "$live/"
echo "Restored customised settings app. Close and reopen Settings to see it."
