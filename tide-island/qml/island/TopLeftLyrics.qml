import QtQuick
import IslandBackend
import "../common"

Item {
    id: root

    property string lyricText: ""
    property bool musicPlaying: false
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property real maxAllowedWidth: 300
    property string islandState: "normal"
    property bool transitionActive: false

    onIslandStateChanged: {
        transitionActive = true;
        transitionTimer.restart();
    }

    Timer {
        id: transitionTimer
        interval: 500
        repeat: false
        onTriggered: {
            transitionActive = false;
        }
    }

    implicitHeight: 32
    height: implicitHeight

    // Smooth visibility animation
    opacity: root.musicPlaying && root.lyricText !== "" && root.lyricText !== "No music playing" && root.lyricText !== "no lyrics" ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing.type: Easing.InOutQuad
        }
    }

    // Determine the width based on the current text length and bounds
    implicitWidth: {
        if (!root.musicPlaying || root.lyricText === "" || root.lyricText === "No music playing" || root.lyricText === "no lyrics") return 0;
        // Icon (musicIcon.implicitWidth) + spacing (8px) + text width + padding (24px)
        const contentWidth = musicIcon.implicitWidth + 8 + lyricMetrics.advanceWidth + 24;
        return Math.max(80, Math.min(root.maxAllowedWidth, contentWidth));
    }
    width: implicitWidth
    Behavior on width {
        enabled: !root.transitionActive && (root.islandState === "normal" || root.islandState === "lyrics")
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutQuint
        }
    }

    Rectangle {
        anchors.fill: parent
        color: StyleTokens.black
        radius: height / 2
        border.width: 1
        border.color: StyleTokens.overviewInnerBorder
    }

    // Text metrics for computing the layout width dynamically
    TextMetrics {
        id: lyricMetrics
        font.family: root.textFontFamily
        font.pixelSize: 14
        font.weight: Font.DemiBold
        text: root.activeLyricText !== "" ? root.activeLyricText : root.lyricText
    }

    // Manage lyric change transitions
    property string activeLyricText: lyricText
    property string previousLyricText: ""
    property real lyricChangeProgress: 1.0

    onLyricTextChanged: {
        if (lyricText === activeLyricText) return;

        if (activeLyricText === "") {
            lyricChangeAnimation.stop();
            previousLyricText = "";
            activeLyricText = lyricText;
            lyricChangeProgress = 1.0;
            return;
        }

        previousLyricText = activeLyricText;
        activeLyricText = lyricText;
        lyricChangeProgress = 0.0;
        lyricChangeAnimation.restart();
    }

    SequentialAnimation {
        id: lyricChangeAnimation

        NumberAnimation {
            target: root
            property: "lyricChangeProgress"
            from: 0.0
            to: 1.0
            duration: 260
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: root.previousLyricText = ""
        }
    }

    Row {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        // Music icon
        Text {
            id: musicIcon
            text: "🎧" // 🎧 headphones
            font.pixelSize: 13
            color: "#a0a0a0"
            anchors.verticalCenter: parent.verticalCenter
        }

        // Clip container for lyrics text sliding animation
        Item {
            id: textContainer
            height: parent.height
            width: Math.max(0, parent.width - musicIcon.width - parent.spacing)
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Text {
                visible: root.previousLyricText !== ""
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -12 * root.lyricChangeProgress
                text: root.previousLyricText
                color: "white"
                opacity: 1.0 - root.lyricChangeProgress
                font.pixelSize: 14
                font.family: root.textFontFamily
                font.weight: Font.DemiBold
                font.letterSpacing: -0.15
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }

            Text {
                visible: root.activeLyricText !== ""
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: root.previousLyricText !== "" ? 12 * (1.0 - root.lyricChangeProgress) : 0
                text: root.activeLyricText
                color: "white"
                opacity: root.previousLyricText !== "" ? root.lyricChangeProgress : 1.0
                font.pixelSize: 14
                font.family: root.textFontFamily
                font.weight: Font.DemiBold
                font.letterSpacing: -0.15
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }
        }
    }
}
