import QtQuick
import QtQuick.Controls.Basic

Item {
    id: root
    implicitWidth: 350
    implicitHeight: 800

    property bool isOpen: false
    property var themeColors: null
    readonly property alias theme: theme
    property bool hasOpenWindows: false

    property string iconFontFamily: ""
    property string textFontFamily: ""

    MatugenTheme {
        id: theme
        colors: root.themeColors
    }

    property alias panel: sidebarPanel

    Rectangle {
        id: glassBackground
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.isOpen ? 340 : 0
        visible: width > 0

        // Deeper tint for better contrast with the widgets
        color: root.hasOpenWindows ? Qt.rgba(theme.surface_container.r, theme.surface_container.g, theme.surface_container.b, 0.65) : "transparent"

        Behavior on width {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: root.hasOpenWindows ? Qt.rgba(theme.outline.r, theme.outline.g, theme.outline.b, 0.4) : "transparent"
        }
    }

    Item {
        id: sidebarPanel
        width: 308 // Slightly wider to accommodate internal widget padding elegantly
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 64
        anchors.bottomMargin: 24

        x: root.isOpen ? 16 : -width - 40

        Behavior on x {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }

        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: widgetColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

            Column {
                id: widgetColumn
                width: parent.width
                spacing: 16 

                TimerWidget { theme: theme; width: parent.width; iconFontFamily: root.iconFontFamily }
                CalendarWidget { theme: theme; width: parent.width; iconFontFamily: root.iconFontFamily }
                WorldClockWidget { theme: theme; width: parent.width; iconFontFamily: root.iconFontFamily }
                TodoListWidget { theme: theme; width: parent.width; iconFontFamily: root.iconFontFamily }
            }
        }
    }
}