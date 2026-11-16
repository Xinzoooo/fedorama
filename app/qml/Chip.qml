import QtQuick

Rectangle {
    id: c
    property string text
    property bool checked: false
    signal clicked()
    height: 30
    width: label.implicitWidth + 26
    radius: 15
    color: checked ? Theme.alpha(Theme.accent, 0.3) : (ma.containsMouse ? Theme.glassHover : Theme.glass)
    border.width: 1
    border.color: checked ? Theme.alpha(Theme.accent, 0.9) : Theme.border
    Behavior on color { ColorAnimation { duration: Theme.anim } }
    Text {
        id: label
        anchors.centerIn: parent
        text: c.text
        color: c.checked ? "#ffffff" : Theme.textDim
        font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.Medium
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.clicked() }
}
