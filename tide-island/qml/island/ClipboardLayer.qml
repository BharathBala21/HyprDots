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
        const itemHeight = 52 + 8; // height + spacing
        const yPos = selectedIndex * itemHeight;
        
        if (yPos < flickable.contentY) {
            flickable.contentY = yPos;
        } else if (yPos + 52 > flickable.contentY + flickable.height) {
            flickable.contentY = yPos + 52 - flickable.height;
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
                        root.clearAll();
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
                        height: 52

                        readonly property bool isSelected: index === root.selectedIndex

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: isSelected 
                                ? Qt.rgba(1, 1, 1, 0.08) 
                                : (itemMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent")
                            border.width: 0
                            
                            Behavior on color { ColorAnimation { duration: 100 } }

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
}
