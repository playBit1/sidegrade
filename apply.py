#!/usr/bin/env python3
"""Rebuild the end-4 settings pages from the originals in backup-original/.

- reorders the sections of each page by importance
- adds controls for the config options the stock settings app does not expose
- fixes the notifications "force monitor" key (forceMonitor -> monitor)

settings.qml (tab order + sub-category navigation) and the Opt*.qml helpers are
edited by hand in ~/.config/quickshell/ii and are not generated here.
Run:  python3 apply.py
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE / "backup-original" / "modules" / "settings"
DST = Path.home() / ".config/quickshell/ii/modules/settings"


def tr(s):
    return 'Translation.tr("%s")' % s.replace('"', '\\"').replace("\n", "\\n")


def switch(key, text, icon="", tooltip="", extra=""):
    out = ["OptSwitch {", f'    key: "{key}"']
    out.append(f"    text: {tr(text)}")
    if tooltip:
        out.append(f"    tooltip: {tr(tooltip)}")
    if extra:
        out.append(f"    {extra}")
    out.append("}")
    return out


def spin(key, text, lo, hi, step=1, icon="", scale=1, extra=""):
    out = ["OptSpin {", f'    key: "{key}"']
    out += [f"    text: {tr(text)}", f"    from: {lo}", f"    to: {hi}", f"    stepSize: {step}"]
    if scale != 1:
        out.append(f"    scale: {scale}")
    if extra:
        out.append(f"    {extra}")
    out.append("}")
    return out


def text(key, label, wide=False):
    out = ["OptText {", f'    key: "{key}"', f"    placeholderText: {tr(label)}"]
    if wide:
        out.append("    wide: true")
    out.append("}")
    return out


def slider(key, label, extra=""):
    out = ["OptSlider {", f'    key: "{key}"', f"    text: {tr(label)}"]
    if extra:
        out.append(f"    {extra}")
    out.append("}")
    return out


def lst(key, label, sep=","):
    out = ["OptList {", f'    key: "{key}"', f"    placeholderText: {tr(label)}"]
    if sep != ",":
        out.append('    separator: "\\n"')
    out.append("}")
    return out


def wrap(head, children, props=()):
    out = [head + " {"] + ["    " + p for p in props]
    for child in children:
        out += ["    " + line for line in child]
    out.append("}")
    return out


def sub(title, *children, tooltip=""):
    props = [f"title: {tr(title)}"]
    if tooltip:
        props.append(f"tooltip: {tr(tooltip)}")
    return wrap("ContentSubsection", children, props)


def row(*children, uniform=True):
    return wrap("ConfigRow", children, ["uniform: true"] if uniform else [])


def section(title, icon, *children):
    return wrap("ContentSection", children, [f'icon: "{icon}"', f"title: {tr(title)}"])


def choice(key, options):
    out = ["ConfigSelectionArray {", f"    currentValue: Config.options.{key}",
           "    onSelected: newValue => {", f"        Config.options.{key} = newValue;", "    }",
           "    options: ["]
    for name, icon, value in options:
        out.append(f'        {{ displayName: {tr(name)}, icon: "{icon}", value: "{value}" }},')
    out += ["    ]", "}"]
    return out


def render(blocks, indent):
    pad = " " * indent
    return "\n".join("\n".join(pad + line if line else "" for line in b) for b in blocks)


# ---------------------------------------------------------------- page plans
# Each page: ordered list of (existing section title, [blocks appended to it])
# or ("+", new section block).
PAGES = {}

PAGES["BarConfig.qml"] = [
    ("Positioning", [
        sub("Auto-hide behaviour",
            spin("bar.autoHide.hoverRegionWidth", "Hover region width (px)", 1, 100, icon="arrow_range"),
            switch("bar.autoHide.pushWindows", "Push windows aside while the bar is revealed", "open_in_full"),
            switch("bar.autoHide.showWhenPressingSuper.enable", "Reveal the bar and workspace numbers while holding Super", "keyboard_command_key"),
            spin("bar.autoHide.showWhenPressingSuper.delay", "Super hold delay (ms)", 0, 2000, 10, icon="timer")),
        sub("Screens",
            lst("bar.screenList", "Monitors to show the bar on (comma-separated, e.g. DP-1, HDMI-A-1)"),
            tooltip="Leave empty to show the bar on every monitor.\nFind monitor names with 'hyprctl monitors'"),
    ]),
    ("+", section("Appearance", "palette",
        switch("bar.showBackground", "Show bar background", "texture"),
        switch("bar.floatStyleShadow", "Shadow behind the bar (float corner style only)", "shadow"),
        switch("bar.verbose", "Verbose (wider centre modules, show the date)", "notes"),
        text("bar.topLeftIcon", "Top-left icon: \"distro\" or an icon name from assets/icons (e.g. spark)", wide=True))),
    ("Workspaces", [
        switch("bar.workspaces.useNerdFont", "Use Nerd Font for workspace numbers", "font_download"),
    ]),
    ("Utility buttons", []),
    ("Tray", [
        switch("tray.filterPassive", "Hide passive items (smart tray)", "filter_alt"),
        switch("tray.showItemId", "Show item ID in tooltips", "badge",
               tooltip="Useful for finding the IDs to put in the pinned list"),
        lst("tray.pinnedItems", "Pinned item IDs (comma-separated)"),
    ]),
    ("+", section("Resources", "memory",
        row(switch("bar.resources.alwaysShowCpu", "Always show CPU", "developer_board"),
            switch("bar.resources.alwaysShowSwap", "Always show swap", "swap_horiz")),
        spin("bar.resources.cpuWarningThreshold", "CPU warning threshold (%)", 0, 100, 5, icon="warning"),
        spin("bar.resources.memoryWarningThreshold", "Memory warning threshold (%)", 0, 100, 5, icon="warning"),
        spin("bar.resources.swapWarningThreshold", "Swap warning threshold (%)", 0, 100, 5, icon="warning"))),
    ("Weather", []),
    ("Notifications", []),
    ("Tooltips", []),
]

PAGES["InterfaceConfig.qml"] = [
    ("+", section("Appearance", "palette",
        switch("appearance.extraBackgroundTint", "Extra background tint", "format_color_fill",
               tooltip="Mixes a little of the accent colour into backgrounds"),
        sub("Transparency",
            switch("appearance.transparency.automatic", "Automatic amount (based on the wallpaper)", "auto_awesome"),
            slider("appearance.transparency.backgroundTransparency", "Background transparency",
                   extra="enabled: !Config.options.appearance.transparency.automatic"),
            slider("appearance.transparency.contentTransparency", "Content transparency",
                   extra="enabled: !Config.options.appearance.transparency.automatic"),
            tooltip="Transparency itself is turned on in the Quick page"),
        sub("Accent colour",
            text("appearance.palette.accentColor", "Hex color (empty = from wallpaper)"),
            tooltip="Takes effect the next time colours are generated (e.g. on wallpaper change)"))),
    ("Sidebars", [
        sub("AI & translator",
            switch("sidebar.ai.textFadeIn", "Fade in AI response text", "animation"),
            spin("sidebar.translator.delay", "Translator request delay (ms)", 0, 5000, 50, icon="timer")),
    ]),
    ("Dock", [
        spin("dock.height", "Height (px)", 30, 200, 2, icon="height"),
        spin("dock.hoverRegionHeight", "Hover region height (px)", 1, 100, icon="arrow_range"),
        lst("dock.pinnedApps", "Pinned apps (desktop entry IDs, comma-separated)"),
        lst("dock.ignoredAppRegexes", "Ignored apps (one regular expression per line)", sep="\n"),
    ]),
    ("+", section("Launcher", "apps",
        lst("launcher.pinnedApps", "Pinned apps (desktop entry IDs, comma-separated)"))),
    ("Overview", []),
    ("Notifications", []),
    ("On-screen display", []),
    ("Lock screen", [
        spin("lock.blur.radius", "Blur radius", 0, 300, 10, icon="blur_on"),
    ]),
    ("Region selector (screen snipping/Google Lens)", [
        sub("Target region appearance",
            switch("regionSelector.targetRegions.showLabel", "Show labels on target regions", "label"),
            slider("regionSelector.targetRegions.opacity", "Region opacity"),
            slider("regionSelector.targetRegions.contentRegionOpacity", "Content region opacity"),
            spin("regionSelector.targetRegions.selectionPadding", "Selection padding (px)", 0, 50, icon="padding")),
        sub("Annotation",
            switch("regionSelector.annotation.useSatty", "Use satty instead of swappy", "edit")),
    ]),
    ("+", section("On-screen keyboard", "keyboard",
        text("osk.layout", "Layout name (e.g. qwerty_full)"),
        switch("osk.pinnedOnStartup", "Pinned on startup", "keep"))),
    ("Cheat sheet", []),
    ("Overlay: General", [
        slider("overlay.clickthroughOpacity", "Opacity of click-through widgets"),
    ]),
    ("Overlay: Crosshair", []),
    ("Overlay: Floating Image", [
        spin("overlay.floatingImage.scale", "Scale (%)", 10, 500, 10, icon="aspect_ratio", scale=100),
    ]),
    ("Wallpaper selector", []),
    ("+", section("Shell windows", "web_asset",
        switch("windows.showTitlebar", "Show titlebar on shell apps (like this one)", "title"),
        switch("windows.centerTitle", "Center the title", "format_align_center"))),
    ("Fonts", []),
]

XY = lambda name: sub(
    "Position",
    row(spin(f"background.widgets.{name}.x", "X", 0, 10000, 10, icon="swap_horiz"),
        spin(f"background.widgets.{name}.y", "Y", 0, 10000, 10, icon="swap_vert")),
    tooltip="Used with the \"free\" placement strategy. The other strategies overwrite it")

PAGES["BackgroundConfig.qml"] = [
    ("+", section("Wallpaper", "wallpaper",
        switch("background.hideWhenFullscreen", "Hide when a window is fullscreen", "fullscreen"),
        text("background.thumbnailPath", "Video wallpaper thumbnail path (normally set automatically)", wide=True))),
    ("Widget: Clock", [
        XY("clock"),
    ]),
    ("Widget: Weather", [XY("weather")]),
    ("Parallax", [
        switch("background.parallax.autoVertical", "Vertical parallax automatically for portrait wallpapers", "swap_vert"),
        spin("background.parallax.widgetsFactor", "Widget parallax factor (%)", 0, 300, 10, icon="layers", scale=100),
    ]),
]

PAGES["GeneralConfig.qml"] = [
    ("Time", [
        sub("Date formats",
            text("time.dateFormat", "Date format (e.g. ddd, dd/MM)"),
            row(text("time.shortDateFormat", "Short date (e.g. dd/MM)", wide=True),
                text("time.dateWithYearFormat", "Date with year (e.g. dd/MM/yyyy)", wide=True)),
            tooltip="Qt date format strings, see https://doc.qt.io/qt-6/qtime.html#toString"),
        sub("Pomodoro",
            spin("time.pomodoro.focus", "Focus (seconds)", 60, 7200, 60, icon="target"),
            spin("time.pomodoro.breakTime", "Break (seconds)", 60, 3600, 60, icon="coffee"),
            spin("time.pomodoro.longBreak", "Long break (seconds)", 60, 7200, 60, icon="weekend"),
            spin("time.pomodoro.cyclesBeforeLongBreak", "Cycles before a long break", 1, 12, icon="repeat")),
    ]),
    ("+", section("Night light", "nightlight",
        switch("light.night.automatic", "Turn on automatically on schedule", "schedule"),
        row(text("light.night.from", "From (HH:mm)", wide=True), text("light.night.to", "To (HH:mm)", wide=True)),
        spin("light.night.colorTemperature", "Colour temperature (K)", 1000, 10000, 100, icon="thermostat"),
        switch("light.antiFlashbang.enable", "Anti-flashbang (dim bright content)", "flash_off"))),
    ("Audio", []),
    ("Sounds", [
        text("sounds.theme", "Sound theme (folder in /usr/share/sounds)"),
    ]),
    ("Language", [
        sub("Translator",
            row(text("language.translator.sourceLanguage", "Source language", wide=True),
                text("language.translator.targetLanguage", "Target language", wide=True)),
            tooltip="Language codes from 'trans -list-all'. \"auto\" detects / uses the system language"),
    ]),
    ("+", section("Default apps", "apps",
        text("apps.terminal", "Terminal (only for shell actions)"),
        text("apps.taskManager", "Task manager"),
        text("apps.volumeMixer", "Volume mixer"),
        text("apps.network", "Network settings"),
        text("apps.networkEthernet", "Ethernet settings"),
        text("apps.bluetooth", "Bluetooth settings"),
        text("apps.manageUser", "User management"),
        text("apps.changePassword", "Change password"),
        text("apps.update", "System update"))),
    ("Battery", []),
    ("Policies", []),
    ("Work safety", [
        sub("Trigger keywords",
            lst("workSafety.triggerCondition.networkNameKeywords", "Network names (comma-separated)"),
            lst("workSafety.triggerCondition.fileKeywords", "File names (comma-separated)"),
            lst("workSafety.triggerCondition.linkKeywords", "Links (comma-separated)"),
            tooltip="Content is treated as unsafe on a network whose name contains one of the first list,\nwhen a file name or link contains one of the others"),
    ]),
]

PAGES["ServicesConfig.qml"] = [
    ("Search", [
        sub("More",
            switch("search.prefix.showDefaultActionsWithoutPrefix", "Show default actions without a prefix", "bolt"),
            text("search.prefix.app", "App prefix"),
            spin("search.nonAppResultDelay", "Delay before non-app results (ms)", 0, 1000, 10, icon="timer"),
            lst("search.excludedSites", "Sites excluded from web search (comma-separated)"),
            text("search.imageSearch.imageSearchEngineBaseUrl", "Image search base URL", wide=True)),
    ]),
    ("AI", [
        sub("Tool",
            choice("ai.tool", [("Functions", "function", "functions"), ("Search", "search", "search"),
                               ("None", "close", "none")])),
        sub("Extra models",
            ["OptJson {", '    key: "ai.extraModels"', f"    label: {tr('Extra models (JSON list)')}", "}"],
            tooltip="Each entry needs: name, model, endpoint, api_format (\"openai\" or \"gemini\"), requires_key, key_id.\nOptional: description, icon, homepage, key_get_link"),
    ]),
    ("Weather", []),
    ("Save paths", []),
    ("Resources", [
        spin("resources.historyLength", "Graph history length (samples)", 10, 600, 10, icon="history"),
    ]),
    ("+", section("Media", "music_note",
        switch("media.filterDuplicatePlayers", "Filter duplicate players", "filter_alt",
               tooltip="Hides the duplicate entries created by playerctl and browser integration"))),
    ("Music Recognition", []),
    ("+", section("Anime boards", "image",
        spin("sidebar.booru.limit", "Results per page", 1, 100, 5, icon="format_list_numbered"),
        text("sidebar.booru.zerochan.username", "Zerochan username"))),
    ("Networking", []),
]

PAGES["AdvancedConfig.qml"] = [
    ("+", section("Panel family", "dashboard",
        choice("panelFamily", [("illogical-impulse", "bubble_chart", "ii"), ("Waffle (Windows-like)", "window", "waffle")]))),
    ("+", section("Scrolling", "mouse",
        switch("interactions.scrolling.fasterTouchpadScroll", "Faster touchpad scrolling", "touchpad_mouse"),
        spin("interactions.scrolling.mouseScrollFactor", "Mouse scroll factor", 10, 1000, 10, icon="mouse"),
        spin("interactions.scrolling.touchpadScrollFactor", "Touchpad scroll factor", 10, 2000, 10, icon="touchpad_mouse"),
        spin("interactions.scrolling.mouseScrollDeltaThreshold", "Mouse detection threshold (delta)", 1, 1000, 10,
             icon="straighten"))),
    ("Color generation", []),
    ("+", section("Conflict killer", "swords",
        switch("conflictKiller.autoKillNotificationDaemons", "Automatically kill other notification daemons",
               "notifications_off"),
        switch("conflictKiller.autoKillTrays", "Automatically kill other trays", "tab_close"))),
    ("+", section("Workarounds", "build",
        switch("interactions.deadPixelWorkaround.enable", "Dead pixel workaround", "pest_control",
               tooltip="Hyprland leaves 1 pixel on the right edge out of interactions"),
        spin("hacks.arbitraryRaceConditionDelay", "Race condition delay (ms)", 0, 1000, 5, icon="timer"))),
]

PAGE_TEMPLATE = """import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings

