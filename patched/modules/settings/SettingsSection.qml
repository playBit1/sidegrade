import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// A settings section: title outside, rows grouped on a faint card
ColumnLayout {
    id: root
    property string title
    property string icon: ""
    default property alias contentData: sectionContent.data

    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.leftMargin: 6
        spacing: 6
        OptionalMaterialSymbol {
            icon: root.icon
            iconSize: Appearance.font.pixelSize.larger
        }
        StyledText {
            text: root.title
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.Medium
            color: Appearance.colors.colOnSecondaryContainer
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: sectionContent.implicitHeight + 16
        radius: Appearance.rounding.normal
        color: Appearance.m3colors.m3surfaceContainer

        ColumnLayout {
            id: sectionContent
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 4
        }
    }
}
