import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Text option bound to a config path. Compact (label left, field right) by default;
// `wide` stacks the label above a full-width field for long values.
GridLayout {
    id: root
    required property string key
    property string placeholderText: ""
    property bool wide: false
    property bool ready: false
    function read() {
        return key.split(".").reduce((o, k) => o?.[k], Config.options);
    }
    function write(v) {
        const ks = key.split(".");
        const last = ks.pop();
        const o = ks.reduce((o, k) => o[k], Config.options);
        if (typeof v === "number" && typeof o[last] === "number" && Math.abs(o[last] - v) < 1e-9) return;
        if (o[last] !== v) o[last] = v;
    }
    columns: wide ? 1 : 2
    rowSpacing: 2
    columnSpacing: 10
    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    Layout.topMargin: 2
    Layout.bottomMargin: 2

    StyledText {
        Layout.fillWidth: true
        text: root.placeholderText
        wrapMode: Text.WordWrap
        color: root.wide ? Appearance.colors.colSubtext : Appearance.colors.colOnSecondaryContainer
        font.pixelSize: root.wide ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.small
        opacity: root.enabled ? 1 : 0.4
    }
    OptField {
        id: field
        Layout.fillWidth: root.wide
        Layout.preferredWidth: root.wide ? -1 : 280
        onTextChanged: {
            if (root.ready) root.write(text);
        }
    }
    Component.onCompleted: {
        field.text = read() ?? "";
        ready = true;
    }
}
