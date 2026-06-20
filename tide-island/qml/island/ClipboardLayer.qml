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

    property var allClips: []
    property int selectedIndex: 0
    property string searchText: ""
    property bool showConfirmModal: false

    readonly property var filteredClips: {
        if (searchText.trim() === "") {
            return allClips;
        }
        const query = searchText.toLowerCase().trim();
        const result = [];
        for (let i = 0; i < allClips.length; i++) {
            const clip = allClips[i];
            if (clip.content.toLowerCase().indexOf(query) !== -1) {
                result.push(clip);
            }
        }
        return result;
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
            clipListProcess.running = true; // Refresh when opening
        }
    }

    onSearchTextChanged: {
        selectedIndex = 0;
    }

    onSelectedIndexChanged: {
        if (filteredClips.length === 0) return;
        
        let yPos = 0;
        let selectedHeight = 52;
        const spacing = 8;
        
        for (let i = 0; i < selectedIndex; i++) {
            const clip = filteredClips[i];
            yPos += (clip.is_image ? 176 : 52) + spacing;
        }
        
        if (selectedIndex < filteredClips.length) {
            selectedHeight = filteredClips[selectedIndex].is_image ? 176 : 52;
        }
        
        if (yPos < flickable.contentY) {
            flickable.contentY = yPos;
        } else if (yPos + selectedHeight > flickable.contentY + flickable.height) {
            flickable.contentY = yPos + selectedHeight - flickable.height;
        }
    }

    function copyClip(clip) {
        if (!clip || !clip.id) return;
        Quickshell.execDetached(["sh", "-c", "echo -n " + JSON.stringify(clip.id) + " | cliphist decode > /tmp/clip_temp_$$ && echo -n " + JSON.stringify(clip.id) + " | cliphist delete && wl-copy < /tmp/clip_temp_$$; rm -f /tmp/clip_temp_$$"]);
        root.closeRequested();
    }

    function deleteClip(clip, index) {
        if (!clip || !clip.id) return;
        Quickshell.execDetached(["sh", "-c", "echo -n " + JSON.stringify(clip.id) + " | cliphist delete"]);
        // Remove locally for instant feedback
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
            width: parent.width
            spacing: 12

            // Search Bar Container
            Rectangle {
                width: parent.width - clearAllButton.width - 12
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

        // Flickable scroll area for clipboard items
        Flickable {
            id: flickable
            width: parent.width
            height: parent.height - 44 - 16
            contentWidth: width
            contentHeight: listColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: listColumn
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.filteredClips

                    delegate: Item {
                        id: clipItem
                        required property var modelData
                        required property int index

                        width: listColumn.width
                        height: modelData.is_image ? 176 : 52

                        readonly property bool isSelected: index === root.selectedIndex

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: isSelected 
                                ? Qt.rgba(1, 1, 1, 0.08) 
                                : (itemMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent")
                            border.width: 0
                            
                            Behavior on color { ColorAnimation { duration: 100 } }

                            // Header row (contains text preview and delete button)
                            Item {
                                id: headerItem
                                width: parent.width
                                height: 52
                                anchors.top: parent.top

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
                                        width: parent.width - deleteButton.width - 24
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
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

                            // Big image preview below the header
                            Rectangle {
                                id: bigImagePreview
                                anchors.top: headerItem.bottom
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 12
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                radius: 8
                                color: "#0a0a0c"
                                border.color: isSelected ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.05)
                                border.width: 1
                                clip: true
                                visible: modelData.is_image

                                // 1. Blurred background representation for color-matched ambient fallback
                                Image {
                                    anchors.fill: parent
                                    source: modelData.is_image ? modelData.thumbnail : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    opacity: 0.3
                                    sourceSize.width: 100 // low resolution for soft natural blur
                                    sourceSize.height: 50
                                }

                                // 2. Foreground full image preview preserving aspect ratio
                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    source: modelData.is_image ? modelData.thumbnail : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    sourceSize.width: 600
                                    sourceSize.height: 300
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.25) }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            anchors.rightMargin: 44 // Don't trigger copy when clicking delete
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
        }
    }

    // No clips found indicator
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 30
        visible: root.filteredClips.length === 0
        spacing: 12

        Text {
            text: ""
            font.family: root.iconFontFamily
            font.pixelSize: 32
            color: Qt.rgba(1, 1, 1, 0.2)
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("Clipboard is empty")
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
        visible: opacity > 0
        opacity: root.showConfirmModal ? 1 : 0
        z: 100

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
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
