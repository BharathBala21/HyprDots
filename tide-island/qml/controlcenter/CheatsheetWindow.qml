import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import IslandBackend

FloatingWindow {
    id: root

    title: "Cheat sheet"
    implicitWidth: 1060
    implicitHeight: 600
    color: colorBackground

    signal cheatsheetClosed()

    onVisibleChanged: {
        if (!visible) {
            cheatsheetClosed();
        }
    }

    Component.onDestruction: {
        cheatsheetClosed();
    }

    readonly property string iconFontFamily: UserConfig.iconFontFamily
    readonly property string textFontFamily: UserConfig.textFontFamily
    readonly property string heroFontFamily: UserConfig.heroFontFamily

    // Matugen dynamic theme colors
    readonly property var themeColors: shellRoot.matugenThemeColors

    readonly property color colorBackground: themeColors ? themeColors.background : "#0b0c10"
    readonly property color colorPrimary: themeColors ? themeColors.primary : "#c084fc"
    readonly property color colorOnSurface: themeColors ? themeColors.on_surface : "#ffffff"
    readonly property color colorOnSurfaceVariant: themeColors ? themeColors.on_surface_variant : "#94a3b8"
    readonly property color colorOutline: themeColors ? themeColors.outline_variant : Qt.rgba(1, 1, 1, 0.08)
    readonly property color colorSecondaryContainer: themeColors ? themeColors.secondary_container : Qt.rgba(1, 1, 1, 0.08)
    readonly property color colorOnSecondaryContainer: themeColors ? themeColors.on_secondary_container : "#f8fafc"

    // Defer focus to the window root to handle escape key press
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
        { keys: "Ctrl+Shift+Esc", desc: "System monitor" }
    ]

    readonly property var appsMediaBinds: [
        { keys: "Super+Enter", desc: "Terminal (kitty)" },
        { keys: "Super+E", desc: "File manager (dolphin)" },
        { keys: "Super+C", desc: "Code editor (VS Code)" },
        { keys: "Super+W", desc: "Browser (zen)" },
        { keys: "Super+Shift+C", desc: "Color picker" },
        { keys: "Super+Shift+O", desc: "OCR text capture" },
        { keys: "Super+Shift+S", desc: "Snip area" },
        { keys: "Print", desc: "Snip screen" },
        { keys: "Super+Shift+W", desc: "Snip window" },
        { keys: "Super+R", desc: "Screen recording" },
        { keys: "Vol Up/Down", desc: "Adjust volume" },
        { keys: "Mute/Mic Mute", desc: "Toggle audio/mic" },
        { keys: "Bright Up/Down", desc: "Adjust brightness" }
    ]

    // Background styling with custom rounding to match tide-island theme
    Rectangle {
        anchors.fill: parent
        color: colorBackground
        border.width: 1
        border.color: colorOutline
        radius: 30
    }

    // Main Layout column
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Header Section
        Item {
            width: parent.width
            height: 40

            Text {
                id: titleText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: "Cheat sheet"
                font.family: root.heroFontFamily
                font.pixelSize: 24
                font.bold: true
                color: colorOnSurface
            }

            // Close button (x)
            MouseArea {
                id: closeBtn
                width: 32
                height: 32
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                hoverEnabled: true
                onClicked: shellRoot.cheatsheetWindowOpen = false

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

        // Scrollable Area containing keybind columns to prevent any overflow issues
        ScrollView {
            id: scrollView
            width: parent.width
            height: parent.height - 40 - 16 - 17 // Remaining height
            clip: true
            
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Row {
                width: scrollView.availableWidth
                spacing: 20

                // Column 1: Window
                Column {
                    width: (parent.width - 60) / 4
                    spacing: 14

                    Text {
                        text: "Window"
                        font.family: root.heroFontFamily
                        font.pixelSize: 18
                        font.bold: true
                        color: colorPrimary
                    }

                    Column {
                        width: parent.width
                        spacing: 10
                        Repeater {
                            model: root.windowBinds
                            delegate: shortcutRowDelegate
                        }
                    }
                }

                // Column 2: Workspace
                Column {
                    width: (parent.width - 60) / 4
                    spacing: 14

                    Text {
                        text: "Workspace"
                        font.family: root.heroFontFamily
                        font.pixelSize: 18
                        font.bold: true
                        color: colorPrimary
                    }

                    Column {
                        width: parent.width
                        spacing: 10
                        Repeater {
                            model: root.workspaceBinds
                            delegate: shortcutRowDelegate
                        }
                    }
                }

                // Column 3: Shell & System
                Column {
                    width: (parent.width - 60) / 4
                    spacing: 14

                    Text {
                        text: "Shell & System"
                        font.family: root.heroFontFamily
                        font.pixelSize: 18
                        font.bold: true
                        color: colorPrimary
                    }

                    Column {
                        width: parent.width
                        spacing: 10
                        Repeater {
                            model: root.shellBinds
                            delegate: shortcutRowDelegate
                        }
                    }
                }

                // Column 4: Apps & Media
                Column {
                    width: (parent.width - 60) / 4
                    spacing: 14

                    Text {
                        text: "Apps & Media"
                        font.family: root.heroFontFamily
                        font.pixelSize: 18
                        font.bold: true
                        color: colorPrimary
                    }

                    Column {
                        width: parent.width
                        spacing: 10
                        Repeater {
                            model: root.appsMediaBinds
                            delegate: shortcutRowDelegate
                        }
                    }
                }
            }
        }
    }

    // Row delegate for keycaps and description
    Component {
        id: shortcutRowDelegate
        Item {
            width: parent.width
            height: 32

            Row {
                id: keysRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                readonly property var keysArray: root.parseKeys(modelData.keys)

                Repeater {
                    model: keysRow.keysArray

                    Row {
                        spacing: 5
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            height: 26
                            width: keyText.text === "" ? 26 : Math.max(26, keyText.implicitWidth + 12)
                            radius: 6
                            color: colorSecondaryContainer
                            border.width: 1
                            border.color: colorOutline
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: keyText
                                text: modelData
                                font.family: modelData === "" ? root.iconFontFamily : root.textFontFamily
                                font.pixelSize: modelData === "" ? 14 : 13
                                font.bold: modelData !== ""
                                color: colorOnSecondaryContainer
                                anchors.centerIn: parent
                            }
                        }

                        Text {
                            text: "+"
                            font.family: root.textFontFamily
                            font.pixelSize: 13
                            color: colorOnSurfaceVariant
                            opacity: 0.5
                            anchors.verticalCenter: parent.verticalCenter
                            visible: index < keysRow.keysArray.length - 1
                        }
                    }
                }
            }

            // Description label aligned to the right, elided if the column is too narrow to avoid overlapping
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - keysRow.width - 8
                text: modelData.desc
                color: colorOnSurfaceVariant
                font.family: root.textFontFamily
                font.pixelSize: 14
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }
    }
}
