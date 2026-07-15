import QtQuick
import QtQuick.Controls.Basic

Window {
    id: window
    width: 1200
    height: 900
    visible: true
    title: "tide-island - Glassmorphic Sidebar Test"

    // Gorgeous gradient wallpaper mimicking a premium macOS desktop
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0F172A" } // Sleek slate dark blue
            GradientStop { position: 0.5; color: "#1E1B4B" } // Soft indigo highlight
            GradientStop { position: 1.0; color: "#020617" } // Deep space black
        }

        // Simulated desktop elements for visual preview context
        Text {
            anchors.centerIn: parent
            text: "Arch Linux Environment"
            color: "#334155"
            font.pixelSize: 24
            font.weight: Font.Light
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 24
            text: "tide-island / qml / sidebar"
            color: "#475569"
            font.pixelSize: 14
        }
    }

    // Sidebar overlay covering the desktop
    Sidebar {
        anchors.fill: parent
    }
}
