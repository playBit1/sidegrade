import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// JSON editor for a list-of-objects config option. Only saves while the text is a valid JSON array.
ColumnLayout {
    id: root
    required property string key
    property string label: ""
    property bool ready: false
    property bool valid: true
    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    spacing: 2

    function read() {
        return key.split(".").reduce((o, k) => o?.[k], Config.options);
    }
    function write(entries) {
        const ks = key.split(".");
        const last = ks.pop();
        const o = ks.reduce((o, k) => o[k], Config.options);
        if (JSON.stringify(Array.from(o[last] ?? [])) !== JSON.stringify(entries)) o[last] = entries;
    }

    StyledText {
        Layout.fillWidth: true
        text: root.label
        color: Appearance.colors.colSubtext
        font.pixelSize: Appearance.font.pixelSize.smaller
    }
    OptField {
        id: area
        Layout.fillWidth: true
        font.family: Appearance.font.family.monospace
        onTextChanged: {
            if (!root.ready) return;
            try {
                const parsed = JSON.parse(text);
                root.valid = Array.isArray(parsed);
                if (root.valid) root.write(parsed);
            } catch (e) {
                root.valid = false;
            }
        }
    }
    StyledText {
        visible: !root.valid
        text: Translation.tr("Not a valid JSON list - changes are not saved until it is")
        color: Appearance.m3colors.m3error
        font.pixelSize: Appearance.font.pixelSize.smaller
    }
    Component.onCompleted: {
        area.text = JSON.stringify(Array.from(read() ?? []), null, 2);
        ready = true;
    }
}
