// Wallpaper still with rounded corners; dark tile with the title when there is no thumbnail.
import QtQuick
import QtQuick.Effects

Item {
    id: t
    property var wp: null
    property int radius: 8
    property int decodeWidth: 300

    Item {
        id: content
        anchors.fill: parent
        visible: false
        Rectangle { anchors.fill: parent; color: "#0a0a0a" }
        Image {
            anchors.fill: parent
            source: t.wp && t.wp.thumb ? "file://" + t.wp.thumb : ""
            sourceSize.width: t.decodeWidth
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Text {
            visible: !!(t.wp && !t.wp.thumb)
            anchors.centerIn: parent; width: parent.width - 12
            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
            text: t.wp ? t.wp.title : ""
            color: Theme.textDim; font { family: Theme.font; pixelSize: 11 }
        }
    }
    Rectangle { id: mask; anchors.fill: parent; radius: t.radius; visible: false; layer.enabled: true }
    MultiEffect { anchors.fill: parent; source: content; maskEnabled: true; maskSource: mask }
}
