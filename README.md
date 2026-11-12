# Sidegrade

Small, reversible mods for [end-4's dots-hyprland](https://github.com/end-4/dots-hyprland) (illogical-impulse), and the website that publishes them.

Unofficial: not affiliated with or endorsed by that project.

## ii Settings Rework

A rework of the Quickshell "ii" settings app.

- **Every option has a control.** The stock app leaves 114 of its 284 options to be edited by hand in `config.json`.
- **Search across every page.** Results show where each option lives and jump to the exact row (Ctrl+F).
- **Sections in the navigation rail.** The selected tab lists its sections and marks the one in view.
- **Tabs ordered by use,** with options nothing in the shell reads moved to a Misc tab.
- **Calmer rows.** Sections sit on cards, units moved out of the labels, short values use compact rows.
- **Update check.** About shows how far behind your dotfiles are and can run end-4's updater, re-applying the mod afterwards.

It also fixes one stock bug: the "force notifications to one monitor" switch wrote to a config key the shell did not define.

### Install

Download `ii-settings-rework.zip` from the site (or take it from `web/public/downloads/`), then:

```sh
unzip ii-settings-rework.zip
bash ii-settings-rework/install.sh
```

The installer backs up every file it replaces to `~/.local/share/ii-settings-rework/backup` and refuses to run if your dots version differs from the one the mod was built against (`--force` overrides that).

```sh
bash ii-settings-rework/install.sh --uninstall   # put the original files back
```

## Layout

| Path | What it is |
| --- | --- |
| `patched/` | The modded files, as installed into `~/.config/quickshell/ii` |
| `backup-original/` | The stock files the mod was built against |
| `apply.py` | Regenerates the settings pages and search index from the stock files |
| `snippets/` | QML blocks `apply.py` inserts |
| `installer/install.sh` | The installer shipped in the zip |
| `restore.sh` | Re-applies `patched/` locally after a dots update |
| `build_site.py` | Builds the zip and the figures the website shows |
| `web/` | The Sidegrade website (React + Vite), deployed to GitHub Pages |
| `site/` | A single-file version of the product page |

## Working on it

```sh
python3 apply.py        # regenerate the pages into ~/.config/quickshell/ii
python3 build_site.py   # rebuild the zip and website data from patched/
cd web && npm install && npm run dev
```

`settings.qml`, the `Opt*.qml` components and `SettingsSection.qml` are edited by hand; copy them into `patched/` after changing them.

## Licence

GPL-3.0, the same as dots-hyprland, which the modded files derive from.
