// Frosted glass panel: translucent fill, hairline border, soft top highlight.
import QtQuick

Rectangle {
    id: g
    property bool hovered: false
    property bool glowing: false
    property color glowColor: Theme.accent
    radius: Theme.radius
    color: hovered ? Theme.glassHover : Theme.glass
    border.width: 1
    border.color: glowing ? Theme.alpha(glowColor, 0.65) : Theme.border
    Behavior on color { ColorAnimation { duration: Theme.anim } }
    Behavior on border.color { ColorAnimation { duration: Theme.anim } }
    Rectangle {           // top sheen
        visible: Theme.sheen
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
        height: Math.min(parent.height * 0.5, 60)
        radius: parent.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.06) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
        }
    }
}
