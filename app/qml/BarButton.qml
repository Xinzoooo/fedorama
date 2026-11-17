// 40x40 icon button for the bar: soft hover, white when active, gives way when pressed.
import QtQuick

Item {
    id: b
    property string icon
    property string tip
    property bool active: false
    property bool danger: false                     // hover turns red (close)
    property color accent: "transparent"          // fixed icon colour (e.g. the red heart)
    readonly property color iconColor: active ? "#000000" : (danger && ma.containsMouse ? Theme.text : accent.a > 0 ? accent : (ma.containsMouse ? Theme.text : Theme.textSoft))
    signal clicked()
    width: 40; height: 40
    opacity: enabled ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: b.active ? Theme.text : (ma.containsMouse ? (b.danger ? Theme.danger : Theme.glassHover) : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        scale: ma.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
        Icon { anchors.centerIn: parent; name: b.icon; size: 20; color: b.iconColor }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }

    // tooltip above the button
    Rectangle {
        visible: opacity > 0
        opacity: ma.containsMouse && b.tip !== "" && tipDelay.done ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        anchors { bottom: parent.top; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
        width: tipText.implicitWidth + 16; height: tipText.implicitHeight + 8
        radius: 7
        color: "#000000"
        border.color: Qt.rgba(1, 1, 1, 0.14)
        Text { id: tipText; anchors.centerIn: parent; text: b.tip; color: Theme.text; font { family: Theme.font; pixelSize: 11; weight: Font.Medium } }
    }
    Timer { id: tipDelay; property bool done: false; interval: 450; running: ma.containsMouse; onRunningChanged: if (!running) done = false; onTriggered: done = true }
}
