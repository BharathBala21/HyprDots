import QtQuick
import Quickshell
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
    property real minimumWidth: 392
    property real maximumWidth: 420
    property real horizontalPadding: 16
    property real spacing: 10
    property int textPixelSize: 16
    property int selectedIdx: 0

    focus: true

    Keys.onLeftPressed: (event) => {
        selectedIdx = (selectedIdx - 1 + powerModel.count) % powerModel.count;
        event.accepted = true;
    }
    Keys.onRightPressed: (event) => {
        selectedIdx = (selectedIdx + 1) % powerModel.count;
        event.accepted = true;
    }
    Keys.onEscapePressed: (event) => {
        root.closeRequested();
        event.accepted = true;
    }
    Keys.onReturnPressed: (event) => {
        root.triggerAction(selectedIdx);
        event.accepted = true;
    }
    Keys.onEnterPressed: (event) => {
        root.triggerAction(selectedIdx);
        event.accepted = true;
    }
    Keys.onSpacePressed: (event) => {
        root.triggerAction(selectedIdx);
        event.accepted = true;
    }

    function triggerAction(index) {
        const item = powerModel.get(index);
        if (!item) return;

        console.log("Triggered power action: " + item.action);
        root.closeRequested();

        const home = Quickshell.env("HOME") || "";

        if (item.action === "lock") {
            Quickshell.execDetached([home + "/.local/src/HyprDots/tide-island/lockscreen/lock.sh"]);
        } else if (item.action === "logout") {
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
        } else if (item.action === "suspend") {
            Quickshell.execDetached(["systemctl", "suspend"]);
        } else if (item.action === "reboot") {
            Quickshell.execDetached(["systemctl", "reboot"]);
        } else if (item.action === "shutdown") {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        }
    }

    readonly property var themeColors: shellRootController ? shellRootController.matugenThemeColors : null
    readonly property color activeColor: themeColors ? themeColors.primary : (StyleTokens.accent || "#e2c46d")
    readonly property color inactiveColor: themeColors ? themeColors.secondary_container : "#222222"
    readonly property color activeTextColor: themeColors ? themeColors.on_primary : "#000000"
    readonly property color inactiveTextColor: themeColors ? themeColors.on_secondary_container : "#ffffff"
    readonly property color inactiveLabelColor: themeColors ? themeColors.on_surface_variant : "#a0a0a0"

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
        id: powerModel
        ListElement { action: "lock"; icon: "\uf023"; label: "Lock" }
        ListElement { action: "logout"; icon: "\uf08b"; label: "Logout" }
        ListElement { action: "suspend"; icon: "\uf186"; label: "Suspend" }
        ListElement { action: "reboot"; icon: "\uf01e"; label: "Reboot" }
        ListElement { action: "shutdown"; icon: "\uf011"; label: "Shutdown" }
    }

    // The Clock (Visible in normal/resting state, slides out to the right)
    Text {
        id: timeLabel
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

    // The Power squircle cards (Slides in from the left)
    Row {
        id: contentRow
        x: itemsX
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacing
        opacity: clampedProgress

        Repeater {
            model: powerModel

            delegate: Rectangle {
                id: buttonRect

                required property string action
                required property string icon
                required property int index
                required property string label

                readonly property bool isActive: (root.selectedIdx === index) || mouseArea.containsMouse

                width: 64
                height: 64
                radius: 16
                color: isActive ? root.activeColor : root.inactiveColor
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
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: buttonRect.icon
                        font.family: root.iconFontFamily
                        font.pixelSize: 18
                        color: isActive ? root.activeTextColor : root.inactiveTextColor

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: buttonRect.label
                        font.family: root.textFontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: isActive ? root.activeTextColor : root.inactiveLabelColor

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
                        root.triggerAction(index);
                    }
                }
            }
        }
    }
}
