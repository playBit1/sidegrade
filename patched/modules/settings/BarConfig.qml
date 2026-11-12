import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings

ContentPage {
    forceWidth: true

    SettingsSection {
        icon: "spoke"
        title: Translation.tr("Positioning")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Automatically hide")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {
            
            ContentSubsection {
                title: Translation.tr("Corner style")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Group style")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => {
                        Config.options.bar.borderless = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Pills"),
                            icon: "location_chip",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Line-separated"),
                            icon: "split_scene",
                            value: true
                        }
                    ]
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Auto-hide behavior")
            OptSpin {
                key: "bar.autoHide.hoverRegionWidth"
                text: Translation.tr("Hover region width")
                suffix: "px"
                from: 1
                to: 100
                stepSize: 1
            }
            OptSwitch {
                key: "bar.autoHide.pushWindows"
                text: Translation.tr("Push windows aside while the bar is revealed")
            }
            OptSwitch {
                key: "bar.autoHide.showWhenPressingSuper.enable"
                text: Translation.tr("Reveal the bar and workspace numbers while holding Super")
            }
            OptSpin {
                key: "bar.autoHide.showWhenPressingSuper.delay"
                text: Translation.tr("Super hold delay")
                suffix: "ms"
                from: 0
                to: 2000
                stepSize: 10
            }
        }
        ContentSubsection {
            title: Translation.tr("Screens")
            tooltip: Translation.tr("Leave empty to show the bar on every monitor.\nFind monitor names with 'hyprctl monitors'")
            OptList {
                key: "bar.screenList"
                placeholderText: Translation.tr("Monitors to show the bar on (comma-separated, e.g. DP-1, HDMI-A-1)")
            }
        }
    }

    SettingsSection {
        icon: "palette"
        title: Translation.tr("Appearance")
        OptSwitch {
            key: "bar.showBackground"
            text: Translation.tr("Show bar background")
        }
        OptSwitch {
            key: "bar.floatStyleShadow"
            text: Translation.tr("Shadow behind the bar (float corner style only)")
        }
        OptSwitch {
            key: "bar.verbose"
            text: Translation.tr("Verbose (wider center modules, show the date)")
        }
        OptText {
            key: "bar.topLeftIcon"
            placeholderText: Translation.tr("Top-left icon: \"distro\" or an icon name from assets/icons (e.g. spark)")
            wide: true
        }
    }

    SettingsSection {
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ConfigSwitch {
            text: Translation.tr('Always show numbers')
            checked: Config.options.bar.workspaces.alwaysShowNumbers
            onCheckedChanged: {
                Config.options.bar.workspaces.alwaysShowNumbers = checked;
            }
        }

        ConfigSwitch {
            text: Translation.tr('Show app icons')
            checked: Config.options.bar.workspaces.showAppIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.showAppIcons = checked;
            }
        }

        ConfigSwitch {
            text: Translation.tr('Tint app icons')
            checked: Config.options.bar.workspaces.monochromeIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.monochromeIcons = checked;
            }
        }

        OptSpin {
            key: "bar.workspaces.shown"
            text: Translation.tr("Workspaces shown")
            from: 1
            to: 30
            stepSize: 1
        }


        ContentSubsection {
            title: Translation.tr("Number style")

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                }
                options: [
                    {
                        displayName: Translation.tr("Normal"),
                        icon: "timer_10",
                        value: '[]'
                    },
                    {
                        displayName: Translation.tr("Han chars"),
                        icon: "square_dot",
                        value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
                    },
                    {
                        displayName: Translation.tr("Roman"),
                        icon: "account_balance",
                        value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
                    }
                ]
            }
        }

        OptSwitch {
            key: "bar.workspaces.useNerdFont"
            text: Translation.tr("Use Nerd Font for workspace numbers")
        }
    }

    SettingsSection {
        icon: "widgets"
        title: Translation.tr("Utility buttons")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: Translation.tr("Screen snip")
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenSnip = checked;
                }
            }
            ConfigSwitch {
                text: Translation.tr("Color picker")
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showColorPicker = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: Translation.tr("Keyboard toggle")
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showKeyboardToggle = checked;
                }
            }
            ConfigSwitch {
                text: Translation.tr("Mic toggle")
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showMicToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: Translation.tr("Dark/Light toggle")
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showDarkModeToggle = checked;
                }
            }
            ConfigSwitch {
                text: Translation.tr("Performance Profile toggle")
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: Translation.tr("Record")
                checked: Config.options.bar.utilButtons.showScreenRecord
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenRecord = checked;
                }
            }
        }
    }

    SettingsSection {
        icon: "shelf_auto_hide"
        title: Translation.tr("Tray")

        ConfigSwitch {
            text: Translation.tr('Make icons pinned by default')
            checked: Config.options.tray.invertPinnedItems
            onCheckedChanged: {
                Config.options.tray.invertPinnedItems = checked;
            }
        }
        
        ConfigSwitch {
            text: Translation.tr('Tint icons')
            checked: Config.options.tray.monochromeIcons
            onCheckedChanged: {
                Config.options.tray.monochromeIcons = checked;
            }
        }

        OptSwitch {
            key: "tray.filterPassive"
            text: Translation.tr("Hide passive items (smart tray)")
        }
        OptSwitch {
            key: "tray.showItemId"
            text: Translation.tr("Show item ID in tooltips")
            tooltip: Translation.tr("Useful for finding the IDs to put in the pinned list")
        }
        OptList {
            key: "tray.pinnedItems"
            placeholderText: Translation.tr("Pinned item IDs (comma-separated)")
        }
    }

    SettingsSection {
        icon: "memory"
        title: Translation.tr("Resources")
        ConfigRow {
            uniform: true
            OptSwitch {
                key: "bar.resources.alwaysShowCpu"
                text: Translation.tr("Always show CPU")
            }
            OptSwitch {
                key: "bar.resources.alwaysShowSwap"
                text: Translation.tr("Always show swap")
            }
        }
        OptSpin {
            key: "bar.resources.cpuWarningThreshold"
            text: Translation.tr("CPU warning threshold")
            suffix: "%"
            from: 0
            to: 100
            stepSize: 5
        }
        OptSpin {
            key: "bar.resources.memoryWarningThreshold"
            text: Translation.tr("Memory warning threshold")
            suffix: "%"
            from: 0
            to: 100
            stepSize: 5
        }
        OptSpin {
            key: "bar.resources.swapWarningThreshold"
            text: Translation.tr("Swap warning threshold")
            suffix: "%"
            from: 0
            to: 100
            stepSize: 5
        }
    }

    SettingsSection {
        icon: "cloud"
        title: Translation.tr("Weather")
        ConfigSwitch {
            text: Translation.tr("Enable")
            checked: Config.options.bar.weather.enable
            onCheckedChanged: {
                Config.options.bar.weather.enable = checked;
            }
        }
    }

    SettingsSection {
        icon: "notifications"
        title: Translation.tr("Notifications")
        ConfigSwitch {
            text: Translation.tr("Unread indicator: show count")
            checked: Config.options.bar.indicators.notifications.showUnreadCount
            onCheckedChanged: {
                Config.options.bar.indicators.notifications.showUnreadCount = checked;
            }
        }
    }

    SettingsSection {
        icon: "tooltip"
        title: Translation.tr("Tooltips")
        ConfigSwitch {
            text: Translation.tr("Click to show")
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
        }
    }
}
