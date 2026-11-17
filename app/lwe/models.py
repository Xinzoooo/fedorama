"""Qt list model of the library. Changing one wallpaper (favourite, params) only
updates its row instead of rebuilding the whole grid."""
from __future__ import annotations

from PySide6.QtCore import QAbstractListModel, QByteArray, QModelIndex, Qt

ROLES = ["wid", "title", "type", "thumb", "source", "favorite", "params", "tags",
         "description", "author", "license", "builtin", "error", "dir"]


class WallpaperModel(QAbstractListModel):
    def __init__(self, engine):
        super().__init__()
        self.engine = engine
        self.rows: list[dict] = []
        self._roles = {Qt.UserRole + i: r for i, r in enumerate(ROLES)}

    def roleNames(self):
        return {k: QByteArray(v.encode()) for k, v in self._roles.items()}

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self.rows)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or index.row() >= len(self.rows):
            return None
        name = self._roles.get(role)
        if name is None:
            return None
        return self.rows[index.row()]["id" if name == "wid" else name]

    def reload(self):
        self.beginResetModel()
        self.rows = self.engine.wallpaper_dicts()
        self.endResetModel()

    def update(self, wid: str):
        for i, r in enumerate(self.rows):
            if r["id"] == wid:
                self.rows[i] = self.engine.wallpaper_dict(wid)
                idx = self.index(i)
                self.dataChanged.emit(idx, idx)
                return
