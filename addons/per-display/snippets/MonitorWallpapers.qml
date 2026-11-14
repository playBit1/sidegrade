ContentSection {
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
