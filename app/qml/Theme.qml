// Look & feel, read from themes/*.json via the backend (lwe.theme).
pragma Singleton
import QtQuick

QtObject {
    readonly property var t: lwe.theme
    readonly property var c: t.colors || ({})
    function col(name, fb) { return c[name] !== undefined ? c[name] : fb }
    function alpha(color, a) { var q = Qt.color(color); return Qt.rgba(q.r, q.g, q.b, a) }

    readonly property color bg: col("bg", "#07070f")
    readonly property color bg2: col("bg2", "#141030")
    readonly property color text: col("text", "#f1f2ff")
    readonly property color textDim: col("textDim", "#9ea3c8")
    readonly property color accent: col("accent", "#8b5cff")
    readonly property color accent2: col("accent2", "#22e6ff")
    readonly property color accent3: col("accent3", "#ff3fb0")
    readonly property color danger: col("danger", "#ff5a7a")
    readonly property color ok: col("ok", "#3df5a7")
    readonly property color glass: alpha(col("glass", "#ffffff"), t.glassOpacity !== undefined ? t.glassOpacity : 0.07)
    readonly property color glassHover: alpha(col("glass", "#ffffff"), t.glassOpacityHover !== undefined ? t.glassOpacityHover : 0.12)
    readonly property color border: alpha(col("border", "#ffffff"), t.borderOpacity !== undefined ? t.borderOpacity : 0.13)
    readonly property real backdropBlur: t.backdropBlur !== undefined ? t.backdropBlur : 64
    readonly property real backdropDim: t.backdropDim !== undefined ? t.backdropDim : 0.6
    readonly property real glow: t.glow !== undefined ? t.glow : 0.9
    readonly property int radius: t.radius || 18
    readonly property int radiusSmall: t.radiusSmall || 11
    readonly property int anim: t.animationMs || 220
    readonly property int tileWidth: t.tileWidth || 290
    readonly property int fontSize: t.fontSize || 14
    readonly property string font: Qt.fontFamilies().indexOf(t.fontFamily || "") >= 0 ? t.fontFamily : (t.fontFallback || "Noto Sans")
}
