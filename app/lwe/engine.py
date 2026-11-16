"""Central controller: library + config + Plasma + playlists + audio + bridge.
Exposed to QML as `engine`."""
from __future__ import annotations

import datetime as dt
import json
import random
import shutil
import subprocess
import threading
import time
from pathlib import Path

from PySide6.QtCore import Property, QObject, QTimer, QUrl, Signal, Slot
from PySide6.QtGui import QDesktopServices, QGuiApplication

from . import paths, plasma
from .audio import AudioAnalyzer
from .bridge import Bridge
from .config import Config
from .library import Library

AUTOSTART = Path.home() / ".config/autostart/lwe.desktop"
PARAM_KEYS = {"brightness", "hue", "saturation", "speed", "renderScale", "parallax", "fill",
              "muted", "volume", "audioPulse", "emitRate", "size", "color", "mouse", "mouseForce"}


def _hhmm(s: str, fallback: int) -> int:
    try:
        h, m = s.split(":")
        return int(h) * 60 + int(m)
    except (ValueError, AttributeError):
        return fallback


class Engine(QObject):
    libraryChanged = Signal()
    screensChanged = Signal()
    stateChanged = Signal()
    settingsChanged = Signal()
    themeChanged = Signal()
    toast = Signal(str, str)            # message, kind (info|error|ok)
    showWindowRequested = Signal()
    _optimized = Signal(str, bool, str)     # from worker thread -> main thread

    def __init__(self, headless: bool = False):
        super().__init__()
        paths.ensure()
        self.cfg = Config()
        self.lib = Library()
        self.audio = AudioAnalyzer()
        self.bridge = None
        self._plasma_screens: list[dict] = []
        self._last_change: dict[str, float] = {}
        self._theme = {}
        self._load_theme()
        self.headless = headless
        self.refresh_screens()
        for s in self.screen_list():            # rotation interval counts from app start
            self._last_change[s["name"]] = time.time()
        if not headless:
            self.bridge = Bridge(int(self.cfg.g["bridgePort"]), self.audio)
            if not self.bridge.start():
                self.toast.emit("Live-Daten-Port belegt – Maus/Audio deaktiviert", "error")
            self._sync_audio()
            self._timer = QTimer(self)
            self._timer.setInterval(20_000)
            self._timer.timeout.connect(self._tick_playlists)
            self._timer.start()
            self._optimized.connect(self._on_optimized)
            self._opt_busy = False
            QTimer.singleShot(8000, self.optimize_pending)
            app = QGuiApplication.instance()
            if app:
                app.screenAdded.connect(lambda *_: QTimer.singleShot(1500, self.refresh_screens))
                app.screenRemoved.connect(lambda *_: QTimer.singleShot(1500, self.refresh_screens))

    # ================================================================ screens
    def refresh_screens(self):
        try:
            self._plasma_screens = plasma.screens()
        except Exception as e:
            print("plasma screens:", e)
            self._plasma_screens = []
        self.screensChanged.emit()

    def _qt_screens(self) -> list[dict]:
        app = QGuiApplication.instance()
        out = []
        if app:
            for s in app.screens():
                g = s.geometry()
                label = " ".join(x for x in (s.manufacturer(), s.model()) if x).strip()
                out.append({"name": s.name(), "label": label or s.name(), "x": g.x(), "y": g.y(),
                            "w": g.width(), "h": g.height()})
        return out

    def screen_list(self) -> list[dict]:
        qt = self._qt_screens()
        res = []
        for ps in self._plasma_screens:
            match = next((q for q in qt if q["x"] == ps["x"] and q["y"] == ps["y"]), None)
            name = match["name"] if match else f"Bildschirm {ps['index'] + 1}"
            sc = self.cfg.data["screens"].get(name, {})
            res.append({
                "name": name, "label": match["label"] if match else name, "index": ps["index"],
                "x": ps["x"], "y": ps["y"], "w": ps["w"], "h": ps["h"],
                "wallpaper": sc.get("wallpaper", ""), "active": ps.get("plugin") == plasma.PLUGIN_ID,
                "playlist": self.cfg.playlist(name),
            })
        res.sort(key=lambda s: (s["x"], s["y"]))
        return res

    def _plasma_index(self, name: str) -> int | None:
        for s in self.screen_list():
            if s["name"] == name:
                return s["index"]
        return None

    # ================================================================ apply
    def merged_params(self, wid: str) -> dict:
        w = self.lib.get(wid)
        if not w:
            return {}
        p = dict(w.defaults)
        if w.type == "particles":
            p.update(w.preset)
        p.update(self.cfg.data["params"].get(wid, {}))
        return p

    def _values(self, wid: str) -> dict:
        w = self.lib.get(wid)
        g = self.cfg.g
        return {
            "WallpaperId": w.id, "Kind": w.type, "Source": w.source,
            "Params": json.dumps(self.merged_params(wid), ensure_ascii=False),
            "Fps": int(g["fps"]), "Paused": bool(self.cfg.data["paused"]),
            "PauseOnFullscreen": bool(g["pauseOnFullscreen"]), "PauseOnMaximized": bool(g["pauseOnMaximized"]),
            "MouseEnabled": bool(g["mouse"]), "AudioEnabled": bool(g["audio"]),
            "BridgePort": int(g["bridgePort"]), "Transition": int(g["transition"]),
        }

    def apply_to(self, wid: str, screen: str = "") -> bool:
        w = self.lib.get(wid)
        if not w:
            self.toast.emit(f"Wallpaper „{wid}“ nicht gefunden", "error")
            return False
        if w.error:
            self.toast.emit(f"{w.title}: {w.error}", "error")
            return False
        targets = [s for s in self.screen_list() if not screen or s["name"] == screen]
        if not targets:
            self.toast.emit("Kein passender Bildschirm gefunden", "error")
            return False
        try:
            for s in targets:
                plasma.apply(s["index"], self._values(wid))
                self.cfg.screen(s["name"])["wallpaper"] = wid
                self._last_change[s["name"]] = time.time()
        except Exception as e:
            self.toast.emit(f"Plasma hat nicht geantwortet: {e}", "error")
            return False
        self.cfg.save()
        self.refresh_screens()
        return True

    def _reapply_wallpaper(self, wid: str):
        """Push changed params of wid to every screen currently showing it."""
        for s in self.screen_list():
            if s["wallpaper"] == wid and s["active"]:
                try:
                    plasma.apply(s["index"], {"Params": json.dumps(self.merged_params(wid), ensure_ascii=False)})
                except Exception as e:
                    print("reapply:", e)

    def _push_globals(self):
        g = self.cfg.g
        try:
            plasma.set_all({
                "Fps": int(g["fps"]), "PauseOnFullscreen": bool(g["pauseOnFullscreen"]),
                "PauseOnMaximized": bool(g["pauseOnMaximized"]), "MouseEnabled": bool(g["mouse"]),
                "AudioEnabled": bool(g["audio"]), "Transition": int(g["transition"]),
                "Paused": bool(self.cfg.data["paused"]),
            })
        except Exception as e:
            print("push globals:", e)

    def restore_all(self):
        """Re-apply the saved wallpaper on each screen (used at login)."""
        for s in self.screen_list():
            wid = s["wallpaper"]
            if wid and self.lib.get(wid) and not s["active"]:
                self.apply_to(wid, s["name"])

    # ================================================================ playlists
    def _tick_playlists(self):
        now = dt.datetime.now()
        minutes = now.hour * 60 + now.minute
        for s in self.screen_list():
            pl = s["playlist"]
            if not pl.get("enabled"):
                continue
            name = s["name"]
            if pl.get("mode") == "daynight":
                day_s = _hhmm(pl.get("dayStart"), 420)
                night_s = _hhmm(pl.get("nightStart"), 1140)
                is_day = day_s <= minutes < night_s if day_s < night_s else not (night_s <= minutes < day_s)
                want = pl.get("day") if is_day else pl.get("night")
                if want and want != s["wallpaper"] and self.lib.get(want):
                    self.apply_to(want, name)
            else:
                last = self._last_change.setdefault(name, time.time())
                if time.time() - last >= max(1, float(pl.get("interval", 10))) * 60:
                    self.next(name)

    def _playlist_items(self, name: str) -> list[str]:
        pl = self.cfg.playlist(name)
        items = [i for i in pl.get("items", []) if self.lib.get(i)]
        if not items:
            items = [i for i in self.cfg.data["favorites"] if self.lib.get(i)]
        if not items:
            items = [w.id for w in self.lib.ordered() if not w.error]
        return items

    def next(self, name: str = "") -> None:
        screens = [s for s in self.screen_list() if not name or s["name"] == name]
        for s in screens:
            items = self._playlist_items(s["name"])
            if not items:
                continue
            cur = s["wallpaper"]
            if self.cfg.playlist(s["name"]).get("shuffle") and len(items) > 1:
                nxt = random.choice([i for i in items if i != cur])
            else:
                nxt = items[(items.index(cur) + 1) % len(items)] if cur in items else items[0]
            self.apply_to(nxt, s["name"])

    # ================================================================ video optimisation
    def _max_screen_h(self) -> int:
        return max([s["h"] for s in self.screen_list()] or [1080])

    def optimize_pending(self):
        """Convert imported videos that the GPU cannot decode (or that are bigger than the
        screens) to AV1 at screen size – one at a time, in the background."""
        if self._opt_busy or not shutil.which("ffmpeg"):
            return
        from .library import needs_optimize, optimize_wallpaper
        max_h = self._max_screen_h()
        for w in self.lib.ordered():
            if w.type != "video" or w.builtin or w.optimized:
                continue
            if not needs_optimize(w.dir / w.file, max_h):
                continue
            self._opt_busy = True
            self.toast.emit(f"Optimiere „{w.title}“ für weniger CPU-Last …", "info")

            def work(w=w):
                ok, how = optimize_wallpaper(w, max_h)
                self._optimized.emit(w.id, ok, how)
            threading.Thread(target=work, name="lwe-optimize", daemon=True).start()
            return

    def _on_optimized(self, wid, ok, how):
        self._opt_busy = False
        self.lib.scan()
        self.libraryChanged.emit()
        w = self.lib.get(wid)
        if ok and w:
            for s in self.screen_list():
                if s["wallpaper"] == wid and s["active"]:
                    plasma.apply(s["index"], self._values(wid))
            self.toast.emit(f"„{w.title}“ optimiert (AV1, {how}) – läuft jetzt über die Grafikkarte", "ok")
        elif w:
            self.toast.emit(f"„{w.title}“ konnte nicht optimiert werden: {how[:120]}", "error")
        QTimer.singleShot(1000, self.optimize_pending)

    # ================================================================ audio / kwin / autostart
    def _sync_audio(self):
        if self.cfg.g["audio"] and not self.headless:
            self.audio.start()
            if self.audio.error:
                self.toast.emit(self.audio.error, "error")
        else:
            self.audio.stop()

    def _kwin_script(self, enabled: bool):
        kw = shutil.which("kwriteconfig6")
        if not kw:
            return
        subprocess.run([kw, "--file", "kwinrc", "--group", "Plugins", "--key", "lwecursorEnabled",
                        "true" if enabled else "false"])
        try:
            from PySide6.QtDBus import QDBusConnection, QDBusMessage
            m = QDBusMessage.createMethodCall("org.kde.KWin", "/KWin", "org.kde.KWin", "reconfigure")
            QDBusConnection.sessionBus().call(m)
        except Exception as e:
            print("kwin reconfigure:", e)

    def _autostart(self, enabled: bool):
        if enabled:
            AUTOSTART.parent.mkdir(parents=True, exist_ok=True)
            exe = shutil.which("lwe") or str(Path.home() / ".local/bin/lwe")
            AUTOSTART.write_text(
                "[Desktop Entry]\nType=Application\nName=Linux Wallpaper Engine\n"
                f"Exec={exe} --tray\nIcon=lwe\nX-KDE-autostart-phase=2\nNoDisplay=true\n", encoding="utf-8")
        elif AUTOSTART.exists():
            AUTOSTART.unlink()

    # ================================================================ theme
    def _load_theme(self):
        name = self.cfg.data.get("theme", "minimal")
        for d in (paths.THEMES_USER, paths.themes_builtin()):
            p = d / f"{name}.json"
            if p.exists():
                try:
                    self._theme = json.loads(p.read_text(encoding="utf-8"))
                    return
                except ValueError as e:
                    self.toast.emit(f"Theme {p.name} fehlerhaft: {e}", "error")
        p = paths.themes_builtin() / "neon-glass.json"
        self._theme = json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}

    # ================================================================ QML API
    @Property("QVariantList", notify=libraryChanged)
    def wallpapers(self):
        favs = set(self.cfg.data["favorites"])
        out = []
        for w in self.lib.ordered():
            d = w.to_dict()
            d["favorite"] = w.id in favs
            d["params"] = self.merged_params(w.id)
            out.append(d)
        return out

    @Property("QVariantList", notify=libraryChanged)
    def allTags(self):
        tags = {}
        for w in self.lib.items.values():
            for t in w.tags:
                tags[t] = tags.get(t, 0) + 1
        return [t for t, _ in sorted(tags.items(), key=lambda kv: (-kv[1], kv[0]))]

    @Property("QVariantList", notify=screensChanged)
    def screens(self):
        return self.screen_list()

    @Property(bool, notify=stateChanged)
    def paused(self):
        return bool(self.cfg.data["paused"])

    @Property("QVariantMap", notify=settingsChanged)
    def settings(self):
        g = dict(self.cfg.g)
        g["autostart"] = AUTOSTART.exists()
        g["theme"] = self.cfg.data.get("theme", "minimal")
        g["audioAvailable"] = AudioAnalyzer.available()
        return g

    @Property("QVariantMap", notify=themeChanged)
    def theme(self):
        return self._theme

    @Property("QVariantList", notify=themeChanged)
    def themes(self):
        names = set()
        for d in (paths.themes_builtin(), paths.THEMES_USER):
            if d.is_dir():
                names |= {p.stem for p in d.glob("*.json")}
        out = []
        for n in sorted(names):
            for d in (paths.THEMES_USER, paths.themes_builtin()):
                p = d / f"{n}.json"
                if p.exists():
                    try:
                        out.append({"id": n, "name": json.loads(p.read_text(encoding="utf-8")).get("name", n)})
                    except ValueError:
                        pass
                    break
        return out

    @Property(str, constant=True)
    def pluginUi(self):
        return QUrl.fromLocalFile(str(paths.plugin_ui())).toString()

    @Property(str, constant=True)
    def themesDir(self):
        return str(paths.THEMES_USER)

    @Slot(str, str, result=bool)
    def apply(self, wid, screen):
        if self.paused:                     # choosing a wallpaper means: play it
            self.setPaused(False)
        ok = self.apply_to(wid, screen)
        if ok:
            w = self.lib.get(wid)
            where = screen if screen else "allen Bildschirmen"
            self.toast.emit(f"„{w.title}“ auf {where}", "ok")
        return ok

    @Slot(str, str, "QVariant")
    def setParam(self, wid, key, value):
        if key not in PARAM_KEYS:
            return
        self.cfg.data["params"].setdefault(wid, {})[key] = value
        self.cfg.save()
        self._reapply_wallpaper(wid)
        self.libraryChanged.emit()

    @Slot(str)
    def resetParams(self, wid):
        self.cfg.data["params"].pop(wid, None)
        self.cfg.save()
        self._reapply_wallpaper(wid)
        self.libraryChanged.emit()

    @Slot(str, result="QVariantMap")
    def params(self, wid):
        return self.merged_params(wid)

    @Slot(str)
    def toggleFavorite(self, wid):
        f = self.cfg.data["favorites"]
        if wid in f:
            f.remove(wid)
        else:
            f.append(wid)
        self.cfg.save()
        self.libraryChanged.emit()

    @Slot("QVariantList", result=int)
    def importUrls(self, urls):
        total, errors = [], []
        for u in urls:
            p = QUrl(u).toLocalFile() if "://" in str(u) else str(u)
            if not p:
                continue
            ok, err = self.lib.import_path(Path(p))
            total += ok
            errors += err
        self.libraryChanged.emit()
        if total:
            self.toast.emit(f"{len(total)} Wallpaper importiert", "ok")
            if not self.headless:
                QTimer.singleShot(500, self.optimize_pending)
        for e in errors[:3]:
            self.toast.emit(e.splitlines()[0] if len(e) > 160 else e, "error")
        if errors:
            print("\n".join(errors))
        return len(total)

    @Slot(str, result=bool)
    def removeWallpaper(self, wid):
        ok = self.lib.remove(wid)
        if ok:
            if wid in self.cfg.data["favorites"]:
                self.cfg.data["favorites"].remove(wid)
            self.cfg.data["params"].pop(wid, None)
            self.cfg.save()
            self.libraryChanged.emit()
            self.toast.emit("Wallpaper gelöscht", "info")
        return ok

    @Slot(str, str, str, result=bool)
    def renameWallpaper(self, wid, title, tags):
        ok = self.lib.rename(wid, title, [t for t in tags.split(",")])
        if ok:
            self.libraryChanged.emit()
        return ok

    @Slot(str)
    def openFolder(self, wid):
        w = self.lib.get(wid)
        QDesktopServices.openUrl(QUrl.fromLocalFile(str(w.dir if w else paths.LIBRARY)))

    @Slot(str, "QVariant")
    def setGlobal(self, key, value):
        if key == "autostart":
            self._autostart(bool(value))
        elif key == "theme":
            self.cfg.data["theme"] = str(value)
            self._load_theme()
            self.themeChanged.emit()
        elif key in self.cfg.g:
            old = self.cfg.g[key]
            self.cfg.g[key] = type(old)(value) if not isinstance(old, bool) else bool(value)
            if key == "audio":
                self._sync_audio()
            if key == "mouse":
                self._kwin_script(bool(value))
            self._push_globals()
        self.cfg.save()
        self.settingsChanged.emit()

    @Slot(bool)
    def setPaused(self, p):
        self.cfg.data["paused"] = bool(p)
        self.cfg.save()
        try:
            plasma.set_all({"Paused": bool(p)})
        except Exception as e:
            self.toast.emit(f"Plasma hat nicht geantwortet: {e}", "error")
        self.stateChanged.emit()

    @Slot()
    def togglePause(self):
        self.setPaused(not self.paused)

    @Slot(str)
    def nextWallpaper(self, screen):
        self.next(screen)

    @Slot(str, "QVariantMap")
    def setPlaylist(self, screen, values):
        pl = self.cfg.playlist(screen)
        for k, v in values.items():
            if k in pl:
                pl[k] = v
        self._last_change[screen] = time.time()
        self.cfg.save()
        self.screensChanged.emit()
        if pl.get("enabled"):
            self._tick_playlists()

    @Slot()
    def restoreDefault(self):
        try:
            plasma.restore_default()
        except Exception as e:
            self.toast.emit(str(e), "error")
        self.refresh_screens()
        self.toast.emit("Plasma-Standardhintergrund wiederhergestellt", "info")

    @Slot()
    def refresh(self):
        self.lib.scan()
        self.refresh_screens()
        self.libraryChanged.emit()

    def shutdown(self):
        self.audio.stop()
        if self.bridge:
            self.bridge.stop()
