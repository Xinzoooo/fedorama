"""Render the window shadow used by app/qml/Main.qml (BorderImage, 9-slice).

The shadow is a static PNG so it costs nothing per frame. Run once after changing a value:
    python3 tools/gen_shadow.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SIZE = 128          # image size; the BorderImage stretches the middle
MARGIN = 28         # transparent window margin = Main.qml shadowMargin
RADIUS = 14         # stage corner radius
BLUR = 10
ALPHA = 0.9
OFFSET_Y = 8        # light comes from above

out = Path(__file__).resolve().parent.parent / "app/qml/images/shadow.png"
mask = Image.new("L", (SIZE, SIZE), 0)
d = ImageDraw.Draw(mask)
d.rounded_rectangle((MARGIN, MARGIN + OFFSET_Y, SIZE - MARGIN, SIZE - MARGIN + OFFSET_Y), RADIUS, fill=int(255 * ALPHA))
mask = mask.filter(ImageFilter.GaussianBlur(BLUR))
# nothing under the stage itself: cut out the stage rectangle
cut = Image.new("L", (SIZE, SIZE), 255)
ImageDraw.Draw(cut).rounded_rectangle((MARGIN, MARGIN, SIZE - MARGIN, SIZE - MARGIN), RADIUS, fill=0)
mask = Image.composite(mask, Image.new("L", (SIZE, SIZE), 0), cut)
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
img.putalpha(mask)
img.save(out)
print(out)
