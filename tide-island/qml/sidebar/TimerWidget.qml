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
    radius: 12 
    
    color: root.theme.surface_container
    border.width: 0

    // Extra layering for thickness and opacity
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(0, 0, 0, 0.45) // Deep contrast layer
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(1.0, 1.0, 1.0, 0.05) // Frosted shine layer
    }


    property bool isMuted: false
    property bool isAlarmRinging: false
    property bool isFloating: false
    property bool isDragging: false
    signal dragMoved(real dx, real dy)

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

    Process {
        id: killSoundHelper
        command: ["sh", "-c", "killall paplay pw-play 2>/dev/null || true"]
        running: false
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
                root.isAlarmRinging = true
                notifyProcess.running = true
                if (!root.isMuted) {
                    soundProcess.running = true
                }
            }
        }
    }

    function setMode(mode) {
        root.timerState = "stopped"
        root.isAlarmRinging = false
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
                implicitWidth: 125
                implicitHeight: 28
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
                    height: 28
                    contentItem: Text {
                        text: modelData.text
                        color: itemDel.highlighted ? root.theme.primary : root.theme.on_surface
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                    }
                    background: Rectangle {
                        color: itemDel.hovered || itemDel.highlighted ? Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.15) : "transparent"
                        radius: 6
                    }
                }

                contentItem: Text {
                    text: modeCombo.currentText
                    font.family: root.textFontFamily
                    font.pixelSize: 12
                    color: root.theme.on_surface
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                    rightPadding: 20
                }

                background: Rectangle {
                    color: Qt.rgba(root.theme.surface_container.r, root.theme.surface_container.g, root.theme.surface_container.b, 0.5)
                    border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.2)
                    border.width: 1
                    radius: 6
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
                        radius: 6
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
                        focus: root.activeMode === "custom" && root.timerState === "stopped"
                        
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab || event.key === Qt.Key_Colon) {
                                secsInput.forceActiveFocus()
                                secsInput.selectAll()
                                event.accepted = true
                            }
                        }
                        
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
                        
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                                minsInput.forceActiveFocus()
                                minsInput.selectAll()
                                event.accepted = true
                            }
                        }
                        
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
                        color: playPauseBtn.pressed ? Qt.darker(root.theme.primary, 1.2) : (playPauseBtn.hovered ? Qt.lighter(root.theme.primary, 1.1) : root.theme.primary)
                        radius: 6 
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
                        border.color: root.theme.outline
                        border.width: 1
                        radius: 6
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
                        killSoundHelper.running = true
                        root.setMode(root.activeMode)
                    }
                }
            }
        }
    }

    // Alarm Ringing Overlay
    Rectangle {
        id: alarmOverlay
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(0.08, 0.08, 0.08, 0.95)
        visible: root.isAlarmRinging

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            // Pulsing Alarm Icon
            Text {
                id: alarmIcon
                Layout.alignment: Qt.AlignHCenter
                text: "\uf0f3" // Bell icon
                font.family: root.iconFontFamily
                font.pixelSize: 28
                color: root.theme.primary

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.isAlarmRinging
                    NumberAnimation { from: 1.0; to: 0.3; duration: 500; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.3; to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Timer Finished!")
                font.family: root.textFontFamily
                font.pixelSize: 14
                font.weight: Font.Bold
                color: root.theme.on_surface
            }

            Button {
                id: dismissBtn
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 120
                implicitHeight: 32

                background: Rectangle {
                    color: dismissBtn.pressed ? Qt.darker(root.theme.primary, 1.2) : (dismissBtn.hovered ? Qt.lighter(root.theme.primary, 1.1) : root.theme.primary)
                    radius: 6
                }

                contentItem: Text {
                    text: qsTr("Dismiss")
                    font.family: root.textFontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: root.theme.on_primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    root.isAlarmRinging = false
                    soundProcess.running = false
                    killSoundHelper.running = true
                    root.setMode(root.activeMode)
                }
            }
        }
    }
}