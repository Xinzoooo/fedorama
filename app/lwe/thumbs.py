"""Render thumbnails (thumb.jpg) for shader and particle wallpapers using the plugin's
own renderer files. usage: python3 -m lwe.thumbs <wallpapers-dir> [--force]"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PySide6.QtCore import QTimer, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView

from . import paths

QML = """
import QtQuick
Item {
    width: 640; height: 360
    property string kind
    property string src
    property string params: "{}"
    QtObject { id: host; property bool running: true; property int fps: 60
        property vector2d mouse: Qt.vector2d(0.62, 0.45); property vector4d audio: Qt.vector4d(0.45, 0.35, 0.3, 0.5)
        property var spectrum: [0.9,0.85,0.75,0.7,0.62,0.55,0.6,0.5,0.45,0.42,0.38,0.33,0.3,0.25,0.2,0.15] }
    Loader {
        id: l; anchors.fill: parent
        source: "%PLUGIN%/Slot.qml"
        onLoaded: { item.host = host; item.opacity = 1 }
    }
    Binding { target: l.item; property: "paramsJson"; value: params; when: l.item !== null }
    Binding { target: l.item; property: "source"; value: src; when: l.item !== null }
    Binding { target: l.item; property: "kind"; value: kind; when: l.item !== null }
}
"""


def main():
    root = Path(sys.argv[1]).resolve()
    force = "--force" in sys.argv
    jobs = []
    for meta in sorted(root.glob("*/wallpaper.json")):
        d = meta.parent
        m = json.loads(meta.read_text(encoding="utf-8"))
        if m.get("type") not in ("shader", "particles"):
            continue
        if (d / "thumb.jpg").exists() and not force:
            continue
        params = dict(m.get("defaults", {}))
        params.update(m.get("preset", {}))
        params["renderScale"] = 1.0
        src = str(d / "shader.qsb") if m["type"] == "shader" else ""
        jobs.append((d, m["type"], src, json.dumps(params)))
    if not jobs:
        return
    app = QGuiApplication(sys.argv[:1])
    qml = Path(paths.DATA) / ".thumbs.qml"
    paths.ensure()
    qml.write_text(QML.replace("%PLUGIN%", QUrl.fromLocalFile(str(paths.plugin_ui())).toString()))
    v = QQuickView()
    v.setTitle("LWE – Vorschaubilder")
    v.setSource(QUrl.fromLocalFile(str(qml)))
    v.show()
    state = {"i": 0}

    def load():
        if state["i"] >= len(jobs):
            qml.unlink(missing_ok=True)
            app.quit()
            return
        d, kind, src, params = jobs[state["i"]]
        r = v.rootObject()
        r.setProperty("kind", "")
        r.setProperty("params", params)
        r.setProperty("src", src)
        r.setProperty("kind", kind)
        # particles need a few seconds to fill the screen, shaders get some time to animate
        QTimer.singleShot(3500 if kind == "particles" else 2200, grab)

    def grab():
        d = jobs[state["i"]][0]
        img = v.grabWindow()
        img.save(str(d / "thumb.jpg"), "JPG", 88)
        print("  thumb", d.name)
        state["i"] += 1
        load()

    QTimer.singleShot(400, load)
    app.exec()


if __name__ == "__main__":
    main()
