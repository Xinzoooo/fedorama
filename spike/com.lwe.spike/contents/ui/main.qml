import QtQuick
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager

WallpaperItem {
    id: root
    property bool fullscreenActive: false
    property int mine: 0
    readonly property rect sr: Qt.rect(Screen.virtualX, Screen.virtualY, Screen.width, Screen.height)
    property string dbg: ""
    property vector2d mouse: Qt.vector2d(0.5, 0.5)

    TaskManager.TasksModel {
        id: tasks
        filterByScreen: false
        screenGeometry: Qt.rect(Screen.virtualX, Screen.virtualY, Screen.width, Screen.height)
        filterByVirtualDesktop: true
        filterByActivity: true
        groupMode: TaskManager.TasksModel.GroupDisabled
    }
    Instantiator {
        id: inst
        model: tasks
        delegate: QtObject {
            readonly property rect geo: model.Geometry
            readonly property bool fs: model.IsFullScreen === true
            readonly property bool minimized: model.IsMinimized === true
            readonly property bool onMyScreen: {
                var cx = geo.x + geo.width/2, cy = geo.y + geo.height/2
                return cx >= Screen.virtualX && cx < Screen.virtualX + Screen.width && cy >= Screen.virtualY && cy < Screen.virtualY + Screen.height
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: {
        var fs = false, n = 0, d = ""
        for (var i = 0; i < inst.count; i++) {
            var o = inst.objectAt(i); if (!o) continue
            d += " " + o.geo.x + (o.fs ? "F" : "") + (o.minimized ? "m" : "")
            var cx = o.geo.x + o.geo.width/2, cy = o.geo.y + o.geo.height/2
            if (cx >= root.sr.x && cx < root.sr.x + root.sr.width && cy >= root.sr.y && cy < root.sr.y + root.sr.height) { n++; if (o.fs && !o.minimized) fs = true }
        }
        root.fullscreenActive = fs; root.mine = n; root.dbg = d
    } }

    Timer { interval: 33; running: true; repeat: true; onTriggered: {
        var x = new XMLHttpRequest()
        x.onreadystatechange = function() { if (x.readyState === 4 && x.status === 200) {
            var j = JSON.parse(x.responseText)
            root.mouse = Qt.vector2d((j.x - root.sr.x) / root.sr.width, (j.y - root.sr.y) / root.sr.height)
        } }
        x.open("GET", "http://127.0.0.1:47811/state"); x.send()
    } }
    ShaderEffect {
        anchors.fill: parent
        property real iTime: 0
        property vector2d iResolution: Qt.vector2d(width, height)
        property vector2d iMouse: root.mouse
        fragmentShader: Qt.resolvedUrl("test.frag.qsb")
        NumberAnimation on iTime { from: 0; to: 1000; duration: 1000000; loops: Animation.Infinite; paused: root.fullscreenActive }
    }
    HoverHandler {
        id: hh
        onPointChanged: root.mouse = Qt.vector2d(point.position.x / root.width, point.position.y / root.height)
    }
    Text { anchors.centerIn: parent; text: "fs=" + root.fullscreenActive + " mine=" + root.mine + "/" + tasks.count + " geo=" + Screen.virtualX + "," + Screen.virtualY + " " + Screen.width + " name=" + Screen.name + "\nMAUS=" + root.mouse.x.toFixed(2) + "," + root.mouse.y.toFixed(2); color: "white"; font.pixelSize: 40; horizontalAlignment: Text.AlignHCenter }
}
