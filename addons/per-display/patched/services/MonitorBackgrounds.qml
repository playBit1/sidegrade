pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * What individual monitors show on their background (ii Settings Rework).
 *
 * A monitor can have its own wallpaper, and its own copy of the widget (clock, weather) and
 * parallax settings. Without them it uses Config.options.background, like every monitor does
 * in the stock shell. Colors are always generated from the main wallpaper.
 *
 * Kept in its own file so the settings app and the shell, which are separate processes,
 * both follow it:
 *   { "HDMI-A-1": { "wallpaperPath": "/path/image.jpg", "settings": { "widgets": {...}, "parallax": {...} } } }
 */
Singleton {
    id: root
    readonly property string filePath: `${Directories.shellConfig}/monitor-backgrounds.json`
    readonly property var groups: ["widgets", "parallax"] // The parts of background a monitor can have its own copy of
    property var displays: ({}) // Monitor name (like "DP-1") -> { wallpaperPath, settings }, both optional

    // ---------------------------------------------------------------- reading
    function wallpaperFor(monitorName) {
        return root.displays[monitorName]?.wallpaperPath ?? "";
    }
    function hasOwnSettings(monitorName) {
        return root.displays[monitorName]?.settings !== undefined;
    }
    // Use only .widgets and .parallax of the result
    function optionsFor(monitorName) {
        return root.displays[monitorName]?.settings ?? Config.options.background;
    }

    // ---------------------------------------------------------------- writing
    function setWallpaper(monitorName, path) {
        root.change(next => {
            let entry = next[monitorName] ?? {};
            if (path && path.length > 0) entry.wallpaperPath = path;
            else delete entry.wallpaperPath;
            next[monitorName] = entry;
        });
    }
    // On: the monitor starts from a copy of the shared settings. Off: its copy is dropped
    function setOwnSettings(monitorName, own) {
        if (own === root.hasOwnSettings(monitorName)) return;
        root.change(next => {
            let entry = next[monitorName] ?? {};
            if (own) entry.settings = root.sharedCopy();
            else delete entry.settings;
            next[monitorName] = entry;
        });
    }
    // key is relative to background, like "widgets.clock.x". Goes to the monitor's own copy
    // if it has one, to the shared settings otherwise
    function write(monitorName, key, value) {
        const keys = key.split(".");
        const last = keys.pop();
        const own = root.hasOwnSettings(monitorName);
        const holder = keys.reduce((o, k) => o?.[k], own ? root.displays[monitorName].settings : Config.options.background);
        if (holder === undefined || holder === null) return;
        const current = holder[last];
        if (current === value) return;
        if (typeof value === "number" && typeof current === "number" && Math.abs(current - value) < 1e-9) return;
        if (!own) {
            holder[last] = value;
            return;
        }
        root.change(next => {
            keys.reduce((o, k) => o[k], next[monitorName].settings)[last] = value;
        });
    }

    function change(edit) {
        let next = JSON.parse(JSON.stringify(root.displays));
        edit(next);
        for (const name in next) {
            if (Object.keys(next[name]).length === 0) delete next[name];
        }
        root.displays = next;
        saveTimer.restart();
    }

    // ---------------------------------------------------------------- settings app
    // Which settings the Background page is editing: a monitor name, or "" for the shared ones
    property string editing: ""
    readonly property var edited: root.optionsFor(root.editing)
    readonly property bool editable: root.editing.length === 0 || root.hasOwnSettings(root.editing)

    // For the option rows, which use full option paths like "background.widgets.clock.x"
    readonly property var editedRoot: ({ background: root.edited })
    function writeEdited(key, value) {
        if (root.editable) root.write(root.editing, key.split(".").slice(1).join("."), value);
    }

    // ---------------------------------------------------------------- file
    function plain(object) { // A config object as plain data
        let out = {};
        for (const key in object) {
            const value = object[key];
            if (key === "objectName" || typeof value === "function") continue;
            out[key] = (value !== null && typeof value === "object") ? root.plain(value) : value;
        }
        return out;
    }
    function sharedCopy() {
        let out = {};
        for (const group of root.groups) out[group] = root.plain(Config.options.background[group]);
        return out;
    }
    function fill(own, base) { // Options added by a shell update start at the shared value
        for (const key in base) {
            const nested = base[key] !== null && typeof base[key] === "object";
            if (own[key] === undefined || (nested && (own[key] === null || typeof own[key] !== "object"))) own[key] = base[key];
            else if (nested) root.fill(own[key], base[key]);
        }
        return own;
    }

    Timer { // Sliders write many times a second
        id: saveTimer
        interval: 80
        onTriggered: fileView.setText(JSON.stringify(root.displays, null, 2) + "\n")
    }

    FileView {
        id: fileView
        path: root.filePath
        watchChanges: true
        printErrors: false // The file only exists once a monitor has something of its own
        onFileChanged: reload()
        onLoaded: {
            if (saveTimer.running) return; // About to be overwritten by what is in memory
            let parsed = {};
            try {
                parsed = JSON.parse(fileView.text());
            } catch (e) {
                console.log("[MonitorBackgrounds] Could not read", root.filePath, e);
                return; // Keep what is shown rather than dropping everything over a typo
            }
            let next = {};
            for (const name in parsed) {
                const entry = parsed[name];
                if (entry === null || typeof entry !== "object") continue;
                let clean = {};
                if (typeof entry.wallpaperPath === "string" && entry.wallpaperPath.length > 0) clean.wallpaperPath = entry.wallpaperPath;
                if (entry.settings !== null && typeof entry.settings === "object") clean.settings = root.fill(entry.settings, root.sharedCopy());
                if (Object.keys(clean).length > 0) next[name] = clean;
            }
            if (JSON.stringify(next) !== JSON.stringify(root.displays)) root.displays = next;
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound && !saveTimer.running) root.displays = {};
        }
    }
}
