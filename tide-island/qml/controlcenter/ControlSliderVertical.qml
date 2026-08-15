import QtQuick
import IslandBackend

Rectangle {
    id: root

    signal interactionStarted()
    signal valueMoved(real value)
    signal commitRequested()
    signal cancelRequested()

    property string iconText: ""
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property real value: 0
    property color trackColor: "#2c2c2e"
    property color fillColor: "#ffffff"
    property color activeIconColor: "#121418"
    property color inactiveIconColor: "#8e8e93"
    readonly property bool pressed: sliderArea.pressed

    function clamp01(nextValue) {
        return Math.max(0, Math.min(1, nextValue));
    }

    radius: 18
    color: "#1c1c1e"
    clip: true

    Behavior on color { ColorAnimation { duration: 150 } }

    // Capsule Slider Track
    Rectangle {
        id: sliderTrack
        anchors.fill: parent
        radius: parent.radius
        color: root.trackColor
        clip: true

        // Vertical fill from bottom up
        Item {
            id: fillContainer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * root.clamp01(root.value)
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: sliderTrack.height
                radius: sliderTrack.radius
                color: root.fillColor
            }
        }

        // Icon anchored near bottom
        Item {
            id: iconBox
            width: parent.width
            height: 32
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter

            // Inactive icon (underneath fill)
            Text {
                anchors.centerIn: parent
                text: root.iconText
                color: root.inactiveIconColor
                font.pixelSize: 18
                font.family: root.iconFontFamily
            }

            // Active icon (clipped to fill area for smart seamless contrast)
            Item {
                anchors.fill: parent
                clip: true
                // Map the icon position relative to fillContainer
                y: 0
                visible: root.value > 0.15

                Text {
                    anchors.centerIn: parent
                    text: root.iconText
                    color: root.activeIconColor
                    font.pixelSize: 18
                    font.family: root.iconFontFamily
                }
            }
        }

        // Interactive mouse & scroll area
        MouseArea {
            id: sliderArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function update(mouseY) {
                if (height <= 0) return;
                const ratio = 1.0 - (mouseY / height);
                root.valueMoved(root.clamp01(ratio));
            }

            onPressed: function(mouse) {
                root.interactionStarted();
                update(mouse.y);
            }

            onPositionChanged: function(mouse) {
                if (pressed) update(mouse.y);
            }

            onReleased: root.commitRequested()
            onCanceled: root.cancelRequested()

            onWheel: function(wheel) {
                root.interactionStarted();
                const delta = (wheel.angleDelta.y > 0 ? 0.05 : -0.05);
                root.valueMoved(root.clamp01(root.value + delta));
                root.commitRequested();
            }
        }
    }
}
