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

    // Typography styling matching tide-island
    property string textFont: "Inter Display"
    property string iconFont: "JetBrainsMono Nerd Font"

    // Fallback theme palette matching tide-island default colors
    QtObject {
        id: fallbackTheme
        readonly property color background: "#16130b"
        readonly property color error: "#ffb4ab"
        readonly property color on_surface: "#eae1d4"
        readonly property color outline: "#4c4639"
        readonly property color primary: "#e2c46d"
        readonly property color surface: "#16130b"
        readonly property color surface_container: "#231f17"
    }

    // Dynamically load active Matugen color palette generated for quickshell
    Loader {
        id: matugenLoader
        source: "file://" + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/state/quickshell/generated/colors.json"
    }

    // Resolve active theme palette
    property var activeTheme: matugenLoader.status === Loader.Ready ? matugenLoader.item : fallbackTheme

    // Apply default font family
    Component.onCompleted: {
        font.family = textFont;
    }

    // Set background color matching theme
    background: Rectangle {
        color: root.activeTheme.background
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
        imageCapture: ImageCapture {
            id: imageCapture
            onImageSaved: (id, fileName) => {
                var path = fileName.toString();
                if (path.indexOf("file://") === 0) {
                    path = path.substring(7);
                }
                console.log("NOTIFICATION: Photo Saved | Photo saved to: " + path);
            }
            onErrorOccurred: (id, error, errorString) => {
                console.log("PHOTO CAPTURE ERROR: " + errorString);
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

        // Shutter flash effect overlay
        Rectangle {
            id: flashOverlay
            anchors.fill: parent
            color: "#ffffff"
            opacity: 0.0
            z: 5

            SequentialAnimation on opacity {
                id: flashAnimation
                running: false
                NumberAnimation { from: 0.8; to: 0.0; duration: 220; easing.type: Easing.OutQuad }
            }
        }

        // Overlay UI elements (siblings of VideoOutput so they are not mirrored)
        Item {
            id: overlay
            anchors.fill: parent

            // 1. Floating Top Status Pill (Symmetric, centered, matching tide-island)
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                width: 280
                height: 40
                radius: 20
                color: "#d9" + root.activeTheme.surface_container.toString().substring(1) // 85% opacity surface container
                border.color: "#22" + root.activeTheme.on_surface.toString().substring(1)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 10

                    Text {
                        text: "Camera Mirror"
                        color: root.activeTheme.on_surface
                        font.family: root.textFont
                        font.pointSize: 10
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    // Recording indicator dot
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: root.recording ? root.activeTheme.error : "#10b981"
                        
                        SequentialAnimation on opacity {
                            running: root.recording
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                        }
                    }

                    Text {
                        text: root.recording ? "Recording" : "Ready"
                        color: root.recording ? root.activeTheme.error : "#10b981"
                        font.family: root.textFont
                        font.pointSize: 8
                        font.bold: true
                    }
                }
            }

            // 2. Floating Centered Settings Panel with Slide-up Animation
            Rectangle {
                id: settingsPanel
                width: 360
                height: 220
                radius: 16
                color: "#f2" + root.activeTheme.surface_container.toString().substring(1) // 95% opacity
                border.color: root.activeTheme.primary
                border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter
                z: 10

                // Slide & Fade Animation bindings
                opacity: root.settingsVisible ? 1.0 : 0.0
                y: root.settingsVisible ? bottomBar.y - height - 15 : bottomBar.y - height + 10
                visible: opacity > 0.0

                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Text {
                        text: "Camera Settings"
                        color: root.activeTheme.on_surface
                        font.family: root.textFont
                        font.pointSize: 11
                        font.bold: true
                    }

                    // Camera Source Select Dropdown
                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: "Select Device:"
                            color: root.activeTheme.outline
                            font.family: root.textFont
                            font.pointSize: 8
                        }
                        ComboBox {
                            id: cameraSelect
                            Layout.fillWidth: true
                            model: mediaDevices.videoInputs
                            textRole: "description"
                            
                            // Custom ComboBox background button style
                            background: Rectangle {
                                color: "#22" + root.activeTheme.on_surface.toString().substring(1)
                                border.color: root.activeTheme.outline
                                border.width: 1
                                radius: 8
                            }
                            
                            contentItem: Text {
                                text: cameraSelect.displayText
                                font.family: root.textFont
                                font.pointSize: 9
                                color: root.activeTheme.on_surface
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 12
                                rightPadding: 24
                                elide: Text.ElideRight
                            }

                            // Clean down arrow indicator
                            indicator: Text {
                                x: cameraSelect.width - 20
                                y: (cameraSelect.height - height) / 2
                                text: "▼"
                                color: root.activeTheme.on_surface
                                font.pointSize: 7
                            }

                            // Popup drop list container
                            popup: Popup {
                                id: comboPopup
                                y: cameraSelect.height + 4
                                width: cameraSelect.width
                                height: Math.min(200, comboListView.contentHeight + 8) // Fixed: height resolved dynamically from list view
                                padding: 4

                                contentItem: ListView {
                                    id: comboListView
                                    clip: true
                                    model: cameraSelect.popup.visible ? cameraSelect.delegateModel : null
                                    currentIndex: cameraSelect.highlightedIndex

                                    ScrollIndicator.vertical: ScrollIndicator {
                                        active: true
                                    }
                                }

                                background: Rectangle {
                                    color: "#f2" + root.activeTheme.surface_container.toString().substring(1)
                                    border.color: root.activeTheme.primary
                                    border.width: 1
                                    radius: 8
                                }
                            }

                            // Menu list item delegate style
                            delegate: ItemDelegate {
                                width: cameraSelect.width - 8
                                height: 32
                                
                                contentItem: Text {
                                    text: modelData ? (modelData.description || modelData) : "" // Fixed: resolved blank text by fetching modelData description
                                    color: highlighted ? root.activeTheme.background : root.activeTheme.on_surface
                                    font.family: root.textFont
                                    font.pointSize: 9
                                    font.bold: highlighted
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 10
                                    elide: Text.ElideRight
                                }

                                background: Rectangle {
                                    color: highlighted ? root.activeTheme.primary : "transparent"
                                    radius: 6
                                }
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

                    // Custom-styled Microphone Switch
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Enable Audio Input"
                            color: root.activeTheme.on_surface
                            font.family: root.textFont
                            font.pointSize: 9
                            Layout.fillWidth: true
                        }
                        Switch {
                            id: micSwitch
                            checked: true
                            
                            indicator: Rectangle {
                                implicitWidth: 36
                                implicitHeight: 18
                                radius: 9
                                color: micSwitch.checked ? root.activeTheme.primary : "#1c" + root.activeTheme.on_surface.toString().substring(1)
                                border.color: micSwitch.checked ? root.activeTheme.primary : root.activeTheme.outline
                                border.width: 1

                                Rectangle {
                                    x: micSwitch.checked ? 19 : 2
                                    y: 2
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: micSwitch.checked ? root.activeTheme.background : root.activeTheme.on_surface
                                    
                                    Behavior on x {
                                        NumberAnimation { duration: 120 }
                                    }
                                }
                            }
                        }
                    }

                    // Custom-styled Mirror Toggle Switch
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Mirror Output"
                            color: root.activeTheme.on_surface
                            font.family: root.textFont
                            font.pointSize: 9
                            Layout.fillWidth: true
                        }
                        Switch {
                            id: mirrorSwitch
                            checked: true
                            onCheckedChanged: {
                                root.mirrorEnabled = checked;
                            }
                            
                            indicator: Rectangle {
                                implicitWidth: 36
                                implicitHeight: 18
                                radius: 9
                                color: mirrorSwitch.checked ? root.activeTheme.primary : "#1c" + root.activeTheme.on_surface.toString().substring(1)
                                border.color: mirrorSwitch.checked ? root.activeTheme.primary : root.activeTheme.outline
                                border.width: 1

                                Rectangle {
                                    x: mirrorSwitch.checked ? 19 : 2
                                    y: 2
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: mirrorSwitch.checked ? root.activeTheme.background : root.activeTheme.on_surface
                                    
                                    Behavior on x {
                                        NumberAnimation { duration: 120 }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 3. Floating Bottom Controls Bar (Dynamic Island Pill style)
            Rectangle {
                id: bottomBar
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 25
                anchors.horizontalCenter: parent.horizontalCenter
                width: 480
                height: 64
                radius: 32
                color: "#c6" + root.activeTheme.surface_container.toString().substring(1)
                border.color: "#22" + root.activeTheme.on_surface.toString().substring(1)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 25
                    anchors.rightMargin: 25
                    spacing: 20

                    // Left Group: Timer
                    RowLayout {
                        spacing: 8
                        Layout.preferredWidth: 100

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: root.activeTheme.error
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
                            color: root.recording ? root.activeTheme.error : root.activeTheme.on_surface
                            font.family: root.textFont
                            font.pointSize: 13
                            font.bold: true
                        }
                    }

                    // Center Group: Controls (Record / Pause / Photo)
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 15

                        // Shutter / Photo Capture Button (visible when not recording)
                        Rectangle {
                            id: btnPhoto
                            width: 36
                            height: 36
                            radius: 18
                            color: enabled ? "#22" + root.activeTheme.on_surface.toString().substring(1) : "#05ffffff"
                            border.color: root.activeTheme.outline
                            border.width: 1
                            visible: !root.recording && !root.paused
                            enabled: !root.recording && !root.paused

                            // Vector camera icon
                            Image {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                source: {
                                    var color = root.activeTheme.on_surface.toString();
                                    var encodedColor = color.replace("#", "%23");
                                    return "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='" + encodedColor + "'><circle cx='12' cy='12' r='3.2'/><path d='M9 2L7.17 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2h-3.17L15 2H9zm3 15c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5z'/></svg>";
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    takePhoto();
                                }
                            }
                        }

                        // Custom Vector Pause Button (visible only when recording)
                        Rectangle {
                            id: btnPause
                            width: 36
                            height: 36
                            radius: 18
                            color: enabled ? "#22" + root.activeTheme.on_surface.toString().substring(1) : "#05ffffff"
                            border.color: root.activeTheme.outline
                            border.width: 1
                            visible: root.recording || root.paused
                            enabled: root.recording || root.paused

                            Item {
                                anchors.centerIn: parent
                                width: 14
                                height: 14

                                // Play triangle (displayed when paused)
                                Text {
                                    anchors.centerIn: parent
                                    text: "▶"
                                    color: btnPause.enabled ? root.activeTheme.on_surface : "#4cffffff"
                                    font.pointSize: 9
                                    visible: root.paused
                                }

                                // Shorter, slimmer pause bars with 4px gap (displayed when recording)
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    visible: !root.paused

                                    Rectangle {
                                        width: 3
                                        height: 12
                                        radius: 1
                                        color: btnPause.enabled ? root.activeTheme.on_surface : "#4cffffff"
                                    }
                                    Rectangle {
                                        width: 3
                                        height: 12
                                        radius: 1
                                        color: btnPause.enabled ? root.activeTheme.on_surface : "#4cffffff"
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (root.paused) {
                                        recorder.record(); // Resumes a paused recording in QMediaRecorder
                                    } else {
                                        recorder.pause();
                                    }
                                }
                            }
                        }

                        // Circular Record / Stop Button
                        Rectangle {
                            id: btnRecord
                            width: 44
                            height: 44
                            radius: 22
                            color: "transparent"
                            border.color: root.activeTheme.on_surface
                            border.width: 3

                            Rectangle {
                                anchors.centerIn: parent
                                width: root.recording || root.paused ? 14 : 26
                                height: root.recording || root.paused ? 14 : 26
                                radius: root.recording || root.paused ? 3 : 13
                                color: root.activeTheme.error

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

                    // Right Group: Settings Toggle Button (Gear icon in circular layout)
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: 100

                        Rectangle {
                            id: btnSettings
                            width: 36
                            height: 36
                            radius: 18
                            color: root.settingsVisible ? root.activeTheme.primary : "#1c" + root.activeTheme.on_surface.toString().substring(1)
                            border.color: root.activeTheme.outline
                            border.width: 1

                            // Perfectly centered vector gear icon
                            Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: {
                                    var color = root.settingsVisible ? root.activeTheme.background.toString() : root.activeTheme.on_surface.toString();
                                    var encodedColor = color.replace("#", "%23");
                                    return "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='" + encodedColor + "'><path d='M19.43 12.98c.04-.32.07-.64.07-.98s-.03-.66-.07-.98l2.11-1.65c.19-.15.24-.42.12-.64l-2-3.46c-.12-.22-.39-.3-.61-.22l-2.49 1c-.52-.4-1.08-.73-1.69-.98l-.38-2.65C14.46 2.18 14.25 2 14 2h-4c-.25 0-.46.18-.49.42l-.38 2.65c-.61.25-1.17.59-1.69.98l-2.49-1c-.23-.09-.49 0-.61.22l-2 3.46c-.13.22-.07.49.12.64l2.11 1.65c-.04.32-.07.65-.07.98s.03.66.07.98l-2.11 1.65c-.19.15-.24.42-.12.64l2 3.46c.12.22.39.3.61.22l2.49-1c.52.4 1.08.73 1.69.98l.38 2.65c.03.24.24.42.49.42h4c.25 0 .46-.18.49-.42l.38-2.65c.61-.25 1.17-.59 1.69-.98l2.49 1c.23.09.49 0 .61-.22l2-3.46c.12-.22.07-.49-.12-.64l-2.11-1.65zM12 15.5c-1.93 0-3-1.07-3-3s1.07-3 3-3 3 1.07 3 3-1.07 3-3 3z'/></svg>";
                                }
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

    // Creating target Pictures path
    function getUniquePhotoFilename() {
        var date = new Date();
        var yyyy = date.getFullYear();
        var mm = String(date.getMonth() + 1).padStart(2, '0');
        var dd = String(date.getDate()).padStart(2, '0');
        var hh = String(date.getHours()).padStart(2, '0');
        var min = String(date.getMinutes()).padStart(2, '0');
        var sec = String(date.getSeconds()).padStart(2, '0');
        var baseDir = StandardPaths.writableLocation(StandardPaths.PicturesLocation).toString();
        if (baseDir.indexOf("file://") === 0) {
            baseDir = baseDir.substring(7);
        }
        if (!baseDir.endsWith("/")) {
            baseDir += "/";
        }
        return baseDir + "photo_" + yyyy + mm + dd + "_" + hh + min + sec + ".jpg";
    }

    function startRecording() {
        var fileUrl = getUniqueFilename();
        recorder.outputLocation = fileUrl;
        recorder.record();
    }

    function takePhoto() {
        var filePath = getUniquePhotoFilename();
        imageCapture.captureToFile(filePath);
        flashAnimation.start();
    }
}
