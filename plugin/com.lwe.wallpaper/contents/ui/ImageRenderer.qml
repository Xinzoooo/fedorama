// SPDX-License-Identifier: MIT
import QtQuick

Item {
    id: r
    property var slot
    readonly property bool ready: img.status === Image.Ready
    readonly property string errorString: img.status === Image.Error ? "Bild konnte nicht geladen werden" : ""

    Image {
        id: img
        anchors.fill: parent
        source: r.slot ? r.slot.sourceUrl : ""
        asynchronous: true
        cache: false
        sourceSize: Qt.size(r.width * 1.1, r.height * 1.1)
        fillMode: r.slot && r.slot.p("fill", "crop") === "fit" ? Image.PreserveAspectFit
                 : r.slot && r.slot.p("fill", "crop") === "stretch" ? Image.Stretch
                 : r.slot && r.slot.p("fill", "crop") === "tile" ? Image.Tile
                 : Image.PreserveAspectCrop
    }
}
