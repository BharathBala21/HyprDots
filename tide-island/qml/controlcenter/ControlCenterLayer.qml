import QtQuick
import QtQuick.Effects
import QtQml
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Mpris
import IslandBackend

Item {
    id: controlCenter

    signal connectivityPanelRequested(string kind, bool open)
    signal batteryModeIndexChangedExternal(int index)
    signal dndToggleRequested()
    signal tempChanged(real val)
    signal timerRequested()

    readonly property var userConfig: UserConfig

    FileView {
        id: ccCfgWatcher
        path: (Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")) + "/.config/tide-island/userconfig.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: ccCfgWatcher.reload()
    }

    readonly property var ccCfgData: {
        try {
            return ccCfgWatcher.text() ? JSON.parse(ccCfgWatcher.text()) : {};
        } catch (e) {
            return {};
        }
    }

    readonly property string tlpPermissionMode: ccCfgData.tlpPermissionMode !== undefined ? String(ccCfgData.tlpPermissionMode) : "password"

    property bool showCondition: false
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    property var shellRootController: null

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
    property string currentArtUrl: ""
    property string timePlayed: "0:00"
    property string timeTotal: "0:00"
    property real trackProgress: 0
    property var activePlayer: null
    property bool musicPlaying: false
    property bool screenRecordingActive: false
    property bool timerRunning: false
    property int timerRemainingSeconds: 0

    function formatTimerTime(sec) {
        const m = Math.floor(sec / 60);
        const s = sec % 60;
        return (m < 10 ? "0" + m : String(m)) + ":" + (s < 10 ? "0" + s : String(s));
    }

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

    property bool batteryModeBusy: false
    property bool batteryModeStateRunning: false
    property bool batteryModeSetterRunning: false
    property bool batteryTlpAvailable: false
    property bool batteryTlpChecked: false
    property int batteryModeInitialIndex: 1
    property int batteryModeIndex: batteryModeInitialIndex
    property int batteryModeAppliedIndex: batteryModeInitialIndex
    property int batteryModePendingIndex: 1
    property string batteryModeInfoMessage: ""
    property string batteryModeError: ""
    property string batteryModeLastCommandOutput: ""
    property int batteryModeRefreshPollsRemaining: 0

    onBatteryModeIndexChanged: {
        batteryModeIndexChangedExternal(batteryModeIndex);
    }

    property bool dndActive: false
    property bool caffeineMode: false
    readonly property bool darkMode: shellRootController ? shellRootController.darkMode : true

    property real tempLevel: 0.0
    property real localTemp: tempLevel
    property real displayedTemp: 0.0
    property real pendingTemp: 0.0
    property real lastAppliedTemp: 0.0
    property bool tempSetterRunning: false

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

    // Notification drawer expansion
    property bool notificationsExpanded: false
    property real controlCenterExtraHeight: notificationsExpanded ? 220 : 0
    Behavior on controlCenterExtraHeight {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    // Power menu popup
    property bool powerMenuOpen: false

    // Screen recording timer
    property int recordingElapsedSeconds: 0
    property double recordingStartTime: 0

    onScreenRecordingActiveChanged: {
        if (screenRecordingActive) {
            recordingStartTime = Date.now();
            recordingElapsedSeconds = 0;
            recordingTimer.start();
        } else {
            recordingTimer.stop();
            recordingElapsedSeconds = 0;
        }
    }

    Timer {
        id: recordingTimer
        interval: 1000
        repeat: true
        running: controlCenter.screenRecordingActive
        onTriggered: {
            if (controlCenter.recordingStartTime > 0) {
                controlCenter.recordingElapsedSeconds = Math.max(0, Math.floor((Date.now() - controlCenter.recordingStartTime) / 1000));
            } else {
                controlCenter.recordingElapsedSeconds += 1;
            }
        }
    }

    function formatRecordingTime(sec) {
        const m = Math.floor(sec / 60);
        const s = sec % 60;
        return (m < 10 ? "0" + m : String(m)) + ":" + (s < 10 ? "0" + s : String(s));
    }

    // Audio waveform animation phase
    property real wavePhase: 0
    NumberAnimation {
        id: waveAnim
        target: controlCenter
        property: "wavePhase"
        from: 0
        to: Math.PI * 2
        duration: 2400
        loops: Animation.Infinite
        running: controlCenter.showCondition && (controlCenter.musicPlaying || (controlCenter.activePlayer && controlCenter.activePlayer.playbackState === MprisPlaybackState.Playing))
    }

    function waveformHeight(index, total) {
        if (!controlCenter.musicPlaying && (!controlCenter.activePlayer || controlCenter.activePlayer.playbackState !== MprisPlaybackState.Playing)) {
            const baseShape = Math.sin((index / total) * Math.PI);
            return 3 + baseShape * 10;
        }
        const norm = index / total;
        const baseShape = Math.sin(norm * Math.PI);
        const dynamic = Math.sin(controlCenter.wavePhase + index * 0.45);
        const dynamic2 = Math.cos(controlCenter.wavePhase * 1.5 + index * 0.7);
        const val = (baseShape * 0.5 + (dynamic + 1) * 0.25 + (dynamic2 + 1) * 0.25);
        return 3 + Math.max(0, Math.min(18, val * 18));
    }

    // Date formatting helpers matching the sketch (e.g. "24th February", "Thursday")
    readonly property var nowObj: new Date()
    property string formattedDayOfWeek: getDayOfWeek(nowObj)
    property string formattedOrdinalDate: getFormattedDate(nowObj)

    Timer {
        id: dateUpdateTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            const d = new Date();
            controlCenter.formattedDayOfWeek = controlCenter.getDayOfWeek(d);
            controlCenter.formattedOrdinalDate = controlCenter.getFormattedDate(d);
        }
    }

    function getDayOfWeek(date) {
        const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        return days[date.getDay()];
    }

    function getFormattedDate(date) {
        const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        const d = date.getDate();
        let suffix = "th";
        if (d === 1 || d === 21 || d === 31) suffix = "st";
        else if (d === 2 || d === 22) suffix = "nd";
        else if (d === 3 || d === 23) suffix = "rd";
        return d + suffix + " " + months[date.getMonth()];
    }

    Instantiator {
        id: wifiSignalTracker
        model: wifiController ? wifiController.networks : null
        onObjectAdded: (index, object) => updateSignal()
        onObjectRemoved: (index, object) => updateSignal()

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
        }
    }

    readonly property var themeColors: shellRootController ? shellRootController.matugenThemeColors : null

    readonly property color panelColor: themeColors ? themeColors.background : StyleTokens.panel
    readonly property color moduleColor: themeColors ? themeColors.secondary_container : "#1c1c1e"
    readonly property color moduleHover: themeColors ? Qt.lighter(themeColors.secondary_container, 1.15) : "#252528"
    readonly property color trackColor: themeColors ? themeColors.secondary_container : "#2c2c2e"
    readonly property color textPrimary: themeColors ? themeColors.on_surface : "#ffffff"
    readonly property color textSecondary: themeColors ? themeColors.on_surface_variant : "#8e8e93"
    readonly property color cardAccent: themeColors ? themeColors.primary : "#0a84ff"
    readonly property color cardAccentPressed: themeColors ? Qt.darker(themeColors.primary, 1.15) : "#0066cc"

    readonly property string wifiGlyph: {
        if (!wifiEnabled) return "\u{F05AE}";
        if (wifiCurrentSsid.length === 0 || wifiSignal < 0) return "\u{F05AD}";
        if (wifiSignal >= 75) return "\u{F05AC}";
        if (wifiSignal >= 50) return "\u{F05AB}";
        if (wifiSignal >= 25) return "\u{F05AA}";
        return "\u{F05A9}";
    }
    readonly property string bluetoothGlyph: ""
    readonly property string chargingIconGlyph: "\uf0e7"
    readonly property string brightnessIconGlyph: "\u{F00DF}"
    readonly property string volumeIconGlyph: volumeGlyph(displayedVolume, isMuted)

    property var notificationModel: null
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
    readonly property string wifiStatusText: wifiController ? wifiController.statusText : "Unavailable"

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
    readonly property string bluetoothStatusText: buildBluetoothStatusText()
    readonly property string bluetoothAvailabilityMessage: bluetoothAvailable ? "" : "No Bluetooth adapter is available."

    readonly property bool hasConnectivityPrompt: wifiPendingPasswordSsid.length > 0 || bluetoothPairingActive
    readonly property string batteryModeStatusText: buildBatteryModeStatusText()

    function clamp01(value) {
        return Math.max(0, Math.min(1, value));
    }

    function trimString(value) {
        if (value === undefined || value === null) return "";
        return String(value).trim();
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

    function requestWifiStateRefresh() {
        if (!showCondition || !wifiController) return;
        wifiController.refreshState();
    }

    function requestWifiListRefresh(rescan) {
        if (!showCondition || !wifiController) return;
        if (!wifiSupported || !wifiAvailable || !wifiEnabled) return;
        wifiController.refreshNetworks(!!rescan);
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
        if (bluetoothAdapter && bluetoothAdapter.discovering) return "Scanning";
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

    function refreshBatteryModeState() {
        if (batteryModeStateRunning) return;
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
        if (trimString(controlCenter.tlpPermissionMode) === "skip") return "Power modes disabled";
        if (!batteryTlpChecked) return "Checking power profiles...";
        if (!batteryTlpAvailable) return "power-profiles-daemon is not installed";
        return batteryModeLabel(batteryModeIndex);
    }

    function rollbackBatteryMode(message) {
        batteryModeBusy = false;
        batteryModeError = message;
        batteryModeInfoMessage = "";
        setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
    }

    function selectBatteryMode(index) {
        if (batteryModeBusy) {
            if (batteryModeSetterRunning) ppSetProcess.running = false;
            batteryModeBusy = false;
            batteryModeSetterRunning = false;
        }

        const nextIndex = Math.max(0, Math.min(2, index));
        if (trimString(controlCenter.tlpPermissionMode) === "skip") {
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
        
        ppSetProcess.pendingMode = batteryModeCommand(nextIndex);
        ppSetProcess.running = true;
    }

    function finishBatteryModeApply(success, exitCode, output, errorString) {
        batteryModeSetterRunning = false;
        batteryModeBusy = false;
        if (!success) {
            rollbackBatteryMode("Failed to apply power mode.");
            return;
        }
        batteryModeAppliedIndex = batteryModePendingIndex;
        batteryModeError = "";
        batteryModeInfoMessage = batteryModeLabel(batteryModeAppliedIndex) + " active.";
        setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
        refreshBatteryModeState();
    }

    function isConnectivityPanelOpen(kind) {
        if (kind === "wifi") return wifiPanelOpen;
        if (kind === "bluetooth") return bluetoothPanelOpen;
        if (kind === "battery") return batteryPanelOpen;
        if (kind === "audio") return audioPanelOpen;
        return false;
    }

    function setConnectivityPanelOpen(kind, open, emitSignal) {
        if (emitSignal === undefined) emitSignal = true;
        const nextOpen = !!open;

        if (nextOpen) {
            if (kind !== "wifi" && wifiPanelOpen) setConnectivityPanelOpen("wifi", false, emitSignal);
            if (kind !== "bluetooth" && bluetoothPanelOpen) setConnectivityPanelOpen("bluetooth", false, emitSignal);
            if (kind !== "battery" && batteryPanelOpen) setConnectivityPanelOpen("battery", false, emitSignal);
            if (kind !== "audio" && audioPanelOpen) setConnectivityPanelOpen("audio", false, emitSignal);
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

            if (nextOpen) {
                if (showCondition && bluetoothAdapter && bluetoothEnabled) {
                    toggleBluetoothScan();
                }
            } else {
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
            if (nextOpen && showCondition) refreshAudioSinks();
        }

        if (changed && emitSignal)
            connectivityPanelRequested(kind, nextOpen);
    }

    function toggleConnectivityOverlay(kind) {
        setConnectivityPanelOpen(kind, !isConnectivityPanelOpen(kind));
    }

    function closeConnectivityPanels(emitSignals) {
        if (emitSignals === undefined) emitSignals = true;
        setConnectivityPanelOpen("wifi", false, emitSignals);
        setConnectivityPanelOpen("bluetooth", false, emitSignals);
        setConnectivityPanelOpen("battery", false, emitSignals);
        setConnectivityPanelOpen("audio", false, emitSignals);
        clearWifiPrompt();
        clearWifiMessages();
        clearBluetoothMessages();
    }

    function toggleWifiEnabled() {
        if (wifiController) wifiController.setEnabled(!wifiEnabled);
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

    function toggleScreenRecording() {
        const home = Quickshell.env("HOME") || "";
        const recordScript = Quickshell.shellDir + "/bin/record.sh";
        if (screenRecordingActive) {
            Quickshell.execDetached([recordScript]);
        } else {
            Quickshell.execDetached([recordScript, "-r"]);
        }
    }

    function togglePlayback() {
        if (!activePlayer || !activePlayer.canControl) return;
        if (activePlayer.canTogglePlaying) {
            activePlayer.togglePlaying();
            return;
        }
        if (activePlayer.playbackState === MprisPlaybackState.Playing) {
            if (activePlayer.canPause) activePlayer.pause();
            return;
        }
        if (activePlayer.canPlay) activePlayer.play();
    }

    function toSeconds(value) {
        const num = Number(value);
        if (isNaN(num) || num <= 0) return 0;
        if (num > 10000000) return num / 1000000;
        if (num > 10000) return num / 1000;
        return num;
    }

    function formatTrackTime(value) {
        const sec = Math.floor(toSeconds(value));
        if (sec <= 0) return "0:00";
        const hours = Math.floor(sec / 3600);
        const minutes = Math.floor((sec % 3600) / 60);
        const seconds = sec % 60;
        const secStr = seconds < 10 ? "0" + seconds : String(seconds);
        if (hours > 0) {
            const minStr = minutes < 10 ? "0" + minutes : String(minutes);
            return hours + ":" + minStr + ":" + secStr;
        }
        return minutes + ":" + secStr;
    }

    function updateTrackProgress() {
        if (!activePlayer) return;
        const posSec = toSeconds(activePlayer.position);
        let lenRaw = Number(activePlayer.length) || 0;
        if (lenRaw <= 0 && activePlayer.metadata && activePlayer.metadata["mpris:length"])
            lenRaw = Number(activePlayer.metadata["mpris:length"]);
        const lenSec = toSeconds(lenRaw);

        if (lenSec > 0) {
            controlCenter.trackProgress = Math.max(0, Math.min(1, posSec / lenSec));
            controlCenter.timePlayed = formatTrackTime(posSec);
            controlCenter.timeTotal = formatTrackTime(lenSec);
        } else {
            controlCenter.trackProgress = 0;
            controlCenter.timePlayed = formatTrackTime(posSec);
            controlCenter.timeTotal = "0:00";
        }
    }

    Timer {
        id: ccProgressTimer
        interval: 500
        repeat: true
        running: controlCenter.showCondition && controlCenter.activePlayer !== null
        triggeredOnStart: true
        onTriggered: controlCenter.updateTrackProgress()
    }

    function seekTrack(progress) {
        if (!activePlayer || !activePlayer.canControl) return;
        let lenRaw = Number(activePlayer.length) || 0;
        if (lenRaw <= 0 && activePlayer.metadata && activePlayer.metadata["mpris:length"])
            lenRaw = Number(activePlayer.metadata["mpris:length"]);
        const lenSec = toSeconds(lenRaw);
        if (lenSec > 0) {
            const targetPosSec = Math.max(0, Math.min(lenSec, progress * lenSec));
            activePlayer.position = targetPosSec;
            controlCenter.trackProgress = progress;
            controlCenter.timePlayed = formatTrackTime(targetPosSec);
        }
    }

    function volumeGlyph(value, muted) {
        if (muted) return "\u{F075F}";
        if (value <= 0) return "\u{F0581}";
        if (value < 0.33) return "\u{F057F}";
        if (value < 0.66) return "\u{F0580}";
        return "\u{F057E}";
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

    function tempFromValue(v) {
        return Math.round(6500 - v * 4000);
    }

    function queueTemp(value) {
        localTemp = clamp01(value);
        if (showCondition && !sliderIntroPending) displayedTemp = localTemp;
        pendingTemp = localTemp;
        tempApplyTimer.restart();
    }

    function flushTemp(force) {
        const nextValue = clamp01(pendingTemp);
        if (!force && Math.abs(nextValue - lastAppliedTemp) < 0.02) return;
        lastAppliedTemp = nextValue;
        if (nextValue < 0.05) {
            Quickshell.execDetached(["sh", "-c", "hyprctl hyprsunset identity || pkill -x hyprsunset"]);
        } else {
            const targetK = tempFromValue(nextValue);
            Quickshell.execDetached(["sh", "-c", "hyprctl hyprsunset temperature " + targetK + " || (hyprsunset -t " + targetK + " &)"]);
        }
    }

    Timer {
        id: tempApplyTimer
        interval: 100
        repeat: false
        onTriggered: controlCenter.flushTemp(false)
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
                controlCenter.applyBatteryModeState(false, "", "", "power-profiles-daemon is not installed.");
            }
        }
    }

    function syncBrightnessFromLevel(level) {
        if (level < 0 || sliderIntroPending) return;
        localBrightness = clamp01(level);
        if (showCondition && !sliderIntroPending) displayedBrightness = localBrightness;
        pendingBrightness = localBrightness;
        lastAppliedBrightness = localBrightness;
    }

    function syncVolumeFromLevel(level) {
        if (level < 0 || sliderIntroPending) return;
        localVolume = clamp01(level);
        if (showCondition && !sliderIntroPending) displayedVolume = localVolume;
        pendingVolume = localVolume;
        lastAppliedVolume = localVolume;
    }

    function syncTempFromLevel(level) {
        if (level < 0 || sliderIntroPending) return;
        localTemp = clamp01(level);
        if (showCondition && !sliderIntroPending) displayedTemp = localTemp;
        pendingTemp = localTemp;
        lastAppliedTemp = localTemp;
    }

    function refreshAudioSinks() {
        audioQueryProcess.running = true;
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
                                if (isDefault) activeDesc = s.description;
                                cleanedSinks.push({
                                    name: s.name,
                                    description: s.description,
                                    connected: isDefault,
                                    deviceType: (s.name.indexOf("bluez") !== -1 || s.description.toLowerCase().indexOf("headset") !== -1 || s.description.toLowerCase().indexOf("headphone") !== -1) ? "headset" : "speaker"
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
        id: ppQueryProcess
        command: ["powerprofilesctl", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    controlCenter.applyBatteryModeState(true, this.text.trim(), this.text, "");
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
        }
    }

    Connections {
        target: SystemServices
        function onBrightnessSnapshotReady(value, errorString) {
            if (errorString === "") syncBrightnessFromLevel(value);
        }
        function onBrightnessSetFinished(value, success, errorString) {
            controlCenter.brightnessSetterRunning = false;
            if (success) syncBrightnessFromLevel(value);
        }
        function onVolumeSnapshotReady(value, muted, errorString) {
            if (errorString === "") {
                syncVolumeFromLevel(value);
                controlCenter.isMuted = !!muted;
            }
        }
        function onVolumeSetFinished(value, success, errorString) {
            controlCenter.volumeSetterRunning = false;
            if (success) syncVolumeFromLevel(value);
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

    anchors.fill: parent
    anchors.margins: 18
    opacity: showCondition ? 1 : 0
    visible: opacity > 0

    onBrightnessLevelChanged: syncBrightnessFromLevel(brightnessLevel)
    onVolumeLevelChanged: syncVolumeFromLevel(volumeLevel)
    onTempLevelChanged: syncTempFromLevel(tempLevel)

    onShowConditionChanged: {
        if (showCondition) {
            sliderIntroPending = true;
            syncBrightnessFromLevel(brightnessLevel);
            syncVolumeFromLevel(volumeLevel);
            syncTempFromLevel(tempLevel);
            displayedBrightness = localBrightness;
            displayedVolume = localVolume;
            displayedTemp = localTemp;
            sliderIntroTimer.interval = sliderIntroDelay;
            sliderIntroTimer.restart();
            refreshBatteryModeState();
            refreshAudioSinks();
            checkHypridleProcess.running = true;
        } else {
            sliderIntroTimer.stop();
            sliderIntroPending = false;
            closeConnectivityPanels();
            powerMenuOpen = false;
        }
    }

    Component.onCompleted: {
        syncBrightnessFromLevel(brightnessLevel);
        syncVolumeFromLevel(volumeLevel);
        syncTempFromLevel(tempLevel);
        displayedBrightness = localBrightness;
        displayedVolume = localVolume;
        displayedTemp = localTemp;
        SystemServices.requestBrightness();
        SystemServices.requestVolume();
        refreshBatteryModeState();
        refreshAudioSinks();
        checkHypridleProcess.running = true;
    }

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 240 : 100
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on displayedBrightness {
        enabled: controlCenter.showCondition && !controlCenter.sliderIntroPending
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }

    Behavior on displayedVolume {
        enabled: controlCenter.showCondition && !controlCenter.sliderIntroPending
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }

    Behavior on displayedTemp {
        enabled: controlCenter.showCondition && !controlCenter.sliderIntroPending
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => { mouse.accepted = true; }
        onClicked: (mouse) => { mouse.accepted = true; }
    }

    // ================= MAIN LAYOUT =================
    Column {
        anchors.fill: parent
        spacing: 12

        // TOP HEADER: Clock, Date/Day & Actions
        Item {
            width: parent.width
            height: 38

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // Large digital clock
                Text {
                    id: timeLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: controlCenter.currentTime
                    color: "#ffffff"
                    font.pixelSize: 25
                    font.family: heroFontFamily
                    font.weight: Font.Bold
                    font.letterSpacing: -0.5
                }

                // Vertical divider line
                Rectangle {
                    width: 1.5
                    height: 28
                    radius: 1
                    color: "#38383a"
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Date & Day column
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: controlCenter.formattedOrdinalDate
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.family: textFontFamily
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: controlCenter.formattedDayOfWeek
                        color: "#8e8e93"
                        font.pixelSize: 11
                        font.family: textFontFamily
                        font.weight: Font.Medium
                    }
                }
            }

            // Right header icons: Power & Settings
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // Power button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: powerButtonMouse.containsMouse || controlCenter.powerMenuOpen ? "#33ffffff" : "#1c1c1e"
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf011" // Power icon
                        color: controlCenter.powerMenuOpen ? "#ff453a" : (powerButtonMouse.containsMouse ? "#ffffff" : "#8e8e93")
                        font.pixelSize: 15
                        font.family: iconFontFamily
                    }

                    MouseArea {
                        id: powerButtonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controlCenter.powerMenuOpen = !controlCenter.powerMenuOpen
                    }
                }

                // Settings button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: settingsButtonMouse.containsMouse ? "#33ffffff" : "#1c1c1e"
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf013" // Gear icon
                        color: settingsButtonMouse.containsMouse ? "#ffffff" : "#8e8e93"
                        font.pixelSize: 15
                        font.family: iconFontFamily
                    }

                    MouseArea {
                        id: settingsButtonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (controlCenter.shellRootController) {
                                controlCenter.shellRootController.settingsWindowOpen = !controlCenter.shellRootController.settingsWindowOpen;
                            }
                        }
                    }
                }
            }
        }

        // Optional Power Menu Dropdown Row
        Item {
            width: parent.width
            height: controlCenter.powerMenuOpen ? 38 : 0
            visible: height > 0
            clip: true

            Behavior on height {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "#252528"

                Row {
                    anchors.centerIn: parent
                    spacing: 16

                    // Lock
                    Rectangle {
                        width: 76
                        height: 28
                        radius: 8
                        color: lockMouse.containsMouse ? "#3a3a3c" : "#1c1c1e"
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "\uf023"; color: "#ffffff"; font.family: iconFontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Lock"; color: "#ffffff"; font.family: textFontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            id: lockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                controlCenter.powerMenuOpen = false;
                                Quickshell.execDetached([Quickshell.env("HOME") + "/.local/src/HyprDots/tide-island/lockscreen/lock.sh"]);
                            }
                        }
                    }

                    // Suspend
                    Rectangle {
                        width: 76
                        height: 28
                        radius: 8
                        color: suspendMouse.containsMouse ? "#3a3a3c" : "#1c1c1e"
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "\uf186"; color: "#ffffff"; font.family: iconFontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Sleep"; color: "#ffffff"; font.family: textFontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            id: suspendMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                controlCenter.powerMenuOpen = false;
                                Quickshell.execDetached(["systemctl", "suspend"]);
                            }
                        }
                    }

                    // Reboot
                    Rectangle {
                        width: 76
                        height: 28
                        radius: 8
                        color: rebootMouse.containsMouse ? "#3a3a3c" : "#1c1c1e"
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "\uf021"; color: "#ff9f0a"; font.family: iconFontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Reboot"; color: "#ffffff"; font.family: textFontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            id: rebootMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                controlCenter.powerMenuOpen = false;
                                Quickshell.execDetached(["systemctl", "reboot"]);
                            }
                        }
                    }

                    // Power Off
                    Rectangle {
                        width: 76
                        height: 28
                        radius: 8
                        color: poweroffMouse.containsMouse ? "#ff453a" : "#1c1c1e"
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "\uf011"; color: poweroffMouse.containsMouse ? "#ffffff" : "#ff453a"; font.family: iconFontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Shut Down"; color: "#ffffff"; font.family: textFontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            id: poweroffMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                controlCenter.powerMenuOpen = false;
                                Quickshell.execDetached(["systemctl", "poweroff"]);
                            }
                        }
                    }
                }
            }
        }

        // ================= TWO-COLUMN GRID (Quick Controls) =================
        Row {
            width: parent.width
            height: 192
            spacing: 12

            // -------- LEFT COLUMN (~54% width) --------
            Column {
                width: (parent.width - 12) * 0.54
                height: parent.height
                spacing: 8

                // 1. BATTERY & POWER PROFILES CARD
                Rectangle {
                    width: parent.width
                    height: 76
                    radius: 18
                    color: "#1c1c1e"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    // Card header
                    Item {
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        height: 20

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Text {
                                text: "Battery"
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.family: textFontFamily
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: (controlCenter.batteryCapacity > 0 ? (controlCenter.batteryCapacity + "%") : "") + (controlCenter.isCharging ? " \uf0e7" : "")
                                color: "#8e8e93"
                                font.pixelSize: 11
                                font.family: iconFontFamily
                                visible: controlCenter.batteryCapacity > 0 || controlCenter.isCharging
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: controlCenter.batteryModeStatusText
                            color: "#8e8e93"
                            font.pixelSize: 11
                            font.family: textFontFamily
                            font.weight: Font.Medium
                        }
                    }

                    // Mode switcher pills (Leaf, Battery, Lightning)
                    Row {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        height: 28
                        spacing: 6

                        Repeater {
                            model: [
                                { icon: "\uf06c", label: "Power Saver" },
                                { icon: "\uf242", label: "Balanced" },
                                { icon: "\uf0e7", label: "Performance" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: (parent.width - 12) / 3
                                height: 28
                                radius: 14
                                color: controlCenter.batteryModeIndex === index ? "#ffffff" : (pillMouse.containsMouse ? "#323236" : "#2c2c2e")

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: index === controlCenter.batteryModeIndex ? "#121418" : "#8e8e93"
                                    font.pixelSize: 13
                                    font.family: iconFontFamily
                                }

                                MouseArea {
                                    id: pillMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: controlCenter.selectBatteryMode(index)
                                }
                            }
                        }
                    }
                }

                // 2. MIDDLE ROW: RECORDING CARD & TIMER CARD (Side-by-side)
                Row {
                    width: parent.width
                    height: 52
                    spacing: 8

                    readonly property real cardWidth: (width - 8) / 2

                    // 2a. SCREEN RECORDING CARD
                    Rectangle {
                        width: parent.cardWidth
                        height: 52
                        radius: 16
                        color: controlCenter.screenRecordingActive ? "#321618" : (recMouse.containsMouse ? "#242428" : "#1c1c1e")
                        border.width: controlCenter.screenRecordingActive ? 1 : 0
                        border.color: controlCenter.screenRecordingActive ? "#ff453a55" : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            // Record / Stop Badge
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: controlCenter.screenRecordingActive ? "#ff453a" : "#2c2c2e"
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: controlCenter.screenRecordingActive ? 9 : 10
                                    height: controlCenter.screenRecordingActive ? 9 : 10
                                    radius: controlCenter.screenRecordingActive ? 2 : 5
                                    color: controlCenter.screenRecordingActive ? "#ffffff" : "#ff453a"
                                    anchors.centerIn: parent
                                }
                            }

                            // Text Column
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                width: parent.width - 36

                                Text {
                                    text: controlCenter.screenRecordingActive
                                        ? ("Rec " + controlCenter.formatRecordingTime(controlCenter.recordingElapsedSeconds))
                                        : "Record"
                                    color: controlCenter.screenRecordingActive ? "#ff453a" : "#ffffff"
                                    font.pixelSize: 11
                                    font.family: textFontFamily
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: controlCenter.screenRecordingActive ? "Stop" : "Start"
                                    color: "#8e8e93"
                                    font.pixelSize: 10
                                    font.family: textFontFamily
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        MouseArea {
                            id: recMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlCenter.toggleScreenRecording()
                        }
                    }

                    // 2b. CLOCK / TIMER CARD
                    Rectangle {
                        width: parent.cardWidth
                        height: 52
                        radius: 16
                        color: controlCenter.timerRunning ? "#1a2a3a" : (timerMouse.containsMouse ? "#242428" : "#1c1c1e")
                        border.width: controlCenter.timerRunning ? 1 : 0
                        border.color: controlCenter.timerRunning ? "#0a84ff55" : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            // Clock / Timer Icon Badge
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: controlCenter.timerRunning ? "#0a84ff" : "#2c2c2e"
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf017" // Clock icon
                                    color: controlCenter.timerRunning ? "#ffffff" : (controlCenter.themeColors ? controlCenter.themeColors.primary : "#0a84ff")
                                    font.pixelSize: 13
                                    font.family: iconFontFamily
                                }
                            }

                            // Text Column
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                width: parent.width - 36

                                Text {
                                    text: controlCenter.timerRunning
                                        ? controlCenter.formatTimerTime(controlCenter.timerRemainingSeconds)
                                        : "Timer"
                                    color: controlCenter.timerRunning ? "#0a84ff" : "#ffffff"
                                    font.pixelSize: 11
                                    font.family: textFontFamily
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: controlCenter.timerRunning ? "Active" : "Open timer"
                                    color: "#8e8e93"
                                    font.pixelSize: 10
                                    font.family: textFontFamily
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        MouseArea {
                            id: timerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlCenter.timerRequested()
                        }
                    }
                }

                // 3. COFFEE MODE CARD
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 16
                    color: coffeeMouse.containsMouse ? "#242428" : "#1c1c1e"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Text {
                                text: "\uf0f4" // Coffee cup
                                color: controlCenter.caffeineMode ? "#ff9f0a" : "#8e8e93"
                                font.pixelSize: 15
                                font.family: iconFontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Coffee mode"
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.family: textFontFamily
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // iOS-style Toggle Switch
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38
                            height: 22
                            radius: 11
                            color: controlCenter.caffeineMode ? "#ff9f0a" : "#39393d"

                            Behavior on color { ColorAnimation { duration: 180 } }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: controlCenter.caffeineMode ? 18 : 2

                                Behavior on x {
                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: coffeeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controlCenter.toggleCaffeineMode()
                    }
                }
            }

            // -------- RIGHT COLUMN (~46% width) --------
            Column {
                width: (parent.width - 12) * 0.46
                height: parent.height
                spacing: 8

                // 1. TOP ROW: 3 CIRCULAR TOGGLE BUTTONS
                Row {
                    width: parent.width
                    height: 48
                    spacing: 8

                    readonly property real circleSize: (width - 16) / 3

                    // Wi-Fi Button
                    Rectangle {
                        width: parent.circleSize
                        height: 48
                        radius: 24
                        color: controlCenter.wifiEnabled ? (controlCenter.themeColors ? controlCenter.themeColors.primary : "#0a84ff") : (wifiBtnMouse.containsMouse ? "#28282c" : "#1c1c1e")

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: controlCenter.wifiGlyph
                            color: controlCenter.wifiEnabled ? "#ffffff" : "#8e8e93"
                            font.pixelSize: 18
                            font.family: iconFontFamily
                        }

                        MouseArea {
                            id: wifiBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    controlCenter.toggleConnectivityOverlay("wifi");
                                } else {
                                    controlCenter.toggleWifiEnabled();
                                }
                            }
                        }
                    }

                    // Bluetooth Button
                    Rectangle {
                        width: parent.circleSize
                        height: 48
                        radius: 24
                        color: controlCenter.bluetoothEnabled ? (controlCenter.themeColors ? controlCenter.themeColors.primary : "#0a84ff") : (btBtnMouse.containsMouse ? "#28282c" : "#1c1c1e")

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: controlCenter.bluetoothGlyph
                            color: controlCenter.bluetoothEnabled ? "#ffffff" : "#8e8e93"
                            font.pixelSize: 18
                            font.family: iconFontFamily
                        }

                        MouseArea {
                            id: btBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    controlCenter.toggleConnectivityOverlay("bluetooth");
                                } else {
                                    controlCenter.toggleBluetoothEnabled();
                                }
                            }
                        }
                    }

                    // Do Not Disturb / Silent Button
                    Rectangle {
                        width: parent.circleSize
                        height: 48
                        radius: 24
                        color: controlCenter.dndActive ? "#ff453a" : (dndBtnMouse.containsMouse ? "#28282c" : "#1c1c1e")

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: controlCenter.dndActive ? "\u{F00A0}" : "\uf0f3"
                            color: controlCenter.dndActive ? "#ffffff" : "#8e8e93"
                            font.pixelSize: 18
                            font.family: iconFontFamily
                        }

                        MouseArea {
                            id: dndBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlCenter.dndToggleRequested()
                        }
                    }
                }

                // 2. BOTTOM ROW: 3 VERTICAL SLIDERS
                Row {
                    width: parent.width
                    height: 136
                    spacing: 8

                    readonly property real sliderW: (width - 16) / 3

                    // Brightness Slider
                    ControlSliderVertical {
                        width: parent.sliderW
                        height: parent.height
                        value: controlCenter.displayedBrightness
                        iconText: controlCenter.brightnessIconGlyph
                        iconFontFamily: controlCenter.iconFontFamily
                        fillColor: "#ffffff"

                        onInteractionStarted: {
                            if (controlCenter.sliderIntroPending) {
                                sliderIntroTimer.stop();
                                controlCenter.sliderIntroPending = false;
                                controlCenter.displayedBrightness = controlCenter.localBrightness;
                            }
                        }
                        onValueMoved: (val) => controlCenter.queueBrightness(val)
                        onCommitRequested: {
                            brightnessApplyTimer.stop();
                            controlCenter.flushBrightness(true);
                        }
                        onCancelRequested: SystemServices.requestBrightness()
                    }

                    // Volume Slider
                    ControlSliderVertical {
                        width: parent.sliderW
                        height: parent.height
                        value: controlCenter.displayedVolume
                        iconText: controlCenter.volumeIconGlyph
                        iconFontFamily: controlCenter.iconFontFamily
                        fillColor: "#ffffff"

                        onInteractionStarted: {
                            if (controlCenter.sliderIntroPending) {
                                sliderIntroTimer.stop();
                                controlCenter.sliderIntroPending = false;
                                controlCenter.displayedVolume = controlCenter.localVolume;
                            }
                        }
                        onValueMoved: (val) => controlCenter.queueVolume(val)
                        onCommitRequested: {
                            volumeApplyTimer.stop();
                            controlCenter.flushVolume(true);
                        }
                        onCancelRequested: SystemServices.requestVolume()
                    }

                    // Night Light / Temperature Slider
                    ControlSliderVertical {
                        width: parent.sliderW
                        height: parent.height
                        value: controlCenter.displayedTemp
                        iconText: "\uf186" // Moon / Night light icon
                        iconFontFamily: controlCenter.iconFontFamily
                        fillColor: controlCenter.displayedTemp > 0.05 ? "#ff9f0a" : "#ffffff"

                        onInteractionStarted: {
                            if (controlCenter.sliderIntroPending) {
                                sliderIntroTimer.stop();
                                controlCenter.sliderIntroPending = false;
                                controlCenter.displayedTemp = controlCenter.localTemp;
                            }
                        }
                        onValueMoved: (val) => controlCenter.queueTemp(val)
                        onCommitRequested: {
                            tempApplyTimer.stop();
                            controlCenter.flushTemp(true);
                        }
                        onCancelRequested: controlCenter.syncTempFromLevel(controlCenter.tempLevel)
                    }
                }
            }
        }

        // ================= MEDIA PLAYER CARD (Full Width) =================
        Rectangle {
            id: playerCard
            width: parent.width
            height: 114
            radius: 20
            color: "#1c1c1e"

            Behavior on color { ColorAnimation { duration: 150 } }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Top: Art, Title/Artist & Playback Controls
                Item {
                    width: parent.width
                    height: 48

                    Row {
                        anchors.left: parent.left
                        anchors.right: playerControlsRow.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        // Album art thumbnail (circular)
                        Rectangle {
                            id: albumArtContainer
                            width: 44
                            height: 44
                            radius: 22
                            color: "#2c2c2e"
                            clip: true
                            layer.enabled: true
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: albumArtImg
                                anchors.fill: parent
                                source: controlCenter.currentArtUrl
                                fillMode: Image.PreserveAspectCrop
                                visible: source.toString() !== "" && status !== Image.Error
                                sourceSize: Qt.size(88, 88)
                                asynchronous: true
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: albumArtMask
                                }
                            }

                            Rectangle {
                                id: albumArtMask
                                width: albumArtContainer.width
                                height: albumArtContainer.height
                                radius: 22
                                visible: false
                                layer.enabled: true
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "\uf001" // Music note fallback
                                color: "#8e8e93"
                                font.pixelSize: 18
                                font.family: iconFontFamily
                                visible: !controlCenter.currentArtUrl || controlCenter.currentArtUrl === "" || albumArtImg.status === Image.Error
                            }
                        }

                        // Title & Artist
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            width: parent.width - 56

                            Text {
                                width: parent.width
                                text: controlCenter.currentTrack.length > 0 ? controlCenter.currentTrack : "Not Playing"
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.family: textFontFamily
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: controlCenter.currentArtist.length > 0 ? controlCenter.currentArtist : "No media active"
                                color: "#8e8e93"
                                font.pixelSize: 11
                                font.family: textFontFamily
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // Playback Controls: Prev, Play/Pause, Next
                    Row {
                        id: playerControlsRow
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        // Prev
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: prevMouse.containsMouse ? "#2c2c2e" : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "\uf048" // Step backward
                                color: prevMouse.containsMouse ? "#ffffff" : "#8e8e93"
                                font.pixelSize: 12
                                font.family: iconFontFamily
                            }

                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (controlCenter.activePlayer) controlCenter.activePlayer.previous()
                            }
                        }

                        // Play/Pause prominent button
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: (controlCenter.musicPlaying || (controlCenter.activePlayer && controlCenter.activePlayer.playbackState === MprisPlaybackState.Playing)) ? "\uf04c" : "\uf04b"
                                color: "#121418"
                                font.pixelSize: 13
                                font.family: iconFontFamily
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: controlCenter.togglePlayback()
                            }
                        }

                        // Next
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: nextMouse.containsMouse ? "#2c2c2e" : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "\uf051" // Step forward
                                color: nextMouse.containsMouse ? "#ffffff" : "#8e8e93"
                                font.pixelSize: 12
                                font.family: iconFontFamily
                            }

                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (controlCenter.activePlayer) controlCenter.activePlayer.next()
                            }
                        }
                    }
                }

                // Bottom: Timestamps + Waveform Visualizer Scrubber
                Item {
                    width: parent.width
                    height: 28

                    Text {
                        id: timePlayedLabel
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: controlCenter.timePlayed
                        color: "#8e8e93"
                        font.pixelSize: 11
                        font.family: textFontFamily
                        font.weight: Font.Medium
                    }

                    // Scrubber with acoustic soundwave bars & playhead line
                    Item {
                        id: scrubberArea
                        anchors.left: timePlayedLabel.right
                        anchors.leftMargin: 10
                        anchors.right: timeTotalLabel.left
                        anchors.rightMargin: 10
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter

                        readonly property int barCount: 36
                        readonly property real progressFrac: controlCenter.clamp01(controlCenter.trackProgress)

                        Row {
                            anchors.fill: parent
                            spacing: Math.max(1, (parent.width - (scrubberArea.barCount * 3)) / (scrubberArea.barCount - 1))

                            Repeater {
                                model: scrubberArea.barCount

                                delegate: Rectangle {
                                    required property int index
                                    readonly property real frac: index / (scrubberArea.barCount - 1)
                                    readonly property bool isPlayed: frac <= scrubberArea.progressFrac

                                    width: 3
                                    height: controlCenter.waveformHeight(index, scrubberArea.barCount)
                                    radius: 1.5
                                    color: isPlayed ? "#ffffff" : "#38383c"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on height {
                                        enabled: !controlCenter.musicPlaying
                                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                    }
                                }
                            }
                        }

                        // Playhead line cursor (like the `|` in drawing)
                        Rectangle {
                            width: 2
                            height: 20
                            radius: 1
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                            x: scrubberArea.progressFrac * Math.max(0, scrubberArea.width - 2)

                            Behavior on x {
                                enabled: !scrubberMouse.pressed
                                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: scrubberMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            function seekFromMouse(mouseX) {
                                if (width <= 0) return;
                                const frac = controlCenter.clamp01(mouseX / width);
                                controlCenter.seekTrack(frac);
                            }

                            onPressed: (mouse) => seekFromMouse(mouse.x)
                            onPositionChanged: (mouse) => { if (pressed) seekFromMouse(mouse.x); }
                        }
                    }

                    Text {
                        id: timeTotalLabel
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: controlCenter.timeTotal
                        color: "#8e8e93"
                        font.pixelSize: 11
                        font.family: textFontFamily
                        font.weight: Font.Medium
                    }
                }
            }
        }

        // ================= BOTTOM DRAGGABLE HANDLE =================
        Item {
            id: bottomHandle
            width: parent.width
            height: 18

            // Horizontal rounded pill
            Rectangle {
                width: 46
                height: 5
                radius: 2.5
                color: handleMouseArea.containsMouse ? "#636366" : "#3a3a3c"
                anchors.centerIn: parent

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: handleMouseArea
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                property real startY: 0
                onPressed: (mouse) => { startY = mouse.y; }
                onReleased: (mouse) => {
                    const delta = mouse.y - startY;
                    if (delta > 20) {
                        controlCenter.notificationsExpanded = true;
                    } else if (delta < -20) {
                        controlCenter.notificationsExpanded = false;
                    } else {
                        controlCenter.notificationsExpanded = !controlCenter.notificationsExpanded;
                    }
                }
                onCanceled: {}
            }
        }

        // ================= NOTIFICATIONS DRAWER =================
        Item {
            id: notificationsDrawer
            width: parent.width
            height: controlCenter.controlCenterExtraHeight
            visible: controlCenter.controlCenterExtraHeight > 4
            clip: true
            opacity: Math.min(1.0, controlCenter.controlCenterExtraHeight / 160)

            Column {
                anchors.fill: parent
                spacing: 8

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#2c3038"
                    opacity: 0.8
                }

                // Header
                Item {
                    width: parent.width
                    height: 22

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            text: "Notifications"
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: "#2c2c2e"
                            visible: notificationModel && notificationModel.count > 0
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: notificationModel ? String(notificationModel.count) : "0"
                                color: "#8e8e93"
                                font.pixelSize: 10
                                font.family: textFontFamily
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Clear all"
                        color: clearAllMouse.containsMouse ? "#ffffff" : "#3bc99d"
                        font.pixelSize: 11
                        font.family: textFontFamily
                        font.weight: Font.Medium
                        visible: notificationModel && notificationModel.count > 0

                        MouseArea {
                            id: clearAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (notificationModel) notificationModel.clear();
                            }
                        }
                    }
                }

                // Empty state
                Item {
                    width: parent.width
                    height: Math.max(0, parent.height - 34)
                    visible: !notificationModel || notificationModel.count === 0

                    Text {
                        anchors.centerIn: parent
                        text: "No new notifications"
                        color: "#8e8e93"
                        font.pixelSize: 12
                        font.family: textFontFamily
                    }
                }

                // Notifications ListView
                ListView {
                    id: notificationsList
                    width: parent.width
                    height: Math.max(0, parent.height - 34)
                    spacing: 8
                    model: notificationModel
                    interactive: contentHeight > height
                    clip: true
                    visible: notificationModel && notificationModel.count > 0

                    delegate: Rectangle {
                        width: notificationsList.width
                        height: 68
                        radius: 14
                        color: notifItemMouse.containsMouse ? "#272a34" : "#1c1f26"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: notifItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const home = controlCenter.shellRootController ? controlCenter.shellRootController.getHomePath() : (Quickshell.env("HOME") || "");
                                Quickshell.execDetached([home + "/.local/src/HyprDots/tide-island/bin/redirect_app.py", appName, summary, body]);
                                if (controlCenter.shellRootController) {
                                    controlCenter.shellRootController.forEachWindow((w) => {
                                        if (w && w.toggleControlCenter) w.toggleControlCenter();
                                    });
                                }
                            }
                        }

                        // Dismiss button
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.top: parent.top
                            anchors.topMargin: 10
                            width: 18
                            height: 18
                            radius: 9
                            color: dismissMouse.containsMouse ? "#33ffffff" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: "#8e8e93"
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: dismissMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (notificationModel) notificationModel.remove(index);
                                }
                            }
                        }

                        // App initial / icon box
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
                                font.pixelSize: 13
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
                                    color: "#8e8e93"
                                    font.pixelSize: 10
                                    font.family: textFontFamily
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "•"
                                    color: "#8e8e93"
                                    font.pixelSize: 10
                                    visible: timestamp && timestamp.length > 0
                                }

                                Text {
                                    text: timestamp
                                    color: "#8e8e93"
                                    font.pixelSize: 10
                                    font.family: textFontFamily
                                    visible: timestamp && timestamp.length > 0
                                }
                            }

                            Text {
                                width: parent.width
                                text: summary
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.family: textFontFamily
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: body
                                color: "#8e8e93"
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
}
