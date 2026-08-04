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

    property real nightLightTemp: 0.0
    onNightLightTempChanged: {
        if (!shuttingDown) {
            saveTempCacheTimer.restart();
        }
    }
    property bool caffeineMode: false
    property int batteryModeIndex: 1
    property bool darkMode: true

    function toggleDarkMode() {
        shellRoot.darkMode = !shellRoot.darkMode;
        const modeStr = shellRoot.darkMode ? "dark" : "light";
        console.log("[DarkMode] Toggling dark mode to: " + modeStr);
        Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/apply_theme_mode.py", modeStr]);
    }



    Timer {
        id: saveTempCacheTimer
        interval: 500
        repeat: false
        onTriggered: {
            console.log("[NightLight] saveTempCacheTimer triggered. Saving nightLightTemp = " + shellRoot.nightLightTemp);
            Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.cache/tide-island && echo '" + shellRoot.nightLightTemp + "' > ~/.cache/tide-island/night_light_temp"]);
            const val = shellRoot.nightLightTemp;
            if (val < 0.05) {
                Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
            } else {
                const targetK = Math.round(6500 - (val * 4000));
                Quickshell.execDetached(["sh", "-c", "hyprctl hyprsunset temperature " + targetK + " || (hyprsunset -t " + targetK + " &)"]);
            }
        }
    }

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
            shellRoot.nightLightTemp = value;
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

        function toggleUtilities() {
            shellRoot.forEachWindow((window) => {
                if (window && window.toggleUtilities)
                    window.toggleUtilities();
            });
        }

        function toggleTimer() {
            shellRoot.forEachWindow((window) => {
                if (window && window.toggleTimer)
                    window.toggleTimer();
            });
        }

        function toggleNotepad() {
            shellRoot.forEachWindow((window) => {
                if (window && window.toggleNotepad)
                    window.toggleNotepad();
            });
        }

        function toggleCheatsheet() {
            shellRoot.toggleCheatsheetAll();
        }

        function toggleDarkMode() {
            shellRoot.toggleDarkMode();
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

    Process {
        id: startupCheckHypridleProcess
        command: ["pgrep", "-x", "hypridle"]
        running: false
        onExited: (exitCode) => {
            shellRoot.caffeineMode = (exitCode !== 0);
        }
    }

    Process {
        id: startupQueryHyprsunsetProcess
        command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && ps -o command= -p $(pgrep -x hyprsunset) || cat " + getHomePath() + "/.cache/tide-island/night_light_temp 2>/dev/null || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text ? this.text.trim() : "";
                console.log("[NightLight] startupQueryHyprsunsetProcess finished. stdout: '" + text + "'");
                if (text !== "") {
                    const match = text.match(/-t\s+(\d+)/);
                    if (match && match[1]) {
                        const temp = parseInt(match[1]);
                        const calculatedTemp = (6500 - temp) / 4000;
                        console.log("[NightLight] Found running hyprsunset with temp " + temp + "K. Setting nightLightTemp = " + calculatedTemp);
                        shellRoot.nightLightTemp = calculatedTemp;
                    } else {
                        const val = parseFloat(text);
                        if (!isNaN(val) && val >= 0.0 && val <= 1.0) {
                            console.log("[NightLight] Found cached temperature " + val + ". Setting nightLightTemp.");
                            shellRoot.nightLightTemp = val;
                            if (val >= 0.05) {
                                const targetK = Math.round(6500 - (val * 4000));
                                console.log("[NightLight] Starting hyprsunset with cached temp " + targetK + "K");
                                Quickshell.execDetached(["sh", "-c", "hyprctl hyprsunset temperature " + targetK + " || (hyprsunset -t " + targetK + " &)"]);
                            }
                        } else {
                            console.log("[NightLight] Cached value invalid: '" + text + "'. Setting nightLightTemp = 0");
                            shellRoot.nightLightTemp = 0;
                        }
                    }
                } else {
                    console.log("[NightLight] No running process or cache found. Setting nightLightTemp = 0");
                    shellRoot.nightLightTemp = 0;
                }
            }
        }
    }

    Process {
        id: startupPpQueryProcess
        command: ["powerprofilesctl", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    const profileName = this.text.trim();
                    let idx = 1;
                    if (profileName === "power-saver") idx = 0;
                    else if (profileName === "performance") idx = 2;
                    shellRoot.batteryModeIndex = idx;
                }
            }
        }
    }

    Process {
        id: startupQueryDarkModeProcess
        command: ["sh", "-c", "cat " + getHomePath() + "/.cache/tide-island/theme_mode 2>/dev/null || gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'dark'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text ? this.text.trim().toLowerCase() : "";
                if (text.indexOf("light") !== -1) {
                    shellRoot.darkMode = false;
                } else {
                    shellRoot.darkMode = true;
                }
                console.log("[DarkMode] Startup query result: darkMode = " + shellRoot.darkMode);
            }
        }
    }

    Component.onDestruction: {
        shuttingDown = true;
    }

    Component.onCompleted: {
        SystemServices.ensureSetupComplete(Quickshell.shellDir);
        SystemServices.requestScreenRecordingSnapshot();
        startupCheckHypridleProcess.running = true;
        startupQueryHyprsunsetProcess.running = true;
        startupPpQueryProcess.running = true;
        startupQueryDarkModeProcess.running = true;
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
