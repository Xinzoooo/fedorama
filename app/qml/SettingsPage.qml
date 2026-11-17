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
            Text { text: sec.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
        }
        Column { id: inner; x: 22; y: 58; width: parent.width - 44; spacing: 14 }
    }

    Column {
        id: head
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 4
        Text { text: "Einstellungen"; color: Theme.text; font.family: Theme.font; font.pixelSize: 20; font.weight: Font.Medium }
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
                Text { text: "Leistungsstufe"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize }
                Grid {
                    id: presetGrid
                    width: parent.width
                    columns: width > 640 ? 5 : (width > 380 ? 3 : 2)
                    spacing: 8
                    Repeater {
                        model: lwe.qualityPresets
                        Rectangle {
                            id: card
                            readonly property bool checked: page.s.quality === modelData.id
                            width: (presetGrid.width - presetGrid.spacing * (presetGrid.columns - 1)) / presetGrid.columns
                            height: 84
                            radius: Theme.radiusSmall
                            color: checked ? Theme.alpha(Theme.accent, 0.3) : (cardMa.containsMouse ? Theme.glassHover : Theme.glass)
                            border.width: 1
                            border.color: checked ? Theme.alpha(Theme.accent, 0.9) : Theme.border
                            Behavior on color { ColorAnimation { duration: Theme.anim } }
                            Column {
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                                spacing: 3
                                Row {
                                    spacing: 2
                                    // level bars: 1..5
                                    Repeater {
                                        model: 5
                                        Item {
                                            width: 6; height: 12
                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                width: 6; height: 4 + index * 2; radius: 1
                                                color: index <= card.levelIndex ? Theme.accent2 : Theme.border
                                            }
                                        }
                                    }
                                }
                                Text { text: modelData.name; color: card.checked ? "#ffffff" : Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.Medium }
                                Text { width: parent.width; text: modelData.hint; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                            }
                            readonly property int levelIndex: index
                            MouseArea { id: cardMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lwe.setQuality(modelData.id) }
                        }
                    }
                }
                Text {
                    visible: page.s.quality === "custom"
                    text: "Eigene Einstellung – wähle eine Stufe, um zurückzusetzen."
                    color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                }
                NeonSlider {
                    width: parent.width; text: "Maximale Bildrate (Shader & Partikel)"
                    from: 10; to: 144; stepSize: 1; value: page.s.fps
                    format: function(v) { return Math.round(v) + " FPS" }
                    onMoved: (v) => fpsTimer.restartWith(Math.round(v))
                    Timer { id: fpsTimer; interval: 350; property int v: 30; function restartWith(x) { v = x; restart() } onTriggered: lwe.setGlobal("fps", v) }
                }
                Toggle { width: parent.width; text: "Bei Vollbild-Fenstern und Spielen pausieren"; hint: "Pro Monitor – auch bei randlosen Fenstern, die den ganzen Bildschirm bedecken."; checked: page.s.pauseOnFullscreen; onToggled: (v) => lwe.setGlobal("pauseOnFullscreen", v) }
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
                Toggle { width: parent.width; text: "Auch auf dem Sperrbildschirm"; hint: "Zeigt das Wallpaper des ersten Monitors beim Sperren."; checked: page.s.lockscreen; onToggled: (v) => lwe.setGlobal("lockscreen", v) }
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
