"""Build the lighthouse (tower, keepers' building, compound wall) in Blender -> glTF.

    python build_lighthouse.py

Local frame: origin at the tower's centre on the ground, X east, Y north, Z up.
South (-Y) is where the keepers' building and the gate are. The exterior is a set of
closed meshes (outer faces only matter); the interior rooms are built in the game so
indoor and outdoor lighting stay separate. Outputs game/assets/models/lighthouse.glb
and lighthouse_meta.json (the numbers the game uses for collision and rooms).
"""
import json, math, os
import bpy, bmesh
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
MODELS = os.path.abspath(os.path.join(HERE, "..", "..", "game", "assets", "models"))
os.makedirs(MODELS, exist_ok=True)

COLORS = {"whitewash": (0.93, 0.93, 0.92), "stone": (0.52, 0.52, 0.50), "iron": (0.10, 0.10, 0.11),
          "roof": (0.22, 0.23, 0.25), "glass": (0.05, 0.06, 0.07), "wood": (0.30, 0.24, 0.18)}
bms = {k: bmesh.new() for k in COLORS}


def M(loc=(0, 0, 0), rz=0.0, scale=(1, 1, 1)):
    return Matrix.Translation(Vector(loc)) @ Matrix.Rotation(rz, 4, "Z") @ Matrix.Diagonal((*scale, 1.0))


def cyl(mat, r0, r1, z0, z1, segs=20, rot=0.0, cx=0.0, cy=0.0):
    bmesh.ops.create_cone(bms[mat], cap_ends=True, cap_tris=False, segments=segs, radius1=r0, radius2=r1,
                          depth=z1 - z0, matrix=M((cx, cy, (z0 + z1) / 2), rot))


def box(mat, size, center, rz=0.0):
    bmesh.ops.create_cube(bms[mat], size=1.0, matrix=M(center, rz, size))


def sphere(mat, r, center, scale=(1, 1, 1), segs=14, rings=8):
    bmesh.ops.create_uvsphere(bms[mat], u_segments=segs, v_segments=rings, radius=r, matrix=M(center, 0, scale))


def ring(mat, major, minor, z, segs=32, minor_segs=6):
    """A torus-like rail made of short boxes laid around a circle."""
    step = 2 * math.pi / segs
    length = 2 * major * math.sin(step / 2) * 1.02
    for k in range(segs):
        a = k * step
        box(mat, (minor * 2, length, minor * 2), (major * math.cos(a), major * math.sin(a), z), a + math.pi / 2)


# ---- dimensions -------------------------------------------------------------------
PLINTH_R, PLINTH_H = 3.2, 1.1
SHAFT_R0, SHAFT_R1, SHAFT_Z0, SHAFT_Z1 = 2.7, 1.95, PLINTH_H, 11.7


def shaft_r(z):
    return SHAFT_R0 + (SHAFT_R1 - SHAFT_R0) * (z - SHAFT_Z0) / (SHAFT_Z1 - SHAFT_Z0)


# ---- tower ---------------------------------------------------------------------------
cyl("stone", PLINTH_R, PLINTH_R - 0.1, 0.0, PLINTH_H, 20)
cyl("stone", PLINTH_R + 0.12, PLINTH_R + 0.12, PLINTH_H - 0.12, PLINTH_H + 0.05, 20)          # plinth cap
cyl("whitewash", SHAFT_R0, SHAFT_R1, SHAFT_Z0, SHAFT_Z1, 20)
for z in (4.2, 7.8, 10.9):                                                                      # painted string courses
    cyl("stone", shaft_r(z) + 0.07, shaft_r(z) + 0.07, z, z + 0.22, 20)
for z, ang in ((3.1, 40), (5.5, 130), (7.9, 220), (10.0, 310), (6.6, 90)):                      # slit windows, spiralling up
    a = math.radians(ang)
    r = shaft_r(z) - 0.02
    c = (r * math.cos(a), r * math.sin(a), z + 0.45)
    box("glass", (0.42, 0.14, 0.9), c, a - math.pi / 2)
    box("stone", (0.62, 0.12, 0.12), (c[0], c[1], c[2] + 0.55), a - math.pi / 2)                # lintel
    box("stone", (0.6, 0.18, 0.1), (c[0], c[1], c[2] - 0.5), a - math.pi / 2)                   # sill

