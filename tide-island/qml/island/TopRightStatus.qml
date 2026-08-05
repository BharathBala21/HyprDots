import QtQuick
import Quickshell
import Quickshell.Io
import IslandBackend
import "../common"

Item {
    id: root

    property var cavaLevels: [0, 0, 0, 0, 0, 0, 0, 0]
    property int batteryCapacity: 100
    property bool isCharging: false
    property bool musicPlaying: false
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property real currentVolume: 0

    FileView {
        id: statusCfgWatcher
        path: (Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")) + "/.config/tide-island/userconfig.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: statusCfgWatcher.reload()
    }

    readonly property var statusCfgData: {
        try {
            return statusCfgWatcher.text() ? JSON.parse(statusCfgWatcher.text()) : {};
        } catch (e) {
            return {};
        }
    }

    readonly property bool showBatteryPercentage: statusCfgData.showBatteryPercentage !== undefined ? statusCfgData.showBatteryPercentage : true
    readonly property bool showBattery: statusCfgData.showTopRightBattery !== undefined ? statusCfgData.showTopRightBattery : (statusCfgData.showTopRightPill !== undefined ? statusCfgData.showTopRightPill : true)

    opacity: root.showBattery ? 1.0 : 0.0
    visible: opacity > 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing.type: Easing.InOutQuad
        }
    }

    implicitWidth: root.showBattery ? (batteryRow.implicitWidth + 24) : 0
    implicitHeight: 32
    width: implicitWidth
    height: implicitHeight

    Behavior on width {
        NumberAnimation { duration: 380; easing.type: Easing.OutQuint }
    }

    MouseArea {
        id: scrollArea
        anchors.fill: parent
        enabled: root.musicPlaying && root.showBattery
        acceptedButtons: Qt.NoButton

        onWheel: (wheel) => {
            if (root.currentVolume < 0)
                return;
            const step = 0.02;
            const nextVal = root.currentVolume + (wheel.angleDelta.y > 0 ? step : -step);
            SystemServices.setVolume(Math.max(0.0, Math.min(1.0, nextVal)));
            wheel.accepted = true;
        }
    }

    readonly property string styleChoice: statusCfgData.topRightPillStyle || statusCfgData.islandStyle || "pill"
    readonly property bool isNotchStyle: styleChoice === "notch"

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: StyleTokens.black
        radius: height / 2
        border.width: 1
        border.color: StyleTokens.overviewInnerBorder
    }

    // Top Notch Extension (Square top corners attached flush to top screen edge in Notch mode)
    Rectangle {
        visible: root.isNotchStyle
        anchors.top: bgRect.top
        anchors.left: bgRect.left
        anchors.right: bgRect.right
        height: Math.min(16, bgRect.height / 2)
        color: bgRect.color
        z: -1

        Behavior on height {
            NumberAnimation { duration: 380; easing.type: Easing.OutQuint }
        }
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 0

        Row {
            id: batteryRow
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showBattery

            Text {
                text: "\uf0e7" // chargingIconGlyph
                font.family: root.iconFontFamily
                font.pixelSize: 14
                color: "white"
                visible: root.isCharging
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.batteryCapacity + "%"
                font.family: root.textFontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showBatteryPercentage
            }

            Item {
                width: 28
                height: 14
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    anchors.rightMargin: 3
                    radius: 4
                    color: StyleTokens.transparent
                    border.color: "#8e8e93"
                    border.width: 1

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        radius: 2
                        width: Math.max(0, (parent.width - 4) * (Math.max(0, Math.min(100, root.batteryCapacity)) / 100.0))
                        color: {
                            if (root.isCharging) return "#34c759";
                            if (root.batteryCapacity < 10) return "#ff3b30";
                            if (root.batteryCapacity < 20) return "#ffcc00";
                            return "#34c759";
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Rectangle {
                    width: 3
                    height: 6
                    radius: 1
                    color: "#8e8e93"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
