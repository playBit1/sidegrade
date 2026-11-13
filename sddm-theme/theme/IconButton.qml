import QtQuick

Rectangle {
    id: btn
    property alias icon: glyph.text
    property alias iconSize: glyph.iconSize
    property color iconColor: "#c8c6c3"
    property color hoverColor: Qt.rgba(1, 1, 1, 0.08)
    property color baseColor: "transparent"
    signal clicked()
    width: height
    height: parent ? parent.height : 40
    radius: height / 2
    color: area.pressed ? Qt.darker(hoverColor, 1.0) : (area.containsMouse && baseColor.a === 0 ? hoverColor : baseColor)
    opacity: enabled ? 1 : 0.5
    Icon {
        id: glyph
        anchors.centerIn: parent
        color: btn.iconColor
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
