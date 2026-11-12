import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings

ContentPage {
    forceWidth: true

    NoticeBox {
        Layout.fillWidth: true
        text: Translation.tr("Nothing in the shell reads these options, so changing them has no effect. They are only here so that every entry of the config file has a control.")
    }

    SettingsSection {
        icon: "block"
        title: Translation.tr("Unused options")
        OptSpin {
            key: "bar.workspaces.showNumberDelay"
            text: Translation.tr("Bar: workspace number delay, superseded by Super hold delay")
            suffix: "ms"
            from: 0
            to: 1000
            stepSize: 50
        }
        OptSwitch {
            key: "background.widgets.clock.cookie.dateInClock"
            text: Translation.tr("Cookie clock: date inside the clock")
        }
        OptText {
            key: "language.translator.engine"
            placeholderText: Translation.tr("Translator engine")
        }
        OptSwitch {
            key: "sidebar.booru.allowNsfw"
            text: Translation.tr("Anime boards: allow NSFW")
            tooltip: Translation.tr("The sidebar keeps its own NSFW toggle and ignores this one")
        }
        OptText {
            key: "sidebar.booru.defaultProvider"
            placeholderText: Translation.tr("Anime boards: default provider")
        }
    }
}
