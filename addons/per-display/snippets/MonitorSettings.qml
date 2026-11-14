ContentSection {
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
