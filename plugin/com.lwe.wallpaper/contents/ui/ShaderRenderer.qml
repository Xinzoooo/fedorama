// SPDX-License-Identifier: MIT
import QtQuick

Item {
    id: r
    property var slot
    // plasmashell only compiles a ShaderEffect once it is really drawn, so a nearly
    // transparent incoming layer may stay "Uncompiled": allow a short grace period.
    property bool graceOver: false
    Timer { interval: 120; running: true; onTriggered: r.graceOver = true }
    readonly property bool ready: effect.status === ShaderEffect.Compiled
                                  || (graceOver && effect.status !== ShaderEffect.Error && String(effect.fragmentShader) !== "")
    readonly property string dbg: "st=" + effect.status + " src=" + effect.fragmentShader + " " + effect.log
    readonly property string errorString: effect.status === ShaderEffect.Error ? "Shader-Fehler: " + effect.log : ""

    // wallpaper's own renderScale * preset multiplier, capped by the preset (> 1 = supersampling)
    readonly property real renderScale: slot ? Math.max(0.25, Math.min(Math.min(2.0, slot.renderMax),
                                                                      slot.p("renderScale", 1.0) * slot.renderMul)) : 1.0
    readonly property real speed: slot ? slot.p("speed", 1.0) : 1.0

    Image {
        id: noise
        source: "../images/noise.png"
        visible: false
        smooth: false
    }
    ShaderEffectSource {
        id: noiseSrc
        sourceItem: noise
        wrapMode: ShaderEffectSource.Repeat
        hideSource: true
        visible: false
        live: false
        smooth: true
    }

    Item {
        id: box
        width: Math.ceil(r.width * r.renderScale)
        height: Math.ceil(r.height * r.renderScale)
        transformOrigin: Item.TopLeft
        scale: 1 / r.renderScale
        layer.enabled: Math.abs(r.renderScale - 1.0) > 0.001
        layer.smooth: true
        layer.mipmap: r.renderScale > 1.001     // cleaner downsampling when supersampling

        ShaderEffect {
            id: effect
            anchors.fill: parent
            blending: false
            fragmentShader: r.slot ? r.slot.sourceUrl : ""

            property real iTime: r.slot ? r.slot.p("timeOffset", 0) : 0
            property real iTimeDelta: 0
            property real lweFrame: 0
            property vector3d iResolution: Qt.vector3d(width, height, 1)
            property vector4d iMouse: r.slot ? Qt.vector4d(r.slot.mouse.x * width, (1 - r.slot.mouse.y) * height, 0, 0) : Qt.vector4d(0, 0, 0, 0)
            property vector2d iMouseUV: r.slot ? Qt.vector2d(r.slot.mouse.x, 1 - r.slot.mouse.y) : Qt.vector2d(0.5, 0.5)
            property vector4d iDate: Qt.vector4d(0, 0, 0, 0)
            property vector4d iAudio: r.slot ? r.slot.audio : Qt.vector4d(0, 0, 0, 0)
            property vector4d iSpectrumA: r.band(0)
            property vector4d iSpectrumB: r.band(4)
            property vector4d iSpectrumC: r.band(8)
            property vector4d iSpectrumD: r.band(12)
            property real uBrightness: r.slot ? r.slot.p("brightness", 1.0) : 1.0
            property real uHue: r.slot ? r.slot.p("hue", 0.0) * Math.PI / 180 : 0.0
            property real uSaturation: r.slot ? r.slot.p("saturation", 1.0) : 1.0
            property variant iChannel0: noiseSrc
        }
    }

    function band(i) {
        var s = slot ? slot.spectrum : null
        if (!s || s.length < 16) return Qt.vector4d(0, 0, 0, 0)
        return Qt.vector4d(s[i], s[i + 1], s[i + 2], s[i + 3])
    }

    Timer {
        id: clock
        property double last: 0
        interval: Math.max(4, Math.round(1000 / (r.slot ? r.slot.fps : 30)))
        repeat: true
        running: r.slot !== undefined && r.slot.running && r.ready && r.visible && effect.status !== ShaderEffect.Error
        onRunningChanged: last = 0
        onTriggered: {
            var now = Date.now()
            var dt = last > 0 ? Math.min(0.1, (now - last) / 1000) : 0
            last = now
            dt *= r.speed
            var t = effect.iTime + dt
            if (t > 14400) t -= 14400          // keep float precision sane
            effect.iTime = t
            effect.iTimeDelta = dt
            effect.lweFrame += 1
            if (effect.lweFrame % 30 === 1) {
                var d = new Date()
                effect.iDate = Qt.vector4d(d.getFullYear(), d.getMonth(), d.getDate(),
                                           d.getHours() * 3600 + d.getMinutes() * 60 + d.getSeconds())
            }
        }
    }
}
