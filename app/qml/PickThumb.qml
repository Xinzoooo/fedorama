// Clickable wallpaper still: dimmed (or grey) until hovered or picked, check mark when picked.
import QtQuick
import QtQuick.Effects

Item {
    id: p
    property var wp: null
    property bool picked: false
    property bool grey: false
    signal clicked()
    width: 92; height: 56

    Thumb {
        id: th
        anchors.fill: parent
        wp: p.wp
        decodeWidth: 184
        opacity: p.picked || hov.hovered ? 1 : 0.5
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        layer.enabled: p.grey && !hov.hovered
        layer.effect: MultiEffect { saturation: -1 }
    }
    Rectangle {
        anchors.fill: parent; radius: 8
        color: "transparent"
        border.width: p.picked ? 2 : 0; border.color: Theme.text
    }
    Rectangle {
        visible: p.picked
        anchors { right: parent.right; top: parent.top; margins: 4 }
        width: 18; height: 18; radius: 9; color: Theme.text
        Icon { anchors.centerIn: parent; name: "check"; size: 12; color: "#000000" }
    }
    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: p.clicked() }
    Rectangle {                                   // title on hover
        visible: hov.hovered
        anchors { bottom: parent.top; bottomMargin: 6; horizontalCenter: parent.horizontalCenter }
        width: tip.implicitWidth + 14; height: tip.implicitHeight + 6; radius: 6
        color: "#000000"; border.color: Qt.rgba(1, 1, 1, 0.14)
        z: 10
        Text { id: tip; anchors.centerIn: parent; text: p.wp ? p.wp.title : ""; color: Theme.text; font { family: Theme.font; pixelSize: 11 } }
    }
}
