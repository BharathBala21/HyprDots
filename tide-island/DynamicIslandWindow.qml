import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Wayland
import IslandBackend
import "qml/common"
import "qml/controlcenter"
import "qml/connectivity"
import "qml/island"
import "qml/workspace"

PanelWindow {
    id: root
    property var shellRootController: null
    property real nightLightTemp: 0.0
    property int cachedBatteryModeIndex: 1
    property bool dndActive: false
    property string overviewPhase: "closed"
    property bool overviewPreloading: false
    readonly property bool overviewPreparing: overviewPhase === "preparing"
    readonly property bool overviewVisible: overviewPhase === "preparing" || overviewPhase === "opening" || overviewPhase === "open"
    readonly property bool overviewMounted: overviewPhase !== "closed" || overviewPreloading
    readonly property bool overviewLoaderActive: overviewMounted || overviewUnloadGraceTimer.running
    readonly property bool overviewDataReady: overviewLoader.item
        ? !!overviewLoader.item.overviewDataReady
        : false
    readonly property bool overviewWallpaperReady: overviewWallpaperCache.ready
    readonly property bool overviewVisualReady: overviewDataReady && overviewWallpaperReady
    readonly property bool overviewContentVisible: (overviewPhase === "opening" || overviewPhase === "open")
        && overviewVisualReady
    readonly property var hyprMonitor: screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor
    readonly property string hyprMonitorName: hyprMonitor && hyprMonitor.name ? String(hyprMonitor.name) : ""
    readonly property bool monitorFocused: hyprMonitor ? hyprMonitor.focused : false
    readonly property bool connectivityPromptActive: controlCenterLoader.item
        ? controlCenterLoader.item.hasConnectivityPrompt
        : false
    readonly property int currentMonitorWorkspaceId: hyprMonitor && hyprMonitor.activeWorkspace
        ? hyprMonitor.activeWorkspace.id
        : 1
    readonly property bool screenRecordingActive: shellRootController
        && shellRootController.screenRecordingActive !== undefined
        ? !!shellRootController.screenRecordingActive
        : false
    readonly property bool launcherLayerVisible: islandContainer.islandState === "launcher"
    readonly property bool clipboardLayerVisible: islandContainer.islandState === "clipboard"
    readonly property bool emojiPickerLayerVisible: islandContainer.islandState === "emojis"
    readonly property bool wallpapersLayerVisible: islandContainer.islandState === "wallpapers"
    readonly property bool utilitiesLayerVisible: islandContainer.islandState === "utilities"

    readonly property var userConfig: UserConfig

    ListModel {
        id: notificationHistory
    }

    HyprlandDispatch {
        id: hyprDispatch
    }

    color: StyleTokens.transparent
    anchors { top: true; left: true; right: true }
    mask: Region {
        // Input is the union of the island's visible surfaces plus a compact top
        // gesture strip. The gesture strip must not grow with expanded content.
        Region {
            x: 0
            y: 0
            width: root.width
            height: Math.ceil(root.topGestureInputHeight)
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(mainCapsule.x)
            y: Math.floor(mainCapsule.y)
            width: Math.ceil(mainCapsule.width)
            height: Math.ceil(mainCapsule.height)
        }
        
        // Add existing detail shells
        Region {
            intersection: Intersection.Combine
            x: Math.floor(wifiConnectivityDetailShell.x)
            y: Math.floor(wifiConnectivityDetailShell.y)
            width: wifiConnectivityDetailShell.visible ? Math.ceil(wifiConnectivityDetailShell.width) : 0
            height: wifiConnectivityDetailShell.visible ? Math.ceil(wifiConnectivityDetailShell.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(bluetoothConnectivityDetailShell.x)
            y: Math.floor(bluetoothConnectivityDetailShell.y)
            width: bluetoothConnectivityDetailShell.visible ? Math.ceil(bluetoothConnectivityDetailShell.width) : 0
            height: bluetoothConnectivityDetailShell.visible ? Math.ceil(bluetoothConnectivityDetailShell.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(batteryConnectivityDetailShell.x)
            y: Math.floor(batteryConnectivityDetailShell.y)
            width: batteryConnectivityDetailShell.visible ? Math.ceil(batteryConnectivityDetailShell.width) : 0
            height: batteryConnectivityDetailShell.visible ? Math.ceil(batteryConnectivityDetailShell.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(audioConnectivityDetailShell.x)
            y: Math.floor(audioConnectivityDetailShell.y)
            width: audioConnectivityDetailShell.visible ? Math.ceil(audioConnectivityDetailShell.width) : 0
            height: audioConnectivityDetailShell.visible ? Math.ceil(audioConnectivityDetailShell.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(topRightComponent.x)
            y: Math.floor(topRightComponent.y)
            width: topRightComponent.visible ? Math.ceil(topRightComponent.width) : 0
            height: topRightComponent.visible ? Math.ceil(topRightComponent.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(topRightTray.x)
            y: Math.floor(topRightTray.y)
            width: topRightTray.visible ? Math.ceil(topRightTray.width) : 0
            height: topRightTray.visible ? Math.ceil(topRightTray.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(topLeftComponent.x)
            y: Math.floor(topLeftComponent.y)
            width: topLeftComponent.visible ? Math.ceil(topLeftComponent.width) : 0
            height: topLeftComponent.visible ? Math.ceil(topLeftComponent.height) : 0
        }
    }
    implicitHeight: 680
    exclusiveZone: 38
    aboveWindows: true
    focusable: root.monitorFocused && (root.overviewVisible || root.connectivityPromptActive || islandContainer.islandState === "launcher" || islandContainer.islandState === "clipboard" || islandContainer.islandState === "emojis" || islandContainer.islandState === "wallpapers" || islandContainer.islandState === "utilities")
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.monitorFocused && (root.overviewVisible || root.connectivityPromptActive || islandContainer.islandState === "launcher" || islandContainer.islandState === "clipboard" || islandContainer.islandState === "emojis" || islandContainer.islandState === "wallpapers" || islandContainer.islandState === "utilities")
        ? ((islandContainer.islandState === "launcher" || islandContainer.islandState === "clipboard" || islandContainer.islandState === "emojis" || islandContainer.islandState === "wallpapers" || islandContainer.islandState === "utilities") ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)
        : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        id: launcherGrab
        active: root.monitorFocused && (islandContainer.islandState === "launcher" || islandContainer.islandState === "clipboard" || islandContainer.islandState === "emojis" || islandContainer.islandState === "wallpapers" || islandContainer.islandState === "utilities")
        windows: [ root ]
        onCleared: {
            if (islandContainer.islandState === "launcher" || islandContainer.islandState === "clipboard" || islandContainer.islandState === "emojis" || islandContainer.islandState === "wallpapers" || islandContainer.islandState === "utilities") {
                islandContainer.smartRestoreState();
            }
        }
    }

    readonly property string iconFontFamily: userConfig.iconFontFamily
    readonly property string textFontFamily: userConfig.textFontFamily
    readonly property string heroFontFamily: userConfig.heroFontFamily
    readonly property string timeFontFamily: userConfig.timeFontFamily
    readonly property string defaultSplitIcon: "\ud83c\udfa7"
    readonly property string notificationStatusIcon: "\uf0f3"
    readonly property real overviewWindowCornerRadius: 12
    readonly property int dynamicIslandAcceptedButtons: userConfig.mouseButtonsMask([
        1,
        userConfig.dynamicIslandPrimaryButton,
        userConfig.dynamicIslandSecondaryButton
    ])
    readonly property bool topGestureInputActive: !root.overviewVisible && islandContainer.canShowSideSwipe
    readonly property real topGestureInputHeight: topGestureInputActive ? root.exclusiveZone : 0
    readonly property real overviewCapsuleWidth: islandContainer.overviewView ? islandContainer.overviewView.width : 760
    readonly property real overviewCapsuleHeight: islandContainer.overviewView ? islandContainer.overviewView.height : 308
    readonly property real overviewCapsuleRadius: islandContainer.overviewView
        ? islandContainer.overviewView.largeWorkspaceRadius + islandContainer.overviewView.outerPadding
        : 44
    readonly property color overviewCapsuleColor: islandContainer.overviewView
        ? islandContainer.overviewView.cardColor
        : StyleTokens.overviewCard
    readonly property color overviewCapsuleBorderColor: islandContainer.overviewView
        ? islandContainer.overviewView.cardBorderColor
        : StyleTokens.overviewBorder
    property bool wifiConnectivityDetailOpen: false
    property bool wifiConnectivityDetailMounted: false
    property bool bluetoothConnectivityDetailOpen: false
    property bool bluetoothConnectivityDetailMounted: false
    property bool batteryConnectivityDetailOpen: false
    property bool batteryConnectivityDetailMounted: false
    property bool audioConnectivityDetailOpen: false
    property bool audioConnectivityDetailMounted: false
    readonly property bool anyConnectivityDetailMounted: wifiConnectivityDetailMounted || bluetoothConnectivityDetailMounted || batteryConnectivityDetailMounted || audioConnectivityDetailMounted
    readonly property real connectivityDetailWidth: 318
    readonly property real connectivityDetailHeight: 404
    readonly property real controlCenterMaximumExtraHeight: controlCenterLoader.item
        ? controlCenterLoader.item.controlCenterMaximumExtraHeight
        : 120
    readonly property real controlCenterWindowHeight: islandContainer.controlCenterLayerVisible
        ? 4 + 350 + root.controlCenterMaximumExtraHeight + 12
        : 0
    readonly property real connectivityDetailGap: 16
    readonly property int connectivityDetailAnimationDuration: 360
    readonly property string overviewWallpaperSource: overviewWallpaperCache.effectiveSource

    function beginOverviewOpening() {
        if (!overviewPreparing) return;
        if (overviewLoader.status !== Loader.Ready || !overviewVisualReady) return;
        overviewPreloading = false;
        overviewPhase = "opening";
        overviewRevealTimer.restart();
    }

    function prepareOverview() {
        if (overviewPhase !== "closed") return;
        overviewUnloadGraceTimer.stop();
        overviewPreloading = true;
        overviewPreloadExpireTimer.restart();
    }

    function cancelPreparedOverview() {
        if (overviewPhase !== "closed") return;
        overviewPreloadExpireTimer.stop();
        overviewPreloading = false;
    }

    function openOverview() {
        if (overviewPhase !== "closed") return;
        overviewUnloadGraceTimer.stop();
        overviewPreloadExpireTimer.stop();
        overviewPreloading = true;
        overviewPhase = "preparing";
        if (overviewLoader.status === Loader.Ready) {
            beginOverviewOpening();
        }
    }

    function closeOverview() {
        if (!overviewMounted) return;
        if (overviewLoader.status === Loader.Ready)
            overviewUnloadGraceTimer.restart();
        overviewRevealTimer.stop();
        overviewPreloadExpireTimer.stop();
        islandContainer.restoreRestingCapsule(true);
        overviewPreloading = false;
        overviewPhase = "closed";
    }

    function closeOverviewEverywhere() {
        if (shellRootController && shellRootController.closeOverviewAll) {
            shellRootController.closeOverviewAll();
            return;
        }

        closeOverview();
    }

    function setConnectivityDetailVisible(kind, open) {
        const nextOpen = !!open;

        if (kind === "wifi") {
            if (nextOpen) {
                wifiConnectivityDetailCleanupTimer.stop();
                wifiConnectivityDetailMounted = true;
                wifiConnectivityDetailOpen = true;
            } else {
                if (!wifiConnectivityDetailMounted && !wifiConnectivityDetailOpen)
                    return;
                wifiConnectivityDetailOpen = false;
                wifiConnectivityDetailCleanupTimer.restart();
            }
            return;
        }

        if (kind === "bluetooth") {
            if (nextOpen) {
                bluetoothConnectivityDetailCleanupTimer.stop();
                bluetoothConnectivityDetailMounted = true;
                bluetoothConnectivityDetailOpen = true;
            } else {
                if (!bluetoothConnectivityDetailMounted && !bluetoothConnectivityDetailOpen)
                    return;
                bluetoothConnectivityDetailOpen = false;
                bluetoothConnectivityDetailCleanupTimer.restart();
            }
            return;
        }

        if (kind === "battery") {
            if (nextOpen) {
                batteryConnectivityDetailCleanupTimer.stop();
                batteryConnectivityDetailMounted = true;
                batteryConnectivityDetailOpen = true;
            } else {
                if (!batteryConnectivityDetailMounted && !batteryConnectivityDetailOpen)
                    return;
                batteryConnectivityDetailOpen = false;
                batteryConnectivityDetailCleanupTimer.restart();
            }
            return;
        }

        if (kind === "audio") {
            if (nextOpen) {
                audioConnectivityDetailCleanupTimer.stop();
                audioConnectivityDetailMounted = true;
                audioConnectivityDetailOpen = true;
            } else {
                if (!audioConnectivityDetailMounted && !audioConnectivityDetailOpen)
                    return;
                audioConnectivityDetailOpen = false;
                audioConnectivityDetailCleanupTimer.restart();
            }
        }
    }

    function closeAllConnectivityDetails() {
        setConnectivityDetailVisible("wifi", false);
        setConnectivityDetailVisible("bluetooth", false);
        setConnectivityDetailVisible("battery", false);
        setConnectivityDetailVisible("audio", false);
    }

    function openOverviewEverywhere() {
        if (shellRootController && shellRootController.openOverviewAll) {
            shellRootController.openOverviewAll();
            return;
        }

        openOverview();
    }

    function prepareOverviewEverywhere() {
        if (shellRootController && shellRootController.prepareOverviewAll) {
            shellRootController.prepareOverviewAll();
            return;
        }

        prepareOverview();
    }

    function cancelPreparedOverviewEverywhere() {
        if (shellRootController && shellRootController.cancelPreparedOverviewAll) {
            shellRootController.cancelPreparedOverviewAll();
            return;
        }

        cancelPreparedOverview();
    }

    function toggleOverviewEverywhere() {
        if (shellRootController && shellRootController.toggleOverviewAll) {
            shellRootController.toggleOverviewAll();
            return;
        }

        if (overviewMounted)
            closeOverviewEverywhere();
        else
            openOverviewEverywhere();
    }

    function prewarmWallpaperCache() {
        overviewWallpaperCache.prewarm();
    }

    function showNotification(appName, summary, body) {
        let displayAppName = appName === "TideBatteryAlert" ? "Battery" : appName;
        notificationHistory.append({
            "appName": displayAppName,
            "summary": summary,
            "body": body,
            "timestamp": new Date().toLocaleTimeString(Qt.locale(), "hh:mm")
        });
        if (notificationHistory.count > 50) {
            notificationHistory.remove(0);
        }
        if (!root.dndActive) {
            islandContainer.showNotificationCapsule(appName, summary, body);
        }
    }

    function toggleControlCenter() {
        islandContainer.handleConfiguredClickAction("toggleControlCenter");
    }

    function setNightLightTemp(value) {
        if (controlCenterLoader.item) {
            controlCenterLoader.item.queueTemp(value);
        }
    }

    function toggleLauncher() {
        islandContainer.toggleLauncher();
    }

    function toggleUtilities() {
        islandContainer.toggleUtilities();
    }

    function toggleClipboard() {
        islandContainer.toggleClipboard();
    }

    function toggleEmojis() {
        islandContainer.toggleEmojis();
    }

    function toggleWallpapers() {
        islandContainer.toggleWallpapers();
    }

    onOverviewVisibleChanged: {
        if (overviewVisible && monitorFocused) overviewFocusTimer.restart();
    }
    onConnectivityPromptActiveChanged: {
        if (connectivityPromptActive && monitorFocused)
            connectivityPromptFocusTimer.restart();
    }
    onLauncherLayerVisibleChanged: {
        if (launcherLayerVisible && monitorFocused)
            launcherFocusTimer.restart();
    }
    onClipboardLayerVisibleChanged: {
        if (clipboardLayerVisible && monitorFocused)
            clipboardFocusTimer.restart();
    }
    onEmojiPickerLayerVisibleChanged: {
        if (emojiPickerLayerVisible && monitorFocused)
            emojisFocusTimer.restart();
    }
    onWallpapersLayerVisibleChanged: {
        if (wallpapersLayerVisible && monitorFocused)
            wallpapersFocusTimer.restart();
    }
    onUtilitiesLayerVisibleChanged: {
        if (utilitiesLayerVisible) {
            if (utilitiesSwipeLoader.item) {
                utilitiesSwipeLoader.item.selectedIdx = 0;
                utilitiesSwipeLoader.item.forceActiveFocus();
            }
        }
        if (utilitiesLayerVisible && monitorFocused)
            utilitiesFocusTimer.restart();
    }
    onOverviewVisualReadyChanged: {
        if (overviewVisualReady) beginOverviewOpening();
    }
    onMonitorFocusedChanged: {
        if (overviewVisible && monitorFocused) overviewFocusTimer.restart();
        if (connectivityPromptActive && monitorFocused) connectivityPromptFocusTimer.restart();
        if (launcherLayerVisible && monitorFocused) launcherFocusTimer.restart();
        if (clipboardLayerVisible && monitorFocused) clipboardFocusTimer.restart();
        if (emojiPickerLayerVisible && monitorFocused) emojisFocusTimer.restart();
        if (wallpapersLayerVisible && monitorFocused) wallpapersFocusTimer.restart();
        if (utilitiesLayerVisible && monitorFocused) utilitiesFocusTimer.restart();
    }

    Timer {
        id: overviewFocusTimer
        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: connectivityPromptFocusTimer
        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: launcherFocusTimer
        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: clipboardFocusTimer
        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: emojisFocusTimer
        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: wallpapersFocusTimer
        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: utilitiesFocusTimer
        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: overviewRevealTimer
        interval: 0
        repeat: false
        onTriggered: {
            if (root.overviewPhase === "opening") root.overviewPhase = "open";
        }
    }

    Timer {
        id: overviewPreloadExpireTimer
        interval: 1200
        repeat: false
        onTriggered: {
            if (root.overviewPhase === "closed")
                root.overviewPreloading = false;
        }
    }

    Timer {
        id: overviewUnloadGraceTimer
        interval: 260
        repeat: false
    }

    Timer {
        id: wifiConnectivityDetailCleanupTimer
        interval: root.connectivityDetailAnimationDuration
        repeat: false
        onTriggered: root.wifiConnectivityDetailMounted = false
    }

    Timer {
        id: bluetoothConnectivityDetailCleanupTimer
        interval: root.connectivityDetailAnimationDuration
        repeat: false
        onTriggered: root.bluetoothConnectivityDetailMounted = false
    }

    Timer {
        id: batteryConnectivityDetailCleanupTimer
        interval: root.connectivityDetailAnimationDuration
        repeat: false
        onTriggered: root.batteryConnectivityDetailMounted = false
    }

    Timer {
        id: audioConnectivityDetailCleanupTimer
        interval: root.connectivityDetailAnimationDuration
        repeat: false
        onTriggered: root.audioConnectivityDetailMounted = false
    }

    OverviewWallpaperCacheController {
        id: overviewWallpaperCache

        active: root.overviewLoaderActive
        wallpaperPath: userConfig.wallpaperPath
        hyprMonitor: root.hyprMonitor
        screenObject: root.screen
    }

    IslandClock {
        id: timeObj
    }

    // IslandRootGestureArea {
    //     anchors.fill: parent
    //     enabled: root.topGestureInputActive
    //     islandController: islandContainer
    //     capsule: mainCapsule
    // }

    // --- 灵动岛主容器与全局状态 ---
    FocusScope {
        id: islandContainer
        anchors.fill: parent
        focus: root.monitorFocused && (root.overviewVisible || root.connectivityPromptActive || islandState === "launcher" || islandState === "clipboard" || islandState === "emojis" || islandState === "wallpapers" || islandState === "utilities")

        property string islandState: "normal"
        property string splitIcon: root.defaultSplitIcon
        property real osdProgress: -1.0
        property bool osdProgressAnimationEnabled: true
        property string osdCustomText: ""
        property int currentWs: root.currentMonitorWorkspaceId > 0 ? root.currentMonitorWorkspaceId : 1
        readonly property int batteryCapacity: systemState.batteryCapacity
        readonly property bool isCharging: systemState.isCharging
        readonly property real currentVolume: systemState.currentVolume
        readonly property bool isMuted: systemState.isMuted
        readonly property real currentBrightness: systemState.currentBrightness
        readonly property real currentCpuUsage: systemState.currentCpuUsage
        readonly property real currentRamUsage: systemState.currentRamUsage
        property string notificationAppName: ""
        property string notificationSummary: ""
        property string notificationBody: ""
        property var bluetoothExpandedDevice: null
        readonly property var cavaLevels: systemState.cavaLevels
        property real swipeTransitionProgress: 0
        property string workspaceOriginSide: "none"
        property string splitOriginSide: "none"
        property string restingState: "normal"
        property bool expandedByPlayerAutoOpen: false
        property real customCapsuleWidth: 220
        property real lyricsCapsuleWidth: 220
        property real utilitiesCapsuleWidth: 614
        property bool sideSwipeSettling: false
        readonly property int defaultAutoHideInterval: 1250
        readonly property int notificationAutoHideInterval: 4200
        readonly property int bluetoothExpandedAutoHideInterval: 2500
        readonly property int swipeAnimationDuration: 220
        readonly property bool blocksTransientSplit: islandState === "expanded"
            || islandState === "bluetooth_expanded"
            || islandState === "control_center"
            || islandState === "notification"
            || islandState === "launcher"
            || islandState === "clipboard"
            || islandState === "emojis"
            || islandState === "wallpapers"
            || islandState === "utilities"
        readonly property bool splitShowsProgress: islandState === "split" && osdProgress >= 0
        readonly property bool splitShowsText: islandState === "split" && osdProgress < 0 && osdCustomText !== ""
        readonly property bool splitShowsIconOnly: islandState === "split" && osdProgress < 0 && osdCustomText === ""
        readonly property bool splitUsesExtendedLayout: splitShowsProgress || splitShowsText
        readonly property real splitCapsuleWidth: splitShowsProgress ? 248 : (splitShowsText ? 220 : 140)
        readonly property bool canShowSideSwipe: false
        readonly property real rightSwipeProgress: Math.max(0, swipeTransitionProgress)
        readonly property var customLeftItems: systemState.customLeftItems
        readonly property bool hasCustomLeftItems: systemState.hasCustomLeftItems
        readonly property bool customSwipeVisible: !root.overviewVisible
            && hasCustomLeftItems
            && (
                capsuleMouseArea.sideSwipeInteractive
                ? swipeTransitionProgress < 0
                : (
                    islandState === "custom"
                    || (islandState === "normal" && swipeTransitionProgress < 0)
                    || (islandState === "split" && splitOriginSide === "left")
                    || (islandState === "long_capsule"
                        && (workspaceOriginSide === "left" || swipeTransitionProgress < 0))
                )
            )
        readonly property bool lyricsSwipeVisible: !root.overviewVisible && islandState === "lyrics"
        readonly property bool utilitiesSwipeVisible: !root.overviewVisible && (
            capsuleMouseArea.sideSwipeInteractive
            ? swipeTransitionProgress >= 0
            : (
                islandState === "utilities"
                || (islandState === "normal" && swipeTransitionProgress >= 0)
                || (islandState === "split" && splitOriginSide === "right")
                || (islandState === "long_capsule"
                    && (workspaceOriginSide === "right" || swipeTransitionProgress > 0))
            )
        )
        readonly property bool expandedLayerVisible: !root.overviewVisible && islandState === "expanded"
        readonly property bool bluetoothExpandedLayerVisible: !root.overviewVisible && islandState === "bluetooth_expanded"
        readonly property bool notificationLayerVisible: !root.overviewVisible && islandState === "notification"
        readonly property bool controlCenterLayerVisible: !root.overviewVisible && islandState === "control_center"
        readonly property var activePlayer: mediaController.activePlayer
        readonly property string lyricsDisplayText: mediaController.displayText
        readonly property string currentTrack: mediaController.currentTrack
        readonly property string currentArtist: mediaController.currentArtist
        readonly property string currentArtUrl: mediaController.currentArtUrl
        readonly property real trackProgress: mediaController.trackProgress
        readonly property string timePlayed: mediaController.timePlayed
        readonly property string timeTotal: mediaController.timeTotal
        readonly property bool screenRecordingActive: root.screenRecordingActive
        readonly property var bluetoothDevices: bluetoothConnectionTracker.devices
        readonly property var overviewView: overviewLoader.item && overviewLoader.item.overviewView
            ? overviewLoader.item.overviewView
            : null

        onControlCenterLayerVisibleChanged: {
            if (!controlCenterLayerVisible) {
                if (controlCenterLoader.item)
                    controlCenterLoader.item.closeConnectivityPanels();
                else
                    root.closeAllConnectivityDetails();
            }
        }

        onCustomLeftItemsChanged: {
            if (restingState === "custom" && !hasCustomLeftItems) {
                restingState = "normal";

                if (islandState === "custom"
                        || (islandState === "split" && splitOriginSide === "left")
                        || (islandState === "long_capsule" && workspaceOriginSide === "left")) {
                    restoreRestingCapsule(true);
                } else {
                    applyRestingVisuals();
                }
            } else if (restingState === "custom") {
                syncCustomCapsuleWidth();
            }
        }

        IslandMprisController {
            id: mediaController

            expanded: islandContainer.islandState === "expanded"
        }

        BluetoothConnectionTracker {
            id: bluetoothConnectionTracker

            onAdapterChanged: islandContainer.bluetoothExpandedDevice = null

            onNewConnection: function(device) {
                islandContainer.showBluetoothExpanded(device);
            }
        }

        IslandSystemState {
            id: systemState

            configuredLeftSwipeItems: userConfig.dynamicIslandLeftSwipeItems
            timeText: timeObj.currentTime
            dateText: timeObj.currentDateLabel
            currentWorkspace: islandContainer.currentWs
            customSwipeActive: customSwipeLoader.active
            topRightVisualizerActive: topRightComponent.musicPlaying

            onTransientRequested: function(icon, progress, text) {
                islandContainer.showTransientCapsule(icon, progress, text);
            }

            onBatteryNotificationRequested: function(summary, body) {
                if (root.shellRootController) {
                    root.shellRootController.showNotificationAll("TideBatteryAlert", summary, body);
                } else {
                    root.showNotification("TideBatteryAlert", summary, body);
                }
            }
        }

        HyprlandWorkspaceTracker {
            id: workspaceTracker

            hyprMonitor: root.hyprMonitor
            monitorName: root.hyprMonitorName
            monitorFocused: root.monitorFocused

            onWorkspaceSynced: function(workspaceId) {
                islandContainer.currentWs = workspaceId;
            }

            onWorkspaceActivated: function(workspaceId) {
                islandContainer.showWorkspaceCapsule(workspaceId);
            }
        }

        Behavior on osdProgress {
            enabled: islandContainer.osdProgressAnimationEnabled

            NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
        }
        Behavior on swipeTransitionProgress {
            NumberAnimation {
                duration: capsuleMouseArea.sideSwipeInteractive ? 0 : islandContainer.swipeAnimationDuration
                easing.type: Easing.OutCubic
            }
        }

        Keys.onPressed: (event) => {
            if (!root.overviewVisible) return;

            if ((event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) || event.key === Qt.Key_Backtab) {
                hyprDispatch.focusWorkspace("r-1");
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab) {
                hyprDispatch.focusWorkspace("r+1");
                event.accepted = true;
            }
        }

        function handleConfiguredClickAction(actionName) {
            switch (actionName) {
            case "":
            case "none":
                return;
            case "toggleExpandedPlayer":
                if (islandState === "expanded") {
                    autoHideTimer.stop();
                    smartRestoreState();
                } else {
                    showExpandedPlayer(false);
                }
                return;
            case "openExpandedPlayer":
                showExpandedPlayer(false);
                return;
            case "closeExpandedPlayer":
                if (islandState === "expanded")
                    smartRestoreState();
                return;
            case "toggleControlCenter":
                if (islandState === "control_center")
                    smartRestoreState();
                else
                    showControlCenter();
                return;
            case "openControlCenter":
                showControlCenter();
                return;
            case "closeControlCenter":
                if (islandState === "control_center")
                    smartRestoreState();
                return;
            case "toggleLauncher":
                if (islandState === "launcher")
                    smartRestoreState();
                else
                    showLauncher();
                return;
            case "openLauncher":
                showLauncher();
                return;
            case "closeLauncher":
                if (islandState === "launcher")
                    smartRestoreState();
                return;
            case "toggleClipboard":
                if (islandState === "clipboard")
                    smartRestoreState();
                else
                    showClipboard();
                return;
            case "openClipboard":
                showClipboard();
                return;
            case "closeClipboard":
                if (islandState === "clipboard")
                    smartRestoreState();
                return;
            case "toggleEmojis":
                if (islandState === "emojis")
                    smartRestoreState();
                else
                    showEmojis();
                return;
            case "openEmojis":
                showEmojis();
                return;
            case "closeEmojis":
                if (islandState === "emojis")
                    smartRestoreState();
                return;
            case "toggleWallpapers":
                if (islandState === "wallpapers")
                    smartRestoreState();
                else
                    showWallpapers();
                return;
            case "openWallpapers":
                showWallpapers();
                return;
            case "closeWallpapers":
                if (islandState === "wallpapers")
                    smartRestoreState();
                return;
            case "toggleOverview":
                root.toggleOverviewEverywhere();
                return;
            case "openOverview":
                root.openOverviewEverywhere();
                return;
            case "closeOverview":
                root.closeOverviewEverywhere();
                return;
            case "toggleLyrics":
                if (restingState === "lyrics")
                    showTimeCapsule();
                else
                    showLyricsCapsule();
                return;
            case "showLyrics":
                showLyricsCapsule();
                return;
            case "showTime":
                showTimeCapsule();
                return;
            case "restoreRestingCapsule":
                smartRestoreState();
                return;
            default:
            }
        }

        function clamp01(value) {
            return Math.max(0, Math.min(1, value));
        }

        function normalizeRestingState(nextState) {
            if (nextState === "lyrics") return "normal";
            if (nextState === "custom" && hasCustomLeftItems) return "custom";
            if (nextState === "utilities") return "utilities";
            return "normal";
        }

        function restingStateProgress(nextState) {
            switch (normalizeRestingState(nextState)) {
            case "custom":
                return -1;
            case "lyrics":
                return 1;
            case "utilities":
                return 1;
            default:
                return 0;
            }
        }

        function restingStateSide(nextState) {
            switch (normalizeRestingState(nextState)) {
            case "custom":
                return "left";
            case "lyrics":
                return "right";
            case "utilities":
                return "right";
            default:
                return "none";
            }
        }

        function swipeRestProgressForState() {
            switch (islandState) {
            case "custom":
                return -1;
            case "lyrics":
                return 1;
            case "utilities":
                return 1;
            default:
                return 0;
            }
        }

        function currentTransientOriginSide() {
            switch (islandState) {
            case "custom":
                return "left";
            case "lyrics":
                return "right";
            case "utilities":
                return "right";
            case "long_capsule":
                return workspaceOriginSide;
            case "split":
                return splitOriginSide;
            default:
                return "none";
            }
        }

        function setOsdProgress(nextProgress, animate) {
            osdProgressAnimationReset.stop();
            osdProgressAnimationEnabled = animate;
            osdProgress = nextProgress;
            if (!animate) osdProgressAnimationReset.restart();
        }

        function abortSideTransientMode() {
            sideTransientRestoreTimer.stop();
            workspaceOriginSide = "none";
            splitOriginSide = "none";
        }

        function clearTransientCapsule() {
            setOsdProgress(-1.0, false);
            osdCustomText = "";
            notificationAppName = "";
            notificationSummary = "";
            notificationBody = "";
            bluetoothExpandedDevice = null;
        }

        function cleanNotificationText(text) {
            return String(text === undefined || text === null ? "" : text)
                .replace(/<[^>]*>/g, " ")
                .replace(/&nbsp;/g, " ")
                .replace(/&amp;/g, "&")
                .replace(/&quot;/g, "\"")
                .replace(/&lt;/g, "<")
                .replace(/&gt;/g, ">")
                .replace(/\s+/g, " ")
                .trim();
        }

        function prepareRestingCapsuleGeometry() {
            if (restingState === "custom")
                syncCustomCapsuleWidth();
            if (restingState === "lyrics")
                syncLyricsCapsuleWidth();
            if (restingState === "utilities")
                syncUtilitiesCapsuleWidth();
        }

        function applyRestingVisuals() {
            prepareRestingCapsuleGeometry();
            swipeTransitionProgress = restingStateProgress(restingState);
        }

        function sideSwipeRestProgressForProgress(progressValue) {
            if (progressValue <= -0.5) return -1;
            if (progressValue >= 0.5) return 1;
            return 0;
        }

        function sideSwipeRestWidthForProgress(progressValue) {
            if (progressValue <= -0.5) return customCapsuleWidth;
            if (progressValue >= 0.5) return utilitiesCapsuleWidth;
            return 140;
        }

        function customSideSwipeDragDistance() {
            const view = customSwipeLoader.item;
            if (view && view.dragDistance > 0) return view.dragDistance;
            return Math.max(140, customCapsuleWidth + 4);
        }

        function lyricsSideSwipeDragDistance() {
            const view = lyricsSwipeLoader.item;
            if (view && view.dragDistance > 0) return view.dragDistance;
            return Math.max(140, lyricsCapsuleWidth + 2);
        }

        function utilitiesSideSwipeDragDistance() {
            const view = utilitiesSwipeLoader.item;
            if (view && view.dragDistance > 0) return view.dragDistance;
            return Math.max(140, utilitiesCapsuleWidth + 2);
        }

        function sideSwipeDragDistanceForDirection(direction) {
            if (direction === "left") return customSideSwipeDragDistance();
            if (direction === "right") return utilitiesSideSwipeDragDistance();
            return 140;
        }

        function advanceSideSwipeProgress(currentProgress, deltaX) {
            const minProgress = 0;
            const maxProgress = 1;
            let nextProgress = Math.max(minProgress, Math.min(maxProgress, currentProgress));
            let remainingDelta = deltaX;

            if (remainingDelta > 0) {
                if (remainingDelta > 0 && nextProgress >= 0 && nextProgress < maxProgress) {
                    const rightDistance = Math.max(1, sideSwipeDragDistanceForDirection("right"));
                    nextProgress = Math.min(maxProgress, nextProgress + remainingDelta / rightDistance);
                }
            } else if (remainingDelta < 0) {
                if (nextProgress > 0) {
                    const rightDistance = Math.max(1, sideSwipeDragDistanceForDirection("right"));
                    const progressToCenter = Math.min(nextProgress, -remainingDelta / rightDistance);
                    nextProgress -= progressToCenter;
                    remainingDelta += progressToCenter * rightDistance;
                }
            }

            return Math.max(minProgress, Math.min(maxProgress, nextProgress));
        }

        function resolveSideSwipeSettle(startProgress, finalProgress) {
            let settleAction = "";
            let settleProgress = sideSwipeRestProgressForProgress(startProgress);
            let settleWidth = sideSwipeRestWidthForProgress(startProgress);

            if (finalProgress >= 0.56) {
                settleAction = "utilities";
                settleProgress = 1;
                settleWidth = utilitiesCapsuleWidth;
            } else if (startProgress >= 0.5) {
                if (finalProgress <= 0.44) {
                    settleAction = "time";
                    settleProgress = 0;
                    settleWidth = 140;
                }
            } else {
                settleAction = "time";
                settleProgress = 0;
                settleWidth = 140;
            }

            return {
                action: settleAction,
                progress: settleProgress,
                width: settleWidth
            };
        }

        function beginSideSwipeSettle(targetWidth) {
            sideSwipeSettling = true;
            mainCapsule.displayedWidth = targetWidth;
            sideSwipeSettleReset.restart();
        }

        function cancelSideSwipeSettle() {
            sideSwipeSettleReset.stop();
            sideSwipeSettling = false;
        }

        function finishSideSwipeSettle() {
            sideSwipeSettling = false;
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
        }

        function restartAutoHideTimer(duration) {
            autoHideTimer.interval = duration === undefined ? defaultAutoHideInterval : duration;
            autoHideTimer.restart();
        }

        function stopAutoHideTimer() {
            autoHideTimer.stop();
            autoHideTimer.interval = defaultAutoHideInterval;
        }

        function showTransientCapsule(icon, progress, customText) {
            if (progress === undefined)    progress = -1.0;
            if (customText === undefined)  customText = "";

            if (blocksTransientSplit) return;

            const nextProgress = progress >= 0 ? progress : -1.0;
            const animateProgress = islandState === "split" && osdProgress >= 0 && nextProgress >= 0;
            const animateFromSide = currentTransientOriginSide();

            abortSideTransientMode();
            splitIcon = icon;
            osdCustomText = customText;
            setOsdProgress(nextProgress, animateProgress);
            splitOriginSide = animateFromSide;
            islandState = "split";
            swipeTransitionProgress = 0;
            restartAutoHideTimer();
        }

        function showNotificationCapsule(appName, summary, body) {
            if (root.overviewVisible || islandState === "control_center" || islandState === "expanded" || islandState === "launcher" || islandState === "clipboard" || islandState === "emojis" || islandState === "wallpapers") return;

            let displayAppName = appName === "TideBatteryAlert" ? "Battery" : appName;
            const cleanedAppName = cleanNotificationText(displayAppName);
            const cleanedSummary = cleanNotificationText(summary);
            const cleanedBody = cleanNotificationText(body);
            const resolvedSummary = cleanedSummary !== ""
                ? cleanedSummary
                : (cleanedBody !== "" ? cleanedBody : "New notification");

            abortSideTransientMode();
            clearTransientCapsule();
            notificationAppName = cleanedAppName !== "" ? cleanedAppName : "Notification";
            notificationSummary = resolvedSummary;
            notificationBody = cleanedSummary !== "" ? cleanedBody : "";
            islandState = "notification";
            restartAutoHideTimer(notificationAutoHideInterval);
        }

        function suppressCapsuleClick() {
            capsuleMouseArea.suppressNextClick = true;
            swipeSuppressReset.restart();
        }

        function restoreRestingCapsule(forceImmediate) {
            if (forceImmediate === undefined) forceImmediate = false;
            const normalizedRestingState = normalizeRestingState(restingState);
            const targetSide = restingStateSide(normalizedRestingState);
            const shouldAnimateToSide = targetSide !== "none"
                && ((islandState === "long_capsule" && workspaceOriginSide === targetSide)
                    || (islandState === "split" && splitOriginSide === targetSide));

            if (!forceImmediate && shouldAnimateToSide) {
                expandedByPlayerAutoOpen = false;
                prepareRestingCapsuleGeometry();
                swipeTransitionProgress = restingStateProgress(normalizedRestingState);
                stopAutoHideTimer();
                sideTransientRestoreTimer.restart();
                return;
            }

            abortSideTransientMode();
            prepareRestingCapsuleGeometry();
            islandState = normalizedRestingState;
            clearTransientCapsule();
            applyRestingVisuals();
            expandedByPlayerAutoOpen = false;
            stopAutoHideTimer();
        }

        function setRestingState(nextState) {
            restingState = normalizeRestingState(nextState);
        }

        function smartRestoreState() {
            restoreRestingCapsule();
        }

        function showRestingCapsule(nextState) {
            setRestingState(nextState);
            restoreRestingCapsule();
            stopAutoHideTimer();
        }

        function showExpandedPlayer(autoOpened) {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "expanded";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            expandedByPlayerAutoOpen = autoOpened;
            if (autoOpened) restartAutoHideTimer();
            else stopAutoHideTimer();
        }

        function showBluetoothExpanded(device) {
            if (!device || root.overviewVisible || islandState === "control_center" || islandState === "notification" || islandState === "launcher" || islandState === "clipboard" || islandState === "emojis" || islandState === "wallpapers")
                return;

            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            bluetoothExpandedDevice = device;
            islandState = "bluetooth_expanded";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            expandedByPlayerAutoOpen = false;
            restartAutoHideTimer(bluetoothExpandedAutoHideInterval);
        }

        function showControlCenter() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "control_center";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function showLauncher() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "launcher";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function toggleLauncher() {
            if (islandState === "launcher")
                smartRestoreState();
            else
                showLauncher();
        }

        function showClipboard() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "clipboard";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function toggleClipboard() {
            if (islandState === "clipboard")
                smartRestoreState();
            else
                showClipboard();
        }

        function showEmojis() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "emojis";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function toggleEmojis() {
            if (islandState === "emojis")
                smartRestoreState();
            else
                showEmojis();
        }

        function showWallpapers() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "wallpapers";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function toggleWallpapers() {
            if (islandState === "wallpapers")
                smartRestoreState();
            else
                showWallpapers();
        }

        function showUtilities() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "utilities";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function toggleUtilities() {
            if (islandState === "utilities")
                smartRestoreState();
            else
                showUtilities();
        }

        function showCustomCapsule() {
            if (!hasCustomLeftItems) {
                showTimeCapsule();
                return;
            }

            systemState.refreshMissingValues();
            showRestingCapsule("custom");
        }

        function showLyricsCapsule() {
            showRestingCapsule("lyrics");
        }

        function showUtilitiesCapsule() {
            showRestingCapsule("utilities");
        }

        function showTimeCapsule() {
            showRestingCapsule("normal");
        }

        function closeUtilitiesInstantly() {
            const oldDuration = mainCapsule.morphDuration;
            mainCapsule.morphDuration = 0;
            showTimeCapsule();
            Qt.callLater(() => {
                mainCapsule.morphDuration = oldDuration;
            });
        }

        function showWorkspaceCapsule(wsId) {
            currentWs = wsId;
            if (islandState === "control_center" || islandState === "notification" || islandState === "launcher" || islandState === "clipboard" || islandState === "emojis" || islandState === "wallpapers") return;
            const animateFromSide = currentTransientOriginSide();
            clearTransientCapsule();
            sideTransientRestoreTimer.stop();
            workspaceOriginSide = animateFromSide;
            splitOriginSide = "none";
            islandState = "long_capsule";
            swipeTransitionProgress = 0;
            restartAutoHideTimer();
        }

        Timer { id: autoHideTimer; interval: islandContainer.defaultAutoHideInterval; onTriggered: islandContainer.smartRestoreState() }
        Timer {
            id: osdProgressAnimationReset
            interval: 0
            onTriggered: islandContainer.osdProgressAnimationEnabled = true
        }
        Timer {
            id: sideTransientRestoreTimer
            interval: islandContainer.swipeAnimationDuration
            onTriggered: {
                islandContainer.workspaceOriginSide = "none";
                islandContainer.splitOriginSide = "none";
                islandContainer.prepareRestingCapsuleGeometry();
                islandContainer.islandState = islandContainer.normalizeRestingState(islandContainer.restingState);
                islandContainer.clearTransientCapsule();
                islandContainer.applyRestingVisuals();
                islandContainer.expandedByPlayerAutoOpen = false;
            }
        }
        Timer {
            id: sideSwipeSettleReset
            interval: mainCapsule.morphDuration
            onTriggered: islandContainer.finishSideSwipeSettle()
        }

        function syncCustomCapsuleWidth() {
            const view = customSwipeLoader.item;
            if (!view) return;
            customCapsuleWidth = Math.max(220, Math.min(root.width - 48, view.preferredWidth));
        }

        function syncLyricsCapsuleWidth() {
            const view = lyricsSwipeLoader.item;
            if (!view) return;
            lyricsCapsuleWidth = Math.max(220, Math.min(root.width - 48, view.preferredWidth));
        }

        function syncUtilitiesCapsuleWidth() {
            const view = utilitiesSwipeLoader.item;
            if (!view) return;
            utilitiesCapsuleWidth = Math.max(220, Math.min(root.width - 48, view.preferredWidth));
        }

        onCurrentTrackChanged: {
            if (currentTrack !== ""
                    && islandState !== "control_center"
                    && islandState !== "notification"
                    && islandState !== "bluetooth_expanded"
                    && islandState !== "launcher"
                    && islandState !== "clipboard"
                    && islandState !== "emojis"
                    && islandState !== "wallpapers") {
                if (islandState === "expanded" && !expandedByPlayerAutoOpen) return;
                showExpandedPlayer(true);
            }
        }

        // --- UI 渲染：灵动岛主干 ---
        Rectangle {
            id: mainCapsule
            z: 5
            property int morphDuration: 400
            property real outlineWidth: root.overviewContentVisible ? 1 : 0
            property color outlineColor: root.overviewContentVisible ? root.overviewCapsuleBorderColor : StyleTokens.clearBlack
            property real displayedWidth: baseTargetWidth
            readonly property real baseTargetWidth: {
                if (root.overviewVisible) return root.overviewCapsuleWidth;
                if (sideTransientRestoreTimer.running) {
                    if (islandContainer.restingState === "lyrics"
                            && ((islandContainer.islandState === "split" && islandContainer.splitOriginSide === "right")
                                || (islandContainer.islandState === "long_capsule" && islandContainer.workspaceOriginSide === "right"))) {
                        return islandContainer.lyricsCapsuleWidth;
                    }

                    if (islandContainer.restingState === "utilities"
                            && ((islandContainer.islandState === "split" && islandContainer.splitOriginSide === "right")
                                || (islandContainer.islandState === "long_capsule" && islandContainer.workspaceOriginSide === "right"))) {
                        return islandContainer.utilitiesCapsuleWidth;
                    }

                    if (islandContainer.restingState === "custom"
                            && ((islandContainer.islandState === "split" && islandContainer.splitOriginSide === "left")
                                || (islandContainer.islandState === "long_capsule" && islandContainer.workspaceOriginSide === "left"))) {
                        return islandContainer.customCapsuleWidth;
                    }
                }

                switch (islandContainer.islandState) {
                case "split":
                    return islandContainer.splitCapsuleWidth;
                case "long_capsule":
                    return 220;
                case "custom":
                    return islandContainer.customCapsuleWidth;
                case "lyrics":
                    return islandContainer.lyricsCapsuleWidth;
                case "utilities":
                    return islandContainer.utilitiesCapsuleWidth;
                case "control_center":
                    return 540;
                case "launcher":
                case "clipboard":
                case "emojis":
                case "wallpapers":
                    return 680;
                case "expanded":
                case "bluetooth_expanded":
                    return 400;
                case "notification":
                    if (!notificationLoader.item) return 272;
                    return Math.max(
                        notificationLoader.item.minimumWidth,
                        Math.min(notificationLoader.item.maximumWidth, notificationLoader.item.preferredWidth)
                    );
                default:
                    return 140;
                }
            }
            readonly property real targetHeight: {
                if (root.overviewVisible) return root.overviewCapsuleHeight;

                // Dynamic height scaling during swiping/settling towards utilities
                if (capsuleMouseArea.sideSwipeInteractive && islandContainer.swipeTransitionProgress > 0) {
                    return 35 + (84 - 35) * islandContainer.clamp01(islandContainer.swipeTransitionProgress);
                }
                if (islandContainer.sideSwipeSettling && islandContainer.swipeTransitionProgress > 0) {
                    return 35 + (84 - 35) * islandContainer.clamp01(islandContainer.swipeTransitionProgress);
                }

                switch (islandContainer.islandState) {
                case "control_center":
                    return 350 + (controlCenterLoader.item ? controlCenterLoader.item.controlCenterExtraHeight : 32);
                case "launcher":
                case "clipboard":
                case "emojis":
                case "wallpapers":
                    return 420;
                case "expanded":
                case "bluetooth_expanded":
                    return 165;
                case "notification":
                    return notificationLoader.item
                        ? Math.max(56, Math.min(68, notificationLoader.item.preferredHeight))
                        : 56;
                case "utilities":
                    return 84;
                default:
                    return 35;
                }
            }
            readonly property real targetRadius: {
                if (root.overviewVisible) return root.overviewCapsuleRadius;

                // Dynamic radius scaling during swiping/settling towards utilities
                if (capsuleMouseArea.sideSwipeInteractive && islandContainer.swipeTransitionProgress > 0) {
                    return 19 + (24 - 19) * islandContainer.clamp01(islandContainer.swipeTransitionProgress);
                }
                if (islandContainer.sideSwipeSettling && islandContainer.swipeTransitionProgress > 0) {
                    return 19 + (24 - 19) * islandContainer.clamp01(islandContainer.swipeTransitionProgress);
                }

                switch (islandContainer.islandState) {
                case "control_center":
                case "launcher":
                case "clipboard":
                case "emojis":
                case "wallpapers":
                    return 34;
                case "expanded":
                case "bluetooth_expanded":
                    return 40;
                case "notification":
                    return mainCapsule.targetHeight / 2;
                case "utilities":
                    return 24;
                default:
                    return 19;
                }
            }
            function sideSwipeWidthForProgress(progressValue) {
                if (progressValue < 0)
                    return 140 + (islandContainer.customCapsuleWidth - 140)
                        * islandContainer.clamp01(-progressValue);
                if (progressValue > 0)
                    return 140 + (islandContainer.utilitiesCapsuleWidth - 140)
                        * islandContainer.clamp01(progressValue);
                return 140;
            }
            readonly property real sideSwipePreviewWidth: mainCapsule.sideSwipeWidthForProgress(
                islandContainer.swipeTransitionProgress
            )
            color: root.overviewContentVisible ? root.overviewCapsuleColor : StyleTokens.black
            y: 4
            anchors.horizontalCenter: parent.horizontalCenter
            clip: true
            width: displayedWidth
            height: targetHeight
            radius: targetRadius

            onBaseTargetWidthChanged: {
                if (!capsuleMouseArea.sideSwipeInteractive && !islandContainer.sideSwipeSettling)
                    displayedWidth = baseTargetWidth;
            }

            Behavior on displayedWidth  {
                NumberAnimation {
                    duration: capsuleMouseArea.sideSwipeInteractive ? 0 : mainCapsule.morphDuration
                    easing.type: Easing.OutQuint
                }
            }
            Behavior on height {
                enabled: !(controlCenterLoader.item && controlCenterLoader.item.batteryDrawerMoving)

                NumberAnimation {
                    duration: capsuleMouseArea.sideSwipeInteractive ? 0 : mainCapsule.morphDuration
                    easing.type: Easing.OutQuint
                }
            }
            Behavior on radius { NumberAnimation { duration: mainCapsule.morphDuration; easing.type: Easing.OutQuint } }
            Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.InOutQuad } }
            Behavior on outlineWidth { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            Behavior on outlineColor { ColorAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            border.width: outlineWidth
            border.color: outlineColor

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(parent.radius - 1, 0)
                color: StyleTokens.transparent
                border.width: 1
                border.color: StyleTokens.overviewInnerBorder
                opacity: root.overviewContentVisible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.overviewContentVisible ? 260 : 140
                        easing.type: Easing.InOutQuad
                    }
                }
            }


            MouseArea {
                id: capsuleMouseArea
                anchors.fill: parent
                z: -1
                enabled: !root.overviewVisible && twoFingerTouchArea.touchPoints.length < 2
                acceptedButtons: root.dynamicIslandAcceptedButtons
                preventStealing: true
                property real swipeStartX: 0
                property real swipeStartY: 0
                property real swipeStartProgress: 0
                property real swipeLastX: 0
                readonly property real sideSwipeVerticalTolerance: 24
                property bool swipeArmed: false
                property bool swipeMoved: false
                property bool sideSwipeInteractive: false
                property bool suppressNextClick: false
                property bool preparedOverviewOnPress: false

                Timer {
                    id: swipeSuppressReset
                    interval: 180
                    repeat: false
                    onTriggered: capsuleMouseArea.suppressNextClick = false
                }

                onPressed: (mouse) => {
                    const mappedPoint = capsuleMouseArea.mapToItem(islandContainer, mouse.x, mouse.y);
                    swipeStartX = mappedPoint.x;
                    swipeStartY = mappedPoint.y;
                    islandContainer.cancelSideSwipeSettle();
                    swipeArmed = mouse.button === Qt.LeftButton
                        && islandContainer.canShowSideSwipe;
                    swipeStartProgress = islandContainer.swipeTransitionProgress;
                    swipeLastX = mappedPoint.x;
                    swipeMoved = false;
                    sideSwipeInteractive = swipeArmed;
                    islandContainer.swipeTransitionProgress = swipeStartProgress;

                    let pressedAction = "";
                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton)) {
                        pressedAction = userConfig.dynamicIslandPrimaryAction;
                    } else if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSecondaryButton)) {
                        pressedAction = userConfig.dynamicIslandSecondaryAction;
                    }

                    preparedOverviewOnPress = pressedAction === "openOverview"
                        || (pressedAction === "toggleOverview" && root.overviewPhase === "closed");
                    if (preparedOverviewOnPress)
                        root.prepareOverviewEverywhere();
                }

                onPositionChanged: (mouse) => {
                    if (!pressed || !swipeArmed || suppressNextClick || twoFingerTouchArea.touchPoints.length >= 2) return;

                    const mappedPoint = capsuleMouseArea.mapToItem(islandContainer, mouse.x, mouse.y);
                    const deltaX = mappedPoint.x - swipeLastX;
                    const deltaY = Math.abs(mappedPoint.y - swipeStartY);
                    const adjustedDeltaX = deltaY < sideSwipeVerticalTolerance ? deltaX : 0;
                    const nextProgress = islandContainer.advanceSideSwipeProgress(
                        islandContainer.swipeTransitionProgress,
                        adjustedDeltaX
                    );

                    swipeMoved = swipeMoved || Math.abs(nextProgress - swipeStartProgress) > 0.03 || deltaY > 6;
                    swipeLastX = mappedPoint.x;
                    islandContainer.swipeTransitionProgress = nextProgress;
                    mainCapsule.displayedWidth = mainCapsule.sideSwipePreviewWidth;
                }

                onReleased: {
                    if (swipeMoved) {
                        if (preparedOverviewOnPress)
                            root.cancelPreparedOverviewEverywhere();
                        preparedOverviewOnPress = false;
                        suppressNextClick = true;
                        swipeSuppressReset.restart();
                    }
                    let settleResult = {
                        action: "",
                        progress: islandContainer.sideSwipeRestProgressForProgress(swipeStartProgress),
                        width: islandContainer.sideSwipeRestWidthForProgress(swipeStartProgress)
                    };

                    if (swipeArmed)
                        settleResult = islandContainer.resolveSideSwipeSettle(
                            swipeStartProgress,
                            islandContainer.swipeTransitionProgress
                        );

                    sideSwipeInteractive = false;

                    if (swipeArmed)
                        islandContainer.beginSideSwipeSettle(settleResult.width);
                    else
                        mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;

                    if (swipeArmed) {
                        switch (settleResult.action) {
                        case "time":
                            islandContainer.showTimeCapsule();
                            break;
                        case "custom":
                            islandContainer.showCustomCapsule();
                            break;
                        case "lyrics":
                            islandContainer.showLyricsCapsule();
                            break;
                        case "utilities":
                            islandContainer.showUtilitiesCapsule();
                            break;
                        default:
                            islandContainer.swipeTransitionProgress = settleResult.progress;
                        }
                    } else {
                        islandContainer.swipeTransitionProgress = settleResult.progress;
                    }
                    swipeArmed = false;
                    swipeMoved = false;
                }

                onCanceled: {
                    if (preparedOverviewOnPress)
                        root.cancelPreparedOverviewEverywhere();
                    swipeArmed = false;
                    swipeMoved = false;
                    sideSwipeInteractive = false;
                    suppressNextClick = false;
                    preparedOverviewOnPress = false;
                    swipeSuppressReset.stop();
                    mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
                    islandContainer.swipeTransitionProgress = islandContainer.swipeRestProgressForState();
                }

                onClicked: (mouse) => {
                    if (suppressNextClick) {
                        swipeSuppressReset.stop();
                        suppressNextClick = false;
                        preparedOverviewOnPress = false;
                        return;
                    }

                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton)) {
                        preparedOverviewOnPress = false;
                        islandContainer.handleConfiguredClickAction(userConfig.dynamicIslandPrimaryAction);
                        return;
                    }

                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSecondaryButton)) {
                        preparedOverviewOnPress = false;
                        islandContainer.handleConfiguredClickAction(userConfig.dynamicIslandSecondaryAction);
                    }
                }
            }

            MultiPointTouchArea {
                id: twoFingerTouchArea
                anchors.fill: parent
                z: 0
                enabled: false
                mouseEnabled: false
                minimumTouchPoints: 2
                maximumTouchPoints: 2

                property real swipeStartX: 0
                property real swipeStartProgress: 0
                property bool swipeMoved: false

                onPressed: (touchPoints) => {
                    const centerPoint = islandContainer.mapFromItem(twoFingerTouchArea, 
                        (touchPoints[0].x + touchPoints[1].x) / 2,
                        (touchPoints[0].y + touchPoints[1].y) / 2);
                    swipeStartX = centerPoint.x;
                    swipeStartProgress = islandContainer.swipeTransitionProgress;
                    swipeMoved = false;
                    islandContainer.cancelSideSwipeSettle();
                }

                onUpdated: (touchPoints) => {
                    const centerPoint = islandContainer.mapFromItem(twoFingerTouchArea, 
                        (touchPoints[0].x + touchPoints[1].x) / 2,
                        (touchPoints[0].y + touchPoints[1].y) / 2);
                    
                    const deltaX = centerPoint.x - swipeStartX;
                    const nextProgress = islandContainer.advanceSideSwipeProgress(
                        swipeStartProgress,
                        deltaX
                    );

                    if (Math.abs(nextProgress - swipeStartProgress) > 0.03) {
                        swipeMoved = true;
                    }

                    islandContainer.swipeTransitionProgress = nextProgress;
                    mainCapsule.displayedWidth = mainCapsule.sideSwipePreviewWidth;
                }

                onReleased: {
                    if (swipeMoved) {
                        const settleResult = islandContainer.resolveSideSwipeSettle(
                            swipeStartProgress,
                            islandContainer.swipeTransitionProgress
                        );

                        islandContainer.beginSideSwipeSettle(settleResult.width);

                        switch (settleResult.action) {
                        case "time":
                            islandContainer.showTimeCapsule();
                            break;
                        case "custom":
                            islandContainer.showCustomCapsule();
                            break;
                        case "lyrics":
                            islandContainer.showLyricsCapsule();
                            break;
                        case "utilities":
                            islandContainer.showUtilitiesCapsule();
                            break;
                        default:
                            islandContainer.swipeTransitionProgress = settleResult.progress;
                        }
                    } else {
                        islandContainer.swipeTransitionProgress = islandContainer.sideSwipeRestProgressForProgress(swipeStartProgress);
                    }
                    swipeMoved = false;
                }
            }



            Loader {
                id: customSwipeLoader
                anchors.fill: parent
                active: islandContainer.customSwipeVisible
                asynchronous: false
                visible: active

                onLoaded: islandContainer.syncCustomCapsuleWidth()

                sourceComponent: Component {
                    SwipeCustomInfoLayer {
                        items: islandContainer.customLeftItems
                        cavaLevels: islandContainer.cavaLevels
                        timeText: timeObj.currentTime
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.heroFontFamily
                        timeFontFamily: root.heroFontFamily
                        minimumWidth: 220
                        maximumWidth: Math.max(220, root.width - 48)
                        transitionProgress: islandContainer.swipeTransitionProgress
                        recordingActive: islandContainer.screenRecordingActive
                        showSecondaryText: islandContainer.workspaceOriginSide !== "left"
                            && islandContainer.splitOriginSide !== "left"
                        showCondition: true
                        onPreferredWidthChanged: islandContainer.syncCustomCapsuleWidth()
                    }
                }
            }

            Loader {
                id: lyricsSwipeLoader
                anchors.fill: parent
                active: islandContainer.lyricsSwipeVisible
                asynchronous: false
                visible: active

                onLoaded: islandContainer.syncLyricsCapsuleWidth()

                sourceComponent: Component {
                    SwipeLyricsLayer {
                        lyricText: islandContainer.lyricsDisplayText
                        timeText: timeObj.currentTime
                        textFontFamily: root.textFontFamily
                        timeFontFamily: root.timeFontFamily
                        textPixelSize: 16
                        minimumWidth: 220
                        maximumWidth: Math.max(220, root.width - 48)
                        transitionProgress: islandContainer.rightSwipeProgress
                        recordingActive: islandContainer.screenRecordingActive
                        showSecondaryText: islandContainer.workspaceOriginSide !== "right"
                            && islandContainer.splitOriginSide !== "right"
                        showCondition: true
                        onPreferredWidthChanged: islandContainer.syncLyricsCapsuleWidth()
                    }
                }
            }

            Loader {
                id: utilitiesSwipeLoader
                anchors.fill: parent
                active: islandContainer.utilitiesSwipeVisible
                asynchronous: false
                visible: active
                focus: islandContainer.islandState === "utilities"

                onLoaded: {
                    islandContainer.syncUtilitiesCapsuleWidth();
                    if (item) {
                        item.selectedIdx = 0;
                        item.forceActiveFocus();
                    }
                }

                sourceComponent: Component {
                    SwipeUtilitiesLayer {
                        focus: true
                        shellRootController: root.shellRootController
                        screenRecordingActive: root.screenRecordingActive
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        timeFontFamily: root.timeFontFamily
                        timeText: timeObj.currentTime
                        showSecondaryText: islandContainer.workspaceOriginSide !== "right"
                            && islandContainer.splitOriginSide !== "right"
                        transitionProgress: islandContainer.islandState === "utilities" ? 1.0 : islandContainer.rightSwipeProgress
                        showCondition: true
                        onPreferredWidthChanged: islandContainer.syncUtilitiesCapsuleWidth()
                        onCloseRequested: {
                            islandContainer.closeUtilitiesInstantly();
                        }
                        onWallpaperRequested: {
                            islandContainer.showWallpapers();
                        }
                    }
                }
            }

            Loader {
                id: splitIconLoader
                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.splitShowsIconOnly
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    SplitIconLayer {
                        iconText: islandContainer.splitIcon
                        iconFontFamily: root.iconFontFamily
                        transitionProgress: islandContainer.swipeTransitionProgress
                        slideDirection: islandContainer.splitOriginSide
                        showCondition: true
                    }
                }
            }

            Loader {
                id: osdLayerLoader
                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.splitUsesExtendedLayout
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    OsdLayer {
                        iconText: islandContainer.splitIcon
                        progress: islandContainer.osdProgress
                        customText: islandContainer.osdCustomText
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        transitionProgress: islandContainer.swipeTransitionProgress
                        slideDirection: islandContainer.splitOriginSide
                        showCondition: true
                    }
                }
            }

            Loader {
                id: workspaceLayerLoader
                anchors.fill: parent
                active: !root.overviewVisible
                    && islandContainer.islandState === "long_capsule"
                    && (islandContainer.workspaceOriginSide !== "none"
                        || Math.abs(islandContainer.swipeTransitionProgress) < 0.001)
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    WorkspaceLayer {
                        workspaceId: islandContainer.currentWs
                        displayText: "Workspace " + islandContainer.currentWs
                        textFontFamily: root.textFontFamily
                        textPixelSize: 16
                        animateVisibility: islandContainer.restingState === "normal"
                        transitionProgress: islandContainer.swipeTransitionProgress
                        showCondition: true
                        slideDirection: islandContainer.workspaceOriginSide
                    }
                }
            }

            Loader {
                id: expandedPlayerLoader
                anchors.fill: parent
                active: islandContainer.expandedLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    ExpandedPlayerLayer {
                        currentArtUrl: islandContainer.currentArtUrl
                        currentTrack: islandContainer.currentTrack
                        currentArtist: islandContainer.currentArtist
                        timePlayed: islandContainer.timePlayed
                        timeTotal: islandContainer.timeTotal
                        trackProgress: islandContainer.trackProgress
                        activePlayer: islandContainer.activePlayer
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.expandedLayerVisible
                        onControlPressed: islandContainer.suppressCapsuleClick()
                    }
                }
            }

            Loader {
                id: bluetoothExpandedLoader
                anchors.fill: parent
                active: islandContainer.bluetoothExpandedLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    BluetoothExpandedLayer {
                        device: islandContainer.bluetoothExpandedDevice
                        volumeLevel: islandContainer.currentVolume
                        iconText: ""
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.bluetoothExpandedLayerVisible
                    }
                }
            }

            Loader {
                id: notificationLoader
                anchors.fill: parent
                active: islandContainer.notificationLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    NotificationLayer {
                        appName: islandContainer.notificationAppName
                        summary: islandContainer.notificationSummary
                        body: islandContainer.notificationBody
                        iconText: root.notificationStatusIcon
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: true
                    }
                }
            }

            Loader {
                id: controlCenterLoader
                anchors.fill: parent
                active: islandContainer.controlCenterLayerVisible || root.anyConnectivityDetailMounted
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    ControlCenterLayer {
                        shellRootController: root.shellRootController
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        sliderIntroDelay: mainCapsule.morphDuration
                        currentTime: timeObj.currentTime
                        currentDateLabel: timeObj.currentDateLabel
                        batteryCapacity: islandContainer.batteryCapacity
                        isCharging: islandContainer.isCharging
                        volumeLevel: islandContainer.currentVolume
                        isMuted: islandContainer.isMuted
                        brightnessLevel: islandContainer.currentBrightness
                        tempLevel: root.nightLightTemp
                        batteryModeInitialIndex: root.cachedBatteryModeIndex
                        dndActive: root.dndActive
                        currentWorkspace: islandContainer.currentWs
                        currentTrack: islandContainer.currentTrack
                        currentArtist: islandContainer.currentArtist
                        showCondition: islandContainer.controlCenterLayerVisible
                        notificationModel: notificationHistory
                        onConnectivityPanelRequested: function(kind, open) {
                            root.setConnectivityDetailVisible(kind, open);
                        }
                        onTempChanged: function(val) {
                            root.nightLightTemp = val;
                        }
                        onBatteryModeIndexChangedExternal: function(index) {
                            root.cachedBatteryModeIndex = index;
                        }
                        onDndToggleRequested: {
                            root.dndActive = !root.dndActive;
                        }
                    }
                }
            }

            Loader {
                id: launcherLoader
                anchors.fill: parent
                active: true
                asynchronous: false
                visible: islandContainer.islandState === "launcher"
                focus: islandContainer.islandState === "launcher"

                sourceComponent: Component {
                    AppLauncherLayer {
                        focus: true
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: islandContainer.islandState === "launcher"
                        onCloseRequested: {
                            islandContainer.islandState = "normal";
                        }
                    }
                }
            }

            Loader {
                id: clipboardLoader
                anchors.fill: parent
                active: true
                asynchronous: false
                visible: islandContainer.islandState === "clipboard"
                focus: islandContainer.islandState === "clipboard"

                sourceComponent: Component {
                    ClipboardLayer {
                        focus: true
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: islandContainer.islandState === "clipboard"
                        onCloseRequested: {
                            islandContainer.islandState = "normal";
                        }
                    }
                }
            }

            Loader {
                id: emojisLoader
                anchors.fill: parent
                active: true
                asynchronous: false
                visible: islandContainer.islandState === "emojis"
                focus: islandContainer.islandState === "emojis"

                sourceComponent: Component {
                    EmojiPickerLayer {
                        focus: true
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: islandContainer.islandState === "emojis"
                        onCloseRequested: {
                            islandContainer.islandState = "normal";
                        }
                    }
                }
            }

            Loader {
                id: wallpapersLoader
                anchors.fill: parent
                active: true
                asynchronous: false
                visible: islandContainer.islandState === "wallpapers"
                focus: islandContainer.islandState === "wallpapers"

                sourceComponent: Component {
                    WallpaperPickerLayer {
                        focus: true
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: islandContainer.islandState === "wallpapers"
                        onCloseRequested: {
                            islandContainer.islandState = "normal";
                        }
                    }
                }
            }

            Loader {
                id: overviewLoader

                anchors.fill: parent
                active: root.overviewLoaderActive
                asynchronous: false
                visible: root.overviewContentVisible

                onStatusChanged: {
                    if (status === Loader.Ready && root.overviewPreparing) {
                        root.beginOverviewOpening();
                    }
                }

                sourceComponent: Component {
                    WorkspaceOverviewScene {
                        screen: root.screen
                        showCondition: root.overviewVisible
                        previewsEnabled: root.overviewContentVisible
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        wallpaperPath: root.overviewWallpaperSource
                        windowCornerRadius: root.overviewWindowCornerRadius
                        onCloseRequested: root.closeOverviewEverywhere()
                    }
                }
            }

        }

        ConnectivityDetailShell {
            id: wifiConnectivityDetailShell

            open: root.wifiConnectivityDetailOpen
            mounted: root.wifiConnectivityDetailMounted
            rightSide: false
            panelKind: "wifi"
            provider: controlCenterLoader.item
            mainCapsule: mainCapsule
            availableWidth: root.width
            detailWidth: root.connectivityDetailWidth
            detailHeight: root.connectivityDetailHeight
            detailGap: root.connectivityDetailGap
            iconFontFamily: root.iconFontFamily
            textFontFamily: root.textFontFamily
            heroFontFamily: root.heroFontFamily
        }

        ConnectivityDetailShell {
            id: bluetoothConnectivityDetailShell

            open: root.bluetoothConnectivityDetailOpen
            mounted: root.bluetoothConnectivityDetailMounted
            rightSide: true
            panelKind: "bluetooth"
            provider: controlCenterLoader.item
            mainCapsule: mainCapsule
            availableWidth: root.width
            detailWidth: root.connectivityDetailWidth
            detailHeight: root.connectivityDetailHeight
            detailGap: root.connectivityDetailGap
            iconFontFamily: root.iconFontFamily
            textFontFamily: root.textFontFamily
            heroFontFamily: root.heroFontFamily
        }

        ConnectivityDetailShell {
            id: batteryConnectivityDetailShell

            open: root.batteryConnectivityDetailOpen
            mounted: root.batteryConnectivityDetailMounted
            rightSide: true
            panelKind: "battery"
            provider: controlCenterLoader.item
            mainCapsule: mainCapsule
            availableWidth: root.width
            detailWidth: root.connectivityDetailWidth
            detailHeight: root.connectivityDetailHeight
            detailGap: root.connectivityDetailGap
            iconFontFamily: root.iconFontFamily
            textFontFamily: root.textFontFamily
            heroFontFamily: root.heroFontFamily
        }

        ConnectivityDetailShell {
            id: audioConnectivityDetailShell

            open: root.audioConnectivityDetailOpen
            mounted: root.audioConnectivityDetailMounted
            rightSide: true
            panelKind: "audio"
            provider: controlCenterLoader.item
            mainCapsule: mainCapsule
            availableWidth: root.width
            detailWidth: root.connectivityDetailWidth
            detailHeight: root.connectivityDetailHeight
            detailGap: root.connectivityDetailGap
            iconFontFamily: root.iconFontFamily
            textFontFamily: root.textFontFamily
            heroFontFamily: root.heroFontFamily
        }

        TopRightStatus {
            id: topRightComponent
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 4
            cavaLevels: islandContainer.cavaLevels
            batteryCapacity: islandContainer.batteryCapacity
            isCharging: islandContainer.isCharging
            musicPlaying: islandContainer.activePlayer && islandContainer.activePlayer.playbackState === MprisPlaybackState.Playing
            iconFontFamily: root.iconFontFamily
            textFontFamily: root.textFontFamily
        }

        TopLeftLyrics {
            id: topLeftComponent
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 4
            lyricText: islandContainer.lyricsDisplayText
            musicPlaying: islandContainer.activePlayer && islandContainer.activePlayer.playbackState === MprisPlaybackState.Playing
            textFontFamily: root.textFontFamily
            iconFontFamily: root.iconFontFamily
            maxAllowedWidth: (root.width - mainCapsule.width) / 2 - 32
            islandState: islandContainer.islandState
        }

        TopRightTray {
            id: topRightTray
            anchors.right: topRightComponent.left
            anchors.rightMargin: 12
            anchors.top: parent.top
            anchors.topMargin: 4
            window: root
            textFontFamily: root.textFontFamily
            iconFontFamily: root.iconFontFamily
        }
    }

}
