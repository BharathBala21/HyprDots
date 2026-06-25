import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pam

ShellRoot {
    id: root

    Process {
        id: terminator
        command: ["sh", "-c", "kill -9 $PPID"]
    }

    Component.onCompleted: {
        console.log("PamResult keys:", Object.keys(PamResult));
        console.log("PamResult.Success:", PamResult.Success);
        console.log("PamResult.Error:", PamResult.Error);
        terminator.running = true;
    }
}


