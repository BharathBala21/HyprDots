import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import IslandBackend
import "../common"

Item {
    id: root

    property var window: null
    property string textFontFamily: ""
    property string iconFontFamily: ""

    // Symmetrical styling to TopRightStatus
    implicitHeight: 32
    height: implicitHeight

    // Only visible if there are system tray items
    readonly property bool hasItems: SystemTray.items && SystemTray.items.values && SystemTray.items.values.length > 0
    opacity: hasItems ? 1.0 : 0.0
    visible: opacity > 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing.type: Easing.InOutQuad
        }
    }

    implicitWidth: {
        if (!hasItems) return 0;
        // Padding (8 * 2 = 16) + icons (20 * count) + spacing (8 * (count - 1))
        const count = SystemTray.items.values.length;
        return 16 + (20 * count) + (8 * (count - 1));
    }
    width: implicitWidth

    Behavior on width {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuad
        }
    }

    FileView {
        id: trayCfgWatcher
        path: (Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")) + "/.config/tide-island/userconfig.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: trayCfgWatcher.reload()
    }

    readonly property var trayCfgData: {
        try {
            return trayCfgWatcher.text() ? JSON.parse(trayCfgWatcher.text()) : {};
        } catch (e) {
            return {};
        }
    }

    readonly property bool isNotchStyle: trayCfgData.islandStyle === "notch"

    Rectangle {
        id: trayBgRect
        anchors.fill: parent
        color: StyleTokens.black
        radius: height / 2
        border.width: 1
        border.color: StyleTokens.overviewInnerBorder
    }

    // Top Notch Extension (Square top corners attached flush to top screen edge in Notch mode)
    Rectangle {
        visible: root.isNotchStyle
        anchors.top: trayBgRect.top
        anchors.left: trayBgRect.left
        anchors.right: trayBgRect.right
        height: Math.min(16, trayBgRect.height / 2)
        color: trayBgRect.color
        z: -1
    }

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: SystemTray.items ? SystemTray.items.values : null

            delegate: Item {
                id: delegateRoot
                width: 20
                height: 20

                readonly property var itemData: modelData

                Image {
                    id: iconImage
                    anchors.fill: parent
                    source: delegateRoot.itemData.icon ? delegateRoot.itemData.icon : ""
                    fillMode: Image.PreserveAspectFit
                    sourceSize: Qt.size(20, 20)
                    asynchronous: true
                }

                // Fallback text if the icon is not available
                Text {
                    anchors.centerIn: parent
                    visible: iconImage.status !== Image.Ready
                    text: delegateRoot.itemData.title ? delegateRoot.itemData.title.charAt(0).toUpperCase() : "?"
                    color: "white"
                    font.family: root.textFontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                HoverHandler {
                    id: hoverHandler
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            delegateRoot.itemData.activate();
                        } else if (mouse.button === Qt.RightButton) {
                            if (delegateRoot.itemData.hasMenu) {
                                const mappedPoint = mapToItem(null, mouse.x, mouse.y);
                                if (root.window) {
                                    delegateRoot.itemData.display(root.window, Math.round(mappedPoint.x), Math.round(mappedPoint.y));
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "white"
                    opacity: hoverHandler.hovered ? 0.15 : 0.0
                    radius: 4
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }
}
