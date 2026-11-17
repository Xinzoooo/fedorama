// The app window: frameless, ambient frame, one wallpaper live on the stage.
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Window

ApplicationWindow {
    id: win
    width: 1180; height: 740
    minimumWidth: 820; minimumHeight: 540
    visible: true
    title: "Linux Wallpaper Engine"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "#0a0a0a"
    font.family: Theme.font

    // ------------------------------------------------------------ state
    property var visibleList: []
    property string currentId: ""
    property int lastIndex: 0
    readonly property int index: indexOf(currentId)
    readonly property var current: index >= 0 ? visibleList[index] : null
    property string panel: ""               // "" | all | search | adjust | settings
    property bool idle: false
    property bool justApplied: false
    readonly property bool active: visible && visibility !== Window.Minimized
                                   && Qt.application.state === Qt.ApplicationActive

    function indexOf(id) {
        for (var i = 0; i < visibleList.length; i++) if (visibleList[i].id === id) return i
        return -1
    }
    function rebuild() {
        visibleList = lwe.wallpapers.filter(function(w) { return !w.hidden })
        if (visibleList.length && indexOf(currentId) < 0)       // current got hidden or removed
            currentId = visibleList[Math.min(lastIndex, visibleList.length - 1)].id
    }
    function startIndex() {
        var running = lwe.screens.length ? lwe.screens[0].wallpaper : ""
        return Math.max(0, indexOf(running))
    }
    function step(d) {
        var n = visibleList.length
        if (!n) return
        show(visibleList[((index < 0 ? 0 : index) + d + n) % n].id)
    }
    function show(id) { currentId = id; lastIndex = Math.max(0, indexOf(id)); wake() }
    function togglePanel(name) { panel = panel === name ? "" : name; wake() }
    function applyCurrent() {
        if (current && lwe.applyCurrent(current.id)) { justApplied = true; appliedTimer.restart() }
    }
    function hideCurrent() {
        if (!current || visibleList.length < 2) return
        lastIndex = index
        lwe.toggleHidden(current.id)
    }
    function wake() { idle = false; idleTimer.restart() }

    Connections {
        target: lwe
        function onItemsChanged() { win.rebuild() }
        function onToast(msg, kind) { toasts.push(msg, kind) }
    }
    Component.onCompleted: {
        rebuild()
        if (visibleList.length) show(visibleList[startIndex()].id)
    }
    Timer { id: idleTimer; interval: 2500; onTriggered: win.idle = win.panel === "" }
    Timer { id: appliedTimer; interval: 1400; onTriggered: win.justApplied = false }
    onPanelChanged: if (panel !== "") idle = false

    FontLoader { source: "fonts/InterTight.ttf" }
    FontLoader { source: "fonts/JetBrainsMono.ttf" }

    // ------------------------------------------------------------ ambient frame
    // blurred still of the current wallpaper (never the live shader: costs nothing per frame)
    Item {
        id: ambient
        anchors.fill: parent
        anchors.margins: -40
        visible: false
        property string src: win.current && win.current.thumb ? "file://" + win.current.thumb : ""
        property bool flip: false
        onSrcChanged: { flip = !flip; (flip ? ambA : ambB).source = src }
        Image { id: ambA; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 320; asynchronous: true
                opacity: ambient.flip ? 1 : 0; Behavior on opacity { NumberAnimation { duration: Theme.slow } } }
        Image { id: ambB; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 320; asynchronous: true
                opacity: ambient.flip ? 0 : 1; Behavior on opacity { NumberAnimation { duration: Theme.slow } } }
    }
    MultiEffect {
        anchors.fill: ambient
        source: ambient
        visible: ambient.src !== ""
        blurEnabled: true; blur: 1.0; blurMax: 64
        saturation: 0.5
        brightness: -0.45
    }

    // ------------------------------------------------------------ stage
    Item {
        id: stageBox
        anchors.fill: parent
        anchors.margins: 9

        Item {
            id: stageClip
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect { maskEnabled: true; maskSource: stageMask }
            Rectangle { anchors.fill: parent; color: "#000000" }
            Stage {
                anchors.fill: parent
                wp: win.current
                running: win.active
                fps: lwe.settings.fps
            }
        }
        Rectangle {
            id: stageMask
            anchors.fill: parent
            radius: 13
            visible: false
            layer.enabled: true
        }
        Rectangle {                                  // fine inner edge
            anchors.fill: parent
            radius: 13
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.07)
        }

        HoverHandler { id: hover; onPointChanged: win.wake() }
        DragHandler {                                // drag the free stage to move the window
            target: null
            grabPermissions: PointerHandler.TakeOverForbidden
            onActiveChanged: if (active) win.startSystemMove()
        }
        WheelHandler {
            enabled: win.panel === ""
            property double last: 0
            onWheel: (e) => {
                var now = Date.now()
                if (now - last < 350) return
                last = now
                win.step(e.angleDelta.y < 0 ? 1 : -1)
            }
        }

        Bar {
            id: bar
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }
            z: 5
            opacity: win.idle ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            transform: Translate { y: win.idle ? 10 : 0; Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } } }
        }

        // window buttons: only while the mouse is over the window
        Row {
            anchors { top: parent.top; right: parent.right; margins: 12 }
            spacing: 4
            z: 10
            opacity: hover.hovered && !win.idle ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.anim } }
            WinButton { icon: "minus"; tip: "Minimieren"; onClicked: win.showMinimized() }
            WinButton { icon: "close"; tip: "In den Tray"; danger: true; onClicked: win.close() }
        }
    }

    component WinButton: Rectangle {
        id: wb
        property string icon
        property string tip
        property bool danger: false
        signal clicked()
        width: 28; height: 28; radius: 8
        color: ma.containsMouse ? (danger ? Theme.danger : Theme.text) : Qt.rgba(0, 0, 0, 0.5)
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Icon { anchors.centerIn: parent; name: wb.icon; size: 15; color: ma.containsMouse && !wb.danger ? "#000000" : Theme.text }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wb.clicked() }
        ToolTip.visible: ma.containsMouse; ToolTip.text: tip; ToolTip.delay: 600
    }

    // ------------------------------------------------------------ resize edges (the 9 px frame)
    component Edge: MouseArea {
        property int edges
        hoverEnabled: true
        onPressed: win.startSystemResize(edges)
    }
    Edge { edges: Qt.LeftEdge; anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 16; bottomMargin: 16 } width: 9; cursorShape: Qt.SizeHorCursor }
    Edge { edges: Qt.RightEdge; anchors { right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: 16; bottomMargin: 16 } width: 9; cursorShape: Qt.SizeHorCursor }
    Edge { edges: Qt.TopEdge; anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 } height: 9; cursorShape: Qt.SizeVerCursor }
    Edge { edges: Qt.BottomEdge; anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 } height: 9; cursorShape: Qt.SizeVerCursor }
    Edge { edges: Qt.LeftEdge | Qt.TopEdge; width: 16; height: 16; cursorShape: Qt.SizeFDiagCursor }
    Edge { edges: Qt.RightEdge | Qt.TopEdge; x: parent.width - 16; width: 16; height: 16; cursorShape: Qt.SizeBDiagCursor }
    Edge { edges: Qt.LeftEdge | Qt.BottomEdge; y: parent.height - 16; width: 16; height: 16; cursorShape: Qt.SizeBDiagCursor }
    Edge { edges: Qt.RightEdge | Qt.BottomEdge; x: parent.width - 16; y: parent.height - 16; width: 16; height: 16; cursorShape: Qt.SizeFDiagCursor }

    // ------------------------------------------------------------ input
    DropArea {
        anchors.fill: parent
        onDropped: (drop) => { if (drop.hasUrls) lwe.importUrls(drop.urls) }
    }
    readonly property bool typing: panel === "search"
    Shortcut { sequence: "Left"; enabled: !win.typing; onActivated: win.step(-1) }
    Shortcut { sequence: "Right"; enabled: !win.typing; onActivated: win.step(1) }
    Shortcut { sequences: ["Return", "Enter"]; enabled: !win.typing; onActivated: win.applyCurrent() }
    Shortcut { sequence: "Space"; enabled: !win.typing; onActivated: win.togglePanel("all") }
    Shortcut { sequence: "/"; enabled: !win.typing; onActivated: win.togglePanel("search") }
    Shortcut { sequence: "A"; enabled: !win.typing; onActivated: win.togglePanel("adjust") }
    Shortcut { sequence: "F"; enabled: !win.typing; onActivated: if (win.current) lwe.toggleFavorite(win.current.id) }
    Shortcut { sequence: "Delete"; enabled: !win.typing; onActivated: win.hideCurrent() }
    Shortcut { sequence: "Escape"; onActivated: win.panel = "" }
    Shortcut { sequence: "Ctrl+Q"; onActivated: Qt.quit() }

    Toasts {
        id: toasts
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 22 }
        width: parent.width
    }
}
