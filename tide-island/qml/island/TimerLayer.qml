import QtQuick
import Quickshell
import IslandBackend

Item {
    id: root

    property int remainingSeconds: 300
    property int totalSeconds: 300
    property bool isRunning: false
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property string heroFontFamily: ""

    signal startRequested()
    signal stopRequested()
    signal resetRequested()
    signal adjustTimeRequested(int secondsDelta)
    signal closeRequested()

    readonly property var themeColors: shellRootController ? shellRootController.matugenThemeColors : null
    readonly property color orangeAccent: "#ff9500"
    readonly property color darkCardBg: "#24252a"
    readonly property color textColor: "#ffffff"

    anchors.fill: parent
    focus: true

    Keys.onEscapePressed: (event) => {
        root.closeRequested();
        event.accepted = true;
    }

    function formatTimeDisplay(secs) {
        const h = Math.floor(secs / 3600);
        const m = Math.floor((secs % 3600) / 60);
        const s = secs % 60;
        
        const pad = (n) => (n < 10 ? "0" + n : String(n));
        if (h > 0) {
            return pad(h) + ":" + pad(m) + ":" + pad(s);
        } else {
            return pad(m) + ":" + pad(s);
        }
    }

    function getHours() {
        return Math.floor(remainingSeconds / 3600);
    }

    function getMinutes() {
        return Math.floor((remainingSeconds % 3600) / 60);
    }

    function getSeconds() {
        return remainingSeconds % 60;
    }

    Row {
        anchors.centerIn: parent
        spacing: 24

        // --- Left Side: Circular Ring Progress + Countdown ---
        Item {
            width: 100
            height: 100
            anchors.verticalCenter: parent.verticalCenter

            Canvas {
                id: ringCanvas
                anchors.fill: parent
                antialiasing: true

                property real progress: root.totalSeconds > 0 ? (root.remainingSeconds / root.totalSeconds) : 0

                onProgressChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    const centerX = width / 2;
                    const centerY = height / 2;
                    const radius = (width - 12) / 2;
                    const startAngle = -Math.PI / 2;

                    // Background Track Ring
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
                    ctx.lineWidth = 6;
                    ctx.strokeStyle = "#2c2c2e";
                    ctx.stroke();

                    // Active Progress Arc
                    if (progress > 0) {
                        ctx.beginPath();
                        ctx.arc(centerX, centerY, radius, startAngle, startAngle + (2 * Math.PI * progress), false);
                        ctx.lineWidth = 6;
                        ctx.strokeStyle = root.orangeAccent;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }
            }

            // Center Countdown Text
            Text {
                anchors.centerIn: parent
                text: root.formatTimeDisplay(root.remainingSeconds)
                color: root.textColor
                font.pixelSize: root.remainingSeconds >= 3600 ? 16 : 20
                font.family: root.heroFontFamily || root.textFontFamily
                font.weight: Font.Bold
            }
        }

        // --- Right Side: Controls (Inputs + Buttons) ---
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Top Row: Hours, Minutes & Seconds Stepper Inputs
            Row {
                spacing: 8

                // Hours Input
                Rectangle {
                    width: 88
                    height: 38
                    radius: 10
                    color: root.darkCardBg

                    Text {
                        anchors.centerIn: parent
                        text: root.getHours() + " hr"
                        color: root.textColor
                        font.pixelSize: 13
                        font.family: root.textFontFamily
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: (mouse) => {
                            if (!root.isRunning) {
                                if (mouse.button === Qt.LeftButton) {
                                    root.adjustTimeRequested(3600);
                                } else if (mouse.button === Qt.RightButton) {
                                    root.adjustTimeRequested(-3600);
                                }
                            }
                        }

                        onWheel: (wheel) => {
                            if (!root.isRunning) {
                                if (wheel.angleDelta.y > 0) root.adjustTimeRequested(3600);
                                else if (wheel.angleDelta.y < 0) root.adjustTimeRequested(-3600);
                            }
                        }
                    }
                }

                // Minutes Input
                Rectangle {
                    width: 88
                    height: 38
                    radius: 10
                    color: root.darkCardBg

                    Text {
                        anchors.centerIn: parent
                        text: (root.getMinutes() < 10 ? "0" + root.getMinutes() : root.getMinutes()) + " min"
                        color: root.textColor
                        font.pixelSize: 13
                        font.family: root.textFontFamily
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: (mouse) => {
                            if (!root.isRunning) {
                                if (mouse.button === Qt.LeftButton) {
                                    root.adjustTimeRequested(60);
                                } else if (mouse.button === Qt.RightButton) {
                                    root.adjustTimeRequested(-60);
                                }
                            }
                        }

                        onWheel: (wheel) => {
                            if (!root.isRunning) {
                                if (wheel.angleDelta.y > 0) root.adjustTimeRequested(60);
                                else if (wheel.angleDelta.y < 0) root.adjustTimeRequested(-60);
                            }
                        }
                    }
                }

                // Seconds Input
                Rectangle {
                    width: 88
                    height: 38
                    radius: 10
                    color: root.darkCardBg

                    Text {
                        anchors.centerIn: parent
                        text: (root.getSeconds() < 10 ? "0" + root.getSeconds() : root.getSeconds()) + " sec"
                        color: root.textColor
                        font.pixelSize: 13
                        font.family: root.textFontFamily
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: (mouse) => {
                            if (!root.isRunning) {
                                if (mouse.button === Qt.LeftButton) {
                                    root.adjustTimeRequested(1);
                                } else if (mouse.button === Qt.RightButton) {
                                    root.adjustTimeRequested(-1);
                                }
                            }
                        }

                        onWheel: (wheel) => {
                            if (!root.isRunning) {
                                if (wheel.angleDelta.y > 0) root.adjustTimeRequested(5);
                                else if (wheel.angleDelta.y < 0) root.adjustTimeRequested(-5);
                            }
                        }
                    }
                }
            }

            // Bottom Row: Start/Stop & Reset Buttons
            Row {
                spacing: 8

                // Start / Stop Button
                Rectangle {
                    width: 136
                    height: 38
                    radius: 10
                    color: root.orangeAccent

                    Text {
                        anchors.centerIn: parent
                        text: root.isRunning ? "Stop" : "Start"
                        color: "#000000"
                        font.pixelSize: 14
                        font.family: root.textFontFamily
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.isRunning) {
                                root.stopRequested();
                            } else {
                                root.startRequested();
                            }
                        }
                    }
                }

                // Reset Button
                Rectangle {
                    width: 136
                    height: 38
                    radius: 10
                    color: root.darkCardBg

                    Text {
                        anchors.centerIn: parent
                        text: "Reset"
                        color: root.textColor
                        font.pixelSize: 14
                        font.family: root.textFontFamily
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.resetRequested();
                        }
                    }
                }
            }
        }
    }
}
