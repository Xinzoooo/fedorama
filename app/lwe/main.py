"""Entry point: `lwe` (window), `lwe --tray` (background), plus CLI commands."""
from __future__ import annotations

import argparse
import json
import os
import signal
import sys
from pathlib import Path

SOCKET = f"lwe-{os.getuid()}"


def parse(argv):
    # drop arguments a session manager may append (e.g. -session <id>)
    argv = [a for i, a in enumerate(argv) if not (a == "-session" or (i > 0 and argv[i - 1] == "-session"))]
    p = argparse.ArgumentParser(prog="lwe", description="Linux Wallpaper Engine")
    p.add_argument("--tray", action="store_true", help="im Hintergrund starten (Tray, Playlists, Live-Daten)")
    sub = p.add_subparsers(dest="cmd")
    sub.add_parser("show", help="Fenster öffnen")
    sub.add_parser("pause", help="alle pausieren")
    sub.add_parser("resume", help="fortsetzen")
    sub.add_parser("toggle", help="Pause umschalten")
    n = sub.add_parser("next", help="nächstes Wallpaper")
    n.add_argument("--screen", default="")
    s = sub.add_parser("set", help="Wallpaper setzen")
    s.add_argument("id")
    s.add_argument("--screen", default="", help="z. B. DP-1 (Standard: alle)")
    i = sub.add_parser("import", help="Dateien/Ordner importieren")
    i.add_argument("paths", nargs="+")
    sub.add_parser("list", help="Wallpaper auflisten")
    sub.add_parser("screens", help="Bildschirme auflisten")
    c = sub.add_parser("config", help="Einstellung setzen, z. B. 'lwe config fps 60' oder 'lwe config audio true'")
    c.add_argument("key")
    c.add_argument("value")
    sub.add_parser("quit", help="laufende Instanz beenden")
    sub.add_parser("restore", help="Plasma-Standardhintergrund wiederherstellen")
    return p.parse_args(argv)


def send(msg: dict, timeout=2500) -> dict | None:
    from PySide6.QtNetwork import QLocalSocket
    sock = QLocalSocket()
    sock.connectToServer(SOCKET)
    if not sock.waitForConnected(400):
        return None
    sock.write((json.dumps(msg) + "\n").encode())
    sock.flush()
    sock.waitForBytesWritten(timeout)
    if sock.waitForReadyRead(timeout):
        try:
            return json.loads(bytes(sock.readAll()).decode() or "{}")
        except ValueError:
            return {}
    return {}


def handle(engine, msg: dict, show_window=None, quit_app=None) -> dict:
    c = msg.get("cmd")
    if c == "show" and show_window:
        show_window()
    elif c == "pause":
        engine.setPaused(True)
    elif c == "resume":
        engine.setPaused(False)
    elif c == "toggle":
        engine.togglePause()
    elif c == "next":
        engine.next(msg.get("screen", ""))
    elif c == "set":
        return {"ok": engine.apply(msg["id"], msg.get("screen", ""))}
    elif c == "import":
        n = engine.importUrls(msg["paths"])
        return {"ok": n > 0, "imported": n}
    elif c == "list":
        return {"items": [(w.id, w.type, w.title) for w in engine.lib.ordered()]}
    elif c == "screens":
        return {"items": engine.screen_list()}
    elif c == "config":
        engine.setGlobal(msg["key"], msg["value"])
        return {"ok": True, "settings": engine.settings}
    elif c == "restore":
        engine.restoreDefault()
    elif c == "quit" and quit_app:
        quit_app()
    return {"ok": True}


def print_result(cmd, r):
    if cmd == "list":
        for wid, kind, title in r.get("items", []):
            print(f"{wid:28} {kind:10} {title}")
    elif cmd == "screens":
        for s in r.get("items", []):
            print(f"{s['name']:10} {s['w']}x{s['h']}+{s['x']}+{s['y']}  Plasma#{s['index']}  {s['wallpaper'] or '-'}")
    elif r.get("ok") is False:
        print("Fehlgeschlagen.", file=sys.stderr)
        sys.exit(1)


