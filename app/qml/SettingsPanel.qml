// "Einstellungen": performance, target monitor, behaviour, automatic change, hidden wallpapers, own content.
import QtQuick
import QtQuick.Dialogs

Flickable {
    id: panel
    implicitHeight: col.implicitHeight
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property var s: lwe.settings
    readonly property int cols: Math.max(1, Math.floor((width + 36) / (280 + 36)))
    readonly property real colW: (width - (cols - 1) * 36) / cols
    readonly property var hidden: lwe.wallpapers.filter(function(w) { return w.hidden })
    // screens are sorted left to right; name them by position when that is unambiguous
    function screenLabel(i) {
        var n = lwe.screens.length
        if (n === 2) return ["Links", "Rechts"][i]
        if (n === 3) return ["Links", "Mitte", "Rechts"][i]
        return lwe.screens[i].name
    }
    property string playlistScreen: lwe.screens.length ? lwe.screens[0].name : ""

    component Heading: Text {
        color: "#777777"
        font { family: Theme.mono; pixelSize: 11; letterSpacing: 1.1; capitalization: Font.AllUppercase }
        bottomPadding: 4
    }
    component Note: Text {
        width: parent ? parent.width : 100
        wrapMode: Text.WordWrap
        color: Theme.textDim
        font { family: Theme.font; pixelSize: Theme.fontSize }
    }
    component ScreenPills: Flow {
        id: sp
        property string value
        property string prefix
        property bool withAll: false
        signal picked(string name)
        spacing: 4
        Pill { visible: sp.withAll; objectName: sp.prefix + "all"; text: lwe.screens.length === 3 ? "Alle drei" : "Alle"; checked: sp.value === ""; onClicked: sp.picked("") }
        Repeater {
            model: lwe.screens
            Pill { objectName: sp.prefix + modelData.name; text: panel.screenLabel(index); checked: sp.value === modelData.name; onClicked: sp.picked(modelData.name) }
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 26

        Row {
            spacing: 12
            Text { text: "Einstellungen"; color: Theme.text; font { family: Theme.font; pixelSize: 24; weight: Font.ExtraBold; letterSpacing: -0.7 } anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Gilt für alle Bildschirme."; color: Theme.textDim; font { family: Theme.font; pixelSize: Theme.fontSize } anchors.verticalCenter: parent.verticalCenter }
        }

        Flow {
            width: parent.width
            spacing: 36

            // ---------------------------------------------------- performance + monitors
            Column {
                width: panel.colW
                spacing: 10
                Heading { text: "Leistung" }
                Row {
                    width: parent.width
                    spacing: 4
                    Repeater {
                        model: lwe.qualityPresets
                        Rectangle {
                            readonly property bool on: panel.s.quality === modelData.id
                            width: (parent.width - 16) / 5; height: 56
                            radius: 9
                            color: on ? Theme.text : (lvlMa.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                            border.color: on ? Theme.text : (lvlMa.containsMouse ? "#444444" : "#262626")
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                            Column {
                                anchors.centerIn: parent
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.fps; color: parent.parent.on ? "#000000" : Theme.text; font { family: Theme.mono; pixelSize: 15 } }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "FPS"; opacity: 0.6; color: parent.parent.on ? "#000000" : Theme.text; font { family: Theme.font; pixelSize: 10 } }
                            }
                            MouseArea { id: lvlMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lwe.setQuality(modelData.id) }
                        }
                    }
                }
                Note {
                    text: {
                        if (panel.s.quality === "custom") return "Eigene Einstellung – wähle eine Stufe, um zurückzusetzen."
                        var q = lwe.qualityPresets
                        for (var i = 0; i < q.length; i++) if (q[i].id === panel.s.quality) return q[i].name + " · " + q[i].hint
                        return ""
                    }
                }
                Item { width: 1; height: 8 }
                Heading { text: "Monitore" }
                Note { text: "Wohin „Anwenden“ das Wallpaper setzt." }
                ScreenPills {
                    width: parent.width
                    withAll: true
                    prefix: "target-"
                    value: panel.s.applyTarget
                    onPicked: (name) => lwe.setGlobal("applyTarget", name)
                }
            }

            // ---------------------------------------------------- behaviour
            Column {
                width: panel.colW
                spacing: 6
                Heading { text: "Verhalten" }
                Toggle { width: parent.width; text: "Bei Vollbild und Spielen pausieren"; hint: "Pro Monitor, auch bei randlosen Fenstern."; checked: panel.s.pauseOnFullscreen; onToggled: (v) => lwe.setGlobal("pauseOnFullscreen", v) }
                Toggle { width: parent.width; text: "Bei maximierten Fenstern pausieren"; checked: panel.s.pauseOnMaximized; onToggled: (v) => lwe.setGlobal("pauseOnMaximized", v) }
                Toggle { width: parent.width; text: "Auf die Maus reagieren"; checked: panel.s.mouse; onToggled: (v) => lwe.setGlobal("mouse", v) }
                Toggle {
                    width: parent.width; text: "Auf Musik reagieren"
                    hint: panel.s.audioAvailable ? "Wird lokal analysiert, nichts wird aufgenommen." : "Nicht verfügbar: parec fehlt (Paket pulseaudio-utils)."
                    enabled: !!panel.s.audioAvailable
                    checked: panel.s.audio; onToggled: (v) => lwe.setGlobal("audio", v)
                }
                Toggle { width: parent.width; text: "Auch auf dem Sperrbildschirm"; checked: panel.s.lockscreen; onToggled: (v) => lwe.setGlobal("lockscreen", v) }
                Toggle { width: parent.width; text: "Beim Anmelden starten"; checked: panel.s.autostart; onToggled: (v) => lwe.setGlobal("autostart", v) }
                Fader {
                    width: parent.width; text: "Überblendung beim Wechsel"
                    from: 0; to: 3000; stepSize: 100; value: panel.s.transition
                    format: function(v) { return v < 50 ? "aus" : (v / 1000).toFixed(1) + " s" }
                    onMoved: (v) => lwe.setGlobal("transition", Math.round(v))
                }
            }

            // ---------------------------------------------------- hidden + own content
            Column {
                width: panel.colW
                spacing: 10
                Heading { text: "Ausgeblendet" }
                Flow {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: panel.hidden
                        PickThumb { objectName: "unhide-" + modelData.id; wp: modelData; grey: true; onClicked: lwe.toggleHidden(modelData.id) }
                    }
                }
                Note { text: panel.hidden.length ? panel.hidden.length + " ausgeblendet · klicken zum Zurückholen" : "Nichts ausgeblendet. Was dir nicht gefällt: Entf." }
                Item { width: 1; height: 8 }
                Heading { text: "Eigene Inhalte" }
                TextButton { text: "Video, Bild oder Shader importieren"; icon: "plus"; onClicked: importDialog.open() }
                TextButton { text: "Plasma-Standardhintergrund"; icon: "reset"; onClicked: lwe.restoreDefault() }
            }
        }

        // ---------------------------------------------------- automatic change (playlists)
        Column {
            width: parent.width
            spacing: 10
            Heading { text: "Automatisch wechseln" }
            ScreenPills { width: parent.width; prefix: "playlist-screen-"; value: panel.playlistScreen; onPicked: (name) => panel.playlistScreen = name }
            PlaylistEditor { width: parent.width; screen: panel.playlistScreen }
        }
    }

    FileDialog {
        id: importDialog
        title: "Wallpaper importieren"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Wallpaper (*.mp4 *.webm *.mkv *.mov *.gif *.png *.jpg *.jpeg *.webp *.frag *.glsl *.json)", "Alle Dateien (*)"]
        onAccepted: lwe.importUrls(selectedFiles)
    }
}
