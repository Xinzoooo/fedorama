import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects

Item {
    id: page
    property bool favoritesOnly: false
    property string selectedId: ""
    property string search: ""
    signal openDetail(string id)

    // filtering happens in Python (lwe.library is a proxy model): only changed tiles update
    onFavoritesOnlyChanged: lwe.library.favoritesOnly = favoritesOnly
    onSearchChanged: lwe.library.search = search
    Component.onCompleted: { lwe.library.favoritesOnly = favoritesOnly; lwe.library.search = search }

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
        model: lwe.library
        cacheBuffer: 400
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        delegate: Tile {
            width: grid.cellWidth; height: grid.cellHeight
            required property var model
            wp: ({ id: model.wid, title: model.title, type: model.type, thumb: model.thumb, source: model.source,
                   favorite: model.favorite, params: model.params, error: model.error, tags: model.tags })
            selected: model.wid === page.selectedId
            onClicked: page.openDetail(model.wid)
            onFavoriteClicked: lwe.toggleFavorite(model.wid)
        }

        Column {
            anchors.centerIn: parent
            visible: lwe.library.count === 0
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
