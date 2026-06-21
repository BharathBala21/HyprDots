import QtQuick
import IslandBackend

Rectangle {
    id: button

    property string icon: ""
    property string label: ""
    property bool isSelected: false
    property bool isCancel: false

    signal clicked()

    implicitWidth: buttonRow.width + 24
    implicitHeight: 44
    radius: 22

    // Background color:
    // If selected: StyleTokens.accent (or StyleTokens.error for cancel)
    // If hovered: StyleTokens.moduleHover (or a soft red for cancel)
    // Otherwise: transparent
    color: {
        if (isSelected) {
            return isCancel ? StyleTokens.error : StyleTokens.accent;
        }
        if (mouseArea.containsMouse) {
            return isCancel ? Qt.rgba(StyleTokens.error.r, StyleTokens.error.g, StyleTokens.error.b, 0.2) : StyleTokens.moduleHover;
        }
        return "transparent";
    }

    border.width: isSelected ? 0 : 1
    border.color: mouseArea.containsMouse ? "#40ffffff" : "transparent"

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
                    return "#ffffff";
                }
                return isCancel ? StyleTokens.error : StyleTokens.textPrimary;
            }
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: button.label
            font.family: UserConfig.textFontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: {
                if (isSelected) {
                    return "#ffffff";
                }
                return StyleTokens.textPrimary;
            }
            anchors.verticalCenter: parent.verticalCenter
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
