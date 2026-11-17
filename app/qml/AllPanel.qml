// "Alle": horizontal strip of all visible wallpapers, optionally favourites only.
import QtQuick

Item {
    id: panel
    implicitHeight: head.height + 14 + 98
    property bool favOnly: false
    readonly property var items: favOnly ? win.visibleList.filter(function(w) { return w.favorite }) : win.visibleList

    Row {
        id: head
        spacing: 12
        Text { text: "Alle"; color: Theme.text; font { family: Theme.font; pixelSize: 24; weight: Font.ExtraBold; letterSpacing: -0.7 } anchors.verticalCenter: parent.verticalCenter }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: panel.items.length + (panel.favOnly ? " Favoriten" : " Wallpaper") + " · klicken zum Ansehen"
            color: Theme.textDim; font { family: Theme.font; pixelSize: Theme.fontSize }
        }
    }
    Row {
        anchors { right: parent.right; verticalCenter: head.verticalCenter }
        spacing: 4
        Pill { objectName: "allFilter"; text: "Alle"; checked: !panel.favOnly; onClicked: panel.favOnly = false }
        Pill { objectName: "favFilter"; text: "Favoriten"; checked: panel.favOnly; onClicked: panel.favOnly = true }
    }

    ListView {
        id: strip
        objectName: "allStrip"
        anchors { left: parent.left; right: parent.right; top: head.bottom; topMargin: 14 }
        height: 98
        orientation: ListView.Horizontal
        spacing: 6
        clip: true
        model: panel.items
        boundsBehavior: Flickable.StopAtBounds
        Component.onCompleted: positionViewAtIndex(Math.max(0, win.index), ListView.Center)
        delegate: Item {
            required property var modelData
            readonly property bool isCurrent: win.current && modelData.id === win.current.id
            width: 150; height: 94
            y: hov.hovered ? 0 : 3
            Behavior on y { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            Thumb {
                anchors.fill: parent
                wp: modelData
                opacity: hov.hovered || parent.isCurrent ? 1 : 0.6
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            }
            Rectangle {
                anchors.fill: parent; radius: 8
                color: "transparent"; border.width: 2; border.color: Theme.text
                visible: parent.isCurrent
            }
            HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: win.show(modelData.id) }
        }
    }
}
