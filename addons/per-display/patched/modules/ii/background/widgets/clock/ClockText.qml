import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

StyledText {
    id: clockText
    // ii Settings Rework: this monitor's own widget settings, or the shared ones
    readonly property string bgScreen: QsWindow.window?.screen?.name ?? ""
    readonly property var bgOptions: MonitorBackgrounds.optionsFor(bgScreen)
    Layout.fillWidth: true
    font {
        family: Appearance.font.family.expressive
        pixelSize: 20
        weight: 350
        // Set empty to prevent conflicts, not meaningless
        styleName: ""
        variableAxes: ({})
    }
    style: Text.Raised
    styleColor: Appearance.colors.colShadow
    animateChange: clockText.bgOptions.widgets.clock.digital.animateChange
}