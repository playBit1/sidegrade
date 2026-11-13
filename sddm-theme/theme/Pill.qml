import QtQuick

// Material 3 toolbar: a fully rounded bar holding a row of controls.
Item {
    id: pill
    property color color: "#1f201e"
    property real padding: 8
    default property alias content: row.data
    implicitHeight: 56
    implicitWidth: row.implicitWidth + padding * 2

    // Soft shadow from stacked translucent outlines (no shaders: works on any renderer)
    Repeater {
        model: 4
        Rectangle {
            required property int index
            anchors.fill: parent
            anchors.margins: -(index + 1)
            anchors.topMargin: -(index + 1) + 2
            anchors.bottomMargin: -(index + 1) - 2
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.05)
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: pill.color
    }
    Row {
        id: row
        anchors.centerIn: parent
        height: parent.height - pill.padding * 2
        spacing: 4
    }
}
