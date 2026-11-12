import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings

ContentPage {
    forceWidth: true

    SettingsSection {
        icon: "search"
        title: Translation.tr("Search")

        ConfigSwitch {
            text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
            checked: Config.options.search.sloppy
            onCheckedChanged: {
                Config.options.search.sloppy = checked;
            }
            StyledToolTip {
                text: Translation.tr("Could be better if you make a ton of typos,\nbut results can be weird and might not work with acronyms\n(e.g. \"GIMP\" might not give you the paint program)")
            }
        }

        ContentSubsection {
            title: Translation.tr("Prefixes")
            ConfigRow {
                uniform: true
                OptText {
                    key: "search.prefix.action"
                    placeholderText: Translation.tr("Action")
                    wide: true
                }
                OptText {
                    key: "search.prefix.clipboard"
                    placeholderText: Translation.tr("Clipboard")
                    wide: true
                }
                OptText {
                    key: "search.prefix.emojis"
                    placeholderText: Translation.tr("Emojis")
                    wide: true
                }
            }

            ConfigRow {
                uniform: true
                OptText {
                    key: "search.prefix.math"
                    placeholderText: Translation.tr("Math")
                    wide: true
                }
                OptText {
                    key: "search.prefix.shellCommand"
                    placeholderText: Translation.tr("Shell command")
                    wide: true
                }
                OptText {
                    key: "search.prefix.webSearch"
                    placeholderText: Translation.tr("Web search")
                    wide: true
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Web search")
            OptText {
                key: "search.engineBaseUrl"
                placeholderText: Translation.tr("Base URL")
                wide: true
            }
        }

        ContentSubsection {
            title: Translation.tr("More")
            OptSwitch {
                key: "search.prefix.showDefaultActionsWithoutPrefix"
                text: Translation.tr("Show default actions without a prefix")
            }
            OptText {
                key: "search.prefix.app"
                placeholderText: Translation.tr("App prefix")
            }
            OptSpin {
                key: "search.nonAppResultDelay"
                text: Translation.tr("Delay before non-app results")
                suffix: "ms"
                from: 0
                to: 1000
                stepSize: 10
            }
            OptList {
                key: "search.excludedSites"
                placeholderText: Translation.tr("Sites excluded from web search (comma-separated)")
            }
            OptText {
                key: "search.imageSearch.imageSearchEngineBaseUrl"
                placeholderText: Translation.tr("Image search base URL")
                wide: true
            }
        }
    }

    SettingsSection {
        icon: "neurology"
        title: Translation.tr("AI")

        OptText {
            key: "ai.systemPrompt"
            placeholderText: Translation.tr("System prompt")
            wide: true
        }

        ContentSubsection {
            title: Translation.tr("Tool")
            ConfigSelectionArray {
                currentValue: Config.options.ai.tool
                onSelected: newValue => {
                    Config.options.ai.tool = newValue;
                }
                options: [
                    { displayName: Translation.tr("Functions"), icon: "function", value: "functions" },
                    { displayName: Translation.tr("Search"), icon: "search", value: "search" },
                    { displayName: Translation.tr("None"), icon: "close", value: "none" },
                ]
            }
        }
        ContentSubsection {
            title: Translation.tr("Extra models")
            tooltip: Translation.tr("Each entry needs: name, model, endpoint, api_format (\"openai\" or \"gemini\"), requires_key, key_id.\nOptional: description, icon, homepage, key_get_link")
            OptJson {
                key: "ai.extraModels"
                label: Translation.tr("Extra models (JSON list)")
            }
        }
    }

    SettingsSection {
        icon: "weather_mix"
        title: Translation.tr("Weather")
        ConfigRow {
            ConfigSwitch {
                text: Translation.tr("Enable GPS based location")
                checked: Config.options.bar.weather.enableGPS
                onCheckedChanged: {
                    Config.options.bar.weather.enableGPS = checked;
                }
            }
            ConfigSwitch {
                text: Translation.tr("Fahrenheit unit")
                checked: Config.options.bar.weather.useUSCS
                onCheckedChanged: {
                    Config.options.bar.weather.useUSCS = checked;
                }
                StyledToolTip {
                    text: Translation.tr("It may take a few seconds to update")
                }
            }
        }
        
        OptText {
            key: "bar.weather.city"
            placeholderText: Translation.tr("City name")
            wide: true
        }
        OptSpin {
            key: "bar.weather.fetchInterval"
            text: Translation.tr("Polling interval")
            suffix: "min"
            from: 5
            to: 50
            stepSize: 5
        }
    }

    SettingsSection {
        icon: "file_open"
        title: Translation.tr("Save paths")

        OptText {
            key: "screenRecord.savePath"
            placeholderText: Translation.tr("Video Recording Path")
            wide: true
        }
        
        OptText {
            key: "screenSnip.savePath"
            placeholderText: Translation.tr("Screenshot Path (leave empty to just copy)")
            wide: true
        }
    }

    SettingsSection {
        icon: "memory"
        title: Translation.tr("Resources")

        OptSpin {
            key: "resources.updateInterval"
            text: Translation.tr("Polling interval")
            suffix: "ms"
            from: 100
            to: 10000
            stepSize: 100
        }
        

        OptSpin {
            key: "resources.historyLength"
            text: Translation.tr("Graph history length (samples)")
            from: 10
            to: 600
            stepSize: 10
        }
    }

    SettingsSection {
        icon: "music_note"
        title: Translation.tr("Media")
        OptSwitch {
            key: "media.filterDuplicatePlayers"
            text: Translation.tr("Filter duplicate players")
            tooltip: Translation.tr("Hides the duplicate entries created by playerctl and browser integration")
        }
    }

    SettingsSection {
        icon: "music_cast"
        title: Translation.tr("Music Recognition")

        OptSpin {
            key: "musicRecognition.timeout"
            text: Translation.tr("Total duration timeout")
            suffix: "s"
            from: 10
            to: 100
            stepSize: 2
        }
        OptSpin {
            key: "musicRecognition.interval"
            text: Translation.tr("Polling interval")
            suffix: "s"
            from: 2
            to: 10
            stepSize: 1
        }
    }

    SettingsSection {
        icon: "image"
        title: Translation.tr("Anime boards")
        OptSpin {
            key: "sidebar.booru.limit"
            text: Translation.tr("Results per page")
            from: 1
            to: 100
            stepSize: 5
        }
        OptText {
            key: "sidebar.booru.zerochan.username"
            placeholderText: Translation.tr("Zerochan username")
        }
    }

    SettingsSection {
        icon: "cell_tower"
        title: Translation.tr("Networking")

        OptText {
            key: "networking.userAgent"
            placeholderText: Translation.tr("User agent (for services that require it)")
            wide: true
        }
    }
}
