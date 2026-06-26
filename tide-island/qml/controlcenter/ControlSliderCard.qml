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
    property color moduleColor: StyleTokens.module
    property color moduleHover: StyleTokens.moduleHover
    property color trackColor: StyleTokens.track
    property color textPrimary: StyleTokens.textPrimary
    property color textSecondary: StyleTokens.textSecondary
    readonly property bool pressed: sliderArea.pressed

    function clamp01(nextValue) {
        return Math.max(0, Math.min(1, nextValue));
    }

    radius: height / 2
    color: root.trackColor
    clip: true

    // Fill Rectangle
    Rectangle {
        id: fillRect
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * root.value
        radius: parent.radius
        color: sliderArea.containsMouse ? "#45e0af" : "#3bc99d" // Sleek bright cyan/teal

        Behavior on color {
            ColorAnimation { duration: 100 }
        }
    }

    // Icon Text
    Text {
        id: iconTextItem
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: root.iconText
        color: (parent.width * root.value > 45) ? "#121418" : "#ffffff"
        font.pixelSize: 15
        font.family: root.iconFontFamily

        Behavior on color {
            ColorAnimation { duration: 100 }
        }
    }

    MouseArea {
        id: sliderArea
        anchors.fill: parent
        hoverEnabled: true

        function update(mouseX) {
            root.valueMoved(root.clamp01(mouseX / width));
        }

        onPressed: function(mouse) {
            root.interactionStarted();
            update(mouse.x);
        }
        onPositionChanged: function(mouse) {
            if (pressed)
                update(mouse.x);
        }
        onReleased: root.commitRequested()
        onCanceled: root.cancelRequested()
    }
}
