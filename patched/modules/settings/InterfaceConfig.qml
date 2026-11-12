import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings

ContentPage {
    forceWidth: true

    SettingsSection {
        icon: "palette"
        title: Translation.tr("Appearance")
        OptSwitch {
            key: "appearance.extraBackgroundTint"
            text: Translation.tr("Extra background tint")
            tooltip: Translation.tr("Mixes a little of the accent color into backgrounds")
        }
        ContentSubsection {
            title: Translation.tr("Transparency")
            tooltip: Translation.tr("Transparency itself is turned on in the Quick page")
            OptSwitch {
                key: "appearance.transparency.automatic"
                text: Translation.tr("Automatic amount (based on the wallpaper)")
            }
            OptSlider {
                key: "appearance.transparency.backgroundTransparency"
                text: Translation.tr("Background transparency")
                enabled: !Config.options.appearance.transparency.automatic
            }
            OptSlider {
                key: "appearance.transparency.contentTransparency"
                text: Translation.tr("Content transparency")
                enabled: !Config.options.appearance.transparency.automatic
            }
        }
        ContentSubsection {
            title: Translation.tr("Accent color")
            tooltip: Translation.tr("Takes effect the next time colors are generated (e.g. on wallpaper change)")
            OptText {
                key: "appearance.palette.accentColor"
                placeholderText: Translation.tr("Hex color (empty = from wallpaper)")
            }
        }
    }

    SettingsSection {
        icon: "side_navigation"
        title: Translation.tr("Sidebars")

        ConfigSwitch {
            text: Translation.tr('Keep right sidebar loaded')
            checked: Config.options.sidebar.keepRightSidebarLoaded
            onCheckedChanged: {
                Config.options.sidebar.keepRightSidebarLoaded = checked;
            }
            StyledToolTip {
                text: Translation.tr("When enabled keeps the content of the right sidebar loaded to reduce the delay when opening,\nat the cost of around 15MB of consistent RAM usage. Delay significance depends on your system's performance.\nUsing a custom kernel like linux-cachyos might help")
            }
        }

        ConfigSwitch {
            text: Translation.tr('Enable translator')
            checked: Config.options.sidebar.translator.enable
            onCheckedChanged: {
                Config.options.sidebar.translator.enable = checked;
            }
        }

        ContentSubsection {
            title: Translation.tr("Quick toggles")
            
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.sidebar.quickToggles.style
                onSelected: newValue => {
                    Config.options.sidebar.quickToggles.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "password_2",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Android"),
                        icon: "action_key",
                        value: "android"
                    }
                ]
            }

            ConfigSpinBox {
                enabled: Config.options.sidebar.quickToggles.style === "android"
                text: Translation.tr("Columns")
                value: Config.options.sidebar.quickToggles.android.columns
                from: 1
                to: 8
                stepSize: 1
                onValueChanged: {
                    Config.options.sidebar.quickToggles.android.columns = value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Sliders")

            ConfigSwitch {
                text: Translation.tr("Enable")
                checked: Config.options.sidebar.quickSliders.enable
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.enable = checked;
                }
            }
            
            ConfigSwitch {
                text: Translation.tr("Brightness")
                enabled: Config.options.sidebar.quickSliders.enable
                checked: Config.options.sidebar.quickSliders.showBrightness
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.showBrightness = checked;
                }
            }

            ConfigSwitch {
                text: Translation.tr("Volume")
                enabled: Config.options.sidebar.quickSliders.enable
                checked: Config.options.sidebar.quickSliders.showVolume
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.showVolume = checked;
                }
            }

            ConfigSwitch {
                text: Translation.tr("Microphone")
                enabled: Config.options.sidebar.quickSliders.enable
                checked: Config.options.sidebar.quickSliders.showMic
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.showMic = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Corner open")
            tooltip: Translation.tr("Allows you to open sidebars by clicking or hovering screen corners regardless of bar position")
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: Translation.tr("Enable")
                    checked: Config.options.sidebar.cornerOpen.enable
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.enable = checked;
                    }
                }
            }
            ConfigSwitch {
                text: Translation.tr("Hover to trigger")
                checked: Config.options.sidebar.cornerOpen.clickless
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.clickless = checked;
                }

                StyledToolTip {
                    text: Translation.tr("When this is off you'll have to click")
                }
            }
            Row {
                ConfigSwitch {
                    enabled: !Config.options.sidebar.cornerOpen.clickless
                    text: Translation.tr("Force hover open at absolute corner")
                    checked: Config.options.sidebar.cornerOpen.clicklessCornerEnd
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.clicklessCornerEnd = checked;
                    }

                    StyledToolTip {
                        text: Translation.tr("When the previous option is off and this is on,\nyou can still hover the corner's end to open sidebar,\nand the remaining area can be used for volume/brightness scroll")
                    }
                }
                ConfigSpinBox {
                    text: Translation.tr("with vertical offset")
                    value: Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset
                    from: 0
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset = value;
                    }
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        StyledToolTip {
                            extraVisibleCondition: mouseArea.containsMouse
                            text: Translation.tr("Why this is cool:\nFor non-0 values, it won't trigger when you reach the\nscreen corner along the horizontal edge, but it will when\nyou do along the vertical edge")
                        }
                    }
                }
            }
            
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: Translation.tr("Place at bottom")
                    checked: Config.options.sidebar.cornerOpen.bottom
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.bottom = checked;
                    }

                    StyledToolTip {
                        text: Translation.tr("Place the corners to trigger at the bottom")
                    }
                }
                ConfigSwitch {
                    text: Translation.tr("Value scroll")
                    checked: Config.options.sidebar.cornerOpen.valueScroll
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.valueScroll = checked;
                    }

                    StyledToolTip {
                        text: Translation.tr("Brightness and volume")
                    }
                }
            }
            ConfigSwitch {
                text: Translation.tr("Visualize region")
                checked: Config.options.sidebar.cornerOpen.visualize
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.visualize = checked;
                }
            }
            ConfigRow {
                OptSpin {
                    key: "sidebar.cornerOpen.cornerRegionWidth"
                    text: Translation.tr("Region width")
                    from: 1
                    to: 300
                    stepSize: 1
                }
                OptSpin {
                    key: "sidebar.cornerOpen.cornerRegionHeight"
                    text: Translation.tr("Region height")
                    from: 1
                    to: 300
                    stepSize: 1
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("AI & translator")
            OptSwitch {
                key: "sidebar.ai.textFadeIn"
                text: Translation.tr("Fade in AI response text")
            }
            OptSpin {
                key: "sidebar.translator.delay"
                text: Translation.tr("Translator request delay")
                suffix: "ms"
                from: 0
                to: 5000
                stepSize: 50
            }
        }
    }

    SettingsSection {
        icon: "call_to_action"
        title: Translation.tr("Dock")

        ConfigSwitch {
            text: Translation.tr("Enable")
            checked: Config.options.dock.enable
            onCheckedChanged: {
                Config.options.dock.enable = checked;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: Translation.tr("Hover to reveal")
                checked: Config.options.dock.hoverToReveal
                onCheckedChanged: {
                    Config.options.dock.hoverToReveal = checked;
                }
            }
            ConfigSwitch {
                text: Translation.tr("Pinned on startup")
                checked: Config.options.dock.pinnedOnStartup
                onCheckedChanged: {
                    Config.options.dock.pinnedOnStartup = checked;
                }
            }
        }
        ConfigSwitch {
            text: Translation.tr("Tint app icons")
            checked: Config.options.dock.monochromeIcons
            onCheckedChanged: {
                Config.options.dock.monochromeIcons = checked;
            }
        }

        OptSpin {
            key: "dock.height"
            text: Translation.tr("Height")
            suffix: "px"
            from: 30
            to: 200
            stepSize: 2
        }
        OptSpin {
            key: "dock.hoverRegionHeight"
            text: Translation.tr("Hover region height")
            suffix: "px"
            from: 1
            to: 100
            stepSize: 1
        }
        OptList {
            key: "dock.pinnedApps"
            placeholderText: Translation.tr("Pinned apps (desktop entry IDs, comma-separated)")
        }
        OptList {
            key: "dock.ignoredAppRegexes"
            placeholderText: Translation.tr("Ignored apps (one regular expression per line)")
            separator: "\n"
        }
    }

    SettingsSection {
        icon: "apps"
        title: Translation.tr("Launcher")
        OptList {
            key: "launcher.pinnedApps"
            placeholderText: Translation.tr("Pinned apps (desktop entry IDs, comma-separated)")
        }
    }

    SettingsSection {
        icon: "overview_key"
        title: Translation.tr("Overview")

        ConfigSwitch {
            text: Translation.tr("Enable")
            checked: Config.options.overview.enable
            onCheckedChanged: {
                Config.options.overview.enable = checked;
            }
        }
        ConfigSwitch {
            text: Translation.tr("Center icons")
            checked: Config.options.overview.centerIcons
            onCheckedChanged: {
                Config.options.overview.centerIcons = checked;
            }
        }
        OptSpin {
            key: "overview.scale"
            text: Translation.tr("Scale")
            suffix: "%"
            from: 1
            to: 100
            stepSize: 1
            scale: 100
        }
        ConfigRow {
            uniform: true
            OptSpin {
                key: "overview.rows"
                text: Translation.tr("Rows")
                from: 1
                to: 20
                stepSize: 1
            }
            OptSpin {
                key: "overview.columns"
                text: Translation.tr("Columns")
                from: 1
                to: 20
                stepSize: 1
            }
        }
        ConfigRow {
            uniform: true
            ConfigSelectionArray {
                currentValue: Config.options.overview.orderRightLeft
                onSelected: newValue => {
                    Config.options.overview.orderRightLeft = newValue
                }
                options: [
                    {
                        displayName: Translation.tr("Left to right"),
                        icon: "arrow_forward",
                        value: 0
                    },
                    {
                        displayName: Translation.tr("Right to left"),
                        icon: "arrow_back",
                        value: 1
                    }
                ]
            }
            ConfigSelectionArray {
                currentValue: Config.options.overview.orderBottomUp
                onSelected: newValue => {
                    Config.options.overview.orderBottomUp = newValue
                }
                options: [
                    {
                        displayName: Translation.tr("Top-down"),
                        icon: "arrow_downward",
                        value: 0
                    },
                    {
                        displayName: Translation.tr("Bottom-up"),
                        icon: "arrow_upward",
                        value: 1
                    }
                ]
            }
        }
    }

    SettingsSection {
        icon: "notifications"
        title: Translation.tr("Notifications")

        OptSpin {
            key: "notifications.timeout"
            text: Translation.tr("Timeout duration (if not defined by notification)")
            suffix: "ms"
            from: 1000
            to: 60000
            stepSize: 1000
        }

        ConfigSwitch {
            text: Translation.tr("Force specific monitor")
            checked: Config.options.notifications.monitor.enable
            onCheckedChanged: {
                Config.options.notifications.monitor.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("If you have multiple monitors and want notifications to only show on one of them, enable this and enter the monitor name below (e.g., eDP-1)")
            }
        }

        ConfigRow {
            enabled: Config.options.notifications.monitor.enable
            OptText {
                key: "notifications.monitor.name"
                placeholderText: Translation.tr("Monitor name to show notifications on (e.g., eDP-1)")
                wide: true
            }
        }
    }

    SettingsSection {
        icon: "voting_chip"
        title: Translation.tr("On-screen display")

        OptSpin {
            key: "osd.timeout"
            text: Translation.tr("Timeout")
            suffix: "ms"
            from: 100
            to: 3000
            stepSize: 100
        }
    }

    SettingsSection {
        icon: "lock"
        title: Translation.tr("Lock screen")

        ConfigSwitch {
            text: Translation.tr('Use Hyprlock (instead of Quickshell)')
            checked: Config.options.lock.useHyprlock
            onCheckedChanged: {
                Config.options.lock.useHyprlock = checked;
            }
            StyledToolTip {
                text: Translation.tr("If you want to somehow use fingerprint unlock...")
            }
        }

        ConfigSwitch {
            text: Translation.tr('Launch on startup')
            checked: Config.options.lock.launchOnStartup
            onCheckedChanged: {
                Config.options.lock.launchOnStartup = checked;
            }
        }

        ContentSubsection {
            title: Translation.tr("Security")

            ConfigSwitch {
                text: Translation.tr('Require password to power off/restart')
                checked: Config.options.lock.security.requirePasswordToPower
                onCheckedChanged: {
                    Config.options.lock.security.requirePasswordToPower = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Remember that on most devices one can always hold the power button to force shutdown\nThis only makes it a tiny bit harder for accidents to happen")
                }
            }

            ConfigSwitch {
                text: Translation.tr('Also unlock keyring')
                checked: Config.options.lock.security.unlockKeyring
                onCheckedChanged: {
                    Config.options.lock.security.unlockKeyring = checked;
                }
                StyledToolTip {
                    text: Translation.tr("This is usually safe and needed for your browser and AI sidebar anyway\nMostly useful for those who use lock on startup instead of a display manager that does it (GDM, SDDM, etc.)")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Style: general")

            ConfigSwitch {
                text: Translation.tr('Center clock')
                checked: Config.options.lock.centerClock
                onCheckedChanged: {
                    Config.options.lock.centerClock = checked;
                }
            }

            ConfigSwitch {
                text: Translation.tr('Show "Locked" text')
                checked: Config.options.lock.showLockedText
                onCheckedChanged: {
                    Config.options.lock.showLockedText = checked;
                }
            }

            ConfigSwitch {
                text: Translation.tr('Use varying shapes for password characters')
                checked: Config.options.lock.materialShapeChars
                onCheckedChanged: {
                    Config.options.lock.materialShapeChars = checked;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Style: Blurred")

            ConfigSwitch {
                text: Translation.tr('Enable blur')
                checked: Config.options.lock.blur.enable
                onCheckedChanged: {
                    Config.options.lock.blur.enable = checked;
                }
            }

            OptSpin {
                key: "lock.blur.extraZoom"
                text: Translation.tr("Extra wallpaper zoom")
                suffix: "%"
                from: 1
                to: 150
                stepSize: 2
                scale: 100
            }
        }

        OptSpin {
            key: "lock.blur.radius"
            text: Translation.tr("Blur radius")
            from: 0
            to: 300
            stepSize: 10
        }
    }

    SettingsSection {
        icon: "screenshot_frame_2"
        title: Translation.tr("Region selector")

        ContentSubsection {
            title: Translation.tr("Hint target regions")
            ConfigRow {
                ConfigSwitch {
                    text: Translation.tr('Windows')
                    checked: Config.options.regionSelector.targetRegions.windows
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.windows = checked;
                    }
                }
                ConfigSwitch {
                    text: Translation.tr('Layers')
                    checked: Config.options.regionSelector.targetRegions.layers
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.layers = checked;
                    }
                }
                ConfigSwitch {
                    text: Translation.tr('Content')
                    checked: Config.options.regionSelector.targetRegions.content
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.content = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Could be images or parts of the screen that have some containment.\nMight not always be accurate.\nThis is done with an image processing algorithm run locally and no AI is used.")
                    }
                }
            }
        }
        
        ContentSubsection {
            title: Translation.tr("Google Lens")
            
            ConfigSelectionArray {
                currentValue: Config.options.search.imageSearch.useCircleSelection ? "circle" : "rectangles"
                onSelected: newValue => {
                    Config.options.search.imageSearch.useCircleSelection = (newValue === "circle");
                }
                options: [
                    { icon: "activity_zone", value: "rectangles", displayName: Translation.tr("Rectangular selection") },
                    { icon: "gesture", value: "circle", displayName: Translation.tr("Circle to Search") }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Rectangular selection")

            ConfigSwitch {
                text: Translation.tr("Show aim lines")
                checked: Config.options.regionSelector.rect.showAimLines
                onCheckedChanged: {
                    Config.options.regionSelector.rect.showAimLines = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Circle selection")
            
            OptSpin {
                key: "regionSelector.circle.strokeWidth"
                text: Translation.tr("Stroke width")
                from: 1
                to: 20
                stepSize: 1
            }

            OptSpin {
                key: "regionSelector.circle.padding"
                text: Translation.tr("Padding")
                from: 0
                to: 100
                stepSize: 5
            }
        }

        ContentSubsection {
            title: Translation.tr("Target region appearance")
            OptSwitch {
                key: "regionSelector.targetRegions.showLabel"
                text: Translation.tr("Show labels on target regions")
            }
            OptSlider {
                key: "regionSelector.targetRegions.opacity"
                text: Translation.tr("Region opacity")
            }
            OptSlider {
                key: "regionSelector.targetRegions.contentRegionOpacity"
                text: Translation.tr("Content region opacity")
            }
            OptSpin {
                key: "regionSelector.targetRegions.selectionPadding"
                text: Translation.tr("Selection padding")
                suffix: "px"
                from: 0
                to: 50
                stepSize: 1
            }
        }
        ContentSubsection {
            title: Translation.tr("Annotation")
            OptSwitch {
                key: "regionSelector.annotation.useSatty"
                text: Translation.tr("Use satty instead of swappy")
            }
        }
    }

    SettingsSection {
        icon: "keyboard"
        title: Translation.tr("On-screen keyboard")
        OptText {
            key: "osk.layout"
            placeholderText: Translation.tr("Layout name (e.g. qwerty_full)")
        }
        OptSwitch {
            key: "osk.pinnedOnStartup"
            text: Translation.tr("Pinned on startup")
        }
    }

    SettingsSection {
        icon: "keyboard"
        title: Translation.tr("Cheat sheet")

        ContentSubsection {
            title: Translation.tr("Super key symbol")
            tooltip: Translation.tr("You can also manually edit cheatsheet.superKey")
            ConfigSelectionArray {
                currentValue: Config.options.cheatsheet.superKey
                onSelected: newValue => {
                    Config.options.cheatsheet.superKey = newValue;
                }
                // Use a nerdfont to see the icons
                options: ([
                  "󰖳", "", "󰨡", "", "󰌽", "󰣇", "", "", "", 
                  "", "", "󱄛", "", "", "", "⌘", "󰀲", "󰟍", ""
                ]).map(icon => { return {
                  displayName: icon,
                  value: icon
                  }
                })
            }
        }

        ConfigSwitch {
            text: Translation.tr("Use macOS-like symbols for mods keys")
            checked: Config.options.cheatsheet.useMacSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.useMacSymbol = checked;
            }
            StyledToolTip {
                text: Translation.tr("e.g. 󰘴  for Ctrl, 󰘵  for Alt, 󰘶  for Shift, etc")
            }
        }

        ConfigSwitch {
            text: Translation.tr("Use symbols for function keys")
            checked: Config.options.cheatsheet.useFnSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.useFnSymbol = checked;
            }
            StyledToolTip {
              text: Translation.tr("e.g. 󱊫 for F1, 󱊶  for F12")
            }
        }
        ConfigSwitch {
            text: Translation.tr("Use symbols for mouse")
            checked: Config.options.cheatsheet.useMouseSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.useMouseSymbol = checked;
            }
            StyledToolTip {
              text: Translation.tr("Replace 󱕐   for \"Scroll ↓\", 󱕑   \"Scroll ↑\", L󰍽   \"LMB\", R󰍽   \"RMB\", 󱕒   \"Scroll ↑/↓\" and ⇞/⇟ for \"Page_↑/↓\"")
            }
        }
        ConfigSwitch {
            text: Translation.tr("Split buttons")
            checked: Config.options.cheatsheet.splitButtons
            onCheckedChanged: {
                Config.options.cheatsheet.splitButtons = checked;
            }
            StyledToolTip {
                text: Translation.tr("Display modifiers and keys in multiple keycap (e.g., \"Ctrl + A\" instead of \"Ctrl A\" or \"󰘴 + A\" instead of \"󰘴 A\")")
            }

        }

        OptSpin {
            key: "cheatsheet.fontSize.key"
            text: Translation.tr("Keybind font size")
            from: 8
            to: 30
            stepSize: 1
        }
        OptSpin {
            key: "cheatsheet.fontSize.comment"
            text: Translation.tr("Description font size")
            from: 8
            to: 30
            stepSize: 1
        }
    }

    SettingsSection {
        icon: "select_window"
        title: Translation.tr("Overlay")

        ConfigSwitch {
            text: Translation.tr("Enable opening zoom animation")
            checked: Config.options.overlay.openingZoomAnimation
            onCheckedChanged: {
                Config.options.overlay.openingZoomAnimation = checked;
            }
        }
        ConfigSwitch {
            text: Translation.tr("Darken screen")
            checked: Config.options.overlay.darkenScreen
            onCheckedChanged: {
                Config.options.overlay.darkenScreen = checked;
            }
        }

        OptSlider {
            key: "overlay.clickthroughOpacity"
            text: Translation.tr("Opacity of click-through widgets")
        }
    }

    SettingsSection {
        icon: "point_scan"
        title: Translation.tr("Crosshair overlay")

        OptText {
            key: "crosshair.code"
            placeholderText: Translation.tr("Crosshair code (in Valorant's format)")
            wide: true
        }

        RowLayout {
            StyledText {
                Layout.leftMargin: 10
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallie
                text: Translation.tr("Press Super+G to open the overlay and pin the crosshair")
            }
            Item {
                Layout.fillWidth: true
            }
            RippleButtonWithIcon {
                id: editorButton
                buttonRadius: Appearance.rounding.full
                materialIcon: "open_in_new"
                mainText: Translation.tr("Open editor")
                onClicked: {
                    Qt.openUrlExternally(`https://www.vcrdb.net/builder?c=${Config.options.crosshair.code}`);
                }
                StyledToolTip {
                    text: "www.vcrdb.net"
                }
            }
        }
    }

    SettingsSection {
        icon: "point_scan"
        title: Translation.tr("Floating image overlay")

        OptText {
            key: "overlay.floatingImage.imageSource"
            placeholderText: Translation.tr("Image source")
            wide: true
        }

        OptSpin {
            key: "overlay.floatingImage.scale"
            text: Translation.tr("Scale")
            suffix: "%"
            from: 10
            to: 500
            stepSize: 10
            scale: 100
        }
    }

    SettingsSection {
        icon: "wallpaper_slideshow"
        title: Translation.tr("Wallpaper selector")

        ConfigSwitch {
            text: Translation.tr('Use system file picker')
            checked: Config.options.wallpaperSelector.useSystemFileDialog
            onCheckedChanged: {
                Config.options.wallpaperSelector.useSystemFileDialog = checked;
            }
        }
    }

    SettingsSection {
        icon: "web_asset"
        title: Translation.tr("Shell windows")
        OptSwitch {
            key: "windows.showTitlebar"
            text: Translation.tr("Show titlebar on shell apps (like this one)")
        }
        OptSwitch {
            key: "windows.centerTitle"
            text: Translation.tr("Center the title")
        }
    }

    SettingsSection {
        icon: "text_format"
        title: Translation.tr("Fonts")

        ContentSubsection {
            title: Translation.tr("Main font")
            tooltip: Translation.tr("Used for general UI text")

            OptText {
                key: "appearance.fonts.main"
                placeholderText: Translation.tr("Font family name (e.g., Google Sans Flex)")
                wide: true
            }
        }

        ContentSubsection {
            title: Translation.tr("Numbers font")
            tooltip: Translation.tr("Used for displaying numbers")

            OptText {
                key: "appearance.fonts.numbers"
                placeholderText: Translation.tr("Font family name")
                wide: true
            }
        }

        ContentSubsection {
            title: Translation.tr("Title font")
            tooltip: Translation.tr("Used for headings and titles")

            OptText {
                key: "appearance.fonts.title"
                placeholderText: Translation.tr("Font family name")
                wide: true
            }
        }

        ContentSubsection {
            title: Translation.tr("Monospace font")
            tooltip: Translation.tr("Used for code and terminal")

            OptText {
                key: "appearance.fonts.monospace"
                placeholderText: Translation.tr("Font family name (e.g., JetBrains Mono NF)")
                wide: true
            }
        }

        ContentSubsection {
            title: Translation.tr("Nerd font icons")
            tooltip: Translation.tr("Font used for Nerd Font icons")

            OptText {
                key: "appearance.fonts.iconNerd"
                placeholderText: Translation.tr("Font family name (e.g., JetBrains Mono NF)")
                wide: true
            }
        }

        ContentSubsection {
            title: Translation.tr("Reading font")
            tooltip: Translation.tr("Used for reading large blocks of text")

            OptText {
                key: "appearance.fonts.reading"
                placeholderText: Translation.tr("Font family name (e.g., Readex Pro)")
                wide: true
            }
        }

        ContentSubsection {
            title: Translation.tr("Expressive font")
            tooltip: Translation.tr("Used for decorative/expressive text")

            OptText {
                key: "appearance.fonts.expressive"
                placeholderText: Translation.tr("Font family name (e.g., Space Grotesk)")
                wide: true
            }
        }
    }
}
