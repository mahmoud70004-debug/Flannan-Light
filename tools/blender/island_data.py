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
LIGHT_H = 6.3                   # level ground around the lighthouse
QUAY_H = 1.3                    # landing quay height above the sea


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

    L = to_world(meta["lighthouse_px"])
    P0 = to_world(meta["landing_px"])
    HU = to_world(meta["hump_px"])

    # --- the top: gently domed, rising to a rocky hump in the west -----------
    T = LAND_TOP + lowfreq(22, 0.8) + lowfreq(8, 0.25) - 0.012 * X
    T += HUMP_TOP * np.exp(-(((X - HU[0]) ** 2 + (Y - HU[1]) ** 2) / 13.0 ** 2))
    dl = np.hypot(X - L[0], Y - L[1])
    T = T * (1 - smoothstep(10, 22, 40 - dl) * 0) + 0  # keep T, pad applied below
    T = np.where(dl < 40, T + (LIGHT_H - T) * (1 - smoothstep(9, 24, dl)), T)

    # --- cliffs: steep rounded edge, then the sea floor falling away ---------
    wc = np.clip(3.0 + lowfreq(10, 1.0), 2.0, 4.6)
    f = 1 - (1 - np.clip(sd / wc, 0, 1)) ** 2.0
    h = np.where(sd >= 0, T * f, np.maximum(sd * 0.85, -9.0))
    h += lowfreq(2.5, 0.30) * np.clip(1 - np.abs(sd - 1.5) / 6.0, 0, 1)    # rocky roughness at the coast

    # --- the approach: a gentle path from the quay up to the lighthouse -------
    GATE_PX = [meta["lighthouse_px"][0], meta["lighthouse_px"][1] + 50]       # compound gate, 15 m south of the tower
    wp_px = [meta["landing_px"], [590, 226], [510, 240], [440, 226], [420, 198], GATE_PX]
    wp = np.array([to_world(p) for p in wp_px])
    out_dir = (wp[0] - wp[1]) / np.linalg.norm(wp[0] - wp[1])
    ext = np.array([wp[0] + out_dir * k for k in np.arange(0.0, 14.0, 0.5)])     # quay running into the sea
    dense = []
    for a, b in zip(wp[:-1], wp[1:]):
        n = max(2, int(np.linalg.norm(b - a) / 0.5))
        dense += [a + (b - a) * t for t in np.linspace(0, 1, n, endpoint=False)]
    dense.append(wp[-1])
    dense = np.array(dense)
    seg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(dense, axis=0), axis=1))]
    total = seg[-1]
    t_line = seg / total
    ramp_line = QUAY_H + (LIGHT_H - QUAY_H) * (0.5 - 0.5 * np.cos(np.pi * t_line))
    pts = np.vstack([ext[::-1], dense])
    ramp_vals = np.r_[np.full(len(ext), QUAY_H), ramp_line]
    tree = cKDTree(pts)
    dist, idx = tree.query(np.c_[X.ravel(), Y.ravel()])
    dist = dist.reshape(X.shape)
    ramp_h = ramp_vals[idx].reshape(X.shape)
    w = 1 - smoothstep(2.4, 12.0, dist)
    w = np.where(sd > -9, w, 0)
    h = h + (ramp_h - h) * w

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
    on_path = (1 - smoothstep(0.9, 1.7, dist)) * (h > 0.6)
    col = col + (0.62 - col) * on_path * 0.8
    cav = ndi.gaussian_filter(h, 2.5 / RES) - h
    col *= 1 - np.clip(cav * 0.45, 0, 0.45)
    col = np.clip(col, 0.05, 0.95)

    lighthouse_h = float(h[int((L[1] - Y0) / RES), int((L[0] - X0) / RES)])
    return dict(X=X, Y=Y, h=h, col=col, sd=sd, nx=nx, ny=ny, path=dense, path_h=ramp_line, ext=ext,
                L=L, lighthouse_h=lighthouse_h, P0=P0, wp=wp, total=total, poly_w=poly_w, to_world=to_world, meta=meta)
