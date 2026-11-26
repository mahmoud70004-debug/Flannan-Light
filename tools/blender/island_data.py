"""Shared island heightfield (numpy). Blender convention: X east, Y north, Z up (metres).
Godot's glTF import maps Blender (x, y, z) -> Godot (x, z, -y): north is -Z in Godot.

Everything here is deterministic; run build_island.py to regenerate the assets.
"""
import json, os
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
RES = 1.0                       # grid resolution, metres
SX, SY = 0.22, 0.30             # metres per photo pixel (y is stretched to undo the oblique view)
X0, X1, Y0, Y1 = -105.0, 105.0, -80.0, 80.0
LAND_TOP = 5.6                  # typical height of the top above the sea
HUMP_TOP = 5.0                  # extra height of the rocky hump in the west
TOP_H = 10.5                    # the cliff-top the tower stands on
DECK_H = 1.0                    # the dock's deck above the sea


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def load_planform():
    meta = json.load(open(os.path.join(HERE, "data", "planform.json")))
    poly = np.array(meta["polygon_px"], float)
    c = poly.mean(0)

    def to_world(p):
        return np.array([(p[0] - c[0]) * SX, -(p[1] - c[1]) * SY])

    return meta, np.array([to_world(p) for p in poly]), to_world


def build():
    meta, poly_w, to_world = load_planform()
    nx = int(round((X1 - X0) / RES)) + 1
    ny = int(round((Y1 - Y0) / RES)) + 1
    xs = X0 + np.arange(nx) * RES
    ys = Y0 + np.arange(ny) * RES
    X, Y = np.meshgrid(xs, ys)                         # arrays are [row=y, col=x]
    rng = np.random.default_rng(1900)

    def lowfreq(scale_m, amp=1.0):
        n = ndi.gaussian_filter(rng.standard_normal(X.shape), scale_m / RES)
        return amp * n / n.std()

    # --- coastline -> signed distance (positive inland) --------------------
    img = Image.new("L", (nx, ny), 0)
    ImageDraw.Draw(img).polygon([tuple(((p - np.array([X0, Y0])) / RES)) for p in poly_w], fill=255)
    mask = np.asarray(img) > 0
    sd = (ndi.distance_transform_edt(mask) - ndi.distance_transform_edt(~mask)) * RES

    P0 = to_world(meta["landing_px"])
    HU = to_world(meta["hump_px"])
    wp1 = to_world([590, 226])
    out = (P0 - wp1) / np.linalg.norm(P0 - wp1)            # seaward, at the old landing (about east)
    lat = np.array([-out[1], out[0]])                       # along the coast (about north)

    def W(o, l):                                            # a point by (seaward, along-coast) metres from the old landing
        return P0 + out * o + lat * l

    L = W(-18.5, 1.5)                                       # the tower, on a cliff-top above the landing cove

    # --- the top: gently domed, rising to a rocky hump in the west; a level cliff-top round the tower ----------
    T = LAND_TOP + lowfreq(22, 0.8) + lowfreq(8, 0.25) - 0.012 * X
    T += HUMP_TOP * np.exp(-(((X - HU[0]) ** 2 + (Y - HU[1]) ** 2) / 13.0 ** 2))
    dl = np.hypot(X - L[0], Y - L[1])
    T = T + (TOP_H - T) * (1 - smoothstep(12, 26, dl))

    # --- cliffs: steep rounded edge, then the sea floor falling away ---------
    wc = np.clip(3.0 + lowfreq(10, 1.0), 2.0, 4.6)
    f = 1 - (1 - np.clip(sd / wc, 0, 1)) ** 2.0
    h = np.where(sd >= 0, T * f, np.maximum(sd * 0.85, -9.0))
    h += lowfreq(2.5, 0.30) * np.clip(1 - np.abs(sd - 1.5) / 6.0, 0, 1)    # rocky roughness at the coast

    # --- the landing cove: a steep rock slope from the water up to the cliff-top, in the local frame ----------
    O = (X - P0[0]) * out[0] + (Y - P0[1]) * out[1]
    Lc = (X - P0[0]) * lat[0] + (Y - P0[1]) * lat[1]
    wz = smoothstep(-7.0, -4.0, Lc) * (1 - smoothstep(11.0, 14.0, Lc)) * (1 - smoothstep(-14.0, -12.0, -O)) \
        * smoothstep(-16.0, -12.0, O)
    hs = np.where(O < -2.0, TOP_H * np.clip((-O - 2.0) / 9.0, 0, 1) ** 1.1, (-O - 2.0) * 1.3) + lowfreq(1.6, 0.35)
    h = h * (1 - wz) + hs * wz

    # --- the stair: three flights and two landings up the slope, then a level walk to the tower door ---------
    nodes = [(-2.6, 0.0, DECK_H), (-4.4, 6.8, 4.2), (-5.6, 7.4, 4.2), (-7.2, 0.0, 7.4), (-8.4, -0.6, 7.4),
             (-10.2, 5.0, TOP_H), (-11.6, 5.2, TOP_H)]
    stair = [(W(o, l), hh) for o, l, hh in nodes]
    door = L + out * 3.65
    walk = stair + [(door, TOP_H)]
    dense, dense_h = [], []
    for (a, ha), (b, hb) in zip(walk[:-1], walk[1:]):
        n = max(2, int(np.linalg.norm(b - a) / 0.25))
        for t in np.linspace(0, 1, n, endpoint=False):
            dense.append(a + (b - a) * t)
            dense_h.append(ha + (hb - ha) * t)
    dense.append(walk[-1][0])
    dense_h.append(TOP_H)
    dense = np.array(dense)
    dense_h = np.array(dense_h)
    tree = cKDTree(dense)
    dist, idx = tree.query(np.c_[X.ravel(), Y.ravel()])
    dist = dist.reshape(X.shape)
    sh = dense_h[idx].reshape(X.shape)
    cut = 1 - smoothstep(1.3, 2.2, dist)                    # the stair is cut into the rock, a little below its treads
    h = np.where(cut > 0, np.minimum(h, h * (1 - cut) + (sh - 0.7) * cut), h)
    flat = 1 - smoothstep(1.2, 2.4, dist)                   # the level walk on the cliff-top meets the ground flush
    h = np.where((sh >= TOP_H - 0.01) & (flat > 0), h * (1 - flat) + TOP_H * flat, h)
    h = np.where(dl < 6.0, TOP_H, h)                        # the tower's footing

    # --- the dock: from the foot of the stair out over the water ------------------------------------------
    dock = [W(-2.6, 0.0), W(8.0, 0.0)]
    dd = np.abs((X - dock[0][0]) * lat[0] + (Y - dock[0][1]) * lat[1])
    along = (X - dock[0][0]) * out[0] + (Y - dock[0][1]) * out[1]
    under = (dd < 2.5) & (along > 0.6) & (along < 11.0)
    h = np.where(under, np.minimum(h, -1.6), h)

    # --- boulders: big rocks round the cove and beside the stair, never on the walkway ---------------------
    brng = np.random.default_rng(77)
    boulders = []
    tries = 0
    while len(boulders) < 30 and tries < 4000:
        tries += 1
        o = brng.uniform(-13.0, 5.0)
        l = brng.uniform(-8.0, 14.0)
        p = W(o, l)
        r = brng.uniform(0.9, 2.6) if o > -5 else brng.uniform(0.7, 1.7)
        if np.min(np.hypot(dense[:, 0] - p[0], dense[:, 1] - p[1])) < r + 1.4:
            continue
        dock_d = abs((p[0] - dock[0][0]) * lat[0] + (p[1] - dock[0][1]) * lat[1])
        dock_a = (p[0] - dock[0][0]) * out[0] + (p[1] - dock[0][1]) * out[1]
        if dock_d < r + 1.8 and -1.0 < dock_a < 12.0:
            continue
        if any(np.hypot(p[0] - q[0], p[1] - q[1]) < (r + q[2]) * 0.8 for q in boulders):
            continue
        gi, gj = int(round((p[0] - X0) / RES)), int(round((p[1] - Y0) / RES))
        base = h[gj, gi]
        if base < -4.0 or base > TOP_H - 1.0:
            continue
        boulders.append((p[0], p[1], r, base, int(brng.integers(1, 99999))))

    # --- vertex colours (luminance-first): grass, rock, strata, path, wet, AO --
    gy, gx = np.gradient(h, RES)
    slope = np.hypot(gx, gy)
    steep = smoothstep(0.55, 1.15, slope)
    grass = np.clip(0.30 + lowfreq(3, 0.035), 0.2, 0.4)
    rock = np.clip(0.54 + lowfreq(2, 0.05), 0.4, 0.7)
    col = grass + (rock - grass) * steep
    band = (np.sin(h * 2 * np.pi / 0.9) > 0).astype(float)
    col *= 1 - 0.20 * steep * band
    col = col + (0.18 - col) * 0.85 * (1 - smoothstep(0.3, 1.7, h))               # wet rock at the waterline
    cav = ndi.gaussian_filter(h, 2.5 / RES) - h
    col *= 1 - np.clip(cav * 0.45, 0, 0.45)
    col = np.clip(col, 0.05, 0.95)

    return dict(X=X, Y=Y, h=h, col=col, sd=sd, nx=nx, ny=ny, L=L, out=out, stair=stair, door=door, dock=dock,
                boulders=boulders, poly_w=poly_w, to_world=to_world, meta=meta)
