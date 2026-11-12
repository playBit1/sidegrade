import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// Switch bound to a config option by its dotted path, e.g. "bar.verbose"
ConfigSwitch {
    id: root
    required property string key
    property string tooltip: ""
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
    buttonIcon: ""
    checked: read() ?? false
    onCheckedChanged: write(checked)

    StyledToolTip {
        extraVisibleCondition: root.tooltip.length > 0
        text: root.tooltip
    }
}
