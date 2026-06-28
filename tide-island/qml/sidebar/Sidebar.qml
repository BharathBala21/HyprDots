import QtQuick
import QtQuick.Controls.Basic

Item {
    id: root
    implicitWidth: 350
    implicitHeight: 800

    property bool isOpen: false
    property var themeColors: null
    readonly property alias theme: theme

    // Track if there are open windows in the active workspace
    property bool hasOpenWindows: false

    // Instantiate Matugen theme loader with passed colors
    MatugenTheme {
        id: theme
        colors: root.themeColors
    }

    // Expose the sidebar panel so it can be referenced in mask regions
    property alias panel: sidebarPanel

    // macOS Liquid Glass background panel (only active when windows are open behind it)
    Rectangle {
        id: glassBackground
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        
        // Dynamic width matching the open/closed state of the sidebar panel
        width: root.isOpen ? 332 : 0
        visible: width > 0

        // Liquid glass styling: translucent card color
        color: root.hasOpenWindows ? Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.45) : "transparent"

        Behavior on width {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutQuint
            }
        }

        // Sleek separator line only on the right edge of the glass panel
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: root.hasOpenWindows ? Qt.rgba(theme.outline.r, theme.outline.g, theme.outline.b, 0.25) : "transparent"
        }
    }

    // Sidebar Container (Invisible background behind components)
    Item {
        id: sidebarPanel
        width: 300
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 48 // Start below the status bar
        anchors.bottomMargin: 16

        // Slide animation: closed is off-screen, open is at x: 16
        x: root.isOpen ? 16 : -width - 40

        Behavior on x {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutQuint
            }
        }

        // Scrollable widgets list
        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: widgetColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            // Completely hide scrollbar track and handle to prevent vertical lines
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }

            Column {
                id: widgetColumn
                width: parent.width
                spacing: 16 // Spacing between cards

                // 1. Timer & Pomodoro Widget
                TimerWidget {
                    theme: theme
                    width: parent.width
                }

                // 2. Calendar Widget
                CalendarWidget {
                    theme: theme
                    width: parent.width
                }

                // 3. World Clock Widget
                WorldClockWidget {
                    theme: theme
                    width: parent.width
                }

                // 4. Todo List Widget
                TodoListWidget {
                    theme: theme
                    width: parent.width
                }
            }
        }
    }
}
