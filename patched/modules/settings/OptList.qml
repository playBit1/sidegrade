import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// List-of-strings option bound to a config path, edited as text.
// Entries are separated by `separator` (comma by default, "\n" for one per line).
ColumnLayout {
    id: root
    required property string key
    property string placeholderText: ""
    property string separator: ","
    property bool ready: false
    function read() {
        return key.split(".").reduce((o, k) => o?.[k], Config.options);
    }
    function write(entries) {
        const ks = key.split(".");
        const last = ks.pop();
        const o = ks.reduce((o, k) => o[k], Config.options);
        if (JSON.stringify(Array.from(o[last] ?? [])) !== JSON.stringify(entries)) o[last] = entries;
    }
    spacing: 2
    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    Layout.topMargin: 2
    Layout.bottomMargin: 2

    StyledText {
        Layout.fillWidth: true
        text: root.placeholderText
        wrapMode: Text.WordWrap
        color: Appearance.colors.colSubtext
        font.pixelSize: Appearance.font.pixelSize.smaller
    }
    OptField {
        id: field
        Layout.fillWidth: true
        onTextChanged: {
            if (root.ready) root.write(text.split(root.separator).map(s => s.trim()).filter(s => s.length > 0));
        }
    }
    Component.onCompleted: {
        field.text = Array.from(read() ?? []).join(separator === "\n" ? "\n" : separator + " ");
        ready = true;
    }
}
