//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import IslandBackend

Scope {
    id: shellRoot

    readonly property bool screenRecordingActive: SystemServices.screenRecordingActive || shellRoot.wfRecorderRunning
    property bool wfRecorderRunning: false
    property bool shuttingDown: false
    property bool superReleaseMightTrigger: false
    property bool settingsWindowOpen: false
    property bool cheatsheetWindowOpen: false

    function getHomePath() {
        const envHome = Quickshell.env("HOME") || "";
        if (envHome) {
            return envHome;
        }
        const configPath = UserConfig.userConfigPath || "";
        const idx = configPath.indexOf("/.config/");
        if (idx !== -1) {
            return configPath.substring(0, idx);
        }
        return "/home/" + (Quickshell.env("USER") || "user");
    }

    FileView {
        id: colorsWatcher
        path: getHomePath() + "/.local/state/quickshell/generated/colors.json"
        watchChanges: true
        blockLoading: true

        onFileChanged: {
            colorsWatcher.reload();
        }
    }

    function parseColorsQml(qmlText) {
        if (!qmlText) return null;
        const colors = {};
        const regex = /readonly\s+property\s+color\s+(\w+)\s*:\s*"([^"]+)"/g;
        let match;
        while ((match = regex.exec(qmlText)) !== null) {
            colors[match[1]] = match[2];
        }
        return colors;
    }

    readonly property var matugenThemeColors: parseColorsQml(colorsWatcher.text())

    Timer {
        id: checkWfRecorderTimer
        interval: 2500
        running: true
        repeat: true
        onTriggered: {
            checkWfRecorderProcess.running = true;
        }
    }

    Process {
        id: checkWfRecorderProcess
        command: ["pgrep", "-x", "wf-recorder"]
        running: false
        onExited: (exitCode) => {
            shellRoot.wfRecorderRunning = (exitCode === 0);
        }
    }

    Process {
        id: playAlertProcess
        command: ["pw-play", "/usr/share/tide-island/assets/alert.mp3"]
        running: false
    }

    function playAlertSound() {
        playAlertProcess.running = true;
    }

    readonly property var userConfig: UserConfig

    function forEachWindow(callback) {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window)
                callback(window);
        }
    }

    function showNotificationAll(appName, summary, body) {
        // If charging or full, suppress any battery-related alerts/notifications
        const isCharging = (SysBackend.batteryStatus === "Charging" || SysBackend.batteryStatus === "Full" || SysBackend.batteryStatus === "Not charging");
        const isBatteryNotification = (appName === "Battery" || appName === "TideBatteryAlert" || appName.toLowerCase().indexOf("battery") !== -1);

        if (isCharging && isBatteryNotification) {
            return;
        }

        shellRoot.forEachWindow((window) => {
            if (window && window.showNotification)
                window.showNotification(appName, summary, body);
        });

        if (appName === "TideBatteryAlert") {
            shellRoot.playAlertSound();
        }
    }

    function anyOverviewOpen() {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && window.overviewPhase !== "closed")
                return true;
        }

        return false;
    }

    function prepareOverviewAll() {
        shellRoot.forEachWindow((window) => window.prepareOverview());
    }

    function cancelPreparedOverviewAll() {
        shellRoot.forEachWindow((window) => window.cancelPreparedOverview());
    }

    function openOverviewAll() {
        shellRoot.forEachWindow((window) => window.openOverview());
    }

    function closeOverviewAll() {
        shellRoot.forEachWindow((window) => window.closeOverview());
    }

    function toggleOverviewAll() {
        if (shellRoot.anyOverviewOpen())
            shellRoot.closeOverviewAll();
        else
            shellRoot.openOverviewAll();
    }

    function toggleLauncherAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.toggleLauncher)
                window.toggleLauncher();
        });
    }

    function toggleClipboardAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.toggleClipboard)
                window.toggleClipboard();
        });
    }

    function toggleCheatsheetAll() {
        shellRoot.cheatsheetWindowOpen = !shellRoot.cheatsheetWindowOpen;
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            shellRoot.toggleOverviewAll();
        }

        function open() {
            shellRoot.openOverviewAll();
        }

        function close() {
            shellRoot.closeOverviewAll();
        }

        function refreshWallpaperCache() {
            shellRoot.forEachWindow((window) => {
                if (window && window.prewarmWallpaperCache)
                    window.prewarmWallpaperCache();
            });
        }
    }

    IpcHandler {
        target: "island"

        function toggleControlCenter() {
            shellRoot.forEachWindow((window) => {
                if (window && window.toggleControlCenter)
                    window.toggleControlCenter();
            });
        }

        function setNightLightTemp(value: double) {
            shellRoot.forEachWindow((window) => {
                if (window && window.setNightLightTemp)
                    window.setNightLightTemp(value);
            });
        }

        function toggleLauncher() {
            shellRoot.forEachWindow((window) => {
                if (window && window.toggleLauncher)
                    window.toggleLauncher();
            });
        }

        function toggleClipboard() {
            shellRoot.forEachWindow((window) => {
                if (window && window.toggleClipboard)
                    window.toggleClipboard();
            });
        }

        function toggleEmojis() {
            shellRoot.forEachWindow((window) => {
                if (window && window.toggleEmojis)
                    window.toggleEmojis();
            });
        }

        function toggleWallpapers() {
            shellRoot.forEachWindow((window) => {
                if (window && window.toggleWallpapers)
                    window.toggleWallpapers();
            });
        }

        function toggleCheatsheet() {
            shellRoot.toggleCheatsheetAll();
        }
    }

    GlobalShortcut {
        appid: userConfig.overviewGlobalShortcutAppid
        name: userConfig.overviewGlobalShortcutName

        onPressed: shellRoot.toggleOverviewAll()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "searchToggleRelease"

        onPressed: {
            shellRoot.superReleaseMightTrigger = true;
        }

        onReleased: {
            if (!shellRoot.superReleaseMightTrigger) {
                shellRoot.superReleaseMightTrigger = true;
                return;
            }
            shellRoot.toggleLauncherAll();
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "searchToggleReleaseInterrupt"

        onPressed: {
            shellRoot.superReleaseMightTrigger = false;
        }
    }

    Connections {
        target: SystemServices

        function onNotificationReceived(appName, summary, body) {
            shellRoot.showNotificationAll(appName, summary, body);
        }
    }

    Component.onDestruction: {
        shuttingDown = true;
    }

    Component.onCompleted: {
        SystemServices.ensureSetupComplete(Quickshell.shellDir);
        SystemServices.requestScreenRecordingSnapshot();
    }

    Variants {
        id: panelVariants

        model: Quickshell.screens

        DynamicIslandWindow {
            required property var modelData

            screen: modelData
            shellRootController: shellRoot
        }
    }

    Loader {
        id: settingsWindowLoader
        active: shellRoot.settingsWindowOpen
        source: "qml/controlcenter/SettingsWindow.qml"
        
        onStatusChanged: {
            if (status === Loader.Ready) {
                item.settingsClosed.connect(() => {
                    shellRoot.settingsWindowOpen = false;
                });
            }
        }
    }

    Loader {
        id: cheatsheetWindowLoader
        active: shellRoot.cheatsheetWindowOpen
        source: "qml/controlcenter/CheatsheetWindow.qml"
        
        onStatusChanged: {
            if (status === Loader.Ready) {
                item.cheatsheetClosed.connect(() => {
                    shellRoot.cheatsheetWindowOpen = false;
                });
            }
        }
    }
}
