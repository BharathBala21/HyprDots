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

    signal selectionChanged(int idx)

    // Calculate time details in the timezone
    readonly property var tzDetails: {
        if (!tzList || selectedIndex < 0 || selectedIndex >= tzList.length) {
            return { hours: 0, minutes: 0, seconds: 0, timeString: "00:00" }
        }
        
        var zone = tzList[selectedIndex].zone
        try {
            var options = {
                timeZone: zone,
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: false
            }
            var localeStr = currentDate.toLocaleString("en-US", options)
            var match = localeStr.match(/(\d+):(\d+):(\d+)/)
            if (match) {
                var h = parseInt(match[1])
                var m = parseInt(match[2])
                var s = parseInt(match[3])
                
                var hStr = h < 10 ? "0" + h : h
                var mStr = m < 10 ? "0" + m : m
                
                return {
                    hours: h,
                    minutes: m,
                    seconds: s,
                    timeString: hStr + ":" + mStr
                }
            }
        } catch(e) {
            console.log("Error formatting timezone:", e)
        }
        
        var lh = currentDate.getHours()
        var lm = currentDate.getMinutes()
        var ls = currentDate.getSeconds()
        return {
            hours: lh,
            minutes: lm,
            seconds: ls,
            timeString: (lh < 10 ? "0" + lh : lh) + ":" + (lm < 10 ? "0" + lm : lm)
        }
    }

    // Hands angle calculation
    readonly property real hourAngle: ((tzDetails.hours % 12) * 30) + (tzDetails.minutes * 0.5)
    readonly property real minuteAngle: (tzDetails.minutes * 6) + (tzDetails.seconds * 0.1)
    readonly property real secondAngle: tzDetails.seconds * 6

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        // City dropdown
        ComboBox {
            id: cityCombo
            Layout.fillWidth: true
            implicitHeight: 20
            currentIndex: root.selectedIndex
            model: root.tzList
            textRole: "name"

            delegate: ItemDelegate {
                id: itemDel
                width: cityCombo.width
                height: 22
                contentItem: Text {
                    text: modelData.name
                    color: itemDel.highlighted ? root.theme.primary : root.theme.on_surface
                    font.pixelSize: 10
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 6
                }
                background: Rectangle {
                    color: itemDel.hovered || itemDel.highlighted ? Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.15) : "transparent"
                    radius: 4
                }
            }

            contentItem: Text {
                text: cityCombo.currentText
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: root.theme.on_surface
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                color: "transparent"
            }

            indicator: Canvas {
                id: canvas
                x: cityCombo.width - width - 2
                y: cityCombo.height / 2 - height / 2
                width: 6
                height: 4
                contextType: "2d"
                opacity: 0.4

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

            popup: Popup {
                y: cityCombo.height + 2
                width: cityCombo.width
                implicitHeight: contentItem.implicitHeight + 4
                padding: 2

                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: cityCombo.popup.visible ? cityCombo.delegateModel : null
                    currentIndex: cityCombo.highlightedIndex
                }

                background: Rectangle {
                    color: root.theme.surface
                    border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.3)
                    border.width: 1
                    radius: 8
                }
            }

            onActivated: (index) => {
                root.selectionChanged(index)
            }
        }

        // macOS Clock Face (Opaque black face, white hands, primary accent second hand)
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 58
            height: 58

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#121212" // Solid dark clock face (macOS style)
                border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.3)
                border.width: 1.5

                // Tick marks (subtle 12, 3, 6, 9 markers)
                Repeater {
                    model: 4
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 2
                        width: 1.5
                        height: 4
                        color: Qt.rgba(1, 1, 1, 0.3)
                        transform: Rotation {
                            origin.x: 0.75
                            origin.y: 27
                            angle: index * 90
                        }
                    }
                }

                // Hour Hand (white, clean, solid)
                Rectangle {
                    x: 28
                    y: 15
                    width: 2.2
                    height: 14
                    color: "#FFFFFF"
                    antialiasing: true
                    radius: 1
                    transform: Rotation {
                        origin.x: 1.1
                        origin.y: 14
                        angle: root.hourAngle
                    }
                }

                // Minute Hand (white, thin)
                Rectangle {
                    x: 28.25
                    y: 9
                    width: 1.5
                    height: 20
                    color: "#FFFFFF"
                    antialiasing: true
                    radius: 0.8
                    transform: Rotation {
                        origin.x: 0.75
                        origin.y: 20
                        angle: root.minuteAngle
                    }
                }

                // Second Hand (primary color accent)
                Rectangle {
                    x: 28.5
                    y: 7
                    width: 1
                    height: 22
                    color: root.theme.primary
                    antialiasing: true
                    transform: Rotation {
                        origin.x: 0.5
                        origin.y: 22
                        angle: root.secondAngle
                    }
                }

                // Center Pin
                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: 4
                    radius: 2
                    color: root.theme.primary
                }
            }
        }

        // Digital Time
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.tzDetails.timeString
            color: root.theme.on_surface
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.family: "monospace"
        }

        // Timezone Offset details
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: root.tzList[root.selectedIndex].offsetLabel
            color: root.theme.on_surface_variant
            font.pixelSize: 8
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
