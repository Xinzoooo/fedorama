import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1440; height: 900
    minimumWidth: 1060; minimumHeight: 680
    visible: true
    title: "Linux Wallpaper Engine"
    color: Theme.bg
    font.family: Theme.font

    property int page: 0          // 0 library, 1 favorites, 2 screens, 3 settings
    property string detailId: ""
    property string backdropId: lwe.screens.length ? lwe.screens[0].wallpaper : ""
    readonly property string backdropThumb: {
        var id = detailId || backdropId
        var all = lwe.wallpapers
        for (var i = 0; i < all.length; i++) if (all[i].id === id) return all[i].thumb
        return all.length ? all[0].thumb : ""
    }

    Connections {
        target: lwe
        function onToast(msg, kind) { toasts.push(msg, kind) }
    }

    // ------------------------------------------------------------ backdrop
    Item {
        id: backdrop
        anchors.fill: parent
        visible: Theme.backdrop
        Image {
            id: bgA
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: win.backdropThumb ? "file://" + win.backdropThumb : ""
            sourceSize.width: 480
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: bgA
            blurEnabled: true; blurMax: Theme.backdropBlur; blur: 1.0
            saturation: 0.25
            opacity: bgA.status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 600 } }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.alpha(Theme.bg, Theme.backdropDim) }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.bg, Math.min(1, Theme.backdropDim + 0.25)) }
            }
        }
        // two neon light blobs for depth
        Rectangle {
            width: parent.width * 0.6; height: width; radius: width / 2
            x: -width * 0.3; y: -height * 0.45
            color: Theme.alpha(Theme.accent, 0.16)
            layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 64 }
        }
        Rectangle {
            width: parent.width * 0.5; height: width; radius: width / 2
            x: parent.width - width * 0.6; y: parent.height - height * 0.5
            color: Theme.alpha(Theme.accent2, 0.10)
            layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 64 }
        }
    }

    // ------------------------------------------------------------ sidebar
    Glass {
        id: sidebar
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 16 }
        width: 236
        color: Theme.flat ? Theme.glass : Theme.alpha(Theme.bg, 0.45)

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
            spacing: 6
            Text {
                text: "Wallpaper Engine"
                leftPadding: 6; topPadding: 6; bottomPadding: 22
                font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold
                color: Theme.text
            }
            Repeater {
                model: [["grid", "Bibliothek"], ["heart", "Favoriten"], ["monitor", "Monitore"], ["settings", "Einstellungen"]]
                Item {
                    width: parent.width; height: 46
                    readonly property bool active: win.page === index
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: parent.active ? Theme.alpha(Theme.accent, 0.22) : (nav.containsMouse ? Theme.glassHover : "transparent")
                        border.width: parent.active ? 1 : 0
                        border.color: Theme.alpha(Theme.accent, 0.5)
                        Behavior on color { ColorAnimation { duration: Theme.anim } }
                    }
                    Rectangle {
                        width: 3; height: parent.active ? 22 : 0; radius: 2
                        anchors { left: parent.left; leftMargin: 2; verticalCenter: parent.verticalCenter }
                        color: Theme.accent2
                        Behavior on height { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack } }
                    }
                    Row {
                        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                        spacing: 14
                        Icon { name: modelData[0]; size: 20; color: parent.parent.active ? Theme.accent2 : Theme.textDim }
                        Text {
                            text: modelData[1]
                            color: parent.parent.active ? Theme.text : Theme.textDim
                            font.family: Theme.font; font.pixelSize: Theme.fontSize + 1; font.weight: parent.parent.active ? Font.DemiBold : Font.Normal
                        }
                    }
                    MouseArea { id: nav; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { win.page = index; if (index > 1) win.detailId = "" } }
                }
            }
        }

        // now playing / quick controls
        Glass {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
            height: 128
            color: Theme.alpha(Theme.bg, 0.4)
            Column {
                anchors { fill: parent; margins: 14 }
                spacing: 10
                Text {
                    text: lwe.paused ? "PAUSIERT" : "LÄUFT"
                    color: lwe.paused ? Theme.accent3 : Theme.ok
                    font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 2; font.weight: Font.Bold
                }
                Text {
                    width: parent.width
                    text: lwe.screens.length + (lwe.screens.length === 1 ? " Bildschirm" : " Bildschirme") + " · " + lwe.settings.fps + " FPS"
                    color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                }
                Row {
                    spacing: 8
                    NeonButton { width: 120; text: lwe.paused ? "Weiter" : "Pause"; icon: lwe.paused ? "play" : "pause"; checked: lwe.paused; tint: Theme.accent3; onClicked: lwe.togglePause() }
                    IconButton { icon: "next"; size: 40; tip: "Nächstes Wallpaper (alle Monitore)"; onClicked: lwe.nextWallpaper("") }
                }
            }
        }
    }

    // ------------------------------------------------------------ content
    Item {
        id: content
        anchors { left: sidebar.right; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 16; leftMargin: 24 }

        LibraryPage {
            id: lib
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 10 }
            width: win.detailId && win.page <= 1 ? parent.width - detail.width - 20 : parent.width
            Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
            visible: opacity > 0
            opacity: win.page <= 1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.anim } }
            favoritesOnly: win.page === 1
            selectedId: win.detailId
            onOpenDetail: (id) => win.detailId = (win.detailId === id ? "" : id)
        }
        // pages are only created while shown (no hidden previews/video decoders)
        Loader {
            anchors.fill: parent; anchors.topMargin: 10
            active: win.page === 2
            sourceComponent: ScreensPage {
                onChooseWallpaper: (screen) => { win.page = 0; toasts.push("Wähle ein Wallpaper und klicke im Detailbereich auf den Monitor " + screen + ".", "info") }
            }
        }
        Loader {
            anchors.fill: parent; anchors.topMargin: 10
            active: win.page === 3
            sourceComponent: SettingsPage {}
        }
        DetailPanel {
            id: detail
            anchors { top: parent.top; bottom: parent.bottom; topMargin: 10 }
            width: 420
            x: win.detailId && win.page <= 1 ? parent.width - width : parent.width + 40
            Behavior on x { NumberAnimation { duration: Theme.anim + 80; easing.type: Easing.OutCubic } }
            visible: x < parent.width
            wid: win.detailId
            onCloseRequested: win.detailId = ""
        }
    }

    Toasts {
        id: toasts
        anchors { right: parent.right; bottom: parent.bottom; margins: 24 }
    }
    Shortcut { sequence: "Escape"; onActivated: win.detailId = "" }
    Component.onCompleted: { page = lweStart.page; detailId = lweStart.detail }
    Shortcut { sequence: "Ctrl+Q"; onActivated: win.close() }
}
