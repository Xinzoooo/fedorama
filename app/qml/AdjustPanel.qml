// "Anpassen": the current wallpaper's parameters, live on the stage; info and file actions below.
import QtQuick

Flickable {
    id: panel
    implicitHeight: col.implicitHeight
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property var wp: win.current
    readonly property string wid: wp ? wp.id : ""
    readonly property var pr: wp ? wp.params : ({})
    readonly property bool isShader: !!wp && wp.type === "shader"
    readonly property bool isMedia: !!wp && (wp.type === "video" || wp.type === "gif" || wp.type === "image")
    readonly property bool isVideo: !!wp && wp.type === "video"
    readonly property int cols: Math.max(1, Math.floor((width + 36) / (260 + 36)))
    readonly property real colW: (width - (cols - 1) * 36) / cols
    function pv(k, fb) { return pr[k] === undefined ? fb : pr[k] }
    // forms belong to one wallpaper: stepping on closes them, so nothing acts on the next one
    onWidChanged: closeForms()
    function closeForms() { renameRow.visible = false; rename.focus = false; removeBtn.confirm = false }
    function pct(v) { return Math.round(v * 100) + " %" }

    Column {
        id: col
        width: parent.width
        spacing: 18

        Item {
            width: parent.width; height: 36
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                Text { text: "Anpassen"; color: Theme.text; font { family: Theme.font; pixelSize: 24; weight: Font.ExtraBold; letterSpacing: -0.7 } anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Wirkt sofort, auch in der Vorschau."; color: Theme.textDim; font { family: Theme.font; pixelSize: Theme.fontSize } anchors.verticalCenter: parent.verticalCenter }
            }
            TextButton { objectName: "resetParams"; anchors.right: parent.right; text: "Zurücksetzen"; icon: "reset"; onClicked: lwe.resetParams(panel.wid) }
        }

        Flow {
            width: parent.width
            spacing: 36
            Fader { objectName: "slider-brightness"; width: panel.colW; visible: panel.isShader; text: "Helligkeit"
                     from: 0.2; to: 1.6; value: panel.pv("brightness", 1.0); format: panel.pct
                     onMoved: (v) => lwe.setParam(panel.wid, "brightness", v) }
            Fader { objectName: "slider-hue"; width: panel.colW; visible: panel.isShader; text: "Farbton"
                     from: -180; to: 180; stepSize: 1; value: panel.pv("hue", 0); format: function(v) { return Math.round(v) + "°" }
                     onMoved: (v) => lwe.setParam(panel.wid, "hue", v) }
            Fader { objectName: "slider-saturation"; width: panel.colW; visible: panel.isShader; text: "Sättigung"
                     from: 0; to: 2; value: panel.pv("saturation", 1.0); format: panel.pct
                     onMoved: (v) => lwe.setParam(panel.wid, "saturation", v) }
            Fader { objectName: "slider-speed"; width: panel.colW; visible: !!panel.wp && panel.wp.type !== "image"; text: "Geschwindigkeit"
                     from: 0.1; to: 3; value: panel.pv("speed", 1.0); format: function(v) { return v.toFixed(1) + "×" }
                     onMoved: (v) => lwe.setParam(panel.wid, "speed", v) }
            Fader { objectName: "slider-renderScale"; width: panel.colW; visible: panel.isShader; text: "Render-Auflösung"
                     from: 0.25; to: 1; stepSize: 0.05; value: panel.pv("renderScale", 1.0); format: panel.pct
                     onMoved: (v) => lwe.setParam(panel.wid, "renderScale", v) }
            Fader { objectName: "slider-parallax"; width: panel.colW; visible: panel.isMedia; text: "Parallaxe (Maus)"
                     from: 0; to: 2; value: panel.pv("parallax", 0.6); format: panel.pct
                     onMoved: (v) => lwe.setParam(panel.wid, "parallax", v) }
            Fader { objectName: "slider-audioPulse"; width: panel.colW; visible: panel.isMedia; text: "Bass-Puls"
                     from: 0; to: 2; value: panel.pv("audioPulse", 0); format: panel.pct
                     onMoved: (v) => lwe.setParam(panel.wid, "audioPulse", v) }
            Toggle { width: panel.colW; height: 44; visible: panel.isVideo; text: "Ton abspielen"; checked: !panel.pv("muted", true)
                     onToggled: (v) => lwe.setParam(panel.wid, "muted", !v) }
            Fader { objectName: "slider-volume"; width: panel.colW; visible: panel.isVideo && !panel.pv("muted", true); text: "Lautstärke"
                     from: 0; to: 1; value: panel.pv("volume", 0.5); format: panel.pct
                     onMoved: (v) => lwe.setParam(panel.wid, "volume", v) }
            Row {
                visible: panel.isMedia
                spacing: 4
                Repeater {
                    model: [["crop", "Füllen"], ["fit", "Einpassen"], ["stretch", "Strecken"]]
                    Pill { text: modelData[1]; checked: panel.pv("fill", "crop") === modelData[0]; onClicked: lwe.setParam(panel.wid, "fill", modelData[0]) }
                }
            }
        }

        // ---------------------------------------------------- info and file actions
        Rectangle { width: parent.width; height: 1; color: Theme.line }
        Item {
            width: parent.width
            height: Math.max(info.implicitHeight, actions.height)
            Text {
                id: info
                anchors { left: parent.left; right: actions.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
                wrapMode: Text.Wrap
                text: !panel.wp ? "" : (panel.wp.error ? panel.wp.error
                      : [panel.wp.author, panel.wp.license ? "Lizenz: " + panel.wp.license : ""].filter(function(x) { return x }).join(" · "))
                color: panel.wp && panel.wp.error ? Theme.danger : Theme.textDim
                font { family: Theme.font; pixelSize: Theme.fontSize }
            }
            Row {
                id: actions
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 6
                visible: !!panel.wp && !panel.wp.builtin
                TextButton { text: "Ordner"; icon: "folder"; onClicked: lwe.openFolder(panel.wid) }
                TextButton { objectName: "renameButton"; text: "Umbenennen"; icon: "edit"; onClicked: { rename.text = panel.wp.title; renameRow.visible = true; rename.forceActiveFocus() } }
                TextButton {
                    id: removeBtn
                    objectName: "removeButton"
                    property bool confirm: false
                    text: confirm ? "Wirklich entfernen?" : "Entfernen"; icon: "trash"; danger: true
                    onClicked: { if (!confirm) { confirm = true; confirmTimer.restart(); return } lwe.removeWallpaper(panel.wid) }
                    Timer { id: confirmTimer; interval: 3000; onTriggered: parent.confirm = false }
                }
            }
        }
        Row {
            id: renameRow
            objectName: "renameRow"
            visible: false
            spacing: 8
            Rectangle {
                width: 320; height: 36; radius: 9
                color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.33)
                TextInput {
                    id: rename
                    objectName: "renameField"
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize }
                    onAccepted: save.clicked()
                    Keys.onEscapePressed: panel.closeForms()
                }
            }
            TextButton { id: save; objectName: "saveRename"; text: "Speichern"; icon: "check"
                         onClicked: { lwe.renameWallpaper(panel.wid, rename.text, panel.wp.tags.join(",")); panel.closeForms() } }
        }
    }
}
