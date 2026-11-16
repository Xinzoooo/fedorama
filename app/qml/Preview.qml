// Live preview using the very same renderer files as the desktop plugin.
import QtQuick

Item {
    id: p
    property var wp: null                 // wallpaper dict from lwe.wallpapers
    property bool running: true
    property int fps: 30
    property var paramsOverride: ({})
    property vector2d mouse: Qt.vector2d(0.5, 0.5)
    readonly property bool ready: loader.item ? loader.item.ready : false
    clip: true

    QtObject {
        id: host
        property bool running: p.running
        property int fps: p.fps
        property vector2d mouse: p.mouse
        property vector4d audio: Qt.vector4d(0, 0, 0, 0)
        property var spectrum: []
    }
    function paramsJson() {
        if (!wp) return "{}"
        var o = {}
        var src = wp.params || {}
        for (var k in src) o[k] = src[k]
        for (var j in paramsOverride) o[j] = paramsOverride[j]
        return JSON.stringify(o)
    }
    Loader {
        id: loader
        anchors.fill: parent
        source: lwe.pluginUi + "/Slot.qml"
        onLoaded: { item.host = host; item.opacity = 1 }
    }
    Binding { target: loader.item; property: "paramsJson"; value: p.paramsJson(); when: loader.item !== null }
    Binding { target: loader.item; property: "source"; value: p.wp ? p.wp.source : ""; when: loader.item !== null }
    Binding { target: loader.item; property: "kind"; value: p.wp ? p.wp.type : ""; when: loader.item !== null }
}
