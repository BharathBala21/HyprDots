import QtQuick

Item {
    id: root

    property string iconFontFamily: ""
    property string textFontFamily: ""
    property string timeFontFamily: ""
    property string timeText: ""
    property bool showCondition: false
    property bool showSecondaryText: true
    property real transitionProgress: 0
    property real minimumWidth: 470
    property real maximumWidth: 490
    property real horizontalPadding: 16
    property real spacing: 10
    property int textPixelSize: 16

    readonly property real clampedProgress: Math.max(0, Math.min(1, transitionProgress))
    readonly property real preferredWidth: minimumWidth

    // Calculation for sliding items in from the left
    readonly property real centeredItemsX: (width - contentRow.implicitWidth) / 2
    readonly property real itemsHiddenLeftX: -contentRow.implicitWidth - 18
    readonly property real itemsEntryDistance: Math.max(0, centeredItemsX - itemsHiddenLeftX)
    readonly property real itemsX: centeredItemsX - (1 - clampedProgress) * itemsEntryDistance

    // Calculation for sliding clock out to the right
    readonly property real textWidth: Math.max(0, width - horizontalPadding * 2)
    readonly property real centeredTimeX: horizontalPadding
    readonly property real timeHiddenRightX: width + 18
    readonly property real timeExitDistance: Math.max(0, timeHiddenRightX - centeredTimeX)
    readonly property real dragDistance: Math.max(itemsEntryDistance, timeExitDistance)
    readonly property real timeX: centeredTimeX + clampedProgress * dragDistance

    anchors.fill: parent
    clip: true
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 220 : 140
            easing.type: Easing.InOutQuad
        }
    }

    ListModel {
        id: utilitiesModel
        ListElement { name: "screenshot"; icon: "\uf030"; label: "Screen" }
        ListElement { name: "wallpaper"; icon: "\uf03e"; label: "Wall" }
        ListElement { name: "screenrecord"; icon: "\uf03d"; label: "Record" }
        ListElement { name: "colorpicker"; icon: "\uf1fb"; label: "Picker" }
        ListElement { name: "ocr"; icon: "\uf031"; label: "OCR" }
        ListElement { name: "search"; icon: "\uf1a0"; label: "Search" }
        ListElement { name: "qr"; icon: "\uf029"; label: "Scan" }
    }

    // The Clock (Visible in normal/resting state, slides out to the right)
    Text {
        visible: timeText !== "" && showSecondaryText
        x: timeX
        width: textWidth
        anchors.verticalCenter: parent.verticalCenter
        text: timeText
        color: "white"
        opacity: 1 - clampedProgress
        font.pixelSize: textPixelSize + 1
        font.family: timeFontFamily || textFontFamily
        font.weight: Font.Bold
        font.letterSpacing: -0.25
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
    }

    // The Utilities Cards (Slides in from the left)
    Row {
        id: contentRow
        x: itemsX
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacing
        opacity: clampedProgress

        Repeater {
            model: utilitiesModel

            delegate: Rectangle {
                id: buttonRect

                required property string name
                required property string icon
                required property string label

                width: 54
                height: 54
                radius: 14
                color: mouseArea.containsMouse ? (StyleTokens.accent || "#00f0c2") : "#222222"
                border.width: 1
                border.color: mouseArea.containsMouse ? "#55ffffff" : "transparent"

                scale: mouseArea.pressed ? 0.92 : (mouseArea.containsMouse ? 1.08 : 1.0)

                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutBack }
                }
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: buttonRect.icon
                        font.family: root.iconFontFamily
                        font.pixelSize: 18
                        color: mouseArea.containsMouse ? "#000000" : "#ffffff"

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: buttonRect.label
                        font.family: root.textFontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: mouseArea.containsMouse ? "#000000" : "#a0a0a0"

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    onClicked: {
                        console.log("Clicked utility: " + buttonRect.name);
                        // Functionalities will be added later as requested
                    }
                }
            }
        }
    }
}
