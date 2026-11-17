// Particle wallpapers. The whole preset arrives in slot.params (JSON), so
// plasmashell never has to read files itself.
// SPDX-License-Identifier: MIT
import QtQuick
import QtQuick.Particles

Item {
    id: r
    property var slot
    readonly property bool ready: slot !== undefined
    readonly property string errorString: ""

    function p(n, f) { return slot ? slot.p(n, f) : f }
    readonly property var bg: p("background", ["#05060f", "#0d1330"])
    readonly property real speedMul: p("speed", 1.0)
    readonly property real bass: slot ? slot.audio.x : 0
    readonly property real audioGain: p("audioReact", 0.0)
    readonly property real particleMul: slot ? slot.particleMul : 1.0

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: r.bg[0] }
            GradientStop { position: 1.0; color: r.bg.length > 1 ? r.bg[1] : r.bg[0] }
        }
    }
    // optional soft glow blob that follows the cursor
    Image {
        visible: r.p("cursorGlow", false)
        source: "../images/glow.png"
        width: r.width * 0.5; height: width
        x: (r.slot ? r.slot.mouse.x : 0.5) * r.width - width / 2
        y: (r.slot ? r.slot.mouse.y : 0.5) * r.height - height / 2
        opacity: 0.18
        smooth: true
    }

    ParticleSystem {
        id: sys
        anchors.fill: parent
        running: r.slot !== undefined
        paused: !(r.slot && r.slot.running && r.visible)
    }

    ImageParticle {
        system: sys
        source: r.p("sprite", "glow") === "dot" ? "../images/dot.png" : "../images/glow.png"
        color: r.p("color", "#9fd8ff")
        colorVariation: r.p("colorVariation", 0.2)
        alpha: r.p("alpha", 0.8)
        alphaVariation: r.p("alphaVariation", 0.3)
        rotationVariation: r.p("rotationVariation", 0)
        entryEffect: ImageParticle.Fade
    }

    Emitter {
        id: emitter
        system: sys
        readonly property string mode: r.p("emitter", "area")
        x: 0
        y: mode === "top" ? -r.height * 0.05 : mode === "bottom" ? r.height * 1.02 : 0
        width: r.width
        height: (mode === "top" || mode === "bottom") ? 2 : r.height
        emitRate: r.p("emitRate", 40) * r.particleMul * (1 + r.audioGain * r.bass * 2)
        lifeSpan: r.p("lifeSpan", 8000) / r.speedMul
        lifeSpanVariation: r.p("lifeSpanVariation", 2000) / r.speedMul
        maximumEmitted: Math.round(r.p("maxParticles", 1500) * r.particleMul)
        size: r.p("size", 12) * (1 + r.audioGain * r.bass * 0.8)
        sizeVariation: r.p("sizeVariation", 6)
        endSize: r.p("endSize", -1)
        velocity: AngleDirection {
            angle: r.p("angle", 270)
            angleVariation: r.p("angleVariation", 30)
            magnitude: r.p("velocity", 20) * r.speedMul
            magnitudeVariation: r.p("velocityVariation", 10) * r.speedMul
        }
        acceleration: PointDirection {
            x: r.p("wind", 0) * r.speedMul
            y: r.p("gravity", 0) * r.speedMul
        }
    }

    // fills the whole screen once at start, so the wallpaper does not begin empty
    Emitter {
        system: sys
        anchors.fill: parent
        emitRate: 0
        lifeSpan: emitter.lifeSpan
        lifeSpanVariation: emitter.lifeSpanVariation
        size: emitter.size
        sizeVariation: emitter.sizeVariation
        endSize: emitter.endSize
        velocity: emitter.velocity
        acceleration: emitter.acceleration
        Component.onCompleted: burst(Math.min(emitter.maximumEmitted, Math.round(r.p("prefill", 0) * r.particleMul)))
    }

    Wander {
        system: sys
        enabled: r.p("wander", 0) > 0
        xVariance: r.p("wander", 0)
        yVariance: r.p("wander", 0) * 0.6
        pace: r.p("wanderPace", 60)
    }

    // cursor interaction: pull or push particles near the pointer
    Attractor {
        system: sys
        readonly property string mode: r.p("mouse", "repel")
        enabled: mode !== "none" && r.slot !== undefined
        width: r.width * 0.25; height: width
        x: (r.slot ? r.slot.mouse.x : 0.5) * r.width - width / 2
        y: (r.slot ? r.slot.mouse.y : 0.5) * r.height - height / 2
        pointX: width / 2; pointY: height / 2
        strength: (mode === "attract" ? 1 : -1) * r.p("mouseForce", 60)
        affectedParameter: Attractor.Velocity
        proportionalToDistance: Attractor.InverseLinear
    }
}
