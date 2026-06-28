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

    Item {
        id: glassBackground
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.isOpen ? 360 : 0
        visible: width > 0

        Behavior on width {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }

    }

    Item {
        id: sidebarPanel
        width: 328 // Expanded width for a more premium look
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 48 // Pushes widgets slightly up
        anchors.bottomMargin: 24 // Significantly reduces the gap at the bottom

        readonly property real availableHeight: parent.height - 72
        readonly property real netHeight: availableHeight - 48
        readonly property real scaleFactor: Math.max(1.0, netHeight / 850)

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

                TimerWidget {
                    theme: theme
                    width: parent.width
                    height: Math.round(200 * sidebarPanel.scaleFactor)
                    iconFontFamily: root.iconFontFamily
                    textFontFamily: root.textFontFamily
                }

                CalendarWidget {
                    theme: theme
                    width: parent.width
                    height: Math.round(230 * sidebarPanel.scaleFactor)
                    iconFontFamily: root.iconFontFamily
                    textFontFamily: root.textFontFamily
                }

                WorldClockWidget {
                    theme: theme
                    width: parent.width
                    height: Math.round(210 * sidebarPanel.scaleFactor) // Substantially increased height
                    iconFontFamily: root.iconFontFamily
                    textFontFamily: root.textFontFamily
                }

                TodoListWidget {
                    theme: theme
                    width: parent.width
                    height: Math.round(210 * sidebarPanel.scaleFactor)
                    iconFontFamily: root.iconFontFamily
                    textFontFamily: root.textFontFamily
                }
            }
        }
    }
}