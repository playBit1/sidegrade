import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings

// Displays: arrange monitors by dragging, pick resolution, refresh rate, scale and rotation.
// Apply writes ~/.config/hypr/monitors.lua (through scripts/settings-rework/displays.sh) and
// reloads Hyprland; the previous settings come back unless "Keep" is pressed in time.
ContentPage {
    id: page
    forceWidth: true

    readonly property string script: Quickshell.shellPath("scripts/settings-rework/displays.sh")
    readonly property int confirmSeconds: 15

    property var displays: [] // What is being edited
    property var reported: [] // What Hyprland has right now
    property var savedLines: ({}) // monitors.lua lines by output name, to keep those of unplugged displays
    property int current: 0
    property bool loaded: false
    property bool confirming: false
    property int secondsLeft: 0
    property var expected: null // Set by Apply: what the next state read is checked against
    property string problem: ""
    property bool identifying: false

    // Arrangement view: layout pixels -> canvas pixels
    property real viewScale: 0.08
    property real viewX: 0
    property real viewY: 0
    property int dragIndex: -1
    property real dragX: 0
    property real dragY: 0

    readonly property var cur: displays[current] ?? null
    readonly property int enabledCount: displays.filter(d => d.enabled).length
    readonly property bool dirty: loaded && JSON.stringify(displays.map(fingerprint)) !== JSON.stringify(reported.map(fingerprint))

    function fingerprint(d) {
        return d.enabled ? [d.name, d.width, d.height, d.rate, d.x, d.y, d.scale, d.transform, d.vrr] : [d.name, false];
    }

    // ---------------------------------------------------------------- geometry
    function rectOf(d) { // In layout pixels: scaled, and turned if the display is rotated
        const w = Math.round(d.width / d.scale), h = Math.round(d.height / d.scale);
        return d.transform % 2 === 1 ? { x: d.x, y: d.y, w: h, h: w } : { x: d.x, y: d.y, w: w, h: h };
    }
    function overlaps(a, b) {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    }
    function touches(a, b) { // Share part of an edge, so the pointer can cross
        const sideBySide = (a.x + a.w === b.x || b.x + b.w === a.x) && a.y < b.y + b.h && b.y < a.y + a.h;
        const stacked = (a.y + a.h === b.y || b.y + b.h === a.y) && a.x < b.x + b.w && b.x < a.x + a.w;
        return sideBySide || stacked;
    }
    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v));
    }

    // Moves display i to the nearest spot where it touches one of `placed` and overlaps none
    function settle(list, i, placed) {
        if (placed.length === 0) return;
        const r = rectOf(list[i]);
        const others = placed.map(j => rectOf(list[j]));
        if (!others.some(o => overlaps(r, o)) && others.some(o => touches(r, o))) return;
        let best = null;
        for (const o of others) {
            const shareY = Math.round(Math.min(r.h, o.h) / 4), shareX = Math.round(Math.min(r.w, o.w) / 4);
            const y = clamp(r.y, o.y - r.h + shareY, o.y + o.h - shareY);
            const x = clamp(r.x, o.x - r.w + shareX, o.x + o.w - shareX);
            for (const c of [[o.x + o.w, y], [o.x - r.w, y], [x, o.y + o.h], [x, o.y - r.h]]) {
                const moved = { x: c[0], y: c[1], w: r.w, h: r.h };
                if (others.some(p => overlaps(moved, p))) continue;
                const distance = (moved.x - r.x) ** 2 + (moved.y - r.y) ** 2;
                if (!best || distance < best.distance) best = { x: moved.x, y: moved.y, distance: distance };
            }
        }
        if (!best) best = { x: Math.max(...others.map(o => o.x + o.w)), y: others[0].y };
        list[i].x = Math.round(best.x);
        list[i].y = Math.round(best.y);
    }

    // Keeps `anchor` where it is and closes gaps / removes overlaps around it; top-left ends at 0,0
    function relayout(list, anchor) {
        const placed = [anchor];
        const rest = list.map((d, i) => i).filter(i => i !== anchor && list[i].enabled)
            .sort((a, b) => list[a].x - list[b].x || list[a].y - list[b].y);
        for (const i of rest) {
            settle(list, i, placed);
            placed.push(i);
        }
        const active = list.filter(d => d.enabled);
        const minX = Math.min(...active.map(d => d.x)), minY = Math.min(...active.map(d => d.y));
        for (const d of active) {
            d.x -= minX;
            d.y -= minY;
        }
    }

    function fitView() {
        const rects = displays.filter(d => d.enabled).map(rectOf);
        if (rects.length === 0 || canvas.width <= 0) return;
        const minX = Math.min(...rects.map(r => r.x)), minY = Math.min(...rects.map(r => r.y));
        const w = Math.max(...rects.map(r => r.x + r.w)) - minX, h = Math.max(...rects.map(r => r.y + r.h)) - minY;
        const pad = 28;
        viewScale = Math.min((canvas.width - pad * 2) / w, (canvas.height - pad * 2) / h, 0.085);
        viewX = (canvas.width - w * viewScale) / 2 - minX * viewScale;
        viewY = (canvas.height - h * viewScale) / 2 - minY * viewScale;
    }

    // While dragging: line up with the edges and centers of the other displays
    function snapped(index, x, y) {
        const r = rectOf(displays[index]);
        const reach = 14 / viewScale;
        let bestX = x, bestY = y, gapX = reach, gapY = reach;
        displays.forEach((d, i) => {
            if (i === index || !d.enabled) return;
            const o = rectOf(d);
            for (const c of [o.x - r.w, o.x + o.w, o.x, o.x + o.w - r.w, o.x + (o.w - r.w) / 2]) {
                if (Math.abs(c - x) < gapX) { gapX = Math.abs(c - x); bestX = c; }
            }
            for (const c of [o.y - r.h, o.y + o.h, o.y, o.y + o.h - r.h, o.y + (o.h - r.h) / 2]) {
                if (Math.abs(c - y) < gapY) { gapY = Math.abs(c - y); bestY = c; }
            }
        });
        return { x: Math.round(bestX), y: Math.round(bestY) };
    }

    // ---------------------------------------------------------------- edits
    function edit(change, anchor) {
        const next = displays.map(d => Object.assign({}, d));
        change(next);
        relayout(next, anchor === undefined ? current : anchor);
        displays = next;
        fitView();
    }
    function drop(index, x, y) {
        const next = displays.map(d => Object.assign({}, d));
        next[index].x = x;
        next[index].y = y;
        const others = next.map((d, i) => i).filter(i => i !== index && next[i].enabled);
        settle(next, index, others);
        relayout(next, others.length > 0 ? others[0] : index);
        displays = next;
        fitView();
    }
    function setResolution(w, h) {
        const rates = cur.modes.filter(m => m.w === w && m.h === h).map(m => m.rate);
        const rate = rates.includes(cur.rate) ? cur.rate : (rates[0] ?? cur.rate);
        edit(list => {
            const d = list[current];
            d.width = w;
            d.height = h;
            d.rate = rate;
            d.scale = snapScale(w, h, d.scale);
        });
    }
    function setEnabled(on) {
        const other = displays.findIndex((d, i) => i !== current && d.enabled);
        edit(list => {
            const d = list[current];
            d.enabled = on;
            if (!on) return;
            if (d.width === 0 && d.modes.length > 0) { // Was off when the page opened: start from its first mode
                d.width = d.modes[0].w;
                d.height = d.modes[0].h;
                d.rate = d.modes[0].rate;
                d.scale = 1;
            }
            const rects = list.filter((o, i) => i !== current && o.enabled).map(rectOf);
            d.x = rects.length > 0 ? Math.max(...rects.map(r => r.x + r.w)) : 0;
            d.y = 0;
        }, other >= 0 ? other : current);
    }

    // ---------------------------------------------------------------- modes and scales
    function resolutions(d) {
        let seen = {}, result = [];
        for (const m of d.modes) {
            const key = `${m.w}x${m.h}`;
            if (seen[key]) continue;
            seen[key] = true;
            result.push({ displayName: `${m.w} × ${m.h}`, w: m.w, h: m.h });
        }
        if (!seen[`${d.width}x${d.height}`]) result.push({ displayName: `${d.width} × ${d.height}`, w: d.width, h: d.height });
        return result.sort((a, b) => b.w * b.h - a.w * a.h || b.w - a.w);
    }
    function rates(d) {
        let list = d.modes.filter(m => m.w === d.width && m.h === d.height).map(m => m.rate);
        if (!list.includes(d.rate)) list.push(d.rate);
        list = list.filter((r, i) => list.indexOf(r) === i).sort((a, b) => Number(b) - Number(a));
        return list.map(r => ({ displayName: `${r} Hz`, value: r }));
    }
    // Hyprland only takes scales that divide the resolution into whole pixels (in steps of 1/120)
    function snapScale(w, h, wanted) {
        const target = Math.round(wanted * 120);
        for (let i = 0; i < 60; i++) {
            for (const n of [target + i, target - i]) {
                if (n > 0 && (w * 120) % n === 0 && (h * 120) % n === 0) return n / 120;
            }
        }
        return 1;
    }
    function scales(d) {
        let list = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3].map(s => snapScale(d.width, d.height, s));
        list.push(d.scale);
        list = list.filter((s, i) => list.findIndex(o => Math.abs(o - s) < 0.001) === i).sort((a, b) => a - b);
        return list.map(s => ({ displayName: `${Math.round(s * 100)}%`, value: s }));
    }

    // ---------------------------------------------------------------- reading and writing
    function parseState(text) {
        const parts = text.split("\n@@monitors.lua@@\n");
        let monitors = [];
        try {
            monitors = JSON.parse(parts[0]);
        } catch (e) {
            page.problem = Translation.tr("Could not read the displays from Hyprland.");
            return;
        }
        let lines = {}, vrr = {};
        for (const line of (parts[1] ?? "").split("\n")) {
            const m = line.match(/^\s*hl\.monitor\(\{\s*output\s*=\s*"([^"]+)"/);
            if (!m) continue;
            lines[m[1]] = line.trim();
            const v = line.match(/\bvrr\s*=\s*(\d)/);
            if (v) vrr[m[1]] = Number(v[1]);
        }
        let list = monitors.map(m => {
            const modes = (m.availableModes ?? []).map(s => s.match(/^(\d+)x(\d+)@([\d.]+)Hz$/)).filter(x => x)
                .map(x => ({ w: Number(x[1]), h: Number(x[2]), rate: x[3] }));
            const same = modes.filter(o => o.w === m.width && o.h === m.height)
                .sort((a, b) => Math.abs(Number(a.rate) - m.refreshRate) - Math.abs(Number(b.rate) - m.refreshRate));
            return {
                name: m.name,
                label: m.model || m.name,
                description: [m.make, m.model].filter(part => part).join(" ") || m.name, // m.description also has the serial number
                enabled: !m.disabled,
                width: m.width,
                height: m.height,
                rate: same.length > 0 ? same[0].rate : m.refreshRate.toFixed(2),
                x: m.x,
                y: m.y,
                scale: m.disabled || m.width === 0 ? 1 : snapScale(m.width, m.height, m.scale),
                transform: m.transform,
                vrr: vrr[m.name] ?? -1, // -1: not set here, Hyprland's general setting applies
                vrrCapable: m.hardwareDetails?.vrrCapable ?? true,
                modes: modes
            };
        });
        // Numbered the way they sit on the desk: left to right, then top to bottom; switched-off ones last
        list.sort((a, b) => (b.enabled - a.enabled) || a.x - b.x || a.y - b.y);
        list.forEach((d, i) => d.number = i + 1);

        const keep = page.cur?.name;
        page.savedLines = lines;
        page.reported = list;
        page.displays = list.map(d => Object.assign({}, d));
        page.current = Math.max(0, list.findIndex(d => d.name === keep));
        page.loaded = true;
        page.fitView();

        if (page.expected !== null) {
            const taken = JSON.stringify(list.map(page.fingerprint).sort()) === page.expected;
            page.expected = null;
            if (!taken) page.revert(); // Nothing to keep: put the file back right away
            page.problem = taken ? "" : Translation.tr("Hyprland did not take all of these settings. Another monitor line in your Hyprland config (hyprland.lua or a file in custom/) may come after ~/.config/hypr/monitors.lua and override it.");
        }
    }

    function luaFile() {
        const names = displays.map(d => d.name);
        let out = ["-- Written by Settings > Displays (ii Settings Rework). Pressing Apply there rewrites this file."];
        for (const d of displays) {
            if (!d.enabled) {
                out.push(`hl.monitor({ output = "${d.name}", disabled = true })`);
                continue;
            }
            const vrr = d.vrr >= 0 ? `, vrr = ${d.vrr}` : "";
            out.push(`hl.monitor({ output = "${d.name}", mode = "${d.width}x${d.height}@${d.rate}", position = "${d.x}x${d.y}", `
                + `scale = ${Number(d.scale.toFixed(6))}, transform = ${d.transform}${vrr} })`);
        }
        for (const name in savedLines) { // Displays that are not plugged in right now keep their line
            if (!names.includes(name)) out.push(savedLines[name]);
        }
        return out.join("\n") + "\n";
    }

    function refresh() {
        stateProc.running = true;
    }
    function apply() {
        page.problem = "";
        page.expected = JSON.stringify(displays.map(fingerprint).sort());
        actionProc.command = ["bash", page.script, "apply", String(page.confirmSeconds + 3), luaFile()];
        actionProc.running = true;
        page.secondsLeft = page.confirmSeconds;
        page.confirming = true;
    }
    function keep() {
        page.confirming = false;
        Quickshell.execDetached(["bash", page.script, "keep"]);
    }
    function revert() {
        page.confirming = false;
        page.expected = null;
        page.problem = "";
        actionProc.command = ["bash", page.script, "revert"];
        actionProc.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: stateProc
        command: ["bash", page.script, "state"]
        stdout: StdioCollector {
            onStreamFinished: page.parseState(text)
        }
    }
    Process { // apply / revert; Hyprland needs a moment to switch modes before it is asked again
        id: actionProc
        onExited: settleTimer.restart()
    }
    Timer {
        id: settleTimer
        interval: 1500
        onTriggered: page.refresh()
    }
    Timer {
        interval: 1000
        repeat: true
        running: page.confirming
        onTriggered: {
            page.secondsLeft -= 1;
            if (page.secondsLeft <= 0) page.revert();
        }
    }
    Timer {
        id: identifyTimer
        interval: 2500
        onTriggered: page.identifying = false
    }

    Variants { // "Identify": the number of each display, shown on that display
        model: page.identifying ? Quickshell.screens : []
        PanelWindow {
            id: badge
            required property var modelData
            readonly property var display: page.displays.find(d => d.name === badge.modelData.name)
            screen: modelData
            visible: display !== undefined
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:displayIdentify"
            anchors {
                left: true
                bottom: true
            }
            margins {
                left: 40
                bottom: 40
            }
            implicitWidth: 170
            implicitHeight: 170
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Appearance.colors.colPrimaryContainer
                border.width: 2
                border.color: Appearance.colors.colPrimary
                StyledText {
                    anchors.centerIn: parent
                    text: badge.display?.number ?? ""
                    color: Appearance.colors.colOnPrimaryContainer
                    font.family: Appearance.font.family.title
                    font.pixelSize: 96
                    font.weight: Font.Medium
                }
            }
        }
    }

    component LabeledRow: RowLayout {
        property string label
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 10
        StyledText {
            Layout.fillWidth: true
            text: parent.label
            color: Appearance.colors.colOnSecondaryContainer
        }
    }

    component Choice: StyledComboBox {
        Layout.fillWidth: false
        Layout.preferredWidth: 220
        textRole: "displayName"
    }

    NoticeBox {
        visible: page.confirming
        Layout.fillWidth: true
        materialIcon: "timer"
        text: Translation.tr("Keep these display settings? The previous ones come back in %1 s.").arg(page.secondsLeft)
        RippleButtonWithIcon {
            materialIcon: "check"
            mainText: Translation.tr("Keep")
            onClicked: page.keep()
        }
        RippleButtonWithIcon {
            materialIcon: "undo"
            mainText: Translation.tr("Go back")
            onClicked: page.revert()
        }
    }

    NoticeBox {
        visible: page.problem.length > 0
        Layout.fillWidth: true
        materialIcon: "warning"
        text: page.problem
    }

    SettingsSection {
        icon: "monitor"
        title: Translation.tr("Arrangement")

        Rectangle {
            id: canvas
            Layout.fillWidth: true
            implicitHeight: 270
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer2
            clip: true
            onWidthChanged: page.fitView()

            Repeater {
                model: page.displays
                Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property var box: page.rectOf(modelData)
                    readonly property bool selected: page.current === index
                    readonly property bool dragged: page.dragIndex === index
                    visible: modelData.enabled
                    x: page.viewX + (dragged ? page.dragX : box.x) * page.viewScale
                    y: page.viewY + (dragged ? page.dragY : box.y) * page.viewScale
                    z: dragged ? 2 : selected ? 1 : 0
                    width: box.w * page.viewScale
                    height: box.h * page.viewScale
                    radius: Appearance.rounding.verysmall
                    color: selected ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer3
                    border.width: selected ? 2 : 1
                    border.color: selected ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    opacity: dragged ? 0.85 : 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        spacing: 0
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: tile.modelData.number
                            color: tile.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer3
                            font.family: Appearance.font.family.title
                            font.pixelSize: Math.max(18, Math.min(40, tile.height * 0.3))
                            font.weight: Font.Medium
                        }
                        StyledText {
                            visible: tile.height > 80
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: tile.modelData.label
                            color: tile.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer3
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                        StyledText {
                            visible: tile.height > 100
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: `${tile.modelData.width} × ${tile.modelData.height}`
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }

                    MouseArea {
                        property point pressAt
                        anchors.fill: parent
                        preventStealing: true
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        onPressed: mouse => {
                            page.current = tile.index;
                            pressAt = mapToItem(canvas, mouse.x, mouse.y);
                            page.dragX = tile.box.x;
                            page.dragY = tile.box.y;
                            if (page.enabledCount > 1 && !page.confirming) page.dragIndex = tile.index;
                        }
                        onPositionChanged: mouse => {
                            if (!tile.dragged) return;
                            const now = mapToItem(canvas, mouse.x, mouse.y);
                            const spot = page.snapped(tile.index, tile.box.x + (now.x - pressAt.x) / page.viewScale,
                                tile.box.y + (now.y - pressAt.y) / page.viewScale);
                            page.dragX = spot.x;
                            page.dragY = spot.y;
                        }
                        onReleased: {
                            if (!tile.dragged) return;
                            const moved = page.dragX !== tile.box.x || page.dragY !== tile.box.y;
                            page.dragIndex = -1;
                            if (moved) page.drop(tile.index, page.dragX, page.dragY);
                        }
                        onCanceled: page.dragIndex = -1
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.topMargin: 4
            spacing: 6
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: page.dirty ? Translation.tr("Changes are not applied yet")
                    : page.enabledCount > 1 ? Translation.tr("Drag displays to arrange them")
                    : Translation.tr("Select a display to change its settings")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
            }
            RippleButtonWithIcon {
                materialIcon: "pin"
                mainText: Translation.tr("Identify")
                onClicked: {
                    page.identifying = true;
                    identifyTimer.restart();
                }
            }
            RippleButtonWithIcon {
                enabled: page.dirty && !page.confirming
                opacity: enabled ? 1 : 0.4
                materialIcon: "undo"
                mainText: Translation.tr("Reset")
                onClicked: {
                    page.displays = page.reported.map(d => Object.assign({}, d));
                    page.fitView();
                }
            }
            RippleButton {
                id: applyButton
                enabled: page.dirty && !page.confirming
                opacity: enabled ? 1 : 0.4
                implicitHeight: 35
                horizontalPadding: 14
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colPrimaryHover
                colRipple: Appearance.colors.colPrimaryActive
                onClicked: page.apply()
                contentItem: RowLayout {
                    spacing: 6
                    MaterialSymbol {
                        text: "check"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnPrimary
                    }
                    StyledText {
                        text: Translation.tr("Apply")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
        }
    }

    SettingsSection {
        visible: page.cur !== null
        icon: "display_settings"
        title: Translation.tr("Display")

        ConfigSelectionArray {
            Layout.leftMargin: 4
            currentValue: page.current
            onSelected: newValue => page.current = newValue
            options: page.displays.map((d, i) => ({ displayName: `${d.number}  ${d.label}`, icon: d.enabled ? "monitor" : "desktop_access_disabled", value: i }))
        }
        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.bottomMargin: 4
            elide: Text.ElideRight
            text: page.cur ? `${page.cur.description} · ${page.cur.name}` : ""
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
        }

        ConfigSwitch {
            buttonIcon: ""
            enabled: !page.confirming && !(page.cur?.enabled && page.enabledCount <= 1)
            text: Translation.tr("Use this display")
            checked: page.cur?.enabled ?? false
            onCheckedChanged: {
                if (page.cur && checked !== page.cur.enabled) page.setEnabled(checked);
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            enabled: (page.cur?.enabled ?? false) && !page.confirming
            opacity: enabled ? 1 : 0.4

            LabeledRow {
                label: Translation.tr("Resolution")
                Choice {
                    model: page.cur ? page.resolutions(page.cur) : []
                    currentIndex: model.findIndex(o => o.w === page.cur?.width && o.h === page.cur?.height)
                    onActivated: index => page.setResolution(model[index].w, model[index].h)
                }
            }
            LabeledRow {
                label: Translation.tr("Refresh rate")
                Choice {
                    model: page.cur ? page.rates(page.cur) : []
                    currentIndex: model.findIndex(o => o.value === page.cur?.rate)
                    onActivated: index => {
                        const rate = model[index].value;
                        page.edit(list => list[page.current].rate = rate);
                    }
                }
            }
            LabeledRow {
                label: Translation.tr("Scale")
                Choice {
                    model: page.cur ? page.scales(page.cur) : []
                    currentIndex: model.findIndex(o => Math.abs(o.value - (page.cur?.scale ?? 1)) < 0.001)
                    onActivated: index => {
                        const scale = model[index].value;
                        page.edit(list => list[page.current].scale = scale);
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Orientation")
                ConfigSelectionArray {
                    currentValue: page.cur?.transform ?? 0
                    onSelected: newValue => page.edit(list => list[page.current].transform = newValue)
                    options: [
                        { displayName: Translation.tr("Landscape"), icon: "crop_landscape", value: 0 },
                        { displayName: Translation.tr("Portrait"), icon: "crop_portrait", value: 1 },
                        { displayName: Translation.tr("Landscape, flipped"), icon: "crop_landscape", value: 2 },
                        { displayName: Translation.tr("Portrait, flipped"), icon: "crop_portrait", value: 3 }
                    ]
                }
            }

            ContentSubsection {
                visible: page.cur?.vrrCapable ?? false
                title: Translation.tr("Variable refresh rate")
                tooltip: Translation.tr("Default leaves it to Hyprland's general setting (misc.vrr)")
                ConfigSelectionArray {
                    currentValue: page.cur?.vrr ?? -1
                    onSelected: newValue => page.edit(list => list[page.current].vrr = newValue)
                    options: [
                        { displayName: Translation.tr("Default"), value: -1 },
                        { displayName: Translation.tr("Off"), value: 0 },
                        { displayName: Translation.tr("On"), value: 1 },
                        { displayName: Translation.tr("Fullscreen only"), value: 2 }
                    ]
                }
            }
        }
    }
}
