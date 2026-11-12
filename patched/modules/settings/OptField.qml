import QtQuick
import QtQuick.Controls
import qs.modules.common

// Plain rounded text box used by the Opt* text rows
TextArea {
    id: root
    leftPadding: 10
    rightPadding: 10
    topPadding: 8
    bottomPadding: 8
    wrapMode: TextEdit.Wrap
    selectByMouse: true
    color: Appearance.colors.colOnLayer2
    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    placeholderTextColor: Appearance.colors.colSubtext
    font {
        family: Appearance.font.family.main
        pixelSize: Appearance.font.pixelSize.small
    }
    background: Rectangle {
        implicitHeight: 35
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2
        border.width: root.activeFocus ? 2 : 0
        border.color: Appearance.colors.colPrimary
    }
}
