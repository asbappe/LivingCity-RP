"""Makes the card pictures small enough to send to every player (about a third of what the browser writes):
fewer shades, still plain RGBA PNGs. Run after cards.js:
    node cards.js OUTDIR && python3 cards_shrink.py OUTDIR [SHEET.png]
SHEET is all fourteen on one picture, to look at."""
import glob, os, sys
from PIL import Image

out = sys.argv[1]
for p in sorted(glob.glob(os.path.join(out, "*.png"))):
    im = Image.open(p).convert("RGBA")
    a = im.getchannel("A").point(lambda v: 0 if v < 24 else (255 if v > 232 else (v // 32) * 32))
    rgb = im.convert("RGB").point(lambda v: min(255, (v // 6) * 6 + 3))
    rgb.putalpha(a)
    rgb.save(p, optimize=True)
    print(os.path.basename(p), os.path.getsize(p))
if len(sys.argv) > 2:
    order = [str(n) for n in range(2, 15)] + ["back"]
    w, h = 256, 356
    sheet = Image.new("RGB", (7 * (w + 16) + 16, 2 * (h + 16) + 16), (43, 38, 34))
    for i, n in enumerate(order):
        im = Image.open(os.path.join(out, n + ".png"))
        sheet.paste(im, (16 + (i % 7) * (w + 16), 16 + (i // 7) * (h + 16)), im)
    sheet.save(sys.argv[2])
