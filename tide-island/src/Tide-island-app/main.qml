import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window
    visible: true
    width: 400
    height: 300
    title: "Tide Island Config"

    Rectangle {
        anchors.centerIn: parent
        width: 200
        height: 80
        radius: 20
        color: "#2c2c2c"
        border.color: "#555555"

        Text {
            anchors.centerIn: parent
            text: "Hello, Tide Island!"
            color: "#ffffff"
            font.pixelSize: 18
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: console.log("Window clicked!")
    }
}