ContentPage {
    forceWidth: true

%s
}
"""

PAGES["QuickConfig.qml"] = [
    ("Wallpaper & Colors", []),
    ("Bar & screen", []),
]

PAGES["About.qml"] = [
    ("Distro", []),
    ("+", (HERE / "snippets" / "AboutUpdates.qml").read_text().rstrip("\n").split("\n")),
    ("Dotfiles", []),
]

WAFFLE = PAGE_TEMPLATE % render([
    section("Taskbar", "toolbar",
            switch("waffles.bar.bottom", "Taskbar at the bottom", "vertical_align_bottom"),
            switch("waffles.bar.leftAlignApps", "Left-align apps", "format_align_left")),
    [""],
    section("Action center", "toggle_on",
            lst("waffles.actionCenter.toggles", "Toggles, in order (comma-separated)")),
    [""],
    section("Calendar", "calendar_month",
            switch("waffles.calendar.force2CharDayOfWeek", "Two-letter day names", "short_text"),
            text("calendar.locale", "Calendar locale (e.g. en-GB)")),
    [""],
    section("System updates (Arch only)", "deployed_code_update",
            switch("updates.enableCheck", "Enable update checks", "update"),
            spin("updates.checkInterval", "Check interval (mins)", 10, 1440, 10, icon="av_timer"),
            spin("updates.adviseUpdateThreshold", "Advise updating above (packages)", 1, 2000, 5, icon="package_2"),
            spin("updates.stronglyAdviseUpdateThreshold", "Strongly advise updating above (packages)", 1, 5000, 10,
                 icon="warning")),
    [""],
    section("Tweaks", "tune",
            switch("waffles.tweaks.switchHandlePositionFix", "Fix switch handle position", "toggle_on"),
            switch("waffles.tweaks.smootherMenuAnimations", "Smoother menu animations", "animation"),
            switch("waffles.tweaks.smootherSearchBar", "Smoother search bar", "search")),
], 4)

# Options that exist in the config but that no shell code reads (checked by searching the
# whole shell for each option). They are kept editable here, out of the way of the real ones.
MISC = PAGE_TEMPLATE % render([
    ["NoticeBox {", "    Layout.fillWidth: true",
     "    text: %s" % tr("Nothing in the shell reads these options, so changing them has no effect. They are only here so that every entry of the config file has a control."),
     "}"],
    [""],
    section("Unused options", "block",
            spin("bar.workspaces.showNumberDelay", "Bar: workspace number delay, superseded by Super hold delay (ms)", 0, 1000, 50,
                 icon="touch_long"),
            switch("background.widgets.clock.cookie.dateInClock", "Cookie clock: date inside the clock", "event"),
            text("language.translator.engine", "Translator engine"),
            switch("sidebar.booru.allowNsfw", "Anime boards: allow NSFW", "explicit",
                   tooltip="The sidebar keeps its own NSFW toggle and ignores this one"),
            text("sidebar.booru.defaultProvider", "Anime boards: default provider")),
], 4)

# Stock controls for unused options, cut from their page (they live in Misc instead)
REMOVE = {
    "BarConfig.qml": [('text: Translation.tr("Number show delay when pressing Super (ms)")', "ConfigSpinBox {")],
}

REPLACE = {
    "InterfaceConfig.qml": [("notifications.forceMonitor.", "notifications.monitor.")],
    "About.qml": [("import Quickshell\n", "import Quickshell\nimport Quickshell.Io\n"),
                  ("textFormat: Text.MarkdownText\n",
                   "textFormat: Text.MarkdownText\n                    linkColor: Appearance.colors.colPrimary\n")],
}

# Shorter, consistently styled section titles and US spelling (matching the stock text)
RENAME = [
    ('Translation.tr("Region selector (screen snipping/Google Lens)")', 'Translation.tr("Region selector")'),
    ('Translation.tr("Widget: Clock")', 'Translation.tr("Clock widget")'),
    ('Translation.tr("Widget: Weather")', 'Translation.tr("Weather widget")'),
    ('Translation.tr("Overlay: General")', 'Translation.tr("Overlay")'),
    ('Translation.tr("Overlay: Crosshair")', 'Translation.tr("Crosshair overlay")'),
    ('Translation.tr("Overlay: Floating Image")', 'Translation.tr("Floating image overlay")'),
    ('Translation.tr("System updates (Arch only)")', 'Translation.tr("System updates")'),
    ("Colour", "Color"), ("colour", "color"), ("behaviour", "behavior"), ("centre ", "center "),
]

TEXTAREA = re.compile(
    r'(?P<ind>[ ]*)MaterialTextArea \{\n'
    r'(?:\s*Layout\.fillWidth: true\n)?'
    r'\s*placeholderText: (?P<ph>.*)\n'
    r'\s*text: Config\.options\.(?P<key>[\w.]+)\n'
    r'(?:\s*wrapMode: .*\n)?'
    r'\s*onTextChanged: \{\n'
    r'(?:\s*Qt\.callLater\(\(\) => \{\n)?'
    r'\s*Config\.options\.(?P=key) = text;\n'
    r'(?:\s*\}\);\n)?'
    r'\s*\}\n'
    r'(?P=ind)\}')
SPINBOX = re.compile(
    r'(?P<ind>[ ]*)ConfigSpinBox \{\n'
    r'(?:\s*icon: .*\n)?'
    r'\s*text: (?P<text>.*)\n'
    r'\s*value: Config\.options\.(?P<key>[\w.]+)(?P<mul> \* 100)?\n'
    r'\s*from: (?P<lo>.*)\n'
    r'\s*to: (?P<hi>.*)\n'
    r'\s*stepSize: (?P<step>.*)\n'
    r'\s*onValueChanged: \{\n'
    r'\s*Config\.options\.(?P=key) ?= ?value(?P<div> / 100)?;\n'
    r'\s*\}\n'
    r'(?P=ind)\}')
UNIT = re.compile(r'^(?P<ind> *)text: Translation\.tr\("(?P<label>.*) \((?P<unit>ms|s|m|mins|seconds|%|px|K)\)"\)$')
UNIT_NAMES = {"m": "min", "mins": "min", "seconds": "s"}
ROW_ICON = re.compile(r'^ {12,}(buttonIcon|icon): "[^"]*"$')


def polish(src):
    """Restyle a page: unified row components, no per-row icons, units as suffixes, cards."""
    def textarea(m):
        i = m.group("ind")
        return (f'{i}OptText {{\n{i}    key: "{m.group("key")}"\n{i}    placeholderText: {m.group("ph")}\n'
                f'{i}    wide: true\n{i}}}')

    def spinbox(m):
        if bool(m.group("mul")) != bool(m.group("div")):
            return m.group(0)
        i = m.group("ind")
        scale = f"{i}    scale: 100\n" if m.group("mul") else ""
        return (f'{i}OptSpin {{\n{i}    key: "{m.group("key")}"\n{i}    text: {m.group("text")}\n'
                f'{i}    from: {m.group("lo")}\n{i}    to: {m.group("hi")}\n{i}    stepSize: {m.group("step")}\n'
                f'{scale}{i}}}')

    src = TEXTAREA.sub(textarea, src)
    src = SPINBOX.sub(spinbox, src)
    out = []
    for line in src.split("\n"):
        if ROW_ICON.match(line) and not (out and out[-1].rstrip().endswith(",")):
            continue  # per-row icon; icons inside option lists (previous line ends with a comma) stay
        m = UNIT.match(line)
        if m:
            unit = UNIT_NAMES.get(m.group("unit"), m.group("unit"))
            out.append(f'{m.group("ind")}text: Translation.tr("{m.group("label")}")')
            out.append(f'{m.group("ind")}suffix: "{unit}"')
            continue
        out.append(line)
    src = "\n".join(out).replace("ContentSection {", "SettingsSection {")
    for a, b in RENAME:
        src = src.replace(a, b)
    return src


LABEL = re.compile(r'^ {9,}(?:text|placeholderText|mainText|label|title): Translation\.tr\("(.*)"\)$')
SECTION_TITLE = re.compile(r'^        title: Translation\.tr\("(.*)"\)$')
INDEX = []


def index_page(name, src):
    """Collect every label of a page for the search field."""
    section, seen, prev = None, set(), ""
    for line in src.split("\n"):
        m = SECTION_TITLE.match(line)
        if m:
            section = m.group(1).replace('\\"', '"')
            INDEX.append({"page": f"modules/settings/{name}", "section": section, "label": section})
        else:
            m = LABEL.match(line)
            if m and section and not prev.strip().startswith("StyledToolTip") and "%1" not in m.group(1):
                label = m.group(1).replace('\\"', '"').replace("\\n", " ")
                if (section, label) not in seen and label != section:
                    seen.add((section, label))
                    INDEX.append({"page": f"modules/settings/{name}", "section": section, "label": label})
        if line.strip():
            prev = line


def emit(name, src):
    src = polish(src)
    index_page(name, src)
    (DST / name).write_text(src)
    print(f"wrote {DST / name}")

BLOCK_START = re.compile(r"^    [A-Za-z].*\{\s*$")
TITLE = re.compile(r'^        title: Translation\.tr\("(.*)"\)\s*$')


def split_page(src):
    lines = src.split("\n")
    first = next(i for i, l in enumerate(lines) if BLOCK_START.match(l))
    header, blocks, i = lines[:first], [], first
    while i < len(lines):
        if BLOCK_START.match(lines[i]):
            j = i
            while lines[j] != "    }":
                j += 1
            blocks.append(lines[i:j + 1])
            i = j + 1
        else:
            i += 1
    return header, blocks


def build(name, plan):
    src = (SRC / name).read_text()
    for a, b in REPLACE.get(name, []):
        src = src.replace(a, b)
    for marker, opener in REMOVE.get(name, []):
        lines = src.split("\n")
        at = next(i for i, l in enumerate(lines) if marker in l)
        start = max(i for i in range(at) if lines[i].strip() == opener)
        closing = lines[start].replace(opener, "}")
        end = next(i for i in range(at, len(lines)) if lines[i] == closing)
        del lines[start:end + 1]
        src = "\n".join(lines)
    header, blocks = split_page(src)
    if "import QtQuick.Layouts" not in src:
        header.insert(1, "import QtQuick.Layouts")
    header.insert(header.index("import qs.modules.common.widgets") + 1, "import qs.modules.settings")
    sections, other = {}, []
    for b in blocks:
        title = next((m.group(1) for m in map(TITLE.match, b) if m), None)
        if b[0].strip().startswith("ContentSection") and title:
            sections[title] = b
        else:
            other.append(b)
    out = list(header)
    while out and not out[-1].strip():
        out.pop()
    for b in other:
        if not b[0].strip().startswith("NoticeBox"):  # the "not all options are here" notice is obsolete
            out += [""] + b
    for title, payload in plan:
        if title == "+":
            body = render([payload], 4).split("\n")
        else:
            body = list(sections.pop(title))
            if payload:
                body[-1:] = [""] + render(payload, 8).split("\n") + ["    }"]
        out += [""] + body
    if sections:
        sys.exit(f"{name}: sections not placed: {list(sections)}")
    out += ["}", ""]
    emit(name, "\n".join(out))


for page, plan in PAGES.items():
    build(page, plan)
emit("WaffleConfig.qml", WAFFLE)
emit("MiscConfig.qml", MISC)
# Displays is written by hand (patched/ is its source): only index it and copy it
DISPLAYS = HERE / "patched" / "modules" / "settings" / "DisplaysConfig.qml"
index_page("DisplaysConfig.qml", DISPLAYS.read_text())
(DST / "DisplaysConfig.qml").write_text(DISPLAYS.read_text())

import json  # noqa: E402
(DST / "SearchIndex.qml").write_text(
    "import QtQuick\n\n// Generated by apply.py: every label of every settings page, for the search field\n"
    "QtObject {\n    readonly property var entries: " + json.dumps(INDEX, indent=4).replace("\n", "\n    ") + "\n}\n")
print(f"wrote {DST / 'SearchIndex.qml'} ({len(INDEX)} entries)")
