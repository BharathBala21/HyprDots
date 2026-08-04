import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property string currentTime: "00:00"
    property string currentDateLabel: "Mon, Jan 01"

    function getHomePath() {
        return Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user");
    }

    FileView {
        id: cfgWatcher
        path: getHomePath() + "/.config/tide-island/userconfig.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: cfgWatcher.reload()
    }

    readonly property var cfgData: {
        try {
            return cfgWatcher.text() ? JSON.parse(cfgWatcher.text()) : {};
        } catch (e) {
            return {};
        }
    }

    readonly property string clockFormat: cfgData.clockFormat || "24"

    onClockFormatChanged: updateClock()

    readonly property var monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    function padTwoDigits(value) {
        return value < 10 ? "0" + value : String(value);
    }

    function formatDateLabel(now) {
        return dayNames[now.getDay()]
            + ", "
            + monthNames[now.getMonth()]
            + " "
            + padTwoDigits(now.getDate());
    }

    function updateClock() {
        const now = new Date();
        const fmt = (root.clockFormat === "12") ? "hh:mm ap" : "hh:mm";
        root.currentTime = Qt.formatTime(now, fmt);
        root.currentDateLabel = root.formatDateLabel(now);
    }

    Timer {
        id: clockTimer

        running: true
        repeat: true
        triggeredOnStart: true
        interval: 1000

        onTriggered: {
            root.updateClock();
            const now = new Date();
            interval = (60 - now.getSeconds()) * 1000 - now.getMilliseconds();
        }
    }
}
