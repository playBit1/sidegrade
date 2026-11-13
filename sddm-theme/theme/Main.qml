// ii Login - an SDDM theme that matches the illogical-impulse (end-4) Quickshell lockscreen.
// SDDM loads this file once per monitor. The primary monitor gets all the login controls;
// the others get the wallpaper, the clock and a password field of their own, so typing is
// visible on whichever monitor the pointer is on.
import QtQuick

Item {
    id: root

    readonly property bool isPrimary: typeof primaryScreen === "undefined" ? true : primaryScreen

    // --- State (also what a test harness drives)
    property string userName: userModel.lastUser
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property var userNames: []
    property var sessionNames: []
    property bool canSuspend: sddm.canSuspend
    property bool canPowerOff: sddm.canPowerOff
    property bool canReboot: sddm.canReboot
    property bool busy: false
    property bool failed: false
    property bool sessionMenuOpen: false
    property bool userMenuOpen: false
    property alias passwordText: password.text
    property date now: new Date()

    // --- Theme values: theme.conf, overridden by theme.conf.user (written by sync.sh)
    function opt(key, fallback) {
        var value = config[key];
        return (value === undefined || value === null || value === "") ? fallback : value;
    }
    // Only an absolute path on this machine is accepted, never a URL
    function localFile(path) {
        var text = String(path);
        return text.charAt(0) === "/" ? "file://" + text.split("/").map(encodeURIComponent).join("/") : "";
    }
    function mix(a, b, share) {
        return Qt.rgba(a.r * share + b.r * (1 - share), a.g * share + b.g * (1 - share), a.b * share + b.b * (1 - share), 1);
    }
    QtObject {
        id: col
        readonly property color background: root.opt("background_color", "#131412")
        readonly property color surfaceContainer: root.opt("surface_container", "#1f201e")
        readonly property color surfaceContainerLow: root.opt("surface_container_low", "#1b1c1a")
        readonly property color surfaceContainerHigh: root.opt("surface_container_high", "#2a2a28")
        readonly property color fgSurface: root.opt("on_surface", "#e4e2de")
        readonly property color fgSurfaceVariant: root.opt("on_surface_variant", "#c8c6c3")
        readonly property color outline: root.opt("outline", "#92918d")
        readonly property color primary: root.opt("primary", "#c2c9b4")
        readonly property color fgPrimary: root.opt("on_primary", "#2c3323")
        readonly property color primaryContainer: root.opt("primary_container", "#424939")
        readonly property color secondary: root.opt("secondary", "#c4c8ba")
        readonly property color secondaryContainer: root.opt("secondary_container", "#44483d")
        readonly property color fgSecondaryContainer: root.opt("on_secondary_container", "#e1e4d5")
        readonly property color tertiary: root.opt("tertiary", "#bfcbad")
        readonly property color tertiaryContainer: root.opt("tertiary_container", "#404a34")
        readonly property color fgTertiaryContainer: root.opt("on_tertiary_container", "#dbe7c8")
        readonly property color error: root.opt("error", "#ffb4ab")
        readonly property color hover: Qt.rgba(fgSurface.r, fgSurface.g, fgSurface.b, 0.09)
    }
    FontLoader { id: bundledMain; source: "fonts/GoogleSansFlex.ttf" }
    readonly property string fontMain: bundledMain.status === FontLoader.Ready ? bundledMain.font.family : opt("fontMain", "Google Sans Flex")
    readonly property string fontExpressive: opt("fontExpressive", "Space Grotesk")
    readonly property string fontReading: opt("fontReading", "Readex Pro")
    readonly property string quote: String(opt("quote", "")).trim()
    readonly property bool showDate: String(opt("showDate", "true")) !== "false"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // --- Login
    function login() {
        if (root.busy || root.userName === "")
            return;
        root.busy = true;
        root.failed = false;
        sddm.login(root.userName, password.text, root.sessionIndex);
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.failed = true;
            password.text = "";
            shake.restart();
            password.forceActiveFocus();
        }
    }

    // Names from SDDM's models, kept by index so the pills can show the current one
    Repeater {
        model: userModel
        Item {
            required property int index
            required property string name
            visible: false
            Component.onCompleted: {
                var names = root.userNames.slice();
                names[index] = name;
                root.userNames = names;
                if (root.userName === "" && index === 0)
                    root.userName = name;
            }
        }
    }
    Repeater {
        model: sessionModel
        Item {
            required property int index
            required property string name
            visible: false
            Component.onCompleted: {
                var names = root.sessionNames.slice();
                names[index] = name;
                root.sessionNames = names;
            }
        }
    }

    // --- Wallpaper: already blurred by sync.sh, zoomed and tinted like the lockscreen
    Rectangle {
        anchors.fill: parent
        color: col.background
    }
    Item {
        anchors.fill: parent
        clip: true
        Image {
            anchors.fill: parent
            source: root.localFile(root.opt("background", ""))
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: false
            smooth: true
            scale: Number(root.opt("blurZoom", 1.1))
        }
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(col.background.r, col.background.g, col.background.b, 0.3)
    }

    // Clicking anywhere closes menus and returns focus to the password field.
    // Each monitor is its own window: when the pointer comes onto this one, take the
    // keyboard so what is typed lands in (and shows in) this monitor's password field.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            if (root.Window.window)
                root.Window.window.requestActivate();
            password.forceActiveFocus();
        }
        onPressed: {
            root.sessionMenuOpen = false;
            root.userMenuOpen = false;
            password.forceActiveFocus();
        }
    }

    // --- Clock, quote and date, centred
    Column {
        anchors.centerIn: parent
        spacing: 10

        CookieClock {
            anchors.horizontalCenter: parent.horizontalCenter
            now: root.now
            sides: Number(root.opt("cookieSides", 14))
            timeFormat: root.opt("timeFormat", "hh:mm")
            fontExpressive: root.fontExpressive
            colBackground: col.primaryContainer
            colOnBackground: root.mix(col.secondary, col.primaryContainer, 0.15)
            colBackgroundInfo: root.mix(col.primary, col.primaryContainer, 0.55)
            colHourHand: col.primary
            colMinuteHand: col.tertiary
            colDayBubble: col.tertiaryContainer
            colOnDayBubble: col.fgTertiaryContainer
            colMonthBubble: col.secondaryContainer
            colOnMonthBubble: col.fgSecondaryContainer
        }

        Chip {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.quote !== ""
            icon: "format_quote"
            label: root.quote
            fontFamily: root.fontReading
        }
        Chip {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.showDate
            icon: "calendar_today"
            label: Qt.formatDate(root.now, root.opt("dateFormat", "ddd, dd/MM"))
            fontFamily: root.fontMain
        }
    }

    // --- Login controls: the password field on every monitor, the rest on the primary only
    Item {
        id: controls
        anchors.fill: parent
        opacity: 0
        scale: 0.9
        transformOrigin: Item.Bottom
        Component.onCompleted: {
            opacity = 1;
            scale = 1;
            password.forceActiveFocus();
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

        // Middle: password
        Pill {
            id: mainPill
            color: col.surfaceContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20

            Rectangle {
                id: field
                width: 200
                height: parent.height
                radius: height / 2
                color: col.surfaceContainerLow
                clip: true
                transform: Translate { id: fieldShift }

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                    color: "transparent"
                    selectionColor: "transparent"
                    selectedTextColor: "transparent"
                    cursorDelegate: Item {}
                    enabled: !root.busy
                    focus: true
                    onTextChanged: if (text.length > 0) root.failed = false
                    onAccepted: root.login()
                    Keys.onEscapePressed: text = ""
                }
                Text {
                    anchors.fill: password
                    verticalAlignment: Text.AlignVCenter
                    visible: password.text.length === 0
                    text: root.failed ? "Incorrect password" : "Enter password"
                    color: root.failed ? col.error : col.outline
                    font.family: root.fontMain
                    font.pixelSize: 15
                }
                Row {
                    id: dots
                    anchors.verticalCenter: parent.verticalCenter
                    x: 14 + Math.min(0, field.width - 28 - width)
                    Repeater {
                        model: password.text.length
                        Item {
                            required property int index
                            width: 20
                            height: 20
                            ShapeDot {
                                anchors.centerIn: parent
                                kind: index
                                color: col.fgSurfaceVariant
                                scale: 0.5
                                Component.onCompleted: scale = 1
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            }
                        }
                    }
                    Rectangle {
                        width: 2
                        height: 20
                        color: col.primary
                        visible: password.activeFocus && password.text.length > 0
                    }
                }
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: fieldShift; property: "x"; to: -10; duration: 50 }
                    NumberAnimation { target: fieldShift; property: "x"; to: 10; duration: 90 }
                    NumberAnimation { target: fieldShift; property: "x"; to: -6; duration: 80 }
                    NumberAnimation { target: fieldShift; property: "x"; to: 0; duration: 70 }
                }
            }
            IconButton {
                icon: "arrow_right_alt"
                iconSize: 24
                baseColor: col.primary
                iconColor: col.fgPrimary
                enabled: !root.busy
                onClicked: root.login()
            }
        }

        // Left: user, keyboard layout, caps lock
        Pill {
            id: leftPill
            visible: root.isPrimary
            color: col.surfaceContainer
            anchors.right: mainPill.left
            anchors.rightMargin: 10
            anchors.verticalCenter: mainPill.verticalCenter

            LabelButton {
                icon: "account_circle"
                label: root.userName
                interactive: root.userNames.length > 1
                onClicked: {
                    root.sessionMenuOpen = false;
                    root.userMenuOpen = !root.userMenuOpen;
                }
            }
            LabelButton {
                visible: keyboard.layouts.length > 0
                icon: "keyboard_alt"
                label: keyboard.layouts.length > 0 ? keyboard.layouts[keyboard.currentLayout].shortName : ""
                interactive: keyboard.layouts.length > 1
                onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
            LabelButton {
                visible: keyboard.capsLock
                icon: "keyboard_capslock"
                label: "Caps"
                tint: col.error
                interactive: false
            }
        }

        // Right: session, sleep, power off, restart
        Pill {
            id: rightPill
            visible: root.isPrimary
            color: col.surfaceContainer
            anchors.left: mainPill.right
            anchors.leftMargin: 10
            anchors.verticalCenter: mainPill.verticalCenter

            LabelButton {
                icon: "desktop_windows"
                label: root.sessionNames[root.sessionIndex] || "Session"
                interactive: root.sessionNames.length > 1
                active: root.sessionMenuOpen
                onClicked: {
                    root.userMenuOpen = false;
                    root.sessionMenuOpen = !root.sessionMenuOpen;
                }
            }
            IconButton {
                visible: root.canSuspend
                icon: "dark_mode"
                iconColor: col.fgSurfaceVariant
                hoverColor: col.hover
                onClicked: sddm.suspend()
            }
            IconButton {
                visible: root.canPowerOff
                icon: "power_settings_new"
                iconColor: col.fgSurfaceVariant
                hoverColor: col.hover
                onClicked: sddm.powerOff()
            }
            IconButton {
                visible: root.canReboot
                icon: "restart_alt"
                iconColor: col.fgSurfaceVariant
                hoverColor: col.hover
                onClicked: sddm.reboot()
            }
        }

        Menu {
            visible: root.sessionMenuOpen
            anchors.left: rightPill.left
            anchors.bottom: rightPill.top
            anchors.bottomMargin: 8
            entries: root.sessionNames
            current: root.sessionIndex
            onPicked: index => {
                root.sessionIndex = index;
                root.sessionMenuOpen = false;
                password.forceActiveFocus();
            }
        }
        Menu {
            visible: root.userMenuOpen
            anchors.left: leftPill.left
            anchors.bottom: leftPill.top
            anchors.bottomMargin: 8
            entries: root.userNames
            current: root.userNames.indexOf(root.userName)
            onPicked: index => {
                root.userName = root.userNames[index];
                root.userMenuOpen = false;
                password.forceActiveFocus();
            }
        }
    }

    // --- Small pieces
    component Chip: Item {
        id: chip
        property alias icon: chipIcon.text
        property alias label: chipLabel.text
        property string fontFamily
        implicitWidth: chipRow.implicitWidth + 16
        implicitHeight: chipRow.implicitHeight + 8
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: -2
            radius: 12
            color: Qt.rgba(0, 0, 0, 0.25)
        }
        Rectangle {
            anchors.fill: parent
            radius: 12
            color: col.secondaryContainer
        }
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 4
            Icon {
                id: chipIcon
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 22
                color: col.fgSecondaryContainer
            }
            Text {
                id: chipLabel
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                color: col.fgSecondaryContainer
                font.family: chip.fontFamily
                font.pixelSize: 17
            }
        }
    }

    component LabelButton: Rectangle {
        id: labelButton
        property alias icon: buttonIcon.text
        property alias label: buttonLabel.text
        property bool interactive: true
        property bool active: false
        property color tint: col.fgSurfaceVariant
        signal clicked()
        height: parent ? parent.height : 40
        width: buttonRow.implicitWidth + 20
        radius: height / 2
        color: active ? col.secondaryContainer : (buttonArea.containsMouse && interactive ? col.hover : "transparent")
        Row {
            id: buttonRow
            anchors.centerIn: parent
            spacing: 4
            Icon {
                id: buttonIcon
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 22
                color: labelButton.active ? col.fgSecondaryContainer : labelButton.tint
            }
            Text {
                id: buttonLabel
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                color: labelButton.active ? col.fgSecondaryContainer : labelButton.tint
                font.family: root.fontMain
                font.pixelSize: 15
            }
        }
        MouseArea {
            id: buttonArea
            anchors.fill: parent
            enabled: labelButton.interactive
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: labelButton.clicked()
        }
    }

    component Menu: Rectangle {
        id: menu
        property var entries: []
        property int current: -1
        signal picked(int index)
        property real itemWidth: 260
        width: itemWidth + 16
        height: menuColumn.implicitHeight + 16
        radius: 20
        color: col.surfaceContainer
        border.color: Qt.rgba(col.outline.r, col.outline.g, col.outline.b, 0.25)
        MouseArea { anchors.fill: parent } // clicks on the padding do not close the menu
        Column {
            id: menuColumn
            anchors.centerIn: parent
            spacing: 2
            Repeater {
                model: menu.entries
                Rectangle {
                    id: entry
                    required property int index
                    required property string modelData
                    width: menu.itemWidth
                    height: 40
                    radius: 20
                    color: index === menu.current ? col.secondaryContainer : (entryArea.containsMouse ? col.hover : "transparent")
                    Text {
                        id: entryLabel
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        text: entry.modelData
                        textFormat: Text.PlainText
                        color: entry.index === menu.current ? col.fgSecondaryContainer : col.fgSurface
                        font.family: root.fontMain
                        font.pixelSize: 15
                    }
                    Icon {
                        visible: entry.index === menu.current
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        text: "check"
                        iconSize: 20
                        color: col.fgSecondaryContainer
                    }
                    MouseArea {
                        id: entryArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: menu.picked(entry.index)
                    }
                }
            }
        }
    }
}
