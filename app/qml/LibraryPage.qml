import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects

Item {
    id: page
    property bool favoritesOnly: false
    property string selectedId: ""
    property string search: ""
    property var activeTags: []
    property string typeFilter: ""
    signal openDetail(string id)

    function matches(w) {
        if (favoritesOnly && !w.favorite) return false
        if (typeFilter !== "" && w.type !== typeFilter) return false
        for (var i = 0; i < activeTags.length; i++)
            if (w.tags.indexOf(activeTags[i]) < 0) return false
        if (search !== "") {
            var s = search.toLowerCase()
            var hay = (w.title + " " + w.description + " " + w.tags.join(" ") + " " + w.type).toLowerCase()
            if (hay.indexOf(s) < 0) return false
        }
        return true
    }
    readonly property var filtered: {
        var out = []
        var all = lwe.wallpapers
        for (var i = 0; i < all.length; i++) if (matches(all[i])) out.push(all[i])
        return out
    }
    function toggleTag(t) {
        var a = activeTags.slice()
        var i = a.indexOf(t)
        if (i >= 0) a.splice(i, 1); else a.push(t)
        activeTags = a
    }

    // ------------------------------------------------------------ header
    Column {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 16
        Item {
            width: parent.width; height: 48
            Column {
                id: titleCol
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: page.favoritesOnly ? "Favoriten" : "Bibliothek"
                    color: Theme.text; font.family: Theme.font; font.pixelSize: 30; font.weight: Font.Bold
                }
                Text {
                    text: page.filtered.length + " von " + lwe.wallpapers.length + " Wallpapern"
                    color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                }
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 10
                Glass {
                    width: Math.max(150, Math.min(320, header.width - titleCol.width - importRow.width - 60))
                    height: 42; radius: 21
                    glowing: searchField.activeFocus
                    Icon { id: sIcon; name: "search"; size: 18; color: Theme.textDim; anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter } }
                    TextInput {
                        id: searchField
                        anchors { left: sIcon.right; right: clearBtn.left; leftMargin: 10; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize
                        selectionColor: Theme.accent; clip: true
                        onTextChanged: page.search = text
                        Text {
                            visible: !parent.text && !parent.activeFocus
                            text: "Suchen …  (Strg+F)"; color: Theme.textDim
                            font: parent.font
                        }
                    }
                    IconButton { id: clearBtn; icon: "close"; size: 28; visible: searchField.text !== ""; anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter } onClicked: searchField.text = "" }
                    Shortcut { sequence: "Ctrl+F"; onActivated: searchField.forceActiveFocus() }
                }
                Row {
                    id: importRow
                    spacing: 10
                    NeonButton { text: "Ordner"; icon: "folder-plus"; onClicked: folderDialog.open() }
                    NeonButton { text: "Importieren"; icon: "upload"; primary: true; onClicked: fileDialog.open() }
                }
            }
        }
        // filters
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: [["", "Alle"], ["shader", "Shader"], ["particles", "Partikel"], ["video", "Video"], ["gif", "GIF"], ["image", "Bild"]]
                Chip {
                    text: modelData[1]
                    checked: page.typeFilter === modelData[0]
                    onClicked: page.typeFilter = modelData[0]
                }
            }
            Rectangle { width: 1; height: 30; color: Theme.border }
            Repeater {
                model: lwe.allTags.slice(0, 8)
                Chip {
                    text: "#" + modelData
                    checked: page.activeTags.indexOf(modelData) >= 0
                    onClicked: page.toggleTag(modelData)
                }
            }
        }
    }

    // ------------------------------------------------------------ grid
    GridView {
        id: grid
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; topMargin: 14 }
        anchors.leftMargin: -8; anchors.rightMargin: -8
        clip: true
        readonly property int cols: Math.max(1, Math.floor(width / Theme.tileWidth))
        cellWidth: Math.floor(width / cols)
        cellHeight: Math.round(cellWidth * 9 / 16) + 4
        model: page.filtered
        cacheBuffer: 400
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        delegate: Tile {
            width: grid.cellWidth; height: grid.cellHeight
            wp: modelData
            selected: modelData.id === page.selectedId
            onClicked: page.openDetail(modelData.id)
            onFavoriteClicked: lwe.toggleFavorite(modelData.id)
        }
        // the model is rebuilt on every library change: keep the scroll position
        property real keepY: 0
        property bool restoring: false
        onContentYChanged: if (!restoring) keepY = contentY
        onModelChanged: {
            restoring = true
            Qt.callLater(function() {
                grid.contentY = Math.max(0, Math.min(grid.keepY, grid.contentHeight - grid.height))
                grid.restoring = false
            })
        }

        Column {
            anchors.centerIn: parent
            visible: page.filtered.length === 0
            spacing: 10
            Icon { name: page.favoritesOnly ? "heart" : "search"; size: 44; color: Theme.textDim; anchors.horizontalCenter: parent.horizontalCenter }
            Text {
                text: page.favoritesOnly ? "Noch keine Favoriten – klicke auf das Herz einer Kachel." : "Nichts gefunden."
                color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize + 1
            }
        }
    }

    // ------------------------------------------------------------ drag & drop
    DropArea {
        id: drop
        anchors.fill: parent
        keys: ["text/uri-list"]
        onDropped: (d) => { if (d.hasUrls) { lwe.importUrls(d.urls); d.acceptProposedAction() } }
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        visible: opacity > 0
        opacity: drop.containsDrag ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
        radius: Theme.radius
        color: Theme.alpha(Theme.bg, 0.75)
        border.width: 2
        border.color: Theme.accent2
        Column {
            anchors.centerIn: parent
            spacing: 12
            Icon { name: "upload"; size: 56; color: Theme.accent2; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: "Loslassen zum Importieren"; color: Theme.text; font.family: Theme.font; font.pixelSize: 24; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: "Videos (mp4, webm, mkv) · GIFs · Bilder · Shader (.frag/.glsl) · Ordner"; color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Wallpaper importieren"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Alle unterstützten (*.mp4 *.webm *.mkv *.mov *.m4v *.gif *.png *.jpg *.jpeg *.webp *.frag *.glsl)",
                      "Videos (*.mp4 *.webm *.mkv *.mov *.m4v)", "GIF (*.gif)", "Bilder (*.png *.jpg *.jpeg *.webp)",
                      "Shader (*.frag *.glsl)"]
        onAccepted: lwe.importUrls(selectedFiles)
    }
    FolderDialog {
        id: folderDialog
        title: "Ordner importieren"
        onAccepted: lwe.importUrls([selectedFolder])
    }
}
