
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell

Rectangle {
    id: rect
    // ii Settings Rework: this monitor's own widget settings, or the shared ones
    readonly property string bgScreen: QsWindow.window?.screen?.name ?? ""
    readonly property var bgOptions: MonitorBackgrounds.optionsFor(bgScreen)
    readonly property string dialStyle: rect.bgOptions.widgets.clock.cookie.dialNumberStyle

    StyledText {
        anchors.centerIn: parent
        color: Appearance.colors.colSecondaryHover
        text: Qt.locale().toString(DateTime.clock.date, "dd")
        font {
            family: Appearance.font.family.expressive
            pixelSize: 20
            weight: 1000
        }
    }
}
