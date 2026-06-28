import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import QtQuick.Shapes

Rectangle {
    id: root
    implicitWidth: 300
    implicitHeight: 240
    radius: 12
    
    color: root.theme.surface_container
    border.width: 0

    // Extra layering for thickness and opacity
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(0, 0, 0, 0.45) // Deep contrast layer
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(1.0, 1.0, 1.0, 0.05) // Frosted shine layer
    }



    property QtObject theme
    property string iconFontFamily: ""
    property string textFontFamily: ""

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
        totalCount = todoModel.count
    }

    // Processes to Save/Load Tasks dynamically to user's config directory
    Process {
        id: saveProcess
    }

    function saveTasks() {
        var list = [];
        for (var i = 0; i < todoModel.count; i++) {
            var item = todoModel.get(i);
            list.push({ text: item.taskText, done: item.taskDone });
        }
        var jsonStr = JSON.stringify(list);
        saveProcess.command = ["sh", "-c", "mkdir -p ~/.config/tide-island && echo \"$1\" > ~/.config/tide-island/todo.json", "sh", jsonStr];
        saveProcess.running = true;
    }

    Process {
        id: loadProcess
        command: ["cat", "/home/aashiq/.config/tide-island/todo.json"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        var list = JSON.parse(this.text.trim());
                        if (Array.isArray(list)) {
                            todoModel.clear();
                            for (var i = 0; i < list.length; i++) {
                                todoModel.append({ taskText: list[i].text, taskDone: list[i].done });
                            }
                            root.updateCounts();
                        }
                    } catch (e) {
                        // Keep default if JSON fails to parse
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        loadProcess.running = true;
    }

    ListModel {
        id: todoModel
        ListElement { taskText: "Design Sidebar Widgets"; taskDone: true }
        ListElement { taskText: "Apply Matugen Palette"; taskDone: true }
        ListElement { taskText: "Implement Arch Toggle Pill"; taskDone: false }
        ListElement { taskText: "Verify QML in qml6 runtime"; taskDone: false }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            RowLayout {
                spacing: 10
                Text {
                    text: "\uf0ae"
                    font.family: root.iconFontFamily
                    font.pixelSize: 14
                    color: root.theme.primary
                }
                Text {
                    text: qsTr("Tasks")
                    color: root.theme.on_surface
                    font.family: root.textFontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.doneCount + "/" + root.totalCount
                color: root.theme.primary
                font.family: root.textFontFamily
                font.pixelSize: 12
                font.weight: Font.Bold
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.2)
        }

        // Tasks list
        ListView {
            id: todoListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: todoModel
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 6

            delegate: Item {
                id: delegateItem
                width: todoListView.width
                height: 30

                required property string taskText
                required property bool taskDone
                required property int index

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    Button {
                        id: checkButton
                        implicitWidth: 18
                        implicitHeight: 18
                        Layout.alignment: Qt.AlignVCenter

                        background: Rectangle {
                            radius: height / 2
                            color: delegateItem.taskDone ? root.theme.primary : "transparent"
                            border.color: delegateItem.taskDone ? "transparent" : root.theme.outline
                            border.width: delegateItem.taskDone ? 0 : 1.5
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        contentItem: Text {
                            text: "✓"
                            font.family: root.textFontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: root.theme.on_primary
                            visible: delegateItem.taskDone
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            todoModel.setProperty(delegateItem.index, "taskDone", !delegateItem.taskDone)
                            root.updateCounts()
                            root.saveTasks()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: delegateItem.taskText
                        color: delegateItem.taskDone ? root.theme.on_surface_variant : root.theme.on_surface
                        opacity: delegateItem.taskDone ? 0.5 : 0.9
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        font.strikeout: delegateItem.taskDone
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    
                    // Delete Button
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
                            font.family: root.textFontFamily
                            font.pixelSize: 10
                            color: root.theme.error
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            todoModel.remove(delegateItem.index)
                            root.updateCounts()
                            root.saveTasks()
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
            spacing: 8

            TextField {
                id: taskInput
                Layout.fillWidth: true
                implicitHeight: 32
                placeholderText: qsTr("Add a task...")
                font.family: root.textFontFamily
                font.pixelSize: 12
                color: root.theme.on_surface
                placeholderTextColor: root.theme.on_surface_variant
                
                background: Rectangle {
                    color: Qt.rgba(root.theme.secondary_container.r, root.theme.secondary_container.g, root.theme.secondary_container.b, 0.7)
                    border.color: taskInput.activeFocus ? root.theme.primary : Qt.rgba(root.theme.outline.r, root.theme.outline.g, root.theme.outline.b, 0.25)
                    border.width: 1
                    radius: 6
                }

                onAccepted: {
                    if (text.trim() !== "") {
                        todoModel.append({ taskText: text.trim(), taskDone: false })
                        text = ""
                        root.updateCounts()
                        root.saveTasks()
                    }
                }
            }

            Button {
                id: addBtn
                implicitWidth: 32
                implicitHeight: 32

                background: Rectangle {
                    color: addBtn.pressed ? Qt.darker(root.theme.primary, 1.2) : (addBtn.hovered ? Qt.lighter(root.theme.primary, 1.1) : root.theme.primary)
                    radius: 6
                }
                contentItem: Text {
                    text: "+"
                    font.family: root.textFontFamily
                    font.pixelSize: 16
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
                        root.saveTasks()
                    }
                }
            }
        }
    }
}
