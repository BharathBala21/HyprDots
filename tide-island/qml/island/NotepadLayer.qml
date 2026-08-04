import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
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
    clip: true
    visible: opacity > 0 || notepadOpacityAnim.running
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        OpacityAnimator {
            id: notepadOpacityAnim
            duration: 180
            easing.type: Easing.InOutQuad
        }
    }

    // State properties
    property var allNotes: []
    property int selectedIndex: 0
    property string selectedCategoryFilter: "All"
    property string searchText: ""
    property bool autoSaveEnabled: true
    property string autoSaveStatus: "Saved"
    property string toastMessage: ""

    readonly property var categoryColors: ({
        "All": "#00f0c2",
        "Ideas": "#a78bfa",
        "Work": "#60a5fa",
        "Personal": "#34d399",
        "Todo": "#fbbf24"
    })

    readonly property var filteredNotes: {
        let result = allNotes || [];
        if (selectedCategoryFilter !== "All") {
            result = result.filter(n => n.category === selectedCategoryFilter);
        }
        if (searchText.trim() !== "") {
            const q = searchText.toLowerCase().trim();
            result = result.filter(n => (n.title || "").toLowerCase().indexOf(q) !== -1 || (n.content || "").toLowerCase().indexOf(q) !== -1);
        }
        // Sort: pinned first, then by updated_at descending
        return result.slice().sort((a, b) => {
            if (a.pinned && !b.pinned) return -1;
            if (!a.pinned && b.pinned) return 1;
            return (b.updated_at || 0) - (a.updated_at || 0);
        });
    }

    readonly property var currentNote: (filteredNotes.length > 0 && selectedIndex >= 0 && selectedIndex < filteredNotes.length) ? filteredNotes[selectedIndex] : null

    onShowConditionChanged: {
        if (showCondition) {
            loadNotesFromBackend();
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 30
        repeat: false
        onTriggered: {
            if (currentNote) {
                contentTextEdit.forceActiveFocus();
            } else {
                searchInput.forceActiveFocus();
            }
        }
    }

    Timer {
        id: autoSaveTimer
        interval: 600
        repeat: false
        onTriggered: {
            saveNotesToBackend();
        }
    }

    Timer {
        id: toastTimer
        interval: 2000
        repeat: false
        onTriggered: root.toastMessage = ""
    }

    function showToast(msg) {
        root.toastMessage = msg;
        toastTimer.restart();
    }

    // Backend I/O process
    Process {
        id: loadProcess
        command: ["python3", Quickshell.shellDir + "/bin/notes_manager.py", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        const parsed = JSON.parse(this.text);
                        if (Array.isArray(parsed)) {
                            root.allNotes = parsed;
                            if (root.selectedIndex >= parsed.length) {
                                root.selectedIndex = 0;
                            }
                        }
                    } catch (e) {
                        console.log("[Notepad] Error parsing notes JSON: " + e);
                    }
                }
            }
        }
    }

    function loadNotesFromBackend() {
        loadProcess.running = true;
    }

    function saveNotesToBackend() {
        root.autoSaveStatus = "Saving...";
        const payload = JSON.stringify(root.allNotes);
        Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/notes_manager.py", "save", payload]);
        root.autoSaveStatus = "Saved";
    }

    function triggerAutoSave() {
        if (!root.autoSaveEnabled) {
            root.autoSaveStatus = "Auto-save Off";
            return;
        }
        root.autoSaveStatus = "Unsaved";
        autoSaveTimer.restart();
    }

    function createNewNote() {
        const newId = "note_" + Date.now();
        const newNote = {
            id: newId,
            title: "Untitled Note",
            content: "",
            category: root.selectedCategoryFilter === "All" ? "Ideas" : root.selectedCategoryFilter,
            pinned: false,
            updated_at: Math.floor(Date.now() / 1000)
        };
        const list = root.allNotes.slice();
        list.unshift(newNote);
        root.allNotes = list;
        root.selectedIndex = 0;
        triggerAutoSave();
        titleInput.forceActiveFocus();
        titleInput.selectAll();
        showToast("Created new note");
    }

    function deleteCurrentNote() {
        if (!currentNote) return;
        const targetId = currentNote.id;
        root.allNotes = root.allNotes.filter(n => n.id !== targetId);
        if (root.selectedIndex >= root.filteredNotes.length) {
            root.selectedIndex = Math.max(0, root.filteredNotes.length - 1);
        }
        triggerAutoSave();
        showToast("Note deleted");
    }

    function togglePinCurrentNote() {
        if (!currentNote) return;
        const targetId = currentNote.id;
        const list = root.allNotes.map(n => {
            if (n.id === targetId) {
                return Object.assign({}, n, { pinned: !n.pinned, updated_at: Math.floor(Date.now() / 1000) });
            }
            return n;
        });
        root.allNotes = list;
        triggerAutoSave();
        showToast(currentNote.pinned ? "Pinned note" : "Unpinned note");
    }

    function toggleAutoSave() {
        root.autoSaveEnabled = !root.autoSaveEnabled;
        if (root.autoSaveEnabled) {
            saveNotesToBackend();
            showToast("Auto-save enabled");
        } else {
            root.autoSaveStatus = "Auto-save Off";
            showToast("Auto-save disabled (Press Ctrl+S to save)");
        }
    }

    function insertMarkdown(prefix, suffix) {
        if (!contentTextEdit) return;
        const start = contentTextEdit.selectionStart;
        const end = contentTextEdit.selectionEnd;
        const oldText = contentTextEdit.text || "";
        const selected = oldText.substring(start, end);
        const insertion = prefix + (selected ? selected : "text") + (suffix ? suffix : "");
        const newText = oldText.substring(0, start) + insertion + oldText.substring(end);
        updateNoteField("content", newText);
        contentTextEdit.forceActiveFocus();
        const cursorTarget = start + prefix.length + (selected ? selected.length : 4);
        contentTextEdit.select(cursorTarget, cursorTarget);
    }

    function updateNoteField(field, value) {
        if (!currentNote) return;
        const targetId = currentNote.id;
        const list = root.allNotes.map(n => {
            if (n.id === targetId) {
                const updated = Object.assign({}, n);
                updated[field] = value;
                updated.updated_at = Math.floor(Date.now() / 1000);
                return updated;
            }
            return n;
        });
        root.allNotes = list;
        triggerAutoSave();
    }

    // Key Navigation
    Keys.onPressed: (event) => {
        if ((event.modifiers & Qt.ControlModifier)) {
            if (event.key === Qt.Key_N) {
                createNewNote();
                event.accepted = true;
                return;
            } else if (event.key === Qt.Key_S) {
                saveNotesToBackend();
                showToast("Notes saved");
                event.accepted = true;
                return;
            } else if (event.key === Qt.Key_F) {
                searchInput.forceActiveFocus();
                searchInput.selectAll();
                event.accepted = true;
                return;
            } else if (event.key === Qt.Key_D) {
                deleteCurrentNote();
                event.accepted = true;
                return;
            }
        }
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        }
    }

    // Main Container Layout
    Rectangle {
        id: container
        anchors.fill: parent
        color: "transparent"
        radius: 20
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // 1. Top Header Bar
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: 6

                // Notepad Header Icon & Title
                RowLayout {
                    spacing: 6
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 8
                        color: "#22ffffff"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf24a" // Note icon
                            font.family: root.iconFontFamily
                            font.pixelSize: 13
                            color: "#00f0c2"
                        }
                    }

                    Text {
                        text: "Notepad"
                        font.family: root.heroFontFamily !== "" ? root.heroFontFamily : root.textFontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: "#ffffff"
                    }

                    Rectangle {
                        Layout.preferredWidth: noteCountText.implicitWidth + 10
                        Layout.preferredHeight: 18
                        radius: 9
                        color: "#1affffff"

                        Text {
                            id: noteCountText
                            anchors.centerIn: parent
                            text: filteredNotes.length + " notes"
                            font.family: root.textFontFamily
                            font.pixelSize: 10
                            color: "#a0a0a0"
                        }
                    }
                }

                Item { Layout.fillWidth: true } // Flexible Spacer

                // Category Filter Pills
                Row {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: ["All", "Ideas", "Work", "Personal", "Todo"]
                        delegate: Rectangle {
                            required property string modelData
                            required property int index

                            width: catText.implicitWidth + 12
                            height: 24
                            radius: 12
                            color: selectedCategoryFilter === modelData ? (categoryColors[modelData] || "#00f0c2") : "#14ffffff"

                            Text {
                                id: catText
                                anchors.centerIn: parent
                                text: parent.modelData
                                font.family: root.textFontFamily
                                font.pixelSize: 11
                                font.bold: selectedCategoryFilter === parent.modelData
                                color: selectedCategoryFilter === parent.modelData ? "#0d0e15" : "#c0c0c0"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedCategoryFilter = parent.modelData;
                                    root.selectedIndex = 0;
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredWidth: 6 }

                // Action Buttons (+ New, Auto-save Toggle, Save, Pin, Delete, Close)
                // New Note Button
                Rectangle {
                    Layout.preferredWidth: newBtnRow.implicitWidth + 14
                    Layout.preferredHeight: 26
                    radius: 13
                    color: "#00f0c2"

                    Row {
                        id: newBtnRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "\uf067"
                            font.family: root.iconFontFamily
                            font.pixelSize: 10
                            color: "#0d0e15"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "New"
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: "#0d0e15"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: createNewNote()
                    }
                }

                // Auto-Save Toggle Button
                Rectangle {
                    Layout.preferredWidth: autoSaveRow.implicitWidth + 12
                    Layout.preferredHeight: 26
                    radius: 13
                    color: root.autoSaveEnabled ? "#2000f0c2" : "#1effffff"
                    border.color: root.autoSaveEnabled ? "#00f0c2" : "#20ffffff"
                    border.width: 1

                    Row {
                        id: autoSaveRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: root.autoSaveEnabled ? "\uf00c" : "\uf00d"
                            font.family: root.iconFontFamily
                            font.pixelSize: 9
                            color: root.autoSaveEnabled ? "#00f0c2" : "#a0a0a0"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.autoSaveEnabled ? "Auto-save ON" : "Auto-save OFF"
                            font.family: root.textFontFamily
                            font.pixelSize: 10
                            font.bold: root.autoSaveEnabled
                            color: root.autoSaveEnabled ? "#00f0c2" : "#a0a0a0"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toggleAutoSave()
                    }
                }

                // Manual Save Button (Visible when auto-save is off or when unsaved)
                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 13
                    color: (root.autoSaveStatus === "Unsaved" || !root.autoSaveEnabled) ? "#3000f0c2" : "#1effffff"
                    border.color: (root.autoSaveStatus === "Unsaved") ? "#00f0c2" : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "\uf0c7" // Save disk icon
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                        color: (root.autoSaveStatus === "Unsaved" || !root.autoSaveEnabled) ? "#00f0c2" : "#e0e0e0"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            saveNotesToBackend();
                            showToast("Notes saved!");
                        }
                    }
                }

                // Pin Button
                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 13
                    color: (currentNote && currentNote.pinned) ? "#3000f0c2" : "#1effffff"
                    visible: currentNote !== null

                    Text {
                        anchors.centerIn: parent
                        text: "\uf08d" // Pin icon
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                        color: (currentNote && currentNote.pinned) ? "#00f0c2" : "#e0e0e0"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: togglePinCurrentNote()
                    }
                }

                // Delete Button
                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 13
                    color: "#20ff4444"
                    visible: currentNote !== null

                    Text {
                        anchors.centerIn: parent
                        text: "\uf1f8" // Trash icon
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                        color: "#ff5555"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: deleteCurrentNote()
                    }
                }

                // Close Button
                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 13
                    color: "#1effffff"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d" // Close icon
                        font.family: root.iconFontFamily
                        font.pixelSize: 12
                        color: "#a0a0a0"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            // 2. Main Content Split View (Notes List Left | Editor Right)
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                // Left Panel: Notes List
                Rectangle {
                    Layout.preferredWidth: 220
                    Layout.fillHeight: true
                    radius: 14
                    color: "#12121a"
                    border.color: "#1effffff"
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        // Search Bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 10
                            color: "#1a000000"
                            border.color: searchInput.activeFocus ? "#00f0c2" : "#18ffffff"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Text {
                                    text: "\uf002"
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 11
                                    color: searchInput.activeFocus ? "#00f0c2" : "#808080"
                                }

                                TextField {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    placeholderText: "Search notes..."
                                    placeholderTextColor: "#606060"
                                    color: "#ffffff"
                                    font.family: root.textFontFamily
                                    font.pixelSize: 12
                                    background: null
                                    text: root.searchText
                                    onTextChanged: {
                                        root.searchText = text;
                                        root.selectedIndex = 0;
                                    }
                                }

                                Text {
                                    visible: searchInput.text !== ""
                                    text: "\uf00d"
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 10
                                    color: "#808080"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: searchInput.text = ""
                                    }
                                }
                            }
                        }

                        // Notes Scroll List
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            ListView {
                                id: notesListView
                                anchors.fill: parent
                                model: filteredNotes
                                spacing: 6

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index

                                    width: ListView.view.width
                                    height: 54
                                    radius: 10
                                    color: index === root.selectedIndex ? "#2500f0c2" : (noteMouseArea.containsMouse ? "#18ffffff" : "#0dffffff")
                                    border.color: index === root.selectedIndex ? "#00f0c2" : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        // Category color tag bar
                                        Rectangle {
                                            Layout.preferredWidth: 4
                                            Layout.fillHeight: true
                                            radius: 2
                                            color: categoryColors[modelData.category] || "#00f0c2"
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 4

                                                Text {
                                                    text: modelData.pinned ? "\uf08d " : ""
                                                    font.family: root.iconFontFamily
                                                    font.pixelSize: 10
                                                    color: "#00f0c2"
                                                    visible: modelData.pinned
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.title || "Untitled"
                                                    font.family: root.textFontFamily
                                                    font.pixelSize: 12
                                                    font.bold: index === root.selectedIndex
                                                    color: "#ffffff"
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: (modelData.content || "Empty note...").replace(/\n/g, " ")
                                                font.family: root.textFontFamily
                                                font.pixelSize: 11
                                                color: "#808080"
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: noteMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectedIndex = index;
                                            contentTextEdit.forceActiveFocus();
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: filteredNotes.length === 0
                                    text: searchInput.text !== "" ? "No matching notes" : "No notes yet\nClick + New to create"
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: root.textFontFamily
                                    font.pixelSize: 12
                                    color: "#606060"
                                }
                            }
                        }
                    }
                }

                // Right Panel: Note Editor Area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: "#12121a"
                    border.color: "#1effffff"
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8
                        visible: currentNote !== null

                        // Note Title + Category Selection Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: titleInput
                                Layout.fillWidth: true
                                text: currentNote ? currentNote.title : ""
                                placeholderText: "Note Title..."
                                placeholderTextColor: "#606060"
                                font.family: root.heroFontFamily !== "" ? root.heroFontFamily : root.textFontFamily
                                font.pixelSize: 16
                                font.bold: true
                                color: "#ffffff"
                                background: null
                                onTextChanged: {
                                    if (currentNote && text !== currentNote.title) {
                                        updateNoteField("title", text);
                                    }
                                }
                            }

                            // Category Selector Chips (Flex row with explicit bounds)
                            Row {
                                spacing: 4
                                Layout.alignment: Qt.AlignVCenter

                                Repeater {
                                    model: ["Ideas", "Work", "Personal", "Todo"]
                                    delegate: Rectangle {
                                        required property string modelData

                                        width: tagText.implicitWidth + 10
                                        height: 20
                                        radius: 10
                                        color: (currentNote && currentNote.category === modelData) ? (categoryColors[modelData] || "#00f0c2") : "#14ffffff"

                                        Text {
                                            id: tagText
                                            anchors.centerIn: parent
                                            text: parent.modelData
                                            font.family: root.textFontFamily
                                            font.pixelSize: 10
                                            font.bold: currentNote && currentNote.category === parent.modelData
                                            color: (currentNote && currentNote.category === parent.modelData) ? "#0d0e15" : "#a0a0a0"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                updateNoteField("category", parent.modelData);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Markdown Quick Formatting Toolbar
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 22
                            spacing: 4

                            Text {
                                text: "Format:"
                                font.family: root.textFontFamily
                                font.pixelSize: 10
                                color: "#606060"
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Bold Button
                            Rectangle {
                                width: 22; height: 20; radius: 4; color: "#14ffffff"
                                Text { anchors.centerIn: parent; text: "B"; font.bold: true; font.pixelSize: 11; color: "#e0e0e0" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: insertMarkdown("**", "**") }
                            }

                            // Italic Button
                            Rectangle {
                                width: 22; height: 20; radius: 4; color: "#14ffffff"
                                Text { anchors.centerIn: parent; text: "I"; font.italic: true; font.pixelSize: 11; color: "#e0e0e0" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: insertMarkdown("*", "*") }
                            }

                            // Heading Button
                            Rectangle {
                                width: 22; height: 20; radius: 4; color: "#14ffffff"
                                Text { anchors.centerIn: parent; text: "H"; font.bold: true; font.pixelSize: 11; color: "#00f0c2" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: insertMarkdown("# ", "") }
                            }

                            // Bullet List Button
                            Rectangle {
                                width: 24; height: 20; radius: 4; color: "#14ffffff"
                                Text { anchors.centerIn: parent; text: "• List"; font.pixelSize: 10; color: "#e0e0e0" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: insertMarkdown("- ", "") }
                            }

                            // Todo Task Button
                            Rectangle {
                                width: 44; height: 20; radius: 4; color: "#2000f0c2"; border.color: "#00f0c2"; border.width: 1
                                Text { anchors.centerIn: parent; text: "☑ Todo"; font.pixelSize: 10; font.bold: true; color: "#00f0c2" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: insertMarkdown("- [ ] ", "") }
                            }

                            // Code Button
                            Rectangle {
                                width: 26; height: 20; radius: 4; color: "#14ffffff"
                                Text { anchors.centerIn: parent; text: "<>"; font.pixelSize: 10; color: "#a78bfa" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: insertMarkdown("`", "`") }
                            }

                            Item { Layout.fillWidth: true } // Spacer
                        }

                        // Divider Line
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: "#15ffffff"
                        }

                        // Main Text Area for Note Content
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                id: contentTextEdit
                                anchors.fill: parent
                                text: currentNote ? currentNote.content : ""
                                placeholderText: "Write your note here... (Markdown supported)"
                                placeholderTextColor: "#505050"
                                font.family: root.textFontFamily
                                font.pixelSize: 13
                                color: "#e8e8e8"
                                selectionColor: "#00f0c2"
                                selectedTextColor: "#0d0e15"
                                wrapMode: TextEdit.Wrap
                                background: null
                                selectByMouse: true

                                onTextChanged: {
                                    if (currentNote && text !== currentNote.content) {
                                        updateNoteField("content", text);
                                    }
                                }
                            }
                        }

                        // Bottom Status Bar (Word count, save indicator, key hints)
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20

                            Text {
                                text: {
                                    if (!currentNote || !currentNote.content) return "0 words • 0 chars";
                                    const textVal = currentNote.content.trim();
                                    const words = textVal === "" ? 0 : textVal.split(/\s+/).length;
                                    const chars = currentNote.content.length;
                                    return words + " words • " + chars + " chars";
                                }
                                font.family: root.textFontFamily
                                font.pixelSize: 11
                                color: "#707070"
                            }

                            Text {
                                visible: root.toastMessage !== ""
                                text: "  |  " + root.toastMessage
                                font.family: root.textFontFamily
                                font.pixelSize: 11
                                font.bold: true
                                color: "#00f0c2"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Item { Layout.fillWidth: true; visible: root.toastMessage === "" } // Spacer

                            // Auto save status indicator
                            Row {
                                spacing: 4
                                Text {
                                    text: root.autoSaveStatus === "Saving..." ? "\uf1ce" : "\uf00c"
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 10
                                    color: root.autoSaveStatus === "Saved" ? "#34d399" : (root.autoSaveStatus === "Unsaved" ? "#fbbf24" : "#a0a0a0")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.autoSaveStatus
                                    font.family: root.textFontFamily
                                    font.pixelSize: 11
                                    color: "#a0a0a0"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Empty State if no note selected
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: currentNote === null
                        spacing: 12

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf24a"
                            font.family: root.iconFontFamily
                            font.pixelSize: 42
                            color: "#30ffffff"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No note selected"
                            font.family: root.textFontFamily
                            font.pixelSize: 15
                            font.bold: true
                            color: "#808080"
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: createFirstBtnRow.implicitWidth + 20
                            height: 32
                            radius: 16
                            color: "#00f0c2"

                            Row {
                                id: createFirstBtnRow
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "\uf067"
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 12
                                    color: "#0d0e15"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "Create a Note"
                                    font.family: root.textFontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#0d0e15"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: createNewNote()
                            }
                        }
                    }
                }
            }
        }
    }
}
