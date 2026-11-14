#!/usr/bin/env python3
"""Build the downloadable package and the product page.

  site/ii-settings-rework.zip   install.sh + LICENSE + NOTICE + files/ (from patched/) + stock.sha256
  NOTICE                        the GPL modification notice, naming the dots-hyprland commit
  site/page.html                page body in the form the Artifact tool publishes
  site/index.html               the same page as a standalone document, for any static host
  web/public/..., web/src/data/settings-rework.generated.json   zip, screenshots and sizes for the React storefront

Run after apply.py / after copying edited files into patched/:  python3 build_site.py
"""
import base64
import hashlib
import io
import subprocess
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
PATCHED, STOCK, SITE = HERE / "patched", HERE / "backup-original", HERE / "site"
NAME = "ii-settings-rework"

files = sorted(p for p in PATCHED.rglob("*") if p.is_file())
rel = lambda p: p.relative_to(PATCHED).as_posix()

# --- the dots-hyprland version the mod is built against, and the GPL notice that names it
def dots_git(*args):
    return subprocess.run(["git", "-C", str(Path.home() / ".cache/dots-hyprland"), *args],
                          capture_output=True, text=True).stdout.strip()

commit = dots_git("rev-parse", "--short", "HEAD") or "unknown"
commit_date = dots_git("log", "-1", "--format=%ad", "--date=format:%-d %b %Y") or "unknown"
REPO = "https://github.com/playBit1/sidegrade"
notice = f"""ii Settings Rework
{REPO}

This is a modified version of parts of end-4's dots-hyprland (illogical-impulse),
https://github.com/end-4/dots-hyprland, which is licensed under the GNU General
Public License, version 3.

The files under files/ (patched/ in the repository) were modified from, or added
to, the Quickshell "ii" config of dots-hyprland as of commit {commit} ({commit_date}).
Modifications by playBit1, November 2026. The unmodified originals are kept in
backup-original/ in the repository.

Original work: copyright (C) end-4 and the dots-hyprland contributors.
Modifications: copyright (C) 2026 playBit1.

This program is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License, version 3, as published by the Free
Software Foundation. It is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for the full text.

Not affiliated with or endorsed by the dots-hyprland project.
"""
(HERE / "NOTICE").write_text(notice)

