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

## ii Login

An SDDM theme that makes the login screen match the illogical-impulse lockscreen.

- **Same layout as the lockscreen:** the analog clock, quote and date, and three pill toolbars for user, password, session and power.
- **Follows your desktop:** a user service re-syncs the blurred wallpaper and colours whenever the shell regenerates them.
- **More than one monitor:** login controls on the primary monitor, wallpaper and clock on the others, and an install option to rotate a portrait monitor.
- **Authentication is unchanged:** SDDM still checks the password. The theme code is root-owned; only colours, text and one image are writable by your user.

### Install

Download `ii-login.zip` from the site (or take it from `web/public/downloads/`), then run the installer as yourself. It asks for your sudo password once.

```sh
unzip ii-login.zip
bash ii-login/install.sh                 # add --rotate left|right for a portrait HDMI monitor
bash ii-login/install.sh --uninstall     # remove it
```

If the login screen ever misbehaves, press Ctrl+Alt+F3, log in, and run:

```sh
sudo rm /etc/sddm.conf.d/10-ii-login.conf && sudo systemctl restart sddm
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
| `build_site.py` | Builds the zip, `NOTICE` and the figures the website shows |
| `sddm-theme/` | ii Login: the theme, its sync script, installer and screenshots |
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

GPL-3.0, the same as dots-hyprland. The files in `patched/` are modified versions of dots-hyprland files; `NOTICE` says which version they were modified from and when. `LICENSE` and `NOTICE` are included in the zip. The ii Login theme is a port of the lockscreen to SDDM and carries its own notice in `sddm-theme/NOTICE`.
