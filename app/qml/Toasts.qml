import QtQuick

Column {
    id: toasts
    spacing: 10
    width: 380
    function push(msg, kind) { model.append({ msg: msg, kind: kind }) }
    ListModel { id: model }
    Repeater {
        model: model
        Glass {
            id: t
            width: toasts.width
            height: msgText.implicitHeight + 28
            color: Theme.alpha(Theme.bg, 0.88)
            glowing: true
            glowColor: kind === "error" ? Theme.danger : (kind === "ok" ? Theme.ok : Theme.accent2)
            opacity: 0
            x: 40
            Component.onCompleted: { opacity = 1; x = 0 }
            Behavior on opacity { NumberAnimation { duration: Theme.anim } }
            Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
            Rectangle { width: 4; radius: 2; anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 10 } color: t.glowColor }
            Text {
                id: msgText
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 24; rightMargin: 14 }
                text: msg; wrapMode: Text.WordWrap
                color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize
            }
            Timer { running: true; interval: kind === "error" ? 6000 : 3200; onTriggered: model.remove(index) }
            MouseArea { anchors.fill: parent; onClicked: model.remove(index) }
        }
    }
}
