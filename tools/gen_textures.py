"""Generates the small helper textures shipped with the plugin (own work, MIT)."""
import random, sys, math
from PySide6.QtGui import QImage, QColor, QGuiApplication
out = sys.argv[1]
app = QGuiApplication([])
rnd = random.Random(1337)
img = QImage(256, 256, QImage.Format_RGBA8888)
for y in range(256):
    for x in range(256):
        img.setPixelColor(x, y, QColor(rnd.randrange(256), rnd.randrange(256), rnd.randrange(256), rnd.randrange(256)))
img.save(out + "/noise.png")
g = QImage(64, 64, QImage.Format_RGBA8888)
for y in range(64):
    for x in range(64):
        d = math.hypot(x - 31.5, y - 31.5) / 32.0
        a = max(0.0, 1.0 - d) ** 2.2
        g.setPixelColor(x, y, QColor(255, 255, 255, int(a * 255)))
g.save(out + "/glow.png")
# soft snowflake-like dot with crisper core
s = QImage(32, 32, QImage.Format_RGBA8888)
for y in range(32):
    for x in range(32):
        d = math.hypot(x - 15.5, y - 15.5) / 16.0
        a = max(0.0, 1.0 - d * d) ** 3
        s.setPixelColor(x, y, QColor(255, 255, 255, int(a * 255)))
s.save(out + "/dot.png")
