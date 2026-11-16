import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Glass {
    id: panel
    property string wid: ""
    readonly property var wp: {
        var all = lwe.wallpapers
        for (var i = 0; i < all.length; i++) if (all[i].id === wid) return all[i]
        return null
    }
    readonly property var pr: wp ? wp.params : ({})
    function pv(k, fb) { return pr[k] === undefined ? fb : pr[k] }
    signal closeRequested()
    color: Theme.flat ? Theme.glass : Theme.alpha(Theme.bg, 0.72)
    radius: Theme.radius

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 18
        contentHeight: col.implicitHeight + 10
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        Column {
            id: col
            width: flick.width
            spacing: 16

            // preview
            Item {
                width: parent.width
                height: Math.round(width * 9 / 16)
                Item {
                    id: pvBox
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: MultiEffect { maskEnabled: true; maskSource: pvMask; maskThresholdMin: 0.5; maskSpreadAtMin: 1 }
                    Rectangle { anchors.fill: parent; color: Theme.bg2 }
                    Preview {
                        id: pv
                        anchors.fill: parent
                        wp: panel.wp
                        running: panel.visible && Qt.application.state === Qt.ApplicationActive
                        paramsOverride: ({ muted: true })
                        mouse: pvHover.hovered ? Qt.vector2d(pvHover.point.position.x / width, pvHover.point.position.y / height) : Qt.vector2d(0.5, 0.5)
                        HoverHandler { id: pvHover }
                    }
                }
                Rectangle { id: pvMask; anchors.fill: parent; radius: Theme.radiusSmall + 4; visible: false; layer.enabled: true }
                Rectangle { anchors.fill: parent; radius: Theme.radiusSmall + 4; color: "transparent"; border.width: 1; border.color: Theme.border }
                IconButton { anchors { right: parent.right; top: parent.top; margins: 8 } icon: "close"; size: 32; onClicked: panel.closeRequested() }
            }

            // title
            Column {
                width: parent.width
                spacing: 6
                Row {
                    width: parent.width
                    spacing: 8
                    Text {
                        width: parent.width - favBtn.width - 8
                        text: panel.wp ? panel.wp.title : ""
                        color: Theme.text; font.family: Theme.font; font.pixelSize: 22; font.weight: Font.Bold
                        wrapMode: Text.WordWrap
                    }
                    IconButton {
                        id: favBtn
                        icon: panel.wp && panel.wp.favorite ? "heart-filled" : "heart"
                        active: panel.wp && panel.wp.favorite
                        tint: Theme.accent3; tip: "Favorit"
                        onClicked: lwe.toggleFavorite(panel.wid)
                    }
                }
                Text {
                    width: parent.width
                    text: panel.wp ? panel.wp.description : ""
                    visible: text !== ""
                    color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize; wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    visible: panel.wp && (panel.wp.author !== "" || panel.wp.license !== "")
                    text: panel.wp ? [panel.wp.author, panel.wp.license ? "Lizenz: " + panel.wp.license : ""].filter(function(x) { return x }).join(" · ") : ""
                    color: Theme.alpha(Theme.textDim, 0.8); font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                }
                Text {
                    width: parent.width
                    visible: panel.wp && panel.wp.error !== ""
                    text: panel.wp ? panel.wp.error : ""
                    color: Theme.danger; font.family: Theme.font; font.pixelSize: Theme.fontSize; wrapMode: Text.WordWrap
                }
            }

            // apply
            Column {
                width: parent.width
                spacing: 10
                Text { text: "ANWENDEN"; color: Theme.textDim; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 1.5; font.weight: Font.DemiBold }
                NeonButton {
                    width: parent.width
                    text: lwe.screens.length > 1 ? "Auf allen Bildschirmen" : "Als Hintergrund setzen"
                    icon: "check"; primary: true
                    onClicked: lwe.apply(panel.wid, "")
                }
                ScreenMap {
                    width: parent.width
                    visible: lwe.screens.length > 1
                    height: 90
                    highlightWallpaper: panel.wid
                    onScreenClicked: (name) => lwe.apply(panel.wid, name)
                }
                Text {
                    visible: lwe.screens.length > 1
                    width: parent.width
                    text: "Tipp: Klicke auf einen Monitor, um nur ihn zu ändern."
                    color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                }
            }

            // adjust
            Column {
                width: parent.width
                spacing: 4
                visible: panel.wp !== null
                Item {
                    width: parent.width; height: 28
                    Text { text: "ANPASSEN"; color: Theme.textDim; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 1.5; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: "Zurücksetzen"; color: resetMa.containsMouse ? Theme.accent2 : Theme.textDim
                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                        MouseArea { id: resetMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lwe.resetParams(panel.wid) }
                    }
                }
                readonly property bool isShader: panel.wp && panel.wp.type === "shader"
                readonly property bool isMedia: panel.wp && (panel.wp.type === "video" || panel.wp.type === "gif" || panel.wp.type === "image")
                NeonSlider {
                    width: parent.width; text: "Helligkeit"; visible: parent.isShader
                    from: 0.2; to: 1.6; value: panel.pv("brightness", 1.0)
                    format: function(v) { return Math.round(v * 100) + " %" }
                    onMoved: (v) => lwe.setParam(panel.wid, "brightness", v)
                }
                NeonSlider {
                    width: parent.width; text: "Farbton"; visible: parent.isShader
                    from: -180; to: 180; stepSize: 1; value: panel.pv("hue", 0)
                    format: function(v) { return Math.round(v) + "°" }
                    onMoved: (v) => lwe.setParam(panel.wid, "hue", v)
                }
                NeonSlider {
                    width: parent.width; text: "Sättigung"; visible: parent.isShader
                    from: 0; to: 2; value: panel.pv("saturation", 1.0)
                    format: function(v) { return Math.round(v * 100) + " %" }
                    onMoved: (v) => lwe.setParam(panel.wid, "saturation", v)
                }
                NeonSlider {
                    width: parent.width; text: "Geschwindigkeit"; visible: panel.wp && panel.wp.type !== "image"
                    from: 0.1; to: 3; value: panel.pv("speed", 1.0)
                    format: function(v) { return v.toFixed(1) + "×" }
                    onMoved: (v) => lwe.setParam(panel.wid, "speed", v)
                }
                NeonSlider {
                    width: parent.width; text: "Render-Auflösung (weniger = sparsamer)"; visible: parent.isShader
                    from: 0.25; to: 1; stepSize: 0.05; value: panel.pv("renderScale", 1.0)
                    format: function(v) { return Math.round(v * 100) + " %" }
                    onMoved: (v) => lwe.setParam(panel.wid, "renderScale", v)
                }
                NeonSlider {
                    width: parent.width; text: "Parallaxe (Maus)"; visible: parent.isMedia
                    from: 0; to: 2; value: panel.pv("parallax", 0.6)
                    format: function(v) { return Math.round(v * 100) + " %" }
                    onMoved: (v) => lwe.setParam(panel.wid, "parallax", v)
                }
                NeonSlider {
                    width: parent.width; text: "Bass-Puls"; visible: parent.isMedia
                    from: 0; to: 2; value: panel.pv("audioPulse", 0)
                    format: function(v) { return Math.round(v * 100) + " %" }
                    onMoved: (v) => lwe.setParam(panel.wid, "audioPulse", v)
                }
                Toggle {
                    width: parent.width; visible: panel.wp && panel.wp.type === "video"
                    text: "Ton abspielen"; checked: !panel.pv("muted", true)
                    onToggled: (v) => lwe.setParam(panel.wid, "muted", !v)
                }
                NeonSlider {
                    width: parent.width; text: "Lautstärke"; visible: panel.wp && panel.wp.type === "video" && !panel.pv("muted", true)
                    from: 0; to: 1; value: panel.pv("volume", 0.5)
                    format: function(v) { return Math.round(v * 100) + " %" }
                    onMoved: (v) => lwe.setParam(panel.wid, "volume", v)
                }
                Flow {
                    width: parent.width; spacing: 8; visible: parent.isMedia
                    Repeater {
                        model: [["crop", "Füllen"], ["fit", "Einpassen"], ["stretch", "Strecken"]]
                        Chip { text: modelData[1]; checked: panel.pv("fill", "crop") === modelData[0]; onClicked: lwe.setParam(panel.wid, "fill", modelData[0]) }
                    }
                }
            }

            // manage
            Flow {
                width: parent.width
                spacing: 8
                visible: panel.wp !== null
                NeonButton { text: "Ordner"; icon: "folder"; onClicked: lwe.openFolder(panel.wid) }
                NeonButton {
                    text: "Umbenennen"; icon: "edit"; visible: panel.wp && !panel.wp.builtin
                    onClicked: { renameField.text = panel.wp.title; tagField.text = panel.wp.tags.join(", "); renameBox.visible = true }
                }
                NeonButton {
                    text: confirmDelete ? "Wirklich löschen?" : "Löschen"; icon: "trash"; danger: true
                    visible: panel.wp && !panel.wp.builtin
                    property bool confirmDelete: false
                    onClicked: {
                        if (!confirmDelete) { confirmDelete = true; confirmTimer.restart(); return }
                        var id = panel.wid
                        panel.closeRequested()
                        lwe.removeWallpaper(id)
                    }
                    Timer { id: confirmTimer; interval: 3000; onTriggered: parent.confirmDelete = false }
                }
            }
            Glass {
                id: renameBox
                visible: false
                width: parent.width
                height: renameCol.implicitHeight + 24
                Column {
                    id: renameCol
                    anchors { fill: parent; margins: 12 }
                    spacing: 8
                    Text { text: "Titel"; color: Theme.textDim; font.family: Theme.font; font.pixelSize: 12 }
                    TextField { id: renameField; width: parent.width; color: Theme.text; background: Rectangle { radius: 8; color: Theme.glass; border.color: Theme.border } }
                    Text { text: "Tags (Komma-getrennt)"; color: Theme.textDim; font.family: Theme.font; font.pixelSize: 12 }
                    TextField { id: tagField; width: parent.width; color: Theme.text; background: Rectangle { radius: 8; color: Theme.glass; border.color: Theme.border } }
                    Row {
                        spacing: 8
                        NeonButton { text: "Speichern"; primary: true; onClicked: { lwe.renameWallpaper(panel.wid, renameField.text, tagField.text); renameBox.visible = false } }
                        NeonButton { text: "Abbrechen"; onClicked: renameBox.visible = false }
                    }
                }
            }
        }
    }
}
