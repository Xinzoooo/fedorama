import QtQuick
import org.kde.kwin
Item {
    property real lx: -1
    property real ly: -1
    Timer {
        interval: 33; repeat: true; running: true
        onTriggered: {
            var p = Workspace.cursorPos
            if (p.x === lx && p.y === ly) return
            lx = p.x; ly = p.y
            var x = new XMLHttpRequest()
            x.open("POST", "http://127.0.0.1:47811/cursor?x=" + p.x + "&y=" + p.y)
            x.send()
        }
    }
}
