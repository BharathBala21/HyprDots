import QtQuick
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

    implicitWidth: contentRow.width + 24
    implicitHeight: 32
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        color: StyleTokens.black
        radius: height / 2
        border.width: 1
        border.color: StyleTokens.overviewInnerBorder
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 12

        SwipeCavaBars {
            id: visualizer
            levels: root.cavaLevels
            anchors.verticalCenter: parent.verticalCenter
            visible: opacity > 0
            opacity: root.musicPlaying ? 1 : 0

            width: root.musicPlaying ? implicitWidth : 0
            Behavior on width {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // Separator between visualizer and battery (visible only when music playing)
        Rectangle {
            width: 1
            height: 14
            color: "#44ffffff"
            anchors.verticalCenter: parent.verticalCenter
            visible: visualizer.width > 0 && visualizer.opacity > 0.1

            // Smooth transition matching visualizer width behavior
            opacity: root.musicPlaying ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }

        Row {
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter

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
                            if (root.batteryCapacity <= 10) return "#ff3b30";
                            if (root.batteryCapacity <= 20) return "#ffcc00";
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
