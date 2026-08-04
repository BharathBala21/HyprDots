import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Controls.Basic
import IslandBackend

FloatingWindow {
    id: root

    title: "Tide-Island Settings"
    implicitWidth: 480
    implicitHeight: 560
    color: colorBackground

    signal settingsClosed()

    onVisibleChanged: {
        if (!visible) {
            settingsClosed();
        }
    }

    Component.onDestruction: {
        settingsClosed();
    }

    function getHomePath() {
        return Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user");
    }

    FileView {
        id: settingsCfgWatcher
        path: getHomePath() + "/.config/tide-island/userconfig.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: settingsCfgWatcher.reload()
    }

    readonly property var cfgData: {
        try {
            return settingsCfgWatcher.text() ? JSON.parse(settingsCfgWatcher.text()) : {};
        } catch (e) {
            return {};
        }
    }

    property string clockFormat: cfgData.clockFormat !== undefined ? String(cfgData.clockFormat) : (UserConfig.clockFormat || "24")
    property bool autoExpandOnTrackChange: cfgData.disableAutoExpandOnTrackChange !== undefined ? !cfgData.disableAutoExpandOnTrackChange : !UserConfig.disableAutoExpandOnTrackChange
    property bool showBatteryPercentage: cfgData.showBatteryPercentage !== undefined ? cfgData.showBatteryPercentage : true
    property string primaryAction: cfgData.dynamicIslandPrimaryAction || UserConfig.dynamicIslandPrimaryAction || "toggleExpandedPlayer"
    property string secondaryAction: cfgData.dynamicIslandSecondaryAction || UserConfig.dynamicIslandSecondaryAction || "toggleControlCenter"

    // Matugen dynamic theme colors
    readonly property var themeColors: shellRoot.matugenThemeColors

    readonly property color colorBackground: themeColors ? themeColors.background : "#121316"
    readonly property color colorPrimary: themeColors ? themeColors.primary : "#0a84ff"
    readonly property color colorOnSurface: themeColors ? themeColors.on_surface : "#ffffff"
    readonly property color colorOnSurfaceVariant: themeColors ? themeColors.on_surface_variant : "#8e8e93"
    readonly property color colorOutline: themeColors ? themeColors.outline_variant : "#3a3a3c"
    readonly property color colorSecondaryContainer: themeColors ? themeColors.secondary_container : "#2c2c2e"
    readonly property color colorOnSecondaryContainer: themeColors ? themeColors.on_secondary_container : "#ffffff"
    readonly property color colorCardBg: themeColors ? (themeColors.surface_container_low || themeColors.surface) : "#1c1d21"

    readonly property color colorSwitchBgActive: colorPrimary
    readonly property color colorSwitchBgInactive: themeColors ? themeColors.secondary_container : "#2c2c2e"
    readonly property color colorSwitchKnob: "#ffffff"

    function saveSettings() {
        Quickshell.execDetached([
            "python3",
            Quickshell.shellDir + "/bin/update_tide_config.py",
            "--clock-format", clockFormat,
            "--disable-auto-expand", autoExpandOnTrackChange ? "false" : "true",
            "--show-battery-percentage", showBatteryPercentage ? "true" : "false",
            "--primary-action", primaryAction,
            "--secondary-action", secondaryAction
        ]);
    }

    // Escape key press to close
    Timer {
        id: focusTimer
        interval: 10
        running: true
        repeat: false
        onTriggered: root.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.close();
            event.accepted = true;
        }
    }

    // Component: Switch
    component SettingsSwitch: Rectangle {
        id: swRoot
        property bool checked: false
        signal toggled(bool newValue)

        width: 44
        height: 24
        radius: 12
        color: checked ? colorSwitchBgActive : colorSwitchBgInactive

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            color: colorSwitchKnob
            anchors.verticalCenter: parent.verticalCenter
            x: swRoot.checked ? swRoot.width - width - 3 : 3

            Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                swRoot.checked = !swRoot.checked;
                swRoot.toggled(swRoot.checked);
            }
        }
    }

    // Component: Card layout container
    component SettingsCard: Rectangle {
        default property alias content: cardContent.data
        property string title: ""
        property string subtitle: ""

        width: parent ? parent.width : 440
        implicitHeight: cardCol.height + 24
        radius: 14
        color: colorCardBg
        border.color: Qt.rgba(colorOutline.r, colorOutline.g, colorOutline.b, 0.25)
        border.width: 1

        Column {
            id: cardCol
            width: parent.width - 24
            anchors.centerIn: parent
            spacing: 10

            Row {
                width: parent.width
                visible: title !== ""

                Column {
                    width: parent.width - 100
                    spacing: 2

                    Text {
                        text: title
                        color: colorOnSurface
                        font.pixelSize: 14
                        font.family: "Inter Display"
                        font.weight: Font.Medium
                    }

                    Text {
                        text: subtitle
                        color: colorOnSurfaceVariant
                        font.pixelSize: 11
                        font.family: "Inter Display"
                        visible: subtitle !== ""
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }

            Item {
                id: cardContent
                width: parent.width
                implicitHeight: childrenRect.height
            }
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.margins: 16
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            id: mainColumn
            width: scrollView.width - 12
            spacing: 16

            // Header Title
            Row {
                width: parent.width
                spacing: 10

                Text {
                    text: "🏝️"
                    font.pixelSize: 22
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Tide-Island Settings"
                    color: colorOnSurface
                    font.pixelSize: 20
                    font.family: "Inter Display"
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // --- SECTION 1: Dynamic Island Behavior ---
            Text {
                text: "Island Behavior"
                color: colorPrimary
                font.pixelSize: 12
                font.family: "Inter Display"
                font.weight: Font.Bold
            }

            SettingsCard {
                title: "Clock Format"
                subtitle: "Choose between 12-hour (AM/PM) and 24-hour time format"

                Row {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: -28
                    spacing: 6

                    Rectangle {
                        width: 70
                        height: 28
                        radius: 8
                        color: clockFormat === "12" ? colorPrimary : colorSecondaryContainer
                        Text {
                            anchors.centerIn: parent
                            text: "12-Hour"
                            color: clockFormat === "12" ? "#ffffff" : colorOnSurfaceVariant
                            font.pixelSize: 11
                            font.family: "Inter Display"
                            font.weight: Font.Medium
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                clockFormat = "12";
                                saveSettings();
                            }
                        }
                    }

                    Rectangle {
                        width: 70
                        height: 28
                        radius: 8
                        color: clockFormat === "24" ? colorPrimary : colorSecondaryContainer
                        Text {
                            anchors.centerIn: parent
                            text: "24-Hour"
                            color: clockFormat === "24" ? "#ffffff" : colorOnSurfaceVariant
                            font.pixelSize: 11
                            font.family: "Inter Display"
                            font.weight: Font.Medium
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                clockFormat = "24";
                                saveSettings();
                            }
                        }
                    }
                }
            }

            SettingsCard {
                title: "Auto-Expand on Music Change"
                subtitle: "Automatically expand island briefly when a new song starts playing"

                SettingsSwitch {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: -24
                    checked: autoExpandOnTrackChange
                    onToggled: (newValue) => {
                        autoExpandOnTrackChange = newValue;
                        saveSettings();
                    }
                }
            }

            SettingsCard {
                title: "Show Battery Percentage"
                subtitle: "Display numerical percentage next to the battery icon"

                SettingsSwitch {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: -24
                    checked: showBatteryPercentage
                    onToggled: (newValue) => {
                        showBatteryPercentage = newValue;
                        saveSettings();
                    }
                }
            }

            // --- SECTION 2: Click Actions ---
            Text {
                text: "Island Click Actions"
                color: colorPrimary
                font.pixelSize: 12
                font.family: "Inter Display"
                font.weight: Font.Bold
                topPadding: 6
            }

            SettingsCard {
                title: "Left-Click Action"
                subtitle: "Action triggered when clicking the Dynamic Island"

                Grid {
                    columns: 2
                    spacing: 8
                    width: parent.width
                    topPadding: 6

                    readonly property var options: [
                        { label: "Expanded Player", value: "toggleExpandedPlayer" },
                        { label: "Control Center", value: "toggleControlCenter" },
                        { label: "App Launcher", value: "toggleLauncher" },
                        { label: "Overview", value: "toggleOverview" }
                    ]

                    Repeater {
                        model: parent.options
                        Rectangle {
                            width: (mainColumn.width - 32) / 2
                            height: 32
                            radius: 8
                            color: primaryAction === modelData.value ? colorPrimary : colorSecondaryContainer

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: primaryAction === modelData.value ? "#ffffff" : colorOnSurfaceVariant
                                font.pixelSize: 12
                                font.family: "Inter Display"
                                font.weight: primaryAction === modelData.value ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    primaryAction = modelData.value;
                                    saveSettings();
                                }
                            }
                        }
                    }
                }
            }

            SettingsCard {
                title: "Right-Click Action"
                subtitle: "Secondary action triggered when right-clicking the Dynamic Island"

                Grid {
                    columns: 2
                    spacing: 8
                    width: parent.width
                    topPadding: 6

                    readonly property var options: [
                        { label: "Control Center", value: "toggleControlCenter" },
                        { label: "Workspace Overview", value: "toggleOverview" },
                        { label: "Clipboard Manager", value: "toggleClipboard" },
                        { label: "Emoji Picker", value: "toggleEmojis" }
                    ]

                    Repeater {
                        model: parent.options
                        Rectangle {
                            width: (mainColumn.width - 32) / 2
                            height: 32
                            radius: 8
                            color: secondaryAction === modelData.value ? colorPrimary : colorSecondaryContainer

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: secondaryAction === modelData.value ? "#ffffff" : colorOnSurfaceVariant
                                font.pixelSize: 12
                                font.family: "Inter Display"
                                font.weight: secondaryAction === modelData.value ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    secondaryAction = modelData.value;
                                    saveSettings();
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 10
            }
        }
    }
}
