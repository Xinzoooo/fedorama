// Fixed look: black/white, colour comes only from the wallpapers.
pragma Singleton
import QtQuick

QtObject {
    function alpha(color, a) { var q = Qt.color(color); return Qt.rgba(q.r, q.g, q.b, a) }

    readonly property color bg: "#000000"
    readonly property color surface: "#0b0b0b"
    readonly property color glass: Qt.rgba(0.043, 0.043, 0.043, 0.82)
    readonly property color line: Qt.rgba(1, 1, 1, 0.11)
    readonly property color text: "#ffffff"
    readonly property color textDim: "#8a8a8a"
    readonly property color textSoft: Qt.rgba(1, 1, 1, 0.77)
    readonly property color ok: "#7dffb2"
    readonly property color fav: "#ff5c7a"
    readonly property color danger: "#ff4d5e"
    readonly property int radius: 16
    readonly property int radiusSmall: 11
    readonly property int anim: 110
    readonly property int fast: 70
    readonly property int slow: 200
    readonly property string font: "Inter Tight"
    readonly property string mono: "JetBrains Mono"
    readonly property int fontSize: 13

    // aliases for the kept components (Toasts, Toggle, Icon, Preview)
    readonly property color accent: text
    readonly property color border: line
    readonly property color glassHover: Qt.rgba(1, 1, 1, 0.09)
}
