import QtQuick
import IslandBackend

Rectangle {
    id: button

    property string icon: ""
    property string label: ""
    property bool isSelected: false
    property bool isCancel: false

    signal clicked()

    Colors {
        id: mColors
    }

    implicitWidth: buttonRow.width + 24
    implicitHeight: 44
    radius: 22

    // Background color:
    // If selected, the sliding highlight handles it (so return transparent)
    // If hovered: StyleTokens.moduleHover or transparent red
    color: {
        if (isSelected) {
            return "transparent";
        }
        if (mouseArea.containsMouse) {
            return isCancel ? Qt.rgba(mColors.error.r, mColors.error.g, mColors.error.b, 0.2) : StyleTokens.moduleHover;
        }
        return "transparent";
    }

    border.width: 1
    border.color: (!isSelected && mouseArea.containsMouse) ? Qt.rgba(mColors.primary.r, mColors.primary.g, mColors.primary.b, 0.25) : "transparent"

    scale: mouseArea.pressed ? 0.95 : 1.0

    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    Behavior on scale {
        NumberAnimation { duration: 100 }
    }

    Row {
        id: buttonRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: button.icon
            font.family: UserConfig.iconFontFamily
            font.pixelSize: 18
            color: {
                if (isSelected) {
                    return isCancel ? mColors.on_error : mColors.on_primary;
                }
                return isCancel ? mColors.error : StyleTokens.textPrimary;
            }
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        Text {
            text: button.label
            font.family: UserConfig.textFontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: {
                if (isSelected) {
                    return isCancel ? mColors.on_error : mColors.on_primary;
                }
                return StyleTokens.textPrimary;
            }
            anchors.verticalCenter: parent.verticalCenter

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
        onClicked: button.clicked()
    }
}