# gallery: slab, corbels, balustrade
GZ = SHAFT_Z1
cyl("stone", 3.1, 3.1, GZ, GZ + 0.35, 24)
for k in range(16):
    a = k * 2 * math.pi / 16
    box("stone", (0.34, 0.55, 0.5), (2.55 * math.cos(a), 2.55 * math.sin(a), GZ - 0.22), a + math.pi / 2)
for k in range(32):
    a = k * 2 * math.pi / 32
    box("iron", (0.05, 0.05, 1.0), (2.95 * math.cos(a), 2.95 * math.sin(a), GZ + 0.35 + 0.5), a)
ring("iron", 2.95, 0.03, GZ + 0.35 + 1.0)
ring("iron", 2.95, 0.025, GZ + 0.35 + 0.5)

# lantern room
LZ = GZ + 0.35
cyl("whitewash", 1.85, 1.72, LZ, LZ + 0.95, 16)
cyl("stone", 1.95, 1.95, LZ + 0.9, LZ + 1.02, 16)
GL0, GL1 = LZ + 1.0, LZ + 2.95
cyl("glass", 1.66, 1.66, GL0, GL1, 8, rot=math.pi / 8)
for k in range(8):
    a = k * math.pi / 4
    box("iron", (0.08, 0.08, GL1 - GL0), (1.68 * math.cos(a), 1.68 * math.sin(a), (GL0 + GL1) / 2), a)
for z in (GL0 + 0.03, (GL0 + GL1) / 2, GL1 - 0.03):
    cyl("iron", 1.72, 1.72, z - 0.04, z + 0.04, 8, rot=math.pi / 8)
sphere("iron", 1.95, (0, 0, GL1 + 0.05), (1, 1, 0.55), 16, 8)                                 # copper-style dome
cyl("iron", 0.22, 0.18, GL1 + 1.0, GL1 + 1.4, 10)                                             # ventilator
sphere("iron", 0.26, (0, 0, GL1 + 1.55), (1, 1, 1), 10, 6)
box("iron", (0.04, 0.04, 1.3), (0, 0, GL1 + 2.1))                                             # lightning rod / vane post
box("iron", (0.9, 0.03, 0.12), (0.45, 0, GL1 + 2.55))
TOP_Z = GL1 + 2.75

# ---- keepers' building (south of the tower) -------------------------------------------
BX0, BX1, BY0, BY1 = -5.5, 5.5, -9.4, -2.9
WALL_H, WALL_T = 3.1, 0.45
DOOR_X, DOOR_W, DOOR_H = 0.0, 1.2, 2.3
box("stone", (BX1 - BX0 + 0.3, BY1 - BY0 + 0.3, 0.55), ((BX0 + BX1) / 2, (BY0 + BY1) / 2, 0.275 - 0.4 + 0.4))   # plinth
zc = -0.8 + (WALL_H + 0.8) / 2
full = WALL_H + 0.8
box("whitewash", (BX1 - BX0, WALL_T, full), ((BX0 + BX1) / 2, BY1 - WALL_T / 2, zc))                    # north wall (against the tower)
box("whitewash", (WALL_T, BY1 - BY0, full), (BX0 + WALL_T / 2, (BY0 + BY1) / 2, zc))                    # west wall
box("whitewash", (WALL_T, BY1 - BY0, full), (BX1 - WALL_T / 2, (BY0 + BY1) / 2, zc))                    # east wall
left_w = (DOOR_X - DOOR_W / 2) - BX0
right_w = BX1 - (DOOR_X + DOOR_W / 2)
box("whitewash", (left_w, WALL_T, full), (BX0 + left_w / 2, BY0 + WALL_T / 2, zc))                      # south wall, left of door
box("whitewash", (right_w, WALL_T, full), (BX1 - right_w / 2, BY0 + WALL_T / 2, zc))                    # south wall, right of door
box("whitewash", (DOOR_W, WALL_T, WALL_H - DOOR_H), (DOOR_X, BY0 + WALL_T / 2, DOOR_H + (WALL_H - DOOR_H) / 2))   # lintel
box("stone", (DOOR_W + 0.5, 0.2, 0.18), (DOOR_X, BY0 - 0.02, DOOR_H + 0.09))                          # door head
for sx in (-1, 1):
    box("stone", (0.18, 0.2, DOOR_H), (DOOR_X + sx * (DOOR_W / 2 + 0.12), BY0 - 0.02, DOOR_H / 2))     # door jambs
