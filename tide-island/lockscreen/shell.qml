import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    // Determine mode based on TEST_MODE env var
    property bool testMode: Quickshell.env("TEST_MODE") === "1"

    // Default fallback wallpaper path
    property string wallpaperPath: "file:///home/pirate/Pictures/Wallpapers/cloudy-landscape.jpg"

    // Process to dynamically find the wallpaper path at startup (checking waypaper config first)
    Process {
        id: wallpaperFinder
        command: ["sh", "-c", "if [ -f ~/.config/waypaper/config.ini ]; then WP=$(cat ~/.config/waypaper/config.ini | grep -E \"^wallpaper\\s*=\" | head -n 1 | cut -d'=' -f2 | xargs | sed \"s|^~|$HOME|\"); fi; if [ -z \"$WP\" ] && [ -f ~/.config/hypr/hyprpaper.conf ]; then WP=$(cat ~/.config/hypr/hyprpaper.conf | grep -E \"path\\s*=\" | head -n 1 | cut -d'=' -f2 | xargs | sed \"s|^~|$HOME|\"); fi; echo \"$WP\""]
        running: true
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                let path = collector.text.trim();
                if (path) {
                    root.wallpaperPath = "file://" + path;
                }
                console.log("Loaded wallpaper path:", root.wallpaperPath);
            }
        }
    }

    // Process to terminate Quickshell when successfully unlocked
    Process {
        id: terminator
        command: ["sh", "-c", "kill $PPID"]
    }

    // Matugen Colors Integration
    FileView {
        id: colorsWatcher
        path: root.getHomePath() + "/.local/state/quickshell/generated/colors.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: {
            colorsWatcher.reload();
        }
    }

    function getHomePath() {
        return Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "pirate");
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

    readonly property var themeColors: parseColorsQml(colorsWatcher.text())

    Timer {
        id: quitTimer
        interval: 200 // 200ms delay to allow Wayland round-trip to complete before exit
        running: false
        repeat: false
        onTriggered: {
            terminator.running = true;
        }
    }

    function unlockSession() {
        console.log("Unlocking session and quitting...");
        if (!testMode && lockLoader.item) {
            lockLoader.item.locked = false;
        }
        quitTimer.start();
    }

    // --- TEST MODE (Runs in a Window overlay for validation) ---
    Loader {
        active: root.testMode
        sourceComponent: Component {
            PanelWindow {
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                
                // Ignore panel exclusion zones to cover the panel as well
                exclusionMode: ExclusionMode.Ignore
                
                LockScreen {
                    wallpaperPath: root.wallpaperPath
                    themeColors: root.themeColors
                    isLocked: false
                    onUnlocked: {
                        root.unlockSession();
                    }
                }
            }
        }
    }

    // --- PRODUCTION LOCK MODE (Uses WlSessionLock protocol) ---
    Loader {
        id: lockLoader
        active: !root.testMode
        sourceComponent: Component {
            WlSessionLock {
                id: sessionLock
                locked: true
                
                surface: Component {
                    WlSessionLockSurface {
                        color: "black" // default background color to prevent flash of white
                        
                        LockScreen {
                            wallpaperPath: root.wallpaperPath
                            themeColors: root.themeColors
                            isLocked: true
                            onUnlocked: {
                                root.unlockSession();
                            }
                        }
                    }
                }
            }
        }
    }
}
