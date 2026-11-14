# A contact sheet of rendered posters, to look them over: python3 sheet.py OUT.png A.png B.png ...
import sys
from PIL import Image
out, files = sys.argv[1], sys.argv[2:]
cols = 3 if len(files) > 2 else len(files)
rows = (len(files) + cols - 1) // cols
sheet = Image.new('RGB', (cols * 512, rows * 683), '#000')
for i, f in enumerate(files):
    sheet.paste(Image.open(f).convert('RGB').resize((512, 683), Image.LANCZOS), ((i % cols) * 512, (i // cols) * 683))
sheet.save(out)
