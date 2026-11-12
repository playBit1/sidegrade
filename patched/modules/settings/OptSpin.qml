import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Number option bound to a config path, with the unit shown beside the box.
// `scale` converts fractional options to whole numbers (100 for percent).
RowLayout {
    id: root
    required property string key
    property string text: ""
    property string suffix: ""
    property real scale: 1
    property bool ready: false
    property alias value: box.value
    property alias from: box.from
    property alias to: box.to
    property alias stepSize: box.stepSize
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
    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    StyledText {
        Layout.fillWidth: true
        text: root.text
        elide: Text.ElideRight
        color: Appearance.colors.colOnSecondaryContainer
        opacity: root.enabled ? 1 : 0.4
    }
    StyledText {
        visible: root.suffix.length > 0
        text: root.suffix
        color: Appearance.colors.colSubtext
        font.pixelSize: Appearance.font.pixelSize.smaller
        opacity: root.enabled ? 1 : 0.4
    }
    StyledSpinBox {
        id: box
        Layout.fillWidth: false
    }

    value: Math.round((read() ?? 0) * scale)
    onValueChanged: {
        if (ready) write(value / scale);
    }
    Component.onCompleted: ready = true
}
