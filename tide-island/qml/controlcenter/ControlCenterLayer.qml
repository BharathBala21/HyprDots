import QtQuick
import QtQml
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import IslandBackend

Item {
    id: controlCenter

    signal connectivityPanelRequested(string kind, bool open)

    readonly property var userConfig: UserConfig

    property bool showCondition: false
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    property var shellRootController: null
    // ... rest of properties ...

    scale: showCondition ? 1.0 : 0.12
    transformOrigin: Item.Top

    Behavior on scale {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuint
        }
    }
    property string currentTime: "00:00"
    property string currentDateLabel: ""
    property int batteryCapacity: 0
    property bool isCharging: false
    property real volumeLevel: -1
    property bool isMuted: false
    property real brightnessLevel: -1
    property int sliderIntroDelay: 400
    property int currentWorkspace: 1
    property string currentTrack: ""
    property string currentArtist: ""

    property real localVolume: 0.5
    property real localBrightness: 0.5
    property real displayedVolume: 0.5
    property real displayedBrightness: 0.5
    property real pendingVolume: 0.5
    property real pendingBrightness: 0.5
    property real lastAppliedVolume: -1
    property real lastAppliedBrightness: -1
    property bool brightnessSetterRunning: false
    property bool volumeSetterRunning: false
    property bool sliderIntroPending: false
    property bool wifiPanelOpen: false
    property bool bluetoothPanelOpen: false
    property bool batteryPanelOpen: false
    property bool audioPanelOpen: false
    property string activeSinkName: ""
    property string activeSinkDescription: "Default Output"
    property var audioSinks: []
    property bool batteryDrawerOpen: false
    property bool batteryDrawerDragging: false
    property real batteryDrawerProgress: 0
    property bool batteryDrawerSettling: false
    readonly property bool batteryDrawerMoving: batteryDrawerDragging
        || batteryDrawerSettling
        || batteryDrawerProgressAnimation.running
    property bool batteryModeBusy: false
    property bool batteryModeStateRunning: false
    property bool batteryModeSetterRunning: false
    property bool batteryModeSliderDragging: false
    property bool batteryTlpAvailable: false
    property bool batteryTlpChecked: false
    property int batteryModeInitialIndex: 1
    property int batteryModeIndex: batteryModeInitialIndex
    property int batteryModeAppliedIndex: batteryModeInitialIndex
    property bool dndActive: false

    signal batteryModeIndexChangedExternal(int index)
    signal dndToggleRequested()

    onBatteryModeIndexChanged: {
        batteryModeIndexChangedExternal(batteryModeIndex);
    }
    property int batteryModePendingIndex: 1
    property real batteryModeDragOffset: 0
    property string batteryModeInfoMessage: ""
    property string batteryModeError: ""
    property string batteryModeLastCommandOutput: ""
    property int batteryModeRefreshPollsRemaining: 0
    property bool caffeineMode: false

    property real tempLevel: 0.0
    property real localTemp: tempLevel
    property real displayedTemp: 0.0
    property real pendingTemp: 0.0
    property real lastAppliedTemp: 0.0
    property bool tempSetterRunning: false

    signal tempChanged(real val)

    onLocalTempChanged: {
        tempChanged(localTemp);
    }

    property string wifiLocalInfoMessage: ""
    property string wifiLocalError: ""
    property string wifiPendingPasswordSsid: ""
    property string wifiPendingPasswordValue: ""

    property string bluetoothInfoMessage: ""
    property string bluetoothError: ""
    property string bluetoothPairAndConnectPath: ""
    property string bluetoothPendingSecretValue: ""
    readonly property var wifiController: WifiController
    readonly property var bluetoothPairingAgent: BluetoothPairingAgent
    readonly property var wifiNetworks: wifiController ? wifiController.networks : null

    property int wifiSignal: -1

    Instantiator {
        id: wifiSignalTracker
        model: wifiController ? wifiController.networks : null
        onObjectAdded: (index, object) => {
            updateSignal();
        }
        onObjectRemoved: (index, object) => {
            updateSignal();
        }

        delegate: QtObject {
            required property bool connected
            required property int signal
            onConnectedChanged: wifiSignalTracker.updateSignal()
            onSignalChanged: wifiSignalTracker.updateSignal()
        }

        function updateSignal() {
            let found = -1;
            for (let i = 0; i < count; i++) {
                let obj = objectAt(i);
                if (obj && obj.connected) {
                    found = obj.signal;
                    break;
                }
            }
            controlCenter.wifiSignal = found;
            console.log("[WifiTracker] Connected SSID:", wifiCurrentSsid, "Signal Strength:", found);
        }
    }

    readonly property var themeColors: shellRootController ? shellRootController.matugenThemeColors : null

    readonly property real sliderKnobSize: 24
    readonly property color panelColor: themeColors ? themeColors.background : StyleTokens.panel
    readonly property color moduleColor: themeColors ? themeColors.secondary_container : StyleTokens.module
    readonly property color moduleHover: themeColors ? Qt.lighter(themeColors.secondary_container, 1.15) : StyleTokens.moduleHover
    readonly property color trackColor: themeColors ? themeColors.secondary_container : StyleTokens.track
    readonly property color textPrimary: themeColors ? themeColors.on_surface : StyleTokens.textPrimary
    readonly property color textSecondary: themeColors ? themeColors.on_surface_variant : StyleTokens.textSecondary
    readonly property color cardAccent: themeColors ? themeColors.primary : StyleTokens.accent
    readonly property color cardAccentPressed: themeColors ? Qt.darker(themeColors.primary, 1.15) : StyleTokens.accentPressed
    readonly property color cardFillActive: themeColors ? themeColors.primary : StyleTokens.cardFillActive
    readonly property color cardFillHover: themeColors ? Qt.lighter(themeColors.primary, 1.1) : StyleTokens.cardFillHover
    readonly property color buttonFill: themeColors ? themeColors.secondary_container : StyleTokens.buttonFill
    readonly property color buttonFillHover: themeColors ? Qt.lighter(themeColors.secondary_container, 1.15) : StyleTokens.buttonFillHover
    readonly property color buttonFillPressed: themeColors ? Qt.darker(themeColors.secondary_container, 1.15) : StyleTokens.buttonFillPressed
    readonly property string wifiGlyph: {
        if (!wifiEnabled) return "\u{F05AE}"; // wifi-strength-off
        if (wifiCurrentSsid.length === 0 || wifiSignal < 0) return "\u{F05AD}"; // wifi-strength-outline
        if (wifiSignal >= 75) return "\u{F05AC}"; // wifi-strength-4
        if (wifiSignal >= 50) return "\u{F05AB}"; // wifi-strength-3
        if (wifiSignal >= 25) return "\u{F05AA}"; // wifi-strength-2
        return "\u{F05A9}"; // wifi-strength-1
    }
    readonly property string bluetoothGlyph: ""
    readonly property string chargingIconGlyph: "\uf0e7"
    readonly property string brightnessIconGlyph: "\u{F00DF}"
    readonly property string volumeIconGlyph: {
        return volumeGlyph(displayedVolume, isMuted);
    }

    readonly property var batteryModeGlyphs: ["", "", ""]
    property var notificationModel: null
    readonly property real controlCenterExtraHeight: 230
    readonly property real controlCenterMaximumExtraHeight: 230
    readonly property real shortTileWidth: (controlCenter.width - 24) / 3
    readonly property bool bluetoothAvailable: !!bluetoothAdapter
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var bluetoothDeviceValues: bluetoothAdapter ? bluetoothAdapter.devices.values : []
    readonly property bool wifiSupported: wifiController ? wifiController.supported : false
    readonly property bool wifiReadOnly: wifiController ? wifiController.readOnly : true
    readonly property bool wifiAvailable: wifiController ? wifiController.available : false
    readonly property bool wifiEnabled: wifiController ? wifiController.enabled : false
    readonly property bool wifiBusy: wifiController ? wifiController.busy : false
    readonly property bool wifiListRunning: wifiController ? wifiController.scanning : false
    readonly property string wifiCurrentSsid: wifiController ? wifiController.currentSsid : ""
    readonly property string wifiInfoMessage: wifiLocalInfoMessage.length > 0
        ? wifiLocalInfoMessage
        : (wifiController ? wifiController.infoMessage : "")
    readonly property string wifiError: wifiLocalError.length > 0
        ? wifiLocalError
        : (wifiController ? wifiController.errorMessage : "")
    readonly property string wifiUnsupportedReason: wifiController ? wifiController.unsupportedReason : ""
    readonly property string wifiAvailabilityMessage: {
        if (wifiUnsupportedReason.length > 0) return wifiUnsupportedReason;
        if (wifiSupported && !wifiAvailable) return "No Wi-Fi device is available.";
        return "";
    }
    readonly property bool bluetoothEnabled: bluetoothAdapter ? bluetoothAdapter.enabled : false
    readonly property bool bluetoothBusy: bluetoothAdapter
        ? bluetoothAdapter.state === BluetoothAdapterState.Enabling
            || bluetoothAdapter.state === BluetoothAdapterState.Disabling
        : false
    readonly property bool bluetoothPairingActive: bluetoothPairingAgent ? bluetoothPairingAgent.requestActive : false
    readonly property bool bluetoothPairingRequiresInput: bluetoothPairingAgent ? bluetoothPairingAgent.requestRequiresInput : false
    readonly property bool bluetoothPairingNumericInput: bluetoothPairingAgent ? bluetoothPairingAgent.requestNumericInput : false
    readonly property bool bluetoothPairingRequiresConfirmation: bluetoothPairingAgent ? bluetoothPairingAgent.requestRequiresConfirmation : false
    readonly property string bluetoothPairingTitle: bluetoothPairingAgent ? bluetoothPairingAgent.promptTitle : ""
    readonly property string bluetoothPairingMessage: bluetoothPairingAgent ? bluetoothPairingAgent.promptMessage : ""
    readonly property string bluetoothPairingDisplayedCode: bluetoothPairingAgent ? bluetoothPairingAgent.displayedCode : ""
    readonly property bool hasConnectivityPrompt: wifiPendingPasswordSsid.length > 0 || bluetoothPairingActive
    readonly property bool anyConnectivityPanelOpen: wifiPanelOpen || bluetoothPanelOpen || batteryPanelOpen || audioPanelOpen
    readonly property string wifiStatusText: wifiController ? wifiController.statusText : "Unavailable"
    readonly property string bluetoothStatusText: buildBluetoothStatusText()
    readonly property string bluetoothAvailabilityMessage: bluetoothAvailable ? "" : "No Bluetooth adapter is available."
    readonly property string batteryModeStatusText: buildBatteryModeStatusText()

    function clamp01(value) {
        return Math.max(0, Math.min(1, value));
    }

    function trimString(value) {
        if (value === undefined || value === null) return "";
        return String(value).trim();
    }

    function batteryModeLabel(index) {
        if (index <= 0) return "Power Saver";
        if (index >= 2) return "Performance";
        return "Balanced";
    }

    function batteryModeCommand(index) {
        if (index <= 0) return "power-saver";
        if (index >= 2) return "performance";
        return "balanced";
    }

    function batteryModeIndexForCommand(command) {
        const normalized = trimString(command).toLowerCase();
        if (normalized === "power-saver" || normalized === "bat") return 0;
        if (normalized === "performance" || normalized === "ac") return 2;
        return 1;
    }

    function setBatteryModeVisualIndex(index, animate) {
        const nextIndex = Math.max(0, Math.min(2, index));
        batteryModeIndex = nextIndex;
    }

    function setBatteryDrawerOpen(open) {
        const nextOpen = !!open;
        batteryDrawerOpen = nextOpen;
        batteryDrawerSettling = true;
        batteryDrawerProgress = nextOpen ? 1 : 0;
        batteryDrawerSettleTimer.restart();
        if (nextOpen && !batteryTlpChecked)
            refreshBatteryModeState();
    }

    function toggleBatteryDrawer() {
        setBatteryDrawerOpen(!batteryDrawerOpen);
    }

    function refreshBatteryModeState() {
        if (batteryModeStateRunning)
            return;

        batteryModeStateRunning = true;
        tlpStateTimeoutTimer.start();
        ppQueryProcess.running = true;
    }

    function applyBatteryModeState(available, profile, output, errorString) {
        tlpStateTimeoutTimer.stop();
        batteryModeStateRunning = false;
        batteryTlpChecked = true;
        batteryTlpAvailable = !!available;

        if (!batteryTlpAvailable) {
            batteryModeBusy = false;
            batteryModeError = trimString(errorString).length > 0 ? errorString : "power-profiles-daemon is not installed.";
            setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
            return;
        }

        if (batteryModeError === "power-profiles-daemon is not installed.")
            batteryModeError = "";

        let resolvedProfile = trimString(profile);
        if (resolvedProfile.length === 0) {
            const profileMatch = String(output || "").match(/TLP profile\s*=\s*([a-z-]+)/i);
            if (profileMatch)
                resolvedProfile = profileMatch[1];
        }

        if (resolvedProfile.length > 0) {
            const nextIndex = batteryModeIndexForCommand(resolvedProfile);
            batteryModeAppliedIndex = nextIndex;
            setBatteryModeVisualIndex(nextIndex, true);

            if (batteryModeRefreshPollsRemaining > 0 && nextIndex === batteryModePendingIndex) {
                batteryModeRefreshPollsRemaining = 0;
                batteryModeRefreshTimer.stop();
                batteryModeError = "";
                batteryModeInfoMessage = batteryModeLabel(nextIndex) + " active.";
            }
        }
    }

    function buildBatteryModeStatusText() {
        if (batteryModeBusy) return "Applying " + batteryModeLabel(batteryModePendingIndex);
        if (trimString(userConfig.tlpPermissionMode) === "skip") return "Power modes disabled";
        if (!batteryTlpChecked) return "Checking power profiles...";
        if (!batteryTlpAvailable) return "power-profiles-daemon is not installed";
        return batteryModeLabel(batteryModeIndex);
    }

    function rollbackBatteryMode(message) {
        batteryModeBusy = false;
        batteryModeError = message;
        batteryModeInfoMessage = "";
        batteryModeDragOffset = 0;
        setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
    }

    function classifyBatteryModeFailure(exitCode) {
        return "Failed to apply power mode.";
    }

    function queueBatteryModeStateRefresh(polls) {
        batteryModeRefreshPollsRemaining = Math.max(0, polls);
        if (batteryModeRefreshPollsRemaining > 0)
            batteryModeRefreshTimer.restart();
        else
            batteryModeRefreshTimer.stop();
    }

    function selectBatteryMode(index) {
        if (batteryModeBusy) {
            if (batteryModeSetterRunning)
                ppSetProcess.running = false;
            batteryModeBusy = false;
            batteryModeSetterRunning = false;
        }

        queueBatteryModeStateRefresh(0);

        const nextIndex = Math.max(0, Math.min(2, index));

        if (trimString(userConfig.tlpPermissionMode) === "skip") {
            rollbackBatteryMode("Power mode switching is disabled in userconfig.json.");
            return;
        }

        if (!batteryTlpChecked) {
            refreshBatteryModeState();
            rollbackBatteryMode("Checking power profiles. Try again in a moment.");
            return;
        }

        if (!batteryTlpAvailable) {
            rollbackBatteryMode("power-profiles-daemon is not installed.");
            return;
        }

        if (nextIndex === batteryModeAppliedIndex) {
            batteryModeError = "";
            batteryModeInfoMessage = batteryModeLabel(nextIndex) + " active.";
            setBatteryModeVisualIndex(nextIndex, true);
            return;
        }

        batteryModePendingIndex = nextIndex;
        batteryModeBusy = true;
        batteryModeSetterRunning = true;
        batteryModeError = "";
        batteryModeInfoMessage = "Applying " + batteryModeLabel(nextIndex) + "...";
        setBatteryModeVisualIndex(nextIndex, true);
        batteryModeLastCommandOutput = "";
        
        ppSetProcess.pendingMode = batteryModeCommand(nextIndex);
        ppSetProcess.running = true;
    }

    function finishBatteryModeApply(success, exitCode, output, errorString) {
        batteryModeSetterRunning = false;
        batteryModeBusy = false;
        batteryModeLastCommandOutput = trimString(output);
        if (batteryModeLastCommandOutput.length === 0)
            batteryModeLastCommandOutput = trimString(errorString);

        if (!success) {
            rollbackBatteryMode(classifyBatteryModeFailure(exitCode));
            return;
        }

        batteryModeAppliedIndex = batteryModePendingIndex;
        batteryModeError = "";
        batteryModeInfoMessage = batteryModeLabel(batteryModeAppliedIndex) + " active.";
        setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
        refreshBatteryModeState();
    }

    function clearWifiPrompt() {
        wifiPendingPasswordSsid = "";
        wifiPendingPasswordValue = "";
        wifiLocalInfoMessage = "";
        wifiLocalError = "";
    }

    function clearWifiMessages() {
        wifiLocalInfoMessage = "";
        wifiLocalError = "";
        if (wifiController)
            wifiController.clearMessages();
    }

    function clearBluetoothMessages() {
        bluetoothInfoMessage = "";
        bluetoothError = "";
    }

    function submitBluetoothPairingSecret() {
        if (!bluetoothPairingAgent || !bluetoothPairingRequiresInput)
            return;

        const secret = trimString(bluetoothPendingSecretValue);
        if (!secret) {
            bluetoothError = bluetoothPairingNumericInput
                ? "Enter the 6-digit passkey first."
                : "Enter the PIN first.";
            return;
        }

        if (bluetoothPairingNumericInput && !/^\d{1,6}$/.test(secret)) {
            bluetoothError = "Passkeys must be 1 to 6 digits.";
            return;
        }

        bluetoothError = "";
        bluetoothPairingAgent.submitSecret(secret);
        bluetoothPendingSecretValue = "";
    }

    function confirmBluetoothPairing() {
        if (!bluetoothPairingAgent)
            return;

        bluetoothError = "";
        bluetoothPairingAgent.confirmRequest();
    }

    function cancelBluetoothPairing() {
        if (!bluetoothPairingAgent)
            return;

        bluetoothPairingAgent.cancelRequest();
        bluetoothPendingSecretValue = "";
    }

    function isConnectivityPanelOpen(kind) {
        if (kind === "wifi") return wifiPanelOpen;
        if (kind === "bluetooth") return bluetoothPanelOpen;
        if (kind === "battery") return batteryPanelOpen;
        if (kind === "audio") return audioPanelOpen;
        return false;
    }

    function setConnectivityPanelOpen(kind, open, emitSignal) {
        if (emitSignal === undefined)
            emitSignal = true;

        const nextOpen = !!open;

        if (nextOpen) {
            if (kind !== "wifi" && wifiPanelOpen)
                setConnectivityPanelOpen("wifi", false, emitSignal);
            if (kind !== "bluetooth" && bluetoothPanelOpen)
                setConnectivityPanelOpen("bluetooth", false, emitSignal);
            if (kind !== "battery" && batteryPanelOpen)
                setConnectivityPanelOpen("battery", false, emitSignal);
            if (kind !== "audio" && audioPanelOpen)
                setConnectivityPanelOpen("audio", false, emitSignal);
        }

        let changed = false;

        if (kind === "wifi") {
            changed = wifiPanelOpen !== nextOpen;
            wifiPanelOpen = nextOpen;

            if (nextOpen) {
                if (showCondition) {
                    requestWifiStateRefresh();
                    if (wifiSupported && wifiEnabled)
                        requestWifiListRefresh(true);
                }
            } else {
                clearWifiPrompt();
                clearWifiMessages();
            }
        } else if (kind === "bluetooth") {
            changed = bluetoothPanelOpen !== nextOpen;
            bluetoothPanelOpen = nextOpen;

            if (!nextOpen) {
                if (bluetoothPairingActive)
                    cancelBluetoothPairing();
                if (bluetoothAdapter && bluetoothAdapter.discovering)
                    bluetoothAdapter.discovering = false;
                bluetoothScanStopTimer.stop();
                bluetoothPairAndConnectPath = "";
                bluetoothPendingSecretValue = "";
                clearBluetoothMessages();
            }
        } else if (kind === "battery") {
            changed = batteryPanelOpen !== nextOpen;
            batteryPanelOpen = nextOpen;
        } else if (kind === "audio") {
            changed = audioPanelOpen !== nextOpen;
            audioPanelOpen = nextOpen;

            if (nextOpen) {
                if (showCondition) {
                    refreshAudioSinks();
                }
            }
        } else {
            return;
        }

        if (changed && emitSignal)
            connectivityPanelRequested(kind, nextOpen);
    }

    function toggleConnectivityOverlay(kind) {
        setConnectivityPanelOpen(kind, !isConnectivityPanelOpen(kind));
    }

    function closeConnectivityPanels(emitSignals) {
        if (emitSignals === undefined)
            emitSignals = true;

        setConnectivityPanelOpen("wifi", false, emitSignals);
        setConnectivityPanelOpen("bluetooth", false, emitSignals);
        setConnectivityPanelOpen("battery", false, emitSignals);
        setConnectivityPanelOpen("audio", false, emitSignals);
        clearWifiPrompt();
        clearWifiMessages();
        clearBluetoothMessages();
    }

    function requestWifiStateRefresh() {
        if (!showCondition || !wifiController) return;
        wifiController.refreshState();
    }

    function requestWifiListRefresh(rescan) {
        if (!showCondition || !wifiController) return;
        if (!wifiSupported || !wifiAvailable || !wifiEnabled) return;
        wifiController.refreshNetworks(!!rescan);
    }

    function toggleWifiEnabled() {
        clearWifiPrompt();
        clearWifiMessages();
        if (wifiController)
            wifiController.setEnabled(!wifiEnabled);
    }

    function disconnectWifi() {
        if (!wifiSupported || !wifiAvailable) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "No Wi-Fi device is available.";
            return;
        }

        clearWifiPrompt();
        clearWifiMessages();
        if (wifiController)
            wifiController.disconnectCurrent();
    }

    function connectWifiNetwork(network) {
        if (!network) return;
        if (!wifiSupported) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "Wi-Fi control is unavailable.";
            return;
        }
        if (!wifiAvailable) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "No Wi-Fi device is available.";
            return;
        }
        if (!wifiEnabled) {
            wifiLocalError = "Turn on Wi-Fi first.";
            return;
        }
        if (network.connected) return;

        const ssid = trimString(network.ssid);
        const networkType = trimString(network.type);
        const secure = !!network.secure;
        const savedConnection = !!network.savedConnection;

        if (!ssid) {
            wifiLocalError = "Hidden networks are not supported in this panel yet.";
            return;
        }

        if (!savedConnection && networkType === "wep") {
            wifiLocalError = "WEP networks aren't supported by this panel.";
            return;
        }

        if (!savedConnection && networkType === "8021x") {
            wifiLocalError = "802.1X networks need to be provisioned first.";
            return;
        }

        clearWifiPrompt();
        clearWifiMessages();

        if (savedConnection) {
            if (wifiController)
                wifiController.connectToNetwork(ssid);
            return;
        }

        if (!secure) {
            if (wifiController)
                wifiController.connectToNetwork(ssid);
            return;
        }

        wifiPendingPasswordSsid = ssid;
        wifiPendingPasswordValue = "";
        wifiLocalInfoMessage = "Enter the password for " + ssid + ".";
    }

    function submitWifiPassword() {
        const ssid = trimString(wifiPendingPasswordSsid);
        if (!ssid) return;

        if (trimString(wifiPendingPasswordValue).length === 0) {
            wifiLocalError = "Enter a password first.";
            return;
        }

        const password = wifiPendingPasswordValue;
        clearWifiPrompt();
        clearWifiMessages();
        if (wifiController)
            wifiController.connectToNetwork(ssid, password);
    }

    function applyBrightnessSnapshot(value) {
        if (value >= 0)
            syncBrightnessFromLevel(value);
    }

    function applyVolumeSnapshot(value) {
        if (value >= 0)
            syncVolumeFromLevel(value);
    }

    function applyVolumeSnapshotWithMute(value, muted) {
        applyVolumeSnapshot(value);
        isMuted = !!muted;
    }

    function volumeGlyph(value, muted) {
        if (muted) return "\u{F075F}"; // volume-mute
        if (value <= 0) return "\u{F0581}"; // volume-off
        if (value < 0.33) return "\u{F057F}"; // volume-low
        if (value < 0.66) return "\u{F0580}"; // volume-medium
        return "\u{F057E}"; // volume-high
    }

    function flushBrightness(force) {
        const nextValue = clamp01(pendingBrightness);
        if (!force && Math.abs(nextValue - lastAppliedBrightness) < 0.01) return;
        if (brightnessSetterRunning) {
            brightnessApplyTimer.restart();
            return;
        }

        lastAppliedBrightness = nextValue;
        brightnessSetterRunning = true;
        SystemServices.setBrightness(nextValue);
    }

    function queueBrightness(value) {
        localBrightness = clamp01(value);
        if (showCondition && !sliderIntroPending) displayedBrightness = localBrightness;
        pendingBrightness = localBrightness;
        brightnessApplyTimer.restart();
    }

    function flushVolume(force) {
        const nextValue = clamp01(pendingVolume);
        if (!force && Math.abs(nextValue - lastAppliedVolume) < 0.01) return;
        if (volumeSetterRunning) {
            volumeApplyTimer.restart();
            return;
        }

        lastAppliedVolume = nextValue;
        volumeSetterRunning = true;
        SystemServices.setVolume(nextValue);
    }

    function queueVolume(value) {
        localVolume = clamp01(value);
        if (showCondition && !sliderIntroPending) displayedVolume = localVolume;
        pendingVolume = localVolume;
        volumeApplyTimer.restart();
    }

    function syncBrightnessFromLevel(level) {
        if (level < 0 || brightnessCard.pressed || sliderIntroPending) return;
        localBrightness = clamp01(level);
        if (showCondition && !sliderIntroPending) displayedBrightness = localBrightness;
        pendingBrightness = localBrightness;
        lastAppliedBrightness = localBrightness;
    }

    function syncVolumeFromLevel(level) {
        if (level < 0 || volumeCard.pressed || sliderIntroPending) return;
        localVolume = clamp01(level);
        if (showCondition && !sliderIntroPending) displayedVolume = localVolume;
        pendingVolume = localVolume;
        lastAppliedVolume = localVolume;
    }

    function syncLevelsFromProps() {
        syncBrightnessFromLevel(brightnessLevel);
        syncVolumeFromLevel(volumeLevel);
    }

    function bluetoothDeviceName(device) {
        if (!device) return "Unknown device";
        const preferred = trimString(device.deviceName);
        if (preferred.length > 0) return preferred;

        const alias = trimString(device.name);
        if (alias.length > 0) return alias;

        const address = trimString(device.address);
        return address.length > 0 ? address : "Unknown device";
    }

    function bluetoothDeviceStateText(device) {
        if (!device) return "";
        if (device.pairing) return "Pairing";

        switch (device.state) {
        case BluetoothDeviceState.Connecting:
            return "Connecting";
        case BluetoothDeviceState.Connected:
            return "Connected";
        case BluetoothDeviceState.Disconnecting:
            return "Disconnecting";
        default:
            break;
        }

        if (device.paired || device.bonded) return "Paired";
        return "Available";
    }

    function bluetoothDeviceSubtitle(device) {
        const parts = [];
        const stateLabel = bluetoothDeviceStateText(device);
        if (stateLabel.length > 0) parts.push(stateLabel);
        if (device && device.batteryAvailable) parts.push(bluetoothBatteryPercent(device) + "%");
        return parts.join(" • ");
    }

    function bluetoothBatteryPercent(device) {
        if (!device || !device.batteryAvailable)
            return -1;

        const rawValue = Math.max(0, Number(device.battery) || 0);
        return Math.max(0, Math.min(100, Math.round(rawValue <= 1 ? rawValue * 100 : rawValue)));
    }

    function bluetoothDeviceMatchesSection(device, section) {
        if (!device) return false;

        const paired = device.paired || device.bonded;
        if (section === "connected") return device.connected;
        if (section === "paired") return !device.connected && paired;
        if (section === "available") return !paired;
        return false;
    }

    function buildBluetoothStatusText() {
        if (!bluetoothAvailable) return "Unavailable";
        if (!bluetoothEnabled) return "Off";

        const devices = bluetoothDeviceValues || [];
        const connectedNames = [];

        for (let index = 0; index < devices.length; index++) {
            const device = devices[index];
            if (device && device.connected)
                connectedNames.push(bluetoothDeviceName(device));
        }

        if (connectedNames.length === 1) return connectedNames[0];
        if (connectedNames.length > 1) return connectedNames[0] + " +" + (connectedNames.length - 1);
        if (bluetoothAdapter.discovering) return "Scanning";
        return bluetoothBusy ? "Working..." : "On";
    }

    function toggleBluetoothEnabled() {
        if (!bluetoothAdapter) {
            bluetoothError = "No Bluetooth adapter is available.";
            return;
        }

        bluetoothError = "";
        bluetoothInfoMessage = "";
        bluetoothPairAndConnectPath = "";

        if (bluetoothAdapter.discovering)
            bluetoothAdapter.discovering = false;

        bluetoothAdapter.enabled = !bluetoothAdapter.enabled;
    }

    function toggleCaffeineMode() {
        if (caffeineMode) {
            Quickshell.execDetached(["sh", "-c", "systemctl --user start hypridle || hypridle"]);
            caffeineMode = false;
        } else {
            Quickshell.execDetached(["sh", "-c", "systemctl --user stop hypridle || true; pkill -x hypridle || true"]);
            caffeineMode = true;
        }
        caffeineCheckTimer.restart();
    }

    Timer {
        id: caffeineCheckTimer
        interval: 500
        repeat: false
        onTriggered: checkHypridleProcess.running = true
    }

    function tempFromValue(v) {
        return Math.round(6500 - v * 4000);
    }

    function valueFromTemp(t) {
        return Math.max(0.0, Math.min(1.0, (6500 - t) / 4000));
    }

    function syncTempFromSystem(value) {
        if (tempCard.pressed || sliderIntroPending) return;
        console.log("[NightLight] syncTempFromSystem: value = " + value);
        localTemp = clamp01(value);
        if (showCondition && !sliderIntroPending) displayedTemp = localTemp;
        pendingTemp = localTemp;
        lastAppliedTemp = localTemp;
    }

    function queueTemp(value) {
        console.log("[NightLight] queueTemp: value = " + value);
        localTemp = clamp01(value);
        if (showCondition && !sliderIntroPending) displayedTemp = localTemp;
        pendingTemp = localTemp;
        tempApplyTimer.restart();
    }

    function flushTemp(force) {
        const nextValue = clamp01(pendingTemp);
        console.log("[NightLight] flushTemp: force = " + force + ", nextValue = " + nextValue + ", lastApplied = " + lastAppliedTemp);
        if (!force && Math.abs(nextValue - lastAppliedTemp) < 0.02) {
            console.log("[NightLight] flushTemp: change is too small, ignoring");
            return;
        }

        lastAppliedTemp = nextValue;

        if (nextValue < 0.05) {
            console.log("[NightLight] flushTemp: stopping night light");
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
        } else {
            const targetK = tempFromValue(nextValue);
            console.log("[NightLight] flushTemp: setting night light temp via execDetached to " + targetK);
            Quickshell.execDetached(["sh", "-c", "hyprctl hyprsunset temperature " + targetK + " || (hyprsunset -t " + targetK + " &)"]);
        }
    }

    Timer {
        id: tempApplyTimer
        interval: 100
        repeat: false
        onTriggered: controlCenter.flushTemp(false)
    }

    function toggleBluetoothScan() {
        if (!bluetoothAdapter) {
            bluetoothError = "No Bluetooth adapter is available.";
            return;
        }
        if (!bluetoothEnabled) {
            bluetoothError = "Turn on Bluetooth first.";
            return;
        }

        bluetoothError = "";
        if (bluetoothAdapter.discovering) {
            bluetoothAdapter.discovering = false;
            bluetoothInfoMessage = "";
            bluetoothScanStopTimer.stop();
        } else {
            bluetoothAdapter.discovering = true;
            bluetoothInfoMessage = "Scanning for nearby devices...";
            bluetoothScanStopTimer.restart();
        }
    }

    function handleBluetoothDevicePressed(device) {
        if (!device) return;
        if (!bluetoothAdapter || !bluetoothEnabled) {
            bluetoothError = "Turn on Bluetooth first.";
            return;
        }

        bluetoothError = "";

        if (device.connected) {
            bluetoothInfoMessage = "";
            device.disconnect();
            return;
        }

        if (device.paired || device.bonded) {
            bluetoothInfoMessage = "";
            device.connect();
            return;
        }

        bluetoothPairAndConnectPath = device.dbusPath;
        bluetoothInfoMessage = "Pairing " + bluetoothDeviceName(device) + "...";
        device.pair();
    }

    function forgetBluetoothDevice(device) {
        if (!device) return;
        if (bluetoothPairAndConnectPath === device.dbusPath)
            bluetoothPairAndConnectPath = "";
        device.forget();
    }

    anchors.fill: parent
    anchors.margins: 12
    opacity: showCondition ? 1 : 0
    visible: opacity > 0

    onBrightnessLevelChanged: syncBrightnessFromLevel(brightnessLevel)
    onVolumeLevelChanged: syncVolumeFromLevel(volumeLevel)
    onShowConditionChanged: {
        if (showCondition) {
            syncLevelsFromProps();
            sliderIntroPending = true;
            displayedBrightness = localBrightness;
            displayedVolume = localVolume;
            displayedTemp = localTemp;
            sliderIntroTimer.interval = sliderIntroDelay;
            sliderIntroTimer.restart();
            refreshBatteryModeState();
            controlCenter.refreshAudioSinks();
            requestWifiStateRefresh();
            checkHypridleProcess.running = true;
            queryHyprsunsetProcess.running = true;
            if (wifiPanelOpen && wifiSupported && wifiEnabled)
                requestWifiListRefresh(true);
        } else {
            sliderIntroTimer.stop();
            sliderIntroPending = false;
            // displayedBrightness = localBrightness;
            // displayedVolume = localVolume;
            // displayedTemp = localTemp;
            closeConnectivityPanels();
        }
    }

    Component.onCompleted: {
        syncLevelsFromProps();
        displayedBrightness = localBrightness;
        displayedVolume = localVolume;
        displayedTemp = localTemp;
        SystemServices.requestBrightness();
        SystemServices.requestVolume();
        refreshBatteryModeState();
        controlCenter.refreshAudioSinks();
        checkHypridleProcess.running = true;
        queryHyprsunsetProcess.running = true;
    }

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 240 : 100
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on displayedBrightness {
        enabled: controlCenter.showCondition && !controlCenter.sliderIntroPending && !brightnessCard.pressed

        NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    Behavior on displayedVolume {
        enabled: controlCenter.showCondition && !controlCenter.sliderIntroPending && !volumeCard.pressed

        NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    Behavior on displayedTemp {
        enabled: controlCenter.showCondition && !controlCenter.sliderIntroPending && !tempCard.pressed

        NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    Behavior on batteryDrawerProgress {
        enabled: !controlCenter.batteryDrawerDragging

        NumberAnimation {
            id: batteryDrawerProgressAnimation
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: SystemServices

        function onBrightnessSnapshotReady(value, errorString) {
            if (errorString === "")
                controlCenter.applyBrightnessSnapshot(value);
        }

        function onBrightnessSetFinished(value, success, errorString) {
            controlCenter.brightnessSetterRunning = false;
            if (success)
                controlCenter.applyBrightnessSnapshot(value);
            if (success && Math.abs(controlCenter.pendingBrightness - controlCenter.lastAppliedBrightness) >= 0.01)
                brightnessApplyTimer.restart();
        }

        function onVolumeSnapshotReady(value, muted, errorString) {
            if (errorString === "")
                controlCenter.applyVolumeSnapshotWithMute(value, muted);
        }

        function onVolumeSetFinished(value, success, errorString) {
            controlCenter.volumeSetterRunning = false;
            if (success)
                controlCenter.applyVolumeSnapshot(value);
            if (success && Math.abs(controlCenter.pendingVolume - controlCenter.lastAppliedVolume) >= 0.01)
                volumeApplyTimer.restart();
        }
    }

    Timer {
        id: brightnessApplyTimer
        interval: 55
        repeat: false
        onTriggered: controlCenter.flushBrightness(false)
    }

    Timer {
        id: volumeApplyTimer
        interval: 55
        repeat: false
        onTriggered: controlCenter.flushVolume(false)
    }

    Timer {
        id: tlpStateTimeoutTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (controlCenter.batteryModeStateRunning && !controlCenter.batteryTlpChecked) {
                console.log("Power profiles state request timed out, assuming power-profiles-daemon is not installed.");
                controlCenter.applyBatteryModeState(false, "", "", "power-profiles-daemon is not installed.");
            }
        }
    }

    function refreshAudioSinks() {
        audioQueryProcess.running = true;
    }

    function selectAudioSink(sinkName) {
        audioSetProcess.pendingSink = sinkName;
        audioSetProcess.running = true;
    }

    function toggleAudioMute() {
        if (!audioToggleMuteProcess.running)
            audioToggleMuteProcess.running = true;
    }

    Process {
        id: audioQueryProcess
        command: ["sh", "-c", "pactl get-default-sink && echo '---' && pactl -f json list sinks"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    const parts = this.text.split("---");
                    if (parts.length >= 2) {
                        const defaultSink = parts[0].trim();
                        const jsonText = parts[1].trim();
                        try {
                            const list = JSON.parse(jsonText);
                            let cleanedSinks = [];
                            let activeDesc = "Default Output";
                            for (let i = 0; i < list.length; i++) {
                                const s = list[i];
                                const isDefault = (s.name === defaultSink);
                                if (isDefault) {
                                    activeDesc = s.description;
                                }
                                cleanedSinks.push({
                                    name: s.name,
                                    description: s.description,
                                    connected: isDefault,
                                    deviceType: (s.name.indexOf("bluez") !== -1 || s.description.toLowerCase().indexOf("headset") !== -1 || s.description.toLowerCase().indexOf("headphone") !== -1 || s.description.toLowerCase().indexOf("buds") !== -1) ? "headset" : "speaker"
                                });
                            }
                            controlCenter.audioSinks = cleanedSinks;
                            controlCenter.activeSinkName = defaultSink;
                            controlCenter.activeSinkDescription = activeDesc;
                        } catch (e) {
                            console.log("Error parsing audio sinks: " + e);
                        }
                    }
                }
            }
        }
    }

    Process {
        id: audioSetProcess
        property string pendingSink: ""
        command: ["pactl", "set-default-sink", pendingSink]
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
                controlCenter.refreshAudioSinks();
            }
        }
    }

    Process {
        id: audioToggleMuteProcess
        command: ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0)
                SystemServices.requestVolume();
        }
    }


    Process {
        id: ppQueryProcess
        command: ["powerprofilesctl", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    const profileName = this.text.trim();
                    controlCenter.applyBatteryModeState(true, profileName, this.text, "");
                } else {
                    controlCenter.applyBatteryModeState(false, "", "", "Failed to read profile.");
                }
            }
        }
    }

    Process {
        id: ppSetProcess
        property string pendingMode: ""
        command: ["powerprofilesctl", "set", pendingMode]
        running: false
        
        onExited: (exitCode) => {
            const success = (exitCode === 0);
            controlCenter.finishBatteryModeApply(success, exitCode, "", success ? "" : "Failed to set profile.");
        }
    }

    Process {
        id: checkHypridleProcess
        command: ["pgrep", "-x", "hypridle"]
        running: false
        onExited: (exitCode) => {
            controlCenter.caffeineMode = (exitCode !== 0);
        }
    }

    Process {
        id: queryHyprsunsetProcess
        command: ["sh", "-c", "pgrep -fa hyprsunset || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    const text = this.text.trim();
                    console.log("[NightLight] queryHyprsunsetProcess output: " + text);
                    const match = text.match(/-t\s+(\d+)/);
                    if (match && match[1]) {
                        const temp = parseInt(match[1]);
                        const v = (6500 - temp) / 4000;
                        controlCenter.syncTempFromSystem(v);
                    } else {
                        controlCenter.syncTempFromSystem(0);
                    }
                } else {
                    controlCenter.syncTempFromSystem(0);
                }
            }
        }
    }

    Timer {
        id: sliderIntroTimer
        interval: controlCenter.sliderIntroDelay
        repeat: false

        onTriggered: {
            controlCenter.sliderIntroPending = false;
            controlCenter.displayedBrightness = controlCenter.localBrightness;
            controlCenter.displayedVolume = controlCenter.localVolume;
            controlCenter.displayedTemp = controlCenter.localTemp;
        }
    }

    Timer {
        id: batteryModeRefreshTimer
        interval: 1500
        repeat: true
        onTriggered: {
            if (controlCenter.batteryModeRefreshPollsRemaining <= 0) {
                stop();
                return;
            }

            controlCenter.batteryModeRefreshPollsRemaining -= 1;
            controlCenter.refreshBatteryModeState();

            if (controlCenter.batteryModeRefreshPollsRemaining <= 0)
                stop();
        }
    }

    Timer {
        id: bluetoothScanStopTimer
        interval: 8000
        repeat: false
        onTriggered: {
            if (controlCenter.bluetoothAdapter && controlCenter.bluetoothAdapter.discovering)
                controlCenter.bluetoothAdapter.discovering = false;
            controlCenter.bluetoothInfoMessage = "";
        }
    }

    Timer {
        id: batteryDrawerSettleTimer
        interval: 300
        repeat: false
        onTriggered: controlCenter.batteryDrawerSettling = false
    }

    Connections {
        target: wifiController

        function onEnabledChanged() {
            if (!controlCenter.wifiEnabled)
                controlCenter.clearWifiPrompt();
        }
    }

    Connections {
        target: bluetoothAdapter

        function onEnabledChanged() {
            if (!controlCenter.bluetoothAdapter.enabled) {
                controlCenter.bluetoothPairAndConnectPath = "";
                controlCenter.bluetoothInfoMessage = "";
                controlCenter.bluetoothError = "";
                controlCenter.bluetoothScanStopTimer.stop();
            }
        }

        function onDiscoveringChanged() {
            if (!controlCenter.bluetoothAdapter.discovering)
                controlCenter.bluetoothScanStopTimer.stop();
        }
    }

    Connections {
        target: bluetoothPairingAgent

        function onRequestChanged() {
            controlCenter.bluetoothPendingSecretValue = "";
            if (controlCenter.bluetoothPairingActive) {
                controlCenter.bluetoothError = "";
                controlCenter.setConnectivityPanelOpen("bluetooth", true);
            }
        }

        function onRegistrationErrorChanged() {
            if (!controlCenter.bluetoothPairingAgent)
                return;

            if (!controlCenter.bluetoothPairingAgent.registered
                    && controlCenter.bluetoothPairingAgent.registrationError.length > 0
                    && controlCenter.bluetoothPanelOpen) {
                controlCenter.bluetoothError = controlCenter.bluetoothPairingAgent.registrationError;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => { mouse.accepted = true; }
        onClicked: (mouse) => { mouse.accepted = true; }
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Item {
            width: parent.width
            height: 28

            Item {
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 220
                height: parent.height

                Text {
                    id: timeLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: currentTime
                    color: StyleTokens.textPrimaryBright
                    font.pixelSize: 19
                    font.family: heroFontFamily
                    font.weight: Font.Bold
                    font.letterSpacing: -0.45
                }

                Text {
                    anchors.left: timeLabel.right
                    anchors.leftMargin: 10
                    anchors.baseline: timeLabel.baseline
                    text: currentDateLabel
                    color: textSecondary
                    font.pixelSize: 12
                    font.family: textFontFamily
                    font.weight: Font.Medium
                }
            }

            Row {
                id: headerRightRow
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Rectangle {
                    id: settingsButton
                    width: 24
                    height: 24
                    radius: 12
                    color: settingsButtonMouse.containsMouse ? "#26ffffff" : StyleTokens.transparent
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf013" // Gear icon
                        color: settingsButtonMouse.containsMouse ? "#ffffff" : StyleTokens.textSecondary
                        font.pixelSize: 14
                        font.family: iconFontFamily
                    }

                    MouseArea {
                        id: settingsButtonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (controlCenter.shellRootController) {
                                controlCenter.shellRootController.settingsWindowOpen = !controlCenter.shellRootController.settingsWindowOpen;
                            }
                        }
                    }
                }





            }
        }

        Row {
            id: tilesRow1
            width: parent.width
            spacing: 12

            Rectangle {
                id: wifiCard
                width: shortTileWidth
                height: 64
                radius: 20
                color: wifiEnabled ? cardAccent : moduleColor

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Rectangle {
                    id: wifiIconCircle
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 18
                    color: wifiEnabled ? (themeColors ? Qt.darker(themeColors.primary, 1.15) : "#2aa881") : (themeColors ? Qt.darker(themeColors.secondary_container, 1.15) : "#2d323f")

                    Text {
                        anchors.centerIn: parent
                        text: wifiGlyph
                        color: wifiEnabled ? "#121418" : cardAccent
                        font.pixelSize: 16
                        font.family: iconFontFamily
                    }
                }

                Column {
                    anchors.left: wifiIconCircle.right
                    anchors.leftMargin: 10
                    anchors.right: wifiChevronArea.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: "Wi-Fi"
                        color: wifiEnabled ? "#121418" : cardAccent
                        font.pixelSize: 13
                        font.family: textFontFamily
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: wifiStatusText
                        color: wifiEnabled ? "#2c3e35" : "#a5aab5"
                        font.pixelSize: 10
                        font.family: textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }

                Item {
                    id: wifiChevronArea
                    anchors.right: parent.right
                    width: 36
                    height: parent.height
                    visible: wifiSupported && wifiAvailable

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: wifiEnabled ? "#121418" : "#a5aab5"
                        font.pixelSize: 18
                        font.family: textFontFamily
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (wifiEnabled) {
                                controlCenter.toggleConnectivityOverlay("wifi");
                            } else {
                                controlCenter.toggleWifiEnabled();
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.left: parent.left
                    anchors.right: wifiChevronArea.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    enabled: wifiSupported && wifiAvailable && !wifiBusy
                    onClicked: {
                        controlCenter.toggleWifiEnabled();
                    }
                }
            }

            Rectangle {
                id: audioCard
                width: parent.width - wifiCard.width - 12
                height: 64
                radius: 20
                color: (!isMuted && displayedVolume > 0) ? cardAccent : moduleColor

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Rectangle {
                    id: audioIconCircle
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 18
                    color: (!isMuted && displayedVolume > 0) ? (themeColors ? Qt.darker(themeColors.primary, 1.15) : "#2aa881") : (themeColors ? Qt.darker(themeColors.secondary_container, 1.15) : "#2d323f")

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: controlCenter.volumeIconGlyph
                        color: (!isMuted && displayedVolume > 0) ? "#121418" : cardAccent
                        font.pixelSize: 16
                        font.family: iconFontFamily

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlCenter.toggleAudioMute();
                        }
                    }
                }


                Column {
                    anchors.left: audioIconCircle.right
                    anchors.leftMargin: 10
                    anchors.right: audioChevronArea.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: "Audio"
                        color: (!isMuted && displayedVolume > 0) ? "#121418" : "#ffffff"
                        font.pixelSize: 13
                        font.family: textFontFamily
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    Text {
                        width: parent.width
                        text: controlCenter.activeSinkDescription
                        color: (!isMuted && displayedVolume > 0) ? "#2c3e35" : "#a5aab5"
                        font.pixelSize: 10
                        font.family: textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }

                Item {
                    id: audioChevronArea
                    anchors.right: parent.right
                    width: 36
                    height: parent.height

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: (!isMuted && displayedVolume > 0) ? "#121418" : "#a5aab5"
                        font.pixelSize: 18
                        font.family: textFontFamily
                        font.weight: Font.Bold

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }

                MouseArea {
                    anchors.left: audioIconCircle.right
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    onClicked: {
                        controlCenter.toggleConnectivityOverlay("audio");
                    }
                }
            }
        }

        Row {
            id: tilesRow2
            width: parent.width
            spacing: 12

            Rectangle {
                id: bluetoothCard
                width: shortTileWidth
                height: 64
                radius: 20
                color: bluetoothEnabled ? cardAccent : moduleColor

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Rectangle {
                    id: bluetoothIconCircle
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 18
                    color: bluetoothEnabled ? (themeColors ? Qt.darker(themeColors.primary, 1.15) : "#2aa881") : (themeColors ? Qt.darker(themeColors.secondary_container, 1.15) : "#2d323f")

                    Text {
                        anchors.centerIn: parent
                        text: bluetoothGlyph
                        color: bluetoothEnabled ? "#121418" : cardAccent
                        font.pixelSize: 16
                        font.family: iconFontFamily
                    }
                }

                Column {
                    anchors.left: bluetoothIconCircle.right
                    anchors.leftMargin: 10
                    anchors.right: bluetoothChevronArea.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: "Bluetooth"
                        color: bluetoothEnabled ? "#121418" : "#ffffff"
                        font.pixelSize: 13
                        font.family: textFontFamily
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: bluetoothStatusText
                        color: bluetoothEnabled ? "#2c3e35" : "#a5aab5"
                        font.pixelSize: 10
                        font.family: textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }

                Item {
                    id: bluetoothChevronArea
                    anchors.right: parent.right
                    width: 36
                    height: parent.height
                    visible: bluetoothAvailable

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: bluetoothEnabled ? "#121418" : "#a5aab5"
                        font.pixelSize: 18
                        font.family: textFontFamily
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (bluetoothEnabled) {
                                controlCenter.toggleConnectivityOverlay("bluetooth");
                            } else {
                                controlCenter.toggleBluetoothEnabled();
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.left: parent.left
                    anchors.right: bluetoothChevronArea.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    enabled: bluetoothAvailable && !bluetoothBusy
                    onClicked: {
                        controlCenter.toggleBluetoothEnabled();
                    }
                }
            }

            Rectangle {
                id: caffeineCard
                width: shortTileWidth
                height: 64
                radius: 20
                color: caffeineMode ? cardAccent : moduleColor

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Rectangle {
                    id: caffeineIconCircle
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 18
                    color: caffeineMode ? (themeColors ? Qt.darker(themeColors.primary, 1.15) : "#2aa881") : (themeColors ? Qt.darker(themeColors.secondary_container, 1.15) : "#2d323f")

                    Text {
                        anchors.centerIn: parent
                        text: "\uf0f4"
                        color: caffeineMode ? "#121418" : cardAccent
                        font.pixelSize: 16
                        font.family: iconFontFamily
                    }
                }

                Column {
                    anchors.left: caffeineIconCircle.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: "Caffeine"
                        color: caffeineMode ? "#121418" : "#ffffff"
                        font.pixelSize: 13
                        font.family: textFontFamily
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: caffeineMode ? "Active" : "Off"
                        color: caffeineMode ? "#2c3e35" : "#a5aab5"
                        font.pixelSize: 10
                        font.family: textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        controlCenter.toggleCaffeineMode();
                    }
                }
            }

            Rectangle {
                id: powerModeCard
                width: shortTileWidth
                height: 64
                radius: 20
                color: {
                    if (batteryModeIndex === 0) return cardAccent;
                    if (batteryModeIndex === 2) return "#ff9f0a";
                    return moduleColor;
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Rectangle {
                    id: powerIconCircle
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 18
                    color: {
                        if (batteryModeIndex === 0) return (themeColors ? Qt.darker(themeColors.primary, 1.15) : "#2aa881");
                        if (batteryModeIndex === 2) return "#cc7f08";
                        return (themeColors ? Qt.darker(themeColors.secondary_container, 1.15) : "#2d323f");
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: controlCenter.batteryModeGlyphs[controlCenter.batteryModeIndex]
                        color: (batteryModeIndex === 0 || batteryModeIndex === 2) ? "#121418" : cardAccent
                        font.pixelSize: 16
                        font.family: iconFontFamily

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }

                Column {
                    anchors.left: powerIconCircle.right
                    anchors.leftMargin: 10
                    anchors.right: powerChevronArea.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: "Power "
                        color: (batteryModeIndex === 0 || batteryModeIndex === 2) ? "#121418" : "#ffffff"
                        font.pixelSize: 13
                        font.family: textFontFamily
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    Text {
                        width: parent.width
                        text: controlCenter.batteryModeStatusText
                        color: (batteryModeIndex === 0 || batteryModeIndex === 2) ? "#2c3e35" : "#a5aab5"
                        font.pixelSize: 10
                        font.family: textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }

                Item {
                    id: powerChevronArea
                    anchors.right: parent.right
                    width: 36
                    height: parent.height

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: (batteryModeIndex === 0 || batteryModeIndex === 2) ? "#121418" : "#a5aab5"
                        font.pixelSize: 18
                        font.family: textFontFamily
                        font.weight: Font.Bold

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        controlCenter.toggleConnectivityOverlay("battery");
                    }
                }
            }
        }

        ControlSliderCard {
            id: brightnessCard
            width: parent.width
            height: 44
            title: "Display"
            iconText: controlCenter.brightnessIconGlyph
            iconFontFamily: controlCenter.iconFontFamily
            textFontFamily: controlCenter.textFontFamily
            value: controlCenter.displayedBrightness
            knobSize: controlCenter.sliderKnobSize
            moduleColor: controlCenter.moduleColor
            moduleHover: controlCenter.moduleHover
            trackColor: controlCenter.trackColor
            textPrimary: controlCenter.textPrimary
            textSecondary: controlCenter.textSecondary
            activeColor: controlCenter.cardAccent
            activeHover: controlCenter.cardFillHover

            onInteractionStarted: {
                if (controlCenter.sliderIntroPending) {
                    sliderIntroTimer.stop();
                    controlCenter.sliderIntroPending = false;
                    controlCenter.displayedBrightness = controlCenter.localBrightness;
                    controlCenter.displayedVolume = controlCenter.localVolume;
                    controlCenter.displayedTemp = controlCenter.localTemp;
                }
            }
            onValueMoved: function(value) {
                controlCenter.queueBrightness(value);
            }
            onCommitRequested: {
                brightnessApplyTimer.stop();
                controlCenter.flushBrightness(true);
            }
            onCancelRequested: SystemServices.requestBrightness()
        }

        ControlSliderCard {
            id: volumeCard
            width: parent.width
            height: 44
            title: "Sound"
            iconText: controlCenter.volumeIconGlyph
            iconFontFamily: controlCenter.iconFontFamily
            textFontFamily: controlCenter.textFontFamily
            value: controlCenter.displayedVolume
            knobSize: controlCenter.sliderKnobSize
            moduleColor: controlCenter.moduleColor
            moduleHover: controlCenter.moduleHover
            trackColor: controlCenter.trackColor
            textPrimary: controlCenter.textPrimary
            textSecondary: controlCenter.textSecondary
            activeColor: controlCenter.cardAccent
            activeHover: controlCenter.cardFillHover

            onInteractionStarted: {
                if (controlCenter.sliderIntroPending) {
                    sliderIntroTimer.stop();
                    controlCenter.sliderIntroPending = false;
                    controlCenter.displayedBrightness = controlCenter.localBrightness;
                    controlCenter.displayedVolume = controlCenter.localVolume;
                    controlCenter.displayedTemp = controlCenter.localTemp;
                }
            }
            onValueMoved: function(value) {
                controlCenter.queueVolume(value);
            }
            onCommitRequested: {
                volumeApplyTimer.stop();
                controlCenter.flushVolume(true);
            }
            onCancelRequested: SystemServices.requestVolume()
        }

        ControlSliderCard {
            id: tempCard
            width: parent.width
            height: 44
            title: "Temperature"
            iconText: "\uf186"
            iconFontFamily: controlCenter.iconFontFamily
            textFontFamily: controlCenter.textFontFamily
            value: controlCenter.displayedTemp
            knobSize: controlCenter.sliderKnobSize
            moduleColor: controlCenter.moduleColor
            moduleHover: controlCenter.moduleHover
            trackColor: controlCenter.trackColor
            textPrimary: controlCenter.textPrimary
            textSecondary: controlCenter.textSecondary
            activeColor: controlCenter.cardAccent
            activeHover: controlCenter.cardFillHover

            onInteractionStarted: {
                if (controlCenter.sliderIntroPending) {
                    sliderIntroTimer.stop();
                    controlCenter.sliderIntroPending = false;
                    controlCenter.displayedBrightness = controlCenter.localBrightness;
                    controlCenter.displayedVolume = controlCenter.localVolume;
                    controlCenter.displayedTemp = controlCenter.localTemp;
                }
            }
            onValueMoved: function(value) {
                controlCenter.queueTemp(value);
            }
            onCommitRequested: {
                tempApplyTimer.stop();
                controlCenter.flushTemp(true);
            }
            onCancelRequested: queryHyprsunsetProcess.running = true
        }

        Item {
            width: parent.width
            height: parent.height - y - 12
            clip: true

            Rectangle {
                id: notificationsDivider
                width: parent.width
                height: 1
                color: "#2c3038"
                opacity: 0.8
                anchors.top: parent.top
            }

            Item {
                id: notificationsHeader
                anchors.top: notificationsDivider.bottom
                anchors.topMargin: 12
                width: parent.width
                height: 20

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: "Notifications"
                        color: StyleTokens.textMuted
                        font.pixelSize: 11
                        font.family: textFontFamily
                        font.weight: Font.Medium
                    }

                    // DND Toggle Button
                    Item {
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: dndActive ? "#ff453a" : (themeColors ? themeColors.secondary_container : "#2c2c2e")
                            opacity: dndMouseArea.containsMouse ? 1.0 : 0.8
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: dndActive ? "\u{F00A0}" : "\uf0f3" // bell-sleep (bell with zzz's) or normal bell
                            font.family: iconFontFamily
                            font.pixelSize: 11
                            color: dndActive ? "#ffffff" : StyleTokens.textMuted

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: dndMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                controlCenter.dndToggleRequested();
                            }
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clear all"
                    color: "#3bc99d"
                    font.pixelSize: 11
                    font.family: textFontFamily
                    font.weight: Font.Medium
                    visible: notificationModel && notificationModel.count > 0

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (notificationModel) {
                                notificationModel.clear();
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 10
                text: "No new notifications"
                color: StyleTokens.textMuted
                font.pixelSize: 12
                font.family: textFontFamily
                visible: !notificationModel || notificationModel.count === 0
            }

            ListView {
                id: notificationsList
                anchors.top: notificationsHeader.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 8
                model: notificationModel
                interactive: contentHeight > height
                clip: true

                delegate: Rectangle {
                    id: notificationItem
                    width: notificationsList.width
                    height: 72
                    radius: 12
                    color: notificationMouseArea.containsMouse ? "#272a34" : "#1c1f26"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: notificationMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("[Notification] Clicked notification from app: " + appName + ", summary: " + summary);
                            const home = controlCenter.shellRootController ? controlCenter.shellRootController.getHomePath() : (Quickshell.env("HOME") || "");
                            Quickshell.execDetached([home + "/.local/src/HyprDots/tide-island/bin/redirect_app.py", appName, summary, body]);
                            if (controlCenter.shellRootController) {
                                controlCenter.shellRootController.forEachWindow((w) => {
                                    if (w && w.toggleControlCenter)
                                        w.toggleControlCenter();
                                });
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        width: 16
                        height: 16
                        radius: 8
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: StyleTokens.textMuted
                            font.pixelSize: 10
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                notificationModel.remove(index);
                            }
                        }
                    }

                    Rectangle {
                        id: appIconBox
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        radius: 16
                        color: "#2d323f"

                        Text {
                            anchors.centerIn: parent
                            text: appName && appName.length > 0 ? appName[0].toUpperCase() : "I"
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            font.family: textFontFamily
                        }
                    }

                    Column {
                        anchors.left: appIconBox.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 36
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Row {
                            spacing: 6
                            width: parent.width

                            Text {
                                text: appName
                                color: StyleTokens.textMuted
                                font.pixelSize: 10
                                font.family: textFontFamily
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "•"
                                color: StyleTokens.textMuted
                                font.pixelSize: 10
                                visible: timestamp && timestamp.length > 0
                            }

                            Text {
                                text: timestamp
                                color: StyleTokens.textMuted
                                font.pixelSize: 10
                                font.family: textFontFamily
                                visible: timestamp && timestamp.length > 0
                            }
                        }

                        Text {
                            width: parent.width
                            text: summary
                            color: StyleTokens.textPrimary
                            font.pixelSize: 12
                            font.family: textFontFamily
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: body
                            color: StyleTokens.textSecondary
                            font.pixelSize: 11
                            font.family: textFontFamily
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
