import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    implicitWidth: 300
    implicitHeight: 200
    radius: 20
    clip: true

    color: Qt.rgba(root.theme.surface_container.r, root.theme.surface_container.g, root.theme.surface_container.b, 0.86)
    border.width: 0

    // ---------------------------------------------------------------
    // macOS / iOS style frosted-glass material
    // ---------------------------------------------------------------

    // Depth layer - keeps content legible over any wallpaper behind it
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(0, 0, 0, 0.30)
    }

    // Sheen layer - soft vertical light falloff, brightest near the top.
    // This is the core "thick glass material" look.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        gradient: Gradient {
            GradientStop { position: 0.0;  color: Qt.rgba(1.0, 1.0, 1.0, 0.12) }
            GradientStop { position: 0.45; color: Qt.rgba(1.0, 1.0, 1.0, 0.03) }
            GradientStop { position: 1.0;  color: Qt.rgba(1.0, 1.0, 1.0, 0.0)  }
        }
    }

    // Hairline inner edge - gives the glass a crisp, cut boundary
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(parent.radius - 1, 0)
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.09)
    }

    // Shiny silver edge - top. Light sweeps in from the left and peaks
    // brightest as it reaches the top-right corner.
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        height: 1.6
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(0.85, 0.87, 0.90, 0.10) }
            GradientStop { position: 0.6; color: Qt.rgba(0.88, 0.90, 0.93, 0.45) }
            GradientStop { position: 1.0; color: Qt.rgba(0.95, 0.97, 1.00, 0.90) }
        }
    }

    // Shiny silver edge - right. Continues the same highlight downward
    // from the corner, fading out toward the bottom.
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 10
        anchors.bottomMargin: 12
        anchors.rightMargin: 1
        width: 1.6
        radius: width / 2
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(0.95, 0.97, 1.00, 0.90) }
            GradientStop { position: 0.4; color: Qt.rgba(0.88, 0.90, 0.93, 0.40) }
            GradientStop { position: 1.0; color: Qt.rgba(0.85, 0.87, 0.90, 0.08) }
        }
    }

    property QtObject theme
    property string iconFontFamily: ""
    property string textFontFamily: ""

    property int totalSeconds: 600
    property int remainingSeconds: 600
    
    // Proper state management: "stopped", "running", "paused"
    property string timerState: "stopped"
    readonly property bool isRunning: timerState === "running"
    readonly property bool isPaused: timerState === "paused"
    
    property string activeMode: "custom"

    readonly property real progress: totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0.0
    readonly property string timeString: {
        var mins = Math.floor(remainingSeconds / 60)
        var secs = remainingSeconds % 60
        return (mins < 10 ? "0" + mins : mins) + ":" + (secs < 10 ? "0" + secs : secs)
    }

    Process {
        id: notifyProcess
        command: ["notify-send", "Timer Completed!", "Your countdown has ended."]
    }

    Process {
        id: soundProcess
        command: ["sh", "-c", "for i in {1..5}; do paplay /usr/share/sounds/ocean/stereo/alarm-clock-elapsed.oga || pw-play /usr/share/sounds/ocean/stereo/alarm-clock-elapsed.oga; done"]
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: root.isRunning
        onTriggered: {
            if (remainingSeconds > 0) {
                remainingSeconds--
            } else {
                root.timerState = "stopped"
                notifyProcess.running = true
                soundProcess.running = true
            }
        }
    }

    function setMode(mode) {
        root.timerState = "stopped"
        activeMode = mode
        if (mode === "pomodoro") totalSeconds = 25 * 60
        else if (mode === "shortBreak") totalSeconds = 5 * 60
        else if (mode === "longBreak") totalSeconds = 15 * 60
        else {
            var mins = parseInt(minsInput.text)
            var secs = parseInt(secsInput.text)
            totalSeconds = (isNaN(mins) ? 10 : mins) * 60 + (isNaN(secs) ? 0 : secs)
        }
        remainingSeconds = totalSeconds
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true
            RowLayout {
                spacing: 10
                Text {
                    text: "\uf252"
                    font.family: root.iconFontFamily
                    font.pixelSize: 14
                    color: root.theme.primary
                }
                Text {
                    text: qsTr("Timer")
                    color: root.theme.on_surface
                    font.family: root.textFontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
            }
            
            Item { Layout.fillWidth: true }
            
            ComboBox {
                id: modeCombo
                implicitWidth: 110
                implicitHeight: 24
                model: [
                    { text: qsTr("Custom"), value: "custom" },
                    { text: qsTr("Pomodoro"), value: "pomodoro" },
                    { text: qsTr("Short Break"), value: "shortBreak" },
                    { text: qsTr("Long Break"), value: "longBreak" }
                ]
                textRole: "text"

                delegate: ItemDelegate {
                    id: itemDel
                    width: modeCombo.width
                    height: 24
                    contentItem: Text {
                        text: modelData.text
                        color: itemDel.highlighted ? root.theme.primary : root.theme.on_surface
                        font.family: root.textFontFamily
                        font.pixelSize: 11
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 6
                    }
                    background: Rectangle {
                        color: itemDel.hovered || itemDel.highlighted ? Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.15) : "transparent"
                        radius: 6
                    }
                }

                contentItem: Text {
                    text: modeCombo.currentText
                    font.family: root.textFontFamily
                    font.pixelSize: 11
                    color: root.theme.on_surface
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 6
                    rightPadding: 20
                }

                background: Rectangle {
                    radius: 10
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(root.theme.surface_container.r + 0.04, root.theme.surface_container.g + 0.04, root.theme.surface_container.b + 0.04, 0.55) }
                        GradientStop { position: 1.0; color: Qt.rgba(root.theme.surface_container.r, root.theme.surface_container.g, root.theme.surface_container.b, 0.45) }
                    }
                    border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.25)
                    border.width: 1
                }

                indicator: Text {
                    x: modeCombo.width - width - 8
                    y: (modeCombo.height - height) / 2
                    text: "\uf078"
                    font.family: root.iconFontFamily
                    font.pixelSize: 8
                    color: root.theme.on_surface
                    opacity: 0.5
                }

                popup: Popup {
                    y: modeCombo.height + 2
                    width: modeCombo.width
                    implicitHeight: contentItem.implicitHeight + 4
                    padding: 2

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: modeCombo.popup.visible ? modeCombo.delegateModel : null
                        currentIndex: modeCombo.highlightedIndex
                    }

                    background: Rectangle {
                        color: root.theme.surface
                        border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.3)
                        border.width: 1
                        radius: 10
                    }
                }

                onActivated: (index) => {
                    var selectedMode = model[index].value
                    root.setMode(selectedMode)
                }
            }
        }

        // Body
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 24

            // Ring progress
            Item {
                width: 100
                height: 100
                Layout.alignment: Qt.AlignVCenter

                Shape {
                    anchors.fill: parent
                    ShapePath {
                        strokeColor: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.2)
                        strokeWidth: 6
                        fillColor: "transparent"
                        PathAngleArc { centerX: 50; centerY: 50; radiusX: 44; radiusY: 44; startAngle: -90; sweepAngle: 360 }
                    }
                }

                Shape {
                    anchors.fill: parent
                    opacity: root.isPaused ? 0.4 : 1.0 // Dim when paused
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

                    ShapePath {
                        strokeColor: root.theme.primary
                        strokeWidth: 6
                        capStyle: ShapePath.RoundCap
                        fillColor: "transparent"
                        PathAngleArc { centerX: 50; centerY: 50; radiusX: 44; radiusY: 44; startAngle: -90; sweepAngle: 360 * (1.0 - root.progress) }
                    }
                }

                Text {
                    id: timeText
                    anchors.centerIn: parent
                    text: root.timeString
                    color: root.theme.on_surface
                    font.pixelSize: 20
                    font.family: "monospace"
                    font.weight: Font.Bold
                    // Hide only if stopped AND in custom mode
                    visible: root.activeMode !== "custom" || root.timerState !== "stopped"
                    opacity: root.isPaused ? 0.5 : 1.0 // Dim text when paused
                    
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                }

                RowLayout {
                    anchors.centerIn: parent
                    // Show inputs only when stopped in custom mode
                    visible: root.activeMode === "custom" && root.timerState === "stopped"
                    spacing: 1

                    TextInput {
                        id: minsInput
                        text: "10"
                        font.pixelSize: 20
                        font.family: "monospace"
                        font.weight: Font.Bold
                        color: root.theme.primary
                        maximumLength: 2
                        validator: IntValidator { bottom: 0; top: 99 }
                        onTextChanged: {
                            if (root.activeMode === "custom" && root.timerState === "stopped") {
                                root.totalSeconds = (parseInt(text) || 0) * 60 + (parseInt(secsInput.text) || 0)
                                root.remainingSeconds = root.totalSeconds
                            }
                        }
                    }
                    Text {
                        text: ":"
                        font.pixelSize: 20
                        font.family: "monospace"
                        font.weight: Font.Bold
                        color: root.theme.on_surface_variant
                    }
                    TextInput {
                        id: secsInput
                        text: "00"
                        font.pixelSize: 20
                        font.family: "monospace"
                        font.weight: Font.Bold
                        color: root.theme.primary
                        maximumLength: 2
                        validator: IntValidator { bottom: 0; top: 59 }
                        onTextChanged: {
                            if (root.activeMode === "custom" && root.timerState === "stopped") {
                                root.totalSeconds = (parseInt(minsInput.text) || 0) * 60 + (parseInt(text) || 0)
                                root.remainingSeconds = root.totalSeconds
                            }
                        }
                    }
                }
            }

            // Controls
            ColumnLayout {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 10

                Button {
                    id: playPauseBtn
                    Layout.fillWidth: true
                    implicitWidth: 90
                    implicitHeight: 32
                    
                    background: Rectangle {
                        radius: 10
                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: playPauseBtn.pressed
                                    ? Qt.darker(root.theme.primary, 1.15)
                                    : (playPauseBtn.hovered ? Qt.lighter(root.theme.primary, 1.18) : Qt.lighter(root.theme.primary, 1.06))
                            }
                            GradientStop {
                                position: 1.0
                                color: playPauseBtn.pressed
                                    ? Qt.darker(root.theme.primary, 1.3)
                                    : (playPauseBtn.hovered ? Qt.lighter(root.theme.primary, 1.02) : Qt.darker(root.theme.primary, 1.05))
                            }
                        }
                        border.width: 1
                        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.18)
                    }
                    
                    contentItem: Text {
                        text: root.isRunning ? qsTr("Pause") : (root.isPaused ? qsTr("Resume") : qsTr("Start"))
                        color: root.theme.on_primary
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (root.timerState === "running") {
                            root.timerState = "paused"
                        } else {
                            if (root.timerState === "stopped" && root.activeMode === "custom") {
                                var mins = parseInt(minsInput.text)
                                var secs = parseInt(secsInput.text)
                                root.totalSeconds = (isNaN(mins) ? 10 : mins) * 60 + (isNaN(secs) ? 0 : secs)
                                root.remainingSeconds = root.totalSeconds
                            }
                            root.timerState = "running"
                        }
                    }
                }

                Button {
                    id: resetBtn
                    Layout.fillWidth: true
                    implicitWidth: 90
                    implicitHeight: 32
                    
                    background: Rectangle {
                        color: resetBtn.pressed ? Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.3) : (resetBtn.hovered ? Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.15) : "transparent")
                        border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.5)
                        border.width: 1
                        radius: 10
                    }
                    contentItem: Text {
                        text: qsTr("Reset")
                        color: root.theme.on_surface
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        soundProcess.running = false
                        root.setMode(root.activeMode)
                    }
                }
            }
        }
    }
}
