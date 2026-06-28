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
    property string iconFontFamily: ""

    // 30+ major global cities with standard UTC offsets (in minutes) and original indices
    readonly property var tzData: {
        var base = [
            { name: "New Delhi", zone: "Asia/Kolkata", offset: 330, offsetLabel: "IST (GMT+5:30)" },
            { name: "Mumbai", zone: "Asia/Kolkata", offset: 330, offsetLabel: "IST (GMT+5:30)" },
            { name: "Kolkata", zone: "Asia/Kolkata", offset: 330, offsetLabel: "IST (GMT+5:30)" },
            { name: "New York", zone: "America/New_York", offset: -240, offsetLabel: "EDT (GMT-4)" },
            { name: "London", zone: "Europe/London", offset: 60, offsetLabel: "BST (GMT+1)" },
            { name: "Tokyo", zone: "Asia/Tokyo", offset: 540, offsetLabel: "JST (GMT+9)" },
            { name: "Sydney", zone: "Australia/Sydney", offset: 600, offsetLabel: "AEST (GMT+10)" },
            { name: "Paris", zone: "Europe/Paris", offset: 120, offsetLabel: "CEST (GMT+2)" },
            { name: "Berlin", zone: "Europe/Berlin", offset: 120, offsetLabel: "CEST (GMT+2)" },
            { name: "Moscow", zone: "Europe/Moscow", offset: 180, offsetLabel: "MSK (GMT+3)" },
            { name: "Dubai", zone: "Asia/Dubai", offset: 240, offsetLabel: "GST (GMT+4)" },
            { name: "Singapore", zone: "Asia/Singapore", offset: 480, offsetLabel: "SGT (GMT+8)" },
            { name: "Hong Kong", zone: "Asia/Hong_Kong", offset: 480, offsetLabel: "HKT (GMT+8)" },
            { name: "Shanghai", zone: "Asia/Shanghai", offset: 480, offsetLabel: "CST (GMT+8)" },
            { name: "Seoul", zone: "Asia/Seoul", offset: 540, offsetLabel: "KST (GMT+9)" },
            { name: "Los Angeles", zone: "America/Los_Angeles", offset: -420, offsetLabel: "PDT (GMT-7)" },
            { name: "Chicago", zone: "America/Chicago", offset: -300, offsetLabel: "CDT (GMT-5)" },
            { name: "Denver", zone: "America/Denver", offset: -360, offsetLabel: "MDT (GMT-6)" },
            { name: "Mexico City", zone: "America/Mexico_City", offset: -360, offsetLabel: "CST (GMT-6)" },
            { name: "Sao Paulo", zone: "America/Sao_Paulo", offset: -180, offsetLabel: "BRT (GMT-3)" },
            { name: "Buenos Aires", zone: "America/Argentina/Buenos_Aires", offset: -180, offsetLabel: "ART (GMT-3)" },
            { name: "Cairo", zone: "Africa/Cairo", offset: 180, offsetLabel: "EET (GMT+3)" },
            { name: "Cape Town", zone: "Africa/Johannesburg", offset: 120, offsetLabel: "SAST (GMT+2)" },
            { name: "Nairobi", zone: "Africa/Nairobi", offset: 180, offsetLabel: "EAT (GMT+3)" },
            { name: "Bangkok", zone: "Asia/Bangkok", offset: 420, offsetLabel: "ICT (GMT+7)" },
            { name: "Jakarta", zone: "Asia/Jakarta", offset: 420, offsetLabel: "WIB (GMT+7)" },
            { name: "Auckland", zone: "Pacific/Auckland", offset: 720, offsetLabel: "NZST (GMT+12)" },
            { name: "Reykjavik", zone: "Atlantic/Reykjavik", offset: 0, offsetLabel: "GMT (GMT+0)" },
            { name: "Honolulu", zone: "Pacific/Honolulu", offset: -600, offsetLabel: "HST (GMT-10)" },
            { name: "Anchorage", zone: "America/Anchorage", offset: -480, offsetLabel: "AKDT (GMT-8)" }
        ];
        for (var i = 0; i < base.length; i++) {
            base[i].origIndex = i;
        }
        return base;
    }

    property int clock1Index: 0 // Default: New Delhi
    property int clock2Index: 3 // Default: New York
    property int clock3Index: 4 // Default: London

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
                    text: "\uf0ac"
                    font.family: root.iconFontFamily
                    font.pixelSize: 11
                    color: root.theme.primary
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
                iconFontFamily: root.iconFontFamily
                onSelectionChanged: (idx) => root.clock1Index = idx
            }

            ClockItem {
                Layout.fillWidth: true
                theme: root.theme
                currentDate: root.currentDate
                tzList: root.tzData
                selectedIndex: root.clock2Index
                iconFontFamily: root.iconFontFamily
                onSelectionChanged: (idx) => root.clock2Index = idx
            }

            ClockItem {
                Layout.fillWidth: true
                theme: root.theme
                currentDate: root.currentDate
                tzList: root.tzData
                selectedIndex: root.clock3Index
                iconFontFamily: root.iconFontFamily
                onSelectionChanged: (idx) => root.clock3Index = idx
            }
        }
    }
}
