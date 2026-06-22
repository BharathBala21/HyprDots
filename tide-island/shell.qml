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

    Timer {
        id: checkWfRecorderTimer
        interval: 1000
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
        shellRoot.forEachWindow((window) => {
            if (window && window.showNotification)
                window.showNotification(appName, summary, body);
        });
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
}
