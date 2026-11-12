ContentSection {
    id: updatesSection
    icon: "update"
    title: Translation.tr("Updates")

    property string dotsStatus: Translation.tr("Not checked yet")
    property string systemStatus: Translation.tr("Not checked yet")
    property int dotsBehind: 0
    readonly property bool checking: dotsCheckProc.running || systemCheckProc.running

    function check() {
        dotsStatus = Translation.tr("Checking...");
        systemStatus = Translation.tr("Checking...");
        dotsBehind = 0;
        dotsCheckProc.running = true;
        systemCheckProc.running = true;
    }

    Process { // Compares the local copy of the dotfiles repo with GitHub
        id: dotsCheckProc
        command: ["bash", "-c", 'repo="$HOME/.cache/dots-hyprland"; [ -d "$repo/.git" ] || { echo missing; exit 0; }; git -C "$repo" fetch --quiet origin 2>/dev/null || { echo offline; exit 0; }; git -C "$repo" rev-list --count HEAD..@{u}']
        stdout: StdioCollector {
            onStreamFinished: {
                const result = text.trim();
                if (result === "missing") updatesSection.dotsStatus = Translation.tr("No dotfiles repository found in ~/.cache/dots-hyprland");
                else if (result === "offline") updatesSection.dotsStatus = Translation.tr("Could not reach GitHub");
                else if (isNaN(parseInt(result))) updatesSection.dotsStatus = Translation.tr("Check failed");
                else {
                    updatesSection.dotsBehind = parseInt(result);
                    updatesSection.dotsStatus = updatesSection.dotsBehind === 0 ? Translation.tr("Up to date")
                        : Translation.tr("%1 new commits available").arg(updatesSection.dotsBehind);
                }
            }
        }
    }

    Process { // Pending system packages (Arch only)
        id: systemCheckProc
        command: ["bash", "-c", 'command -v checkupdates >/dev/null || { echo missing; exit 0; }; out=$(checkupdates 2>/dev/null); [ $? -eq 1 ] && { echo failed; exit 0; }; printf "%s" "$out" | grep -c .; true']
        stdout: StdioCollector {
            onStreamFinished: {
                const result = text.trim();
                if (result === "missing") updatesSection.systemStatus = Translation.tr("checkupdates is not installed (pacman-contrib)");
                else if (result === "failed" || isNaN(parseInt(result))) updatesSection.systemStatus = Translation.tr("Check failed");
                else updatesSection.systemStatus = parseInt(result) === 0 ? Translation.tr("Up to date")
                    : Translation.tr("%1 packages can be updated").arg(parseInt(result));
            }
        }
    }

    component StatusRow: RowLayout {
        property string label
        property string status
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 10
        StyledText {
            text: parent.label
            color: Appearance.colors.colOnSecondaryContainer
        }
        Item {
            Layout.fillWidth: true
        }
        StyledText {
            text: parent.status
            color: Appearance.colors.colSubtext
        }
    }

    StatusRow {
        label: Translation.tr("Dotfiles (illogical-impulse)")
        status: updatesSection.dotsStatus
    }
    StatusRow {
        label: Translation.tr("System packages")
        status: updatesSection.systemStatus
    }

    Flow {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 5

        RippleButtonWithIcon {
            enabled: !updatesSection.checking
            materialIcon: "refresh"
            mainText: updatesSection.checking ? Translation.tr("Checking...") : Translation.tr("Check for updates")
            onClicked: updatesSection.check()
        }
        RippleButtonWithIcon {
            visible: updatesSection.dotsBehind > 0
            materialIcon: "open_in_new"
            mainText: Translation.tr("View dotfiles changes")
            onClicked: {
                Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/commits/main")
            }
        }
        RippleButtonWithIcon { // Opens a terminal running end-4's updater, then re-applies this mod
            visible: updatesSection.dotsBehind > 0
            materialIcon: "system_update_alt"
            mainText: Translation.tr("Update dotfiles")
            onClicked: {
                const script = Quickshell.shellPath("scripts/settings-rework/update-dots.sh");
                Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e bash '${script}'`]);
            }
            StyledToolTip {
                text: Translation.tr("Opens a terminal and runs end-4's updater (./setup exp-update).\nIt asks before changing files you have edited")
            }
        }
        RippleButtonWithIcon {
            visible: !updatesSection.checking && updatesSection.systemStatus.includes("packages can")
            materialIcon: "download"
            mainText: Translation.tr("Update system")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", Config.options.apps.update])
            }
        }
    }
}
