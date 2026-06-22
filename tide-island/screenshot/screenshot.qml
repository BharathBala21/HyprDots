import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import IslandBackend

ShellRoot {
    id: shellRoot

    readonly property bool isImmediateAction: Quickshell.env("SCREENSHOT_MODE") === "region" || Quickshell.env("RECORD_MODE") === "region"

    Timer {
        id: startupTimer
        interval: 50
        running: shellRoot.isImmediateAction
        repeat: false
        onTriggered: {
            var screenshotMode = Quickshell.env("SCREENSHOT_MODE");
            var recordMode = Quickshell.env("RECORD_MODE");
            if (screenshotMode === "region") {
                executeAction(0, 2);
            } else if (recordMode === "region") {
                executeAction(1, 2);
            }
        }
    }

    Component.onCompleted: {
        var screenshotMode = Quickshell.env("SCREENSHOT_MODE");
        var recordMode = Quickshell.env("RECORD_MODE");
        if (screenshotMode === "window") {
            selectedMainIndex = 0;
            selectedSubIndex = 1;
            dropdownOpen = true;
        } else if (screenshotMode === "output") {
            selectedMainIndex = 0;
            selectedSubIndex = 0;
            dropdownOpen = true;
        } else if (recordMode === "window") {
            selectedMainIndex = 1;
            selectedSubIndex = 2;
            dropdownOpen = true;
        } else if (recordMode === "output") {
            selectedMainIndex = 1;
            selectedSubIndex = 0;
            dropdownOpen = true;
        }
    }

    // State selection variables
    property int selectedMainIndex: 0 // 0 = Screenshot, 1 = Record, 2 = Cancel
    property bool dropdownOpen: false
    property int selectedSubIndex: 2 // 0 = Workspace, 1 = Window, 2 = Region

    onSelectedMainIndexChanged: {
        if (selectedMainIndex === 1 && selectedSubIndex === 1) {
            selectedSubIndex = 2;
        }
    }

    onSelectedSubIndexChanged: {
        if (selectedMainIndex === 1 && selectedSubIndex === 1) {
            selectedSubIndex = 2;
        }
    }

    // Recording state variables
    property bool isRecording: false
    property bool wfRecorderActive: false
    property int recordingSeconds: 0
    property int startTimeoutCounter: 0

    // Pill coordinates shared state
    property real pillX: 0
    property real pillY: 0

    Timer {
        id: statusCheckTimer
        interval: 500
        running: shellRoot.isRecording
        repeat: true
        onTriggered: {
            if (!checkRecorderProcess.running) {
                checkRecorderProcess.running = true;
            }
            if (!checkSlurpProcess.running) {
                checkSlurpProcess.running = true;
            }
        }
    }

    Process {
        id: checkSlurpProcess
        command: ["pgrep", "-x", "slurp"]
        running: false
        property bool isSlurpRunning: false
        onExited: (exitCode) => {
            isSlurpRunning = (exitCode === 0);
        }
    }

    Process {
        id: checkRecorderProcess
        command: ["pgrep", "-x", "wf-recorder"]
        running: false
        onExited: (exitCode) => {
            var isRunning = (exitCode === 0);
            if (isRunning) {
                if (!shellRoot.wfRecorderActive) {
                    shellRoot.wfRecorderActive = true;
                    recordingTimer.running = true;
                }
            } else {
                if (shellRoot.wfRecorderActive) {
                    // It was recording, but now stopped
                    Qt.quit();
                } else {
                    // Not started yet.
                    if (checkSlurpProcess.isSlurpRunning) {
                        shellRoot.startTimeoutCounter = 0; // Reset while user is selecting
                    } else {
                        shellRoot.startTimeoutCounter++;
                        if (shellRoot.startTimeoutCounter > 3) { // 3 * 500ms = 1.5 seconds
                            Qt.quit();
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: recordingTimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            shellRoot.recordingSeconds++;
        }
    }

    function formatTime(seconds) {
        var mins = Math.floor(seconds / 60);
        var secs = seconds % 60;
        return (mins < 10 ? "0" + mins : mins) + ":" + (secs < 10 ? "0" + secs : secs);
    }

    function stopRecording() {
        var scriptPath = Quickshell.env("HOME") + "/.local/src/HyprDots/tide-island/screenshot/record.sh";
        if (shellRoot.wfRecorderActive) {
            Quickshell.execDetached([scriptPath]);
        } else {
            Quickshell.execDetached(["pkill", "-x", "wf-recorder"]);
        }
        Quickshell.execDetached(["pkill", "-x", "slurp"]);
        Qt.quit();
    }



    function executeAction(mainIndex, subIndex) {
        if (mainIndex === 2) {
            Qt.quit();
            return;
        }

        var cmd = [];
        if (mainIndex === 0) { // Screenshot
            if (subIndex === 0) {
                var monitorName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "eDP-1";
                cmd = ["hyprshot", "-z", "-m", "output", "-m", monitorName];
            } else if (subIndex === 1) {
                cmd = ["hyprshot", "-z", "-m", "window"];
            } else if (subIndex === 2) {
                cmd = ["hyprshot", "-z", "-m", "region"];
            }
            Quickshell.execDetached(cmd);
            Qt.quit();
        } else if (mainIndex === 1) { // Record
            var scriptPath = Quickshell.env("HOME") + "/.local/src/HyprDots/tide-island/screenshot/record.sh";
            if (subIndex === 0) {
                cmd = [scriptPath];
            } else if (subIndex === 1) {
                cmd = [scriptPath, "-r"];
            } else if (subIndex === 2) {
                cmd = [scriptPath, "-r"];
            }
            shellRoot.isRecording = true;
            shellRoot.wfRecorderActive = false;
            shellRoot.recordingSeconds = 0;
            shellRoot.startTimeoutCounter = 0;
            shellRoot.dropdownOpen = false;

            Quickshell.execDetached(cmd);
        }
    }

    // Selection UI - PanelWindow per screen
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            aboveWindows: true
            focusable: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "screenshot_overlay"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            visible: !shellRoot.isRecording && !shellRoot.isImmediateAction

            mask: Region {
                Region {
                    x: 0
                    y: 0
                    width: win.width
                    height: win.height
                }
            }

            Component.onCompleted: {
                if (!shellRoot.isImmediateAction) {
                    fadeInAnimation.start();
                    overlayBackground.forceActiveFocus();
                }
            }

            SequentialAnimation {
                id: fadeInAnimation
                NumberAnimation {
                    target: overlayBackground
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: overlayBackground
                anchors.fill: parent
                color: Qt.rgba(StyleTokens.panel.r, StyleTokens.panel.g, StyleTokens.panel.b, 0.45)
                opacity: 0
                focus: true

                // Clicking anywhere on the background dismisses the screenshot GUI
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Qt.quit();
                    }
                }

                Colors {
                    id: mColors
                }

                // Dropdown menu container
                Rectangle {
                    id: dropdownMenu
                    
                    anchors.bottom: pill.top
                    anchors.bottomMargin: 12
                    
                    x: {
                        var activeTrigger = (shellRoot.selectedMainIndex === 0) ? btnScreenshot : btnRecord;
                        if (!activeTrigger || !pill || !contentRow) return 0;
                        var btnCenterInPill = contentRow.x + activeTrigger.x + activeTrigger.width / 2;
                        var btnCenterInParent = pill.x + btnCenterInPill;
                        return btnCenterInParent - width / 2;
                    }

                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuint
                        }
                    }

                    implicitWidth: 160
                    implicitHeight: dropdownColumn.height + 24
                    radius: 16

                    color: StyleTokens.panel
                    border.color: Qt.rgba(mColors.primary.r, mColors.primary.g, mColors.primary.b, 0.15)
                    border.width: 1

                    opacity: shellRoot.dropdownOpen && shellRoot.selectedMainIndex <= 1 ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    // Sliding sub-highlight background inside the dropdown menu
                    readonly property var targetSubButton: {
                        if (shellRoot.selectedSubIndex === 0) return btnSubWorkspace;
                        if (shellRoot.selectedSubIndex === 1) return btnSubWindow;
                        if (shellRoot.selectedSubIndex === 2) return btnSubRegion;
                        return btnSubRegion;
                    }

                    Rectangle {
                        id: subHighlightBg
                        x: dropdownMenu.targetSubButton ? dropdownColumn.x + dropdownMenu.targetSubButton.x : 0
                        y: dropdownMenu.targetSubButton ? dropdownColumn.y + dropdownMenu.targetSubButton.y : 0
                        width: dropdownMenu.targetSubButton ? dropdownMenu.targetSubButton.width : 0
                        height: dropdownMenu.targetSubButton ? dropdownMenu.targetSubButton.height : 0
                        radius: dropdownMenu.targetSubButton ? dropdownMenu.targetSubButton.radius : 0
                        color: mColors.primary

                        Behavior on x {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutQuint
                            }
                        }
                        Behavior on y {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutQuint
                            }
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutQuint
                            }
                        }
                    }

                    Column {
                        id: dropdownColumn
                        anchors.centerIn: parent
                        spacing: 4
                        width: parent.width - 24

                        PillButton {
                            id: btnSubWorkspace
                            icon: "󰖲"
                            label: "Workspace"
                            width: parent.width
                            centerContent: false
                            isSelected: shellRoot.dropdownOpen && shellRoot.selectedSubIndex === 0
                            onClicked: {
                                shellRoot.selectedSubIndex = 0;
                                shellRoot.executeAction(shellRoot.selectedMainIndex, 0);
                            }
                        }

                        PillButton {
                            id: btnSubWindow
                            icon: "󰖯"
                            label: "Window"
                            width: parent.width
                            centerContent: false
                            visible: shellRoot.selectedMainIndex !== 1
                            isSelected: shellRoot.dropdownOpen && shellRoot.selectedSubIndex === 1
                            onClicked: {
                                shellRoot.selectedSubIndex = 1;
                                shellRoot.executeAction(shellRoot.selectedMainIndex, 1);
                            }
                        }

                        PillButton {
                            id: btnSubRegion
                            icon: "󰆞"
                            label: "Region"
                            width: parent.width
                            centerContent: false
                            isSelected: shellRoot.dropdownOpen && shellRoot.selectedSubIndex === 2
                            onClicked: {
                                shellRoot.selectedSubIndex = 2;
                                shellRoot.executeAction(shellRoot.selectedMainIndex, 2);
                            }
                        }
                    }
                }

                // The Pill GUI container towards the bottom
                Rectangle {
                    id: pill
                    x: (parent.width - width) / 2
                    y: parent.height - height - 80

                    width: contentRow.width + 32
                    implicitHeight: 64
                    radius: 32

                    // Styling matching tide-island
                    color: StyleTokens.panel
                    border.color: Qt.rgba(mColors.primary.r, mColors.primary.g, mColors.primary.b, 0.15)
                    border.width: 1

                    // Reference to the currently selected button for positioning the highlight
                    readonly property var targetButton: {
                        if (shellRoot.selectedMainIndex === 0) return btnScreenshot;
                        if (shellRoot.selectedMainIndex === 1) return btnRecord;
                        if (shellRoot.selectedMainIndex === 2) return btnCancel;
                        return btnScreenshot;
                    }

                    // Sliding highlight background behind the selected option button
                    Rectangle {
                        id: highlightBg
                        x: pill.targetButton ? contentRow.x + pill.targetButton.x : 0
                        y: pill.targetButton ? contentRow.y + pill.targetButton.y : 0
                        width: pill.targetButton ? pill.targetButton.width : 0
                        height: pill.targetButton ? pill.targetButton.height : 0
                        radius: pill.targetButton ? pill.targetButton.radius : 0
                        color: pill.targetButton && pill.targetButton.isCancel ? mColors.error : mColors.primary

                        Behavior on x {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutQuint
                            }
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutQuint
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                    }

                    Row {
                        id: contentRow
                        anchors.centerIn: parent
                        spacing: 8

                        // Screenshot Dropdown Trigger
                        PillButton {
                            id: btnScreenshot
                            icon: "󰹑"
                            label: "Screenshot  󰅀"
                            isSelected: shellRoot.selectedMainIndex === 0
                            onClicked: {
                                shellRoot.selectedMainIndex = 0;
                                shellRoot.dropdownOpen = !shellRoot.dropdownOpen;
                                if (shellRoot.dropdownOpen) {
                                    shellRoot.selectedSubIndex = 2;
                                }
                            }
                        }

                        // Screen Record Dropdown Trigger
                        PillButton {
                            id: btnRecord
                            icon: "󰑋"
                            label: "Record  󰅀"
                            isSelected: shellRoot.selectedMainIndex === 1
                            onClicked: {
                                shellRoot.selectedMainIndex = 1;
                                shellRoot.dropdownOpen = !shellRoot.dropdownOpen;
                                if (shellRoot.dropdownOpen) {
                                    shellRoot.selectedSubIndex = 2;
                                }
                            }
                        }

                        // Vertical separator
                        Rectangle {
                            width: 1
                            height: 24
                            color: Qt.rgba(mColors.primary.r, mColors.primary.g, mColors.primary.b, 0.15)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Cancel button
                        PillButton {
                            id: btnCancel
                            icon: "󰅖"
                            label: "Cancel"
                            isSelected: shellRoot.selectedMainIndex === 2
                            isCancel: true
                            onClicked: {
                                shellRoot.selectedMainIndex = 2;
                                Qt.quit();
                            }
                        }
                    }
                }

                // Handle keyboard navigation globally on each window
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        if (shellRoot.dropdownOpen) {
                            shellRoot.dropdownOpen = false;
                        } else {
                            Qt.quit();
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left) {
                        if (shellRoot.dropdownOpen) {
                            shellRoot.dropdownOpen = false;
                        }
                        shellRoot.selectedMainIndex = (shellRoot.selectedMainIndex + 2) % 3;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right) {
                        if (shellRoot.dropdownOpen) {
                            shellRoot.dropdownOpen = false;
                        }
                        shellRoot.selectedMainIndex = (shellRoot.selectedMainIndex + 1) % 3;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        if (!shellRoot.dropdownOpen) {
                            if (shellRoot.selectedMainIndex <= 1) {
                                shellRoot.dropdownOpen = true;
                                shellRoot.selectedSubIndex = 2; // Default to region
                            }
                        } else {
                            shellRoot.selectedSubIndex = (shellRoot.selectedSubIndex + 2) % 3;
                            if (shellRoot.selectedMainIndex === 1 && shellRoot.selectedSubIndex === 1) {
                                shellRoot.selectedSubIndex = 0; // Skip Window option (index 1) for record
                            }
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        if (shellRoot.dropdownOpen) {
                            if (shellRoot.selectedSubIndex === 2) {
                                shellRoot.dropdownOpen = false;
                            } else {
                                shellRoot.selectedSubIndex = (shellRoot.selectedSubIndex + 1) % 3;
                                if (shellRoot.selectedMainIndex === 1 && shellRoot.selectedSubIndex === 1) {
                                    shellRoot.selectedSubIndex = 2; // Skip Window option (index 1) for record
                                }
                            }
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab) {
                        if (!shellRoot.dropdownOpen) {
                            shellRoot.selectedMainIndex = (shellRoot.selectedMainIndex + 1) % 3;
                        } else {
                            shellRoot.selectedSubIndex = (shellRoot.selectedSubIndex + 1) % 3;
                            if (shellRoot.selectedMainIndex === 1 && shellRoot.selectedSubIndex === 1) {
                                shellRoot.selectedSubIndex = 2; // Skip Window option (index 1) for record
                            }
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                        if (shellRoot.selectedMainIndex === 2) {
                            Qt.quit();
                        } else if (!shellRoot.dropdownOpen) {
                            shellRoot.dropdownOpen = true;
                            shellRoot.selectedSubIndex = 2;
                        } else {
                            shellRoot.executeAction(shellRoot.selectedMainIndex, shellRoot.selectedSubIndex);
                        }
                        event.accepted = true;
                    }
                }
            }
        }
    }

    // Recording UI - Single Window
    PanelWindow {
        id: recWin

        color: "transparent"
        screen: {
            var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
            for (var i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === name) {
                    return Quickshell.screens[i];
                }
            }
            return Quickshell.screens[0];
        }

        implicitWidth: recPill.width
        implicitHeight: recPill.height

        visible: shellRoot.isRecording
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "screenshot_recording"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            bottom: true
        }
        margins.bottom: 80

        Rectangle {
            id: recPill
            color: StyleTokens.panel
            border.color: Qt.rgba(mColors.primary.r, mColors.primary.g, mColors.primary.b, 0.15)
            border.width: 1
            radius: 32

            Colors {
                id: mColors
            }

            Row {
                id: recordingRow
                anchors.centerIn: parent
                spacing: 12

                // Blinking red indicator dot
                Rectangle {
                    id: recDot
                    width: 10
                    height: 10
                    radius: 5
                    color: mColors.error
                    anchors.verticalCenter: parent.verticalCenter
                    visible: shellRoot.wfRecorderActive

                    SequentialAnimation on opacity {
                        running: shellRoot.wfRecorderActive
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.2; duration: 600 }
                        NumberAnimation { from: 0.2; to: 1.0; duration: 600 }
                    }
                }

                Text {
                    text: shellRoot.wfRecorderActive ? "Recording" : "Starting..."
                    font.family: UserConfig.textFontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: StyleTokens.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: formatTime(shellRoot.recordingSeconds)
                    font.family: UserConfig.textFontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: StyleTokens.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                    visible: shellRoot.wfRecorderActive
                }

                // Vertical separator
                Rectangle {
                    width: 1
                    height: 20
                    color: Qt.rgba(mColors.primary.r, mColors.primary.g, mColors.primary.b, 0.15)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Stop/Cancel button
                PillButton {
                    id: btnStopRec
                    icon: "󰙦"
                    label: shellRoot.wfRecorderActive ? "Stop" : "Cancel"
                    isCancel: true
                    onClicked: {
                        stopRecording();
                    }
                }
            }

            width: 320
            height: 64
        }
    }
}
