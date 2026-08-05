import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IslandBackend

FloatingWindow {
    id: root

    title: "Tide-Island Settings"
    implicitWidth: 840
    implicitHeight: 580
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
    property int islandCompactWidth: cfgData.islandCompactWidth !== undefined ? Number(cfgData.islandCompactWidth) : 140
    property int islandCompactHeight: cfgData.islandCompactHeight !== undefined ? Number(cfgData.islandCompactHeight) : 35
    property int islandCornerRadius: cfgData.islandCornerRadius !== undefined ? Number(cfgData.islandCornerRadius) : 19
    property int islandTopOffset: cfgData.islandTopOffset !== undefined ? Number(cfgData.islandTopOffset) : 4
    property int islandInnerPadding: cfgData.islandInnerPadding !== undefined ? Number(cfgData.islandInnerPadding) : 8
    property string notepadDefaultMode: cfgData.notepadDefaultMode !== undefined ? String(cfgData.notepadDefaultMode) : "edit"
    property bool notepadAutoSave: cfgData.notepadAutoSave !== undefined ? cfgData.notepadAutoSave : true

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
            "--island-compact-width", String(islandCompactWidth),
            "--island-compact-height", String(islandCompactHeight),
            "--island-corner-radius", String(islandCornerRadius),
            "--island-top-offset", String(islandTopOffset),
            "--island-inner-padding", String(islandInnerPadding),
            "--notepad-default-mode", notepadDefaultMode,
            "--notepad-auto-save", notepadAutoSave ? "true" : "false"
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
        default property alias content: cardContent.data
        property string title: ""
        property string subtitle: ""

        Layout.fillWidth: true
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
        implicitHeight: 70
        radius: 14
        color: colorCardBg
        border.color: Qt.rgba(colorOutline.r, colorOutline.g, colorOutline.b, 0.25)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: gCard.title
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: colorOnSurface
                    }
                    Text {
                        text: gCard.subtitle
                        font.pixelSize: 11
                        color: colorOnSurfaceVariant
                        visible: gCard.subtitle !== ""
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: Math.round(gCard.value) + " " + gCard.unit
                    font.pixelSize: 13
                    font.bold: true
                    color: colorPrimary
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
                            placeholderText: "Search Settings..."
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
                            { id: "bar_island", icon: "🖥️", label: "Bar & Island", desc: "Shape, size, notch style, and custom geometry." },
                            { id: "notepad", icon: "📝", label: "Notepad Notch", desc: "Default view mode, auto-save settings, and markdown." },
                            { id: "actions", icon: "⚡", label: "Island Actions", desc: "Primary left-click and secondary right-click actions." },
                            { id: "clock_date", icon: "🕒", label: "Clock & Behavior", desc: "Time format, auto-expansion, and battery text." }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: 10
                            color: root.activeCategory === modelData.id ? colorPrimary : (navMouse.containsMouse ? "#18ffffff" : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    font.pixelSize: 15
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
                                    case "bar_island": return "🖥️";
                                    case "notepad": return "📝";
                                    case "actions": return "⚡";
                                    case "clock_date": return "🕒";
                                    default: return "🏝️";
                                    }
                                }
                                font.pixelSize: 22
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
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        width: parent.width - 12
                        spacing: 12

                        // ==================== CATEGORY 1: BAR & ISLAND ====================
                        ColumnLayout {
                            visible: root.activeCategory === "bar_island" || root.searchQuery !== ""
                            Layout.fillWidth: true
                            spacing: 12

                            SettingsCard {
                                title: "Island Visual Style"
                                subtitle: "Choose between floating island pill and flush top screen notch"

                                Row {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: -28
                                    spacing: 6

                                    Rectangle {
                                        width: 85; height: 28; radius: 8
                                        color: islandStyle === "pill" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "Floating Pill"; color: islandStyle === "pill" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { islandStyle = "pill"; saveSettings(); } }
                                    }

                                    Rectangle {
                                        width: 85; height: 28; radius: 8
                                        color: islandStyle === "notch" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "Top Notch"; color: islandStyle === "notch" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { islandStyle = "notch"; saveSettings(); } }
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
                        }

                        // ==================== CATEGORY 2: NOTEPAD ====================
                        ColumnLayout {
                            visible: root.activeCategory === "notepad" || root.searchQuery !== ""
                            Layout.fillWidth: true
                            spacing: 12

                            SettingsCard {
                                title: "Default View Mode"
                                subtitle: "Initial mode when opening the Notepad notch (Edit or Preview)"

                                Row {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: -28
                                    spacing: 6

                                    Rectangle {
                                        width: 70; height: 28; radius: 8
                                        color: notepadDefaultMode === "edit" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "Edit"; color: notepadDefaultMode === "edit" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { notepadDefaultMode = "edit"; saveSettings(); } }
                                    }

                                    Rectangle {
                                        width: 70; height: 28; radius: 8
                                        color: notepadDefaultMode === "preview" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "Preview"; color: notepadDefaultMode === "preview" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { notepadDefaultMode = "preview"; saveSettings(); } }
                                    }
                                }
                            }

                            SettingsCard {
                                title: "Auto-Save Notes"
                                subtitle: "Automatically save note content while typing"

                                SettingsSwitch {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: -24
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
                            spacing: 12

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
                                        { label: "Notepad Notch", value: "toggleNotepad" },
                                        { label: "Overview", value: "toggleOverview" }
                                    ]

                                    Repeater {
                                        model: parent.options
                                        Rectangle {
                                            width: (parent.width - 8) / 2
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
                                        { label: "Notepad Notch", value: "toggleNotepad" },
                                        { label: "Workspace Overview", value: "toggleOverview" },
                                        { label: "Clipboard Manager", value: "toggleClipboard" },
                                        { label: "Emoji Picker", value: "toggleEmojis" }
                                    ]

                                    Repeater {
                                        model: parent.options
                                        Rectangle {
                                            width: (parent.width - 8) / 2
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
                        }

                        // ==================== CATEGORY 4: CLOCK & BEHAVIOR ====================
                        ColumnLayout {
                            visible: root.activeCategory === "clock_date" || root.searchQuery !== ""
                            Layout.fillWidth: true
                            spacing: 12

                            SettingsCard {
                                title: "Clock Format"
                                subtitle: "Choose between 12-hour (AM/PM) and 24-hour time format"

                                Row {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: -28
                                    spacing: 6

                                    Rectangle {
                                        width: 70; height: 28; radius: 8
                                        color: clockFormat === "12" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "12-Hour"; color: clockFormat === "12" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { clockFormat = "12"; saveSettings(); } }
                                    }

                                    Rectangle {
                                        width: 70; height: 28; radius: 8
                                        color: clockFormat === "24" ? colorPrimary : colorSecondaryContainer
                                        Text { anchors.centerIn: parent; text: "24-Hour"; color: clockFormat === "24" ? "#ffffff" : colorOnSurfaceVariant; font.pixelSize: 11; font.family: "Inter Display"; font.weight: Font.Medium }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { clockFormat = "24"; saveSettings(); } }
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
                        }

                        Item { Layout.preferredHeight: 16 }
                    }
                }
            }
        }
    }
}
