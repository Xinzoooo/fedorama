import QtQuick
import QtQuick.Effects

Item {
    id: b
    property string text
    property string icon
    property bool primary: false
    property bool danger: false
    property bool checked: false
    property bool enabledState: true
    property color tint: danger ? Theme.danger : Theme.accent
    signal clicked()
    implicitHeight: 40
    implicitWidth: row.implicitWidth + 32
    opacity: enabledState ? 1 : 0.45

    Rectangle {
        id: glowSrc
        anchors.fill: bg
        radius: bg.radius
        color: b.tint
        visible: false
    }
    MultiEffect {
        anchors.fill: bg
        source: glowSrc
        visible: b.primary || b.checked
        blurEnabled: true; blur: 1.0; blurMax: 32
        opacity: (ma.containsMouse ? 0.75 : 0.45) * Theme.glow
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
    }
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: b.primary ? b.tint : (b.checked ? Theme.alpha(b.tint, 0.35) : (ma.containsMouse ? Theme.glassHover : Theme.glass)) }
            GradientStop { position: 1; color: b.primary ? (b.danger ? Qt.darker(b.tint, 1.3) : Theme.accent2) : (b.checked ? Theme.alpha(b.tint, 0.2) : (ma.containsMouse ? Theme.glassHover : Theme.glass)) }
        }
        border.width: b.primary ? 0 : 1
        border.color: b.checked ? Theme.alpha(b.tint, 0.8) : (ma.containsMouse ? Theme.alpha(b.tint, 0.6) : Theme.border)
        scale: ma.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Icon { name: b.icon; visible: b.icon !== ""; size: 18; anchors.verticalCenter: parent.verticalCenter; color: b.primary ? "#ffffff" : (b.danger ? Theme.danger : Theme.text) }
        Text {
            text: b.text; visible: b.text !== ""
            color: b.primary ? "#ffffff" : (b.danger ? Theme.danger : Theme.text)
            font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: b.enabledState
        onClicked: b.clicked()
    }
}
