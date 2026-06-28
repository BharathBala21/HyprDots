import QtQuick
import QtQuick.Controls.Basic

Item {
    id: root
    implicitWidth: 320
    implicitHeight: 800

    property bool isOpen: false
    property var themeColors: null
    readonly property alias theme: theme

    // Instantiate Matugen theme loader with passed colors
    MatugenTheme {
        id: theme
        colors: root.themeColors
    }

    // Expose the sidebar panel so it can be referenced in mask regions
    property alias panel: sidebarPanel

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
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                background: Rectangle { color: "transparent" }
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: Qt.rgba(theme.on_surface.r, theme.on_surface.g, theme.on_surface.b, 0.15)
                }
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
