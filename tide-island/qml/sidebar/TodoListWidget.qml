import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root
    implicitWidth: 300
    implicitHeight: 220
    radius: 16
    
    // Solid macOS-style widget background
    color: root.theme.surface
    border.color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.15)
    border.width: 1

    property QtObject theme
    property string iconFontFamily: ""

    // Counts
    property int doneCount: 0
    property int totalCount: todoModel.count

    function updateCounts() {
        var count = 0
        for (var i = 0; i < todoModel.count; i++) {
            if (todoModel.get(i).taskDone) {
                count++
            }
        }
        doneCount = count
    }

    Component.onCompleted: updateCounts()

    ListModel {
        id: todoModel
        ListElement { taskText: "Design Sidebar Widgets"; taskDone: true }
        ListElement { taskText: "Apply Matugen Palette"; taskDone: true }
        ListElement { taskText: "Implement Arch Toggle Pill"; taskDone: false }
        ListElement { taskText: "Verify QML in qml6 runtime"; taskDone: false }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                spacing: 6
                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: Qt.rgba(root.theme.primary.r, root.theme.primary.g, root.theme.primary.b, 0.15)
                    
                    Text {
                        anchors.centerIn: parent
                        text: "\uf0ae"
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                        color: root.theme.primary
                    }
                }

                Text {
                    text: qsTr("Tasks")
                    color: root.theme.on_surface
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.doneCount + "/" + root.totalCount + " " + qsTr("done")
                color: root.theme.on_surface_variant
                font.pixelSize: 10
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.1)
        }

        // Tasks list
        ListView {
            id: todoListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: todoModel
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 4

            delegate: Item {
                id: delegateItem
                width: todoListView.width
                height: 26

                required property string taskText
                required property bool taskDone
                required property int index

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    // Circular Checkbox (macOS style)
                    Button {
                        id: checkButton
                        implicitWidth: 16
                        implicitHeight: 16
                        Layout.alignment: Qt.AlignVCenter

                        background: Rectangle {
                            radius: height / 2
                            color: delegateItem.taskDone ? root.theme.primary : "transparent"
                            border.color: delegateItem.taskDone ? "transparent" : root.theme.outline
                            border.width: delegateItem.taskDone ? 0 : 1.5

                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        contentItem: Text {
                            text: "✓"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: root.theme.on_primary
                            visible: delegateItem.taskDone
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            todoModel.setProperty(delegateItem.index, "taskDone", !delegateItem.taskDone)
                            root.updateCounts()
                        }
                    }

                    // Text
                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: delegateItem.taskText
                        color: delegateItem.taskDone ? root.theme.on_surface_variant : root.theme.on_surface
                        opacity: delegateItem.taskDone ? 0.5 : 0.9
                        font.pixelSize: 11
                        font.strikeout: delegateItem.taskDone
                        elide: Text.ElideRight

                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    // Delete
                    Button {
                        id: deleteBtn
                        implicitWidth: 16
                        implicitHeight: 16
                        visible: deleteBtnMouse.hovered

                        background: Rectangle {
                            color: "transparent"
                        }

                        contentItem: Text {
                            text: "✕"
                            font.pixelSize: 9
                            color: root.theme.error
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            todoModel.remove(delegateItem.index)
                            root.updateCounts()
                        }
                    }

                    HoverHandler {
                        id: deleteBtnMouse
                    }
                }
            }
        }

        // Add Input form
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            TextField {
                id: taskInput
                Layout.fillWidth: true
                implicitHeight: 26
                placeholderText: qsTr("Add a task...")
                font.pixelSize: 11
                color: root.theme.on_surface
                placeholderTextColor: root.theme.on_surface_variant
                
                background: Rectangle {
                    color: Qt.rgba(root.theme.surface_container.r, root.theme.surface_container.g, root.theme.surface_container.b, 0.4)
                    border.color: taskInput.activeFocus ? root.theme.primary : Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.2)
                    border.width: taskInput.activeFocus ? 1.5 : 1
                    radius: 6
                }

                onAccepted: {
                    if (text.trim() !== "") {
                        todoModel.append({ taskText: text.trim(), taskDone: false })
                        text = ""
                        root.updateCounts()
                    }
                }
            }

            Button {
                id: addBtn
                implicitWidth: 26
                implicitHeight: 26

                background: Rectangle {
                    color: addBtn.pressed ? Qt.darker(root.theme.primary, 1.1) : (addBtn.hovered ? Qt.lighter(root.theme.primary, 1.05) : root.theme.primary)
                    radius: 6
                }

                contentItem: Text {
                    text: "+"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: root.theme.on_primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    if (taskInput.text.trim() !== "") {
                        todoModel.append({ taskText: taskInput.text.trim(), taskDone: false })
                        taskInput.text = ""
                        root.updateCounts()
                    }
                }
            }
        }
    }
}