def main(argv=None):
    args = parse(sys.argv[1:] if argv is None else argv)
    cmd = args.cmd
    msg = {"cmd": cmd}
    if cmd in ("next", "set"):
        msg["screen"] = args.screen
    if cmd == "set":
        msg["id"] = args.id
    if cmd == "config":
        v = args.value
        msg["key"] = args.key
        msg["value"] = (v.lower() in ("1", "true", "on", "ja")) if v.lower() in ("1", "0", "true", "false", "on", "off", "ja", "nein") else (int(v) if v.isdigit() else v)
    if cmd == "import":
        msg["paths"] = [str(Path(p).resolve()) for p in args.paths]

    if cmd and cmd != "show":
        from PySide6.QtWidgets import QApplication
        app = QApplication(sys.argv[:1])        # needed for screens + QtDBus
        r = send(msg)
        if r is None:                               # no instance running: do it ourselves
            if cmd == "quit":
                return
            from .engine import Engine
            eng = Engine(headless=True)
            eng.toast.connect(lambda m, k: print(("Fehler: " if k == "error" else "") + m))
            r = handle(eng, msg)
        print_result(cmd, r)
        return

    # ------------------------------------------------ GUI / daemon
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    from PySide6.QtCore import QTimer, QUrl, Qt
    from PySide6.QtGui import QGuiApplication
    from PySide6.QtNetwork import QLocalServer
    from PySide6.QtQml import QQmlApplicationEngine
    from PySide6.QtWidgets import QApplication

    QGuiApplication.setDesktopFileName("lwe")
    app = QApplication(sys.argv[:1])
    app.setApplicationName("Linux Wallpaper Engine")
    app.setOrganizationName("lwe")
    app.setQuitOnLastWindowClosed(False)
    # Never let the session manager restore us with an open window at login;
    # the autostart entry (lwe --tray) starts us in the background instead.
    from PySide6.QtGui import QSessionManager
    def no_restore(sm):
        sm.setRestartHint(QSessionManager.RestartNever)
    app.saveStateRequest.connect(no_restore)
    app.commitDataRequest.connect(no_restore)

    if send({"cmd": "show" if not args.tray else "noop"}) is not None:
        return                                       # already running

    QLocalServer.removeServer(SOCKET)
    server = QLocalServer()
    server.listen(SOCKET)

    from .engine import Engine
    from .tray import Tray, app_icon
    from . import paths

    app.setWindowIcon(app_icon())
    engine = Engine()
    state = {"qml": None}

    def show_window():
        if state["qml"] is not None:
            for w in state["qml"].rootObjects():
                w.show(); w.raise_(); w.requestActivate()
            return
        qml = QQmlApplicationEngine()
        qml.rootContext().setContextProperty("lwe", engine)
        # dev/test helpers: open a page or a wallpaper's detail panel right away
        qml.rootContext().setContextProperty("lweStart", {
            "page": int(os.environ.get("LWE_START_PAGE", "0")),
            "detail": os.environ.get("LWE_START_DETAIL", "")})
        qml.load(QUrl.fromLocalFile(str(paths.APP_DIR / "qml/Main.qml")))
        if not qml.rootObjects():
            print("QML konnte nicht geladen werden", file=sys.stderr)
            return
        win = qml.rootObjects()[0]
        state["qml"] = qml

        def closed():
            # free the whole UI (and its RAM/GPU memory) when the window is closed
            def drop():
                if state["qml"] is qml:
                    state["qml"] = None
                    qml.deleteLater()
            QTimer.singleShot(0, drop)
        win.closing.connect(lambda *_: closed())

    def quit_app():
        engine.shutdown()
        app.quit()

    def on_conn():
        sock = server.nextPendingConnection()

        def ready():
            for line in bytes(sock.readAll()).decode().splitlines():
                try:
                    r = handle(engine, json.loads(line), show_window, quit_app)
                except Exception as e:
                    r = {"ok": False, "error": str(e)}
                sock.write((json.dumps(r) + "\n").encode())
                sock.flush()
        sock.readyRead.connect(ready)
    server.newConnection.connect(on_conn)

    tray = Tray(engine, show_window, quit_app)  # noqa: F841 (kept alive)
    signal.signal(signal.SIGINT, lambda *_: quit_app())
    signal.signal(signal.SIGTERM, lambda *_: quit_app())
    pulse = QTimer(); pulse.start(500); pulse.timeout.connect(lambda: None)   # let Python see signals

    if args.tray:
        QTimer.singleShot(4000, engine.restore_all)        # Plasma may still be starting
    else:
        show_window()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
