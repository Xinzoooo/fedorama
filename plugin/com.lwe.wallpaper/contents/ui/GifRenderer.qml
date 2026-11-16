// SPDX-License-Identifier: MIT
import QtQuick

Item {
    id: r
    property var slot
    readonly property bool ready: img.status === Image.Ready
    readonly property string errorString: img.status === Image.Error ? "GIF konnte nicht geladen werden" : ""

    AnimatedImage {
        id: img
        anchors.fill: parent
        source: r.slot ? r.slot.sourceUrl : ""
        asynchronous: true
        cache: false
        smooth: r.slot ? r.slot.p("smooth", true) : true
        playing: r.slot !== undefined && r.slot.running && r.visible
        speed: r.slot ? r.slot.p("speed", 1.0) : 1.0
        fillMode: r.slot && r.slot.p("fill", "crop") === "fit" ? Image.PreserveAspectFit
                 : r.slot && r.slot.p("fill", "crop") === "stretch" ? Image.Stretch
                 : r.slot && r.slot.p("fill", "crop") === "tile" ? Image.Tile
                 : Image.PreserveAspectCrop
    }
}
