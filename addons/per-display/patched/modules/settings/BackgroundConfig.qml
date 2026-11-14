// ii Settings Rework, per-display backgrounds add-on: the Background page with a choice of display
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings

ContentPage {
    forceWidth: true

    SettingsSection {
        id: wallpaperSection
        icon: "wallpaper"
        title: Translation.tr("Wallpaper")

        // What a display without its own wallpaper shows (for a video wallpaper: its still frame)
        readonly property string mainPath: {
            const path = Config.options.background.wallpaperPath;
            return /\.(mp4|webm|mkv|avi|mov)$/.test(path) ? Config.options.background.thumbnailPath : path;
        }
        // Numbered like on the Displays page: left to right, then top to bottom
        readonly property var screens: {
            let list = [];
            for (const screen of Quickshell.screens) list.push(screen);
            return list.sort((a, b) => a.x - b.x || a.y - b.y);
        }
        readonly property string note: Translation.tr("A display without its own wallpaper shows the main one. The main wallpaper is picked on the Quick page or in the wallpaper selector, and the colors always follow it.")

        function choose(screen, shownPath) {
            if (pickProc.running) return;
            const folder = shownPath.includes("/") ? shownPath.substring(0, shownPath.lastIndexOf("/")) : ".";
            pickProc.monitorName = screen.name;
            pickProc.command = ["kdialog", "--title", Translation.tr("Choose wallpaper for %1").arg(screen.model || screen.name),
                "--getopenfilename", folder, "Images (*.png *.jpg *.jpeg *.webp *.avif *.bmp *.gif *.svg)"];
            pickProc.running = true;
        }

        Process { // The file dialog; prints the chosen path, or nothing when cancelled
            id: pickProc
            property string monitorName: ""
            stdout: StdioCollector {
                onStreamFinished: {
                    const path = text.trim();
                    if (path.length > 0) MonitorBackgrounds.setWallpaper(pickProc.monitorName, path);
                }
            }
        }

        Repeater {
            model: wallpaperSection.screens
            RowLayout {
                id: screenRow
                required property var modelData
                required property int index
                readonly property string own: MonitorBackgrounds.wallpaperFor(modelData.name)
                readonly property string shown: own.length > 0 ? own : wallpaperSection.mainPath
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                spacing: 12

                Item { // Preview, in the shape of the display
                    implicitWidth: 128
                    implicitHeight: 76
                    Rectangle {
                        id: preview
                        readonly property real fit: Math.min(128 / screenRow.modelData.width, 76 / screenRow.modelData.height)
                        anchors.centerIn: parent
                        width: Math.round(screenRow.modelData.width * fit)
                        height: Math.round(screenRow.modelData.height * fit)
                        radius: Appearance.rounding.verysmall
                        color: Appearance.colors.colLayer3
                        MaterialSymbol {
                            anchors.centerIn: parent
                            visible: previewImage.status !== Image.Ready
                            text: "broken_image"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colSubtext
                        }
                        StyledImage {
                            id: previewImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: screenRow.shown
                            sourceSize.width: 256
                            sourceSize.height: 256
                            cache: false
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: preview.width
                                    height: preview.height
                                    radius: preview.radius
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: `${screenRow.index + 1}  ${screenRow.modelData.model || screenRow.modelData.name}`
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                        text: `${screenRow.modelData.name} · ` + (screenRow.own.length > 0 ? screenRow.own.substring(screenRow.own.lastIndexOf("/") + 1) : Translation.tr("Main wallpaper"))
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }

                RippleButtonWithIcon {
                    visible: screenRow.own.length > 0
                    materialIcon: "undo"
                    mainText: Translation.tr("Use main")
                    onClicked: MonitorBackgrounds.setWallpaper(screenRow.modelData.name, "")
                    StyledToolTip {
                        text: Translation.tr("Show the main wallpaper on this display again")
                    }
                }
                RippleButtonWithIcon {
                    enabled: !pickProc.running
                    materialIcon: "image"
                    mainText: Translation.tr("Choose")
                    onClicked: wallpaperSection.choose(screenRow.modelData, screenRow.shown)
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 6
            wrapMode: Text.WordWrap
            text: wallpaperSection.note
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
        }

        OptSwitch {
            key: "background.hideWhenFullscreen"
            text: Translation.tr("Hide when a window is fullscreen")
        }
        OptText {
            key: "background.thumbnailPath"
            placeholderText: Translation.tr("Video wallpaper thumbnail path (normally set automatically)")
            wide: true
        }
    }

    SettingsSection {
        id: scopeSection
        icon: "monitor"
        title: Translation.tr("Widgets and parallax per display")

        // Numbered like on the Displays page: left to right, then top to bottom
        readonly property var screens: {
            let list = [];
            for (const screen of Quickshell.screens) list.push(screen);
            return list.sort((a, b) => a.x - b.x || a.y - b.y);
        }
        readonly property string hint: {
            if (MonitorBackgrounds.editing.length === 0) {
                const own = screens.filter(screen => MonitorBackgrounds.hasOwnSettings(screen.name)).map(screen => screen.model || screen.name);
                return own.length === 0 ? Translation.tr("The clock, weather and parallax settings below are used on every display.")
                    : Translation.tr("The clock, weather and parallax settings below are used on every display that does not have its own. With its own: %1.").arg(own.join(", "));
            }
            return MonitorBackgrounds.editable ? Translation.tr("The clock, weather and parallax settings below now change this display only. Turning this off discards them.")
                : Translation.tr("This display uses the same settings as the others. Turn this on to give it its own, starting from a copy of them.");
        }

        Component.onCompleted: MonitorBackgrounds.editing = ""

        ConfigSelectionArray {
            Layout.leftMargin: 4
            currentValue: MonitorBackgrounds.editing
            onSelected: newValue => MonitorBackgrounds.editing = newValue
            options: [{ displayName: Translation.tr("All displays"), icon: "select_all", value: "" }].concat(
                scopeSection.screens.map((screen, i) => ({ displayName: `${i + 1}  ${screen.model || screen.name}`, icon: "monitor", value: screen.name })))
        }

        ConfigSwitch {
            visible: MonitorBackgrounds.editing.length > 0
            text: Translation.tr("Separate settings for this display")
            checked: MonitorBackgrounds.hasOwnSettings(MonitorBackgrounds.editing)
            onCheckedChanged: {
                if (MonitorBackgrounds.editing.length > 0) MonitorBackgrounds.setOwnSettings(MonitorBackgrounds.editing, checked);
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 4
            wrapMode: Text.WordWrap
            text: scopeSection.hint
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }

    SettingsSection {
        id: settingsClock
        icon: "clock_loader_40"
        title: Translation.tr("Clock widget")
        enabled: MonitorBackgrounds.editable
        opacity: enabled ? 1 : 0.4

        function stylePresent(styleName) {
            if (!MonitorBackgrounds.edited.widgets.clock.showOnlyWhenLocked && MonitorBackgrounds.edited.widgets.clock.style === styleName) {
                return true;
            }
            if (MonitorBackgrounds.edited.widgets.clock.styleLocked === styleName) {
                return true;
            }
            return false;
        }

        readonly property bool digitalPresent: stylePresent("digital")
        readonly property bool cookiePresent: stylePresent("cookie")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                text: Translation.tr("Enable")
                checked: MonitorBackgrounds.edited.widgets.clock.enable
                onCheckedChanged: {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.enable", checked);
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: MonitorBackgrounds.edited.widgets.clock.placementStrategy
                onSelected: newValue => {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.placementStrategy", newValue);
                }
                options: [
                    {
                        displayName: Translation.tr("Draggable"),
                        icon: "drag_pan",
                        value: "free"
                    },
                    {
                        displayName: Translation.tr("Least busy"),
                        icon: "category",
                        value: "leastBusy"
                    },
                    {
                        displayName: Translation.tr("Most busy"),
                        icon: "shapes",
                        value: "mostBusy"
                    },
                ]
            }
        }

        ConfigSwitch {
            text: Translation.tr("Show only when locked")
            checked: MonitorBackgrounds.edited.widgets.clock.showOnlyWhenLocked
            onCheckedChanged: {
                MonitorBackgrounds.writeEdited("background.widgets.clock.showOnlyWhenLocked", checked);
            }
        }

        ConfigRow {
            ContentSubsection {
                visible: !MonitorBackgrounds.edited.widgets.clock.showOnlyWhenLocked
                title: Translation.tr("Clock style")
                Layout.fillWidth: true
                ConfigSelectionArray {
                    currentValue: MonitorBackgrounds.edited.widgets.clock.style
                    onSelected: newValue => {
                        MonitorBackgrounds.writeEdited("background.widgets.clock.style", newValue);
                    }
                    options: [
                        {
                            displayName: Translation.tr("Digital"),
                            icon: "timer_10",
                            value: "digital"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Clock style (locked)")
                Layout.fillWidth: false
                ConfigSelectionArray {
                    currentValue: MonitorBackgrounds.edited.widgets.clock.styleLocked
                    onSelected: newValue => {
                        MonitorBackgrounds.writeEdited("background.widgets.clock.styleLocked", newValue);
                    }
                    options: [
                        {
                            displayName: Translation.tr("Digital"),
                            icon: "timer_10",
                            value: "digital"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        }
                    ]
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.digitalPresent
            title: Translation.tr("Digital clock settings")
            tooltip: Translation.tr("Font width and roundness settings are only available for some fonts like Google Sans Flex")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: Translation.tr("Vertical")
                    checked: MonitorBackgrounds.edited.widgets.clock.digital.vertical
                    onCheckedChanged: {
                        MonitorBackgrounds.writeEdited("background.widgets.clock.digital.vertical", checked);
                    }
                }
                ConfigSwitch {
                    text: Translation.tr("Animate time change")
                    checked: MonitorBackgrounds.edited.widgets.clock.digital.animateChange
                    onCheckedChanged: {
                        MonitorBackgrounds.writeEdited("background.widgets.clock.digital.animateChange", checked);
                    }
                }
            }

            ConfigRow {
                uniform: true

                ConfigSwitch {
                    text: Translation.tr("Show date")
                    checked: MonitorBackgrounds.edited.widgets.clock.digital.showDate
                    onCheckedChanged: {
                        MonitorBackgrounds.writeEdited("background.widgets.clock.digital.showDate", checked);
                    }
                }
                ConfigSwitch {
                    text: Translation.tr("Use adaptive alignment")
                    checked: MonitorBackgrounds.edited.widgets.clock.digital.adaptiveAlignment
                    onCheckedChanged: {
                        MonitorBackgrounds.writeEdited("background.widgets.clock.digital.adaptiveAlignment", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Aligns the date and quote to left, center or right depending on its position on the screen.")
                    }
                }
            }

            OptText {
                key: "background.widgets.clock.digital.font.family"
                store: MonitorBackgrounds.editedRoot
                writer: (key, value) => MonitorBackgrounds.writeEdited(key, value)
                placeholderText: Translation.tr("Font family")
                wide: true
            }

            ConfigSlider {
                text: Translation.tr("Font weight")
                value: MonitorBackgrounds.edited.widgets.clock.digital.font.weight
                usePercentTooltip: false
                from: 1
                to: 1000
                stopIndicatorValues: [350]
                onValueChanged: {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.digital.font.weight", value);
                }
            }

            ConfigSlider {
                text: Translation.tr("Font size")
                value: MonitorBackgrounds.edited.widgets.clock.digital.font.size
                usePercentTooltip: false
                from: 50
                to: 700
                stopIndicatorValues: [90]
                onValueChanged: {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.digital.font.size", value);
                }
            }

            ConfigSlider {
                text: Translation.tr("Font width")
                value: MonitorBackgrounds.edited.widgets.clock.digital.font.width
                usePercentTooltip: false
                from: 25
                to: 125
                stopIndicatorValues: [100]
                onValueChanged: {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.digital.font.width", value);
                }
            }
            ConfigSlider {
                text: Translation.tr("Font roundness")
                value: MonitorBackgrounds.edited.widgets.clock.digital.font.roundness
                usePercentTooltip: false
                from: 0
                to: 100
                onValueChanged: {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.digital.font.roundness", value);
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Cookie clock settings")

            ConfigSwitch {
                text: Translation.tr("Auto styling with Gemini")
                checked: MonitorBackgrounds.edited.widgets.clock.cookie.aiStyling
                onCheckedChanged: {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.aiStyling", checked);
                }
                StyledToolTip {
                    text: Translation.tr("Uses Gemini to categorize the wallpaper then picks a preset based on it.\nYou'll need to set Gemini API key on the left sidebar first.\nImages are downscaled for performance, but just to be safe,\ndo not select wallpapers with sensitive information.")
                }
            }

            ConfigSwitch {
                text: Translation.tr("Use old sine wave cookie implementation")
                checked: MonitorBackgrounds.edited.widgets.clock.cookie.useSineCookie
                onCheckedChanged: {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.useSineCookie", checked);
                }
                StyledToolTip {
                    text: Translation.tr("Looks a bit softer and more consistent with different number of sides,\nbut has less impressive morphing")
                }
            }

            OptSpin {
                key: "background.widgets.clock.cookie.sides"
                store: MonitorBackgrounds.editedRoot
                writer: (key, value) => MonitorBackgrounds.writeEdited(key, value)
                text: Translation.tr("Sides")
                from: 0
                to: 40
                stepSize: 1
            }

            ConfigSwitch {
                text: Translation.tr("Constantly rotate")
                checked: MonitorBackgrounds.edited.widgets.clock.cookie.constantlyRotate
                onCheckedChanged: {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.constantlyRotate", checked);
                }
                StyledToolTip {
                    text: Translation.tr("Makes the clock always rotate. This is extremely expensive\n(expect 50% usage on Intel UHD Graphics) and thus impractical.")
                }
            }

            ConfigRow {

                ConfigSwitch {
                    enabled: MonitorBackgrounds.edited.widgets.clock.cookie.dialNumberStyle === "dots" || MonitorBackgrounds.edited.widgets.clock.cookie.dialNumberStyle === "full"
                    text: Translation.tr("Hour marks")
                    checked: MonitorBackgrounds.edited.widgets.clock.cookie.hourMarks
                    onEnabledChanged: {
                        checked = MonitorBackgrounds.edited.widgets.clock.cookie.hourMarks;
                    }
                    onCheckedChanged: {
                        MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.hourMarks", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Can only be turned on using the 'Dots' or 'Full' dial style for aesthetic reasons")
                    }
                }

                ConfigSwitch {
                    enabled: MonitorBackgrounds.edited.widgets.clock.cookie.dialNumberStyle !== "numbers"
                    text: Translation.tr("Digits in the middle")
                    checked: MonitorBackgrounds.edited.widgets.clock.cookie.timeIndicators
                    onEnabledChanged: {
                        checked = MonitorBackgrounds.edited.widgets.clock.cookie.timeIndicators;
                    }
                    onCheckedChanged: {
                        MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.timeIndicators", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Can't be turned on when using 'Numbers' dial style for aesthetic reasons")
                    }
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Dial style")
            ConfigSelectionArray {
                currentValue: MonitorBackgrounds.edited.widgets.clock.cookie.dialNumberStyle
                onSelected: newValue => {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.dialNumberStyle", newValue);
                    if (newValue !== "dots" && newValue !== "full") {
                        MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.hourMarks", false);
                    }
                    if (newValue === "numbers") {
                        MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.timeIndicators", false);
                    }
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "none"
                    },
                    {
                        displayName: Translation.tr("Dots"),
                        icon: "graph_6",
                        value: "dots"
                    },
                    {
                        displayName: Translation.tr("Full"),
                        icon: "history_toggle_off",
                        value: "full"
                    },
                    {
                        displayName: Translation.tr("Numbers"),
                        icon: "counter_1",
                        value: "numbers"
                    }
                ]
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Hour hand")
            ConfigSelectionArray {
                currentValue: MonitorBackgrounds.edited.widgets.clock.cookie.hourHandStyle
                onSelected: newValue => {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.hourHandStyle", newValue);
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Hollow"),
                        icon: "circle",
                        value: "hollow"
                    },
                    {
                        displayName: Translation.tr("Fill"),
                        icon: "eraser_size_5",
                        value: "fill"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Minute hand")

            ConfigSelectionArray {
                currentValue: MonitorBackgrounds.edited.widgets.clock.cookie.minuteHandStyle
                onSelected: newValue => {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.minuteHandStyle", newValue);
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Thin"),
                        icon: "line_end",
                        value: "thin"
                    },
                    {
                        displayName: Translation.tr("Medium"),
                        icon: "eraser_size_2",
                        value: "medium"
                    },
                    {
                        displayName: Translation.tr("Bold"),
                        icon: "eraser_size_4",
                        value: "bold"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Second hand")

            ConfigSelectionArray {
                currentValue: MonitorBackgrounds.edited.widgets.clock.cookie.secondHandStyle
                onSelected: newValue => {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.secondHandStyle", newValue);
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Line"),
                        icon: "line_end",
                        value: "line"
                    },
                    {
                        displayName: Translation.tr("Dot"),
                        icon: "adjust",
                        value: "dot"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Date style")

            ConfigSelectionArray {
                currentValue: MonitorBackgrounds.edited.widgets.clock.cookie.dateStyle
                onSelected: newValue => {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.cookie.dateStyle", newValue);
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Bubble"),
                        icon: "bubble_chart",
                        value: "bubble"
                    },
                    {
                        displayName: Translation.tr("Border"),
                        icon: "rotate_right",
                        value: "border"
                    },
                    {
                        displayName: Translation.tr("Rect"),
                        icon: "rectangle",
                        value: "rect"
                    }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Quote")

            ConfigSwitch {
                text: Translation.tr("Enable")
                checked: MonitorBackgrounds.edited.widgets.clock.quote.enable
                onCheckedChanged: {
                    MonitorBackgrounds.writeEdited("background.widgets.clock.quote.enable", checked);
                }
            }
            OptText {
                key: "background.widgets.clock.quote.text"
                store: MonitorBackgrounds.editedRoot
                writer: (key, value) => MonitorBackgrounds.writeEdited(key, value)
                placeholderText: Translation.tr("Quote")
                wide: true
            }
        }

        ContentSubsection {
            title: Translation.tr("Position")
            tooltip: Translation.tr("Used with the \"free\" placement strategy. The other strategies overwrite it")
            ConfigRow {
                uniform: true
                OptSpin {
                    key: "background.widgets.clock.x"
                    store: MonitorBackgrounds.editedRoot
                    writer: (key, value) => MonitorBackgrounds.writeEdited(key, value)
                    text: Translation.tr("X")
                    from: 0
                    to: 10000
                    stepSize: 10
                }
                OptSpin {
                    key: "background.widgets.clock.y"
                    store: MonitorBackgrounds.editedRoot
                    writer: (key, value) => MonitorBackgrounds.writeEdited(key, value)
                    text: Translation.tr("Y")
                    from: 0
                    to: 10000
                    stepSize: 10
                }
            }
        }
    }

    SettingsSection {
        icon: "weather_mix"
        title: Translation.tr("Weather widget")
        enabled: MonitorBackgrounds.editable
        opacity: enabled ? 1 : 0.4

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                text: Translation.tr("Enable")
                checked: MonitorBackgrounds.edited.widgets.weather.enable
                onCheckedChanged: {
                    MonitorBackgrounds.writeEdited("background.widgets.weather.enable", checked);
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: MonitorBackgrounds.edited.widgets.weather.placementStrategy
                onSelected: newValue => {
                    MonitorBackgrounds.writeEdited("background.widgets.weather.placementStrategy", newValue);
                }
                options: [
                    {
                        displayName: Translation.tr("Draggable"),
                        icon: "drag_pan",
                        value: "free"
                    },
                    {
                        displayName: Translation.tr("Least busy"),
                        icon: "category",
                        value: "leastBusy"
                    },
                    {
                        displayName: Translation.tr("Most busy"),
                        icon: "shapes",
                        value: "mostBusy"
                    },
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Position")
            tooltip: Translation.tr("Used with the \"free\" placement strategy. The other strategies overwrite it")
            ConfigRow {
                uniform: true
                OptSpin {
                    key: "background.widgets.weather.x"
                    store: MonitorBackgrounds.editedRoot
                    writer: (key, value) => MonitorBackgrounds.writeEdited(key, value)
                    text: Translation.tr("X")
                    from: 0
                    to: 10000
                    stepSize: 10
                }
                OptSpin {
                    key: "background.widgets.weather.y"
                    store: MonitorBackgrounds.editedRoot
                    writer: (key, value) => MonitorBackgrounds.writeEdited(key, value)
                    text: Translation.tr("Y")
                    from: 0
                    to: 10000
                    stepSize: 10
                }
            }
        }
    }

    SettingsSection {
        icon: "sync_alt"
        title: Translation.tr("Parallax")
        enabled: MonitorBackgrounds.editable
        opacity: enabled ? 1 : 0.4

        ConfigSwitch {
            text: Translation.tr("Vertical")
            checked: MonitorBackgrounds.edited.parallax.vertical
            onCheckedChanged: {
                MonitorBackgrounds.writeEdited("background.parallax.vertical", checked);
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: Translation.tr("Depends on workspace")
                checked: MonitorBackgrounds.edited.parallax.enableWorkspace
                onCheckedChanged: {
                    MonitorBackgrounds.writeEdited("background.parallax.enableWorkspace", checked);
                }
            }
            ConfigSwitch {
                text: Translation.tr("Depends on sidebars")
                checked: MonitorBackgrounds.edited.parallax.enableSidebar
                onCheckedChanged: {
                    MonitorBackgrounds.writeEdited("background.parallax.enableSidebar", checked);
                }
            }
        }
        OptSpin {
            key: "background.parallax.workspaceZoom"
            store: MonitorBackgrounds.editedRoot
            writer: (key, value) => MonitorBackgrounds.writeEdited(key, value)
            text: Translation.tr("Preferred wallpaper zoom")
            suffix: "%"
            from: 10
            to: 200
            stepSize: 1
            scale: 100
        }

        OptSwitch {
            key: "background.parallax.autoVertical"
            store: MonitorBackgrounds.editedRoot
            writer: (key, value) => MonitorBackgrounds.writeEdited(key, value)
            text: Translation.tr("Vertical parallax automatically for portrait wallpapers")
        }
        OptSpin {
            key: "background.parallax.widgetsFactor"
            store: MonitorBackgrounds.editedRoot
            writer: (key, value) => MonitorBackgrounds.writeEdited(key, value)
            text: Translation.tr("Widget parallax factor")
            suffix: "%"
            from: 0
            to: 300
            stepSize: 10
            scale: 100
        }
    }
}
