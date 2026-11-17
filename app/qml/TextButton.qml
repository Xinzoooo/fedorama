// Outlined text button with an optional icon (Zurücksetzen, Ordner, Importieren …).
import QtQuick

Rectangle {
    id: b
    property string text
    property string icon: ""
    property bool danger: false
    signal clicked()
    width: row.implicitWidth + 28; height: 36
    radius: 9
    color: "transparent"
    border.color: ma.containsMouse ? (danger ? Theme.danger : Qt.rgba(1, 1, 1, 0.33)) : Qt.rgba(1, 1, 1, 0.16)
    Behavior on border.color { ColorAnimation { duration: Theme.fast } }
    scale: ma.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Icon { visible: b.icon !== ""; name: b.icon; size: 16; color: label.color; anchors.verticalCenter: parent.verticalCenter }
        Text {
            id: label
            text: b.text
            color: b.danger ? Theme.danger : (ma.containsMouse ? Theme.text : "#cccccc")
            font { family: Theme.font; pixelSize: Theme.fontSize }
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
}
