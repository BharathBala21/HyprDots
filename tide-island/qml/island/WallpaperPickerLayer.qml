import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io

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

    // Properties for wallpaper list
    property string wallpaperFolder: ""
    property string initialWallpaper: ""
    property string currentWallpaper: ""
    property var allWallpapers: []
    property int selectedIndex: 0
    property string searchText: ""

    // Grid configuration (4 columns fit perfectly)
    readonly property int columns: 4
    readonly property int itemWidth: (width - 32 - (columns - 1) * 12) / columns
    readonly property int itemHeight: Math.round(itemWidth * 9 / 16) // Keep 16:9 ratio

    readonly property var filteredWallpapers: {
        if (searchText.trim() === "") {
            return allWallpapers;
        }
        const query = searchText.toLowerCase().trim();
        return allWallpapers.filter(function(w) {
            return w.name.toLowerCase().indexOf(query) !== -1;
        });
    }

    // Defer active focus to text field to prevent Wayland focus racing
    Timer {
        id: focusTimer
        interval: 10
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    onShowConditionChanged: {
        if (showCondition) {
            searchText = "";
            wallpaperListProcess.running = true;
            focusTimer.restart();
        }
    }

    onSearchTextChanged: {
        selectedIndex = 0;
    }

    onSelectedIndexChanged: {
        if (filteredWallpapers.length === 0) return;
        if (gridView.currentIndex !== selectedIndex) {
            gridView.currentIndex = selectedIndex;
        }
        gridView.positionViewAtIndex(selectedIndex, GridView.Contain);
    }

    function previewWallpaper(path) {
        root.currentWallpaper = path;
        Quickshell.execDetached(["waypaper", "--wallpaper", path]);
        Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/update_user_config.py", "--wallpaper", path]);
    }

    function confirmWallpaper(path) {
        previewWallpaper(path);
        root.initialWallpaper = path; // Confirm it as the active wallpaper (reverting won't change it back)    
        root.closeRequested();
    }

    function revertAndClose() {
        if (initialWallpaper !== "" && initialWallpaper !== currentWallpaper) {
            Quickshell.execDetached(["waypaper", "--wallpaper", initialWallpaper]);
            Quickshell.execDetached(["python3", Quickshell.shellDir + "/bin/update_user_config.py", "--wallpaper", initialWallpaper]);
        }
        root.closeRequested();
    }

    Process {
        id: wallpaperListProcess
        command: ["python3", Quickshell.shellDir + "/bin/wallpaper_list.py"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        const res = JSON.parse(this.text);
                        root.wallpaperFolder = res.folder;
                        root.initialWallpaper = res.current;
                        root.currentWallpaper = res.current;
                        root.allWallpapers = res.wallpapers;
                        
                        // Set selectedIndex to matching active wallpaper path
                        for (let i = 0; i < res.wallpapers.length; i++) {
                            if (res.wallpapers[i].path === res.current) {
                                root.selectedIndex = i;
                                break;
                            }
                        }
                    } catch (e) {
                        console.log("Error parsing wallpaper JSON:", e);
                    }
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Search bar
        Rectangle {
            id: searchBarContainer
            width: parent.width
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
                    width: parent.width - searchIcon.width - (clearButton.visible ? clearButton.width : 0) - 40
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    
                    placeholderText: qsTr("Search wallpapers...")
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
                            if (root.filteredWallpapers.length > 0) {
                                root.selectedIndex = Math.min(root.filteredWallpapers.length - 1, root.selectedIndex + cols);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Up) {
                            if (root.filteredWallpapers.length > 0) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - cols);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Right) {
                            if (root.filteredWallpapers.length > 0) {
                                root.selectedIndex = Math.min(root.filteredWallpapers.length - 1, root.selectedIndex + 1);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Left) {
                            if (root.filteredWallpapers.length > 0) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.filteredWallpapers.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredWallpapers.length) {
                                root.confirmWallpaper(root.filteredWallpapers[root.selectedIndex].path);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Escape) {
                            root.revertAndClose();
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

        // Selection header details
        Text {
            width: parent.width
            height: 18
            text: {
                if (root.filteredWallpapers.length === 0) return qsTr("No wallpapers");
                const currentName = root.filteredWallpapers[root.selectedIndex].name;
                return currentName ? currentName : "";
            }
            font.family: root.textFontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Qt.rgba(1, 1, 1, 0.6)
            elide: Text.ElideRight
        }

        GridView {
            id: gridView
            width: parent.width
            height: parent.height - searchBarContainer.height - 46
            cellWidth: width / root.columns
            cellHeight: root.itemHeight + 12
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: root.selectedIndex

            onCurrentIndexChanged: {
                root.selectedIndex = currentIndex;
            }

            model: root.filteredWallpapers

            delegate: Item {
                id: wallpaperItem
                width: gridView.cellWidth
                height: gridView.cellHeight

                readonly property bool isSelected: index === root.selectedIndex
                readonly property bool isActive: modelData.path === root.initialWallpaper

                // Wallpaper Card Wrapper
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 10
                    color: isSelected ? Qt.rgba(1, 1, 1, 0.12) : (itemMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
                    clip: true
                    border.width: isSelected ? 2 : (isActive ? 1 : 0)
                    border.color: isSelected ? "#ffffff" : Qt.rgba(1, 1, 1, 0.25)
                    
                    scale: isSelected ? 1.04 : 1.0

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Image {
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        source: "file://" + modelData.thumb
                        // Guard decode size to prevent full resolution decoding during initialization
                        sourceSize.width: root.itemWidth > 0 ? root.itemWidth : 200
                        sourceSize.height: root.itemHeight > 0 ? root.itemHeight : 113
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        opacity: isSelected ? 1.0 : 0.75
                        
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    // Glowing badge for active wallpaper
                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 6
                        width: 14
                        height: 14
                        radius: 7
                        color: "#4caf50"
                        visible: isActive
                        border.width: 1.5
                        border.color: "#ffffff"
                    }
                }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.selectedIndex = index;
                        root.previewWallpaper(modelData.path);
                    }
                    onDoubleClicked: {
                        root.confirmWallpaper(modelData.path);
                    }
                }
            }
        }
    }

    // No wallpapers found indicator
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 30
        visible: root.filteredWallpapers.length === 0
        spacing: 12

        Text {
            text: "🖼️"
            font.pixelSize: 32
            opacity: 0.2
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("No matching wallpapers found")
            font.family: root.textFontFamily
            font.pixelSize: 13
            color: Qt.rgba(1, 1, 1, 0.2)
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
