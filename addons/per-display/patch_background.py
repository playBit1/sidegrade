#!/usr/bin/env python3
"""Rebuild the desktop background files from the originals in backup-original/.

Makes the background of each monitor follow services/MonitorBackgrounds.qml: its own
wallpaper, and its own widget (clock, weather) and parallax settings when it has them.
Every read of Config.options.background.widgets / .parallax in the background module
becomes a read of that monitor's settings; the few writes go through the service.

Part of the "per-display backgrounds" add-on. Writes patched/modules/ii/background/ next to
this script, and the same files in ~/.config/quickshell/ii when the add-on is installed there.
Run:  python3 addons/per-display/patch_background.py
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
MODULE = "modules/ii/background"
SRC = HERE / "backup-original" / MODULE
LIVE = Path.home() / ".config/quickshell/ii"
DESTINATIONS = [HERE / "patched" / MODULE]
if (LIVE / "services/MonitorBackgrounds.qml").exists():  # the add-on is installed here: keep it in step
    DESTINATIONS.append(LIVE / MODULE)

SHARED = "Config.options.background."
ASSIGN = re.compile(r"^(\s*)Config\.options\.background\.(widgets\.[\w.]+) = (.+?);?$", re.M)
MARK = "// ii Settings Rework: this monitor's own widget settings, or the shared ones"


def swap(src, old, new, count=1):
    if src.count(old) != count:
        sys.exit(f"expected {count} of {old!r}, found {src.count(old)}: the stock file changed, redo this patch")
    return src.replace(old, new)


def add_imports(src):
    lines = src.split("\n")
    at = max(i for i, line in enumerate(lines) if line.startswith("import "))
    for needed in ("import qs.services", "import Quickshell"):
        if needed not in lines:
            lines.insert(at + 1, needed)
    return "\n".join(lines)


def widget(src, root, inherits=False):
    """A widget file: read the settings of the monitor its window is on."""
    if SHARED + "widgets" not in src:
        return src
    src = ASSIGN.sub(lambda m: f'{m.group(1)}MonitorBackgrounds.write({root}.bgScreen, "{m.group(2)}", {m.group(3)})', src)
    src = src.replace(SHARED + "widgets", f"{root}.bgOptions.widgets")
    if inherits:  # the properties come from AbstractBackgroundWidget
        return src.replace(f"    id: {root}\n", f"    id: {root} // ii Settings Rework: reads this monitor's settings, see AbstractBackgroundWidget\n", 1)
    lines = src.split("\n")
    first = next(i for i, line in enumerate(lines) if re.match(r"^[A-Za-z].*\{$", line))
    if lines[first + 1].strip() == f"id: {root}":
        first += 1
    else:
        lines.insert(first + 1, f"    id: {root}")
        first += 1
    lines[first + 1:first + 1] = [
        f"    {MARK}",
        '    readonly property string bgScreen: QsWindow.window?.screen?.name ?? ""',
        "    readonly property var bgOptions: MonitorBackgrounds.optionsFor(bgScreen)",
    ]
    return add_imports("\n".join(lines))


def abstract_widget(src):
    src = widget(src, "root")
    # Dragging a widget saves its position: to this monitor's settings when it has its own
    src = swap(src, "        configEntry.x = root.targetX;",
               "        MonitorBackgrounds.write(root.bgScreen, `widgets.${root.configEntryName}.x`, root.targetX);")
    src = swap(src, "        configEntry.y = root.targetY;",
               "        MonitorBackgrounds.write(root.bgScreen, `widgets.${root.configEntryName}.y`, root.targetY);")
    return src


def background(src):
    src = swap(src, """        // Wallpaper
        property bool wallpaperIsVideo: Config""", """        // ii Settings Rework: a monitor can have its own image and its own widget and parallax settings
        // (Settings > Background), otherwise it shows the main wallpaper with the shared settings
        readonly property var bgOptions: MonitorBackgrounds.optionsFor(modelData.name)
        property string ownWallpaperPath: MonitorBackgrounds.wallpaperFor(modelData.name)
        // Wallpaper
        property bool wallpaperIsVideo: ownWallpaperPath.length === 0 && Config""")
    src = swap(src, "        property string wallpaperPath: wallpaperIsVideo ?",
               "        property string wallpaperPath: ownWallpaperPath.length > 0 ? ownWallpaperPath : wallpaperIsVideo ?")
    for name in ("WeatherWidget", "ClockWidget"):  # placement and text color follow the image this monitor shows
        src = swap(src, f"sourceComponent: {name} {{\n",
                   f"sourceComponent: {name} {{\n                        wallpaperPath: bgRoot.wallpaperPath\n")
    for group in ("widgets", "parallax"):
        src = src.replace(SHARED + group, f"bgRoot.bgOptions.{group}")
    return src


W = "widgets/"
FILES = {
    "Background.qml": background,
    W + "AbstractBackgroundWidget.qml": abstract_widget,
    W + "clock/ClockWidget.qml": lambda s: widget(s, "root", inherits=True),
    W + "clock/ClockText.qml": lambda s: widget(s, "clockText"),
    W + "clock/DigitalClock.qml": lambda s: widget(s, "clockColumn"),
    W + "clock/dateIndicator/RectangleDate.qml": lambda s: widget(s, "rect"),
}
for name in ("CookieQuote", "CookieClock", "SecondHand", "TimeColumn", "dateIndicator/DateIndicator",
             "dateIndicator/RotatingDate", "minuteMarks/MinuteMarks"):
    FILES[W + f"clock/{name}.qml"] = lambda s: widget(s, "root")

stock = {p.relative_to(SRC).as_posix() for p in SRC.rglob("*.qml")}
if stock != set(FILES):
    sys.exit(f"backup-original and this script disagree on the files: {sorted(stock ^ set(FILES))}")

for name, patch in FILES.items():
    out = patch((SRC / name).read_text())
    for group in ("widgets", "parallax"):
        if SHARED + group in out:
            sys.exit(f"{name}: still reads {SHARED}{group}")
    if "ii Settings Rework" not in out:  # install.sh tells the add-on's files from upstream's by this
        sys.exit(f"{name}: patched file does not name the mod")
    for dst in DESTINATIONS:
        (dst / name).parent.mkdir(parents=True, exist_ok=True)
        (dst / name).write_text(out)
    print(f"patched {MODULE}/{name}")
