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

    // Properties for applications list
    property var allApps: []
    property int selectedIndex: 0
    property string searchText: ""
    
    // Columns configuration
    readonly property int columns: 4
    readonly property int itemWidth: (width - 32 - (columns - 1) * 16) / columns
    readonly property int itemHeight: 90

    readonly property var filteredApps: {
        if (searchText.trim() === "") {
            return allApps;
        }
        const query = searchText.toLowerCase().trim();
        const result = [];
        for (let i = 0; i < allApps.length; i++) {
            const app = allApps[i];
            if (app.search.indexOf(query) !== -1) {
                result.push(app);
            }
        }
        return result;
    }

    // Defer active focus to text field to prevent wayland focus racing
    Timer {
        id: focusTimer
        interval: 10
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    Component.onCompleted: {
        appListProcess.running = true;
    }

    onShowConditionChanged: {
        if (showCondition) {
            searchText = "";
            selectedIndex = 0;
            focusTimer.restart();
        } else {
            // Refresh applications list in background to pick up any changes
            appListProcess.running = true;
        }
    }

    onSearchTextChanged: {
        selectedIndex = 0;
    }

    onSelectedIndexChanged: {
        if (filteredApps.length === 0) return;
        const row = Math.floor(selectedIndex / columns);
        const yPos = row * (itemHeight + 16);
        
        if (yPos < flickable.contentY) {
            flickable.contentY = yPos;
        } else if (yPos + itemHeight > flickable.contentY + flickable.height) {
            flickable.contentY = yPos + itemHeight - flickable.height;
        }
    }

    function launchApp(app) {
        if (!app || !app.exec) return;
        Quickshell.execDetached(["sh", "-c", app.exec]);
        root.closeRequested();
    }

    // Process to run python helper and load applications list
    Process {
        id: appListProcess
        command: ["python3", Quickshell.shellDir + "/bin/app_list.py"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        const apps = JSON.parse(this.text);
                        root.allApps = apps;
                    } catch (e) {
                        console.log("Error parsing apps JSON:", e);
                    }
                }
            }
        }
    }

    // Main Layout wrapper
    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 16

        // Search Bar Input Container (Ultra-Premium Dynamic Island Style, NO BORDER)
        Rectangle {
            id: searchBarContainer
            width: parent.width
            height: 44
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 0 // NO BORDER AT ALL

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
                    width: parent.width - searchIcon.width - (clearButton.visible ? clearButton.width : 0) - 40
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    
                    placeholderText: qsTr("Search applications...")
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
                        const cols = root.columns;
                        if (event.key === Qt.Key_Down) {
                            if (root.filteredApps.length > 0) {
                                root.selectedIndex = Math.min(root.filteredApps.length - 1, root.selectedIndex + cols);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Up) {
                            if (root.filteredApps.length > 0) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - cols);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Right) {
                            if (root.filteredApps.length > 0) {
                                root.selectedIndex = Math.min(root.filteredApps.length - 1, root.selectedIndex + 1);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Left) {
                            if (root.filteredApps.length > 0) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.filteredApps.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredApps.length) {
                                root.launchApp(root.filteredApps[root.selectedIndex]);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Escape) {
                            root.closeRequested();
                            event.accepted = true;
                        }
                    }
                }

                // Clear button
                Text {
                    id: clearButton
                    text: ""
                    font.family: root.iconFontFamily
                    font.pixelSize: 14
                    color: clearMouseArea.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.35)
                    visible: root.searchText !== ""
                    anchors.verticalCenter: parent.verticalCenter

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

        // Flickable Area for Grid (Scrollbars Hidden)
        Flickable {
            id: flickable
            width: parent.width
            height: parent.height - searchBarContainer.height - 16
            contentWidth: width
            contentHeight: grid.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // Grid View of Applications
            Grid {
                id: grid
                width: parent.width
                columns: root.columns
                spacing: 16

                Repeater {
                    model: root.filteredApps

                    delegate: Item {
                        id: appItem
                        required property var modelData
                        required property int index

                        width: root.itemWidth
                        height: root.itemHeight

                        readonly property bool isSelected: index === root.selectedIndex

                        // App Card (Clean background, NO BORDER)
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: isSelected 
                                ? Qt.rgba(1, 1, 1, 0.08) 
                                : (itemMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent")
                            border.width: 0 // NO BORDER AT ALL
                            
                            scale: isSelected ? 1.05 : 1.0
                            
                            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                // Rounded Container for App Icon
                                Rectangle {
                                    width: 40
                                    height: 40
                                    radius: 10
                                    color: "transparent"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    clip: true

                                    Image {
                                        id: appIconImage
                                        anchors.fill: parent
                                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                        smooth: true
                                        mipmap: true
                                        
                                        onStatusChanged: {
                                            if (status === Image.Error) {
                                                source = "image://icon/application-x-executable";
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.name
                                    color: isSelected ? "#ffffff" : Qt.rgba(1, 1, 1, 0.65)
                                    font.family: root.textFontFamily
                                    font.pixelSize: 12
                                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                                    width: appItem.width - 16
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onContainsMouseChanged: {
                                if (containsMouse) {
                                    root.selectedIndex = index;
                                }
                            }
                            onClicked: {
                                root.launchApp(modelData);
                            }
                        }
                    }
                }
            }
        }
    }

    // No apps found indicator
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 30
        visible: root.filteredApps.length === 0
        spacing: 12

        Text {
            text: ""
            font.family: root.iconFontFamily
            font.pixelSize: 32
            color: Qt.rgba(1, 1, 1, 0.2)
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("No applications found")
            font.family: root.textFontFamily
            font.pixelSize: 13
            color: Qt.rgba(1, 1, 1, 0.2)
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
