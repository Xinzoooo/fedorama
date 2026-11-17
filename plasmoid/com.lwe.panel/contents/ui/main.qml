/*
 * Fedorama – panel widget
 * SPDX-License-Identifier: MIT
 *
 * Talks to the running app through its local bridge (127.0.0.1:47811):
 *   GET  /status          current wallpapers, pause state, preset, favorites
 *   POST /cmd?cmd=...     pause/resume/toggle/next/set/quality/show
 * Both need the header "X-LWE: 1".
 *
 * Panel icon: left click = popup, middle click = pause, mouse wheel = next wallpaper.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string base: "http://127.0.0.1:47811"
    property bool online: false
    property var st: ({})
    readonly property bool paused: st.paused === true
    readonly property var current: {
        var s = st.screens || []
        for (var i = 0; i < s.length; i++) if (s[i].wallpaper) return s[i].wallpaper
        return null
    }
    readonly property int activeScreens: {
        var s = st.screens || [], n = 0
        for (var i = 0; i < s.length; i++) if (s[i].wallpaper) n++
        return n
    }

    Plasmoid.icon: "lwe"
    Plasmoid.status: online ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    toolTipMainText: "Fedorama"
    toolTipSubText: !online ? "App läuft nicht"
                  : (current ? current.title : "Kein Wallpaper aktiv") + (paused ? " · pausiert" : "")
                    + "\nMittelklick: Pause · Mausrad: Nächstes"

    // ------------------------------------------------------------ bridge
    function poll() {
        var x = new XMLHttpRequest()
        x.onreadystatechange = function() {
            if (x.readyState !== XMLHttpRequest.DONE) return
            if (x.status === 200) {
                try { root.st = JSON.parse(x.responseText); root.online = true } catch (e) { root.online = false }
            } else {
                root.online = false
            }
        }
        x.open("GET", base + "/status")
        x.setRequestHeader("X-LWE", "1")
        x.send()
    }
    function cmd(c, args) {
        var q = "cmd=" + encodeURIComponent(c)
        for (var k in (args || {})) q += "&" + k + "=" + encodeURIComponent(args[k])
        var x = new XMLHttpRequest()
        x.onreadystatechange = function() { if (x.readyState === XMLHttpRequest.DONE) pollSoon.restart() }
        x.open("POST", base + "/cmd?" + q)
        x.setRequestHeader("X-LWE", "1")
        x.send()
        if (c === "toggle") root.st = Object.assign({}, root.st, { paused: !root.paused })   // instant feedback
    }
    Timer { interval: root.expanded ? 1000 : 4000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.poll() }
    Timer { id: pollSoon; interval: 250; onTriggered: root.poll() }

    P5Support.DataSource {
        id: shell
        engine: "executable"
        onNewData: (source) => disconnectSource(source)
    }
    function startApp(window) {
        shell.connectSource("setsid -f \"$HOME/.local/bin/lwe\"" + (window ? "" : " --tray") + " >/dev/null 2>&1")
        pollSoon.interval = 2500; pollSoon.restart()
    }

    // ------------------------------------------------------------ panel icon
    compactRepresentation: MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        onClicked: (m) => {
            if (m.button === Qt.MiddleButton) { if (root.online) root.cmd("toggle") }
            else root.expanded = !root.expanded
        }
        onWheel: (w) => { if (root.online && w.angleDelta.y < 0) root.cmd("next") }
        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: parent.containsMouse
            opacity: root.online && !root.paused ? 1 : 0.45
        }
        // small pause badge
        Rectangle {
            visible: root.online && root.paused
            anchors { right: parent.right; bottom: parent.bottom }
            width: Math.round(parent.height * 0.42); height: width; radius: width / 2
            color: Kirigami.Theme.backgroundColor
            Kirigami.Icon { anchors.fill: parent; anchors.margins: 1; source: "media-playback-pause" }
        }
    }

    // ------------------------------------------------------------ popup
    fullRepresentation: PlasmaExtras.Representation {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: col.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        collapseMarginsHint: true

        // app not running
        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 2
            visible: !root.online
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Icon { source: "lwe"; Layout.alignment: Qt.AlignHCenter; implicitWidth: Kirigami.Units.iconSizes.huge; implicitHeight: implicitWidth; opacity: 0.6 }
            PC3.Label { text: "Fedorama läuft nicht"; Layout.alignment: Qt.AlignHCenter }
            PC3.Button { text: "Starten"; icon.name: "media-playback-start"; Layout.alignment: Qt.AlignHCenter; onClicked: root.startApp(false) }
        }

        ColumnLayout {
            id: col
            visible: root.online
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Kirigami.Units.largeSpacing }
            spacing: Kirigami.Units.largeSpacing

            // --- now playing
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(width * 9 / 16)
                Rectangle {
                    id: frame
                    anchors.fill: parent
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(0, 0, 0, 0.35)
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: root.current && root.current.thumb ? "file://" + root.current.thumb : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 640
                        asynchronous: true
                        opacity: root.paused ? 0.5 : 1
                        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration } }
                    }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: parent.height * 0.45
                        gradient: Gradient {
                            GradientStop { position: 0; color: "transparent" }
                            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.75) }
                        }
                    }
                    Column {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Kirigami.Units.largeSpacing }
                        PC3.Label {
                            width: parent.width; elide: Text.ElideRight
                            text: root.current ? root.current.title : "Kein Wallpaper aktiv"
                            color: "white"; font.weight: Font.DemiBold
                        }
                        PC3.Label {
                            text: (root.paused ? "Pausiert · " : "") + root.activeScreens + (root.activeScreens === 1 ? " Monitor" : " Monitore")
                            color: Qt.rgba(1, 1, 1, 0.75); font: Kirigami.Theme.smallFont
                        }
                    }
                    Kirigami.Icon {
                        visible: root.paused
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.large; height: width
                        source: "media-playback-pause"; color: "white"; isMask: true
                    }
                }
            }

            // --- controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing
                PC3.ToolButton { icon.name: root.paused ? "media-playback-start" : "media-playback-pause"; text: root.paused ? "Fortsetzen" : "Pausieren"; display: PC3.AbstractButton.IconOnly; PC3.ToolTip.text: text; PC3.ToolTip.visible: hovered; onClicked: root.cmd("toggle") }
                PC3.ToolButton { icon.name: "media-skip-forward"; text: "Nächstes Wallpaper"; display: PC3.AbstractButton.IconOnly; PC3.ToolTip.text: text; PC3.ToolTip.visible: hovered; onClicked: root.cmd("next") }
                PC3.ToolButton { icon.name: "view-grid"; text: "Bibliothek öffnen"; display: PC3.AbstractButton.IconOnly; PC3.ToolTip.text: text; PC3.ToolTip.visible: hovered; onClicked: { root.cmd("show"); root.expanded = false } }
            }

            // --- performance preset
            PlasmaExtras.Heading { level: 5; text: "Leistungsstufe"; opacity: 0.7 }
            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: root.st.presets || []
                    PC3.Button {
                        text: modelData.name
                        checkable: true
                        checked: root.st.quality === modelData.id
                        flat: !checked
                        onClicked: root.cmd("quality", { preset: modelData.id })
                    }
                }
            }

            // --- favorites
            PlasmaExtras.Heading { level: 5; text: "Favoriten"; opacity: 0.7 }
            PC3.Label {
                visible: !(root.st.favorites || []).length
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: "Noch keine Favoriten – markiere Wallpaper in der App mit dem Herz."
                opacity: 0.6; font: Kirigami.Theme.smallFont
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: Kirigami.Units.smallSpacing; rowSpacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: root.st.favorites || []
                    Item {
                        id: fav
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(width * 9 / 16)
                        readonly property bool isCurrent: root.current && root.current.id === modelData.id
                        Rectangle {
                            anchors.fill: parent
                            radius: Kirigami.Units.cornerRadius
                            color: Qt.rgba(0, 0, 0, 0.3)
                            clip: true
                            border.width: fav.isCurrent || favMa.containsMouse ? 2 : 0
                            border.color: Kirigami.Theme.highlightColor
                            Image {
                                anchors.fill: parent; anchors.margins: parent.border.width
                                source: modelData.thumb ? "file://" + modelData.thumb : ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 240
                                asynchronous: true
                            }
                        }
                        MouseArea {
                            id: favMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.cmd("set", { id: modelData.id })
                        }
                        PC3.ToolTip.text: modelData.title
                        PC3.ToolTip.visible: favMa.containsMouse
                    }
                }
            }
        }
    }
}
