import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.settings

ContentPage {
    forceWidth: true

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    SettingsSection {
        icon: "nest_clock_farsight_analog"
        title: Translation.tr("Time")

        ConfigSwitch {
            text: Translation.tr("Second precision")
            checked: Config.options.time.secondPrecision
            onCheckedChanged: {
                Config.options.time.secondPrecision = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enable if you want clocks to show seconds accurately")
            }
        }

        ContentSubsection {
            title: Translation.tr("Format")
            tooltip: ""

            ConfigSelectionArray {
                currentValue: Config.options.time.format
                onSelected: newValue => {
                    if (newValue === "hh:mm") {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    } else {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    }

                    Config.options.time.format = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("24h"),
                        value: "hh:mm"
                    },
                    {
                        displayName: Translation.tr("12h am/pm"),
                        value: "h:mm ap"
                    },
                    {
                        displayName: Translation.tr("12h AM/PM"),
                        value: "h:mm AP"
                    },
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Date formats")
            tooltip: Translation.tr("Qt date format strings, see https://doc.qt.io/qt-6/qtime.html#toString")
            OptText {
                key: "time.dateFormat"
                placeholderText: Translation.tr("Date format (e.g. ddd, dd/MM)")
            }
            ConfigRow {
                uniform: true
                OptText {
                    key: "time.shortDateFormat"
                    placeholderText: Translation.tr("Short date (e.g. dd/MM)")
                    wide: true
                }
                OptText {
                    key: "time.dateWithYearFormat"
                    placeholderText: Translation.tr("Date with year (e.g. dd/MM/yyyy)")
                    wide: true
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Pomodoro")
            OptSpin {
                key: "time.pomodoro.focus"
                text: Translation.tr("Focus")
                suffix: "s"
                from: 60
                to: 7200
                stepSize: 60
            }
            OptSpin {
                key: "time.pomodoro.breakTime"
                text: Translation.tr("Break")
                suffix: "s"
                from: 60
                to: 3600
                stepSize: 60
            }
            OptSpin {
                key: "time.pomodoro.longBreak"
                text: Translation.tr("Long break")
                suffix: "s"
                from: 60
                to: 7200
                stepSize: 60
            }
            OptSpin {
                key: "time.pomodoro.cyclesBeforeLongBreak"
                text: Translation.tr("Cycles before a long break")
                from: 1
                to: 12
                stepSize: 1
            }
        }
    }

    SettingsSection {
        icon: "nightlight"
        title: Translation.tr("Night light")
        OptSwitch {
            key: "light.night.automatic"
            text: Translation.tr("Turn on automatically on schedule")
        }
        ConfigRow {
            uniform: true
            OptText {
                key: "light.night.from"
                placeholderText: Translation.tr("From (HH:mm)")
                wide: true
            }
            OptText {
                key: "light.night.to"
                placeholderText: Translation.tr("To (HH:mm)")
                wide: true
            }
        }
        OptSpin {
            key: "light.night.colorTemperature"
            text: Translation.tr("Color temperature")
            suffix: "K"
            from: 1000
            to: 10000
            stepSize: 100
        }
        OptSwitch {
            key: "light.antiFlashbang.enable"
            text: Translation.tr("Anti-flashbang (dim bright content)")
        }
    }

    SettingsSection {
        icon: "volume_up"
        title: Translation.tr("Audio")

        ConfigSwitch {
            text: Translation.tr("Earbang protection")
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                Config.options.audio.protection.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Prevents abrupt increments and restricts volume limit")
            }
        }
        ConfigRow {
            enabled: Config.options.audio.protection.enable
            OptSpin {
                key: "audio.protection.maxAllowedIncrease"
                text: Translation.tr("Max allowed increase")
                from: 0
                to: 100
                stepSize: 2
            }
            OptSpin {
                key: "audio.protection.maxAllowed"
                text: Translation.tr("Volume limit")
                from: 0
                to: 154 // pavucontrol allows up to 153%
                stepSize: 2
            }
        }
    }

    SettingsSection {
        icon: "notification_sound"
        title: Translation.tr("Sounds")
        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: Translation.tr("Battery")
                checked: Config.options.sounds.battery
                onCheckedChanged: {
                    Config.options.sounds.battery = checked;
                }
            }
            ConfigSwitch {
                text: Translation.tr("Pomodoro")
                checked: Config.options.sounds.pomodoro
                onCheckedChanged: {
                    Config.options.sounds.pomodoro = checked;
                }
            }
        }

        OptText {
            key: "sounds.theme"
            placeholderText: Translation.tr("Sound theme (folder in /usr/share/sounds)")
        }
    }

    SettingsSection {
        icon: "language"
        title: Translation.tr("Language")

        ContentSubsection {
            title: Translation.tr("Interface Language")
            tooltip: Translation.tr("Select the language for the user interface.\n\"Auto\" will use your system's locale.")

            StyledComboBox {
                id: languageSelector
                textRole: "displayName"

                model: [
                    {
                        displayName: Translation.tr("Auto (System)"),
                        value: "auto"
                    },
                    ...Translation.allAvailableLanguages.map(lang => {
                        return {
                            displayName: lang,
                            value: lang
                        };
                    })]

                currentIndex: {
                    const index = model.findIndex(item => item.value === Config.options.language.ui);
                    return index !== -1 ? index : 0;
                }

                onActivated: index => {
                    Config.options.language.ui = model[index].value;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Generate translation with Gemini")
            tooltip: Translation.tr("You'll need to enter your Gemini API key first.\nType /key on the sidebar for instructions.")

            ConfigRow {
                MaterialTextArea {
                    id: localeInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Locale code, e.g. fr_FR, de_DE, zh_CN...")
                    text: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                }
                RippleButtonWithIcon {
                    id: generateTranslationBtn
                    Layout.fillHeight: true
                    nerdIcon: ""
                    enabled: !translationProc.running || (translationProc.locale !== localeInput.text.trim())
                    mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
                    onClicked: {
                        translationProc.locale = localeInput.text.trim();
                        translationProc.running = false;
                        translationProc.running = true;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Translator")
            tooltip: Translation.tr("Language codes from 'trans -list-all'. \"auto\" detects / uses the system language")
            ConfigRow {
                uniform: true
                OptText {
                    key: "language.translator.sourceLanguage"
                    placeholderText: Translation.tr("Source language")
                    wide: true
                }
                OptText {
                    key: "language.translator.targetLanguage"
                    placeholderText: Translation.tr("Target language")
                    wide: true
                }
            }
        }
    }

    SettingsSection {
        icon: "apps"
        title: Translation.tr("Default apps")
        OptText {
            key: "apps.terminal"
            placeholderText: Translation.tr("Terminal (only for shell actions)")
        }
        OptText {
            key: "apps.taskManager"
            placeholderText: Translation.tr("Task manager")
        }
        OptText {
            key: "apps.volumeMixer"
            placeholderText: Translation.tr("Volume mixer")
        }
        OptText {
            key: "apps.network"
            placeholderText: Translation.tr("Network settings")
        }
        OptText {
            key: "apps.networkEthernet"
            placeholderText: Translation.tr("Ethernet settings")
        }
        OptText {
            key: "apps.bluetooth"
            placeholderText: Translation.tr("Bluetooth settings")
        }
        OptText {
            key: "apps.manageUser"
            placeholderText: Translation.tr("User management")
        }
        OptText {
            key: "apps.changePassword"
            placeholderText: Translation.tr("Change password")
        }
        OptText {
            key: "apps.update"
            placeholderText: Translation.tr("System update")
        }
    }

    SettingsSection {
        icon: "battery_android_full"
        title: Translation.tr("Battery")

        ConfigRow {
            uniform: true
            OptSpin {
                key: "battery.low"
                text: Translation.tr("Low warning")
                from: 0
                to: 100
                stepSize: 5
            }
            OptSpin {
                key: "battery.critical"
                text: Translation.tr("Critical warning")
                from: 0
                to: 100
                stepSize: 5
            }
        }
        ConfigRow {
            uniform: false
            Layout.fillWidth: false
            ConfigSwitch {
                text: Translation.tr("Automatic suspend")
                checked: Config.options.battery.automaticSuspend
                onCheckedChanged: {
                    Config.options.battery.automaticSuspend = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Automatically suspends the system when battery is low")
                }
            }
            ConfigSpinBox {
                enabled: Config.options.battery.automaticSuspend
                text: Translation.tr("at")
                value: Config.options.battery.suspend
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.suspend = value;
                }
            }
        }
        ConfigRow {
            uniform: true
            OptSpin {
                key: "battery.full"
                text: Translation.tr("Full warning")
                from: 0
                to: 101
                stepSize: 5
            }
        }
    }

    SettingsSection {
        icon: "rule"
        title: Translation.tr("Policies")

        ConfigRow {

            // AI policy
            ColumnLayout {
                ContentSubsectionLabel {
                    text: Translation.tr("AI")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.ai
                    onSelected: newValue => {
                        Config.options.policies.ai = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Local only"),
                            icon: "sync_saved_locally",
                            value: 2
                        }
                    ]
                }
            }

            // Weeb policy
            ColumnLayout {

                ContentSubsectionLabel {
                    text: Translation.tr("Weeb")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.weeb
                    onSelected: newValue => {
                        Config.options.policies.weeb = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Closet"),
                            icon: "ev_shadow",
                            value: 2
                        }
                    ]
                }
            }
        }
    }

    SettingsSection {
        icon: "work_alert"
        title: Translation.tr("Work safety")

        ConfigSwitch {
            text: Translation.tr("Hide clipboard images copied from sussy sources")
            checked: Config.options.workSafety.enable.clipboard
            onCheckedChanged: {
                Config.options.workSafety.enable.clipboard = checked;
            }
        }
        ConfigSwitch {
            text: Translation.tr("Hide sussy/anime wallpapers")
            checked: Config.options.workSafety.enable.wallpaper
            onCheckedChanged: {
                Config.options.workSafety.enable.wallpaper = checked;
            }
        }

        ContentSubsection {
            title: Translation.tr("Trigger keywords")
            tooltip: Translation.tr("Content is treated as unsafe on a network whose name contains one of the first list,\nwhen a file name or link contains one of the others")
            OptList {
                key: "workSafety.triggerCondition.networkNameKeywords"
                placeholderText: Translation.tr("Network names (comma-separated)")
            }
            OptList {
                key: "workSafety.triggerCondition.fileKeywords"
                placeholderText: Translation.tr("File names (comma-separated)")
            }
            OptList {
                key: "workSafety.triggerCondition.linkKeywords"
                placeholderText: Translation.tr("Links (comma-separated)")
            }
        }
    }
}