box("stone", (DOOR_W + 0.9, 0.9, 0.18), (DOOR_X, BY0 - 0.45, 0.09))                                    # doorstep
box("stone", (DOOR_W + 0.5, 0.4, 0.18), (DOOR_X, BY0 - 0.9, 0.0))

for x in (-3.9, -2.3, 2.3, 3.9):                                                                        # windows, south face
    box("glass", (0.8, 0.1, 1.15), (x, BY0 - 0.02, 1.7))
    box("stone", (1.05, 0.14, 0.12), (x, BY0 - 0.04, 2.38))
    box("stone", (1.05, 0.2, 0.1), (x, BY0 - 0.06, 1.07))
    box("iron", (0.05, 0.12, 1.15), (x, BY0 - 0.03, 1.7))
for y in (-4.6, -7.2):                                                                                  # windows, east and west
    for sx in (-1, 1):
        box("glass", (0.1, 0.8, 1.15), (sx * (BX1 + 0.01), y, 1.7))
        box("stone", (0.14, 1.05, 0.12), (sx * (BX1 + 0.03), y, 2.38))
        box("stone", (0.2, 1.05, 0.1), (sx * (BX1 + 0.05), y, 1.07))

# hipped roof: closed mesh with eaves
rb = bmesh.new()
EX, EY, RZ0, RZ1, RIDGE = 0.45, 0.45, WALL_H, WALL_H + 1.9, 3.2
v = [rb.verts.new(p) for p in [(BX0 - EX, BY0 - EY, RZ0), (BX1 + EX, BY0 - EY, RZ0), (BX1 + EX, BY1 + EY, RZ0), (BX0 - EX, BY1 + EY, RZ0),
                               (BX0 + RIDGE - 0.6, (BY0 + BY1) / 2, RZ1), (BX1 - RIDGE + 0.6, (BY0 + BY1) / 2, RZ1)]]
for f in [(0, 1, 5, 4), (1, 2, 5), (2, 3, 4, 5), (3, 0, 4), (0, 3, 2, 1)]:
    rb.faces.new([v[i] for i in f])
bmesh.ops.recalc_face_normals(rb, faces=rb.faces)
bmesh.ops.transform(rb, matrix=Matrix.Identity(4), verts=rb.verts)
bms["roof"].from_mesh  # (bmesh API: keep reference)
mesh_tmp = bpy.data.meshes.new("roof_tmp")
rb.to_mesh(mesh_tmp)
bms["roof"].from_mesh(mesh_tmp)
rb.free()
box("stone", (0.8, 0.8, 1.9), (-3.5, -6.2, WALL_H + 1.4))                                               # chimney
box("stone", (1.0, 1.0, 0.18), (-3.5, -6.2, WALL_H + 2.4))
box("iron", (0.25, 0.25, 0.4), (-3.5, -6.2, WALL_H + 2.6))
for k, x in enumerate((-4.2, 3.2)):                                                                      # roof ridge ornaments
    box("stone", (0.3, 0.3, 0.3), (x, -6.15, RZ1 + 0.1))

