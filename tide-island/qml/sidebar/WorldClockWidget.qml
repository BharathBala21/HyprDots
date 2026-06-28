import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root
    implicitWidth: 300
    implicitHeight: 200
    radius: 16
    
    // Solid macOS-style widget background
    color: root.theme.surface
    border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.15)
    border.width: 1

    property QtObject theme

    readonly property var tzData: [
        { name: "New Delhi", zone: "Asia/Kolkata", offsetLabel: "IST (GMT+5:30)" },
        { name: "New York", zone: "America/New_York", offsetLabel: "EST/EDT (GMT-4)" },
        { name: "London", zone: "Europe/London", offsetLabel: "GMT/BST (GMT+1)" },
        { name: "Tokyo", zone: "Asia/Tokyo", offsetLabel: "JST (GMT+9)" },
        { name: "Sydney", zone: "Australia/Sydney", offsetLabel: "AEST/AEDT (GMT+10)" },
        { name: "Paris", zone: "Europe/Paris", offsetLabel: "CET/CEST (GMT+2)" }
    ]

    property int clock1Index: 0 // New Delhi
    property int clock2Index: 1 // New York
    property int clock3Index: 2 // London

    property date currentDate: new Date()

    Timer {
        id: ticker
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.currentDate = new Date()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 24
                height: 24
                radius: 6
                color: Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.15)
                
                Text {
                    anchors.centerIn: parent
                    text: "🌐"
                    font.pixelSize: 11
                }
            }

            Text {
                text: qsTr("World Clock")
                color: root.theme.on_surface
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }
        }

        // Clocks grid
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            ClockItem {
                Layout.fillWidth: true
                theme: root.theme
                currentDate: root.currentDate
                tzList: root.tzData
                selectedIndex: root.clock1Index
                onSelectionChanged: (idx) => root.clock1Index = idx
            }

            ClockItem {
                Layout.fillWidth: true
                theme: root.theme
                currentDate: root.currentDate
                tzList: root.tzData
                selectedIndex: root.clock2Index
                onSelectionChanged: (idx) => root.clock2Index = idx
            }

            ClockItem {
                Layout.fillWidth: true
                theme: root.theme
                currentDate: root.currentDate
                tzList: root.tzData
                selectedIndex: root.clock3Index
                onSelectionChanged: (idx) => root.clock3Index = idx
            }
        }
    }
}
