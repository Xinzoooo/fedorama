// Small choice chip: outlined, white when checked.
import QtQuick

Rectangle {
    id: p
    property string text
    property bool checked: false
    signal clicked()
    width: label.implicitWidth + 24; height: 32
    radius: 9
    color: checked ? Theme.text : "transparent"
    border.color: checked ? Theme.text : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.33) : Qt.rgba(1, 1, 1, 0.16))
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    scale: ma.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }
    Text {
        id: label
        anchors.centerIn: parent
        text: p.text
        color: p.checked ? "#000000" : (ma.containsMouse ? Theme.text : "#bbbbbb")
        font { family: Theme.font; pixelSize: Theme.fontSize }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: p.clicked() }
}
