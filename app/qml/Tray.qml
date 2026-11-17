// Container above the bar: grows upwards to the height of the open panel.
// Only the open panel is loaded; it stays until the close animation has finished.
import QtQuick

Rectangle {
    id: tray
    property string panel: ""
    property real maxHeight: 440
    property string shown: ""
    readonly property var files: ({ all: "AllPanel.qml", search: "SearchPanel.qml", adjust: "AdjustPanel.qml", settings: "SettingsPanel.qml" })
    readonly property real target: panel !== "" && ld.item ? Math.min(ld.item.implicitHeight + 44, maxHeight) : 0

    onPanelChanged: if (panel !== "") shown = panel
    height: target
    Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    onHeightChanged: if (height === 0 && panel === "") shown = ""
    visible: height > 0
    clip: true
    radius: Theme.radius
    color: Theme.glass
    border.color: Theme.line

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => w.accepted = true }   // keep clicks off the stage

    Loader {
        id: ld
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 22 }
        height: tray.target - 44
        source: tray.shown ? tray.files[tray.shown] : ""
        opacity: tray.panel !== "" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        transform: Translate { y: tray.panel !== "" ? 0 : 12; Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } }
    }
}
