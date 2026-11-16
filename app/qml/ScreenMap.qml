// Monitor layout drawn to scale. Each monitor shows the thumbnail of its wallpaper.
import QtQuick

Item {
    id: map
    property string highlightWallpaper: ""
    property string selected: ""
    signal screenClicked(string name)
    readonly property var scr: lwe.screens
    readonly property var bounds: {
        var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
        for (var i = 0; i < scr.length; i++) {
            x0 = Math.min(x0, scr[i].x); y0 = Math.min(y0, scr[i].y)
            x1 = Math.max(x1, scr[i].x + scr[i].w); y1 = Math.max(y1, scr[i].y + scr[i].h)
        }
        return scr.length ? Qt.rect(x0, y0, x1 - x0, y1 - y0) : Qt.rect(0, 0, 1, 1)
    }
    readonly property real k: Math.min(width / bounds.width, height / bounds.height)
    function thumbOf(id) {
        var all = lwe.wallpapers
        for (var i = 0; i < all.length; i++) if (all[i].id === id) return all[i].thumb
        return ""
    }
    Item {
        width: map.bounds.width * map.k; height: map.bounds.height * map.k
        anchors.centerIn: parent
        Repeater {
            model: map.scr
            Item {
                id: mon
                x: (modelData.x - map.bounds.x) * map.k + 3
                y: (modelData.y - map.bounds.y) * map.k + 3
                width: modelData.w * map.k - 6
                height: modelData.h * map.k - 6
                readonly property bool sel: map.selected === modelData.name
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: Theme.bg2
                    clip: true
                    Image {
                        anchors.fill: parent; anchors.margins: 2
                        source: map.thumbOf(modelData.wallpaper) ? "file://" + map.thumbOf(modelData.wallpaper) : ""
                        fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 400
                        opacity: 0.85
                    }
                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: ma.containsMouse ? Theme.alpha(Theme.accent, 0.3) : Qt.rgba(0, 0, 0, 0.45)
                        Behavior on color { ColorAnimation { duration: Theme.anim } }
                    }
                    Rectangle {
                        anchors.fill: parent; radius: 8; color: "transparent"
                        border.width: mon.sel || ma.containsMouse ? 1.5 : 0
                        border.color: mon.sel ? Theme.accent2 : (ma.containsMouse ? Theme.accent : Theme.border)
                    }
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.name
                        color: "#ffffff"; font.family: Theme.font; font.pixelSize: Math.max(10, Math.min(13, parent.height / 4))
                        elide: Text.ElideRight
                    }
                }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: map.screenClicked(modelData.name) }
            }
        }
    }
}
