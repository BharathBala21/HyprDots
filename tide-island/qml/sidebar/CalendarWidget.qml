import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root
    implicitWidth: 300
    implicitHeight: 230
    radius: 16
    
    // Solid macOS-style widget background
    color: root.theme.surface
    border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.15)
    border.width: 1

    property QtObject theme

    // Calendar state
    property int currentMonth: new Date().getMonth()
    property int currentYear: new Date().getFullYear()
    property var gridDays: []

    readonly property var monthNames: [
        qsTr("January"), qsTr("February"), qsTr("March"), qsTr("April"),
        qsTr("May"), qsTr("June"), qsTr("July"), qsTr("August"),
        qsTr("September"), qsTr("October"), qsTr("November"), qsTr("December")
    ]

    Component.onCompleted: updateCalendar()

    onCurrentMonthChanged: updateCalendar()
    onCurrentYearChanged: updateCalendar()

    function updateCalendar() {
        var days = []
        var prevMonth = currentMonth === 0 ? 11 : currentMonth - 1
        var prevYear = currentMonth === 0 ? currentYear - 1 : currentYear
        var daysInPrevMonth = new Date(prevYear, prevMonth + 1, 0).getDate()
        
        var daysInCurrentMonth = new Date(currentYear, currentMonth + 1, 0).getDate()
        var startDay = new Date(currentYear, currentMonth, 1).getDay()
        
        // Prev month days
        for (var i = startDay - 1; i >= 0; i--) {
            days.push({
                day: daysInPrevMonth - i,
                isCurrentMonth: false,
                isToday: false
            })
        }
        
        // Current month days
        var today = new Date()
        for (var d = 1; d <= daysInCurrentMonth; d++) {
            var isToday = (d === today.getDate() && 
                           currentMonth === today.getMonth() && 
                           currentYear === today.getFullYear())
            days.push({
                day: d,
                isCurrentMonth: true,
                isToday: isToday
            })
        }
        
        // Next month days
        var remaining = 42 - days.length
        for (var n = 1; n <= remaining; n++) {
            days.push({
                day: n,
                isCurrentMonth: false,
                isToday: false
            })
        }
        
        gridDays = days
    }

    function prevMonth() {
        if (currentMonth === 0) {
            currentMonth = 11
            currentYear--
        } else {
            currentMonth--
        }
    }

    function nextMonth() {
        if (currentMonth === 11) {
            currentMonth = 0
            currentYear++
        } else {
            currentMonth++
        }
    }

    function goToday() {
        var today = new Date()
        currentMonth = today.getMonth()
        currentYear = today.getFullYear()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                spacing: 6
                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.15)
                    
                    Text {
                        anchors.centerIn: parent
                        text: "📅"
                        font.pixelSize: 11
                    }
                }

                Text {
                    text: root.monthNames[root.currentMonth] + " " + root.currentYear
                    color: root.theme.on_surface
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }

            // Navigation
            RowLayout {
                spacing: 2

                Button {
                    id: prevBtn
                    implicitWidth: 22
                    implicitHeight: 22
                    background: Rectangle {
                        color: prevBtn.pressed ? Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.25) : "transparent"
                        radius: 5
                    }
                    contentItem: Text {
                        text: "<"
                        color: root.theme.on_surface
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.prevMonth()
                }

                Button {
                    id: todayBtn
                    implicitWidth: 42
                    implicitHeight: 22
                    background: Rectangle {
                        color: todayBtn.pressed ? Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.25) : Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.08)
                        border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.15)
                        radius: 5
                    }
                    contentItem: Text {
                        text: qsTr("Today")
                        color: root.theme.on_surface
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.goToday()
                }

                Button {
                    id: nextBtn
                    implicitWidth: 22
                    implicitHeight: 22
                    background: Rectangle {
                        color: nextBtn.pressed ? Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.25) : "transparent"
                        radius: 5
                    }
                    contentItem: Text {
                        text: ">"
                        color: root.theme.on_surface
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.nextMonth()
                }
            }
        }

        // Calendar Grid
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            // Weekday labels
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: [qsTr("S"), qsTr("M"), qsTr("T"), qsTr("W"), qsTr("T"), qsTr("F"), qsTr("S")]
                    delegate: Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: index === 0 || index === 6 ? root.theme.primary : root.theme.on_surface_variant
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.1)
            }

            // Days grid
            Grid {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                spacing: 0

                readonly property real cellWidth: width / 7
                readonly property real cellHeight: height / 6

                Repeater {
                    model: root.gridDays
                    delegate: Item {
                        width: parent.cellWidth
                        height: parent.cellHeight

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) - 4
                            height: width
                            radius: width / 2
                            
                            // Highlight today with solid primary color (macOS style)
                            color: modelData.isToday ? root.theme.primary : "transparent"
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                font.pixelSize: 10
                                font.weight: modelData.isToday ? Font.Bold : Font.Normal
                                color: {
                                    if (modelData.isToday)
                                        return root.theme.on_primary
                                    if (modelData.isCurrentMonth)
                                        return root.theme.on_surface
                                    return root.theme.on_surface_variant
                                }
                                opacity: modelData.isCurrentMonth ? 1.0 : 0.35
                            }
                        }
                    }
                }
            }
        }
    }
}
