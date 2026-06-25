import QtQuick
import IslandBackend

Item {
    id: root

    signal closeRequested()
    property var shellRootController: null
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property string timeFontFamily: ""
    property string timeText: ""
    property bool showCondition: false
    property bool showSecondaryText: true
    property real transitionProgress: 0
    property real minimumWidth: 614
    property real maximumWidth: 640
    property real horizontalPadding: 16
    property real spacing: 10
    property int textPixelSize: 16
    property int selectedIdx: 0

    focus: true

    Keys.onLeftPressed: (event) => {
        selectedIdx = (selectedIdx - 1 + utilitiesModel.count) % utilitiesModel.count;
        event.accepted = true;
    }
    Keys.onRightPressed: (event) => {
        selectedIdx = (selectedIdx + 1) % utilitiesModel.count;
        event.accepted = true;
    }
    Keys.onEscapePressed: (event) => {
        root.closeRequested();
        event.accepted = true;
    }
    Keys.onReturnPressed: (event) => {
        root.triggerUtility(selectedIdx);
        event.accepted = true;
    }
    Keys.onEnterPressed: (event) => {
        root.triggerUtility(selectedIdx);
        event.accepted = true;
    }
    Keys.onSpacePressed: (event) => {
        root.triggerUtility(selectedIdx);
        event.accepted = true;
    }

    function triggerUtility(index) {
        const item = utilitiesModel.get(index);
        if (item) {
            console.log("Triggered utility: " + item.name);
        }
    }

    readonly property var themeColors: shellRootController ? shellRootController.matugenThemeColors : null
    readonly property color activeColor: themeColors ? themeColors.primary : (StyleTokens.accent || "#00f0c2")

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
        ListElement { name: "screenshot"; icon: "\uf030"; label: "Screenshot" }
        ListElement { name: "wallpaper"; icon: "\uf03e"; label: "Wallpaper" }
        ListElement { name: "screenrecord"; icon: "\uf03d"; label: "Record" }
        ListElement { name: "colorpicker"; icon: "\uf1fb"; label: "Picker" }
        ListElement { name: "ocr"; icon: "T"; label: "OCR" }
        ListElement { name: "search"; icon: "\uf1a0"; label: "Search" }
        ListElement { name: "qr"; icon: "\uf029"; label: "Scan" }
        ListElement { name: "mirror"; icon: ""; label: "Mirror" }
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

    // The Utilities squircle cards (Slides in from the left)
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
                required property int index
                required property string label

                readonly property bool isActive: (root.selectedIdx === index) || mouseArea.containsMouse

                width: 64
                height: 64
                radius: 16
                color: isActive ? root.activeColor : "#222222"
                border.width: 1
                border.color: isActive ? "#55ffffff" : "transparent"

                scale: mouseArea.pressed ? 0.92 : (isActive ? 1.08 : 1.0)

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
                        id: iconText
                        visible: buttonRect.name !== "mirror"
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: buttonRect.icon
                        font.family: buttonRect.name === "ocr" ? root.textFontFamily : root.iconFontFamily
                        font.pixelSize: 18
                        font.weight: buttonRect.name === "ocr" ? Font.Medium : Font.Normal
                        color: isActive ? "#000000" : "#ffffff"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    Item {
                        id: webcamIcon
                        visible: buttonRect.name === "mirror"
                        width: 18
                        height: 18
                        anchors.horizontalCenter: parent.horizontalCenter

                        property color iconColor: isActive ? "#000000" : "#ffffff"

                        Behavior on iconColor {
                            ColorAnimation { duration: 150 }
                        }

                        // Outer ring of the webcam body
                        Rectangle {
                            id: outerRing
                            width: 12
                            height: 12
                            radius: 6
                            color: "transparent"
                            border.color: webcamIcon.iconColor
                            border.width: 1.5
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 1

                            // Inner ring / lens aperture
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: "transparent"
                                border.color: webcamIcon.iconColor
                                border.width: 1
                                anchors.centerIn: parent

                                // Center lens dot
                                Rectangle {
                                    width: 2
                                    height: 2
                                    radius: 1
                                    color: webcamIcon.iconColor
                                    anchors.centerIn: parent
                                }
                            }
                        }

                        // Stand leg (stem)
                        Rectangle {
                            id: stem
                            width: 1.5
                            height: 3
                            color: webcamIcon.iconColor
                            anchors.top: outerRing.bottom
                            anchors.topMargin: -0.5
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        // Stand base
                        Rectangle {
                            width: 12
                            height: 1.5
                            radius: 0.75
                            color: webcamIcon.iconColor
                            anchors.top: stem.bottom
                            anchors.topMargin: -0.5
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: buttonRect.label
                        font.family: root.textFontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: isActive ? "#000000" : "#a0a0a0"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    onEntered: {
                        root.selectedIdx = index;
                    }

                    onClicked: {
                        root.triggerUtility(index);
                    }
                }
            }
        }
    }
}
