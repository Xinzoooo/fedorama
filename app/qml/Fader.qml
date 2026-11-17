// Thin slider: 2 px line, white fill, white knob that grows while dragged; value right in mono.
import QtQuick

Item {
    id: s
    property string text
    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: 0
    property var format: null
    signal moved(real value)
    implicitHeight: 44
    implicitWidth: 260

    property real shown: value                      // follows the drag without waiting for the backend
    onValueChanged: if (!ma.pressed) shown = value
    readonly property real frac: to > from ? Math.max(0, Math.min(1, (shown - from) / (to - from))) : 0

    Text { text: s.text; color: "#cccccc"; font { family: Theme.font; pixelSize: Theme.fontSize } }
    Text {
        anchors.right: parent.right
        text: s.format ? s.format(s.shown) : s.shown.toFixed(2)
        color: Theme.text; font { family: Theme.mono; pixelSize: 12 }
    }
    Item {
        id: track
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 7 }
        height: 14
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 2; color: "#333333" }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * s.frac; height: 2; color: Theme.text }
        Rectangle {
            x: parent.width * s.frac - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 14; height: 14; radius: 7
            color: Theme.text
            scale: ma.pressed ? 1.4 : (ma.containsMouse ? 1.15 : 1)
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            function set(mx) {
                var f = Math.max(0, Math.min(1, (mx - 8) / track.width))
                var v = s.from + f * (s.to - s.from)
                if (s.stepSize > 0) v = Math.round(v / s.stepSize) * s.stepSize
                s.shown = v
                s.moved(v)
            }
            onPressed: (m) => set(m.x)
            onPositionChanged: (m) => { if (pressed) set(m.x) }
        }
    }
}
