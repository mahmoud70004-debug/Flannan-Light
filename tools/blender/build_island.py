"""Build the island terrain + sea stacks in Blender and export glTF for Godot.

    pip install bpy numpy scipy pillow
    python build_island.py [--preview out.png]

Outputs (relative to the repository):
    game/assets/models/island.glb         terrain (flat-shaded, vertex colours) + sea stacks
    game/assets/models/island_meta.json   landmarks, bounds and the approach path (Godot coordinates)
    game/assets/textures/shore_mask.png   foam mask for the sea shader
"""
import json, os, sys
import numpy as np
from PIL import Image
import bpy
from island_data import *

REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
MODELS = os.path.join(REPO, "game", "assets", "models")
TEX = os.path.join(REPO, "game", "assets", "textures")
os.makedirs(MODELS, exist_ok=True)
os.makedirs(TEX, exist_ok=True)

d = build()
h, col, sd, X, Y, nx, ny = d["h"], d["col"], d["sd"], d["X"], d["Y"], d["nx"], d["ny"]


# ---- terrain mesh: flat triangles where the ground is above -2.5 m ------------------
def terrain_arrays():
    verts, cols = [], []
    keep = (h[:-1, :-1] > -2.5) | (h[:-1, 1:] > -2.5) | (h[1:, :-1] > -2.5) | (h[1:, 1:] > -2.5)
    js, is_ = np.nonzero(keep)
    for j, i in zip(js, is_):
        a, b, c, e = (i, j), (i + 1, j), (i, j + 1), (i + 1, j + 1)
        ha, hb, hc, he = h[j, i], h[j, i + 1], h[j + 1, i], h[j + 1, i + 1]
        tris = [(a, b, e), (a, e, c)] if abs(ha - he) < abs(hb - hc) else [(a, b, c), (b, e, c)]
        for tri in tris:
            vs = [(X[q[1], q[0]], Y[q[1], q[0]], h[q[1], q[0]]) for q in tri]
            cc = float(np.mean([col[q[1], q[0]] for q in tri]))
            cc += (hash((i, j, tri[0], tri[1])) % 1000 / 1000.0 - 0.5) * 0.04
            verts += vs
            cols += [cc] * 3
    return np.array(verts, float), np.array(cols, float)


V, C = terrain_arrays()
ntri = len(V) // 3
print("terrain triangles:", ntri)


def make_object(name, V, C):
    mesh = bpy.data.meshes.new(name)
    n = len(V) // 3
    mesh.from_pydata(V.tolist(), [], [(3 * k, 3 * k + 1, 3 * k + 2) for k in range(n)])
    mesh.update()
    for p in mesh.polygons:
        p.use_smooth = False
    attr = mesh.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    rgba = np.repeat(np.clip(C, 0, 1), 4).reshape(-1, 4)
    rgba[:, 3] = 1.0
    attr.data.foreach_set("color", rgba.ravel())
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    mat = bpy.data.materials.new(name + "_mat")
    mat.use_nodes = True
    obj.data.materials.append(mat)
    return obj


bpy.ops.wm.read_factory_settings(use_empty=True)
terrain = make_object("Terrain", V, C)


