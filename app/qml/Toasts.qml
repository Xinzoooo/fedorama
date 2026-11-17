// Short messages, top centre: white pill (errors red), slides in from above.
import QtQuick

Column {
    id: toasts
    spacing: 8
    function push(msg, kind) {
        for (var i = 0; i < toastModel.count; i++) if (toastModel.get(i).msg === msg) return
        while (toastModel.count >= 3) toastModel.remove(0)
        toastModel.append({ msg: msg, kind: kind })
    }
    ListModel { id: toastModel }
    Repeater {
        model: toastModel
        Rectangle {
            id: t
            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
            width: Math.min(520, label.implicitWidth + 32)
            height: label.implicitHeight + 18
            radius: 12
            color: kind === "error" ? Theme.danger : Theme.text
            opacity: 0
            y: -20
            Component.onCompleted: { opacity = 1; y = 0; life.start() }
            Behavior on opacity { NumberAnimation { duration: Theme.anim } }
            Text {
                id: label
                anchors.centerIn: parent
                width: Math.min(implicitWidth, 488)
                text: msg
                wrapMode: Text.Wrap
                color: kind === "error" ? Theme.text : "#000000"
                font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
            }
            Timer { id: life; interval: kind === "error" ? 5000 : 2200; onTriggered: toastModel.remove(index) }
        }
    }
}
