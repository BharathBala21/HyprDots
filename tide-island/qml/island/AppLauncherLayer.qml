import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import IslandBackend

FocusScope {
    id: root
    focus: true

    property string iconFontFamily: ""
    property string textFontFamily: ""
    property string heroFontFamily: ""
    property bool showCondition: false

    signal closeRequested()

    anchors.fill: parent
    visible: opacity > 0
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 180
            easing.type: Easing.InOutQuad
        }
    }

    // In-memory persistent app cache
    property var allApps: []
    property var frequentApps: []
    property var filteredResults: []
    property int selectedIndex: 0
    property string searchText: ""
    property string activeCategory: "all"
    property string searchMode: "apps" // "apps" | "calc" | "cmd" | "web"
    property string calcResult: ""
    property string calcDetail: ""
    property bool showCopyToast: false

    readonly property var categoryList: [
        { id: "all", name: "All", icon: "\uf009" },
        { id: "frequent", name: "Frequent", icon: "\uf0e7" },
        { id: "dev", name: "Dev", icon: "\uf121" },
        { id: "web", name: "Web", icon: "\uf0ac" },
        { id: "media", name: "Media", icon: "\uf001" },
        { id: "system", name: "System", icon: "\uf013" },
        { id: "tools", name: "Tools", icon: "\uf0ad" }
    ]

    // Fast focus timer
    Timer {
        id: focusTimer
        interval: 10
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    Timer {
        id: copyToastTimer
        interval: 1500
        repeat: false
        onTriggered: root.showCopyToast = false
    }

    Component.onCompleted: {
        loadAppList();
    }

    onShowConditionChanged: {
        if (showCondition) {
            searchText = "";
            activeCategory = "all";
            searchMode = "apps";
            selectedIndex = 0;
            updateFilteredResults();
            focusTimer.restart();
        } else {
            // Background refresh to pick up new installations
            loadAppList();
        }
    }

    onActiveCategoryChanged: {
        selectedIndex = 0;
        updateFilteredResults();
    }

    onSearchTextChanged: {
        selectedIndex = 0;
        detectSearchMode();
        updateFilteredResults();
    }

    function loadAppList() {
        if (!appListProcess.running) {
            appListProcess.running = true;
        }
    }

    Process {
        id: appListProcess
        command: ["python3", Quickshell.shellDir + "/bin/app_list.py"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        const apps = JSON.parse(this.text);
                        if (Array.isArray(apps)) {
                            root.allApps = apps;
                            // Extract top frequent apps (count > 0)
                            const freq = [];
                            for (let i = 0; i < apps.length && freq.length < 6; i++) {
                                if (apps[i].count && apps[i].count > 0) {
                                    freq.push(apps[i]);
                                }
                            }
                            // If no usage history yet, default to first 6 apps
                            if (freq.length === 0) {
                                for (let i = 0; i < Math.min(6, apps.length); i++) {
                                    freq.push(apps[i]);
                                }
                            }
                            root.frequentApps = freq;
                            root.updateFilteredResults();
                        }
                    } catch (e) {
                        console.log("Error parsing apps JSON:", e);
                    }
                }
            }
        }
    }

    // Pure JS Instant Math Evaluator
    function evaluateMath(expr) {
        if (!expr) return null;
        let clean = expr.trim();
        if (clean.startsWith("=")) clean = clean.substring(1).trim();
        if (!clean) return null;

        // Replace common math expressions safely
        let jsExpr = clean
            .replace(/\^/g, "**")
            .replace(/sqrt\(/gi, "Math.sqrt(")
            .replace(/cbrt\(/gi, "Math.cbrt(")
            .replace(/sin\(/gi, "Math.sin(")
            .replace(/cos\(/gi, "Math.cos(")
            .replace(/tan\(/gi, "Math.tan(")
            .replace(/abs\(/gi, "Math.abs(")
            .replace(/log\(/gi, "Math.log10(")
            .replace(/ln\(/gi, "Math.log(")
            .replace(/round\(/gi, "Math.round(")
            .replace(/floor\(/gi, "Math.floor(")
            .replace(/ceil\(/gi, "Math.ceil(")
            .replace(/pi/gi, "Math.PI")
            .replace(/e(?![a-z0-9_])/gi, "Math.E");

        // Validate allowed characters for safety
        if (!/^[0-9+\-*/().,% MathPIE*xXa-fA-F_]+$/.test(jsExpr)) {
            return null;
        }

        try {
            const func = new Function("return (" + jsExpr + ");");
            const res = func();
            if (res === undefined || res === null || isNaN(res) || !isFinite(res)) {
                return null;
            }
            return res;
        } catch (err) {
            return null;
        }
    }

    function detectSearchMode() {
        const query = root.searchText.trim();
        if (query.startsWith("=") || (!query.startsWith(">") && !query.startsWith("?") && !query.startsWith(":") && /^[0-9+\-*/().\s^%]+$/.test(query) && /[0-9]/.test(query) && /[+\-*/^%]/.test(query))) {
            root.searchMode = "calc";
            const val = evaluateMath(query);
            if (val !== null) {
                let formatted = typeof val === "number" ? (Number.isInteger(val) ? val.toLocaleString() : parseFloat(val.toFixed(6)).toString()) : String(val);
                root.calcResult = formatted;
                if (Number.isInteger(val) && val >= 0 && val <= 0xffffffff) {
                    root.calcDetail = "Hex: 0x" + val.toString(16).toUpperCase() + "  |  Bin: 0b" + val.toString(2);
                } else {
                    root.calcDetail = "";
                }
            } else {
                root.calcResult = "...";
                root.calcDetail = "";
            }
        } else if (query.startsWith(">") || query.startsWith("!")) {
            root.searchMode = "cmd";
        } else if (query.startsWith("?")) {
            root.searchMode = "web";
        } else {
            root.searchMode = "apps";
        }
    }

    function getSystemActions(query) {
        const actions = [
            {
                name: "Lock Screen",
                exec: Quickshell.shellDir + "/lockscreen/lock.sh",
                icon: "\uf023",
                description: "Lock current desktop session",
                category: "system",
                isSystem: true,
                keywords: "lock screen logout security"
            },
            {
                name: "Reboot System",
                exec: "systemctl reboot",
                icon: "\uf021",
                description: "Restart the operating system",
                category: "system",
                isSystem: true,
                keywords: "reboot restart computer"
            },
            {
                name: "Power Off",
                exec: "systemctl poweroff",
                icon: "\uf011",
                description: "Shut down computer completely",
                category: "system",
                isSystem: true,
                keywords: "power off shutdown turn off"
            },
            {
                name: "Suspend System",
                exec: "systemctl suspend",
                icon: "\uf186",
                description: "Put computer into sleep mode",
                category: "system",
                isSystem: true,
                keywords: "sleep suspend hibernate"
            },
            {
                name: "Exit Hyprland",
                exec: "hyprctl dispatch exit",
                icon: "\uf2f5",
                description: "Log out of Hyprland Wayland compositor",
                category: "system",
                isSystem: true,
                keywords: "logout exit session quit"
            },
            {
                name: "Open Terminal",
                exec: "kitty",
                icon: "\uf120",
                description: "Launch Kitty GPU-accelerated terminal",
                category: "system",
                isSystem: true,
                keywords: "terminal console kitty shell fish bash"
            },
            {
                name: "Reload Shell & Compositor",
                exec: "hyprctl reload",
                icon: "\uf0e2",
                description: "Reload Hyprland & QuickShell configuration",
                category: "system",
                isSystem: true,
                keywords: "reload refresh restart hyprland config"
            }
        ];

        if (!query) return [];
        const q = query.toLowerCase().trim();
        const matched = [];
        for (let i = 0; i < actions.length; i++) {
            const act = actions[i];
            if (act.name.toLowerCase().includes(q) || act.keywords.includes(q) || (q.startsWith(":") && act.name.toLowerCase().includes(q.substring(1)))) {
                matched.push(act);
            }
        }
        return matched;
    }

    function scoreApp(app, query, cat) {
        // Category filtering
        if (cat !== "all") {
            if (cat === "frequent") {
                if (!app.count || app.count <= 0) return -1;
            } else if (app.category !== cat && (!app.rawCategories || !app.rawCategories.toLowerCase().includes(cat))) {
                return -1;
            }
        }

        if (!query) {
            return (app.count || 0) * 100 + 10;
        }

        const nameLower = (app.name || "").toLowerCase();
        const execLower = (app.exec || "").toLowerCase();
        const searchLower = (app.search || "");

        // 1. Exact match on name
        if (nameLower === query) return 10000 + (app.count || 0) * 10;

        // 2. Name starts with query
        if (nameLower.startsWith(query)) return 6000 + (query.length / nameLower.length) * 1000 + (app.count || 0) * 10;

        // 3. Word boundary in name
        const words = nameLower.split(/[\s\-_]+/);
        for (let i = 0; i < words.length; i++) {
            if (words[i].startsWith(query)) {
                return 4000 + (query.length / words[i].length) * 500 + (app.count || 0) * 10;
            }
        }

        // 4. Acronym match (e.g. "vsc" for "Visual Studio Code")
        if (words.length > 1) {
            const acronym = words.map(w => w[0] || "").join("");
            if (acronym.startsWith(query)) {
                return 3500 + (query.length / acronym.length) * 500 + (app.count || 0) * 10;
            }
        }

        // 5. Executable name starts with query
        const execBase = execLower.split(/[\s\/]+/)[0];
        if (execBase.startsWith(query)) return 3000 + (app.count || 0) * 10;

        // 6. Name contains query
        const nameIdx = nameLower.indexOf(query);
        if (nameIdx !== -1) return 2000 - nameIdx * 10 + (app.count || 0) * 10;

        // 7. Search metadata contains query (keywords, generic name, comment)
        const searchIdx = searchLower.indexOf(query);
        if (searchIdx !== -1) return 1000 - searchIdx * 5 + (app.count || 0) * 10;

        // 8. Fuzzy match
        let qIdx = 0;
        let score = 0;
        for (let i = 0; i < nameLower.length && qIdx < query.length; i++) {
            if (nameLower[i] === query[qIdx]) {
                score += 10;
                if (i > 0 && nameLower[i - 1] === " ") score += 20;
                qIdx++;
            }
        }
        if (qIdx === query.length) {
            return 500 + score + (app.count || 0) * 10;
        }

        return -1;
    }

    function updateFilteredResults() {
        if (root.searchMode === "calc") {
            root.filteredResults = [];
            return;
        }

        const query = root.searchText.toLowerCase().trim();

        // Check for Command Runner mode
        if (root.searchMode === "cmd") {
            const cmd = query.substring(1).trim();
            root.filteredResults = [{
                name: cmd ? "Run: " + cmd : "Type command to execute in terminal...",
                exec: cmd,
                icon: "\uf120",
                description: "Execute in terminal (Enter) or background (Ctrl+Enter)",
                category: "tools",
                isCommand: true
            }];
            return;
        }

        // Check for Web search mode
        if (root.searchMode === "web") {
            const webQ = query.substring(1).trim();
            root.filteredResults = [{
                name: webQ ? "Search Web: " + webQ : "Type query to search web...",
                exec: "xdg-open 'https://www.google.com/search?q=" + encodeURIComponent(webQ) + "'",
                icon: "\uf0ac",
                description: "Open search results in default browser",
                category: "web",
                isWebSearch: true
            }];
            return;
        }

        const results = [];

        // 1. Check system actions
        const sysActions = getSystemActions(query);
        for (let i = 0; i < sysActions.length; i++) {
            results.push({ app: sysActions[i], score: 8000 - i * 100 });
        }

        // 2. Score all apps
        const cat = root.activeCategory;
        const apps = root.allApps;
        for (let i = 0; i < apps.length; i++) {
            const s = scoreApp(apps[i], query, cat);
            if (s > 0) {
                results.push({ app: apps[i], score: s });
            }
        }

        // Sort by score descending
        results.sort(function(a, b) { return b.score - a.score; });

        // Limit results to top 30 for maximum rendering performance
        const finalApps = [];
        const limit = Math.min(30, results.length);
        for (let i = 0; i < limit; i++) {
            finalApps.push(results[i].app);
        }

        // If user typed something and no apps matched, suggest web search
        if (finalApps.length === 0 && query !== "") {
            finalApps.push({
                name: "Search Google for \"" + root.searchText.trim() + "\"",
                exec: "xdg-open 'https://www.google.com/search?q=" + encodeURIComponent(root.searchText.trim()) + "'",
                icon: "\uf0ac",
                description: "No local applications found. Press Enter to search web",
                category: "web",
                isWebSearch: true
            });
        }

        root.filteredResults = finalApps;
    }

    function launchApp(app, inTerminal) {
        if (!app) return;

        if (root.searchMode === "calc") {
            if (root.calcResult && root.calcResult !== "...") {
                Quickshell.execDetached(["sh", "-c", "echo -n " + JSON.stringify(root.calcResult) + " | wl-copy"]);
                root.showCopyToast = true;
                copyToastTimer.restart();
            }
            return;
        }

        if (app.isCommand) {
            if (!app.exec) return;
            if (inTerminal) {
                Quickshell.execDetached(["kitty", "-e", "sh", "-c", app.exec + "; echo; echo 'Press Enter to close...'; read line"]);
            } else {
                Quickshell.execDetached(["sh", "-c", app.exec]);
            }
            root.closeRequested();
            return;
        }

        if (app.isWebSearch) {
            if (app.exec) Quickshell.execDetached(["sh", "-c", app.exec]);
            root.closeRequested();
            return;
        }

        if (app.isSystem) {
            if (app.exec) Quickshell.execDetached(["sh", "-c", app.exec]);
            root.closeRequested();
            return;
        }

        if (!app.exec) return;

        if (inTerminal || app.terminal) {
            Quickshell.execDetached(["kitty", "-e", "sh", "-c", app.exec]);
        } else {
            Quickshell.execDetached(["sh", "-c", app.exec]);
        }

        if (app.filename) {
            Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/app_list.py", "--track", app.filename]);
        }

        root.closeRequested();
    }

    // Main Layout
    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Search Bar & Header
        Rectangle {
            id: searchBarContainer
            width: parent.width
            height: 48
            radius: 14
            color: searchInput.activeFocus ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: searchInput.activeFocus ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.06)

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                // Search Glyph / Mode Indicator
                Rectangle {
                    id: modeBadge
                    width: root.searchMode !== "apps" ? modeRow.implicitWidth + 14 : 28
                    height: 28
                    radius: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.searchMode === "calc" 
                        ? Qt.rgba(0.2, 0.8, 0.4, 0.25)
                        : (root.searchMode === "cmd" 
                            ? Qt.rgba(0.9, 0.6, 0.1, 0.25)
                            : (root.searchMode === "web" ? Qt.rgba(0.2, 0.6, 1.0, 0.25) : "transparent"))
                    border.width: root.searchMode !== "apps" ? 1 : 0
                    border.color: root.searchMode === "calc" 
                        ? Qt.rgba(0.2, 0.8, 0.4, 0.5)
                        : (root.searchMode === "cmd" 
                            ? Qt.rgba(0.9, 0.6, 0.1, 0.5)
                            : Qt.rgba(0.2, 0.6, 1.0, 0.5))

                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Row {
                        id: modeRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: root.searchMode === "calc" ? "\uf1ec" : (root.searchMode === "cmd" ? "\uf120" : (root.searchMode === "web" ? "\uf0ac" : "\uf002"))
                            font.family: root.iconFontFamily
                            font.pixelSize: 14
                            color: searchInput.activeFocus ? "#ffffff" : Qt.rgba(1, 1, 1, 0.4)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            visible: root.searchMode !== "apps"
                            text: root.searchMode === "calc" ? "CALC" : (root.searchMode === "cmd" ? "RUN" : "WEB")
                            font.family: root.textFontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Input Field
                TextField {
                    id: searchInput
                    focus: true
                    width: parent.width - modeBadge.width - (clearButton.visible ? clearButton.width + 10 : 0) - resultCountBadge.width - 32
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    placeholderText: root.searchMode === "calc" 
                        ? "Enter math calculation (e.g. 128 * 4, sqrt(256))..."
                        : (root.searchMode === "cmd" 
                            ? "Enter terminal command to run..." 
                            : (root.searchMode === "web" ? "Search web with browser..." : "Search"))
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.3)
                    color: "#ffffff"
                    font.family: root.textFontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    background: null
                    leftPadding: 0
                    rightPadding: 0
                    verticalAlignment: TextInput.AlignVCenter

                    text: root.searchText
                    onTextChanged: root.searchText = text

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier)) || (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier))) {
                            if (root.filteredResults.length > 0) {
                                root.selectedIndex = (root.selectedIndex + 1) % root.filteredResults.length;
                                resultsListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)) || (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier))) {
                            if (root.filteredResults.length > 0) {
                                root.selectedIndex = (root.selectedIndex - 1 + root.filteredResults.length) % root.filteredResults.length;
                                resultsListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Tab) {
                            // Cycle category filter
                            const cats = root.categoryList;
                            let curIdx = 0;
                            for (let i = 0; i < cats.length; i++) {
                                if (cats[i].id === root.activeCategory) { curIdx = i; break; }
                            }
                            const nextIdx = (event.modifiers & Qt.ShiftModifier) 
                                ? (curIdx - 1 + cats.length) % cats.length 
                                : (curIdx + 1) % cats.length;
                            root.activeCategory = cats[nextIdx].id;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.searchMode === "calc") {
                                root.launchApp(null, false);
                                event.accepted = true;
                            } else if (root.filteredResults.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredResults.length) {
                                const inTerminal = (event.modifiers & Qt.ControlModifier) || (event.modifiers & Qt.ShiftModifier);
                                root.launchApp(root.filteredResults[root.selectedIndex], inTerminal);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Escape) {
                            root.closeRequested();
                            event.accepted = true;
                        } else if (event.modifiers & Qt.AltModifier) {
                            // Alt+1 .. Alt+6 for instant frequent app launch
                            const num = event.key - Qt.Key_1;
                            if (num >= 0 && num < root.frequentApps.length) {
                                root.launchApp(root.frequentApps[num], false);
                                event.accepted = true;
                            }
                        }
                    }
                }

                // Match counter badge
                Rectangle {
                    id: resultCountBadge
                    visible: root.searchMode === "apps" && root.filteredResults.length > 0
                    width: countText.implicitWidth + 14
                    height: 22
                    radius: 11
                    color: Qt.rgba(1, 1, 1, 0.08)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: root.filteredResults.length + (root.filteredResults.length === 1 ? " app" : " apps")
                        font.family: root.textFontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: Qt.rgba(1, 1, 1, 0.5)
                    }
                }

                // Clear button
                Rectangle {
                    id: clearButton
                    width: 24
                    height: 24
                    radius: 12
                    color: clearMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                    visible: root.searchText !== ""
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        font.family: root.iconFontFamily
                        font.pixelSize: 12
                        color: clearMouseArea.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.4)
                    }

                    MouseArea {
                        id: clearMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // Category Filter Bar (Only visible in Apps mode)
        Row {
            id: categoryRow
            width: parent.width
            height: 28
            spacing: 6
            visible: root.searchMode === "apps"

            Repeater {
                model: root.categoryList

                delegate: Rectangle {
                    id: catChip
                    readonly property bool isSelected: root.activeCategory === modelData.id
                    width: catRow.implicitWidth + 16
                    height: 26
                    radius: 13
                    color: isSelected 
                        ? Qt.rgba(1, 1, 1, 0.15) 
                        : (chipMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
                    border.width: isSelected ? 1 : 0
                    border.color: Qt.rgba(1, 1, 1, 0.25)

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        id: catRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: modelData.icon
                            font.family: root.iconFontFamily
                            font.pixelSize: 11
                            color: isSelected ? "#ffffff" : Qt.rgba(1, 1, 1, 0.5)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.name
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                            color: isSelected ? "#ffffff" : Qt.rgba(1, 1, 1, 0.6)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: chipMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.activeCategory = modelData.id;
                            searchInput.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // Frequent Apps Quick Row (Visible when search query is empty & 'all' or 'frequent' category is active)
        Rectangle {
            id: frequentContainer
            width: parent.width
            height: 64
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.03)
            visible: root.searchMode === "apps" && root.searchText.trim() === "" && (root.activeCategory === "all" || root.activeCategory === "frequent") && root.frequentApps.length > 0

            Row {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                Repeater {
                    model: root.frequentApps

                    delegate: Rectangle {
                        id: freqCard
                        width: (frequentContainer.width - 12 - (root.frequentApps.length - 1) * 8) / root.frequentApps.length
                        height: parent.height
                        radius: 10
                        color: freqMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.04)

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 7
                                color: "transparent"
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    anchors.fill: parent
                                    source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                    smooth: true
                                    mipmap: true
                                    sourceSize: Qt.size(28, 28)
                                    asynchronous: true
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: freqCard.width - 44
                                spacing: 2

                                Text {
                                    text: modelData.name
                                    font.family: root.textFontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: "#ffffff"
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: "Alt+" + (index + 1)
                                    font.family: root.textFontFamily
                                    font.pixelSize: 9
                                    color: Qt.rgba(1, 1, 1, 0.35)
                                }
                            }
                        }

                        MouseArea {
                            id: freqMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.launchApp(modelData, false)
                        }
                    }
                }
            }
        }

        // Results Container
        Item {
            id: resultsContainer
            width: parent.width
            height: parent.height - searchBarContainer.height - (categoryRow.visible ? categoryRow.height + 10 : 0) - (frequentContainer.visible ? frequentContainer.height + 10 : 0) - footerRow.height - 24

            // 1. Application / Command Results ListView
            ListView {
                id: resultsListView
                anchors.fill: parent
                visible: root.searchMode !== "calc" && root.filteredResults.length > 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.selectedIndex
                model: root.filteredResults
                spacing: 4

                onCurrentIndexChanged: {
                    root.selectedIndex = currentIndex;
                }

                delegate: Rectangle {
                    id: itemCard
                    readonly property bool isSelected: index === root.selectedIndex
                    width: resultsListView.width
                    height: 52
                    radius: 12
                    color: isSelected 
                        ? Qt.rgba(1, 1, 1, 0.11) 
                        : (rowMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")

                    Behavior on color { ColorAnimation { duration: 80 } }

                    // Selection Indicator Bar
                    Rectangle {
                        width: 3
                        height: 24
                        radius: 1.5
                        color: "#ffffff"
                        visible: isSelected
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: isSelected ? 14 : 10
                        anchors.rightMargin: 12
                        spacing: 12

                        // Left Icon Container
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 9
                            color: Qt.rgba(1, 1, 1, 0.06)
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                visible: !(modelData && (modelData.isSystem || modelData.isCommand || modelData.isWebSearch))
                                anchors.fill: parent
                                anchors.margins: 2
                                source: Quickshell.iconPath(modelData.icon || "application-x-executable", "application-x-executable")
                                smooth: true
                                mipmap: true
                                sourceSize: Qt.size(36, 36)
                                asynchronous: true
                            }

                            Text {
                                visible: !!(modelData && (modelData.isSystem || modelData.isCommand || modelData.isWebSearch))
                                text: (modelData && modelData.icon) ? modelData.icon : "\uf120"
                                font.family: root.iconFontFamily
                                font.pixelSize: 16
                                color: "#ffffff"
                                anchors.centerIn: parent
                            }
                        }

                        // App Information
                        Column {
                            width: parent.width - 48 - actionPill.width - 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Row {
                                spacing: 8
                                width: parent.width

                                Text {
                                    text: modelData.name || ""
                                    font.family: root.textFontFamily
                                    font.pixelSize: 13
                                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                                    color: isSelected ? "#ffffff" : Qt.rgba(1, 1, 1, 0.85)
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // Category / Terminal tag
                                Rectangle {
                                    visible: !!(modelData && modelData.category && !modelData.isSystem)
                                    width: catLabel.implicitWidth + 8
                                    height: 16
                                    radius: 4
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        id: catLabel
                                        anchors.centerIn: parent
                                        text: (modelData.category || "").toUpperCase()
                                        font.family: root.textFontFamily
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        color: Qt.rgba(1, 1, 1, 0.45)
                                    }
                                }
                            }

                            Text {
                                text: modelData.description || (modelData.exec ? "Exec: " + modelData.exec : "")
                                font.family: root.textFontFamily
                                font.pixelSize: 11
                                color: isSelected ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(1, 1, 1, 0.35)
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Right Action Pill
                        Rectangle {
                            id: actionPill
                            width: isSelected ? actionText.implicitWidth + 14 : 0
                            height: 24
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.12)
                            anchors.verticalCenter: parent.verticalCenter
                            visible: isSelected
                            clip: true

                            Text {
                                id: actionText
                                anchors.centerIn: parent
                                text: "↵ Open"
                                font.family: root.textFontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: "#ffffff"
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: {
                            if (containsMouse) {
                                root.selectedIndex = index;
                            }
                        }
                        onClicked: {
                            root.launchApp(modelData, false);
                        }
                    }
                }
            }

            // 2. Calculator Mode View
            Rectangle {
                anchors.fill: parent
                radius: 14
                color: Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)
                visible: root.searchMode === "calc"

                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    width: parent.width - 40

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Text {
                            text: "\uf1ec"
                            font.family: root.iconFontFamily
                            font.pixelSize: 16
                            color: Qt.rgba(0.3, 0.9, 0.5, 0.9)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "CALCULATOR"
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                            font.letterSpacing: 1.5
                            font.weight: Font.Bold
                            color: Qt.rgba(0.3, 0.9, 0.5, 0.9)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: root.calcResult
                        font.family: root.heroFontFamily || root.textFontFamily
                        font.pixelSize: 36
                        font.weight: Font.Bold
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.calcDetail !== ""
                        text: root.calcDetail
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        color: Qt.rgba(1, 1, 1, 0.45)
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }

                    Rectangle {
                        width: copyHintText.implicitWidth + 20
                        height: 28
                        radius: 14
                        color: root.showCopyToast ? Qt.rgba(0.2, 0.8, 0.4, 0.3) : Qt.rgba(1, 1, 1, 0.08)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: root.showCopyToast ? "\uf00c" : "\uf0c5"
                                font.family: root.iconFontFamily
                                font.pixelSize: 12
                                color: root.showCopyToast ? "#4ade80" : Qt.rgba(1, 1, 1, 0.7)
                            }

                            Text {
                                id: copyHintText
                                text: root.showCopyToast ? "Copied to clipboard!" : "Press Enter to Copy"
                                font.family: root.textFontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: root.showCopyToast ? "#4ade80" : Qt.rgba(1, 1, 1, 0.7)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.launchApp(null, false)
                        }
                    }
                }
            }

            // 3. Empty State (When no apps found)
            Column {
                anchors.centerIn: parent
                visible: root.searchMode === "apps" && root.filteredResults.length === 0
                spacing: 10

                Text {
                    text: "\uf002"
                    font.family: root.iconFontFamily
                    font.pixelSize: 28
                    color: Qt.rgba(1, 1, 1, 0.2)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "No applications found"
                    font.family: root.textFontFamily
                    font.pixelSize: 13
                    color: Qt.rgba(1, 1, 1, 0.35)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // Footer Toolbar
        Row {
            id: footerRow
            width: parent.width
            height: 20
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                height: parent.height
                width: (parent.width - footerShortcuts.implicitWidth) / 2
            }

            Row {
                id: footerShortcuts
                spacing: 14
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "↵"; font.family: root.textFontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: Qt.rgba(1, 1, 1, 0.4) }
                    Text { text: "Open"; font.family: root.textFontFamily; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.3) }
                }

                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Ctrl+↵"; font.family: root.textFontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: Qt.rgba(1, 1, 1, 0.4) }
                    Text { text: "Terminal"; font.family: root.textFontFamily; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.3) }
                }

                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Tab"; font.family: root.textFontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: Qt.rgba(1, 1, 1, 0.4) }
                    Text { text: "Category"; font.family: root.textFontFamily; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.3) }
                }

                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: ">"; font.family: root.textFontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: Qt.rgba(1, 1, 1, 0.4) }
                    Text { text: "Command"; font.family: root.textFontFamily; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.3) }
                }

                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "="; font.family: root.textFontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: Qt.rgba(1, 1, 1, 0.4) }
                    Text { text: "Math"; font.family: root.textFontFamily; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.3) }
                }

                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Esc"; font.family: root.textFontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: Qt.rgba(1, 1, 1, 0.4) }
                    Text { text: "Close"; font.family: root.textFontFamily; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.3) }
                }
            }
        }
    }
}
