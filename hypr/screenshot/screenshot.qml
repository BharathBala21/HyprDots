import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import IslandBackend

ShellRoot {
    id: shellRoot

    // The shared active selection state across all windows
    property int selectedIndex: 2 // default to Region

    // When an option is confirmed
    signal confirmed(int index)

    onConfirmed: (index) => {
        takeScreenshot(index);
    }

    Component.onCompleted: {
        var mode = Quickshell.env("SCREENSHOT_MODE") || "region";
        if (mode === "output" || mode === "workspace") {
            selectedIndex = 0;
        } else if (mode === "window") {
            selectedIndex = 1;
        } else if (mode === "region") {
            selectedIndex = 2;
        } else {
            selectedIndex = 2;
        }
    }

    function takeScreenshot(index) {
        if (index === 3) {
            Qt.quit();
            return;
        }

        var cmd = [];
        if (index === 0) {
            var monitorName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "eDP-1";
            cmd = ["hyprshot", "-z", "-m", "output", "-m", monitorName];
        } else if (index === 1) {
            cmd = ["hyprshot", "-z", "-m", "window"];
        } else if (index === 2) {
            cmd = ["hyprshot", "-z", "-m", "region"];
        }

        Quickshell.execDetached(cmd);
        Qt.quit();
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            aboveWindows: true
            focusable: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "screenshot_overlay"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // Fade-in animation for the overlay content
            Component.onCompleted: {
                fadeInAnimation.start();
                overlayBackground.forceActiveFocus();
            }

            SequentialAnimation {
                id: fadeInAnimation
                NumberAnimation {
                    target: overlayBackground
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: overlayBackground
                anchors.fill: parent
                color: Qt.rgba(StyleTokens.panel.r, StyleTokens.panel.g, StyleTokens.panel.b, 0.45)
                opacity: 0
                focus: true

                // Clicking anywhere on the background dismisses the screenshot GUI
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Qt.quit();
                    }
                }

                // Handle keyboard navigation globally on each window
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        Qt.quit();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                        shellRoot.selectedIndex = (shellRoot.selectedIndex + 3) % 4;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                        shellRoot.selectedIndex = (shellRoot.selectedIndex + 1) % 4;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                        shellRoot.confirmed(shellRoot.selectedIndex);
                        event.accepted = true;
                    }
                }

                // The Pill GUI container towards the bottom
                Rectangle {
                    id: pill
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 80
                    anchors.horizontalCenter: parent.horizontalCenter

                    implicitWidth: contentRow.width + 32
                    implicitHeight: 64
                    radius: 32

                    // Styling matching tide-island
                    color: StyleTokens.panel
                    border.color: Qt.rgba(StyleTokens.textPrimary.r, StyleTokens.textPrimary.g, StyleTokens.textPrimary.b, 0.15)
                    border.width: 1

                    Row {
                        id: contentRow
                        anchors.centerIn: parent
                        spacing: 8

                        // Workspace button
                        PillButton {
                            icon: "󰖲"
                            label: "Workspace"
                            isSelected: shellRoot.selectedIndex === 0
                            onClicked: {
                                shellRoot.selectedIndex = 0;
                                shellRoot.confirmed(0);
                            }
                        }

                        // Window button
                        PillButton {
                            icon: "󰖯"
                            label: "Window"
                            isSelected: shellRoot.selectedIndex === 1
                            onClicked: {
                                shellRoot.selectedIndex = 1;
                                shellRoot.confirmed(1);
                            }
                        }

                        // Region button
                        PillButton {
                            icon: "󰆞"
                            label: "Region"
                            isSelected: shellRoot.selectedIndex === 2
                            onClicked: {
                                shellRoot.selectedIndex = 2;
                                shellRoot.confirmed(2);
                            }
                        }

                        // Vertical separator
                        Rectangle {
                            width: 1
                            height: 24
                            color: Qt.rgba(StyleTokens.textPrimary.r, StyleTokens.textPrimary.g, StyleTokens.textPrimary.b, 0.15)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Cancel button
                        PillButton {
                            icon: "󰅖"
                            label: "Cancel"
                            isSelected: shellRoot.selectedIndex === 3
                            isCancel: true
                            onClicked: {
                                shellRoot.selectedIndex = 3;
                                shellRoot.confirmed(3);
                            }
                        }
                    }
                }
            }
        }
    }
}
