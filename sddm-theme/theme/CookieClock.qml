import QtQuick

// The lockscreen's analog "cookie" clock: scalloped face, minute ticks, the time as
// numbers in the middle, a filled hour hand, a medium minute hand, and date bubbles.
Item {
    id: clock
    property date now: new Date()
    property int sides: 14
    property string timeFormat: "hh:mm"
    property string fontExpressive: "Space Grotesk"
    property color colBackground
    property color colOnBackground
    property color colBackgroundInfo
    property color colHourHand
    property color colMinuteHand
    property color colDayBubble
    property color colOnDayBubble
    property color colMonthBubble
    property color colOnMonthBubble
    readonly property var parts: Qt.formatTime(now, timeFormat).split(/[: ]/)
    implicitWidth: 230
    implicitHeight: 230

    // Face, with its drop shadow
    Canvas {
        id: face
        anchors.centerIn: parent
        width: parent.width + 40
        height: parent.height + 40
        property color fill: clock.colBackground
        property int sides: clock.sides
        property color bubble: clock.colDayBubble
        onFillChanged: requestPaint()
        onBubbleChanged: requestPaint()
        onSidesChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var cx = width / 2, cy = height / 2;
            var outer = clock.width / 2;
            var amp = outer * 0.032;
            ctx.beginPath();
            for (var i = 0; i <= 720; i++) {
                var a = i * Math.PI / 360;
                var r = outer - amp + amp * Math.cos(a * face.sides);
                var x = cx + r * Math.cos(a), y = cy + r * Math.sin(a);
                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            }
            ctx.closePath();
            ctx.shadowColor = Qt.rgba(0, 0, 0, 0.45);
            ctx.shadowBlur = 14;
            ctx.shadowOffsetY = 3;
            ctx.fillStyle = face.fill;
            ctx.fill();

            // Day-of-month bubble: a rounded pentagon over the top-left of the face
            ctx.shadowColor = "transparent";
            ctx.shadowBlur = 0;
            ctx.shadowOffsetY = 0;
            var bx = cx - outer + 32, by = cy - outer + 33;
            ctx.fillStyle = face.bubble;
            ctx.strokeStyle = face.bubble;
            ctx.lineJoin = "round";
            ctx.lineWidth = 16;
            ctx.beginPath();
            for (var k = 0; k < 5; k++) {
                var b = -Math.PI / 2 + k * 2 * Math.PI / 5;
                if (k === 0) ctx.moveTo(bx + 22 * Math.cos(b), by + 22 * Math.sin(b));
                else ctx.lineTo(bx + 22 * Math.cos(b), by + 22 * Math.sin(b));
            }
            ctx.closePath();
            ctx.fill();
            ctx.stroke();
        }
    }

    // Hour and minute ticks
    Item {
        anchors.fill: parent
        anchors.margins: 10
        Repeater {
            model: 60
            Item {
                required property int index
                anchors.fill: parent
                rotation: 6 * index
                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: index % 5 === 0 ? 18 : 7
                    height: index % 5 === 0 ? 4 : 2
                    radius: height / 2
                    color: clock.colOnBackground
                }
            }
        }
    }

    // Time as numbers
    Column {
        anchors.centerIn: parent
        spacing: -16
        Repeater {
            model: clock.parts
            Text {
                required property string modelData
                readonly property bool isAmPm: !/\d/.test(modelData)
                anchors.horizontalCenter: parent.horizontalCenter
                text: isAmPm ? modelData : ("0" + modelData).slice(-2)
                color: clock.colBackgroundInfo
                font.family: clock.fontExpressive
                font.weight: Font.Bold
                font.pixelSize: isAmPm ? 26 : 68
            }
        }
    }

    // Minute hand
    Item {
        anchors.fill: parent
        rotation: -90 + 6 * clock.now.getMinutes()
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 - height / 2
            width: 95
            height: 12
            radius: height / 2
            color: clock.colMinuteHand
        }
    }
    // Hour hand
    Item {
        anchors.fill: parent
        rotation: -90 + 30 * (clock.now.getHours() % 12 + clock.now.getMinutes() / 60)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: (parent.width - height) / 2
            width: 72
            height: 20
            radius: height / 2
            color: clock.colHourHand
        }
    }
    Rectangle {
        anchors.centerIn: parent
        width: 6
        height: 6
        radius: 3
        color: clock.colBackground
    }

    // Date bubbles: day of month (top left), month (bottom right)
    Item {
        width: 64
        height: 64
        anchors.left: parent.left
        anchors.top: parent.top
        Text {
            anchors.centerIn: parent
            text: Qt.formatDate(clock.now, "d")
            color: clock.colOnDayBubble
            font.family: clock.fontExpressive
            font.weight: Font.Black
            font.pixelSize: 30
        }
    }
    Item {
        width: 64
        height: 64
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        Rectangle {
            anchors.centerIn: parent
            width: 62
            height: 42
            radius: 21
            rotation: -45
            color: clock.colMonthBubble
        }
        Text {
            anchors.centerIn: parent
            text: Qt.formatDate(clock.now, "MM")
            color: clock.colOnMonthBubble
            font.family: clock.fontExpressive
            font.weight: Font.Black
            font.pixelSize: 30
        }
    }
}
