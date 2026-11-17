"""System tray icon (StatusNotifierItem on Plasma)."""
from __future__ import annotations

from PySide6.QtGui import QAction, QIcon
from PySide6.QtWidgets import QMenu, QSystemTrayIcon

from . import paths


def app_icon() -> QIcon:
    for p in (paths.APP_DIR / "qml/lwe.svg", paths.DATA / "app/app/qml/lwe.svg"):
        if p.exists():
            return QIcon(str(p))
    return QIcon.fromTheme("preferences-desktop-wallpaper")


class Tray:
    def __init__(self, engine, show_window, quit_app):
        self.engine = engine
        self.icon = QSystemTrayIcon(app_icon())
        self.icon.setToolTip("Fedorama")
        self.menu = QMenu()
        self.show_window = show_window
        self.quit_app = quit_app
        self.menu.aboutToShow.connect(self.rebuild)
        self.icon.setContextMenu(self.menu)
        self.icon.activated.connect(self._activated)
        engine.stateChanged.connect(self._update_tip)
        self.rebuild()
        self.icon.show()
        self._update_tip()

    def _activated(self, reason):
        if reason in (QSystemTrayIcon.Trigger, QSystemTrayIcon.DoubleClick):
            self.show_window()
        elif reason == QSystemTrayIcon.MiddleClick:
            self.engine.togglePause()

    def _update_tip(self):
        self.icon.setToolTip("Fedorama – " + ("pausiert" if self.engine.paused else "läuft"))

    def _act(self, text, fn, icon=None):
        a = QAction(text, self.menu)
        if icon:
            a.setIcon(QIcon.fromTheme(icon))
        a.triggered.connect(fn)
        return a

    def rebuild(self):
        m = self.menu
        m.clear()
        e = self.engine
        m.addAction(self._act("Bibliothek öffnen", self.show_window, "view-grid"))
        m.addSeparator()
        if e.paused:
            m.addAction(self._act("Fortsetzen", lambda: e.setPaused(False), "media-playback-start"))
        else:
            m.addAction(self._act("Pausieren", lambda: e.setPaused(True), "media-playback-pause"))
        m.addAction(self._act("Nächstes Wallpaper", lambda: e.next(""), "media-skip-forward"))

        favs = [e.lib.get(i) for i in e.cfg.data["favorites"] if e.lib.get(i)]
        sub = m.addMenu(QIcon.fromTheme("emblem-favorite"), "Favoriten")
        if not favs:
            a = sub.addAction("Noch keine Favoriten")
            a.setEnabled(False)
        for w in favs:
            sub.addAction(self._act(w.title, lambda _=False, wid=w.id: e.apply_to(wid, "")))

        screens = e.screen_list()
        if len(screens) > 1:
            sm = m.addMenu(QIcon.fromTheme("video-display"), "Monitore")
            for s in screens:
                cur = e.lib.get(s["wallpaper"])
                sm.addAction(self._act(f"{s['name']}: Nächstes  ({cur.title if cur else '–'})",
                                       lambda _=False, n=s["name"]: e.next(n)))
        m.addSeparator()
        m.addAction(self._act("Beenden", self.quit_app, "application-exit"))
