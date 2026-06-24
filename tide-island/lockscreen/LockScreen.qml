import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Pam

Item {
    id: rootItem
    anchors.fill: parent
    focus: true

    property string wallpaperPath: ""
    property bool isLocked: true
    signal unlocked()

    property bool passwordFieldVisible: false

    // Format date and time
    function updateTime() {
        let d = new Date();
        let hours = d.getHours().toString().padStart(2, '0');
        let minutes = d.getMinutes().toString().padStart(2, '0');
        timeText.text = hours + ":" + minutes;

        let days = [qsTr("Sunday"), qsTr("Monday"), qsTr("Tuesday"), qsTr("Wednesday"), qsTr("Thursday"), qsTr("Friday"), qsTr("Saturday")];
        let months = [qsTr("January"), qsTr("February"), qsTr("March"), qsTr("April"), qsTr("May"), qsTr("June"), 
                      qsTr("July"), qsTr("August"), qsTr("September"), qsTr("October"), qsTr("November"), qsTr("December")];
        dateText.text = days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate();
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: rootItem.updateTime()
    }

    // Wallpaper with scale and blur transition
    Image {
        id: bgImage
        source: rootItem.wallpaperPath
        fillMode: Image.PreserveAspectCrop
        // Make the image slightly larger than the screen to hide blur edge artifacts
        width: parent.width + 128
        height: parent.height + 128
        anchors.centerIn: parent
        asynchronous: true
        
        // Start slightly zoomed out for the transition
        scale: 1.05

        Behavior on scale {
            NumberAnimation { duration: 1200; easing.type: Easing.OutCubic }
        }

        Component.onCompleted: {
            // Trigger zoom in transition
            bgImage.scale = 1.0;
        }
    }

    MultiEffect {
        id: blurEffect
        source: bgImage
        anchors.fill: bgImage
        blurEnabled: true
        blurMax: 64
        
        // Start clean, transition to fully blurred
        blur: 0.0

        Behavior on blur {
            NumberAnimation { duration: 1000; easing.type: Easing.OutQuad }
        }

        Component.onCompleted: {
            // Trigger blur transition
            blurEffect.blur = 1.0;
        }
    }

    // Dark tint overlay to ensure text contrast (WCAG)
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.45
    }

    // Ambient floating glow spots (render-thread animated particles)
    Repeater {
        model: 6
        Item {
            id: particle
            width: 250 + index * 80
            height: width
            
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                // Curated visual palette of dark blue, indigo, and violet spots
                color: index % 3 === 0 ? "#1d4ed8" : (index % 3 === 1 ? "#4f46e5" : "#7c3aed")
                opacity: 0.08
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 64
                    blur: 1.0
                }
            }

            Component.onCompleted: {
                x = Math.random() * (rootItem.width - width);
                y = Math.random() * (rootItem.height - height);
                
                driftX.from = x;
                driftX.to = Math.random() * (rootItem.width - width);
                driftX.duration = 18000 + Math.random() * 12000;
                driftX.start();
                
                driftY.from = y;
                driftY.to = Math.random() * (rootItem.height - height);
                driftY.duration = 18000 + Math.random() * 12000;
                driftY.start();
            }

            XAnimator {
                id: driftX
                target: particle
                onFinished: {
                    from = to;
                    to = Math.random() * (rootItem.width - particle.width);
                    duration = 18000 + Math.random() * 12000;
                    start();
                }
            }

            YAnimator {
                id: driftY
                target: particle
                onFinished: {
                    from = to;
                    to = Math.random() * (rootItem.height - particle.height);
                    duration = 18000 + Math.random() * 12000;
                    start();
                }
            }
        }
    }

    // Main layout container (centered clock and input)
    Item {
        id: centerContainer
        width: 400
        height: 300
        anchors.centerIn: parent

        // Time and Date Section
        Column {
            id: timeAndDateContainer
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            
            // Decelerating slide-up and fade-in transitions
            opacity: 0.0
            y: 30

            Text {
                id: timeText
                font.family: "Noto Sans, sans-serif"
                font.pixelSize: 84
                font.weight: Font.DemiBold
                color: "white"
                anchors.horizontalCenter: parent.horizontalCenter
                
                // Add a subtle drop shadow to text for maximum legibility
                style: Text.Outline
                styleColor: "#40000000"
            }

            Text {
                id: dateText
                font.family: "Noto Sans, sans-serif"
                font.pixelSize: 20
                font.weight: Font.Normal
                color: "#e2e8f0"
                anchors.horizontalCenter: parent.horizontalCenter
                
                style: Text.Outline
                styleColor: "#40000000"
            }

            Component.onCompleted: {
                timeAndDateContainer.opacity = 1.0;
                timeAndDateContainer.y = 0;
            }

            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
        }

        // Login & Password Section (positioned lower, slides into view)
        Item {
            id: loginContainer
            width: 320
            height: 120
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: timeAndDateContainer.bottom
            anchors.topMargin: 40
            
            property int shakeOffset: 0
            x: shakeOffset

            // Transition states
            state: rootItem.passwordFieldVisible ? "visible" : "hidden"

            states: [
                State {
                    name: "hidden"
                    PropertyChanges { loginContainer.opacity: 0.0 }
                    PropertyChanges { loginContainer.y: 40 }
                    PropertyChanges { loginContainer.visible: false }
                },
                State {
                    name: "visible"
                    PropertyChanges { loginContainer.opacity: 1.0 }
                    PropertyChanges { loginContainer.y: 0 }
                    PropertyChanges { loginContainer.visible: true }
                }
            ]

            transitions: [
                Transition {
                    from: "hidden"
                    to: "visible"
                    ParallelAnimation {
                        NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.OutCubic }
                        NumberAnimation { target: loginContainer; property: "opacity"; duration: 350; easing.type: Easing.OutQuad }
                    }
                },
                Transition {
                    from: "visible"
                    to: "hidden"
                    ParallelAnimation {
                        NumberAnimation { properties: "y"; duration: 450; easing.type: Easing.InQuad }
                        NumberAnimation { target: loginContainer; property: "opacity"; duration: 250; easing.type: Easing.InQuad }
                    }
                }
            ]

            // Premium Glassmorphic input field
            Rectangle {
                id: inputFieldBg
                width: parent.width
                height: 44
                radius: 22
                
                // Translucent background
                color: "#1affffff"
                border.width: passwordInput.activeFocus ? 2 : 1
                border.color: passwordInput.activeFocus ? "#3b82f6" : "#40ffffff"

                // Glow ring on focus
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: 26
                    color: "transparent"
                    border.width: 2
                    border.color: "#203b82f6"
                    visible: passwordInput.activeFocus
                }

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 44
                    verticalAlignment: TextInput.AlignVCenter
                    
                    font.family: "Noto Sans, sans-serif"
                    font.pixelSize: 15
                    color: "white"
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    passwordMaskDelay: 600
                    selectByMouse: true
                    
                    focus: false
                    enabled: true

                    // Placeholder text
                    Text {
                        text: qsTr("Enter password...")
                        color: "#80ffffff"
                        font.family: "Noto Sans, sans-serif"
                        font.pixelSize: 15
                        visible: !passwordInput.text && !passwordInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    onAccepted: {
                        rootItem.submitPassword();
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            rootItem.hidePasswordField();
                            event.accepted = true;
                        }
                    }
                }

                // Eye/reveal button (subtle secondary action)
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: "transparent"
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: passwordInput.echoMode === TextInput.Password ? "👁" : "👁‍🗨"
                        color: mouseAreaEye.containsMouse ? "white" : "#80ffffff"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: mouseAreaEye
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            passwordInput.echoMode = passwordInput.echoMode === TextInput.Password ? 
                                                     TextInput.Normal : TextInput.Password;
                        }
                    }
                }
            }

            // Prompt Status Text
            Text {
                id: statusText
                text: qsTr("Session Locked")
                font.family: "Noto Sans, sans-serif"
                font.pixelSize: 13
                color: "#94a3b8"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: inputFieldBg.bottom
                anchors.topMargin: 12
            }

            // Pulsing sequential dots for authentication progress
            Row {
                id: loadingIndicator
                spacing: 6
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: statusText.bottom
                anchors.topMargin: 8
                visible: pam.active && !pam.responseRequired

                Repeater {
                    model: 3
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: "#3b82f6"
                        opacity: 0.3

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: loadingIndicator.visible

                            PauseAnimation { duration: index * 120 }
                            NumberAnimation { to: 1.0; duration: 250 }
                            NumberAnimation { to: 0.3; duration: 250 }
                            PauseAnimation { duration: (2 - index) * 120 }
                        }
                    }
                }
            }
        }
    }

    // Shake animation for incorrect password
    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: loginContainer; property: "shakeOffset"; to: -12; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: loginContainer; property: "shakeOffset"; to: 12; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: loginContainer; property: "shakeOffset"; to: -8; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: loginContainer; property: "shakeOffset"; to: 8; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: loginContainer; property: "shakeOffset"; to: -4; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: loginContainer; property: "shakeOffset"; to: 4; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: loginContainer; property: "shakeOffset"; to: 0; duration: 50; easing.type: Easing.InQuad }
    }

    // Helper functions for revealing/hiding password field
    function showPasswordField() {
        if (!passwordFieldVisible) {
            passwordFieldVisible = true;
            passwordInput.forceActiveFocus();
            statusText.text = qsTr("Enter password to unlock");
            statusText.color = "#94a3b8";
        }
    }

    function hidePasswordField() {
        if (passwordFieldVisible) {
            // Abort PAM if in progress
            if (pam.active) {
                pam.abort();
            }
            passwordFieldVisible = false;
            passwordInput.text = "";
            passwordInput.focus = false;
            rootItem.forceActiveFocus();
        }
    }

    // Auto-hide idle timer (returns to clockOnly mode after 15 seconds of inactivity)
    Timer {
        id: idleTimer
        interval: 15000
        running: passwordFieldVisible && !passwordInput.text && !pam.active
        repeat: false
        onTriggered: rootItem.hidePasswordField()
    }

    // Inactivity listener: reset idle timer on keypresses
    onActiveFocusChanged: {
        if (activeFocus && passwordFieldVisible) {
            idleTimer.restart();
        }
    }

    // Catch typing keys at root level to automatically show and focus password box
    Keys.onPressed: event => {
        // Reset idle timer
        idleTimer.restart();

        // Allow Ctrl+Q to exit test mode instantly
        if (!rootItem.isLocked && event.key === Qt.Key_Q && (event.modifiers & Qt.ControlModifier)) {
            rootItem.unlocked();
            event.accepted = true;
            return;
        }

        if (!passwordFieldVisible) {
            // Don't intercept function keys or navigation keys
            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Escape || 
                (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12)) {
                return;
            }
            
            showPasswordField();
            
            // If the key is a printable text key, insert it into the field
            if (event.text.length > 0 && event.text !== "\r" && event.text !== "\n" && event.text !== "\t") {
                passwordInput.text = event.text;
                passwordInput.cursorPosition = passwordInput.text.length;
                event.accepted = true;
            }
        }
    }

    // Background interaction to trigger password field
    MouseArea {
        anchors.fill: parent
        onClicked: {
            rootItem.showPasswordField();
        }
    }

    // PAM Authentication Context
    PamContext {
        id: pam
        config: "vlock" // Matches console lock service (unix password check)
        
        property string submittedPassword: ""

        onResponseRequiredChanged: {
            if (responseRequired && submittedPassword !== "") {
                respond(submittedPassword);
                submittedPassword = "";
            }
        }

        onCompleted: result => {
            submittedPassword = "";
            passwordInput.enabled = true;
            
            if (result === PamResult.Success) {
                statusText.text = qsTr("Access Granted");
                statusText.color = "#10b981"; // Success Green
                rootItem.unlocked();
            } else {
                statusText.text = qsTr("Incorrect Password");
                statusText.color = "#f43f5e"; // Rose Red
                shakeAnimation.start();
                passwordInput.text = "";
                passwordInput.forceActiveFocus();
                
                // Reset authentication context state
                pam.active = false;
            }
        }
        
        onError: error => {
            submittedPassword = "";
            passwordInput.enabled = true;
            statusText.text = qsTr("Auth Service Error");
            statusText.color = "#f43f5e";
            shakeAnimation.start();
            pam.active = false;
        }
    }

    function submitPassword() {
        let pwd = passwordInput.text;
        if (pwd === "") return;

        statusText.text = qsTr("Authenticating...");
        statusText.color = "white";
        pam.submittedPassword = pwd;
        passwordInput.enabled = false;

        if (pam.active) {
            if (pam.responseRequired) {
                pam.respond(pwd);
                pam.submittedPassword = "";
            }
        } else {
            pam.active = true;
        }
    }

    // Exit button only visible in test mode for easy developer closure
    Rectangle {
        id: exitTestButton
        visible: !rootItem.isLocked
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        width: 100
        height: 36
        radius: 18
        color: "#20ffffff"
        border.width: 1
        border.color: "#30ffffff"
        
        Text {
            text: qsTr("Exit Test")
            color: "white"
            font.family: "Noto Sans, sans-serif"
            font.pixelSize: 13
            anchors.centerIn: parent
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                rootItem.unlocked();
            }
        }
    }
}
