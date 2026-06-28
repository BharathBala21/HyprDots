import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Shapes

Rectangle {
    id: root
    implicitWidth: 300
    implicitHeight: 200
    radius: 16
    
    // Solid macOS-style widget surface background
    color: root.theme.surface
    border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.15)
    border.width: 1

    property QtObject theme

    // Timer variables
    property int totalSeconds: 600
    property int remainingSeconds: 600
    property bool isRunning: countdownTimer.running
    property string activeMode: "standard"

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
        running: false
        onTriggered: {
            if (remainingSeconds > 0) {
                remainingSeconds--
            } else {
                countdownTimer.stop()
            }
        }
    }

    function setMode(mode) {
        countdownTimer.stop()
        activeMode = mode
        if (mode === "pomodoro") {
            totalSeconds = 25 * 60
        } else if (mode === "shortBreak") {
            totalSeconds = 5 * 60
        } else if (mode === "longBreak") {
            totalSeconds = 15 * 60
        } else {
            totalSeconds = (parseInt(minsInput.text) || 10) * 60 + (parseInt(secsInput.text) || 0)
        }
        remainingSeconds = totalSeconds
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true

            RowLayout {
                spacing: 8
                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.15)
                    
                    Text {
                        anchors.centerIn: parent
                        text: "⏳"
                        font.pixelSize: 11
                    }
                }

                Text {
                    text: qsTr("Timer")
                    color: root.theme.on_surface
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }

            ComboBox {
                id: modeCombo
                implicitWidth: 110
                implicitHeight: 24
                model: [
                    { text: qsTr("Standard"), value: "standard" },
                    { text: qsTr("Pomodoro"), value: "pomodoro" },
                    { text: qsTr("Short Break"), value: "shortBreak" },
                    { text: qsTr("Long Break"), value: "longBreak" }
                ]
                textRole: "text"

                delegate: ItemDelegate {
                    width: modeCombo.width
                    height: 24
                    contentItem: Text {
                        text: modelData.text
                        color: highlighted ? root.theme.primary : root.theme.on_surface
                        font.pixelSize: 11
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: hovered ? Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.1) : "transparent"
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
            spacing: 16

            // Ring progress
            Item {
                width: 90
                height: 90
                Layout.alignment: Qt.AlignVCenter

                Shape {
                    anchors.fill: parent
                    ShapePath {
                        strokeColor: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.15)
                        strokeWidth: 4
                        fillColor: "transparent"
                        PathAngleArc {
                            centerX: 45; centerY: 45
                            radiusX: 38; radiusY: 38
                            startAngle: -90
                            sweepAngle: 360
                        }
                    }
                }

                Shape {
                    anchors.fill: parent
                    ShapePath {
                        strokeColor: root.theme.primary
                        strokeWidth: 4
                        capStyle: ShapePath.RoundCap
                        fillColor: "transparent"
                        PathAngleArc {
                            centerX: 45; centerY: 45
                            radiusX: 38; radiusY: 38
                            startAngle: -90
                            sweepAngle: 360 * (1.0 - root.progress)
                        }
                    }
                }

                Text {
                    id: timeText
                    anchors.centerIn: parent
                    text: root.timeString
                    color: root.theme.on_surface
                    font.pixelSize: 16
                    font.family: "monospace"
                    font.weight: Font.DemiBold
                    visible: root.activeMode !== "standard" || root.isRunning
                }

                RowLayout {
                    anchors.centerIn: parent
                    visible: root.activeMode === "standard" && !root.isRunning
                    spacing: 1

                    TextInput {
                        id: minsInput
                        text: "10"
                        font.pixelSize: 16
                        font.family: "monospace"
                        font.weight: Font.DemiBold
                        color: root.theme.primary
                        maximumLength: 2
                        validator: IntValidator { bottom: 0; top: 99 }
                        onTextChanged: {
                            if (root.activeMode === "standard" && !root.isRunning) {
                                root.totalSeconds = (parseInt(text) || 0) * 60 + (parseInt(secsInput.text) || 0)
                                root.remainingSeconds = root.totalSeconds
                            }
                        }
                    }
                    Text {
                        text: ":"
                        font.pixelSize: 16
                        color: root.theme.on_surface_variant
                    }
                    TextInput {
                        id: secsInput
                        text: "00"
                        font.pixelSize: 16
                        font.family: "monospace"
                        font.weight: Font.DemiBold
                        color: root.theme.primary
                        maximumLength: 2
                        validator: IntValidator { bottom: 0; top: 59 }
                        onTextChanged: {
                            if (root.activeMode === "standard" && !root.isRunning) {
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
                spacing: 8

                Button {
                    id: playPauseBtn
                    implicitWidth: 90
                    implicitHeight: 28
                    
                    background: Rectangle {
                        color: playPauseBtn.pressed ? Qt.darker(root.theme.primary, 1.1) : (playPauseBtn.hovered ? Qt.lighter(root.theme.primary, 1.05) : root.theme.primary)
                        radius: 14
                    }
                    
                    contentItem: Text {
                        text: root.isRunning ? qsTr("Pause") : qsTr("Start")
                        color: root.theme.on_primary
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (root.isRunning) {
                            countdownTimer.stop()
                        } else {
                            if (root.activeMode === "standard") {
                                root.totalSeconds = (parseInt(minsInput.text) || 10) * 60 + (parseInt(secsInput.text) || 0)
                                if (root.remainingSeconds <= 0 || root.remainingSeconds > root.totalSeconds) {
                                    root.remainingSeconds = root.totalSeconds
                                }
                            }
                            countdownTimer.start()
                        }
                    }
                }

                Button {
                    id: resetBtn
                    implicitWidth: 90
                    implicitHeight: 28
                    
                    background: Rectangle {
                        color: resetBtn.pressed ? Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.25) : (resetBtn.hovered ? Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.15) : Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.08))
                        border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.2)
                        radius: 14
                    }

                    contentItem: Text {
                        text: qsTr("Reset")
                        color: root.theme.on_surface
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        countdownTimer.stop()
                        root.setMode(root.activeMode)
                    }
                }
            }
        }
    }
}
