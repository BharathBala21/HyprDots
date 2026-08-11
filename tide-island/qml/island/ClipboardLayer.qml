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
    visible: opacity > 0 || clipboardOpacityAnim.running
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        OpacityAnimator {
            id: clipboardOpacityAnim
            duration: 180
            easing.type: Easing.InOutQuad
        }
    }

    property string currentTab: "recent" // "recent" or "pinned"
    property var allClips: []
    property int selectedIndex: 0
    property string searchText: ""
    property bool showConfirmModal: false

    readonly property var activeClips: {
        if (currentTab === "recent") {
            return allClips;
        }
        const result = [];
        for (let i = 0; i < allClips.length; i++) {
            if (allClips[i].is_pinned) {
                result.push(allClips[i]);
            }
        }
        return result;
    }

    readonly property var filteredClips: {
        if (searchText.trim() === "") {
            return activeClips;
        }
        const query = searchText.toLowerCase().trim();
        const result = [];
        for (let i = 0; i < activeClips.length; i++) {
            const clip = activeClips[i];
            const contentToSearch = clip.content || clip.preview || "";
            if (contentToSearch.toLowerCase().indexOf(query) !== -1) {
                result.push(clip);
            }
        }
        return result;
    }

    onCurrentTabChanged: {
        selectedIndex = 0;
        flickable.contentY = 0;
    }

    Timer {
        id: focusTimer
        interval: 10
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    Component.onCompleted: {
        clipListProcess.running = true;
    }

    onShowConditionChanged: {
        if (showCondition) {
            searchText = "";
            selectedIndex = 0;
            focusTimer.restart();
            clipListProcess.running = true;
        }
    }

    onSearchTextChanged: {
        selectedIndex = 0;
    }

    onSelectedIndexChanged: {
        if (filteredClips.length === 0) return;
        if (listView.currentIndex !== selectedIndex) {
            listView.currentIndex = selectedIndex;
        }
        listView.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function copyClip(clip) {
        if (!clip || !clip.id) return;
        if (clip.is_image) {
            let ext = "png";
            const match = clip.content.match(/(png|jpg|jpeg|bmp|gif)\s*\]\]$/i);
            if (match) {
                ext = match[1].toLowerCase();
            }
            let mime = "image/" + ext;
            if (ext === "jpg") mime = "image/jpeg";
            Quickshell.execDetached(["sh", "-c", "echo -n " + JSON.stringify(clip.id) + " | cliphist decode > /tmp/clip_temp_$$ && echo -n " + JSON.stringify(clip.id) + " | cliphist delete && wl-copy --type " + mime + " < /tmp/clip_temp_$$; rm -f /tmp/clip_temp_$$"]);
        } else if (clip.content.trim().startsWith("file://")) {
            Quickshell.execDetached(["sh", "-c", "echo -n " + JSON.stringify(clip.id) + " | cliphist decode > /tmp/clip_temp_$$ && echo -n " + JSON.stringify(clip.id) + " | cliphist delete && wl-copy --type text/uri-list < /tmp/clip_temp_$$; rm -f /tmp/clip_temp_$$"]);
        } else {
            Quickshell.execDetached(["sh", "-c", "echo -n " + JSON.stringify(clip.id) + " | cliphist decode > /tmp/clip_temp_$$ && echo -n " + JSON.stringify(clip.id) + " | cliphist delete && wl-copy < /tmp/clip_temp_$$; rm -f /tmp/clip_temp_$$"]);
        }
        root.closeRequested();
    }

    function togglePin(clip) {
        if (!clip || !clip.id) return;
        
        const isPinned = clip.is_pinned || false;
        
        if (isPinned) {
            Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/clip_list.py", "--unpin", clip.content]);
            
            var updated = [];
            for (var i = 0; i < root.allClips.length; i++) {
                var c = root.allClips[i];
                if (c.id === clip.id) {
                    c.is_pinned = false;
                }
                updated.push(c);
            }
            root.allClips = updated;
        } else {
            Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/clip_list.py", "--pin", clip.id]);
            
            var updated = [];
            for (var i = 0; i < root.allClips.length; i++) {
                var c = root.allClips[i];
                if (c.id === clip.id) {
                    c.is_pinned = true;
                }
                updated.push(c);
            }
            root.allClips = updated;
        }
    }

    function deleteClip(clip, index) {
        if (!clip || !clip.id) return;
        
        if (clip.is_pinned) {
            Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/clip_list.py", "--unpin", clip.content]);
        }
        
        Quickshell.execDetached(["sh", "-c", "echo -n " + JSON.stringify(clip.id) + " | cliphist delete"]);
        
        var updated = [];
        for (var i = 0; i < root.allClips.length; i++) {
            if (root.allClips[i].id !== clip.id) {
                updated.push(root.allClips[i]);
            }
        }
        root.allClips = updated;
        
        if (root.selectedIndex >= root.filteredClips.length) {
            root.selectedIndex = Math.max(0, root.filteredClips.length - 1);
        }
    }

    function clearAll() {
        Quickshell.execDetached(["sh", "-c", "cliphist wipe && rm -rf ~/.cache/cliphist/thumbnails/*"]);
        root.allClips = [];
        root.searchText = "";
        root.selectedIndex = 0;
    }

    Process {
        id: clipListProcess
        command: ["python3", Quickshell.shellDir + "/bin/clip_list.py"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        const clips = JSON.parse(this.text);
                        root.allClips = clips;
                    } catch (e) {
                        console.log("Error parsing clips JSON:", e);
                    }
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 16

        // Search Bar & Clear All Row
        Row {
            id: searchRow
            width: parent.width
            spacing: 12

            // Search Bar Container
            Rectangle {
                width: parent.width - (clearAllButton.visible ? clearAllButton.width + 12 : 0)
                height: 44
                radius: 14
                color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 0

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        id: searchIcon
                        text: ""
                        font.family: root.iconFontFamily
                        font.pixelSize: 14
                        color: searchInput.activeFocus ? "#ffffff" : Qt.rgba(1, 1, 1, 0.35)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextField {
                        id: searchInput
                        focus: true
                        width: parent.width - searchIcon.width - 24
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        
                        placeholderText: qsTr("Search clipboard...")
                        placeholderTextColor: Qt.rgba(1, 1, 1, 0.3)
                        color: "#ffffff"
                        
                        font.family: root.textFontFamily
                        font.pixelSize: 14
                        
                        background: null
                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0
                        verticalAlignment: TextInput.AlignVCenter
                        
                        text: root.searchText
                        onTextChanged: root.searchText = text

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Down) {
                                if (root.filteredClips.length > 0) {
                                    root.selectedIndex = Math.min(root.filteredClips.length - 1, root.selectedIndex + 1);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Up) {
                                if (root.filteredClips.length > 0) {
                                    root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ControlModifier)) {
                                root.currentTab = root.currentTab === "recent" ? "pinned" : "recent";
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (root.filteredClips.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredClips.length) {
                                    root.copyClip(root.filteredClips[root.selectedIndex]);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Delete) {
                                if (root.filteredClips.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredClips.length) {
                                    root.deleteClip(root.filteredClips[root.selectedIndex], root.selectedIndex);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Escape) {
                                root.closeRequested();
                                event.accepted = true;
                            }
                        }
                    }
                }
            }

            // Clear All Button
            Rectangle {
                id: clearAllButton
                visible: root.currentTab === "recent"
                width: 120
                height: 44
                radius: 14
                color: clearAllMouseArea.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.15) : Qt.rgba(1, 1, 1, 0.05)
                border.width: 0

                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: ""
                        font.family: root.iconFontFamily
                        font.pixelSize: 14
                        color: clearAllMouseArea.containsMouse ? "#ff5555" : Qt.rgba(1, 1, 1, 0.6)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: qsTr("Clear All")
                        font.family: root.textFontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: clearAllMouseArea.containsMouse ? "#ff5555" : Qt.rgba(1, 1, 1, 0.6)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: clearAllMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.showConfirmModal = true;
                    }
                }
            }
        }

        // Sliding pill tab bar
        Rectangle {
            id: tabBar
            width: parent.width
            height: 36
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.03)
            border.width: 0

            Rectangle {
                id: tabIndicator
                width: parent.width / 2 - 8
                height: parent.height - 8
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 0
                y: 4
                x: root.currentTab === "recent" ? 4 : parent.width / 2 + 4
                
                Behavior on x {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Row {
                anchors.fill: parent
                
                Item {
                    width: parent.width / 2
                    height: parent.height
                    
                    Text {
                        text: qsTr("Recent")
                        anchors.centerIn: parent
                        font.family: root.textFontFamily
                        font.pixelSize: 13
                        font.weight: root.currentTab === "recent" ? Font.Bold : Font.Normal
                        color: root.currentTab === "recent" ? "#ffffff" : Qt.rgba(1, 1, 1, 0.4)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.currentTab = "recent";
                        }
                    }
                }
                
                Item {
                    width: parent.width / 2
                    height: parent.height
                    
                    Text {
                        text: qsTr("Pinned")
                        anchors.centerIn: parent
                        font.family: root.textFontFamily
                        font.pixelSize: 13
                        font.weight: root.currentTab === "pinned" ? Font.Bold : Font.Normal
                        color: root.currentTab === "pinned" ? "#ffffff" : Qt.rgba(1, 1, 1, 0.4)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.currentTab = "pinned";
                        }
                    }
                }
            }
        }

        // ListView scroll area for clipboard items
        ListView {
            id: listView
            width: parent.width
            height: parent.height - searchRow.height - tabBar.height - 32
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 8
            currentIndex: root.selectedIndex

            onCurrentIndexChanged: {
                root.selectedIndex = currentIndex;
            }

            model: root.filteredClips

            delegate: Item {
                id: clipItem
                width: listView.width
                height: modelData.is_image ? 180 : 52

                readonly property bool isSelected: index === root.selectedIndex

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: isSelected 
                        ? Qt.rgba(1, 1, 1, 0.08) 
                        : (itemMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent")
                    border.width: 0
                    
                    Behavior on color { ColorAnimation { duration: 100 } }

                    // Header row for text clips only
                    Item {
                        id: headerItem
                        width: parent.width
                        height: 52
                        anchors.top: parent.top
                        visible: !modelData.is_image

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 8
                            spacing: 12

                            // Clip Text Preview
                            Text {
                                text: modelData.preview
                                color: isSelected ? "#ffffff" : Qt.rgba(1, 1, 1, 0.65)
                                font.family: root.textFontFamily
                                font.pixelSize: 13
                                font.weight: isSelected ? Font.Medium : Font.Normal
                                width: parent.width - deleteButton.width - pinButton.width - 36
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Pin option
                            Rectangle {
                                id: pinButton
                                width: 36
                                height: 36
                                radius: 8
                                color: pinMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                anchors.verticalCenter: parent.verticalCenter
                                
                                readonly property bool isPinnedItem: root.currentTab === "pinned" || !!modelData.is_pinned

                                Text {
                                    text: ""
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 14
                                    color: pinButton.isPinnedItem 
                                        ? (pinMouseArea.containsMouse ? "#38bdf8" : "#0ea5e9") 
                                        : (pinMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(1, 1, 1, 0.3))
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: pinMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.togglePin(modelData);
                                    }
                                }
                            }

                            // Delete option on the right end
                            Rectangle {
                                id: deleteButton
                                width: 36
                                height: 36
                                radius: 8
                                color: deleteMouseArea.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.15) : "transparent"
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: ""
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 14
                                    color: deleteMouseArea.containsMouse ? "#ff5555" : Qt.rgba(1, 1, 1, 0.3)
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: deleteMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.deleteClip(modelData, index);
                                    }
                                }
                            }
                        }
                    }

                    // Full-width edge-to-edge clear image preview for image clips
                    Rectangle {
                        id: bigImagePreview
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 10
                        color: "#0c0c0e"
                        border.color: isSelected ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1
                        clip: true
                        visible: modelData.is_image

                        // Clean, high-resolution image preview without downscaling or dark overlays
                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: modelData.is_image ? modelData.thumbnail : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            mipmap: true
                        }

                        // Floating top-right overlay action buttons for Pin & Delete on image clips
                        Row {
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            spacing: 6
                            z: 10

                            Rectangle {
                                id: imgPinBtn
                                width: 32
                                height: 32
                                radius: 16
                                color: imgPinMouseArea.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.55)
                                border.color: Qt.rgba(255, 255, 255, 0.15)
                                border.width: 1

                                readonly property bool isPinnedItem: root.currentTab === "pinned" || !!modelData.is_pinned

                                Text {
                                    text: ""
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 13
                                    color: imgPinBtn.isPinnedItem 
                                        ? (imgPinMouseArea.containsMouse ? "#38bdf8" : "#0ea5e9") 
                                        : (imgPinMouseArea.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.7))
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: imgPinMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.togglePin(modelData)
                                }
                            }

                            Rectangle {
                                id: imgDeleteBtn
                                width: 32
                                height: 32
                                radius: 16
                                color: imgDeleteMouseArea.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.4) : Qt.rgba(0, 0, 0, 0.55)
                                border.color: Qt.rgba(255, 255, 255, 0.15)
                                border.width: 1

                                Text {
                                    text: ""
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 13
                                    color: imgDeleteMouseArea.containsMouse ? "#ff5555" : Qt.rgba(1, 1, 1, 0.7)
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: imgDeleteMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.deleteClip(modelData, index)
                                }
                            }
                        }

                        // Floating bottom-left badge tag
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            height: 22
                            width: imgTagText.implicitWidth + 14
                            radius: 11
                            color: Qt.rgba(0, 0, 0, 0.55)
                            border.color: Qt.rgba(255, 255, 255, 0.1)
                            border.width: 1
                            z: 10

                            Text {
                                id: imgTagText
                                anchors.centerIn: parent
                                text: "🖼️ Image"
                                color: Qt.rgba(1, 1, 1, 0.75)
                                font.family: root.textFontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    anchors.rightMargin: modelData.is_image ? 0 : 96
                    hoverEnabled: true
                    onContainsMouseChanged: {
                        if (containsMouse) {
                            root.selectedIndex = index;
                        }
                    }
                    onClicked: {
                        root.copyClip(modelData);
                    }
                }
            }
        }
    }

    // No clips found indicator
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 30
        visible: root.filteredClips.length === 0
        spacing: 12

        Text {
            text: root.currentTab === "pinned" ? "" : ""
            font.family: root.iconFontFamily
            font.pixelSize: 32
            color: Qt.rgba(1, 1, 1, 0.2)
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.currentTab === "pinned" 
                ? (root.searchText !== "" ? qsTr("No matching pinned items") : qsTr("No pinned items yet"))
                : (root.searchText !== "" ? qsTr("No matching clips found") : qsTr("Clipboard is empty"))
            font.family: root.textFontFamily
            font.pixelSize: 13
            color: Qt.rgba(1, 1, 1, 0.2)
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Clear All Confirmation Modal Overlay
    Rectangle {
        id: confirmModalOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        visible: opacity > 0 || clipModalOpacityAnim.running
        opacity: root.showConfirmModal ? 1 : 0
        z: 100

        Behavior on opacity {
            OpacityAnimator {
                id: clipModalOpacityAnim
                duration: 180
                easing.type: Easing.InOutQuad
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
        }

        Rectangle {
            width: 320
            height: 170
            radius: 20
            color: "#18181a"
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            anchors.centerIn: parent

            scale: root.showConfirmModal ? 1.0 : 0.9
            Behavior on scale {
                NumberAnimation { duration: 180; easing.type: Easing.OutBack }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Text {
                    text: qsTr("Clear clipboard history?")
                    color: "#ffffff"
                    font.family: root.textFontFamily
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: qsTr("This will delete all items and cannot be undone.")
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.family: root.textFontFamily
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    wrapMode: Text.Wrap
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Row {
                    width: parent.width
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 40
                        radius: 12
                        color: cancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            text: qsTr("Cancel")
                            color: "#ffffff"
                            font.family: root.textFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.showConfirmModal = false;
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 40
                        radius: 12
                        color: confirmMouse.containsMouse ? "#ff4444" : "#e63946"
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            text: qsTr("Clear All")
                            color: "#ffffff"
                            font.family: root.textFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: confirmMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.showConfirmModal = false;
                                root.clearAll();
                            }
                        }
                    }
                }
            }
        }
    }
}
