import QtQuick
import QtQuick.Controls

Item {
    id: page
    readonly property var s: lwe.settings
    component Section: Glass {
        id: sec
        property string title
        property string icon
        default property alias content: inner.data
        width: parent ? parent.width : 400
        height: inner.implicitHeight + 74
        Row {
            x: 22; y: 20; spacing: 10
            Icon { name: sec.icon; size: 20; color: Theme.accent2; anchors.verticalCenter: parent.verticalCenter }
            Text { text: sec.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
        Column { id: inner; x: 22; y: 58; width: parent.width - 44; spacing: 14 }
    }

    Column {
        id: head
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 4
        Text { text: "Einstellungen"; color: Theme.text; font.family: Theme.font; font.pixelSize: 30; font.weight: Font.Bold }
        Text { text: "Gilt für alle Bildschirme. Änderungen wirken sofort."; color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
    }
    Flickable {
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; topMargin: 18 }
        contentHeight: col.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        Column {
            id: col
            width: Math.min(parent.width, 820)
            spacing: 16

            Section {
                title: "Leistung"; icon: "gauge"
                NeonSlider {
                    width: parent.width; text: "Maximale Bildrate (Shader & Partikel)"
                    from: 10; to: 144; stepSize: 1; value: page.s.fps
                    format: function(v) { return Math.round(v) + " FPS" }
                    onMoved: (v) => fpsTimer.restartWith(Math.round(v))
                    Timer { id: fpsTimer; interval: 350; property int v: 30; function restartWith(x) { v = x; restart() } onTriggered: lwe.setGlobal("fps", v) }
                }
                Toggle { width: parent.width; text: "Bei Vollbild-Fenstern und Spielen pausieren"; hint: "Pro Monitor – nur der Bildschirm mit dem Vollbild-Fenster pausiert."; checked: page.s.pauseOnFullscreen; onToggled: (v) => lwe.setGlobal("pauseOnFullscreen", v) }
                Toggle { width: parent.width; text: "Bei maximierten Fenstern pausieren"; hint: "Spart Strom, wenn der Desktop ohnehin verdeckt ist."; checked: page.s.pauseOnMaximized; onToggled: (v) => lwe.setGlobal("pauseOnMaximized", v) }
                NeonSlider {
                    width: parent.width; text: "Überblendung beim Wechsel"
                    from: 0; to: 3000; stepSize: 100; value: page.s.transition
                    format: function(v) { return v < 50 ? "aus" : (v / 1000).toFixed(1) + " s" }
                    onMoved: (v) => lwe.setGlobal("transition", Math.round(v))
                }
            }
            Section {
                title: "Interaktion"; icon: "mouse"
                Toggle { width: parent.width; text: "Auf die Maus reagieren"; hint: "Parallaxe und Effekte folgen dem Mauszeiger (auch unter Fenstern)."; checked: page.s.mouse; onToggled: (v) => lwe.setGlobal("mouse", v) }
                Toggle {
                    width: parent.width; text: "Auf Musik reagieren (Audio-Visualizer)"
                    hint: page.s.audioAvailable ? "Analysiert lokal, was gerade abgespielt wird. Nichts wird aufgenommen oder gespeichert." : "Nicht verfügbar: parec fehlt (Paket pulseaudio-utils)."
                    checked: page.s.audio; onToggled: (v) => lwe.setGlobal("audio", v)
                }
            }
            Section {
                title: "Aussehen"; icon: "palette"
                Flow {
                    width: parent.width; spacing: 8
                    Repeater {
                        model: lwe.themes
                        Chip { text: modelData.name; checked: page.s.theme === modelData.id; onClicked: lwe.setGlobal("theme", modelData.id) }
                    }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    text: "Eigene Themes: JSON-Datei nach " + lwe.themesDir + " kopieren (Vorlage: eines der mitgelieferten Themes)."
                    color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                }
            }
            Section {
                title: "System"; icon: "power"
                Toggle { width: parent.width; text: "Beim Anmelden automatisch starten"; hint: "Startet im Hintergrund mit Tray-Symbol."; checked: page.s.autostart; onToggled: (v) => lwe.setGlobal("autostart", v) }
                Row {
                    spacing: 10
                    NeonButton { text: "Bibliothek neu laden"; icon: "refresh"; onClicked: lwe.refresh() }
                    NeonButton { text: "Plasma-Standardhintergrund"; icon: "close"; danger: true; onClicked: lwe.restoreDefault() }
                }
            }
        }
    }
}
