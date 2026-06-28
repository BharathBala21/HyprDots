import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Shapes

Rectangle {
    id: root
    implicitWidth: 300
    implicitHeight: 230
    radius: 16
    
    color: Qt.rgba(root.theme.surface_container.r, root.theme.surface_container.g, root.theme.surface_container.b, 0.92)
    border.width: 0

    // Extra layering for thickness and opacity
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(1.0, 1.0, 1.0, 0.04)
    }



    property QtObject theme
    property string iconFontFamily: ""
    property string textFontFamily: ""

    // Calendar state
    property int currentMonth: new Date().getMonth()
    property int currentYear: new Date().getFullYear()
    property var gridDays: []

    // View Mode: "days", "months", "years"
    property string viewMode: "days"
    
    // Year range offset page (for 12-year grid navigation)
    property int startYearOfPage: currentYear - 5

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

    function prev() {
        if (viewMode === "days") {
            if (currentMonth === 0) {
                currentMonth = 11
                currentYear--
            } else {
                currentMonth--
            }
        } else if (viewMode === "months") {
            currentYear--
        } else if (viewMode === "years") {
            startYearOfPage -= 12
        }
    }

    function next() {
        if (viewMode === "days") {
            if (currentMonth === 11) {
                currentMonth = 0
                currentYear++
            } else {
                currentMonth++
            }
        } else if (viewMode === "months") {
            currentYear++
        } else if (viewMode === "years") {
            startYearOfPage += 12
        }
    }

    function goToday() {
        var today = new Date()
        currentMonth = today.getMonth()
        currentYear = today.getFullYear()
        startYearOfPage = currentYear - 5
        viewMode = "days"
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
                        text: "\uf073"
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                        color: root.theme.primary
                    }
                }

                // Clickable Header Month/Year Selector
                RowLayout {
                    spacing: 2

                    Button {
                        id: headerMonthBtn
                        implicitWidth: contentItem.implicitWidth + 8
                        implicitHeight: 24
                        background: Rectangle {
                            color: headerMonthBtn.hovered ? Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.1) : "transparent"
                            radius: 4
                        }
                        contentItem: Text {
                            text: root.monthNames[root.currentMonth]
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: root.viewMode === "months" ? root.theme.primary : root.theme.on_surface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if (root.viewMode === "months") {
                                root.viewMode = "days"
                            } else {
                                root.viewMode = "months"
                            }
                        }
                    }

                    Button {
                        id: headerYearBtn
                        implicitWidth: contentItem.implicitWidth + 8
                        implicitHeight: 24
                        background: Rectangle {
                            color: headerYearBtn.hovered ? Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.1) : "transparent"
                            radius: 4
                        }
                        contentItem: Text {
                            text: root.currentYear
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: root.viewMode === "years" ? root.theme.primary : root.theme.on_surface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if (root.viewMode === "years") {
                                root.viewMode = "days"
                            } else {
                                root.startYearOfPage = root.currentYear - 5
                                root.viewMode = "years"
                            }
                        }
                    }
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
                        text: "\uf053"
                        font.family: root.iconFontFamily
                        font.pixelSize: 8
                        color: prevBtn.hovered ? root.theme.primary : root.theme.on_surface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.prev()
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
                        text: "\uf054"
                        font.family: root.iconFontFamily
                        font.pixelSize: 8
                        color: nextBtn.hovered ? root.theme.primary : root.theme.on_surface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.next()
                }
            }
        }

        // Main View Content Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 1. DAYS VIEW
            ColumnLayout {
                id: daysView
                anchors.fill: parent
                visible: root.viewMode === "days"
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
                            font.family: root.textFontFamily
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
                                color: modelData.isToday ? root.theme.primary : "transparent"
                                
                                 Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    font.family: root.textFontFamily
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

            // 2. MONTHS VIEW (4x3 Grid)
            Grid {
                id: monthsView
                anchors.fill: parent
                visible: root.viewMode === "months"
                columns: 4
                rows: 3
                spacing: 6

                readonly property real cellWidth: (width - (spacing * 3)) / 4
                readonly property real cellHeight: (height - (spacing * 2)) / 3

                Repeater {
                    model: [
                        qsTr("Jan"), qsTr("Feb"), qsTr("Mar"), qsTr("Apr"),
                        qsTr("May"), qsTr("Jun"), qsTr("Jul"), qsTr("Aug"),
                        qsTr("Sep"), qsTr("Oct"), qsTr("Nov"), qsTr("Dec")
                    ]
                    delegate: Button {
                        id: mBtn
                        width: monthsView.cellWidth
                        height: monthsView.cellHeight

                        background: Rectangle {
                            color: root.currentMonth === index ? root.theme.primary : (mBtn.hovered ? Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.15) : Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.05))
                            radius: 8
                            border.color: root.currentMonth === index ? "transparent" : Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.15)
                            border.width: 1
                        }

                        contentItem: Text {
                            text: modelData
                            font.pixelSize: 11
                            font.weight: root.currentMonth === index ? Font.Bold : Font.Normal
                            color: root.currentMonth === index ? root.theme.on_primary : root.theme.on_surface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            root.currentMonth = index
                            root.viewMode = "days"
                        }
                    }
                }
            }

            // 3. YEARS VIEW (4x3 Grid)
            Grid {
                id: yearsView
                anchors.fill: parent
                visible: root.viewMode === "years"
                columns: 4
                rows: 3
                spacing: 6

                readonly property real cellWidth: (width - (spacing * 3)) / 4
                readonly property real cellHeight: (height - (spacing * 2)) / 3

                Repeater {
                    model: 12
                    delegate: Button {
                        id: yBtn
                        width: yearsView.cellWidth
                        height: yearsView.cellHeight

                        readonly property int yearValue: root.startYearOfPage + index

                        background: Rectangle {
                            color: root.currentYear === yBtn.yearValue ? root.theme.primary : (yBtn.hovered ? Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.15) : Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.05))
                            radius: 8
                            border.color: root.currentYear === yBtn.yearValue ? "transparent" : Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.15)
                            border.width: 1
                        }

                        contentItem: Text {
                            text: yBtn.yearValue
                            font.pixelSize: 11
                            font.weight: root.currentYear === yBtn.yearValue ? Font.Bold : Font.Normal
                            color: root.currentYear === yBtn.yearValue ? root.theme.on_primary : root.theme.on_surface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            root.currentYear = yBtn.yearValue
                            root.viewMode = "days"
                        }
                    }
                }
            }
        }
    }
}
