// "Automatisch wechseln" for one monitor: off, rotation or day/night (same logic as before, new look).
import QtQuick

Column {
    id: ed
    property string screen: ""
    readonly property var scr: {
        for (var i = 0; i < lwe.screens.length; i++) if (lwe.screens[i].name === screen) return lwe.screens[i]
        return null
    }
    readonly property var pl: scr ? scr.playlist : ({})
    function setPl(k, v) { var o = {}; o[k] = v; lwe.setPlaylist(screen, o) }
    function title(id) {
        for (var i = 0; i < lwe.wallpapers.length; i++) if (lwe.wallpapers[i].id === id) return lwe.wallpapers[i].title
        return "nicht gewählt"
    }
    spacing: 14

    Row {
        spacing: 4
        Pill { objectName: "playlist-off"; text: "Aus"; checked: !ed.pl.enabled; onClicked: ed.setPl("enabled", false) }
        Pill { objectName: "playlist-interval"; text: "Rotation"; checked: !!ed.pl.enabled && ed.pl.mode === "interval"
               onClicked: lwe.setPlaylist(ed.screen, { enabled: true, mode: "interval" }) }
        Pill { objectName: "playlist-daynight"; text: "Tag / Nacht"; checked: !!ed.pl.enabled && ed.pl.mode === "daynight"
               onClicked: lwe.setPlaylist(ed.screen, { enabled: true, mode: "daynight" }) }
    }

    // ---- rotation
    Column {
        width: parent.width
        spacing: 12
        visible: !!ed.pl.enabled && ed.pl.mode === "interval"
        Row {
            spacing: 36
            Fader {
                width: 280; text: "Wechsel alle"
                from: 1; to: 120; stepSize: 1; value: ed.pl.interval || 10
                format: function(v) { return Math.round(v) + " min" }
                onMoved: (v) => ed.setPl("interval", Math.round(v))
            }
            Toggle { width: 280; height: 44; text: "Zufällige Reihenfolge"; checked: ed.pl.shuffle === true; onToggled: (v) => ed.setPl("shuffle", v) }
        }
        Text {
            width: parent.width; wrapMode: Text.WordWrap
            text: (ed.pl.items && ed.pl.items.length ? ed.pl.items.length + " ausgewählt." : "Keine Auswahl: es werden deine Favoriten verwendet (oder alle, wenn keine Favoriten).")
                  + " Klick auf ein Bild nimmt es auf oder heraus."
            color: Theme.textDim; font { family: Theme.font; pixelSize: Theme.fontSize }
        }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: win.visibleList
                PickThumb {
                    wp: modelData
                    picked: !!ed.pl.items && ed.pl.items.indexOf(modelData.id) >= 0
                    onClicked: {
                        var a = (ed.pl.items || []).slice()
                        var i = a.indexOf(modelData.id)
                        if (i >= 0) a.splice(i, 1); else a.push(modelData.id)
                        ed.setPl("items", a)
                    }
                }
            }
        }
    }

    // ---- day / night: time + the wallpaper on the stage right now
    Column {
        spacing: 10
        visible: !!ed.pl.enabled && ed.pl.mode === "daynight"
        Repeater {
            model: [["day", "dayStart", "Tagsüber ab"], ["night", "nightStart", "Nachts ab"]]
            Row {
                spacing: 12
                Text { text: modelData[2]; width: 100; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize } anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    width: 70; height: 34; radius: 9
                    color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.2)
                    anchors.verticalCenter: parent.verticalCenter
                    TextInput {
                        anchors.fill: parent
                        horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                        inputMask: "99:99"
                        text: ed.pl[modelData[1]] || ""
                        color: Theme.text; font { family: Theme.mono; pixelSize: 13 }
                        onEditingFinished: ed.setPl(modelData[1], text)
                    }
                }
                Text { text: ed.title(ed.pl[modelData[0]]); width: 200; elide: Text.ElideRight; color: Theme.textSoft; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold } anchors.verticalCenter: parent.verticalCenter }
                TextButton {
                    text: "Aktuelles nehmen"
                    enabled: win.current !== null
                    onClicked: ed.setPl(modelData[0], win.current.id)
                }
            }
        }
    }
}
