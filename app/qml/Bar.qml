// The floating bar: panels left · ‹ name › centre · favourite, hide, apply right.
import QtQuick

Rectangle {
    id: bar
    height: 68
    radius: Theme.radius
    color: Theme.glass
    border.color: Theme.line

    readonly property var wp: win.current
    readonly property bool live: {
        if (!wp) return false
        for (var i = 0; i < lwe.screens.length; i++) if (lwe.screens[i].wallpaper === wp.id) return true
        return false
    }
    readonly property string typeLabel: wp ? ({ shader: "SHADER", particles: "PARTIKEL", video: "VIDEO", gif: "GIF", image: "BILD" })[wp.type] || wp.type.toUpperCase() : ""

    // swallow clicks so they don't reach the stage below
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    // ---------------------------------------------------- left: panels
    Row {
        id: leftGroup
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 2
        Repeater {
            model: [["all", "all", "Alle (Leertaste)"], ["search", "search", "Suchen (/)"],
                    ["adjust", "adjust", "Anpassen (A)"], ["settings", "settings", "Einstellungen"]]
            BarButton {
                objectName: "panel-" + modelData[0]
                icon: modelData[1]; tip: modelData[2]
                active: win.panel === modelData[0]
                onClicked: win.togglePanel(modelData[0])
            }
        }
    }

    // ---------------------------------------------------- centre: ‹ name ›
    Row {
        anchors.centerIn: parent
        spacing: 14
        BarButton { objectName: "prevButton"; icon: "prev"; tip: "Zurück (←)"; anchors.verticalCenter: parent.verticalCenter; onClicked: win.step(-1) }
        Item {
            id: title
            // the centre stays centred, so it may only use what the wider side group leaves free
            width: Math.max(120, Math.min(300, bar.width - 2 * (Math.max(leftGroup.width + 10, rightGroup.width + 12) + 12) - 2 * (40 + 14)))
            height: 44
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            property string shown: bar.wp ? bar.wp.title : ""
            property string target: bar.wp ? bar.wp.title : ""
            onTargetChanged: if (target !== shown) swap.restart()
            SequentialAnimation {
                id: swap
                ParallelAnimation {
                    NumberAnimation { target: nameText; property: "anchors.verticalCenterOffset"; to: 18; duration: 160; easing.type: Easing.InCubic }
                    NumberAnimation { target: nameText; property: "opacity"; to: 0; duration: 160 }
                }
                ScriptAction { script: { title.shown = title.target; nameText.anchors.verticalCenterOffset = -18 } }
                ParallelAnimation {
                    NumberAnimation { target: nameText; property: "anchors.verticalCenterOffset"; to: -7; duration: 260; easing.type: Easing.OutCubic }
                    NumberAnimation { target: nameText; property: "opacity"; to: 1; duration: 200 }
                }
            }
            Text {
                id: nameText
                anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: -7 }
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: title.shown
                color: Theme.text
                font { family: Theme.font; pixelSize: 22; weight: Font.ExtraBold; letterSpacing: -0.6 }
            }
            Row {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                spacing: 10
                Text {
                    text: win.visibleList.length ? String(win.index + 1).padStart(2, "0") + "/" + win.visibleList.length : ""
                    color: Theme.textDim; font { family: Theme.mono; pixelSize: 11; letterSpacing: 0.8 }
                }
                Text { text: bar.typeLabel; color: Theme.textDim; font { family: Theme.mono; pixelSize: 11; letterSpacing: 0.8 } }
                Text { visible: bar.live; text: "● LÄUFT"; color: Theme.ok; font { family: Theme.mono; pixelSize: 11; letterSpacing: 0.8 } }
            }
        }
        BarButton { objectName: "nextButton"; icon: "next"; tip: "Weiter (→)"; anchors.verticalCenter: parent.verticalCenter; onClicked: win.step(1) }
    }

    // ---------------------------------------------------- right: favourite, hide, apply
    Row {
        id: rightGroup
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 6
        BarButton {
            objectName: "favButton"
            anchors.verticalCenter: parent.verticalCenter
            icon: bar.wp && bar.wp.favorite ? "heart-filled" : "heart"
            accent: bar.wp && bar.wp.favorite ? Theme.fav : "transparent"
            tip: "Favorit (F)"
            onClicked: if (bar.wp) lwe.toggleFavorite(bar.wp.id)
        }
        BarButton {
            objectName: "hideButton"
            anchors.verticalCenter: parent.verticalCenter
            icon: "hide"; tip: "Ausblenden (Entf)"
            enabled: win.visibleList.length > 1
            onClicked: win.hideCurrent()
        }
        Rectangle {
            id: applyButton
            objectName: "applyButton"
            signal clicked()
            onClicked: win.applyCurrent()
            anchors.verticalCenter: parent.verticalCenter
            width: applyRow.implicitWidth + 40; height: 44
            radius: 12
            color: win.justApplied ? Theme.ok : Theme.text
            Behavior on color { ColorAnimation { duration: Theme.anim } }
            scale: applyMa.pressed ? 0.95 : 1
            Behavior on scale { NumberAnimation { duration: 80 } }
            Rectangle {                             // hover ring
                anchors.fill: parent; anchors.margins: -4; radius: 16
                color: "transparent"; border.width: 4; border.color: Qt.rgba(1, 1, 1, 0.16)
                opacity: applyMa.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            }
            Row {
                id: applyRow
                anchors.centerIn: parent
                spacing: 10
                Text { text: win.justApplied ? "Läuft" : "Anwenden"; color: "#000000"; font { family: Theme.font; pixelSize: 14; weight: Font.DemiBold } anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18; height: 16; radius: 4
                    color: "transparent"; border.color: Qt.rgba(0, 0, 0, 0.2)
                    Text { anchors.centerIn: parent; text: "↵"; color: Qt.rgba(0, 0, 0, 0.55); font { family: Theme.mono; pixelSize: 11 } }
                }
            }
            MouseArea { id: applyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: applyButton.clicked() }
        }
    }
}
