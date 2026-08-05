import QtQuick
import IslandBackend

Rectangle {
    id: root

    signal interactionStarted()
    signal valueMoved(real value)
    signal commitRequested()
    signal cancelRequested()

    property string title: ""
    property string iconText: ""
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property real value: 0
    property real knobSize: 24
    property color moduleColor: "#1c1c1e"
    property color moduleHover: "#242426"
    property color trackColor: "#2c2c2e"
    property color textPrimary: "#ffffff"
    property color textSecondary: "#8e8e93"
    property color activeColor: "#ffffff"
    property color activeHover: "#ffffff"
    readonly property bool pressed: sliderArea.pressed

    function clamp01(nextValue) {
        return Math.max(0, Math.min(1, nextValue));
    }

    radius: 20
    color: "#1c1c1e"
    clip: true

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        // Label
        Text {
            text: root.title
            color: "#ffffff"
            font.pixelSize: 13
            font.family: root.textFontFamily
            font.weight: Font.DemiBold
        }

        // Capsule Slider Track
        Rectangle {
            id: sliderTrack
            width: parent.width
            height: Math.max(22, parent.height - 24)
            radius: height / 2
            color: "#2c2c2e"
            clip: true

            Item {
                width: parent.width * root.value
                height: parent.height
                clip: true

                Rectangle {
                    width: sliderTrack.width
                    height: sliderTrack.height
                    radius: sliderTrack.radius
                    color: "#ffffff"
                }
            }

            MouseArea {
                id: sliderArea
                anchors.fill: parent
                hoverEnabled: true

                function update(mouseX) {
                    if (width <= 0) return;
                    root.valueMoved(root.clamp01(mouseX / width));
                }

                onPressed: function(mouse) {
                    root.interactionStarted();
                    update(mouse.x);
                }
                onPositionChanged: function(mouse) {
                    if (pressed) update(mouse.x);
                }
                onReleased: root.commitRequested()
                onCanceled: root.cancelRequested()
            }
        }
    }
}
