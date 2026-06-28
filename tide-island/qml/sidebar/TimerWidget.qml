import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Shapes

Rectangle {
    id: root
    implicitWidth: 300
    implicitHeight: 200
    radius: 12 
    
    color: root.theme.surface
    border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.3)
    border.width: 1

    property QtObject theme
    property string iconFontFamily: ""

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
            }
        }
    }

    function setMode(mode) {
        root.timerState = "stopped"
        activeMode = mode
        if (mode === "pomodoro") totalSeconds = 25 * 60
        else if (mode === "shortBreak") totalSeconds = 5 * 60
        else if (mode === "longBreak") totalSeconds = 15 * 60
        else totalSeconds = (parseInt(minsInput.text) || 10) * 60 + (parseInt(secsInput.text) || 0)
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
                    font.pixelSize: 11
                    color: root.theme.on_surface
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 6
                }

                background: Rectangle {
                    color: Qt.rgba(root.theme.surface_container.r, root.theme.surface_container.g, root.theme.surface_container.b, 0.5)
                    border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.2)
                    border.width: 1
                    radius: 6
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
                        color: playPauseBtn.pressed ? Qt.darker(root.theme.primary, 1.2) : (playPauseBtn.hovered ? Qt.lighter(root.theme.primary, 1.1) : root.theme.primary)
                        radius: 6 
                    }
                    
                    contentItem: Text {
                        text: root.isRunning ? qsTr("Pause") : (root.isPaused ? qsTr("Resume") : qsTr("Start"))
                        color: root.theme.on_primary
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
                                root.totalSeconds = (parseInt(minsInput.text) || 10) * 60 + (parseInt(secsInput.text) || 0)
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
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        root.setMode(root.activeMode)
                    }
                }
            }
        }
    }
}