# ---- sea stacks: layered, lumpy rock towers placed where the photo shows them ------
def stack(name_seed, cx, cy, r0, height, base=-3.0):
    r = np.random.default_rng(name_seed)
    rings, segs = 9, 11
    zs = np.linspace(base, height, rings)
    grid = []
    for k, z in enumerate(zs):
        t = (z - base) / (height - base)
        rad = r0 * (1.0 - 0.42 * t ** 1.4) * (1 + 0.20 * (r.random(segs) - 0.5) * 2)
        step = 0.6 + 0.4 * r.random()          # ledges: radius jumps every other ring
        if k % 2 == 1:
            rad *= 0.9 * step + 0.1
        ang = np.linspace(0, 2 * np.pi, segs, endpoint=False) + k * 0.15
        grid.append([(cx + rr * np.cos(a), cy + rr * np.sin(a), z) for rr, a in zip(rad, ang)])
    top = (cx, cy, height + 0.2 * r0)
    tris, cols = [], []
    for k in range(rings - 1):
        for s in range(segs):
            s2 = (s + 1) % segs
            a, b, c, e = grid[k][s], grid[k][s2], grid[k + 1][s], grid[k + 1][s2]
            shade = 0.40 + 0.16 * ((k // 1) % 2) + (r.random() - 0.5) * 0.05
            tris += [a, b, e, a, e, c]
            cols += [shade] * 6
    for s in range(segs):
        s2 = (s + 1) % segs
        tris += [grid[-1][s], grid[-1][s2], top]
        cols += [0.62] * 3
    return np.array(tris), np.array(cols)


stack_defs = []
tp = d["to_world"]
for seed, (px, py), r0, ht in [(1, (690, 335), 7.0, 6.5), (2, (700, 440), 11.0, 9.0), (3, (500, 405), 3.5, 2.6),
                               (4, (560, 450), 5.0, 4.2), (5, (45, 438), 6.0, 5.0)]:
    wxy = tp((px, py))
    stack_defs.append((seed, wxy[0], wxy[1], r0, ht))
SV, SC = [], []
for sd_ in stack_defs:
    v, c = stack(*sd_)
    SV.append(v)
    SC.append(c)
SV = np.vstack(SV)
SC = np.concatenate(SC)
stacks = make_object("Stacks", SV, SC)

# ---- export ----------------------------------------------------------------------
bpy.ops.object.select_all(action="DESELECT")
for o in (terrain, stacks):
    o.select_set(True)
bpy.ops.export_scene.gltf(
    filepath=os.path.join(MODELS, "island.glb"), export_format="GLB", use_selection=True,
    export_yup=True, export_apply=True, export_normals=True, export_vertex_color="ACTIVE",
    export_materials="EXPORT", export_image_format="NONE")
print("exported", os.path.getsize(os.path.join(MODELS, "island.glb")) // 1024, "KiB")


# ---- metadata for Godot (Godot coordinates: x, y up, z = -north) ----------------------
def g(p, y):
    return [round(float(p[0]), 3), round(float(y), 3), round(float(-p[1]), 3)]


path = d["path"]
step = max(1, len(path) // 24)
meta = {
    "bounds": {"min_x": X0, "max_x": X1, "min_z": -Y1, "max_z": -Y0},
    "quay_height": QUAY_H,
    "lighthouse": g(d["L"], d["lighthouse_h"]),
    "landing": g(d["P0"], QUAY_H),
    "path": [g(p, hh) for p, hh in zip(path[::step], d["path_h"][::step])],
    "path_length_m": round(float(d["total"]), 1),
    "stacks": [g((s[1], s[2]), 0.0) + [s[3]] for s in stack_defs],
    "triangles": {"terrain": ntri, "stacks": len(SV) // 3},
}
json.dump(meta, open(os.path.join(MODELS, "island_meta.json"), "w"), indent=1)

# ---- foam mask for the sea shader: 1 at the waterline, fading out to sea -----------------
mh, mw = ny * 2 - 1, nx * 2 - 1
sd_img = np.array(Image.fromarray(sd.astype(np.float32)).resize((mw, mh), Image.BILINEAR))
foam = np.clip(1.0 + sd_img / 10.0, 0, 1) * (sd_img <= 1.0)          # outside the coast, within 10 m
foam = np.where(sd_img > 1.0, np.clip(1 - (sd_img - 1.0) / 2.0, 0, 1) * 0.5, foam)   # thin surf on the rocks
img = (np.flipud(foam) * 255).astype(np.uint8)                       # image row 0 = north (min z)
Image.fromarray(img, "L").save(os.path.join(TEX, "shore_mask.png"))

# ---- report ------------------------------------------------------------------------
dh = np.diff(d["path_h"]) / np.maximum(np.diff(d["path_h"]) * 0 + 0.5, 1e-6)
print("path length %.0f m, max path gradient %.1f deg" % (d["total"], np.degrees(np.arctan(np.max(np.abs(dh))))))
print("lighthouse ground %.2f m, top height max %.1f m" % (d["lighthouse_h"], h.max()))

if "--preview" in sys.argv:
    out = sys.argv[sys.argv.index("--preview") + 1]
    scn = bpy.context.scene
    scn.render.engine = "BLENDER_WORKBENCH"
    scn.display.shading.color_type = "VERTEX"
    scn.display.shading.light = "STUDIO"
    scn.render.resolution_x, scn.render.resolution_y = 1100, 700
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    bpy.context.collection.objects.link(cam)
    cam.location = (-20, -150, 95)
    import math
    cam.rotation_euler = (math.radians(58), 0, math.radians(-8))
    cam.data.clip_end = 1000
    scn.camera = cam
    bpy.data.worlds.new("w")
    scn.world = bpy.data.worlds["w"]
    scn.world.color = (0.30, 0.45, 0.55)
    scn.render.filepath = out
    bpy.ops.render.render(write_still=True)