# ---- compound wall ------------------------------------------------------------------
CX0, CX1, CY0, CY1 = -11.0, 11.0, -15.0, 6.0
CH, CT = 1.3, 0.45
GATE_W = 2.6
zc2 = -0.8 + (CH + 0.8) / 2
fullc = CH + 0.8
box("whitewash", (CX1 - CX0, CT, fullc), (0, CY1 - CT / 2, zc2))                                         # north
box("whitewash", (CT, CY1 - CY0, fullc), (CX0 + CT / 2, (CY0 + CY1) / 2, zc2))                           # west
box("whitewash", (CT, CY1 - CY0, fullc), (CX1 - CT / 2, (CY0 + CY1) / 2, zc2))                           # east
gl = (-GATE_W / 2) - CX0
gr = CX1 - GATE_W / 2
box("whitewash", (gl, CT, fullc), (CX0 + gl / 2, CY0 + CT / 2, zc2))                                     # south, left of gate
box("whitewash", (gr - GATE_W / 2 + GATE_W / 2 - 0.0, CT, fullc), (GATE_W / 2 + (CX1 - GATE_W / 2) / 2, CY0 + CT / 2, zc2))
for (x0, x1, y0, y1) in ((CX0, CX1, CY1 - CT, CY1), (CX0, CX0 + CT, CY0, CY1), (CX1 - CT, CX1, CY0, CY1)):
    box("stone", (x1 - x0 + (0.14 if x1 - x0 > 1 else 0.14), y1 - y0 + (0.14 if y1 - y0 > 1 else 0.14), 0.12),
        ((x0 + x1) / 2, (y0 + y1) / 2, CH + 0.06))                                                       # coping
box("stone", (gl + 0.14, CT + 0.14, 0.12), (CX0 + gl / 2, CY0 + CT / 2, CH + 0.06))
box("stone", (CX1 - GATE_W / 2 + 0.14 - GATE_W / 2 + GATE_W / 2, CT + 0.14, 0.12), (GATE_W / 2 + (CX1 - GATE_W / 2) / 2, CY0 + CT / 2, CH + 0.06))
for sx in (-1, 1):                                                                                       # gate piers
    box("stone", (0.7, 0.7, 2.0), (sx * (GATE_W / 2 + 0.35), CY0 + CT / 2, 1.0))
    box("stone", (0.85, 0.85, 0.16), (sx * (GATE_W / 2 + 0.35), CY0 + CT / 2, 2.08))
    sphere("stone", 0.2, (sx * (GATE_W / 2 + 0.35), CY0 + CT / 2, 2.3), (1, 1, 1), 8, 5)

# small outbuilding (oil store) in the compound's east yard
box("whitewash", (3.2, 2.6, 2.4), (7.2, -9.6, 1.2 - 0.0))
box("roof", (3.8, 3.2, 0.25), (7.2, -9.6, 2.5))
box("wood", (0.9, 0.12, 1.9), (7.2, -10.95, 0.95))

# ---- export -----------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
objs = []
for name, bm in bms.items():
    if len(bm.verts) == 0:
        continue
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    for p in mesh.polygons:
        p.use_smooth = False
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*COLORS[name], 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*COLORS[name], 1.0)
        bsdf.inputs["Roughness"].default_value = 1.0
    mesh.materials.append(mat)
    o = bpy.data.objects.new("LH_" + name, mesh)
    bpy.context.collection.objects.link(o)
    objs.append(o)
tris = sum(len(o.data.polygons) for o in objs)
bpy.ops.object.select_all(action="DESELECT")
for o in objs:
    o.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(MODELS, "lighthouse.glb"), export_format="GLB", use_selection=True,
                          export_yup=True, export_apply=True, export_normals=True, export_materials="EXPORT",
                          export_image_format="NONE")

meta = {
    "tower": {"plinth_r": PLINTH_R, "base_r": SHAFT_R0, "height": TOP_Z, "gallery_z": GZ, "lantern_z": (GL0 + GL1) / 2},
    "building": {"x0": BX0, "x1": BX1, "y0": BY0, "y1": BY1, "wall_h": WALL_H, "wall_t": WALL_T,
                 "door_x": DOOR_X, "door_w": DOOR_W, "door_h": DOOR_H},
    "compound": {"x0": CX0, "x1": CX1, "y0": CY0, "y1": CY1, "wall_h": CH, "wall_t": CT, "gate_w": GATE_W},
    "faces": tris,
}
json.dump(meta, open(os.path.join(MODELS, "lighthouse_meta.json"), "w"), indent=1)
print("lighthouse: %d faces, %.1f m tall, %d KiB" % (tris, TOP_Z, os.path.getsize(os.path.join(MODELS, "lighthouse.glb")) // 1024))
