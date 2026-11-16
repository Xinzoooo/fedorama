import QtQuick
import QtQuick.Effects

Item {
    id: tile
    property var wp
    property bool selected: false
    signal clicked()
    signal favoriteClicked()
    readonly property bool hovered: hover.hovered

    Rectangle {
        id: glowSrc
        anchors.fill: card
        radius: card.radius
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
        visible: false
    }
    MultiEffect {
        anchors.fill: card
        source: glowSrc
        visible: Theme.glow > 0
        blurEnabled: true; blur: 1; blurMax: 40
        scale: card.scale
        opacity: (tile.hovered || tile.selected) ? 0.7 * Theme.glow : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
    }

    Item {
        id: card
        anchors.fill: parent
        anchors.margins: 8
        property real radius: Theme.radius
        scale: tile.hovered ? 1.035 : 1
        Behavior on scale { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

        Item {
            id: content
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: mask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
            Rectangle { anchors.fill: parent; color: Theme.bg2 }
            Image {
                id: thumb
                anchors.fill: parent
                source: tile.wp && tile.wp.thumb ? "file://" + tile.wp.thumb : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 560
                opacity: live.ready && live.visible ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
            // no thumbnail: a single still frame of the real renderer
            Loader {
                anchors.fill: parent
                active: tile.wp && !tile.wp.thumb && (tile.wp.type === "shader" || tile.wp.type === "particles")
                sourceComponent: Preview { wp: tile.wp; running: false; paramsOverride: ({ renderScale: 0.4 }) }
            }
            Loader {
                id: liveLoader
                anchors.fill: parent
                active: tile.hovered && hoverDelay.done
                property bool ready: item ? item.ready : false
                sourceComponent: Preview {
                    wp: tile.wp
                    running: true
                    fps: 30
                    paramsOverride: ({ renderScale: 0.5, muted: true })
                    mouse: Qt.vector2d(hover.point.position.x / Math.max(1, tile.width), hover.point.position.y / Math.max(1, tile.height))
                    opacity: ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
            }
            QtObject { id: live; property bool ready: liveLoader.ready; property bool visible: liveLoader.active }
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: parent.height * 0.4
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.82) }
                }
            }
        }
        Rectangle { id: mask; anchors.fill: parent; radius: card.radius; visible: false; layer.enabled: true }
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: "transparent"
            border.width: tile.selected ? 2 : 1
            border.color: tile.selected ? Theme.accent2 : (tile.hovered ? Theme.alpha("#ffffff", 0.35) : Theme.border)
        }

        Column {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }
            spacing: 4
            Text {
                width: parent.width
                text: tile.wp ? tile.wp.title : ""
                color: "#ffffff"; elide: Text.ElideRight
                font.family: Theme.font; font.pixelSize: Theme.fontSize + 1; font.weight: Font.DemiBold
            }
        }
        IconButton {
            anchors { right: parent.right; top: parent.top; margins: 8 }
            size: 34
            icon: tile.wp && tile.wp.favorite ? "heart-filled" : "heart"
            active: tile.wp && tile.wp.favorite
            tint: Theme.accent3
            visible: tile.hovered || (tile.wp && tile.wp.favorite)
            onClicked: tile.favoriteClicked()
        }
        Rectangle {
            visible: tile.wp && tile.wp.error !== ""
            anchors { left: parent.left; top: parent.top; margins: 10 }
            radius: 8; height: 22; width: errT.implicitWidth + 14
            color: Theme.alpha(Theme.danger, 0.85)
            Text { id: errT; anchors.centerIn: parent; text: "Fehler"; color: "white"; font.pixelSize: 11; font.bold: true }
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    Timer { id: hoverDelay; property bool done: false; interval: 280; running: tile.hovered; onTriggered: done = true; onRunningChanged: if (!running && !tile.hovered) done = false }
    TapHandler { onTapped: tile.clicked() }
}
