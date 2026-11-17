// One wallpaper layer. main.qml crossfades between two of these.
// SPDX-License-Identifier: MIT
import QtQuick

Item {
    id: slot
    property var host                      // the WallpaperItem (running, fps, mouse, audio, spectrum)
    property string kind: ""
    property string source: ""
    property string paramsJson: "{}"
    readonly property var params: {
        try { return JSON.parse(paramsJson) } catch (e) { return {} }
    }
    readonly property string dbg: loader.item && loader.item.dbg ? loader.item.dbg : ""
    readonly property bool ready: loader.status === Loader.Ready && loader.item !== null && loader.item.ready === true
    opacity: 0

    function p(name, fallback) {
        var v = params[name]
        return (v === undefined || v === null) ? fallback : v
    }

    readonly property url sourceUrl: source === "" ? "" : (source.indexOf("://") > 0 ? source : "file://" + source)
    readonly property bool running: host ? host.running : false
    readonly property int fps: host ? host.fps : 30
    readonly property vector2d mouse: host ? host.mouse : Qt.vector2d(0.5, 0.5)
    readonly property vector4d audio: host ? host.audio : Qt.vector4d(0, 0, 0, 0)
    readonly property var spectrum: host ? host.spectrum : []
    readonly property real renderMul: host ? host.renderMul : 1.0
    readonly property real renderMax: host ? host.renderMax : 1.0
    readonly property real particleMul: host ? host.particleMul : 1.0

    // Parallax: media layers are zoomed slightly and shifted against the cursor.
    readonly property real parallax: p("parallax", kind === "shader" ? 0 : 0.6)
    readonly property real audioPulse: p("audioPulse", 0.0)
    Item {
        id: stage
        anchors.fill: parent
        readonly property real zoom: 1 + 0.06 * slot.parallax + slot.audioPulse * 0.04 * slot.audio.x
        scale: zoom
        transform: Translate {
            x: -(slot.mouse.x - 0.5) * slot.width * 0.05 * slot.parallax
            y: -(slot.mouse.y - 0.5) * slot.height * 0.05 * slot.parallax
        }
        Loader {
            id: loader
            anchors.fill: parent
            asynchronous: false
        }
    }
    // The renderer gets `slot` as an initial property, so e.g. a ShaderEffect never
    // starts with an empty fragmentShader (which leaves it in an error state).
    function reload() {
        var file = ({ shader: "ShaderRenderer.qml", video: "VideoRenderer.qml", gif: "GifRenderer.qml",
                      image: "ImageRenderer.qml", particles: "ParticleRenderer.qml" })[kind] || ""
        loader.source = ""
        if (file !== "" && source !== "" || kind === "particles") loader.setSource(file, { slot: slot })
    }
    onKindChanged: reload()
    onSourceChanged: if (kind !== "particles") reload()

    Text {
        visible: loader.item && loader.item.errorString ? true : false
        text: loader.item ? ("Fedorama: " + loader.item.errorString) : ""
        color: "#ff6b9a"; font.pixelSize: 16
        anchors { left: parent.left; bottom: parent.bottom; margins: 24 }
    }
}
