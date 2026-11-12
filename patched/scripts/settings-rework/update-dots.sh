#!/usr/bin/env bash
# Opened in a terminal by Settings > About > "Update dotfiles" (ii Settings Rework).
# Runs end-4's own updater, then puts the reworked settings app back if the update replaced it.
repo="$HOME/.cache/dots-hyprland"
reapply="${XDG_DATA_HOME:-$HOME/.local/share}/ii-settings-rework/package/install.sh"

finish() {
    echo
    read -n1 -rsp "Press any key to close this window"
    echo
}
trap finish EXIT

if [ ! -f "$repo/setup" ]; then
    echo "No dots-hyprland repository found at $repo, so there is nothing to update from."
    exit 1
fi
cd "$repo" || exit 1

echo "Updating illogical-impulse with end-4's own updater:  ./setup exp-update"
echo "It pulls the latest dotfiles, then copies them over your config and asks what to do"
echo "with each file you have changed. For the settings app files either answer is fine:"
echo "the reworked settings app is re-applied afterwards."
echo

./setup exp-update
status=$?
if [ "$status" -ne 0 ]; then
    echo
    echo "The updater stopped with an error (exit $status). The settings mod was left as it is."
    exit "$status"
fi

echo
if [ -f "$reapply" ]; then
    echo "Re-applying ii Settings Rework..."
    bash "$reapply" || echo "The mod was not re-applied; see the message above."
else
    echo "Note: the update may have replaced the reworked settings app."
    echo "Run its install.sh again to put it back."
fi
