import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import IslandBackend
import "../common"

Item {
    id: root

    property string lyricText: ""
    property bool musicPlaying: false
    property string artUrl: ""
    property var cavaLevels: [0, 0, 0, 0, 0, 0, 0, 0]
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property real maxAllowedWidth: 350
    property string islandState: "normal"
    property bool transitionActive: false

    readonly property bool showCava: lyricsCfgData.showTopRightCava !== undefined ? lyricsCfgData.showTopRightCava : true

    function formatArtUrl(rawUrl) {
        if (!rawUrl) return "";
        let url = String(rawUrl).trim();
        if (url === "") return "";
        if (url.indexOf("open.spotify.com/image/") !== -1) {
            url = url.replace("open.spotify.com/image/", "i.scdn.co/image/");
        }
        if (url.indexOf("spotify:image:") === 0) {
            url = "https://i.scdn.co/image/" + url.substring(14);
        }
        if (url.indexOf("/") === 0 && url.indexOf("file://") !== 0) {
            url = "file://" + url;
        }
        return url;
    }

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
        const cavaW = (root.showCava && root.musicPlaying) ? visualizer.implicitWidth + 8 : 0;
        const contentWidth = 20 + 8 + lyricMetrics.advanceWidth + cavaW + 28;
        return Math.max(90, Math.min(root.maxAllowedWidth, contentWidth));
    }
    width: implicitWidth
    Behavior on width {
        enabled: !root.transitionActive && (root.islandState === "normal" || root.islandState === "lyrics")
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutQuint
        }
    }

    FileView {
        id: lyricsCfgWatcher
        path: (Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")) + "/.config/tide-island/userconfig.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: lyricsCfgWatcher.reload()
    }

    readonly property var lyricsCfgData: {
        try {
            return lyricsCfgWatcher.text() ? JSON.parse(lyricsCfgWatcher.text()) : {};
        } catch (e) {
            return {};
        }
    }

    readonly property string styleChoice: lyricsCfgData.topLeftPillStyle || lyricsCfgData.islandStyle || "pill"
    readonly property bool isNotchStyle: styleChoice === "notch"

    Rectangle {
        id: lyricsBgRect
        anchors.fill: parent
        color: StyleTokens.black
        radius: height / 2
        border.width: 1
        border.color: StyleTokens.overviewInnerBorder
    }

    // Top Notch Extension (Square top corners attached flush to top screen edge in Notch mode)
    Rectangle {
        visible: root.isNotchStyle
        anchors.top: lyricsBgRect.top
        anchors.left: lyricsBgRect.left
        anchors.right: lyricsBgRect.right
        height: Math.min(16, lyricsBgRect.height / 2)
        color: lyricsBgRect.color
        z: -1

        Behavior on height {
            NumberAnimation { duration: 380; easing.type: Easing.OutQuint }
        }
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
        }
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

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        // Circular Media Album Art Thumbnail / Fallback Icon
        Rectangle {
            id: musicArtBox
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            radius: 10
            color: "#20ffffff"
            clip: true
            layer.enabled: true
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: albumArtImg
                anchors.fill: parent
                source: root.formatArtUrl(root.artUrl)
                fillMode: Image.PreserveAspectCrop
                visible: source.toString() !== "" && status !== Image.Error
                asynchronous: true
                cache: true

                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: artMask
                }
            }

            Rectangle {
                id: artMask
                width: 20
                height: 20
                radius: 10
                visible: false
                layer.enabled: true
            }

            Text {
                anchors.centerIn: parent
                text: "🎧"
                font.pixelSize: 11
                color: "#a0a0a0"
                visible: !albumArtImg.visible || albumArtImg.status === Image.Error
            }
        }

        // Clip container for lyrics text sliding animation
        Item {
            id: textContainer
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height
            clip: true
            Layout.alignment: Qt.AlignVCenter

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

        // Compact Cava audio visualizer on far right of left pill
        SwipeCavaBars {
            id: visualizer
            levels: root.cavaLevels
            barCount: 5
            barWidth: 3
            barSpacing: 2
            Layout.alignment: Qt.AlignVCenter
            visible: root.showCava && root.musicPlaying && width > 0
            opacity: (root.showCava && root.musicPlaying) ? 1 : 0
            clip: true

            width: (root.showCava && root.musicPlaying) ? implicitWidth : 0
            Behavior on width {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutQuint
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
