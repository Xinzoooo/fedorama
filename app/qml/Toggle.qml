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
        Text { text: t.hint; visible: t.hint !== ""; color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2; width: parent.width; wrapMode: Text.WordWrap }
    }
    Rectangle {
        id: sw
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 46; height: 26; radius: 13
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: t.checked ? Theme.accent : Theme.glassHover }
            GradientStop { position: 1; color: t.checked ? Theme.accent2 : Theme.glassHover }
        }
        border.width: t.checked ? 0 : 1
        border.color: Theme.border
        Rectangle {
            width: 20; height: 20; radius: 10
            y: 3
            x: t.checked ? parent.width - width - 3 : 3
            color: "#ffffff"
            Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: t.toggled(!t.checked) }
}
