#!/usr/bin/env python3
"""Build the downloadable package and the product page.

  site/ii-settings-rework.zip   install.sh + files/ (from patched/) + stock.sha256
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

# --- zip (fixed timestamps so the same input gives the same file)
buf = io.BytesIO()
with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    def add(name, data, mode=0o644):
        info = zipfile.ZipInfo(f"{NAME}/{name}", date_time=(2026, 11, 12, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = mode << 16
        z.writestr(info, data)
    add("install.sh", (HERE / "installer" / "install.sh").read_bytes(), 0o755)
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
    ("modules/settings/*Config.qml, About.qml", "The ten pages",
     lambda r: r.startswith("modules/settings/") and (r.endswith("Config.qml") or r.endswith("About.qml"))),
    ("modules/settings/Opt*.qml, SettingsSection.qml", "Row and section components",
     lambda r: r.startswith("modules/settings/Opt") or r.endswith("SettingsSection.qml")),
    ("modules/settings/SearchIndex.qml", "Labels the search field looks through", lambda r: r.endswith("SearchIndex.qml")),
    ("modules/ii/notificationPopup/NotificationPopup.qml", "One-line fix for the notification monitor option",
     lambda r: r.endswith("NotificationPopup.qml")),
    ("scripts/settings-rework/update-dots.sh", "Run by the Update dotfiles button",
     lambda r: r.endswith("update-dots.sh")),
]
rows, seen, groups = [], set(), []
for label, what, match in GROUPS:
    group = [p for p in files if match(rel(p))]
    seen.update(group)
    groups.append({"files": label, "what": what, "count": len(group), "bytes": sum(p.stat().st_size for p in group)})
    rows.append(f'          <tr><td>{label}</td><td class="what">{what}</td>'
                f'<td class="n">{len(group)}</td><td class="n">{kb(sum(p.stat().st_size for p in group))} KB</td></tr>')
assert seen == set(files), [rel(p) for p in set(files) - seen]

commit = subprocess.run(["git", "-C", str(Path.home() / ".cache/dots-hyprland"), "rev-parse", "--short", "HEAD"],
                        capture_output=True, text=True).stdout.strip() or "unknown"

page = (SITE / "page.src.html").read_text()
for key, value in {
    "{{ZIP_KB}}": kb(len(zip_bytes)), "{{RAW_KB}}": kb(raw), "{{FILE_COUNT}}": str(len(files)),
    "{{FILE_ROWS}}": "\n".join(rows), "{{COMMIT}}": commit,
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
WEB = HERE / "web"
if WEB.is_dir():
    import json
    import shutil
    (WEB / "public" / "downloads").mkdir(parents=True, exist_ok=True)
    (WEB / "public" / "shots").mkdir(parents=True, exist_ok=True)
    shutil.copy(SITE / f"{NAME}.zip", WEB / "public" / "downloads" / f"{NAME}.zip")
    for shot in (SITE / "shots").glob("*.png"):
        shutil.copy(shot, WEB / "public" / "shots" / shot.name)
    (WEB / "src" / "data" / "settings-rework.generated.json").write_text(json.dumps(
        {"zipBytes": len(zip_bytes), "rawBytes": raw, "fileCount": len(files), "commit": commit, "groups": groups},
        indent=2) + "\n")

print(f"{len(files)} files, {raw} bytes installed, zip {len(zip_bytes)} bytes, page {len(page)} bytes")
