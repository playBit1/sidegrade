pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: clockColumn
    // ii Settings Rework: this monitor's own widget settings, or the shared ones
    readonly property string bgScreen: QsWindow.window?.screen?.name ?? ""
    readonly property var bgOptions: MonitorBackgrounds.optionsFor(bgScreen)
    spacing: 4

    property bool isVertical: clockColumn.bgOptions.widgets.clock.digital.vertical
    property color colText: Appearance.colors.colOnSecondaryContainer
    property var textHorizontalAlignment: Text.AlignHCenter

    // Time
    ClockText {
        id: timeTextTop
        text: clockColumn.isVertical ? DateTime.time.split(":")[0].padStart(2, "0") : DateTime.time
        color: clockColumn.colText
        horizontalAlignment: Text.AlignHCenter
        font {
            pixelSize: clockColumn.bgOptions.widgets.clock.digital.font.size
            weight: clockColumn.bgOptions.widgets.clock.digital.font.weight
            family: clockColumn.bgOptions.widgets.clock.digital.font.family
            variableAxes: ({
                    "wdth": clockColumn.bgOptions.widgets.clock.digital.font.width,
                    "ROND": clockColumn.bgOptions.widgets.clock.digital.font.roundness
                })
        }
    }

    Loader {
        Layout.topMargin: -40
        Layout.fillWidth: true
        active: clockColumn.isVertical
        visible: active
        sourceComponent: ClockText {
            id: timeTextBottom
            text: DateTime.time.split(":")[1].split(" ")[0].padStart(2, "0")
            color: clockColumn.colText
            horizontalAlignment: clockColumn.textHorizontalAlignment
            font {
                pixelSize: timeTextTop.font.pixelSize
                weight: timeTextTop.font.weight
                family: timeTextTop.font.family
                variableAxes: timeTextTop.font.variableAxes
            }
        }
    }

    // Date
    ClockText {
        visible: clockColumn.bgOptions.widgets.clock.digital.showDate
        Layout.topMargin: -20
        Layout.fillWidth: true
        text: DateTime.longDate
        color: clockColumn.colText
        horizontalAlignment: clockColumn.textHorizontalAlignment
    }

    // Quote
    ClockText {
        visible: clockColumn.bgOptions.widgets.clock.quote.enable && clockColumn.bgOptions.widgets.clock.quote.text.length > 0
        font.pixelSize: Appearance.font.pixelSize.normal
        text: clockColumn.bgOptions.widgets.clock.quote.text
        animateChange: false
        color: clockColumn.colText
        horizontalAlignment: clockColumn.textHorizontalAlignment
    }
}
