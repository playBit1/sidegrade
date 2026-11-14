pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell

Column {
    id: root
    // ii Settings Rework: this monitor's own widget settings, or the shared ones
    readonly property string bgScreen: QsWindow.window?.screen?.name ?? ""
    readonly property var bgOptions: MonitorBackgrounds.optionsFor(bgScreen)
    property list<string> clockNumbers: DateTime.time.split(/[: ]/)
    property bool isEnabled: root.bgOptions.widgets.clock.cookie.timeIndicators
    property color color: Appearance.colors.colOnSecondaryContainer

    property bool hourMarksEnabled: root.bgOptions.widgets.clock.cookie.hourMarks
    spacing: -16

    Repeater {
        model: root.clockNumbers

        delegate: StyledText {
            required property string modelData
            text: modelData.padStart(2, "0")
            property bool isAmPm: !text.match(/\d{2}/i)
            property real numberSizeWithoutGlow: isAmPm ? 26 : 68
            property real numberSizeWithGlow: isAmPm ? 20 : 40
            property real numberSize: root.hourMarksEnabled ? numberSizeWithGlow : numberSizeWithoutGlow

            anchors.horizontalCenter: root.horizontalCenter
            color: root.color
            font {
                family: Appearance.font.family.expressive
                weight: Font.Bold
                pixelSize: numberSize
            }

            Behavior on numberSize {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
        }
    }
}
