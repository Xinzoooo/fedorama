// The stage: the current wallpaper live, cross-fading between two previews.
// At most two Preview instances exist; the hidden one is unloaded after the fade.
import QtQuick

Item {
    id: stage
    property var wp: null
    property bool running: true
    property int fps: 30
    property int slot: 0                    // 0: loader a shows the current wallpaper, 1: loader b

    onWpChanged: swap()
    Component.onCompleted: swap()

    function swap() {
        if (!wp) return
        var cur = slot === 0 ? a : b
        if (cur.w && cur.w.id === wp.id) { cur.w = wp; return }   // same wallpaper, new data (params, favourite)
        var nx = slot === 0 ? b : a
        nx.w = wp
        slot = 1 - slot
        unload.restart()
    }

    Timer {
        id: unload
        interval: Theme.slow + 60
        onTriggered: (stage.slot === 0 ? b : a).w = null
    }

    component Layer: Loader {
        id: l
        property var w: null
        property bool shown: false
        anchors.fill: parent
        active: w !== null
        opacity: shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
        sourceComponent: Preview {
            wp: l.w
            running: stage.running && l.shown
            fps: stage.fps
            // the wallpaper's own renderScale, at most 0.75: sharp in a normal window, bounded when maximised on 4K
            paramsOverride: ({ renderScale: Math.min(0.75, l.w && l.w.params && l.w.params.renderScale !== undefined ? l.w.params.renderScale : 1.0) })
        }
    }
    Layer { id: a; shown: stage.slot === 0 }
    Layer { id: b; shown: stage.slot === 1 }

    Text {
        anchors.centerIn: parent
        visible: !!(stage.wp && stage.wp.error)
        text: stage.wp ? stage.wp.error : ""
        color: Theme.textDim
        font { family: Theme.font; pixelSize: 15 }
    }

    // keeps the bar readable
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: parent.height * 0.3
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.5) }
        }
    }
}
