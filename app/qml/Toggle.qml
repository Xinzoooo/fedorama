import QtQuick

Item {
    id: t
    property bool checked: false
    property string text
    property string hint
    signal toggled(bool value)
    implicitHeight: Math.max(30, col.implicitHeight)
    implicitWidth: 320
    Column {
        id: col
        anchors { left: parent.left; right: sw.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 2
        Text { text: t.text; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; width: parent.width; wrapMode: Text.WordWrap }
        Text { text: t.hint; visible: t.hint !== ""; color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; width: parent.width; wrapMode: Text.WordWrap }
    }
    Rectangle {
        id: sw
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 34; height: 20; radius: 10
        color: t.checked ? Theme.text : "#2a2a2a"
        opacity: t.enabled ? 1 : 0.4
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Rectangle {
            width: 14; height: 14; radius: 7
            y: 3
            x: t.checked ? parent.width - width - 3 : 3
            color: t.checked ? "#000000" : "#777777"
            Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: t.enabled; onClicked: t.toggled(!t.checked) }
}
