import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: 88
    implicitHeight: 140

    property QtObject theme
    property date currentDate
    property var tzList
    property int selectedIndex
    property string iconFontFamily: ""

    signal selectionChanged(int idx)

    readonly property var tzDetails: {
        if (!tzList || selectedIndex < 0 || selectedIndex >= tzList.length) {
            return { hours: 0, minutes: 0, seconds: 0, timeString: "00:00" }
        }
        
        var targetTz = tzList[selectedIndex];
        var offsetMinutes = targetTz.offset; 
        
        var localTime = currentDate.getTime();
        var localOffsetMs = currentDate.getTimezoneOffset() * 60000;
        var utcMs = localTime + localOffsetMs;
        var targetDate = new Date(utcMs + (offsetMinutes * 60000));
        
        var h = targetDate.getHours();
        var m = targetDate.getMinutes();
        var s = targetDate.getSeconds();
        
        var hStr = h < 10 ? "0" + h : h
        var mStr = m < 10 ? "0" + m : m
        
        return {
            hours: h,
            minutes: m,
            seconds: s,
            timeString: hStr + ":" + mStr
        }
    }

    readonly property real hourAngle: ((tzDetails.hours % 12) * 30) + (tzDetails.minutes * 0.5)
    readonly property real minuteAngle: (tzDetails.minutes * 6) + (tzDetails.seconds * 0.1)
    readonly property real secondAngle: tzDetails.seconds * 6

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Button {
            id: citySelectorBtn
            Layout.fillWidth: true
            implicitHeight: 24

            background: Rectangle {
                color: citySelectorBtn.hovered ? Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.1) : "transparent"
                radius: 6
            }

            contentItem: Item {
                Text {
                    anchors.left: parent.left
                    anchors.right: indicatorIcon.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.tzList && root.tzList[root.selectedIndex] ? root.tzList[root.selectedIndex].name : ""
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: root.theme.on_surface
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                Canvas {
                    id: indicatorIcon
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 6
                    contextType: "2d"
                    opacity: 0.5

                    onPaint: {
                        var context = getContext("2d");
                        context.reset();
                        context.moveTo(0, 0);
                        context.lineTo(width, 0);
                        context.lineTo(width / 2, height);
                        context.closePath();
                        context.fillStyle = root.theme.on_surface;
                        context.fill();
                    }
                }
            }

            onClicked: comboPopup.open()

            Popup {
                id: comboPopup
                y: citySelectorBtn.height + 4
                x: -(width - citySelectorBtn.width) / 2
                width: 160
                implicitHeight: Math.min(220, popupLayout.implicitHeight + 12)
                padding: 6
                focus: true 
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                background: Rectangle {
                    color: root.theme.surface_container
                    border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.3)
                    border.width: 1
                    radius: 8
                }

                onOpened: {
                    searchField.text = "";
                    searchField.forceActiveFocus();
                }

                ColumnLayout {
                    id: popupLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 6

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        implicitHeight: 28
                        placeholderText: qsTr("Search...")
                        font.pixelSize: 11
                        color: root.theme.on_surface
                        placeholderTextColor: root.theme.on_surface_variant
                        focus: true
                        
                        background: Rectangle {
                            color: Qt.rgba(root.theme.surface.r, root.theme.surface.g, root.theme.surface.b, 0.8)
                            border.color: searchField.activeFocus ? root.theme.primary : Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.2)
                            border.width: 1
                            radius: 6
                        }
                        
                        Keys.onEscapePressed: comboPopup.close()
                        
                        // Down arrow moves focus to the list
                        Keys.onDownPressed: {
                            if (comboList.count > 0) {
                                comboList.currentIndex = 0;
                                comboList.forceActiveFocus();
                            }
                        }
                    }

                    ListView {
                        id: comboList
                        Layout.fillWidth: true
                        implicitHeight: Math.min(160, comboList.contentHeight)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        spacing: 2
                        focus: true
                        
                        model: {
                            var txt = searchField.text.trim().toLowerCase();
                            if (!root.tzList) return [];
                            if (txt === "") return root.tzList;
                            var res = [];
                            for (var i = 0; i < root.tzList.length; i++) {
                                var item = root.tzList[i];
                                if (item && item.name && item.name.toLowerCase().indexOf(txt) !== -1) {
                                    res.push(item);
                                }
                            }
                            return res;
                        }

                        // Up arrow on first item moves focus back to search field
                        Keys.onUpPressed: {
                            if (currentIndex === 0) {
                                searchField.forceActiveFocus();
                            } else {
                                decrementCurrentIndex();
                            }
                        }
                        
                        // Enter/Return key selects the current item
                        Keys.onReturnPressed: {
                            if (currentIndex >= 0 && currentIndex < count) {
                                var currentData = model[currentIndex];
                                if (currentData) {
                                    root.selectionChanged(currentData.origIndex);
                                    comboPopup.close();
                                }
                            }
                        }

                        delegate: ItemDelegate {
                            id: itemDel
                            width: comboList.width
                            height: 26
                            padding: 0
                            
                            contentItem: Text {
                                text: modelData.name 
                                color: (itemDel.hovered || itemDel.ListView.isCurrentItem) ? root.theme.primary : root.theme.on_surface
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 6
                            }
                            
                            background: Rectangle {
                                color: (itemDel.hovered || itemDel.ListView.isCurrentItem) ? Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.15) : "transparent"
                                radius: 4
                            }
                            
                            onClicked: {
                                root.selectionChanged(modelData.origIndex);
                                comboPopup.close();
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 64
            height: 64
            Layout.topMargin: 4

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#0A0A0A" 
                border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.4)
                border.width: 1.5

                Repeater {
                    model: 4
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 3
                        width: 1.5
                        height: 5
                        color: Qt.rgba(1, 1, 1, 0.4)
                        transform: Rotation {
                            origin.x: 0.75
                            origin.y: 29
                            angle: index * 90
                        }
                    }
                }

                Rectangle {
                    x: 31
                    y: 16
                    width: 2.5
                    height: 16
                    color: "#FFFFFF"
                    antialiasing: true
                    radius: 1.25
                    transform: Rotation {
                        origin.x: 1.25
                        origin.y: 16
                        angle: root.hourAngle
                    }
                }

                Rectangle {
                    x: 31.25
                    y: 8
                    width: 1.5
                    height: 24
                    color: "#FFFFFF"
                    antialiasing: true
                    radius: 0.75
                    transform: Rotation {
                        origin.x: 0.75
                        origin.y: 24
                        angle: root.minuteAngle
                    }
                }

                Rectangle {
                    x: 31.5
                    y: 6
                    width: 1
                    height: 26
                    color: root.theme.primary
                    antialiasing: true
                    transform: Rotation {
                        origin.x: 0.5
                        origin.y: 26
                        angle: root.secondAngle
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: 4
                    radius: 2
                    color: root.theme.primary
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            text: root.tzDetails.timeString
            color: root.theme.on_surface
            font.pixelSize: 16
            font.weight: Font.Bold
            font.family: "monospace"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: root.tzList[root.selectedIndex].offsetLabel
            color: root.theme.on_surface_variant
            font.pixelSize: 10
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}