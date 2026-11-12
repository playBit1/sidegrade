import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings

ContentPage {
    forceWidth: true

    SettingsSection {
        icon: "dashboard"
        title: Translation.tr("Panel family")
        ConfigSelectionArray {
            currentValue: Config.options.panelFamily
            onSelected: newValue => {
                Config.options.panelFamily = newValue;
            }
            options: [
                { displayName: Translation.tr("illogical-impulse"), icon: "bubble_chart", value: "ii" },
                { displayName: Translation.tr("Waffle (Windows-like)"), icon: "window", value: "waffle" },
            ]
        }
    }

    SettingsSection {
        icon: "mouse"
        title: Translation.tr("Scrolling")
        OptSwitch {
            key: "interactions.scrolling.fasterTouchpadScroll"
            text: Translation.tr("Faster touchpad scrolling")
        }
        OptSpin {
            key: "interactions.scrolling.mouseScrollFactor"
            text: Translation.tr("Mouse scroll factor")
            from: 10
            to: 1000
            stepSize: 10
        }
        OptSpin {
            key: "interactions.scrolling.touchpadScrollFactor"
            text: Translation.tr("Touchpad scroll factor")
            from: 10
            to: 2000
            stepSize: 10
        }
        OptSpin {
            key: "interactions.scrolling.mouseScrollDeltaThreshold"
            text: Translation.tr("Mouse detection threshold (delta)")
            from: 1
            to: 1000
            stepSize: 10
        }
    }

    SettingsSection {
        icon: "colors"
        title: Translation.tr("Color generation")

        ConfigSwitch {
            text: Translation.tr("Shell & utilities")
            checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked;
            }
        }
        ConfigSwitch {
            text: Translation.tr("Qt apps")
            checked: Config.options.appearance.wallpaperTheming.enableQtApps
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableQtApps = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shell & utilities theming must also be enabled")
            }
        }
        ConfigSwitch {
            text: Translation.tr("Terminal")
            checked: Config.options.appearance.wallpaperTheming.enableTerminal
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableTerminal = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shell & utilities theming must also be enabled")
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: Translation.tr("Force dark mode in terminal")
                checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
                onCheckedChanged: {
                     Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode= checked;
                }
                StyledToolTip {
                    text: Translation.tr("Ignored if terminal theming is not enabled")
                }
            }
        }

        OptSpin {
            key: "appearance.wallpaperTheming.terminalGenerationProps.harmony"
            text: Translation.tr("Terminal: Harmony")
            suffix: "%"
            from: 0
            to: 100
            stepSize: 10
            scale: 100
        }
        OptSpin {
            key: "appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold"
            text: Translation.tr("Terminal: Harmonize threshold")
            from: 0
            to: 100
            stepSize: 10
        }
        OptSpin {
            key: "appearance.wallpaperTheming.terminalGenerationProps.termFgBoost"
            text: Translation.tr("Terminal: Foreground boost")
            suffix: "%"
            from: 0
            to: 100
            stepSize: 10
            scale: 100
        }
    }

    SettingsSection {
        icon: "swords"
        title: Translation.tr("Conflict killer")
        OptSwitch {
            key: "conflictKiller.autoKillNotificationDaemons"
            text: Translation.tr("Automatically kill other notification daemons")
        }
        OptSwitch {
            key: "conflictKiller.autoKillTrays"
            text: Translation.tr("Automatically kill other trays")
        }
    }

    SettingsSection {
        icon: "build"
        title: Translation.tr("Workarounds")
        OptSwitch {
            key: "interactions.deadPixelWorkaround.enable"
            text: Translation.tr("Dead pixel workaround")
            tooltip: Translation.tr("Hyprland leaves 1 pixel on the right edge out of interactions")
        }
        OptSpin {
            key: "hacks.arbitraryRaceConditionDelay"
            text: Translation.tr("Race condition delay")
            suffix: "ms"
            from: 0
            to: 1000
            stepSize: 5
        }
    }
}
