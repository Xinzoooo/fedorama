import QtQuick
import QtQuick.Controls

Item {
    id: b
    property string icon
    property string tip
    property bool active: false
    property color tint: Theme.accent
    property int size: 30
    signal clicked()
    implicitWidth: size; implicitHeight: size
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: b.active ? Theme.alpha(b.tint, 0.28) : (ma.containsMouse ? Theme.glassHover : "transparent")
        border.width: ma.containsMouse || b.active ? 1 : 0
        border.color: Theme.alpha(b.tint, 0.6)
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }
    Icon { anchors.centerIn: parent; name: b.icon; size: Math.round(b.size * 0.5); color: b.active ? b.tint : Theme.text }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
    ToolTip.visible: tip !== "" && ma.containsMouse
    ToolTip.delay: 600
    ToolTip.text: tip
}