# --- zip (fixed timestamps so the same input gives the same file)
buf = io.BytesIO()
with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    def add(name, data, mode=0o644):
        info = zipfile.ZipInfo(f"{NAME}/{name}", date_time=(2026, 11, 12, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = mode << 16
        z.writestr(info, data)
    add("install.sh", (HERE / "installer" / "install.sh").read_bytes(), 0o755)
    add("LICENSE", (HERE / "LICENSE").read_bytes())
    add("NOTICE", notice)
    add("stock.sha256", "".join(
        f"{hashlib.sha256(p.read_bytes()).hexdigest()}  ./{p.relative_to(STOCK).as_posix()}\n"
        for p in sorted(STOCK.rglob("*")) if p.is_file()))
    for p in files:
        add(f"files/{rel(p)}", p.read_bytes())
zip_bytes = buf.getvalue()
(SITE / f"{NAME}.zip").write_bytes(zip_bytes)

# --- sizes
raw = sum(p.stat().st_size for p in files)
kb = lambda n: f"{n / 1024:.0f}"
GROUPS = [
    ("settings.qml", "The window: tabs, navigation rail, search", lambda r: r == "settings.qml"),
    ("modules/settings/*Config.qml, About.qml", "The eleven pages",
     lambda r: r.startswith("modules/settings/") and (r.endswith("Config.qml") or r.endswith("About.qml"))),
    ("modules/settings/Opt*.qml, SettingsSection.qml", "Row and section components",
     lambda r: r.startswith("modules/settings/Opt") or r.endswith("SettingsSection.qml")),
    ("modules/settings/SearchIndex.qml", "Labels the search field looks through", lambda r: r.endswith("SearchIndex.qml")),
    ("modules/ii/notificationPopup/NotificationPopup.qml", "One-line fix for the notification monitor option",
     lambda r: r.endswith("NotificationPopup.qml")),
    ("scripts/settings-rework/update-dots.sh", "Run by the Update dotfiles button",
     lambda r: r.endswith("update-dots.sh")),
    ("scripts/settings-rework/displays.sh", "Writes the display settings, and undoes them if they are not kept",
     lambda r: r.endswith("displays.sh")),
]
rows, seen, groups = [], set(), []
for label, what, match in GROUPS:
    group = [p for p in files if match(rel(p))]
    seen.update(group)
    groups.append({"files": label, "what": what, "count": len(group), "bytes": sum(p.stat().st_size for p in group)})
    rows.append(f'          <tr><td>{label}</td><td class="what">{what}</td>'
                f'<td class="n">{len(group)}</td><td class="n">{kb(sum(p.stat().st_size for p in group))} KB</td></tr>')
assert seen == set(files), [rel(p) for p in set(files) - seen]

page = (SITE / "page.src.html").read_text()
for key, value in {
    "{{ZIP_KB}}": kb(len(zip_bytes)), "{{RAW_KB}}": kb(raw), "{{FILE_COUNT}}": str(len(files)),
    "{{FILE_ROWS}}": "\n".join(rows), "{{COMMIT}}": commit, "{{COMMIT_DATE}}": commit_date, "{{REPO}}": REPO,
    "{{ZIP_B64}}": base64.b64encode(zip_bytes).decode(),
}.items():
    page = page.replace(key, value)
(SITE / "page.html").write_text(page)
(SITE / "index.html").write_text(
    '<!doctype html><html lang="en"><head><meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'
    "<style>body{margin:0}img{max-width:100%}[hidden]{display:none!important}</style></head><body>\n"
    + page + "</body></html>\n")
# --- React storefront (web/): the same zip, screenshots and figures
import json
import shutil
WEB = HERE / "web"
if WEB.is_dir():
    (WEB / "public" / "downloads").mkdir(parents=True, exist_ok=True)
    (WEB / "public" / "shots").mkdir(parents=True, exist_ok=True)
    shutil.copy(SITE / f"{NAME}.zip", WEB / "public" / "downloads" / f"{NAME}.zip")
    for shot in (SITE / "shots").glob("*.png"):
        shutil.copy(shot, WEB / "public" / "shots" / shot.name)
    (WEB / "src" / "data" / "settings-rework.generated.json").write_text(json.dumps(
        {"zipBytes": len(zip_bytes), "rawBytes": raw, "fileCount": len(files), "commit": commit, "commitDate": commit_date, "groups": groups},
        indent=2) + "\n")


# --- add-on "per-display backgrounds" (addons/per-display/): its own zip, installed on top of the mod.
# It is separate because it patches the shell's desktop background files, which the mod itself leaves alone.
ADDON = HERE / "addons" / "per-display"
ADDON_NAME = f"{NAME}-per-display"  # install.sh finds add-ons by this prefix
ADDON_TITLE = "Per-display backgrounds"
addon_files = sorted(p for p in (ADDON / "patched").rglob("*") if p.is_file())
addon_rel = lambda p: p.relative_to(ADDON / "patched").as_posix()
addon_stock = {p.relative_to(ADDON / "backup-original").as_posix(): p for p in (ADDON / "backup-original").rglob("*") if p.is_file()}
for p in addon_files:  # files it takes over from the mod: only installs on top of this exact build of them
    if (PATCHED / addon_rel(p)).is_file():
        addon_stock[addon_rel(p)] = PATCHED / addon_rel(p)
    assert addon_rel(p) in addon_stock or "MonitorBackgrounds" in p.name, addon_rel(p)
addon_notice = f"""{ADDON_TITLE} - an add-on for ii Settings Rework
{REPO}

This is a modified version of parts of end-4's dots-hyprland (illogical-impulse),
https://github.com/end-4/dots-hyprland, which is licensed under the GNU General
Public License, version 3.

The files under files/modules/ii/background/ were modified from the Quickshell "ii" config
of dots-hyprland as of commit {commit} ({commit_date}); the other files were added.
Modifications by playBit1, November 2026. The unmodified originals are kept in
addons/per-display/backup-original/ in the repository.

Original work: copyright (C) end-4 and the dots-hyprland contributors.
Modifications: copyright (C) 2026 playBit1.

This program is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License, version 3, as published by the Free
Software Foundation. It is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for the full text.

Not affiliated with or endorsed by the dots-hyprland project.
"""
(ADDON / "NOTICE").write_text(addon_notice)
buf = io.BytesIO()
with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    def add_addon(name, data, mode=0o644):
        info = zipfile.ZipInfo(f"{ADDON_NAME}/{name}", date_time=(2026, 11, 14, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = mode << 16
        z.writestr(info, data)
    add_addon("install.sh", (HERE / "installer" / "install.sh").read_bytes(), 0o755)
    add_addon("NAME", ADDON_NAME + "\n")
    add_addon("TITLE", ADDON_TITLE + "\n")
    add_addon("REQUIRES", NAME + "\n")
    add_addon("LICENSE", (HERE / "LICENSE").read_bytes())
    add_addon("NOTICE", addon_notice)
    add_addon("stock.sha256", "".join(
        f"{hashlib.sha256(p.read_bytes()).hexdigest()}  ./{r}\n" for r, p in sorted(addon_stock.items())))
    for p in addon_files:
        add_addon(f"files/{addon_rel(p)}", p.read_bytes())
addon_zip = buf.getvalue()
if WEB.is_dir():
    (WEB / "public" / "downloads" / f"{ADDON_NAME}.zip").write_bytes(addon_zip)
    (WEB / "src" / "data" / "per-display.generated.json").write_text(json.dumps(
        {"zipBytes": len(addon_zip), "rawBytes": sum(p.stat().st_size for p in addon_files), "fileCount": len(addon_files),
         "shellFiles": sum(1 for p in addon_files if addon_rel(p).startswith("modules/ii/"))}, indent=2) + "\n")
print(f"{ADDON_NAME}: {len(addon_files)} files, zip {len(addon_zip)} bytes")


# --- ii Login (sddm-theme/): its own zip, screenshots and figures for the storefront
LOGIN = HERE / "sddm-theme"
LOGIN_NAME = "ii-login"
login_notice = f"""ii Login - an SDDM theme matching the illogical-impulse lockscreen
{REPO}

The clock and toolbars in this theme are a port of the lockscreen and clock widgets of
end-4's dots-hyprland (illogical-impulse), https://github.com/end-4/dots-hyprland, which
is licensed under the GNU General Public License, version 3. They were rewritten for SDDM
from dots-hyprland as of commit {commit} ({commit_date}) by playBit1, November 2026.

Original work: copyright (C) end-4 and the dots-hyprland contributors.
This theme: copyright (C) 2026 playBit1.

This program is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License, version 3, as published by the Free
Software Foundation. It is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for the full text.

Not affiliated with or endorsed by the dots-hyprland or SDDM projects.
"""
(LOGIN / "NOTICE").write_text(login_notice)
login_files = [LOGIN / "install.sh", LOGIN / "sync.sh"] + sorted(p for p in (LOGIN / "theme").iterdir() if p.is_file())
buf = io.BytesIO()
with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    def add_login(name, data, mode=0o644):
        info = zipfile.ZipInfo(f"{LOGIN_NAME}/{name}", date_time=(2026, 11, 14, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = mode << 16
        z.writestr(info, data)
    add_login("LICENSE", (HERE / "LICENSE").read_bytes())
    add_login("NOTICE", login_notice)
    for p in login_files:
        add_login(p.relative_to(LOGIN).as_posix(), p.read_bytes(), 0o755 if p.suffix == ".sh" else 0o644)
login_zip = buf.getvalue()
LOGIN_GROUPS = [
    ("theme/Main.qml", "The login screen: wallpaper, toolbars, menus, login", lambda p: p.name == "Main.qml"),
    ("theme/CookieClock.qml", "The analog clock with date bubbles", lambda p: p.name == "CookieClock.qml"),
    ("theme/Pill.qml, Icon.qml, IconButton.qml, ShapeDot.qml", "Toolbar, icon and password-character components",
     lambda p: p.name in ("Pill.qml", "Icon.qml", "IconButton.qml", "ShapeDot.qml")),
    ("theme/metadata.desktop, theme.conf", "Theme description and default colours",
     lambda p: p.name in ("metadata.desktop", "theme.conf")),
    ("sync.sh", "Copies your wallpaper and colours for the theme to read", lambda p: p.name == "sync.sh"),
    ("install.sh", "Installer and uninstaller", lambda p: p.name == "install.sh"),
]
login_seen, login_groups = set(), []
for label, what, match in LOGIN_GROUPS:
    group = [p for p in login_files if match(p)]
    login_seen.update(group)
    login_groups.append({"files": label, "what": what, "count": len(group), "bytes": sum(p.stat().st_size for p in group)})
assert login_seen == set(login_files), [p.name for p in set(login_files) - login_seen]
if WEB.is_dir():
    (WEB / "public" / "downloads" / f"{LOGIN_NAME}.zip").write_bytes(login_zip)
    for shot in (LOGIN / "shots").glob("*.png"):
        shutil.copy(shot, WEB / "public" / "shots" / shot.name)
    (WEB / "src" / "data" / "login.generated.json").write_text(json.dumps(
        {"zipBytes": len(login_zip), "rawBytes": sum(p.stat().st_size for p in login_files),
         "fileCount": len(login_files), "commit": commit, "commitDate": commit_date, "groups": login_groups},
        indent=2) + "\n")
print(f"ii-login: {len(login_files)} files, zip {len(login_zip)} bytes")

print(f"{len(files)} files, {raw} bytes installed, zip {len(zip_bytes)} bytes, page {len(page)} bytes")
