// "Suchen": big input, results as a grid; Enter takes the first hit.
import QtQuick

Item {
    id: panel
    implicitHeight: field.height + 12 + Math.min(results.contentHeight, 4 * 52)
    readonly property var hits: {
        var q = field.text.trim().toLowerCase()
        var all = win.visibleList
        return q ? all.filter(function(w) { return w.title.toLowerCase().indexOf(q) >= 0 }) : all
    }
    function take(id) { win.show(id); win.panel = "" }

    TextInput {
        id: field
        objectName: "searchField"
        width: parent.width
        font { family: Theme.font; pixelSize: 30; weight: Font.ExtraBold; letterSpacing: -0.9 }
        color: Theme.text
        selectionColor: Qt.rgba(1, 1, 1, 0.3)
        Component.onCompleted: forceActiveFocus()
        onAccepted: if (panel.hits.length) panel.take(panel.hits[0].id)
        Keys.onEscapePressed: win.panel = ""
        Text {
            visible: !field.text
            text: "Suchen …"
            color: Theme.textDim
            font: field.font
        }
        Rectangle { anchors { left: parent.left; right: parent.right; top: parent.bottom; topMargin: 6 } height: 1; color: Qt.rgba(1, 1, 1, 0.16) }
    }

    GridView {
        id: results
        anchors { left: parent.left; right: parent.right; top: field.bottom; topMargin: 16; bottom: parent.bottom }
        cellWidth: Math.max(230, width / Math.max(1, Math.floor(width / 230)))
        cellHeight: 52
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: panel.hits
        delegate: Rectangle {
            required property var modelData
            required property int index
            width: results.cellWidth - 4; height: 48
            radius: 10
            color: hov.hovered || index === 0 ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
            Row {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                spacing: 12
                Thumb { width: 64; height: 40; radius: 6; decodeWidth: 128; wp: modelData }
                Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.title; color: Theme.text; font { family: Theme.font; pixelSize: 14; weight: Font.DemiBold } }
            }
            HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: panel.take(modelData.id) }
        }
    }
}
