"""One-off: derive the island's planform (outline only) from a reference aerial photo.

Usage: python trace_planform.py <photo.jpg> [out.json]

Only the simplified outline polygon is written (data/planform.json); the photo itself
is never copied into the repository (it is someone else's copyright). The outline of a
real island is geography; it is used here as a loose guide, not traced pixel for pixel.
"""
import json, sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as ndi
from skimage import measure

photo = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else "data/planform.json"

im = Image.open(photo).convert("RGB")
w, h = im.size
a = np.asarray(im).astype(float)
r, g, b = a[..., 0], a[..., 1], a[..., 2]
bright = a.sum(-1)
land = ((g > b + 4) | (r > b + 12)) & ~((r > 200) & (g > 200) & (b > 200))
land |= (r >= b - 2) & (bright < 330)
land[int(h * 0.94):, :] = False                       # caption strip

m = ndi.binary_closing(land, iterations=6)
m = ndi.binary_fill_holes(m)
m = ndi.binary_opening(m, iterations=5)
lab, n = ndi.label(m)
sizes = ndi.sum(m, lab, range(1, n + 1))
m = lab == (1 + int(np.argmax(sizes)))                 # the main island only (no stacks)
sm = ndi.gaussian_filter(m.astype(float), 5.0)

cs = measure.find_contours(sm, 0.5)
c = max(cs, key=len)
poly = measure.approximate_polygon(c, tolerance=2.5)   # (row, col)
pts = [[float(col), float(row)] for row, col in poly]

# Landmarks in photo pixels: lighthouse compound, the east landing, west rock hump.
meta = {
    "photo_size": [w, h],
    "polygon_px": pts,
    "lighthouse_px": [420, 88],
    "landing_px": [655, 228],
    "hump_px": [175, 125],
}
json.dump(meta, open(out, "w"), indent=1)
print("points", len(pts), "bbox", np.min(pts, 0), np.max(pts, 0))

vis = im.copy()
from PIL import ImageDraw
d = ImageDraw.Draw(vis)
d.line([tuple(p) for p in pts] + [tuple(pts[0])], fill=(255, 0, 0), width=3)
for k in ("lighthouse_px", "landing_px", "hump_px"):
    x, y = meta[k]
    d.ellipse([x - 6, y - 6, x + 6, y + 6], outline=(255, 255, 0), width=3)
vis.save("/tmp/btest/planform_vis.png")
