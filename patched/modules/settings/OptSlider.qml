import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Percentage slider bound to a 0..1 config option
RowLayout {
    id: root
    required property string key
    property string text: ""
    property var store: Config.options // What the key is looked up in
    property var writer: null // function(key, value): replaces writing into store (used by add-on pages)
    function read() {
        return key.split(".").reduce((o, k) => o?.[k], store);
    }
    function write(v) {
        if (writer) return writer(key, v);
        const ks = key.split(".");
        const last = ks.pop();
        const o = ks.reduce((o, k) => o[k], store);
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
    StyledSlider {
        id: slider
        Layout.fillWidth: false
        Layout.preferredWidth: 220
        configuration: StyledSlider.Configuration.XS
        from: 0
        to: 1
        stopIndicatorValues: []
        value: root.read() ?? 0
        onMoved: root.write(Math.round(value * 100) / 100)
    }
    StyledText {
        Layout.preferredWidth: 38
        horizontalAlignment: Text.AlignRight
        text: Math.round(slider.value * 100) + "%"
        color: Appearance.colors.colSubtext
        font.pixelSize: Appearance.font.pixelSize.smaller
    }
}
