import QtQuick

// Material Symbols Rounded glyph, addressed by its ligature name.
Text {
    property real iconSize: 22
    property real fill: 1
    font.family: "Material Symbols Rounded"
    font.pixelSize: iconSize
    font.variableAxes: ({ "FILL": fill, "opsz": Math.max(20, Math.min(48, iconSize)) })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
}
