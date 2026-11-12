import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings

ContentPage {
    forceWidth: true

    SettingsSection {
        icon: "toolbar"
        title: Translation.tr("Taskbar")
        OptSwitch {
            key: "waffles.bar.bottom"
            text: Translation.tr("Taskbar at the bottom")
        }
        OptSwitch {
            key: "waffles.bar.leftAlignApps"
            text: Translation.tr("Left-align apps")
        }
    }

    SettingsSection {
        icon: "toggle_on"
        title: Translation.tr("Action center")
        OptList {
            key: "waffles.actionCenter.toggles"
            placeholderText: Translation.tr("Toggles, in order (comma-separated)")
        }
    }

    SettingsSection {
        icon: "calendar_month"
        title: Translation.tr("Calendar")
        OptSwitch {
            key: "waffles.calendar.force2CharDayOfWeek"
            text: Translation.tr("Two-letter day names")
        }
        OptText {
            key: "calendar.locale"
            placeholderText: Translation.tr("Calendar locale (e.g. en-GB)")
        }
    }

    SettingsSection {
        icon: "deployed_code_update"
        title: Translation.tr("System updates")
        OptSwitch {
            key: "updates.enableCheck"
            text: Translation.tr("Enable update checks")
        }
        OptSpin {
            key: "updates.checkInterval"
            text: Translation.tr("Check interval")
            suffix: "min"
            from: 10
            to: 1440
            stepSize: 10
        }
        OptSpin {
            key: "updates.adviseUpdateThreshold"
            text: Translation.tr("Advise updating above (packages)")
            from: 1
            to: 2000
            stepSize: 5
        }
        OptSpin {
            key: "updates.stronglyAdviseUpdateThreshold"
            text: Translation.tr("Strongly advise updating above (packages)")
            from: 1
            to: 5000
            stepSize: 10
        }
    }

    SettingsSection {
        icon: "tune"
        title: Translation.tr("Tweaks")
        OptSwitch {
            key: "waffles.tweaks.switchHandlePositionFix"
            text: Translation.tr("Fix switch handle position")
        }
        OptSwitch {
            key: "waffles.tweaks.smootherMenuAnimations"
            text: Translation.tr("Smoother menu animations")
        }
        OptSwitch {
            key: "waffles.tweaks.smootherSearchBar"
            text: Translation.tr("Smoother search bar")
        }
    }
}
