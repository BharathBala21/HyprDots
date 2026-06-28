import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import IslandBackend

FloatingWindow {
    id: root

    title: "Cheat sheet"
    implicitWidth: 1120 // Slightly widened to provide cozy breathing room for descriptions
    implicitHeight: 620
    color: "transparent"

    signal cheatsheetClosed()

    onVisibleChanged: {
        if (!visible) {
            cheatsheetClosed();
        }
    }

    Component.onDestruction: {
        cheatsheetClosed();
    }

    function close() {
        cheatsheetClosed();
    }

    readonly property string iconFontFamily: UserConfig.iconFontFamily
    readonly property string textFontFamily: UserConfig.textFontFamily
    readonly property string heroFontFamily: UserConfig.heroFontFamily

    // Matugen dynamic theme colors
    property var themeColors: shellRoot.matugenThemeColors
    property bool openOnStartup: false
    signal toggleOpenOnStartup(bool val)

    readonly property color colorBackground: themeColors ? themeColors.background : "#0b0c10"
    readonly property color colorPrimary: themeColors ? themeColors.primary : "#c084fc"
    readonly property color colorOnSurface: themeColors ? themeColors.on_surface : "#ffffff"
    readonly property color colorOnSurfaceVariant: themeColors ? themeColors.on_surface_variant : "#94a3b8"
    readonly property color colorOutline: themeColors ? themeColors.outline_variant : Qt.rgba(1, 1, 1, 0.08)
    readonly property color colorSecondaryContainer: themeColors ? themeColors.secondary_container : Qt.rgba(1, 1, 1, 0.08)
    readonly property color colorOnSecondaryContainer: themeColors ? themeColors.on_secondary_container : "#f8fafc"

    // Defer focus to the background container to handle escape key press without warnings
    Timer {
        id: focusTimer
        interval: 10
        running: true
        repeat: false
        onTriggered: cheatsheetContentContainer.forceActiveFocus()
    }

    // Helper function to parse key combo string into friendly symbols
    function parseKeys(keyStr) {
        if (!keyStr) return [];
        const parts = String(keyStr).split("+");
        const result = [];
        for (let i = 0; i < parts.length; i++) {
            let part = parts[i].trim();
            if (part === "") continue;
            
            const lower = part.toLowerCase();
            if (lower === "super" || lower === "super_l" || lower === "win") {
                result.push(""); // Font Awesome Arch
            } else if (lower === "ctrl" || lower === "control") {
                result.push("Ctrl");
            } else if (lower === "shift") {
                result.push("Shift");
            } else if (lower === "alt") {
                result.push("Alt");
            } else if (lower === "left") {
                result.push("←");
            } else if (lower === "right") {
                result.push("→");
            } else if (lower === "up") {
                result.push("↑");
            } else if (lower === "down") {
                result.push("↓");
            } else if (lower === "return" || lower === "enter") {
                result.push("Enter");
            } else if (lower === "space") {
                result.push("Space");
            } else if (lower === "period") {
                result.push(".");
            } else if (lower.indexOf("mouse:") !== -1) {
                if (lower === "mouse:272") result.push("LMB");
                else if (lower === "mouse:273") result.push("RMB");
                else result.push(part);
            } else if (lower === "mouse_up") {
                result.push("Scroll ↑");
            } else if (lower === "mouse_down") {
                result.push("Scroll ↓");
            } else if (lower === "code:9") {
                result.push("Esc");
            } else {
                result.push(part.charAt(0).toUpperCase() + part.slice(1));
            }
        }
        return result;
    }

    // Keybinds Data Models
    readonly property var windowBinds: [
        { keys: "Super+Q", desc: "Close window" },
        { keys: "Super+Arrow Keys", desc: "Focus direction" },
        { keys: "Alt+Tab", desc: "Cycle windows" },
        { keys: "Alt+Shift+Tab", desc: "Cycle previous" },
        { keys: "Super+Z", desc: "Interactive move" },
        { keys: "Super+X", desc: "Interactive resize" },
        { keys: "Super+LMB", desc: "Drag window" },
        { keys: "Super+RMB", desc: "Resize window" },
        { keys: "Super+P", desc: "Pseudo mode" },
        { keys: "Super+Alt+Space", desc: "Float / Tile" },
        { keys: "Super+Shift+Arrow Keys", desc: "Move direction" },
        { keys: "Super+F", desc: "Fullscreen" },
        { keys: "Super+D", desc: "Maximize" }
    ]

    readonly property var workspaceBinds: [
        { keys: "Super+1..9", desc: "Focus workspace" },
        { keys: "Super+Ctrl+←/→", desc: "Workspace left/right" },
        { keys: "Super+Scroll", desc: "Workspace left/right" },
        { keys: "Super+Alt+1..9", desc: "Move window to workspace" },
        { keys: "Super+Alt+S", desc: "Spotify workspace" },
        { keys: "Super+Alt+D", desc: "Discord workspace" },
        { keys: "Super+Alt+E", desc: "Yazi workspace" },
        { keys: "Super+Alt+Enter", desc: "Terminal workspace" }
    ]

    readonly property var shellBinds: [
        { keys: "Super", desc: "Toggle Launcher" },
        { keys: "Super+V", desc: "Clipboard history" },
        { keys: "Super+.", desc: "Emoji picker" },
        { keys: "Super+Alt+W", desc: "Wallpaper picker" },
        { keys: "Super+Tab", desc: "Workspace overview" },
        { keys: "Super+A", desc: "Control center" },
        { keys: "Super+L", desc: "Lock screen" },
        { keys: "Ctrl+Shift+Esc", desc: "System monitor" },
        { keys: "Super+U", desc: "Utilities" },
        { keys: "Super+/", desc: "Toggle cheatsheet" },
        { keys: "Super+Shift+R", desc: "Reload shell" },
        { keys: "Super+Shift+Q", desc: "Exit shell" }
    ]

    readonly property var appsMediaBinds: [
        { keys: "Super+Enter", desc: "Terminal (kitty)" },
        { keys: "Super+E", desc: "File manager (dolphin)" },
        { keys: "Super+C", desc: "Code editor (VS Code)" },
        { keys: "Super+W", desc: "Browser (zen)" },
        { keys: "Super+Shift+C", desc: "Color picker" },
        { keys: "Super+Shift+O", desc: "OCR text capture" },
        { keys: "Super+Shift+V", desc: "Visual search (Lens)" },
        { keys: "Super+Shift+S", desc: "Snip area" },
        { keys: "Print", desc: "Snip screen" },
        { keys: "Super+Shift+W", desc: "Snip window" },
        { keys: "Super+R", desc: "Start/Stop Screen recording" }
    ]

    // Background styling with custom rounding to match tide-island theme
    Rectangle {
        id: cheatsheetContentContainer
        anchors.fill: parent
        color: colorBackground
        border.width: 0
        border.color: colorOutline
        radius: 30
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            }
        }
    }

    // Main Layout column
    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // Header Section
        Item {
            width: parent.width
            height: 40

            // Open on startup toggle on the left
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    text: "Open on startup"
                    font.family: root.textFontFamily
                    font.pixelSize: 13
                    color: colorOnSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Switch widget
                MouseArea {
                    id: startupToggle
                    width: 38
                    height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    hoverEnabled: true
                    onClicked: {
                        root.toggleOpenOnStartup(!root.openOnStartup);
                    }

                    Rectangle {
                        id: switchTrack
                        anchors.fill: parent
                        radius: height / 2
                        color: root.openOnStartup ? colorPrimary : (startupToggle.containsMouse ? colorSecondaryContainer : Qt.rgba(1, 1, 1, 0.05))
                        border.width: 1
                        border.color: root.openOnStartup ? "transparent" : colorOutline
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            id: switchThumb
                            width: 16
                            height: 16
                            radius: 8
                            color: root.openOnStartup ? colorBackground : (startupToggle.containsMouse ? colorOnSurface : colorOnSurfaceVariant)
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.openOnStartup ? (parent.width - width - 3) : 3
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }

            // Centered title and keycap shortcut
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Text {
                    id: titleText
                    text: "Cheat sheet"
                    font.family: root.heroFontFamily
                    font.pixelSize: 24
                    font.bold: true
                    color: colorOnSurface
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Keycap shortcut modular group
                Row {
                    id: headerShortcutRow
                    spacing: 6
                    anchors.verticalCenter: parent.verticalCenter
                    
                    readonly property var headerKeys: ["", "/"]

                    Repeater {
                        model: headerShortcutRow.headerKeys

                        Row {
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter

                            // Individual modular keycap
                            Rectangle {
                                height: 24
                                width: Math.max(24, headerKeyText.implicitWidth + 12)
                                radius: 6
                                color: colorSecondaryContainer
                                border.width: 1
                                border.color: colorOutline
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: headerKeyText
                                    text: modelData
                                    font.family: modelData === "" ? root.iconFontFamily : root.textFontFamily
                                    font.pixelSize: modelData === "" ? 12 : 11
                                    font.bold: true
                                    color: colorOnSecondaryContainer
                                    anchors.centerIn: parent
                                }
                            }

                            // Plus separator logic
                            Text {
                                text: "+"
                                font.family: root.textFontFamily
                                font.pixelSize: 12
                                color: colorOnSurfaceVariant
                                opacity: 0.5
                                anchors.verticalCenter: parent.verticalCenter
                                visible: index < headerShortcutRow.headerKeys.length - 1
                            }
                        }
                    }
                }
            }

            // Close button (x)
            MouseArea {
                id: closeBtn
                width: 32
                height: 32
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                hoverEnabled: true
                onClicked: root.close()

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: closeBtn.containsMouse ? colorSecondaryContainer : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    text: "" // Font Awesome close x icon
                    font.family: root.iconFontFamily
                    font.pixelSize: 14
                    color: closeBtn.containsMouse ? colorOnSurface : colorOnSurfaceVariant
                    anchors.centerIn: parent
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        // Horizontal Divider line
        Rectangle {
            width: parent.width
            height: 1
            color: colorOutline
        }

        // Scrollable Area containing keybind columns
        ScrollView {
            id: scrollView
            width: parent.width
            height: parent.height - 40 - 16 - 24 // Adjusted to offset bottom margins cleanly
            clip: true
            
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Row {
                width: scrollView.availableWidth
                spacing: 24 // Increased column gap slightly for easier parsing

                // Column 1: Window
                Column {
                    width: (parent.width - 72) / 4
                    spacing: 16

                    Text {
                        text: "Window"
                        font.family: root.heroFontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colorPrimary
                    }

                    Column {
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: root.windowBinds
                            delegate: shortcutRowDelegate
                        }
                    }
                }

                // Column 2: Workspace
                Column {
                    width: (parent.width - 72) / 4
                    spacing: 16

                    Text {
                        text: "Workspace"
                        font.family: root.heroFontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colorPrimary
                    }

                    Column {
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: root.workspaceBinds
                            delegate: shortcutRowDelegate
                        }
                    }
                }

                // Column 3: Shell & System
                Column {
                    width: (parent.width - 72) / 4
                    spacing: 16

                    Text {
                        text: "Shell & System"
                        font.family: root.heroFontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colorPrimary
                    }

                    Column {
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: root.shellBinds
                            delegate: shortcutRowDelegate
                        }
                    }
                }

                // Column 4: Apps & Media
                Column {
                    width: (parent.width - 72) / 4
                    spacing: 16

                    Text {
                        text: "Apps & Media"
                        font.family: root.heroFontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colorPrimary
                    }

                    Column {
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: root.appsMediaBinds
                            delegate: shortcutRowDelegate
                        }
                    }
                }
            }
        }
    }

    // Row delegate optimized for instant readability and visual binding alignment
    Component {
        id: shortcutRowDelegate
        Item {
            width: parent.width
            height: 34

            // Alternating rows / clean hit box backdrop to guide line tracking
            Rectangle {
                anchors.fill: parent
                radius: 6
                color: Qt.rgba(1, 1, 1, index % 2 === 0 ? 0.015 : 0.0)
            }

            // Fixed-width track container for the shortcut keys to align all text descriptions perfectly
            Item {
                id: keysContainer
                width: parent.width * 0.48 // Reserves stable alignment footprint across long combos (e.g., Super+Shift+Arrow Keys)
                height: parent.height
                anchors.left: parent.left
                anchors.leftMargin: 4

                Row {
                    id: keysRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    readonly property var keysArray: root.parseKeys(modelData.keys)

                    Repeater {
                        model: keysRow.keysArray

                        Row {
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                height: 24
                                width: (modelData === "" || modelData === "") ? 24 : Math.max(24, keyText.implicitWidth + 10)
                                radius: 5
                                color: colorSecondaryContainer
                                border.width: 1
                                border.color: colorOutline
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: keyText
                                    text: modelData
                                    font.family: (modelData === "" || modelData === "") ? root.iconFontFamily : root.textFontFamily
                                    font.pixelSize: (modelData === "" || modelData === "") ? 13 : 11
                                    font.bold: (modelData !== "" && modelData !== "")
                                    color: colorOnSecondaryContainer
                                    anchors.centerIn: parent
                                }
                            }

                            Text {
                                text: "+"
                                font.family: root.textFontFamily
                                font.pixelSize: 11
                                color: colorOnSurfaceVariant
                                opacity: 0.4
                                anchors.verticalCenter: parent.verticalCenter
                                visible: index < keysRow.keysArray.length - 1
                            }
                        }
                    }
                }
            }

            // Description text is now left-aligned adjacent to the keys container with an elide protective layer
            Text {
                anchors.left: keysContainer.right
                anchors.leftMargin: 6
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                
                text: modelData.desc
                color: colorOnSurface
                opacity: 0.85
                font.family: root.textFontFamily
                font.pixelSize: 13
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
            }
        }
    }
}