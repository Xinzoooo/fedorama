// SPDX-License-Identifier: MIT
import QtQuick
import QtMultimedia

Item {
    id: r
    property var slot
    readonly property bool ready: player.mediaStatus === MediaPlayer.BufferedMedia
                                  || player.mediaStatus === MediaPlayer.LoadedMedia
                                  || player.mediaStatus === MediaPlayer.BufferingMedia
                                  || player.playbackState === MediaPlayer.PlayingState
    readonly property string errorString: player.error !== MediaPlayer.NoError ? "Video-Fehler: " + player.errorString : ""
    readonly property bool shouldPlay: slot !== undefined && slot.running && visible

    VideoOutput {
        id: out
        anchors.fill: parent
        fillMode: r.slot && r.slot.p("fill", "crop") === "fit" ? VideoOutput.PreserveAspectFit
                 : r.slot && r.slot.p("fill", "crop") === "stretch" ? VideoOutput.Stretch
                 : VideoOutput.PreserveAspectCrop
    }
    MediaPlayer {
        id: player
        source: r.slot ? r.slot.sourceUrl : ""
        loops: MediaPlayer.Infinite
        videoOutput: out
        playbackRate: r.slot ? r.slot.p("speed", 1.0) : 1.0
        audioOutput: AudioOutput {
            muted: r.slot ? r.slot.p("muted", true) : true
            volume: r.slot ? r.slot.p("volume", 0.5) : 0.5
        }
        onMediaStatusChanged: if (mediaStatus === MediaPlayer.LoadedMedia && r.shouldPlay) play()
    }
    onShouldPlayChanged: shouldPlay ? player.play() : player.pause()
    Component.onCompleted: if (shouldPlay) player.play()
}
