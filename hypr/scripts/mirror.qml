import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtCore

ApplicationWindow {
    id: root
    width: 960
    height: 540
    visible: true
    title: "Mirror & Camera Recorder"

    // Default theme structure (will be overwritten dynamically by theme.json if present)
    property var theme: {
        "background": "#16130b",
        "primary": "#e2c46d",
        "surface": "#231f17",
        "on_surface": "#eae1d4",
        "outline": "#4c4639",
        "error": "#ffb4ab",
        "text_font": "Inter Display",
        "icon_font": "JetBrainsMono Nerd Font"
    }

    // Load dynamic system palette on creation
    Component.onCompleted: {
        try {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "theme.json", false);
            xhr.send(null);
            if (xhr.status === 200) {
                var customTheme = JSON.parse(xhr.responseText);
                for (var key in customTheme) {
                    theme[key] = customTheme[key];
                }
            }
        } catch (e) {
            console.log("Using fallback theme: " + e);
        }
        // Set default font family
        font.family = theme.text_font;
    }

    // Background color matching tide-island
    background: Rectangle {
        color: root.theme.background
    }

    // State properties
    property bool recording: recorder.recorderState === MediaRecorder.RecordingState
    property bool paused: recorder.recorderState === MediaRecorder.PausedState
    property bool mirrorEnabled: true
    property bool settingsVisible: false

    MediaDevices {
        id: mediaDevices
    }

    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            active: true
            cameraDevice: mediaDevices.defaultVideoInput
        }
        audioInput: AudioInput {
            id: audioInput
            muted: !micSwitch.checked
        }
        recorder: MediaRecorder {
            id: recorder
            // MPEG4 + H264 + AAC configuration ensures reliable recording on standard FFmpeg setups
            mediaFormat {
                fileFormat: MediaFormat.MPEG4
                videoCodec: MediaFormat.VideoCodec.H264
                audioCodec: MediaFormat.AudioCodec.AAC
            }
            onRecorderStateChanged: {
                if (recorder.recorderState === MediaRecorder.StoppedState) {
                    var path = recorder.actualLocation.toString();
                    if (path.indexOf("file://") === 0) {
                        path = path.substring(7);
                    }
                    console.log("NOTIFICATION: Recording Saved | Video saved to: " + path);
                } else if (recorder.recorderState === MediaRecorder.RecordingState) {
                    console.log("NOTIFICATION: Recording Started | Video recording has begun.");
                }
            }
            onErrorOccurred: (error, errorString) => {
                console.log("RECORDER ERROR: " + error + " - " + errorString);
            }
        }
        videoOutput: videoOutput
    }

    Item {
        id: mainContainer
        anchors.fill: parent

        // Video feed (positioned behind floating bars)
        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop

            transform: Scale {
                xScale: root.mirrorEnabled ? -1 : 1
                origin.x: videoOutput.width / 2
            }
        }

        // Overlay UI elements (siblings of VideoOutput so they are not mirrored)
        Item {
            id: overlay
            anchors.fill: parent

            // 1. Floating Top Status Bar (Matching tide-island style)
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                height: 54
                radius: 12
                color: "#e6" + root.theme.surface.substring(1) // 90% opacity surface
                border.color: root.theme.outline
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 12

                    Text {
                        text: "Mirror & Camera Recorder"
                        color: root.theme.on_surface
                        font.family: root.theme.text_font
                        font.pointSize: 12
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    // Recording indicator dot
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: root.recording ? root.theme.error : "#10b981"
                        
                        SequentialAnimation on opacity {
                            running: root.recording
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                        }
                    }

                    Text {
                        text: root.recording ? "Recording" : "Ready"
                        color: root.recording ? root.theme.error : "#10b981"
                        font.family: root.theme.text_font
                        font.pointSize: 9
                        font.bold: true
                    }
                }
            }

            // 2. Floating Settings Panel
            Rectangle {
                id: settingsPanel
                width: 320
                height: 200
                radius: 12
                color: "#f2" + root.theme.surface.substring(1) // 95% opacity
                border.color: root.theme.primary
                border.width: 1
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.bottom: bottomBar.top
                anchors.bottomMargin: 15
                visible: root.settingsVisible
                z: 10

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 12

                    Text {
                        text: "Settings"
                        color: root.theme.on_surface
                        font.family: root.theme.text_font
                        font.pointSize: 10
                        font.bold: true
                    }

                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: "Camera Source:"
                            color: root.theme.outline
                            font.family: root.theme.text_font
                            font.pointSize: 8
                        }
                        ComboBox {
                            id: cameraSelect
                            Layout.fillWidth: true
                            model: mediaDevices.videoInputs
                            textRole: "description"
                            
                            background: Rectangle {
                                color: "#33" + root.theme.on_surface.substring(1)
                                border.color: root.theme.outline
                                border.width: 1
                                radius: 6
                            }
                            
                            contentItem: Text {
                                text: cameraSelect.displayText
                                font.family: root.theme.text_font
                                font.pointSize: 9
                                color: root.theme.on_surface
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }

                            onActivated: {
                                camera.cameraDevice = model[index];
                            }

                            Component.onCompleted: {
                                for (var i = 0; i < model.length; i++) {
                                    if (model[i].id === camera.cameraDevice.id) {
                                        currentIndex = i;
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Enable Microphone"
                            color: root.theme.on_surface
                            font.family: root.theme.text_font
                            font.pointSize: 9
                            Layout.fillWidth: true
                        }
                        Switch {
                            id: micSwitch
                            checked: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Mirror Preview"
                            color: root.theme.on_surface
                            font.family: root.theme.text_font
                            font.pointSize: 9
                            Layout.fillWidth: true
                        }
                        Switch {
                            id: mirrorSwitch
                            checked: true
                            onCheckedChanged: {
                                root.mirrorEnabled = checked;
                            }
                        }
                    }
                }
            }

            // 3. Floating Bottom Controls Bar (Matching tide-island style)
            Rectangle {
                id: bottomBar
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                height: 70
                radius: 12
                color: "#e6" + root.theme.surface.substring(1)
                border.color: root.theme.outline
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 20

                    // Left Group: Timer
                    RowLayout {
                        spacing: 8
                        Layout.preferredWidth: 120

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: root.theme.error
                            visible: root.recording
                            
                            SequentialAnimation on opacity {
                                running: root.recording
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.2; duration: 500 }
                                NumberAnimation { from: 0.2; to: 1.0; duration: 500 }
                            }
                        }

                        Text {
                            text: formatDuration(recorder.duration)
                            color: root.recording ? root.theme.error : root.theme.on_surface
                            font.family: root.theme.text_font
                            font.pointSize: 14
                            font.bold: true
                        }
                    }

                    // Center Group: Controls
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 15

                        // Pause Button
                        Rectangle {
                            id: btnPause
                            width: 36
                            height: 36
                            radius: 18
                            color: enabled ? "#22" + root.theme.on_surface.substring(1) : "#05ffffff"
                            border.color: root.theme.outline
                            border.width: 1
                            visible: root.recording || root.paused
                            enabled: root.recording || root.paused

                            Text {
                                anchors.centerIn: parent
                                text: root.paused ? "▶" : "‖"
                                color: parent.enabled ? root.theme.on_surface : "#4cffffff"
                                font.family: root.theme.text_font
                                font.pointSize: 10
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (root.paused) {
                                        recorder.resume();
                                    } else {
                                        recorder.pause();
                                    }
                                }
                            }
                        }

                        // Circular Record / Stop Button
                        Rectangle {
                            id: btnRecord
                            width: 48
                            height: 48
                            radius: 24
                            color: "transparent"
                            border.color: root.theme.on_surface
                            border.width: 3

                            Rectangle {
                                anchors.centerIn: parent
                                width: root.recording || root.paused ? 16 : 30
                                height: root.recording || root.paused ? 16 : 30
                                radius: root.recording || root.paused ? 3 : 15
                                color: root.theme.error

                                Behavior on width { NumberAnimation { duration: 150 } }
                                Behavior on height { NumberAnimation { duration: 150 } }
                                Behavior on radius { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (root.recording || root.paused) {
                                        recorder.stop();
                                    } else {
                                        startRecording();
                                    }
                                }
                            }
                        }
                    }

                    // Right Group: Settings Toggle Button
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: 120

                        Rectangle {
                            id: btnSettings
                            width: 96
                            height: 34
                            radius: 8
                            color: root.settingsVisible ? root.theme.primary : "#1c" + root.theme.on_surface.substring(1)
                            border.color: root.theme.outline
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "⚙ Settings"
                                color: root.settingsVisible ? root.theme.background : root.theme.on_surface
                                font.family: root.theme.text_font
                                font.pointSize: 9
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.settingsVisible = !root.settingsVisible;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Formatting timer string
    function formatDuration(ms) {
        var totalSec = Math.floor(ms / 1000);
        var min = Math.floor(totalSec / 60).toString().padStart(2, '0');
        var sec = (totalSec % 60).toString().padStart(2, '0');
        return min + ":" + sec;
    }

    // Creating target Movies path
    function getUniqueFilename() {
        var date = new Date();
        var yyyy = date.getFullYear();
        var mm = String(date.getMonth() + 1).padStart(2, '0');
        var dd = String(date.getDate()).padStart(2, '0');
        var hh = String(date.getHours()).padStart(2, '0');
        var min = String(date.getMinutes()).padStart(2, '0');
        var sec = String(date.getSeconds()).padStart(2, '0');
        var baseDir = StandardPaths.writableLocation(StandardPaths.MoviesLocation);
        if (!baseDir.toString().endsWith("/")) {
            baseDir += "/";
        }
        return baseDir + "record_" + yyyy + mm + dd + "_" + hh + min + sec + ".mp4";
    }

    function startRecording() {
        var fileUrl = getUniqueFilename();
        recorder.outputLocation = fileUrl;
        recorder.record();
    }
}
