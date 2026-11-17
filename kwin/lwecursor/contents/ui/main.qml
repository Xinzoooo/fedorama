// Sends the global cursor position to the Fedorama bridge.
// Wayland clients cannot read the cursor outside their own windows, KWin can.
// Only sends when the cursor moved; stops trying for a while if the app is not running.
// SPDX-License-Identifier: MIT
import QtQuick
import org.kde.kwin

Item {
    id: root
    property real lx: -1
    property real ly: -1
    property bool busy: false
    property int failures: 0
    readonly property int port: 47811

    Timer {
        interval: root.failures > 3 ? 3000 : 40
        repeat: true
        running: true
        onTriggered: {
            var p = Workspace.cursorPos
            if ((p.x === root.lx && p.y === root.ly && root.failures === 0) || root.busy) return
            root.lx = p.x; root.ly = p.y
            root.busy = true
            var x = new XMLHttpRequest()
            x.onreadystatechange = function() {
                if (x.readyState !== XMLHttpRequest.DONE) return
                root.busy = false
                root.failures = (x.status === 204) ? 0 : root.failures + 1
            }
            x.open("POST", "http://127.0.0.1:" + root.port + "/cursor?x=" + Math.round(p.x) + "&y=" + Math.round(p.y))
            x.send()
        }
    }
}
