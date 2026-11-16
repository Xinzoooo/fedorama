/*
 * Linux Wallpaper Engine – Plasma 6 wallpaper plugin
 * SPDX-License-Identifier: MIT
 *
 * Runs inside plasmashell, so it is drawn behind every window and desktop icon.
 * The companion app writes the config (Kind/Source/Params/...) via the
 * PlasmaShell scripting D-Bus API. Live data (global cursor, audio spectrum)
 * comes from the app's local bridge at 127.0.0.1:BridgePort.
 */
import QtQuick
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager

WallpaperItem {
    id: root

    // ---------------------------------------------------------------- config
    readonly property string cfgKind: configuration.Kind || "shader"
    readonly property string cfgSource: configuration.Source || ""
    readonly property string cfgParams: configuration.Params || "{}"
    readonly property int fps: Math.max(5, Math.min(240, configuration.Fps || 30))
    readonly property bool mouseEnabled: configuration.MouseEnabled !== false
    readonly property bool audioEnabled: configuration.AudioEnabled === true
    readonly property int bridgePort: configuration.BridgePort || 47811
    readonly property int transitionMs: configuration.Transition === undefined ? 900 : configuration.Transition

    // ---------------------------------------------------------------- state
    readonly property rect screenRect: Qt.rect(Screen.virtualX, Screen.virtualY, Screen.width, Screen.height)
    property bool coveredFullscreen: false
    property bool coveredMaximized: false
    property string taskDebug: ""
    readonly property bool running: !configuration.Paused
                                    && !(configuration.PauseOnFullscreen !== false && coveredFullscreen)
                                    && !(configuration.PauseOnMaximized === true && coveredMaximized)

    property vector2d mouse: Qt.vector2d(0.5, 0.5)       // smoothed, 0..1, y down
    property vector2d mouseTarget: Qt.vector2d(0.5, 0.5)
    property vector4d audio: Qt.vector4d(0, 0, 0, 0)       // bass, mid, treble, level
    property var spectrum: [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0]
    property bool bridgeOnline: false

    // ------------------------------------------------- fullscreen detection
    TaskManager.TasksModel {
        id: tasks
        filterByVirtualDesktop: true
        filterByActivity: true
        groupMode: TaskManager.TasksModel.GroupDisabled
    }
    Instantiator {
        id: taskObjects
        model: (configuration.PauseOnFullscreen !== false || configuration.PauseOnMaximized === true) ? tasks : null
        delegate: QtObject {
            readonly property rect geo: model.Geometry || Qt.rect(0, 0, 0, 0)
            readonly property bool fullscreen: model.IsFullScreen === true
            readonly property bool maximized: model.IsMaximized === true
            readonly property bool minimized: model.IsMinimized === true
        }
    }
    function checkCovered() {
        var fs = false, mx = false, d = ""
        var r = root.screenRect
        for (var i = 0; i < taskObjects.count; i++) {
            var o = taskObjects.objectAt(i)
            if (!o) continue
            d += " [" + o.geo.x + "," + o.geo.width + (o.fullscreen ? " F" : "") + (o.minimized ? " m" : "") + "]"
            if (o.minimized) continue
            var cx = o.geo.x + o.geo.width / 2, cy = o.geo.y + o.geo.height / 2
            if (cx < r.x || cx >= r.x + r.width || cy < r.y || cy >= r.y + r.height) continue
            // real fullscreen, or a borderless window covering the whole monitor
            // ("windowed fullscreen" in games, video players, ...)
            var covers = o.geo.x <= r.x + 2 && o.geo.y <= r.y + 2
                         && o.geo.x + o.geo.width >= r.x + r.width - 2
                         && o.geo.y + o.geo.height >= r.y + r.height - 2
            if (o.fullscreen || covers) fs = true
            if (o.maximized) mx = true
        }
        coveredFullscreen = fs
        taskDebug = d
        coveredMaximized = mx
    }
    Timer {
        interval: 750; repeat: true; triggeredOnStart: true
        running: taskObjects.model !== null
        onTriggered: root.checkCovered()
        onRunningChanged: if (!running) { root.coveredFullscreen = false; root.coveredMaximized = false }
    }

    // ------------------------------------------------------- live bridge
    property bool pollBusy: false
    property int pollFailures: 0
    function pollBridge() {
        if (pollBusy) return
        pollBusy = true
        var x = new XMLHttpRequest()
        x.onreadystatechange = function() {
            if (x.readyState !== XMLHttpRequest.DONE) return
            pollBusy = false
            if (x.status !== 200) { bridgeOnline = false; pollFailures++; return }
            pollFailures = 0
            bridgeOnline = true
            try {
                var j = JSON.parse(x.responseText)
                var r = root.screenRect
                if (root.mouseEnabled && j.cursor) {
                    mouseTarget = Qt.vector2d(Math.max(0, Math.min(1, (j.cursor[0] - r.x) / r.width)),
                                              Math.max(0, Math.min(1, (j.cursor[1] - r.y) / r.height)))
                }
                if (root.audioEnabled && j.audio) {
                    audio = Qt.vector4d(j.audio[0], j.audio[1], j.audio[2], j.audio[3])
                    if (j.spectrum && j.spectrum.length === 16) spectrum = j.spectrum
                }
            } catch (e) {}
        }
        x.open("GET", "http://127.0.0.1:" + bridgePort + "/state?screen=" + encodeURIComponent(Screen.name))
        x.send()
    }
    Timer {
        // back off to 3 s while the app is not running
        interval: root.pollFailures > 3 ? 3000 : Math.round(1000 / Math.min(root.fps, 60))
        repeat: true
        running: root.running && (root.mouseEnabled || root.audioEnabled)
        onTriggered: root.pollBridge()
    }
    Timer {
        // smoothing of cursor + decay of audio when bridge is quiet
        interval: Math.round(1000 / Math.min(root.fps, 60)); repeat: true
        running: root.running
        onTriggered: {
            var k = 0.12
            var dx = root.mouseTarget.x - root.mouse.x, dy = root.mouseTarget.y - root.mouse.y
            if (Math.abs(dx) > 0.0005 || Math.abs(dy) > 0.0005)
                root.mouse = Qt.vector2d(root.mouse.x + dx * k, root.mouse.y + dy * k)
            if (!root.audioEnabled && root.audio.w > 0) root.audio = Qt.vector4d(0, 0, 0, 0)
        }
    }

    // ----------------------------------------------- crossfading slots
    property int front: 0
    property string currentKey: ""
    readonly property var slotItems: [slotA, slotB]

    function applyConfig() {
        var key = cfgKind + "|" + cfgSource
        var front = slotItems[root.front]
        if (key === currentKey) {           // only parameters changed
            front.paramsJson = cfgParams
            return
        }
        currentKey = key
        var back = slotItems[1 - root.front]
        fade.stop()
        back.opacity = 0.004   // must be > 0 so the scene graph renders (and compiles) it
        back.kind = ""                // unload first so no renderer sees a mismatched source
        back.paramsJson = cfgParams
        back.source = cfgSource
        back.kind = cfgKind
        back.z = 1; front.z = 0
        pending = true
        if (back.ready) finishSwap()
    }
    property bool pending: false
    function finishSwap() {
        if (!pending) return
        pending = false
        var back = slotItems[1 - root.front]
        if (!slotItems[root.front].kind || transitionMs <= 0) { back.opacity = 1; done(); return }
        fade.target = back
        fade.start()
    }
    function done() {
        var old = slotItems[root.front]
        root.front = 1 - root.front
        old.kind = ""
        old.source = ""
        old.opacity = 0
    }
    NumberAnimation {
        id: fade
        property: "opacity"; from: 0.004; to: 1
        duration: root.transitionMs
        easing.type: Easing.InOutQuad
        onFinished: root.done()
    }

    onCfgKindChanged: applyTimer.restart()
    onCfgSourceChanged: applyTimer.restart()
    onCfgParamsChanged: applyTimer.restart()
    // coalesce the separate config change signals into one apply
    Timer { id: applyTimer; interval: 30; onTriggered: root.applyConfig() }
    Component.onCompleted: applyConfig()

    Rectangle { anchors.fill: parent; color: "#05060a" }

    Slot {
        id: slotA
        host: root
        anchors.fill: parent
        onReadyChanged: if (ready && root.slotItems[1 - root.front] === slotA) root.finishSwap()
    }
    Slot {
        id: slotB
        host: root
        anchors.fill: parent
        onReadyChanged: if (ready && root.slotItems[1 - root.front] === slotB) root.finishSwap()
    }

    Text {
        z: 10
        visible: root.cfgParams.indexOf('"debug"') >= 0
        color: "white"; style: Text.Outline; styleColor: "black"; font.pixelSize: 18
        anchors { top: parent.top; right: parent.right; margins: 40 }
        text: "front=" + root.front + " pending=" + root.pending + " running=" + root.running + " bridge=" + root.bridgeOnline + " fs=" + root.coveredFullscreen + " tasks=" + taskObjects.count + " scr=" + root.screenRect + "\n" + root.taskDebug
              + "\nA: " + slotA.kind + " ready=" + slotA.ready + " op=" + slotA.opacity.toFixed(3) + " " + slotA.dbg
              + "\nB: " + slotB.kind + " ready=" + slotB.ready + " op=" + slotB.opacity.toFixed(3) + " " + slotB.dbg
              + "\nmouse=" + root.mouse.x.toFixed(2) + "," + root.mouse.y.toFixed(2) + " audio=" + root.audio.x.toFixed(2)
    }
}
