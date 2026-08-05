import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IslandBackend

FloatingWindow {
    id: root

    title: "Tide-Island Settings"
    implicitWidth: 880
    implicitHeight: 620
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

    readonly property string iconFontFamily: UserConfig.iconFontFamily || ""

    // Active Category State ("bar_island", "notepad", "actions", "clock_date")
    property string activeCategory: "bar_island"
    property string searchQuery: ""

    // Settings values loaded from userconfig.json
    property string clockFormat: cfgData.clockFormat !== undefined ? String(cfgData.clockFormat) : (UserConfig.clockFormat || "24")
    property bool autoExpandOnTrackChange: cfgData.disableAutoExpandOnTrackChange !== undefined ? !cfgData.disableAutoExpandOnTrackChange : !UserConfig.disableAutoExpandOnTrackChange
    property bool showBatteryPercentage: cfgData.showBatteryPercentage !== undefined ? cfgData.showBatteryPercentage : true
    property string primaryAction: cfgData.dynamicIslandPrimaryAction || UserConfig.dynamicIslandPrimaryAction || "toggleExpandedPlayer"
    property string secondaryAction: cfgData.dynamicIslandSecondaryAction || UserConfig.dynamicIslandSecondaryAction || "toggleControlCenter"
    property string islandStyle: cfgData.islandStyle !== undefined ? String(cfgData.islandStyle) : "pill"
    property string centerPillStyle: cfgData.centerPillStyle !== undefined ? String(cfgData.centerPillStyle) : (islandStyle === "notch" ? "notch" : "pill")
    property string topLeftPillStyle: cfgData.topLeftPillStyle !== undefined ? String(cfgData.topLeftPillStyle) : (islandStyle === "notch" ? "notch" : "pill")
    property string topRightPillStyle: cfgData.topRightPillStyle !== undefined ? String(cfgData.topRightPillStyle) : (islandStyle === "notch" ? "notch" : "pill")
    property string topRightTrayStyle: cfgData.topRightTrayStyle !== undefined ? String(cfgData.topRightTrayStyle) : (islandStyle === "notch" ? "notch" : "pill")
    property int islandCompactWidth: cfgData.islandCompactWidth !== undefined ? Number(cfgData.islandCompactWidth) : 140
    property int islandCompactHeight: cfgData.islandCompactHeight !== undefined ? Number(cfgData.islandCompactHeight) : 35
    property int islandCornerRadius: cfgData.islandCornerRadius !== undefined ? Number(cfgData.islandCornerRadius) : 19
    property int islandTopOffset: cfgData.islandTopOffset !== undefined ? Number(cfgData.islandTopOffset) : 4
    property int islandInnerPadding: cfgData.islandInnerPadding !== undefined ? Number(cfgData.islandInnerPadding) : 8
    property int reservedTopSpace: cfgData.reservedTopSpace !== undefined ? Number(cfgData.reservedTopSpace) : 38
    property bool showTopLeftPill: cfgData.showTopLeftPill !== undefined ? cfgData.showTopLeftPill : true
    property bool showTopRightCava: cfgData.showTopRightCava !== undefined ? cfgData.showTopRightCava : true
    property bool showTopRightBattery: cfgData.showTopRightBattery !== undefined ? cfgData.showTopRightBattery : (cfgData.showTopRightPill !== undefined ? cfgData.showTopRightPill : true)
    property bool showTopRightPill: cfgData.showTopRightPill !== undefined ? cfgData.showTopRightPill : true
    property bool showTopRightTray: cfgData.showTopRightTray !== undefined ? cfgData.showTopRightTray : true
    property bool islandAutoHideEnabled: cfgData.islandAutoHideEnabled !== undefined ? cfgData.islandAutoHideEnabled : false
    property string notepadDefaultMode: cfgData.notepadDefaultMode !== undefined ? String(cfgData.notepadDefaultMode) : "edit"
    property bool notepadAutoSave: cfgData.notepadAutoSave !== undefined ? cfgData.notepadAutoSave : true
    property string tlpPermissionMode: cfgData.tlpPermissionMode !== undefined ? String(cfgData.tlpPermissionMode) : "password"

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
            "--secondary-action", secondaryAction,
            "--island-style", islandStyle,
            "--center-pill-style", centerPillStyle,
            "--top-left-pill-style", topLeftPillStyle,
            "--top-right-pill-style", topRightPillStyle,
            "--top-right-tray-style", topRightTrayStyle,
            "--island-compact-width", String(islandCompactWidth),
            "--island-compact-height", String(islandCompactHeight),
            "--island-corner-radius", String(islandCornerRadius),
            "--island-top-offset", String(islandTopOffset),
            "--island-inner-padding", String(islandInnerPadding),
            "--reserved-top-space", String(reservedTopSpace),
            "--show-top-left-pill", showTopLeftPill ? "true" : "false",
            "--show-top-right-cava", showTopRightCava ? "true" : "false",
            "--show-top-right-battery", showTopRightBattery ? "true" : "false",
            "--show-top-right-tray", showTopRightTray ? "true" : "false",
            "--island-auto-hide", islandAutoHideEnabled ? "true" : "false",
            "--notepad-default-mode", notepadDefaultMode,
            "--notepad-auto-save", notepadAutoSave ? "true" : "false",
            "--tlp-permission-mode", tlpPermissionMode
        ]);
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
        id: cardRoot
        property string title: ""
        property string subtitle: ""
        property alias control: cardControlSlot.data
        default property alias extraContent: extraSlot.data

        Layout.fillWidth: true
        implicitHeight: cardLayout.implicitHeight + 28
        radius: 14
        color: colorCardBg
        border.color: Qt.rgba(colorOutline.r, colorOutline.g, colorOutline.b, 0.25)
        border.width: 1

        ColumnLayout {
            id: cardLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: cardRoot.title
                        color: colorOnSurface
                        font.pixelSize: 13
                        font.family: "Inter Display"
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }

                    Text {
                        text: cardRoot.subtitle
                        color: colorOnSurfaceVariant
                        font.pixelSize: 11
                        font.family: "Inter Display"
                        visible: cardRoot.subtitle !== ""
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                Item {
                    id: cardControlSlot
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    implicitWidth: childrenRect.width
                    implicitHeight: childrenRect.height
                }
            }

            Item {
                id: extraSlot
                Layout.fillWidth: true
                implicitHeight: childrenRect.height
                visible: children.length > 0
            }
        }
    }

    // Component: Interactive Slider Card
    component GeometrySliderCard: Rectangle {
        id: gCard
        property string title: ""
        property string subtitle: ""
        property real value: 0
        property real from: 0
        property real to: 100
        property string unit: "px"
        signal valueMoved(real newValue)

        Layout.fillWidth: true
        implicitHeight: gLayout.implicitHeight + 28
        radius: 14
        color: colorCardBg
        border.color: Qt.rgba(colorOutline.r, colorOutline.g, colorOutline.b, 0.25)
        border.width: 1

        ColumnLayout {
            id: gLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: gCard.title
                        font.pixelSize: 13
                        font.family: "Inter Display"
                        font.weight: Font.DemiBold
                        color: colorOnSurface
                    }
                    Text {
                        text: gCard.subtitle
                        font.pixelSize: 11
                        font.family: "Inter Display"
                        color: colorOnSurfaceVariant
                        visible: gCard.subtitle !== ""
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: Math.round(gCard.value) + " " + gCard.unit
                    font.pixelSize: 13
                    font.bold: true
                    color: colorPrimary
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }
            }

            Slider {
                Layout.fillWidth: true
                from: gCard.from
                to: gCard.to
                value: gCard.value
                onMoved: {
                    gCard.valueMoved(value);
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // --- LEFT SIDEBAR NAVIGATION (Width: 230) ---
        Rectangle {
            Layout.preferredWidth: 230
            Layout.minimumWidth: 220
            Layout.fillHeight: true
            color: "#0a0b0e"
            border.color: "#18ffffff"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // Search Input Box
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: "#16ffffff"
                    border.color: "#20ffffff"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Text {
                            text: "🔍"
                            font.pixelSize: 12
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            placeholderText: "Search..."
                            placeholderTextColor: "#606060"
                            font.family: "Inter Display"
                            font.pixelSize: 12
                            color: "#ffffff"
                            background: null
                            onTextChanged: root.searchQuery = text
                        }
                    }
                }

                // Category List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: [
                            { id: "bar_island", icon: "\uf108", label: "Bar & Island", desc: "Shape, size, notch style, and custom geometry." },
                            { id: "notepad", icon: "\uf044", label: "Notepad Notch", desc: "Default view mode, auto-save settings, and markdown." },
                            { id: "actions", icon: "\uf0e7", label: "Island Actions", desc: "Primary left-click and secondary right-click actions." },
                            { id: "clock_date", icon: "\uf017", label: "Clock & Behavior", desc: "Time format, auto-expansion, and battery text." }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 10
                            color: root.activeCategory === modelData.id ? colorPrimary : (navMouse.containsMouse ? "#18ffffff" : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 15
                                    color: root.activeCategory === modelData.id ? "#ffffff" : colorOnSurfaceVariant
                                }

                                Text {
                                    text: modelData.label
                                    font.family: "Inter Display"
                                    font.pixelSize: 13
                                    font.weight: root.activeCategory === modelData.id ? Font.Bold : Font.Medium
                                    color: root.activeCategory === modelData.id ? "#ffffff" : colorOnSurface
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeCategory = modelData.id;
                                    root.searchQuery = "";
                                    searchInput.text = "";
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true } // Spacer
            }
        }

        // --- RIGHT MAIN SETTINGS PANEL ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    root.close();
                    event.accepted = true;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Section Hero Banner Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: 16
                    color: "#16ffffff"
                    border.color: "#20ffffff"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        Rectangle {
                            width: 46
                            height: 46
                            radius: 14
                            color: colorPrimary

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    switch (root.activeCategory) {
                                    case "bar_island": return "\uf108";
                                    case "notepad": return "\uf044";
                                    case "actions": return "\uf0e7";
                                    case "clock_date": return "\uf017";
                                    default: return "\uf108";
                                    }
                                }
                                font.family: root.iconFontFamily
                                font.pixelSize: 20
                                color: "#ffffff"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: {
                                    switch (root.activeCategory) {
                                    case "bar_island": return "Bar & Island";
                                    case "notepad": return "Notepad Notch";
                                    case "actions": return "Island Actions";
                                    case "clock_date": return "Clock & Behavior";
                                    default: return "Tide-Island Settings";
                                    }
                                }
                                font.family: "Inter Display"
                                font.pixelSize: 18
                                font.bold: true
                                color: "#ffffff"
                            }

                            Text {
                                text: {
                                    switch (root.activeCategory) {
                                    case "bar_island": return "Customize island visual style (Pill vs Notch), height, width, radius, and padding.";
                                    case "notepad": return "Configure default view mode (Edit vs Preview) and auto-save behavior for notes.";
                                    case "actions": return "Set primary left-click and secondary right-click actions for the Dynamic Island.";
                                    case "clock_date": return "Adjust 12h/24h time format, battery percentage text, and auto-expand options.";
                                    default: return "System preferences for Tide-Island.";
                                    }
                                }
                                font.family: "Inter Display"
                                font.pixelSize: 11
                                color: "#a0a0a0"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Scrollable Content Area
                ScrollView {
                    id: mainScrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        width: mainScrollView.availableWidth - 12
                        spacing: 14

                        // ==================== CATEGORY 1: BAR & ISLAND ====================
                        ColumnLayout {
                            visible: root.activeCategory === "bar_island" || root.searchQuery !== ""
                            Layout.fillWidth: true
                            spacing: 14

                            SettingsCard {
                                title: "Island Visual Style"
                                subtitle: "Choose preset style (Floating Pill or Top Notch) or Custom per-pill styling"

                                control: Row {
                                    spacing: 6
                                    Rectangle {
                                        width: 85; height: 32; radius: 8
                                        color: islandStyle === "pill" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "Floating Pill"; color: islandStyle === "pill" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                islandStyle = "pill";
                                                centerPillStyle = "pill";
                                                topLeftPillStyle = "pill";
                                                topRightPillStyle = "pill";
                                                topRightTrayStyle = "pill";
                                                saveSettings();
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 85; height: 32; radius: 8
                                        color: islandStyle === "notch" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "Top Notch"; color: islandStyle === "notch" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                islandStyle = "notch";
                                                centerPillStyle = "notch";
                                                topLeftPillStyle = "notch";
                                                topRightPillStyle = "notch";
                                                topRightTrayStyle = "notch";
                                                saveSettings();
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 85; height: 32; radius: 8
                                        color: islandStyle === "custom" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "Custom"; color: islandStyle === "custom" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                islandStyle = "custom";
                                                saveSettings();
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                visible: islandStyle === "custom"
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "Per-Pill Custom Styles"
                                    color: colorPrimary
                                    font.pixelSize: 12
                                    font.family: "Inter Display"
                                    font.weight: Font.Bold
                                    topPadding: 4
                                }

                                SettingsCard {
                                    title: "Center Island Pill"
                                    subtitle: "Style for main center clock/island capsule"

                                    control: Row {
                                        spacing: 6
                                        Rectangle {
                                            width: 75; height: 28; radius: 8
                                            color: centerPillStyle === "pill" ? colorPrimary : colorSecondaryContainer
                                            Text { anchors.centerIn: parent; text: "Pill"; color: centerPillStyle === "pill" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { centerPillStyle = "pill"; saveSettings(); } }
                                        }
                                        Rectangle {
                                            width: 75; height: 28; radius: 8
                                            color: centerPillStyle === "notch" ? colorPrimary : colorSecondaryContainer
                                            Text { anchors.centerIn: parent; text: "Notch"; color: centerPillStyle === "notch" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { centerPillStyle = "notch"; saveSettings(); } }
                                        }
                                    }
                                }

                                SettingsCard {
                                    title: "Left Lyrics / Status Pill"
                                    subtitle: "Style for left lyrics and music status pill"

                                    control: Row {
                                        spacing: 6
                                        Rectangle {
                                            width: 75; height: 28; radius: 8
                                            color: topLeftPillStyle === "pill" ? colorPrimary : colorSecondaryContainer
                                            Text { anchors.centerIn: parent; text: "Pill"; color: topLeftPillStyle === "pill" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { topLeftPillStyle = "pill"; saveSettings(); } }
                                        }
                                        Rectangle {
                                            width: 75; height: 28; radius: 8
                                            color: topLeftPillStyle === "notch" ? colorPrimary : colorSecondaryContainer
                                            Text { anchors.centerIn: parent; text: "Notch"; color: topLeftPillStyle === "notch" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { topLeftPillStyle = "notch"; saveSettings(); } }
                                        }
                                    }
                                }

                                SettingsCard {
                                    title: "Right Status Pill (Battery & Volume)"
                                    subtitle: "Style for right battery and volume status pill"

                                    control: Row {
                                        spacing: 6
                                        Rectangle {
                                            width: 75; height: 28; radius: 8
                                            color: topRightPillStyle === "pill" ? colorPrimary : colorSecondaryContainer
                                            Text { anchors.centerIn: parent; text: "Pill"; color: topRightPillStyle === "pill" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { topRightPillStyle = "pill"; saveSettings(); } }
                                        }
                                        Rectangle {
                                            width: 75; height: 28; radius: 8
                                            color: topRightPillStyle === "notch" ? colorPrimary : colorSecondaryContainer
                                            Text { anchors.centerIn: parent; text: "Notch"; color: topRightPillStyle === "notch" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { topRightPillStyle = "notch"; saveSettings(); } }
                                        }
                                    }
                                }

                                SettingsCard {
                                    title: "Right System Tray Pill"
                                    subtitle: "Style for system tray icons pill"

                                    control: Row {
                                        spacing: 6
                                        Rectangle {
                                            width: 75; height: 28; radius: 8
                                            color: topRightTrayStyle === "pill" ? colorPrimary : colorSecondaryContainer
                                            Text { anchors.centerIn: parent; text: "Pill"; color: topRightTrayStyle === "pill" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { topRightTrayStyle = "pill"; saveSettings(); } }
                                        }
                                        Rectangle {
                                            width: 75; height: 28; radius: 8
                                            color: topRightTrayStyle === "notch" ? colorPrimary : colorSecondaryContainer
                                            Text { anchors.centerIn: parent; text: "Notch"; color: topRightTrayStyle === "notch" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { topRightTrayStyle = "notch"; saveSettings(); } }
                                        }
                                    }
                                }
                            }

                            GeometrySliderCard {
                                title: "Collapsed Width"
                                subtitle: "Idle capsule width in pixels (100px - 260px)"
                                value: islandCompactWidth
                                from: 100; to: 260
                                onValueMoved: (newVal) => { islandCompactWidth = Math.round(newVal); saveSettings(); }
                            }

                            GeometrySliderCard {
                                title: "Collapsed Height"
                                subtitle: "Idle capsule height in pixels (24px - 50px)"
                                value: islandCompactHeight
                                from: 24; to: 50
                                onValueMoved: (newVal) => { islandCompactHeight = Math.round(newVal); saveSettings(); }
                            }

                            GeometrySliderCard {
                                title: "Corner Radius"
                                subtitle: "Curvature radius of pill/notch corners (4px - 30px)"
                                value: islandCornerRadius
                                from: 4; to: 30
                                onValueMoved: (newVal) => { islandCornerRadius = Math.round(newVal); saveSettings(); }
                            }

                            GeometrySliderCard {
                                title: "Top Edge Offset"
                                subtitle: "Vertical gap/offset from top screen edge (0px - 24px)"
                                value: islandTopOffset
                                from: 0; to: 24
                                onValueMoved: (newVal) => { islandTopOffset = Math.round(newVal); saveSettings(); }
                            }

                            GeometrySliderCard {
                                title: "Inner Content Padding"
                                subtitle: "Padding inside collapsed pill for clock/icons (2px - 16px)"
                                value: islandInnerPadding
                                from: 2; to: 16
                                onValueMoved: (newVal) => { islandInnerPadding = Math.round(newVal); saveSettings(); }
                            }

                            GeometrySliderCard {
                                title: "Reserved Top Space (Hyprland)"
                                subtitle: "Reserved top screen exclusive space for window layout margin (0px - 100px)"
                                value: reservedTopSpace
                                from: 0; to: 100
                                onValueMoved: (newVal) => { reservedTopSpace = Math.round(newVal); saveSettings(); }
                            }

                            Text {
                                text: "Pill & Bar Visibility"
                                color: colorPrimary
                                font.pixelSize: 13
                                font.family: "Inter Display"
                                font.weight: Font.Bold
                                topPadding: 8
                            }

                            SettingsCard {
                                title: "Left Lyrics / Status Pill"
                                subtitle: "Show/hide the left status pill for music lyrics and app status"

                                control: SettingsSwitch {
                                    checked: showTopLeftPill
                                    onToggled: (newValue) => {
                                        showTopLeftPill = newValue;
                                        saveSettings();
                                    }
                                }
                            }

                            SettingsCard {
                                title: "Right Cava Audio Visualizer Pill"
                                subtitle: "Show/hide the audio spectrum visualizer pill when music is playing"

                                control: SettingsSwitch {
                                    checked: showTopRightCava
                                    onToggled: (newValue) => {
                                        showTopRightCava = newValue;
                                        saveSettings();
                                    }
                                }
                            }

                            SettingsCard {
                                title: "Right Battery & Volume Status Pill"
                                subtitle: "Show/hide the right status pill for battery level and volume status"

                                control: SettingsSwitch {
                                    checked: showTopRightBattery
                                    onToggled: (newValue) => {
                                        showTopRightBattery = newValue;
                                        saveSettings();
                                    }
                                }
                            }

                            SettingsCard {
                                title: "Right System Tray Pill"
                                subtitle: "Show/hide the right system tray icons pill"

                                control: SettingsSwitch {
                                    checked: showTopRightTray
                                    onToggled: (newValue) => {
                                        showTopRightTray = newValue;
                                        saveSettings();
                                    }
                                }
                            }

                            SettingsCard {
                                title: "Power Mode Profile Switcher"
                                subtitle: "Enable or disable power-profiles-daemon switching in Control Center"

                                control: Row {
                                    spacing: 6
                                    Rectangle {
                                        width: 85; height: 32; radius: 8
                                        color: tlpPermissionMode !== "skip" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "Enabled"; color: tlpPermissionMode !== "skip" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                tlpPermissionMode = "password";
                                                saveSettings();
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 85; height: 32; radius: 8
                                        color: tlpPermissionMode === "skip" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "Disabled"; color: tlpPermissionMode === "skip" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                tlpPermissionMode = "skip";
                                                saveSettings();
                                            }
                                        }
                                    }
                                }
                            }

                            SettingsCard {
                                title: "Auto-Hide Idle Center Island"
                                subtitle: "Automatically hide the center island pill when idle"

                                control: SettingsSwitch {
                                    checked: islandAutoHideEnabled
                                    onToggled: (newValue) => {
                                        islandAutoHideEnabled = newValue;
                                        saveSettings();
                                    }
                                }
                            }
                        }

                        // ==================== CATEGORY 2: NOTEPAD ====================
                        ColumnLayout {
                            visible: root.activeCategory === "notepad" || root.searchQuery !== ""
                            Layout.fillWidth: true
                            spacing: 14

                            SettingsCard {
                                title: "Default View Mode"
                                subtitle: "Initial mode when opening the Notepad notch (Edit or Preview)"

                                control: Row {
                                    spacing: 8
                                    Rectangle {
                                        width: 80; height: 32; radius: 8
                                        color: notepadDefaultMode === "edit" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "Edit"; color: notepadDefaultMode === "edit" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { notepadDefaultMode = "edit"; saveSettings(); } }
                                    }

                                    Rectangle {
                                        width: 80; height: 32; radius: 8
                                        color: notepadDefaultMode === "preview" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "Preview"; color: notepadDefaultMode === "preview" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { notepadDefaultMode = "preview"; saveSettings(); } }
                                    }
                                }
                            }

                            SettingsCard {
                                title: "Auto-Save Notes"
                                subtitle: "Automatically save note content while typing"

                                control: SettingsSwitch {
                                    checked: notepadAutoSave
                                    onToggled: (newValue) => {
                                        notepadAutoSave = newValue;
                                        saveSettings();
                                    }
                                }
                            }
                        }

                        // ==================== CATEGORY 3: ISLAND ACTIONS ====================
                        ColumnLayout {
                            visible: root.activeCategory === "actions" || root.searchQuery !== ""
                            Layout.fillWidth: true
                            spacing: 14

                            SettingsCard {
                                title: "Left-Click Action"
                                subtitle: "Action triggered when clicking the Dynamic Island"

                                Grid {
                                    columns: 2
                                    spacing: 8
                                    width: parent.width
                                    topPadding: 4

                                    readonly property var options: [
                                        { label: "Expanded Player", value: "toggleExpandedPlayer" },
                                        { label: "Control Center", value: "toggleControlCenter" },
                                        { label: "App Launcher", value: "toggleLauncher" },
                                        { label: "Notepad Notch", value: "toggleNotepad" },
                                        { label: "Overview", value: "toggleOverview" }
                                    ]

                                    Repeater {
                                        model: parent.options
                                        Rectangle {
                                            width: (parent.width - 8) / 2
                                            height: 34
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
                                    topPadding: 4

                                    readonly property var options: [
                                        { label: "Control Center", value: "toggleControlCenter" },
                                        { label: "Notepad Notch", value: "toggleNotepad" },
                                        { label: "Workspace Overview", value: "toggleOverview" },
                                        { label: "Clipboard Manager", value: "toggleClipboard" },
                                        { label: "Emoji Picker", value: "toggleEmojis" }
                                    ]

                                    Repeater {
                                        model: parent.options
                                        Rectangle {
                                            width: (parent.width - 8) / 2
                                            height: 34
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
                        }

                        // ==================== CATEGORY 4: CLOCK & BEHAVIOR ====================
                        ColumnLayout {
                            visible: root.activeCategory === "clock_date" || root.searchQuery !== ""
                            Layout.fillWidth: true
                            spacing: 14

                            SettingsCard {
                                title: "Clock Format"
                                subtitle: "Choose between 12-hour (AM/PM) and 24-hour time format"

                                control: Row {
                                    spacing: 8
                                    Rectangle {
                                        width: 80; height: 32; radius: 8
                                        color: clockFormat === "12" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "12-Hour"; color: clockFormat === "12" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { clockFormat = "12"; saveSettings(); } }
                                    }

                                    Rectangle {
                                        width: 80; height: 32; radius: 8
                                        color: clockFormat === "24" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "24-Hour"; color: clockFormat === "24" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { clockFormat = "24"; saveSettings(); } }
                                    }
                                }
                            }

                            SettingsCard {
                                title: "Auto-Expand on Music Change"
                                subtitle: "Automatically expand island briefly when a new song starts playing"

                                control: SettingsSwitch {
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

                                control: SettingsSwitch {
                                    checked: showBatteryPercentage
                                    onToggled: (newValue) => {
                                        showBatteryPercentage = newValue;
                                        saveSettings();
                                    }
                                }
                            }
                        }

                        Item { Layout.preferredHeight: 16 }
                    }
                }
            }
        }
    }
}
