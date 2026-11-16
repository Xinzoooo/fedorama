import QtQuick
import QtQuick.Controls

Item {
    id: page
    property string current: lwe.screens.length ? lwe.screens[0].name : ""
    readonly property var scr: {
        var s = lwe.screens
        for (var i = 0; i < s.length; i++) if (s[i].name === current) return s[i]
        return s.length ? s[0] : null
    }
    readonly property var pl: scr ? scr.playlist : ({})
    function wpById(id) {
        var all = lwe.wallpapers
        for (var i = 0; i < all.length; i++) if (all[i].id === id) return all[i]
        return null
    }
    function setPl(k, v) { var o = {}; o[k] = v; lwe.setPlaylist(page.current, o) }
    signal chooseWallpaper(string screen)

    Column {
        id: head
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 4
        Text { text: "Monitore & Playlists"; color: Theme.text; font.family: Theme.font; font.pixelSize: 20; font.weight: Font.Medium }
        Text { text: "Jeder Bildschirm hat sein eigenes Wallpaper und seine eigene Rotation."; color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
    }

    Flickable {
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; topMargin: 18 }
        contentHeight: body.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        Column {
            id: body
            width: parent.width
            spacing: 18

            Glass {
                width: parent.width; height: 230
                ScreenMap {
                    anchors.fill: parent; anchors.margins: 20
                    selected: page.current
                    onScreenClicked: (n) => page.current = n
                }
            }

            Row {
                width: parent.width
                spacing: 18
                // ---------------------------------------- current wallpaper
                Glass {
                    width: (parent.width - 18) * 0.42
                    height: Math.max(curCol.implicitHeight, plCol.implicitHeight) + 40
                    Column {
                        id: curCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                        spacing: 12
                        Text { text: page.scr ? page.scr.name + (page.scr.label !== page.scr.name ? "  ·  " + page.scr.label : "") : ""; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium; elide: Text.ElideRight; width: parent.width }
                        Text { text: page.scr ? page.scr.w + " × " + page.scr.h : ""; color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
                        Item {
                            width: parent.width; height: width * 9 / 16
                            Rectangle { anchors.fill: parent; radius: Theme.radiusSmall; color: Theme.bg2; clip: true
                                Preview {
                                    anchors.fill: parent
                                    wp: page.scr ? page.wpById(page.scr.wallpaper) : null
                                    running: page.visible && Qt.application.state === Qt.ApplicationActive
                                    paramsOverride: ({ renderScale: 0.5, muted: true })
                                }
                            }
                            Rectangle { anchors.fill: parent; radius: Theme.radiusSmall; color: "transparent"; border.color: Theme.border }
                            Text {
                                anchors.centerIn: parent
                                visible: !page.scr || !page.scr.wallpaper
                                text: "Noch kein Wallpaper"; color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize
                            }
                        }
                        Text {
                            width: parent.width
                            text: page.scr && page.wpById(page.scr.wallpaper) ? page.wpById(page.scr.wallpaper).title : "–"
                            color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 1; elide: Text.ElideRight
                        }
                        Row {
                            spacing: 8
                            NeonButton { text: "Wählen"; icon: "grid"; primary: true; onClicked: page.chooseWallpaper(page.current) }
                            NeonButton { text: "Nächstes"; icon: "next"; onClicked: lwe.nextWallpaper(page.current) }
                        }
                    }
                }
                // ---------------------------------------- playlist
                Glass {
                    width: (parent.width - 18) * 0.58
                    height: Math.max(curCol.implicitHeight, plCol.implicitHeight) + 40
                    Column {
                        id: plCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                        spacing: 14
                        Row {
                            spacing: 10
                            Icon { name: "playlist"; size: 22; color: Theme.accent2; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Automatisch wechseln"; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Flow {
                            width: parent.width; spacing: 8
                            Chip { text: "Aus"; checked: !page.pl.enabled; onClicked: page.setPl("enabled", false) }
                            Chip { text: "Rotation"; checked: page.pl.enabled && page.pl.mode === "interval"; onClicked: lwe.setPlaylist(page.current, { enabled: true, mode: "interval" }) }
                            Chip { text: "Tag / Nacht"; checked: page.pl.enabled && page.pl.mode === "daynight"; onClicked: lwe.setPlaylist(page.current, { enabled: true, mode: "daynight" }) }
                        }
                        // ---- interval
                        Column {
                            width: parent.width; spacing: 10
                            visible: page.pl.enabled && page.pl.mode === "interval"
                            NeonSlider {
                                width: parent.width; text: "Wechsel alle"
                                from: 1; to: 120; stepSize: 1; value: page.pl.interval || 10
                                format: function(v) { return Math.round(v) + " min" }
                                onMoved: (v) => page.setPl("interval", Math.round(v))
                            }
                            Toggle { width: parent.width; text: "Zufällige Reihenfolge"; checked: page.pl.shuffle === true; onToggled: (v) => page.setPl("shuffle", v) }
                            Text {
                                width: parent.width; wrapMode: Text.WordWrap
                                text: (page.pl.items && page.pl.items.length ? page.pl.items.length + " ausgewählt" : "Keine Auswahl → es werden deine Favoriten verwendet (oder alle, wenn keine Favoriten).") + "  Klicke Bilder an, um sie in die Playlist aufzunehmen:"
                                color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                            }
                            Flow {
                                width: parent.width; spacing: 6
                                Repeater {
                                    model: lwe.wallpapers
                                    Item {
                                        width: 92; height: 52
                                        readonly property bool inList: page.pl.items && page.pl.items.indexOf(modelData.id) >= 0
                                        Rectangle {
                                            anchors.fill: parent; radius: 8; color: Theme.bg2; clip: true
                                            Image { anchors.fill: parent; source: modelData.thumb ? "file://" + modelData.thumb : ""; fillMode: Image.PreserveAspectCrop; sourceSize.width: 184; asynchronous: true; opacity: parent.parent.inList ? 1 : 0.45 }
                                            Text { visible: !modelData.thumb; anchors.centerIn: parent; text: modelData.title; color: Theme.textDim; font.pixelSize: 9; width: parent.width - 6; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
                                        }
                                        Rectangle { anchors.fill: parent; radius: 8; color: "transparent"; border.width: parent.inList ? 2 : 1; border.color: parent.inList ? Theme.accent2 : Theme.border }
                                        Icon { visible: parent.inList; name: "check"; size: 16; color: Theme.accent2; anchors { right: parent.right; top: parent.top; margins: 4 } }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var a = (page.pl.items || []).slice()
                                                var i = a.indexOf(modelData.id)
                                                if (i >= 0) a.splice(i, 1); else a.push(modelData.id)
                                                page.setPl("items", a)
                                            }
                                        }
                                        ToolTip.visible: hov.hovered; ToolTip.text: modelData.title; ToolTip.delay: 500
                                        HoverHandler { id: hov }
                                    }
                                }
                            }
                        }
                        // ---- day / night
                        Column {
                            width: parent.width; spacing: 12
                            visible: page.pl.enabled && page.pl.mode === "daynight"
                            Repeater {
                                model: [["day", "dayStart", "sun", "Tagsüber ab"], ["night", "nightStart", "moon", "Nachts ab"]]
                                Row {
                                    spacing: 10
                                    Icon { name: modelData[2]; size: 22; color: modelData[0] === "day" ? "#ffd166" : Theme.accent2; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: modelData[3]; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; width: 90; anchors.verticalCenter: parent.verticalCenter }
                                    TextField {
                                        width: 70; text: page.pl[modelData[1]] || ""
                                        inputMask: "99:99"; color: Theme.text; horizontalAlignment: Text.AlignHCenter
                                        background: Rectangle { radius: 8; color: Theme.glass; border.color: Theme.border }
                                        onEditingFinished: page.setPl(modelData[1], text)
                                    }
                                    ComboBox {
                                        id: combo
                                        width: 230
                                        model: lwe.wallpapers
                                        textRole: "title"
                                        currentIndex: {
                                            var id = page.pl[modelData[0]]
                                            for (var i = 0; i < lwe.wallpapers.length; i++) if (lwe.wallpapers[i].id === id) return i
                                            return -1
                                        }
                                        displayText: currentIndex >= 0 ? currentText : "Wallpaper wählen …"
                                        onActivated: (i) => page.setPl(modelData[0], lwe.wallpapers[i].id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
