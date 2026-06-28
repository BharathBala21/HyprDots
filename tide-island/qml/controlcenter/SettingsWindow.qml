import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Controls.Basic

FloatingWindow {
    id: root

    title: "Hyprland Customizer"
    implicitWidth: 700
    implicitHeight: 580
    color: colorBackground // Sleek dark panel background

    signal settingsClosed()

    onVisibleChanged: {
        if (!visible) {
            settingsClosed();
        }
    }

    Component.onDestruction: {
        settingsClosed();
    }

    property int hyprRounding: 7
    property int hyprBorder: 1
    property int hyprGapsIn: 5
    property int hyprGapsOut: 7

    property bool blurEnabled: true
    property int blurSize: 8
    property int blurPasses: 1
    property bool blurIgnoreOpacity: true
    property bool blurNewOptimizations: true
    property bool blurXray: false
    property real blurNoise: 0.0117
    property real blurContrast: 0.8916
    property real blurBrightness: 0.8172
    property real blurVibrancy: 0.1696
    property real blurVibrancyDarkness: 0.0

    property bool addRulePanelOpen: false
    property real ruleOpacity: 1.0

    property int activeSection: 0

    // Matugen configurations
    property string matugenMode: "dark"
    property string matugenType: "scheme-tonal-spot"
    property real matugenContrast: 0.0
    property string matugenPrefer: "default"
    property int matugenSourceColorIndex: 0

    // VS Code configurations
    property string vscodeTheme: "Matugen"
    property bool vscodeAutoUpdate: true
    property bool vscodeExtensionInstalled: false
    property bool spicetifyInstalled: false

    // Matugen dynamic theme colors
    readonly property var themeColors: shellRoot.matugenThemeColors

    readonly property color colorBackground: themeColors ? themeColors.background : "#121316"
    readonly property color colorPrimary: themeColors ? themeColors.primary : "#0a84ff"
    readonly property color colorOnSurface: themeColors ? themeColors.on_surface : "#ffffff"
    readonly property color colorOnSurfaceVariant: themeColors ? themeColors.on_surface_variant : "#8e8e93"
    readonly property color colorOutline: themeColors ? themeColors.outline_variant : "#3a3a3c"
    readonly property color colorSecondaryContainer: themeColors ? themeColors.secondary_container : "#2c2c2e"
    readonly property color colorOnSecondaryContainer: themeColors ? themeColors.on_secondary_container : "#ffffff"

    readonly property color colorCardBg: themeColors ? (themeColors.surface_container_low || themeColors.surface) : "#1c1d21"

    readonly property color colorSwitchBgActive: themeColors ? themeColors.primary : "#30d158"
    readonly property color colorSwitchBgInactive: themeColors ? themeColors.secondary_container : "#2c2c2e"
    readonly property color colorSwitchBgDisabled: themeColors ? themeColors.surface_dim : "#1c1c1e"
    readonly property color colorSwitchKnobActive: themeColors ? themeColors.on_primary : "#ffffff"
    readonly property color colorSwitchKnobInactive: themeColors ? themeColors.on_secondary_container : "#ffffff"

    readonly property color colorSliderTrackActive: colorPrimary
    readonly property color colorSliderTrackInactive: themeColors ? themeColors.surface_variant : "#48484a"

    readonly property color colorButtonBg: themeColors ? themeColors.secondary_container : "#24252a"
    readonly property color colorButtonBgHover: themeColors ? Qt.lighter(themeColors.secondary_container, 1.15) : "#2e2f35"
    readonly property color colorButtonText: themeColors ? themeColors.on_secondary_container : "#ffffff"
    readonly property color colorButtonTextDisabled: themeColors ? themeColors.outline : "#4e4f55"

    function updateHyprRounding(val) {
        hyprRounding = val;
        Quickshell.execDetached(["hyprctl", "eval", "hl.config({ decoration = { rounding = " + hyprRounding + " } })"]);
        savePersistentSettings();
    }

    function updateHyprGapsIn(val) {
        hyprGapsIn = val;
        Quickshell.execDetached(["hyprctl", "eval", "hl.config({ general = { gaps_in = " + hyprGapsIn + " } })"]);
        savePersistentSettings();
    }

    function updateHyprGapsOut(val) {
        hyprGapsOut = val;
        Quickshell.execDetached(["hyprctl", "eval", "hl.config({ general = { gaps_out = " + hyprGapsOut + " } })"]);
        savePersistentSettings();
    }

    function updateHyprBorder(val) {
        hyprBorder = val;
        Quickshell.execDetached(["hyprctl", "eval", "hl.config({ general = { border_size = " + hyprBorder + " } })"]);
        savePersistentSettings();
    }

    function updateBlurConfig() {
        var cmd = "hl.config({ decoration = { blur = { " +
            "enabled = " + (blurEnabled ? "true" : "false") + ", " +
            "size = " + blurSize + ", " +
            "passes = " + blurPasses + ", " +
            "ignore_opacity = " + (blurIgnoreOpacity ? "true" : "false") + ", " +
            "new_optimizations = " + (blurNewOptimizations ? "true" : "false") + ", " +
            "xray = " + (blurXray ? "true" : "false") + ", " +
            "noise = " + blurNoise.toFixed(4) + ", " +
            "contrast = " + blurContrast.toFixed(4) + ", " +
            "brightness = " + blurBrightness.toFixed(4) + ", " +
            "vibrancy = " + blurVibrancy.toFixed(4) + ", " +
            "vibrancy_darkness = " + blurVibrancyDarkness.toFixed(4) +
            " } } })";
        Quickshell.execDetached(["hyprctl", "eval", cmd]);
        savePersistentSettings();
    }

    function updateBlurEnabled(val) {
        blurEnabled = val;
        updateBlurConfig();
    }
    function updateBlurSize(val) {
        blurSize = val;
        updateBlurConfig();
    }
    function updateBlurPasses(val) {
        blurPasses = val;
        updateBlurConfig();
    }
    function updateBlurIgnoreOpacity(val) {
        blurIgnoreOpacity = val;
        updateBlurConfig();
    }
    function updateBlurNewOptimizations(val) {
        blurNewOptimizations = val;
        if (!val) {
            blurXray = false;
        }
        updateBlurConfig();
    }
    function updateBlurXray(val) {
        blurXray = val;
        updateBlurConfig();
    }
    function updateBlurNoise(val) {
        blurNoise = val;
        updateBlurConfig();
    }
    function updateBlurContrast(val) {
        blurContrast = val;
        updateBlurConfig();
    }
    function updateBlurBrightness(val) {
        blurBrightness = val;
        updateBlurConfig();
    }
    function updateBlurVibrancy(val) {
        blurVibrancy = val;
        updateBlurConfig();
    }
    function updateBlurVibrancyDarkness(val) {
        blurVibrancyDarkness = val;
        updateBlurConfig();
    }

    function savePersistentSettings() {
        Quickshell.execDetached([
            "python3", 
            Quickshell.shellDir + "/bin/update_hypr_config.py", 
            "--gaps-in", hyprGapsIn.toString(), 
            "--gaps-out", hyprGapsOut.toString(), 
            "--border", hyprBorder.toString(), 
            "--rounding", hyprRounding.toString(),
            "--blur-enabled", blurEnabled ? "true" : "false",
            "--blur-size", blurSize.toString(),
            "--blur-passes", blurPasses.toString(),
            "--blur-ignore-opacity", blurIgnoreOpacity ? "true" : "false",
            "--blur-new-optimizations", blurNewOptimizations ? "true" : "false",
            "--blur-xray", blurXray ? "true" : "false",
            "--blur-noise", blurNoise.toFixed(4),
            "--blur-contrast", blurContrast.toFixed(4),
            "--blur-brightness", blurBrightness.toFixed(4),
            "--blur-vibrancy", blurVibrancy.toFixed(4),
            "--blur-vibrancy-darkness", blurVibrancyDarkness.toFixed(4)
        ]);
    }

    function saveWindowRules() {
        var rules = [];
        for (var i = 0; i < rulesListModel.count; i++) {
            var item = rulesListModel.get(i);
            var rule = {};
            if (item.class !== undefined && item.class !== "") rule.class = item.class;
            if (item.title !== undefined && item.title !== "") rule.title = item.title;
            if (item.float !== undefined) rule.float = item.float;
            if (item.opaque !== undefined) rule.opaque = item.opaque;
            if (item.no_blur !== undefined) rule.no_blur = item.no_blur;
            if (item.stay_focused !== undefined) rule.stay_focused = item.stay_focused;
            if (item.persistent_size !== undefined) rule.persistent_size = item.persistent_size;
            if (item.opacity !== undefined && item.opacity !== null) rule.opacity = item.opacity;
            if (item.rounding !== undefined && item.rounding !== null) rule.rounding = item.rounding;
            
            if (rule.class || rule.title) {
                rules.push(rule);
            }
        }
        Quickshell.execDetached([
            "python3",
            Quickshell.shellDir + "/bin/update_hypr_config.py",
            "--window-rules",
            JSON.stringify(rules)
        ]);
    }

    function deleteRule(idx) {
        rulesListModel.remove(idx);
        saveWindowRules();
    }

    function resetAddRuleForm() {
        classInput.text = "";
        floatSwitch.checked = false;
        stayFocusedSwitch.checked = false;
        opaqueSwitch.checked = false;
        noBlurSwitch.checked = false;
        ruleOpacity = 1.0;
    }

    function saveMatugenSettings() {
        var args = [
            "python3",
            Quickshell.shellDir + "/bin/update_user_config.py",
            "--mode", matugenMode,
            "--type", matugenType,
            "--contrast", matugenContrast.toString(),
            "--prefer", matugenPrefer,
            "--source-color-index", matugenSourceColorIndex.toString()
        ];
        Quickshell.execDetached(args);
    }

    Process {
        id: matugenConfigReadProcess
        command: [
            "cat",
            Qt.getenv("HOME") + "/.config/tide-island/userconfig.json"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        var config = JSON.parse(this.text);
                        if (config.matugenMode !== undefined) matugenMode = config.matugenMode;
                        if (config.matugenType !== undefined) matugenType = config.matugenType;
                        if (config.matugenContrast !== undefined) matugenContrast = parseFloat(config.matugenContrast);
                        if (config.matugenPrefer !== undefined) matugenPrefer = config.matugenPrefer;
                        if (config.matugenSourceColorIndex !== undefined) matugenSourceColorIndex = parseInt(config.matugenSourceColorIndex);
                    } catch (e) {
                        console.log("Error parsing userconfig.json: " + e);
                    }
                }
            }
        }
    }

    Process {
        id: vscodeConfigReadProcess
        command: [
            "python3",
            "-c",
            "import json, os; " +
            "theme = 'Default'; auto_up = True; ext_installed = False; spicetify_installed = False; " +
            "for p in ['~/.config/Code/User/settings.json', '~/.config/VSCodium/User/settings.json', '~/.config/Code - Insiders/User/settings.json']:" +
            "    path = os.path.expanduser(p); " +
            "    if os.path.exists(path): " +
            "        try: " +
            "            d = json.load(open(path)); " +
            "            theme = d.get('workbench.colorTheme', theme); " +
            "            auto_up = d.get('matugenTheme.autoUpdate', auto_up); " +
            "            break; " +
            "        except: pass; " +
            "for ext_dir in ['~/.vscode/extensions', '~/.vscode-oss/extensions']:" +
            "    full_ext = os.path.expanduser(ext_dir); " +
            "    if os.path.exists(full_ext):" +
            "        for item in os.listdir(full_ext):" +
            "            if item.startswith('haikalllp.matugen-theme'):" +
            "                ext_installed = True; break;" +
            "if os.path.exists(os.path.expanduser('~/.spicetify/spicetify')):" +
            "    spicetify_installed = True;" +
            "print(json.dumps({'theme': theme, 'autoUpdate': auto_up, 'extensionInstalled': ext_installed, 'spicetifyInstalled': spicetify_installed}))"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        var res = JSON.parse(this.text);
                        vscodeTheme = res.theme;
                        vscodeAutoUpdate = res.autoUpdate;
                        vscodeExtensionInstalled = res.extensionInstalled;
                        spicetifyInstalled = res.spicetifyInstalled;
                    } catch (e) {
                        console.log("Error reading VS Code config: " + e);
                    }
                }
            }
        }
    }

    ListModel {
        id: rulesListModel
    }

    Process {
        id: generalReadProcess
        command: [
            "cat",
            Qt.getenv("HOME") + "/.local/src/HyprDots/hypr/hyprlua/gui.lua"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    var matchIn = this.text.match(/gaps_in\s*=\s*(\d+)/);
                    if (matchIn) hyprGapsIn = parseInt(matchIn[1]);
                    
                    var matchOut = this.text.match(/gaps_out\s*=\s*(\d+)/);
                    if (matchOut) hyprGapsOut = parseInt(matchOut[1]);
                    
                    var matchBorder = this.text.match(/border_size\s*=\s*(\d+)/);
                    if (matchBorder) hyprBorder = parseInt(matchBorder[1]);
                }
            }
        }
    }

    Process {
        id: decorationReadProcess
        command: [
            "cat",
            Qt.getenv("HOME") + "/.local/src/HyprDots/hypr/hyprlua/gui.lua"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    var matchRounding = this.text.match(/rounding\s*=\s*(\d+)/);
                    if (matchRounding) hyprRounding = parseInt(matchRounding[1]);

                    var blurBlockMatch = this.text.match(/blur\s*=\s*\{([^}]+)\}/);
                    if (blurBlockMatch) {
                        var blurBody = blurBlockMatch[1];
                        
                        var matchEnabled = blurBody.match(/enabled\s*=\s*(true|false)/);
                        if (matchEnabled) blurEnabled = (matchEnabled[1] === "true");
                        
                        var matchSize = blurBody.match(/size\s*=\s*(\d+)/);
                        if (matchSize) blurSize = parseInt(matchSize[1]);
                        
                        var matchPasses = blurBody.match(/passes\s*=\s*(\d+)/);
                        if (matchPasses) blurPasses = parseInt(matchPasses[1]);
                        
                        var matchIgnoreOpacity = blurBody.match(/ignore_opacity\s*=\s*(true|false)/);
                        if (matchIgnoreOpacity) blurIgnoreOpacity = (matchIgnoreOpacity[1] === "true");
                        
                        var matchNewOptimizations = blurBody.match(/new_optimizations\s*=\s*(true|false)/);
                        if (matchNewOptimizations) blurNewOptimizations = (matchNewOptimizations[1] === "true");
                        
                        var matchXray = blurBody.match(/xray\s*=\s*(true|false)/);
                        if (matchXray) blurXray = (matchXray[1] === "true");
                        
                        var matchNoise = blurBody.match(/noise\s*=\s*([0-9.]+)/);
                        if (matchNoise) blurNoise = parseFloat(matchNoise[1]);
                        
                        var matchContrast = blurBody.match(/contrast\s*=\s*([0-9.]+)/);
                        if (matchContrast) blurContrast = parseFloat(matchContrast[1]);
                        
                        var matchBrightness = blurBody.match(/brightness\s*=\s*([0-9.]+)/);
                        if (matchBrightness) blurBrightness = parseFloat(matchBrightness[1]);
                        
                        var matchVibrancy = blurBody.match(/vibrancy\s*=\s*([0-9.]+)/);
                        if (matchVibrancy) blurVibrancy = parseFloat(matchVibrancy[1]);
                        
                        var matchVibrancyDarkness = blurBody.match(/vibrancy_darkness\s*=\s*([0-9.]+)/);
                        if (matchVibrancyDarkness) blurVibrancyDarkness = parseFloat(matchVibrancyDarkness[1]);
                    }
                }
            }
        }
    }

    Process {
        id: rulesReadProcess
        command: ["python3", "~/.local/src/HyprDots/tide-island/bin/update_hypr_config.py", "--get-window-rules"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        var rules = JSON.parse(this.text);
                        rulesListModel.clear();
                        for (var i = 0; i < rules.length; i++) {
                            rulesListModel.append(rules[i]);
                        }
                    } catch (e) {
                        console.log("Error parsing window rules JSON: " + e);
                    }
                }
            }
        }
    }

    // Reusable Custom Switch
    component SettingsSwitch: Rectangle {
        id: switchRoot
        property bool checked: false
        property bool active: true
        signal toggled(bool newValue)
        
        width: 38
        height: 22
        radius: 11
        color: !active ? colorSwitchBgDisabled : (checked ? colorSwitchBgActive : colorSwitchBgInactive)
        opacity: active ? 1.0 : 0.4
        border.width: checked ? 0 : 1
        border.color: colorOutline
        
        Behavior on color {
            ColorAnimation { duration: 140 }
        }
        
        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 2
            x: checked ? 18 : 2
            color: checked ? colorSwitchKnobActive : colorSwitchKnobInactive
            
            Behavior on x {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
        }
        
        MouseArea {
            anchors.fill: parent
            enabled: switchRoot.active
            onClicked: {
                switchRoot.toggled(!switchRoot.checked);
                scrollView.forceActiveFocus();
            }
        }
    }

    // Reusable Custom Slider
    component SettingsSlider: Item {
        id: sliderRoot
        property real value: 0.0
        property real from: 0.0
        property real to: 1.0
        property bool active: true
        signal moved(real newValue)
        
        width: 130
        height: 20
        opacity: active ? 1.0 : 0.4
        
        Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: colorSecondaryContainer
            
            Rectangle {
                anchors.left: parent.left
                height: parent.height
                radius: parent.radius
                width: ((sliderRoot.to - sliderRoot.from) > 0) ? Math.max(0, Math.min(track.width, track.width * ((sliderRoot.value - sliderRoot.from) / (sliderRoot.to - sliderRoot.from)))) : 0
                color: sliderRoot.active ? colorSliderTrackActive : colorSliderTrackInactive
            }
        }
        
        Rectangle {
            id: handle
            width: 16
            height: 16
            radius: 8
            color: sliderRoot.active ? (themeColors ? themeColors.on_primary : "#ffffff") : (themeColors ? themeColors.surface_dim : "#e2e2e7")
            anchors.verticalCenter: parent.verticalCenter
            x: ((sliderRoot.to - sliderRoot.from) > 0) ? Math.max(0, Math.min(track.width - width, (track.width - width) * ((sliderRoot.value - sliderRoot.from) / (sliderRoot.to - sliderRoot.from)))) : 0
            
            border.width: 1
            border.color: colorOutline
        }
        
        MouseArea {
            anchors.fill: parent
            enabled: sliderRoot.active
            
            function updateVal(mouseX) {
                var percentage = Math.max(0, Math.min(1, mouseX / width));
                var val = sliderRoot.from + percentage * (sliderRoot.to - sliderRoot.from);
                sliderRoot.moved(val);
            }
            
            onPressed: {
                updateVal(mouseX);
                scrollView.forceActiveFocus();
            }
            onPositionChanged: {
                if (pressed) {
                    updateVal(mouseX);
                }
            }
        }
    }

    // Reusable Custom Stepper
    component SettingsStepper: Row {
        id: stepperRoot
        property int value: 0
        property int min: 0
        property int max: 30
        property string suffix: "px"
        property bool active: true
        signal changed(int newValue)
        
        spacing: 12
        opacity: active ? 1.0 : 0.4
        
        Rectangle {
            width: 28
            height: 28
            radius: 14
            color: (minusMouse.containsMouse && stepperRoot.active) ? colorButtonBgHover : colorButtonBg
            Text {
                anchors.centerIn: parent
                text: "-"
                color: stepperRoot.active ? colorButtonText : colorButtonTextDisabled
                font.pixelSize: 15
            }
            MouseArea {
                id: minusMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: stepperRoot.active
                onClicked: {
                    if (stepperRoot.value > stepperRoot.min) {
                        stepperRoot.changed(stepperRoot.value - 1);
                    }
                    scrollView.forceActiveFocus();
                }
            }
        }

        Text {
            width: 40
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            text: stepperRoot.value + stepperRoot.suffix
            color: stepperRoot.active ? colorOnSurface : colorOnSurfaceVariant
            font.pixelSize: 13
            font.family: "Inter Display"
            font.weight: Font.DemiBold
        }

        Rectangle {
            width: 28
            height: 28
            radius: 14
            color: (plusMouse.containsMouse && stepperRoot.active) ? colorButtonBgHover : colorButtonBg
            Text {
                anchors.centerIn: parent
                text: "+"
                color: stepperRoot.active ? colorButtonText : colorButtonTextDisabled
                font.pixelSize: 15
            }
            MouseArea {
                id: plusMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: stepperRoot.active
                onClicked: {
                    if (stepperRoot.value < stepperRoot.max) {
                        stepperRoot.changed(stepperRoot.value + 1);
                    }
                    scrollView.forceActiveFocus();
                }
            }
        }
    }

    // Reusable Custom Card
    component SettingsCard: Rectangle {
        id: cardRoot
        property string title: ""
        property bool active: true
        
        width: parent.width
        height: 52
        radius: 14
        color: colorCardBg
        opacity: active ? 1.0 : 0.4
        
        Behavior on opacity {
            NumberAnimation { duration: 140 }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: {
                scrollView.forceActiveFocus();
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: cardRoot.title
            color: colorOnSurface
            font.pixelSize: 13
            font.family: "Inter Display"
            font.weight: Font.Medium
        }
    }

    // Reusable Custom Input Text Field
    component SettingsInput: Rectangle {
        id: inputRoot
        property alias text: textInput.text
        property string placeholder: ""
        
        width: 140
        height: 28
        radius: 6
        color: colorSecondaryContainer
        border.width: textInput.activeFocus ? 1 : 0
        border.color: colorPrimary
        
        TextInput {
            id: textInput
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            color: colorOnSurface
            font.pixelSize: 12
            font.family: "Inter Display"
            onAccepted: {
                scrollView.forceActiveFocus();
            }
            
            Text {
                text: inputRoot.placeholder
                color: colorOnSurfaceVariant
                font.pixelSize: 12
                font.family: "Inter Display"
                visible: textInput.text === "" && !textInput.activeFocus
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Reusable Custom Editable Number Input
    component SettingsNumberInput: Rectangle {
        id: numInputRoot
        property real value: 0.0
        property real from: 0.0
        property real to: 1.0
        property int decimals: 4
        property bool active: true
        signal changed(real newValue)

        width: 54
        height: 20
        radius: 4
        color: textInput.activeFocus ? colorSecondaryContainer : "transparent"
        border.width: textInput.activeFocus ? 1 : 0
        border.color: colorPrimary
        opacity: active ? 1.0 : 0.4

        TextInput {
            id: textInput
            anchors.fill: parent
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            color: active ? colorOnSurface : colorOnSurfaceVariant
            font.pixelSize: 13
            font.family: "Inter Display"
            font.weight: Font.DemiBold
            enabled: numInputRoot.active
            
            text: activeFocus ? textInput.text : numInputRoot.value.toFixed(numInputRoot.decimals)
            
            validator: DoubleValidator {
                bottom: numInputRoot.from
                top: numInputRoot.to
                decimals: numInputRoot.decimals
            }
            
            function commit() {
                var val = parseFloat(textInput.text);
                if (!isNaN(val)) {
                    val = Math.max(numInputRoot.from, Math.min(numInputRoot.to, val));
                    numInputRoot.changed(val);
                }
                scrollView.forceActiveFocus();
            }
            
            onAccepted: commit()
            onActiveFocusChanged: {
                if (activeFocus) {
                    textInput.text = numInputRoot.value.toFixed(numInputRoot.decimals);
                } else {
                    commit();
                }
            }
        }
    }

    // Restructured layout: Row containing Sidebar and Content Area
    Row {
        id: mainRow
        anchors.fill: parent
        spacing: 0

        // Left Sidebar
        Rectangle {
            id: sidebar
            width: 160
            height: parent.height
            color: "transparent"

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Text {
                    text: "Settings"
                    color: colorOnSurface
                    font.pixelSize: 18
                    font.family: "Inter Display"
                    font.weight: Font.Bold
                    bottomPadding: 12
                }

                // Sidebar buttons
                Repeater {
                    model: [
                        { name: "Styling", icon: "🎨" },
                        { name: "Blur", icon: "✨" },
                        { name: "Rules", icon: "📝" },
                        { name: "Matugen", icon: "🌈" }
                    ]

                    delegate: Rectangle {
                        width: parent.width
                        height: 36
                        radius: 8
                        color: index === activeSection
                            ? colorSecondaryContainer
                            : (sidebarItemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            spacing: 8

                            Text {
                                text: modelData.icon
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.name
                                color: index === activeSection ? colorPrimary : colorOnSurface
                                font.pixelSize: 13
                                font.family: "Inter Display"
                                font.weight: index === activeSection ? Font.DemiBold : Font.Normal
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: sidebarItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                activeSection = index;
                                scrollView.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        // Vertical separator line
        Rectangle {
            width: 1
            height: parent.height
            color: colorOutline
        }

        // Right Content Area
        Item {
            id: contentArea
            width: parent.width - sidebar.width - 1
            height: parent.height

            // Background click handler inside content area to unfocus text inputs
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: {
                    scrollView.forceActiveFocus();
                }
            }

            ScrollView {
                id: scrollView
                anchors.fill: parent
                anchors.margins: 16
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                background: Rectangle {
                    color: "transparent"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            scrollView.forceActiveFocus();
                        }
                    }
                }

                Column {
                    id: mainColumn
                    property var settingsWindow: root
                    width: scrollView.width - 12
                    spacing: 12

                    // SECTION 0: Styling
                    Column {
                        width: parent.width
                        visible: activeSection === 0
                        spacing: 12

                        Text {
                            text: "Hyprland Styling"
                            color: colorOnSurface
                            font.pixelSize: 16
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            bottomPadding: 4
                        }

                        Text {
                            text: "General Settings"
                            color: colorOnSurfaceVariant
                            font.pixelSize: 11
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            leftPadding: 6
                        }

                        SettingsCard {
                            title: "Window Rounding"
                            SettingsStepper {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                value: hyprRounding
                                min: 0
                                max: 30
                                suffix: "px"
                                onChanged: (newValue) => {
                                    root.updateHyprRounding(newValue);
                                }
                            }
                        }

                        SettingsCard {
                            title: "Border Thickness"
                            SettingsStepper {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                value: hyprBorder
                                min: 0
                                max: 15
                                suffix: "px"
                                onChanged: (newValue) => {
                                    root.updateHyprBorder(newValue);
                                }
                            }
                        }

                        SettingsCard {
                            title: "Gaps (Between Windows)"
                            SettingsStepper {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                value: hyprGapsIn
                                min: 0
                                max: 40
                                suffix: "px"
                                onChanged: (newValue) => {
                                    root.updateHyprGapsIn(newValue);
                                }
                            }
                        }

                        SettingsCard {
                            title: "Gaps (Screen Edges)"
                            SettingsStepper {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                value: hyprGapsOut
                                min: 0
                                max: 40
                                suffix: "px"
                                onChanged: (newValue) => {
                                    root.updateHyprGapsOut(newValue);
                                }
                            }
                        }
                    }

                    // SECTION 1: Blur
                    Column {
                        width: parent.width
                        visible: activeSection === 1
                        spacing: 12

                        Text {
                            text: "Blur Settings"
                            color: colorOnSurface
                            font.pixelSize: 16
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            bottomPadding: 4
                        }

                        SettingsCard {
                            title: "Enable Window Blur"
                            SettingsSwitch {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                checked: blurEnabled
                                onToggled: (newValue) => {
                                    root.updateBlurEnabled(newValue);
                                }
                            }
                        }

                        SettingsCard {
                            title: "Blur Size"
                            active: blurEnabled
                            SettingsStepper {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                value: blurSize
                                min: 1
                                max: 20
                                suffix: ""
                                active: blurEnabled
                                onChanged: (newValue) => {
                                    root.updateBlurSize(newValue);
                                }
                            }
                        }

                        SettingsCard {
                            title: "Blur Passes"
                            active: blurEnabled
                            SettingsStepper {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                value: blurPasses
                                min: 1
                                max: 10
                                suffix: ""
                                active: blurEnabled
                                onChanged: (newValue) => {
                                    root.updateBlurPasses(newValue);
                                }
                            }
                        }

                        SettingsCard {
                            title: "Ignore Window Opacity"
                            active: blurEnabled
                            SettingsSwitch {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                checked: blurIgnoreOpacity
                                active: blurEnabled
                                onToggled: (newValue) => {
                                    root.updateBlurIgnoreOpacity(newValue);
                                }
                            }
                        }

                        SettingsCard {
                            title: "New Optimizations"
                            active: blurEnabled
                            SettingsSwitch {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                checked: blurNewOptimizations
                                active: blurEnabled
                                onToggled: (newValue) => {
                                    root.updateBlurNewOptimizations(newValue);
                                }
                            }
                        }

                        SettingsCard {
                            title: "X-Ray Blur"
                            active: blurEnabled && blurNewOptimizations
                            SettingsSwitch {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                checked: blurXray
                                active: blurEnabled && blurNewOptimizations
                                onToggled: (newValue) => {
                                    root.updateBlurXray(newValue);
                                }
                            }
                        }

                        SettingsCard {
                            title: "Blur Noise"
                            active: blurEnabled

                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                SettingsNumberInput {
                                    value: blurNoise
                                    from: 0.0
                                    to: 1.0
                                    decimals: 4
                                    active: blurEnabled
                                    anchors.verticalCenter: parent.verticalCenter
                                    onChanged: (newValue) => {
                                        root.updateBlurNoise(newValue);
                                    }
                                }

                                SettingsSlider {
                                    value: blurNoise
                                    from: 0.0
                                    to: 1.0
                                    active: blurEnabled
                                    onMoved: (newValue) => {
                                        root.updateBlurNoise(newValue);
                                    }
                                }
                            }
                        }

                        SettingsCard {
                            title: "Blur Contrast"
                            active: blurEnabled

                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                SettingsNumberInput {
                                    value: blurContrast
                                    from: 0.0
                                    to: 2.0
                                    decimals: 4
                                    active: blurEnabled
                                    anchors.verticalCenter: parent.verticalCenter
                                    onChanged: (newValue) => {
                                        root.updateBlurContrast(newValue);
                                    }
                                }

                                SettingsSlider {
                                    value: blurContrast
                                    from: 0.0
                                    to: 2.0
                                    active: blurEnabled
                                    onMoved: (newValue) => {
                                        root.updateBlurContrast(newValue);
                                    }
                                }
                            }
                        }

                        SettingsCard {
                            title: "Blur Brightness"
                            active: blurEnabled

                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                SettingsNumberInput {
                                    value: blurBrightness
                                    from: 0.0
                                    to: 2.0
                                    decimals: 4
                                    active: blurEnabled
                                    anchors.verticalCenter: parent.verticalCenter
                                    onChanged: (newValue) => {
                                        root.updateBlurBrightness(newValue);
                                    }
                                }

                                SettingsSlider {
                                    value: blurBrightness
                                    from: 0.0
                                    to: 2.0
                                    active: blurEnabled
                                    onMoved: (newValue) => {
                                        root.updateBlurBrightness(newValue);
                                    }
                                }
                            }
                        }

                        SettingsCard {
                            title: "Blur Vibrancy"
                            active: blurEnabled

                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                SettingsNumberInput {
                                    value: blurVibrancy
                                    from: 0.0
                                    to: 1.0
                                    decimals: 4
                                    active: blurEnabled
                                    anchors.verticalCenter: parent.verticalCenter
                                    onChanged: (newValue) => {
                                        root.updateBlurVibrancy(newValue);
                                    }
                                }

                                SettingsSlider {
                                    value: blurVibrancy
                                    from: 0.0
                                    to: 1.0
                                    active: blurEnabled
                                    onMoved: (newValue) => {
                                        root.updateBlurVibrancy(newValue);
                                    }
                                }
                            }
                        }

                        SettingsCard {
                            title: "Blur Vibrancy Darkness"
                            active: blurEnabled

                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                SettingsNumberInput {
                                    value: blurVibrancyDarkness
                                    from: 0.0
                                    to: 1.0
                                    decimals: 4
                                    active: blurEnabled
                                    anchors.verticalCenter: parent.verticalCenter
                                    onChanged: (newValue) => {
                                        root.updateBlurVibrancyDarkness(newValue);
                                    }
                                }

                                SettingsSlider {
                                    value: blurVibrancyDarkness
                                    from: 0.0
                                    to: 1.0
                                    active: blurEnabled
                                    onMoved: (newValue) => {
                                        root.updateBlurVibrancyDarkness(newValue);
                                    }
                                }
                            }
                        }
                    }

                    // SECTION 2: Rules
                    Column {
                        width: parent.width
                        visible: activeSection === 2
                        spacing: 12

                        Text {
                            text: "Window Rules"
                            color: colorOnSurface
                            font.pixelSize: 16
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            bottomPadding: 4
                        }

                        // Displaying each rule in the list
                        Repeater {
                            model: rulesListModel
                            delegate: Rectangle {
                                width: parent.width
                                height: 52
                                radius: 14
                                color: colorCardBg

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        scrollView.forceActiveFocus();
                                    }
                                }

                                Column {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: model.class ? "Class: " + model.class : (model.title ? "Title: " + model.title : "Any Window")
                                        color: colorOnSurface
                                        font.pixelSize: 13
                                        font.family: "Inter Display"
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        text: {
                                            var effects = [];
                                            if (model.float) effects.push("Float");
                                            if (model.opaque) effects.push("Opaque");
                                            if (model.no_blur) effects.push("No Blur");
                                            if (model.stay_focused) effects.push("Stay Focused");
                                            if (model.opacity !== undefined && model.opacity !== null && model.opacity !== 1.0) effects.push("Opacity: " + model.opacity);
                                            if (model.rounding !== undefined && model.rounding !== null) effects.push("Rounding: " + model.rounding + "px");
                                            return effects.join(", ") || "No Effects";
                                        }
                                        color: colorOnSurfaceVariant
                                        font.pixelSize: 11
                                        font.family: "Inter Display"
                                    }
                                }

                                // Delete button on the right
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: deleteMouse.containsMouse ? (themeColors ? themeColors.error : "#ff3b30") : colorSecondaryContainer

                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: deleteMouse.containsMouse ? (themeColors ? themeColors.on_error : "#ffffff") : colorOnSurface
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                    }

                                    MouseArea {
                                        id: deleteMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            mainColumn.settingsWindow.deleteRule(index);
                                        }
                                    }
                                }
                            }
                        }

                        // Add Rule Toggle Button
                        Rectangle {
                            visible: !addRulePanelOpen
                            width: parent.width
                            height: 40
                            radius: 10
                            color: addRuleMouse.containsMouse ? colorButtonBgHover : colorCardBg
                            border.width: 1
                            border.color: colorOutline

                            Text {
                                anchors.centerIn: parent
                                text: "+ Add New Window Rule"
                                color: colorPrimary
                                font.pixelSize: 13
                                font.family: "Inter Display"
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: addRuleMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    addRulePanelOpen = true;
                                    scrollTimer.restart();
                                }
                            }
                        }

                        // Expandable Add Rule Form
                        Rectangle {
                            visible: addRulePanelOpen
                            width: parent.width
                            height: 240
                            radius: 14
                            color: colorCardBg
                            border.width: 1
                            border.color: colorOutline

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    scrollView.forceActiveFocus();
                                }
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Text {
                                    text: "New Window Rule"
                                    color: colorOnSurface
                                    font.pixelSize: 13
                                    font.family: "Inter Display"
                                    font.weight: Font.Bold
                                }

                                Row {
                                    spacing: 12
                                    width: parent.width

                                    Text {
                                        text: "Match Class:"
                                        color: colorOnSurface
                                        font.pixelSize: 12
                                        font.family: "Inter Display"
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 80
                                    }

                                    SettingsInput {
                                        id: classInput
                                        placeholder: "e.g. kitty"
                                        width: parent.width - 100
                                    }
                                }

                                Row {
                                    spacing: 12
                                    width: parent.width

                                    Text {
                                        text: "Opacity:"
                                        color: colorOnSurface
                                        font.pixelSize: 12
                                        font.family: "Inter Display"
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 80
                                    }

                                    SettingsNumberInput {
                                        value: ruleOpacity
                                        from: 0.1
                                        to: 1.0
                                        decimals: 2
                                        width: 38
                                        anchors.verticalCenter: parent.verticalCenter
                                        onChanged: (newValue) => {
                                            ruleOpacity = newValue;
                                        }
                                    }

                                    SettingsSlider {
                                        id: ruleOpacitySlider
                                        value: ruleOpacity
                                        from: 0.1
                                        to: 1.0
                                        width: parent.width - 150
                                        onMoved: (newValue) => {
                                            ruleOpacity = newValue;
                                        }
                                    }
                                }

                                // Grid of checkable switches/options
                                Grid {
                                    columns: 2
                                    spacing: 12
                                    width: parent.width

                                    Item {
                                        width: 180
                                        height: 24

                                        Row {
                                            spacing: 8
                                            anchors.fill: parent

                                            SettingsSwitch {
                                                id: floatSwitch
                                                checked: false
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                text: "Float Window"
                                                color: colorOnSurface
                                                font.pixelSize: 12
                                                font.family: "Inter Display"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                floatSwitch.checked = !floatSwitch.checked;
                                                scrollView.forceActiveFocus();
                                            }
                                        }
                                    }

                                    Item {
                                        width: 180
                                        height: 24

                                        Row {
                                            spacing: 8
                                            anchors.fill: parent

                                            SettingsSwitch {
                                                id: stayFocusedSwitch
                                                checked: false
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                text: "Stay Focused"
                                                color: colorOnSurface
                                                font.pixelSize: 12
                                                font.family: "Inter Display"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                stayFocusedSwitch.checked = !stayFocusedSwitch.checked;
                                                scrollView.forceActiveFocus();
                                            }
                                        }
                                    }

                                    Item {
                                        width: 180
                                        height: 24

                                        Row {
                                            spacing: 8
                                            anchors.fill: parent

                                            SettingsSwitch {
                                                id: opaqueSwitch
                                                checked: false
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                text: "Force Opaque"
                                                color: colorOnSurface
                                                font.pixelSize: 12
                                                font.family: "Inter Display"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                opaqueSwitch.checked = !opaqueSwitch.checked;
                                                scrollView.forceActiveFocus();
                                            }
                                        }
                                    }

                                    Item {
                                        width: 180
                                        height: 24

                                        Row {
                                            spacing: 8
                                            anchors.fill: parent

                                            SettingsSwitch {
                                                id: noBlurSwitch
                                                checked: false
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                text: "Disable Blur"
                                                color: colorOnSurface
                                                font.pixelSize: 12
                                                font.family: "Inter Display"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                noBlurSwitch.checked = !noBlurSwitch.checked;
                                                scrollView.forceActiveFocus();
                                            }
                                        }
                                    }
                                }

                                // Action Buttons (Save/Cancel)
                                Row {
                                    spacing: 12
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Rectangle {
                                        width: 80
                                        height: 28
                                        radius: 6
                                        color: cancelMouse.containsMouse ? (themeColors ? Qt.darker(themeColors.error, 1.15) : "#e03025") : (themeColors ? themeColors.error : "#ff3b30")
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Cancel"
                                            color: themeColors ? themeColors.on_error : "#ffffff"
                                            font.pixelSize: 12
                                            font.family: "Inter Display"
                                            font.weight: Font.Medium
                                        }
                                        MouseArea {
                                            id: cancelMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                mainColumn.settingsWindow.resetAddRuleForm();
                                                addRulePanelOpen = false;
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 80
                                        height: 28
                                        radius: 6
                                        color: saveMouse.containsMouse ? (themeColors ? Qt.darker(themeColors.primary, 1.15) : "#28b54c") : (themeColors ? themeColors.primary : "#30d158")
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Save"
                                            color: themeColors ? themeColors.on_primary : "#ffffff"
                                            font.pixelSize: 12
                                            font.family: "Inter Display"
                                            font.weight: Font.Medium
                                        }
                                        MouseArea {
                                            id: saveMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                if (classInput.text !== "") {
                                                    rulesListModel.append({
                                                        "class": classInput.text,
                                                        "float": floatSwitch.checked,
                                                        "opaque": opaqueSwitch.checked,
                                                        "no_blur": noBlurSwitch.checked,
                                                        "stay_focused": stayFocusedSwitch.checked,
                                                        "opacity": ruleOpacity
                                                    });
                                                    mainColumn.settingsWindow.saveWindowRules();
                                                    mainColumn.settingsWindow.resetAddRuleForm();
                                                    addRulePanelOpen = false;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // SECTION 3: Matugen
                    Column {
                        width: parent.width
                        visible: activeSection === 3
                        spacing: 12

                        Text {
                            text: "Matugen Styling"
                            color: colorOnSurface
                            font.pixelSize: 16
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            bottomPadding: 4
                        }

                        Text {
                            text: "Theme Mode"
                            color: colorOnSurfaceVariant
                            font.pixelSize: 11
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            leftPadding: 6
                        }

                        SettingsCard {
                            title: "Dark Theme Mode"
                            SettingsSwitch {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                checked: matugenMode === "dark"
                                onToggled: (newValue) => {
                                    matugenMode = newValue ? "dark" : "light";
                                    root.saveMatugenSettings();
                                }
                            }
                        }

                        Text {
                            text: "Palette Type"
                            color: colorOnSurfaceVariant
                            font.pixelSize: 11
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            leftPadding: 6
                            topPadding: 8
                        }

                        // Grid of Palette styles
                        Grid {
                            columns: 2
                            spacing: 8
                            width: parent.width

                            Repeater {
                                model: [
                                    { value: "scheme-tonal-spot", label: "Tonal Spot" },
                                    { value: "scheme-content", label: "Content" },
                                    { value: "scheme-expressive", label: "Expressive" },
                                    { value: "scheme-fidelity", label: "Fidelity" },
                                    { value: "scheme-fruit-salad", label: "Fruit Salad" },
                                    { value: "scheme-monochrome", label: "Monochrome" },
                                    { value: "scheme-neutral", label: "Neutral" },
                                    { value: "scheme-rainbow", label: "Rainbow" },
                                    { value: "scheme-vibrant", label: "Vibrant" }
                                ]

                                delegate: Rectangle {
                                    width: (parent.width - 8) / 2
                                    height: 36
                                    radius: 10
                                    color: matugenType === modelData.value ? colorSecondaryContainer : colorCardBg
                                    border.width: 1
                                    border.color: matugenType === modelData.value ? colorPrimary : colorOutline

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: matugenType === modelData.value ? colorPrimary : colorOnSurface
                                        font.pixelSize: 12
                                        font.family: "Inter Display"
                                        font.weight: matugenType === modelData.value ? Font.DemiBold : Font.Normal
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            matugenType = modelData.value;
                                            root.saveMatugenSettings();
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Contrast & extraction"
                            color: colorOnSurfaceVariant
                            font.pixelSize: 11
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            leftPadding: 6
                            topPadding: 8
                        }

                        SettingsCard {
                            title: "Theme Contrast"

                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                SettingsNumberInput {
                                    value: matugenContrast
                                    from: -1.0
                                    to: 1.0
                                    decimals: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    onChanged: (newValue) => {
                                        matugenContrast = newValue;
                                        root.saveMatugenSettings();
                                    }
                                }

                                SettingsSlider {
                                    value: matugenContrast
                                    from: -1.0
                                    to: 1.0
                                    onMoved: (newValue) => {
                                        matugenContrast = newValue;
                                        root.saveMatugenSettings();
                                    }
                                }
                            }
                        }

                        SettingsCard {
                            title: "Source Color Index"
                            SettingsStepper {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                value: matugenSourceColorIndex
                                min: 0
                                max: 4
                                suffix: ""
                                onChanged: (newValue) => {
                                    matugenSourceColorIndex = newValue;
                                    root.saveMatugenSettings();
                                }
                            }
                        }

                        Text {
                            text: "Color Preference"
                            color: colorOnSurfaceVariant
                            font.pixelSize: 11
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            leftPadding: 6
                            topPadding: 8
                        }

                        Grid {
                            columns: 2
                            spacing: 8
                            width: parent.width

                            Repeater {
                                model: [
                                    { value: "default", label: "Default" },
                                    { value: "darkness", label: "Darkness" },
                                    { value: "lightness", label: "Lightness" },
                                    { value: "saturation", label: "Saturation" },
                                    { value: "less-saturation", label: "Less Saturation" },
                                    { value: "value", label: "Value" },
                                    { value: "closest-to-fallback", label: "Closest to Fallback" }
                                ]

                                delegate: Rectangle {
                                    width: (parent.width - 8) / 2
                                    height: 36
                                    radius: 10
                                    color: matugenPrefer === modelData.value ? colorSecondaryContainer : colorCardBg
                                    border.width: 1
                                    border.color: matugenPrefer === modelData.value ? colorPrimary : colorOutline

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: matugenPrefer === modelData.value ? colorPrimary : colorOnSurface
                                        font.pixelSize: 12
                                        font.family: "Inter Display"
                                        font.weight: matugenPrefer === modelData.value ? Font.DemiBold : Font.Normal
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            matugenPrefer = modelData.value;
                                            root.saveMatugenSettings();
                                        }
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 8 } // spacing

                        Text {
                            text: "VS Code Integration"
                            color: colorOnSurface
                            font.pixelSize: 14
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            leftPadding: 6
                            topPadding: 12
                            bottomPadding: 2
                        }

                        SettingsCard {
                            title: "Matugen Theme Extension"
                            
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 100
                                height: 28
                                radius: 6
                                color: vscodeExtensionInstalled ? colorSecondaryContainer : (installBtnMouse.containsMouse ? colorButtonBgHover : colorButtonBg)
                                border.width: 1
                                border.color: vscodeExtensionInstalled ? colorPrimary : colorOutline

                                Text {
                                    anchors.centerIn: parent
                                    text: vscodeExtensionInstalled ? "✓ Installed" : "Install"
                                    color: vscodeExtensionInstalled ? colorPrimary : colorOnSurface
                                    font.pixelSize: 12
                                    font.family: "Inter Display"
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    id: installBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: !vscodeExtensionInstalled
                                    enabled: !vscodeExtensionInstalled
                                    onClicked: {
                                        Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/update_user_config.py", "--install-vscode-extension"]);
                                        vscodeExtensionInstalled = true;
                                    }
                                }
                            }
                        }

                        Text {
                            text: "VS Code Theme"
                            color: colorOnSurfaceVariant
                            font.pixelSize: 11
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            leftPadding: 6
                            topPadding: 6
                        }

                        Grid {
                            columns: 3
                            spacing: 8
                            width: parent.width

                            Repeater {
                                model: [
                                    { value: "Matugen", label: "Matugen" },
                                    { value: "Matugen Bordered", label: "Bordered" },
                                    { value: "Default Dark Modern", label: "Default Theme" }
                                ]

                                delegate: Rectangle {
                                    width: (parent.width - 16) / 3
                                    height: 36
                                    radius: 10
                                    color: vscodeTheme === modelData.value ? colorSecondaryContainer : colorCardBg
                                    border.width: 1
                                    border.color: vscodeTheme === modelData.value ? colorPrimary : colorOutline

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: vscodeTheme === modelData.value ? colorPrimary : colorOnSurface
                                        font.pixelSize: 11
                                        font.family: "Inter Display"
                                        font.weight: vscodeTheme === modelData.value ? Font.DemiBold : Font.Normal
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            vscodeTheme = modelData.value;
                                            Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/update_user_config.py", "--set-vscode-theme", modelData.value]);
                                        }
                                    }
                                }
                            }
                        }

                        SettingsCard {
                            title: "Auto-Update Theme"
                            SettingsSwitch {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                checked: vscodeAutoUpdate
                                onToggled: (newValue) => {
                                    vscodeAutoUpdate = newValue;
                                    Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/update_user_config.py", "--set-vscode-autoupdate", newValue ? "true" : "false"]);
                                }
                            }
                        }

                        Item { width: 1; height: 8 } // spacing

                        Text {
                            text: "Spotify (Spicetify)"
                            color: colorOnSurface
                            font.pixelSize: 14
                            font.family: "Inter Display"
                            font.weight: Font.Bold
                            leftPadding: 6
                            topPadding: 12
                            bottomPadding: 2
                        }

                        SettingsCard {
                            title: "Setup Spicetify"
                            
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 100
                                height: 28
                                radius: 6
                                color: spicetifyInstalled ? colorSecondaryContainer : (installSpicetifyBtnMouse.containsMouse ? colorButtonBgHover : colorButtonBg)
                                border.width: 1
                                border.color: spicetifyInstalled ? colorPrimary : colorOutline

                                Text {
                                    anchors.centerIn: parent
                                    text: spicetifyInstalled ? "✓ Setup" : "Setup"
                                    color: spicetifyInstalled ? colorPrimary : colorOnSurface
                                    font.pixelSize: 12
                                    font.family: "Inter Display"
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    id: installSpicetifyBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: !spicetifyInstalled
                                    enabled: !spicetifyInstalled
                                    onClicked: {
                                        Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/update_user_config.py", "--install-spicetify"]);
                                        spicetifyInstalled = true;
                                    }
                                }
                            }
                        }

                        SettingsCard {
                            title: "Apply Spotify Theme"
                            
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 100
                                height: 28
                                radius: 6
                                color: applySpicetifyBtnMouse.containsMouse ? colorButtonBgHover : colorButtonBg
                                border.width: 1
                                border.color: colorOutline

                                Text {
                                    anchors.centerIn: parent
                                    text: "Apply"
                                    color: colorPrimary
                                    font.pixelSize: 12
                                    font.family: "Inter Display"
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    id: applySpicetifyBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/update_user_config.py", "--apply-spicetify"]);
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 12 } // spacing

                        // Regenerate Button
                        Rectangle {
                            width: parent.width
                            height: 40
                            radius: 10
                            color: regenerateMouse.containsMouse ? colorButtonBgHover : colorCardBg
                            border.width: 1
                            border.color: colorOutline

                            Text {
                                anchors.centerIn: parent
                                text: "🔄 Regenerate Colors"
                                color: colorPrimary
                                font.pixelSize: 13
                                font.family: "Inter Display"
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: regenerateMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.saveMatugenSettings();
                                }
                            }
                        }
                    }

                }
            }
        }
    }

    Timer {
        id: scrollTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (scrollView.contentItem) {
                scrollView.contentItem.contentY = Math.max(0, scrollView.contentItem.contentHeight - scrollView.contentItem.height);
            }
        }
    }
}


