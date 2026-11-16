"""Qt list models for the library grid. Changing one wallpaper (favourite, params) only
updates its row instead of rebuilding the whole grid."""
from __future__ import annotations

from PySide6.QtCore import (Property, QAbstractListModel, QByteArray, QModelIndex,
                            QSortFilterProxyModel, Qt, Signal)

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


class FilterModel(QSortFilterProxyModel):
    searchChanged = Signal()
    favoritesOnlyChanged = Signal()
    countChanged = Signal()

    def __init__(self, source):
        super().__init__()
        self._search = ""
        self._fav = False
        self.setSourceModel(source)
        self.setDynamicSortFilter(True)
        for sig in (self.rowsInserted, self.rowsRemoved, self.modelReset, self.layoutChanged):
            sig.connect(self.countChanged)

    def filterAcceptsRow(self, row, parent):
        r = self.sourceModel().rows[row]
        if self._fav and not r["favorite"]:
            return False
        if self._search:
            hay = " ".join([r["title"], r["description"], r["type"], " ".join(r["tags"])]).lower()
            return all(word in hay for word in self._search.lower().split())
        return True

    def _get_search(self):
        return self._search

    def _set_search(self, v):
        if v != self._search:
            self._search = v
            self.invalidateFilter()
            self.searchChanged.emit()

    def _get_fav(self):
        return self._fav

    def _set_fav(self, v):
        if v != self._fav:
            self._fav = v
            self.invalidateFilter()
            self.favoritesOnlyChanged.emit()

    search = Property(str, _get_search, _set_search, notify=searchChanged)
    favoritesOnly = Property(bool, _get_fav, _set_fav, notify=favoritesOnlyChanged)
    count = Property(int, lambda self: self.rowCount(), notify=countChanged)
