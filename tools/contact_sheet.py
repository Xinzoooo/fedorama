"""Render every compiled wallpaper shader into one contact sheet PNG (dev tool).
usage: python3 tools/contact_sheet.py <wallpapers-dir> <out.png> [time] [ids...]"""
import sys
from pathlib import Path
from PySide6.QtCore import QUrl, QTimer
from PySide6.QtGui import QGuiApplication, QImage, QPainter, QColor, QFont
from PySide6.QtQuick import QQuickView

QML = b"""
import QtQuick
Item {
    width: 640; height: 360
    property url src
    property real t: 10
    Image { id: noise; source: "PLUGIN/images/noise.png"; visible: false }
    ShaderEffectSource { id: ns; sourceItem: noise; wrapMode: ShaderEffectSource.Repeat; hideSource: true; visible: false }
    ShaderEffect {
        anchors.fill: parent
        fragmentShader: parent.src
        property real iTime: parent.t
        property real iTimeDelta: 0.016
        property real lweFrame: 600
        property vector3d iResolution: Qt.vector3d(width, height, 1)
        property vector4d iMouse: Qt.vector4d(width * 0.6, height * 0.5, 0, 0)
        property vector2d iMouseUV: Qt.vector2d(0.6, 0.5)
        property vector4d iDate: Qt.vector4d(2026, 10, 16, 79200)
        property vector4d iAudio: Qt.vector4d(0.5, 0.4, 0.3, 0.45)
        property vector4d iSpectrumA: Qt.vector4d(0.9, 0.8, 0.7, 0.65)
        property vector4d iSpectrumB: Qt.vector4d(0.6, 0.5, 0.55, 0.45)
        property vector4d iSpectrumC: Qt.vector4d(0.4, 0.35, 0.3, 0.3)
        property vector4d iSpectrumD: Qt.vector4d(0.25, 0.2, 0.15, 0.1)
        property real uBrightness: 1
        property real uHue: 0
        property real uSaturation: 1
        property variant iChannel0: ns
    }
}
"""
root = Path(sys.argv[1]); out = sys.argv[2]
t = float(sys.argv[3]) if len(sys.argv) > 3 else 10.0
ids = sys.argv[4:]
frags = sorted(p for p in root.glob("*/shader.qsb") if not ids or p.parent.name in ids)
app = QGuiApplication(sys.argv)
plugin = Path(__file__).resolve().parent.parent / "plugin/com.lwe.wallpaper/contents"
qml = Path("/tmp") / f"lwe_cs_{id(app)}.qml"
qml.write_bytes(QML.replace(b"PLUGIN", str(plugin).encode()))
v = QQuickView(); v.setSource(QUrl.fromLocalFile(str(qml))); v.show()
shots = []
cols = 3
def step(i=0):
    if i > 0:
        shots.append((frags[i - 1].parent.name, v.grabWindow()))
    if i == len(frags):
        rows = (len(shots) + cols - 1) // cols
        sheet = QImage(cols * 640, rows * 360, QImage.Format_RGB32); sheet.fill(QColor("black"))
        p = QPainter(sheet); p.setFont(QFont("Sans", 14, QFont.Bold))
        for k, (name, img) in enumerate(shots):
            x, y = (k % cols) * 640, (k // cols) * 360
            p.drawImage(x, y, img); p.setPen(QColor("black")); p.drawText(x + 11, y + 25, name)
            p.setPen(QColor("white")); p.drawText(x + 10, y + 24, name)
        p.end(); sheet.save(out); qml.unlink(); app.quit(); return
    v.rootObject().setProperty("src", QUrl.fromLocalFile(str(frags[i])))
    v.rootObject().setProperty("t", t)
    QTimer.singleShot(250, lambda: step(i + 1))
QTimer.singleShot(300, step)
app.exec()
