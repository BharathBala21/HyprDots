import QtQuick
import Quickshell.Services.Mpris
import IslandBackend

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool expanded: false
    property string clientId: "island-mpris-default"
    property string registeredLyricsClientId: ""

    property string lastActivePlayerDbusName: ""
    property var playersList: Mpris.players.values !== undefined ? Mpris.players.values : Mpris.players
    property var activePlayer: resolveActivePlayer()

    readonly property string lyricsLookupTitle: activePlayer ? (activePlayer.trackTitle || activePlayer.title || "") : ""
    readonly property string lyricsLookupArtist: {
        if (!activePlayer) return "";
        let artist = activePlayer.artist;
        if (!artist && activePlayer.metadata) artist = activePlayer.metadata["xesam:artist"];
        if (artist) return Array.isArray(artist) ? artist.join(", ") : String(artist);
        return "";
    }
    readonly property string currentTrack: activePlayer ? (lyricsLookupTitle !== "" ? lyricsLookupTitle : "Unknown") : ""
    readonly property string currentArtist: {
        if (!activePlayer) return "";
        if (lyricsLookupArtist !== "") return lyricsLookupArtist;
        return "Unknown";
    }
    function extractYoutubeThumbnail(urlOrTitle) {
        if (!urlOrTitle) return "";
        const str = String(urlOrTitle);
        const match = str.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/);
        if (match && match[1]) {
            return "https://i.ytimg.com/vi/" + match[1] + "/hqdefault.jpg";
        }
        return "";
    }

    readonly property string currentArtUrl: {
        if (!activePlayer) return "";

        let url = activePlayer.trackArtUrl || activePlayer.artUrl || "";
        if (!url && activePlayer.metadata) {
            url = activePlayer.metadata["mpris:artUrl"]
               || activePlayer.metadata["artUrl"]
               || activePlayer.metadata["xesam:userIcon"]
               || "";
        }

        // Check if browser sent YouTube URL in metadata xesam:url or track url
        let webUrl = activePlayer.metadata ? (activePlayer.metadata["xesam:url"] || "") : "";
        if (!webUrl && activePlayer.url) webUrl = activePlayer.url;

        let ytThumb = extractYoutubeThumbnail(webUrl);
        if (ytThumb !== "") return ytThumb;

        if (!url) return "";
        url = String(url).trim();

        ytThumb = extractYoutubeThumbnail(url);
        if (ytThumb !== "") return ytThumb;

        if (url.indexOf("open.spotify.com/image/") !== -1) {
            url = url.replace("open.spotify.com/image/", "i.scdn.co/image/");
        }
        if (url.indexOf("spotify:image:") === 0) {
            url = "https://i.scdn.co/image/" + url.substring(14);
        }
        if (url.indexOf("i.ytimg.com") !== -1) {
            url = url.replace("/vi_webp/", "/vi/");
            url = url.replace("maxresdefault.jpg", "hqdefault.jpg")
                     .replace("maxresdefault.webp", "hqdefault.jpg")
                     .replace("hqdefault.webp", "hqdefault.jpg");
        }
        if (url.indexOf("/") === 0 && url.indexOf("file://") !== 0) {
            url = "file://" + url;
        }
        return url;
    }

    Connections {
        target: root.activePlayer
        ignoreUnknownSignals: true
        function onMetadataChanged() {
            root.activePlayerChanged();
        }
        function onTrackArtUrlChanged() {
            root.activePlayerChanged();
        }
        function onPlaybackStateChanged() {
            root.activePlayer = root.resolveActivePlayer();
        }
    }
    readonly property string inlineLyricsRaw: {
        if (!activePlayer || !activePlayer.metadata) return "";
        let inlineLyrics = activePlayer.metadata["xesam:asText"];
        if (!inlineLyrics) inlineLyrics = activePlayer.metadata["xesam:comment"];
        if (Array.isArray(inlineLyrics)) return inlineLyrics.join("\n");
        return inlineLyrics ? String(inlineLyrics) : "";
    }
    readonly property string displayText: lyricsBridge.displayText

    property string plainLyric: ""
    property string _lastParsedInlineLyricsRaw: ""
    property real trackProgress: 0
    property string timePlayed: "0:00"
    property string timeTotal: "0:00"

    onActivePlayerChanged: {
        syncLyricsBackend();
        Qt.callLater(function() {
            const nextDbusName = root.activePlayer && root.activePlayer.dbusName
                ? root.activePlayer.dbusName
                : "";
            if (root.lastActivePlayerDbusName !== nextDbusName)
                root.lastActivePlayerDbusName = nextDbusName;
        });
    }

    onInlineLyricsRawChanged: updatePlainLyric()
    onClientIdChanged: syncLyricsBackend()

    Component.onCompleted: {
        updatePlainLyric();
        syncLyricsBackend();
    }
    Component.onDestruction: {
        if (registeredLyricsClientId !== "")
            SysBackend.setLyricsClientActive(registeredLyricsClientId, false);
    }

    function syncLyricsBackend() {
        const nextClientId = String(clientId || "island-mpris-default");
        if (registeredLyricsClientId !== "" && registeredLyricsClientId !== nextClientId)
            SysBackend.setLyricsClientActive(registeredLyricsClientId, false);

        registeredLyricsClientId = nextClientId;
        SysBackend.setLyricsClientActive(registeredLyricsClientId, activePlayer !== null);
    }

    function formatTime(value) {
        const numberValue = Number(value);
        if (isNaN(numberValue) || numberValue <= 0) return "0:00";

        let totalSeconds = 0;
        if (numberValue < 10000) totalSeconds = Math.floor(numberValue);
        else if (numberValue < 100000000) totalSeconds = Math.floor(numberValue / 1000);
        else totalSeconds = Math.floor(numberValue / 1000000);

        const minutes = Math.floor(totalSeconds / 60);
        const seconds = Math.floor(totalSeconds % 60);
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    function cleanLyricLineText(text) {
        return String(text === undefined || text === null ? "" : text)
            .replace(/\s+/g, " ")
            .trim();
    }

    function extractFirstPlainLyric(rawLyrics) {
        const source = String(rawLyrics === undefined || rawLyrics === null ? "" : rawLyrics);
        let lineStart = 0;

        for (let index = 0; index <= source.length; index++) {
            if (index < source.length && source[index] !== "\n" && source[index] !== "\r")
                continue;

            const row = source.slice(lineStart, index).trim();
            if (row !== "" && !/^\[[a-zA-Z]+:.*\]$/.test(row)) {
                const lineText = cleanLyricLineText(row.replace(/\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/g, ""));
                if (lineText !== "")
                    return lineText;
            }

            if (source[index] === "\r" && source[index + 1] === "\n")
                index++;

            lineStart = index + 1;
        }

        return "";
    }

    function updatePlainLyric() {
        if (inlineLyricsRaw === _lastParsedInlineLyricsRaw)
            return;

        _lastParsedInlineLyricsRaw = inlineLyricsRaw;
        plainLyric = extractFirstPlainLyric(inlineLyricsRaw);
    }

    function playerHasTrackInfo(player) {
        if (!player) return false;
        if ((player.trackTitle || player.title || "") !== "") return true;
        if (!player.metadata) return false;
        return Boolean(
            player.metadata["xesam:title"]
            || player.metadata["mpris:trackid"]
            || player.metadata["xesam:url"]
        );
    }

    function findPlayerByDbusName(dbusName) {
        if (!playersList || !dbusName) return null;
        for (let index = 0; index < playersList.length; index++) {
            if (playersList[index].dbusName === dbusName)
                return playersList[index];
        }
        return null;
    }

    function isMusicPlayerApp(player) {
        if (!player) return false;
        const identity = (player.identity || "").toLowerCase();
        const dbusName = (player.dbusName || "").toLowerCase();
        const entry = (player.entry || "").toLowerCase();
        const fullName = identity + " " + dbusName + " " + entry;

        // Exclude generic web browsers unless it's explicitly YouTube Music (music.youtube.com)
        const isGenericBrowser = dbusName.indexOf("firefox") !== -1 ||
                                 dbusName.indexOf("chrome") !== -1 ||
                                 dbusName.indexOf("chromium") !== -1 ||
                                 dbusName.indexOf("brave") !== -1 ||
                                 dbusName.indexOf("vivaldi") !== -1 ||
                                 dbusName.indexOf("edge") !== -1;

        if (isGenericBrowser) {
            const webUrl = (player.metadata ? (player.metadata["xesam:url"] || "") : "").toLowerCase();
            return webUrl.indexOf("music.youtube.com") !== -1 || fullName.indexOf("music.youtube.com") !== -1;
        }

        return fullName.indexOf("spotify") !== -1 ||
               fullName.indexOf("music") !== -1 ||
               fullName.indexOf("rhythmbox") !== -1 ||
               fullName.indexOf("amberol") !== -1 ||
               fullName.indexOf("audacious") !== -1 ||
               fullName.indexOf("clementine") !== -1 ||
               fullName.indexOf("lollypop") !== -1 ||
               fullName.indexOf("feishin") !== -1 ||
               fullName.indexOf("cmus") !== -1 ||
               fullName.indexOf("mpd") !== -1 ||
               fullName.indexOf("sayonara") !== -1 ||
               fullName.indexOf("tidal") !== -1 ||
               fullName.indexOf("apple") !== -1 ||
               fullName.indexOf("vlc") !== -1;
    }

    function resolveActivePlayer() {
        if (!playersList || playersList.length === 0) return null;

        // 1. Music Player Apps currently PLAYING (Spotify, YouTube Music, Rhythmbox, etc.)
        for (let index = 0; index < playersList.length; index++) {
            let p = playersList[index];
            if (p.playbackState === MprisPlaybackState.Playing && isMusicPlayerApp(p))
                return p;
        }

        // 2. Remembered last active music player
        const rememberedPlayer = findPlayerByDbusName(lastActivePlayerDbusName);
        if (rememberedPlayer && isMusicPlayerApp(rememberedPlayer) && (playerHasTrackInfo(rememberedPlayer) || rememberedPlayer.canControl))
            return rememberedPlayer;

        // 3. Music Player Apps currently PAUSED
        for (let index = 0; index < playersList.length; index++) {
            let p = playersList[index];
            if (p.playbackState === MprisPlaybackState.Paused && isMusicPlayerApp(p) && playerHasTrackInfo(p))
                return p;
        }

        // 4. Any controllable Music Player App
        for (let index = 0; index < playersList.length; index++) {
            let p = playersList[index];
            if (p.canControl && isMusicPlayerApp(p))
                return p;
        }

        return null;
    }

    QtObject {
        id: lyricsBridge

        readonly property string title: root.currentTrack
        readonly property string currentLyric: SysBackend && SysBackend.lyricsCurrentLyric !== undefined
            ? SysBackend.lyricsCurrentLyric
            : ""
        readonly property bool isSynced: SysBackend && SysBackend.lyricsIsSynced !== undefined
            ? SysBackend.lyricsIsSynced
            : false
        readonly property string backendStatus: SysBackend && SysBackend.lyricsBackendStatus !== undefined
            ? SysBackend.lyricsBackendStatus
            : "idle"
        readonly property string plainLyric: root.plainLyric
        readonly property string displayText: {
            if (title === "") return "No music playing";
            if (backendStatus === "missing" || backendStatus === "error") return "no lyrics";
            if (isSynced && currentLyric !== "") return currentLyric;
            if (plainLyric !== "") return plainLyric;
            return title;
        }
    }

    Timer {
        id: progressPoller

        interval: 500
        running: root.activePlayer !== null && root.expanded
        repeat: true

        onTriggered: {
            let player = root.activePlayer;
            if (!player) return;

            const currentPosition = Number(player.position) || 0;
            let totalLength = Number(player.length) || 0;
            if (totalLength <= 0 && player.metadata && player.metadata["mpris:length"])
                totalLength = Number(player.metadata["mpris:length"]);

            if (totalLength > 0) {
                root.trackProgress = currentPosition / totalLength;
                root.timePlayed = root.formatTime(currentPosition);
                root.timeTotal = root.formatTime(totalLength);
            } else {
                root.trackProgress = 0;
                root.timePlayed = root.formatTime(currentPosition);
                root.timeTotal = "0:00";
            }
        }
    }
}
