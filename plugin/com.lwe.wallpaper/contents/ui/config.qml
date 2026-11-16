// Settings page shown in Plasma's "Configure Desktop and Wallpaper" dialog.
// The full library lives in the Linux Wallpaper Engine app.
// SPDX-License-Identifier: MIT
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property alias cfg_Fps: fps.value
    property alias cfg_PauseOnFullscreen: pauseFs.checked
    property alias cfg_PauseOnMaximized: pauseMax.checked
    property alias cfg_MouseEnabled: mouse.checked
    property alias cfg_AudioEnabled: audio.checked
    property string cfg_WallpaperId
    property string cfg_Kind
    property string cfg_Source
    property string cfg_Params
    property bool cfg_Paused
    property int cfg_BridgePort
    property int cfg_Transition

    QQC2.Label {
        Kirigami.FormData.label: "Aktuell:"
        text: page.cfg_WallpaperId ? page.cfg_WallpaperId : "–"
    }
    QQC2.Label {
        Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        wrapMode: Text.WordWrap
        opacity: 0.75
        text: "Wallpaper auswählen, importieren und Playlists verwalten: App „Linux Wallpaper Engine“ starten (Befehl: lwe)."
    }
    QQC2.SpinBox {
        id: fps
        Kirigami.FormData.label: "Max. FPS:"
        from: 5; to: 144
    }
    QQC2.CheckBox { id: pauseFs; Kirigami.FormData.label: "Pausieren:"; text: "bei Vollbild-Fenstern und Spielen" }
    QQC2.CheckBox { id: pauseMax; text: "bei maximierten Fenstern" }
    QQC2.CheckBox { id: mouse; Kirigami.FormData.label: "Interaktion:"; text: "Auf Maus reagieren" }
    QQC2.CheckBox { id: audio; text: "Auf Musik reagieren (Audio-Visualizer)" }
}
