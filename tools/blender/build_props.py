"""Builds the furniture and clutter models (run with the bpy wheel: python build_props.py).
Everything is built from beveled boxes, cylinders and lathes, so the silhouettes are soft and catch light
instead of reading as bare cuboids. The game merges these meshes into the room batches (no extra draw calls)."""
import math, random, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from props_lib import *

FABRIC = rgb("5c5348"); FABRIC_L = rgb("6a6054"); FABRIC_D = rgb("463f37")
WOOD = rgb("4a3322"); WOOD_D = rgb("2e1f15"); WOOD_L = rgb("6b4b32")
WHITE = rgb("c9c8c2"); OFFWHITE = rgb("b9b6ac"); CHROME = rgb("b8babd"); BLACK = rgb("0c0c0e"); BRASS = rgb("8a6b38")
BEER = rgb("6b3d12"); LABEL = rgb("9a9078"); SHEET = rgb("a39e92"); DUVET = rgb("3b4350"); LEATHER = rgb("2a1810")
tris = 0


def sofa(name, w):
    p = Prop(name)
    p.box((w, 0.84, 0.2), (0, 0, 0.2), FABRIC_D, bevel=0.03)                                   # base frame
    for sx in (-1, 1):
        p.box((0.2, 0.88, 0.52), (sx * (w / 2 - 0.1), 0, 0.46), FABRIC, bevel=0.07, smooth=True, seg=3, jitter=0.03)   # arms
    seat_w = (w - 0.4) / 2
    for i in range(2):
        x = (-0.5 + i) * seat_w
        p.box((seat_w - 0.01, 0.62, 0.17), (x, 0.09, 0.38), FABRIC_L, bevel=0.06, smooth=True, seg=3, jitter=0.04)   # seat cushions
        p.box((seat_w - 0.02, 0.2, 0.44), (x, -0.27, 0.64), FABRIC_L, bevel=0.07, smooth=True, seg=3, rot=(math.radians(-9), 0, 0), jitter=0.04)   # back cushions
    p.box((w - 0.36, 0.16, 0.6), (0, -0.37, 0.58), FABRIC, bevel=0.05, smooth=True, seg=2)    # back frame
    for sx in (-1, 1):
        for sy in (-1, 1):
            p.cyl(0.03, 0.1, (sx * (w / 2 - 0.08), sy * 0.36, 0.05), WOOD_D, r2=0.022, segs=8)
    p.export()


def bed(name, w, l):
    p = Prop(name)
    p.box((w + 0.1, l + 0.08, 0.24), (0, 0, 0.2), WOOD, bevel=0.025)
    for sx in (-1, 1):
        for sy in (-1, 1):
            p.box((0.07, 0.07, 0.1), (sx * (w / 2 + 0.01), sy * (l / 2 - 0.02), 0.05), WOOD_D)
    p.box((w, l, 0.2), (0, 0, 0.42), SHEET, bevel=0.06, smooth=True, seg=3)                  # mattress
    faces = p.box((w - 0.04, l * 0.64, 0.1), (0.0, l * 0.12, 0.56), DUVET, bevel=0.04, smooth=True, seg=2, jitter=0.05)
    p.box((w - 0.04, l * 0.2, 0.07), (-0.02, l * 0.46 - l * 0.0, 0.54), DUVET, bevel=0.03, smooth=True, rot=(0, 0, math.radians(3)))  # a fold kicked off
    for px in ((-0.25, 0.25) if w > 1.2 else (0.0,)):
        p.box((0.5 if w > 1.2 else 0.45, 0.34, 0.14), (px * w, -l * 0.4, 0.58), SHEET, bevel=0.06, smooth=True, seg=3, rot=(0, 0, math.radians(px * 8)), jitter=0.05)
    p.box((w + 0.14, 0.07, 0.95), (0, -l / 2 - 0.035, 0.475), WOOD, bevel=0.03)             # headboard
    p.box((w + 0.2, 0.09, 0.07), (0, -l / 2 - 0.035, 0.97), WOOD_L, bevel=0.03, smooth=True)
    p.export()


def chair(name):
    p = Prop(name)
    p.box((0.43, 0.42, 0.045), (0, 0, 0.44), WOOD, bevel=0.012)
    for sx in (-1, 1):
        for sy in (-1, 1):
            p.cyl(0.022, 0.44, (sx * 0.18, sy * 0.18, 0.22), WOOD_D, r2=0.016, segs=8)
    for sx in (-1, 1):
        p.box((0.035, 0.035, 0.5), (sx * 0.18, -0.19, 0.69), WOOD_D, bevel=0.008)
    for i in range(3):
        p.box((0.36, 0.02, 0.07), (0, -0.19, 0.56 + i * 0.12), WOOD, bevel=0.006)
    p.export()


def table(name, w, d, h):
    p = Prop(name)
    p.box((w, d, 0.04), (0, 0, h - 0.02), WOOD, bevel=0.015)
    p.box((w - 0.12, d - 0.12, 0.07), (0, 0, h - 0.075), WOOD_D, bevel=0.01)
    for sx in (-1, 1):
        for sy in (-1, 1):
            p.cyl(0.032, h - 0.04, (sx * (w / 2 - 0.06), sy * (d / 2 - 0.06), (h - 0.04) / 2), WOOD, r2=0.022, segs=8)
    p.export()


def fridge(name):
    p = Prop(name)
    p.box((0.62, 0.62, 1.78), (0, 0, 0.9), OFFWHITE, mat=GLOSS, bevel=0.035, smooth=False, seg=2)
    p.box((0.6, 0.02, 0.56), (0, 0.31, 1.43), WHITE, mat=GLOSS, bevel=0.012)
    p.box((0.6, 0.02, 1.12), (0, 0.31, 0.62), WHITE, mat=GLOSS, bevel=0.012)
    p.box((0.02, 0.04, 0.35), (0.25, 0.345, 1.45), CHROME, mat=METAL, bevel=0.006)
    p.box((0.02, 0.04, 0.5), (0.25, 0.345, 0.85), CHROME, mat=METAL, bevel=0.006)
    p.box((0.6, 0.01, 0.01), (0, 0.322, 1.14), rgb("3a3a3a"))
    p.export()


def toilet(name):
    p = Prop(name)
    p.sphere((0.19, 0.27, 0.15), (0, 0.05, 0.3), WHITE, mat=GLOSS)
    p.cyl(0.13, 0.28, (0, 0.0, 0.14), WHITE, mat=GLOSS, r2=0.1)
    p.box((0.4, 0.17, 0.4), (0, -0.28, 0.62), WHITE, mat=GLOSS, bevel=0.03, smooth=True)
    p.cyl(0.19, 0.03, (0, 0.04, 0.46), rgb("b9b7b1"), mat=GLOSS, segs=18)
    p.export()


def tub(name, w=1.7, d=0.75, h=0.56):
    p = Prop(name)
    faces = p.box((w, d, h), (0, 0, h / 2), WHITE, mat=GLOSS, bevel=0.07, smooth=False, seg=3)
    top = max((f for f in faces), key=lambda f: f.calc_center_median().z)
    res = bmesh.ops.inset_region(p.bm, faces=[top], thickness=0.06, depth=0.0)
    inner = [f for f in p.bm.faces if f == top][0]
    for v in inner.verts:
        v.co.z -= 0.42
    p.box((0.05, 0.05, 0.05), (w / 2 - 0.25, d / 2 - 0.1, h + 0.03), CHROME, mat=METAL)
    p.export()


def sink(name):
    p = Prop(name)
    p.sphere((0.24, 0.2, 0.08), (0, 0, 0.82), WHITE, mat=GLOSS)
    p.cyl(0.07, 0.8, (0, -0.02, 0.4), WHITE, mat=GLOSS, r2=0.05, segs=10)
    p.cyl(0.012, 0.12, (0, -0.1, 0.95), CHROME, mat=METAL, segs=8)
    p.export()


def wardrobe(name, w=1.2, d=0.6, h=2.0):
    p = Prop(name)
    p.box((w, d, h), (0, 0, h / 2), WOOD, bevel=0.015)
    for sx in (-1, 1):
        p.box((w / 2 - 0.02, 0.02, h - 0.14), (sx * (w / 4), d / 2 + 0.005, h / 2), WOOD_L, bevel=0.008)
        p.box((0.02, 0.02, 0.35), (sx * 0.05, d / 2 + 0.03, h * 0.5), BRASS, mat=METAL, bevel=0.004)
    p.box((w + 0.04, d + 0.03, 0.05), (0, 0, h + 0.02), WOOD_D, bevel=0.01)
    p.export()


def armchair(name):
    p = Prop(name)
    p.box((0.84, 0.82, 0.22), (0, 0, 0.19), LEATHER, bevel=0.03)
    p.box((0.58, 0.6, 0.16), (0, 0.06, 0.38), rgb("3a241a"), bevel=0.06, smooth=True, seg=3, jitter=0.04)
    p.box((0.8, 0.16, 0.72), (0, -0.34, 0.62), rgb("33201a"), bevel=0.07, smooth=True, seg=3, rot=(math.radians(-8), 0, 0))
    for sx in (-1, 1):
        p.box((0.16, 0.8, 0.46), (sx * 0.34, 0, 0.5), rgb("33201a"), bevel=0.06, smooth=True, seg=3)
        for sy in (-1, 1):
            p.cyl(0.03, 0.08, (sx * 0.34, sy * 0.34, 0.04), WOOD_D, segs=8)
    p.export()


def bottle(name):
    p = Prop(name)
    prof = [(0.0, 0.0), (0.03, 0.0), (0.0335, 0.012), (0.0335, 0.13), (0.03, 0.15), (0.019, 0.175), (0.0135, 0.2), (0.0135, 0.235), (0.0165, 0.241), (0.0165, 0.25), (0.0, 0.25)]
    p.lathe(prof, (0, 0, 0), BEER, mat=GLOSS, segs=10)
    p.cyl(0.0345, 0.05, (0, 0, 0.085), LABEL, segs=10, caps=False)
    p.export()


def bag(name, seed):
    p = Prop(name)
    p.sphere((0.22, 0.2, 0.19), (0, 0, 0.17), rgb("22262a"), mat=GLOSS, segs=10, rings=6)
    rnd = random.Random(seed)
    for v in p.bm.verts:
        k = 1.0 + rnd.uniform(-0.16, 0.16)
        v.co.x *= k; v.co.y *= k; v.co.z *= 1 + rnd.uniform(-0.1, 0.1)
    p.cyl(0.035, 0.07, (0, 0, 0.36), rgb("22262a"), mat=GLOSS, r2=0.015, segs=6)     # the knotted top
    p.export()


def floor_lamp(name):
    p = Prop(name)
    p.cyl(0.16, 0.03, (0, 0, 0.015), rgb("2a2a2c"), mat=METAL, segs=16)
    p.cyl(0.014, 1.5, (0, 0, 0.78), rgb("3a3a3d"), mat=METAL, segs=8)
    p.cyl(0.2, 0.3, (0, 0, 1.6), rgb("a8996f"), r2=0.12, segs=16, caps=False)
    p.export()


def plate(name):
    p = Prop(name)
    p.lathe([(0.0, 0.0), (0.07, 0.0), (0.11, 0.012), (0.115, 0.022), (0.1, 0.018), (0.0, 0.01)], (0, 0, 0), rgb("b7b4ab"), mat=GLOSS, segs=18)
    p.export()


def laptop(name):
    p = Prop(name)
    p.box((0.32, 0.22, 0.02), (0, 0, 0.01), rgb("6a6c70"), mat=METAL, bevel=0.005)
    p.box((0.32, 0.01, 0.21), (0, -0.1, 0.13), rgb("1a1a1c"), mat=GLOSS, bevel=0.004, rot=(math.radians(-12), 0, 0))
    p.export()


def tv(name):
    """Origin on the stand's top surface."""
    p = Prop(name)
    p.cyl(0.05, 0.05, (0, 0, 0.025), rgb("0a0a0c"), segs=10)
    p.box((0.45, 0.2, 0.012), (0, 0.0, 0.006), rgb("0a0a0c"), mat=GLOSS)
    p.box((1.15, 0.05, 0.68), (0, 0, 0.38), rgb("0a0a0c"), mat=GLOSS, bevel=0.012)
    p.box((1.07, 0.01, 0.6), (0, 0.027, 0.38), rgb("101216"), mat=GLOSS)
    p.export()


def phone(name):
    p = Prop(name)
    p.box((0.26, 0.22, 0.07), (0, 0, 0.04), rgb("141416"), mat=GLOSS, bevel=0.012, smooth=True, rot=(math.radians(6), 0, 0))
    p.box((0.22, 0.07, 0.04), (0, 0.04, 0.095), rgb("141416"), mat=GLOSS, bevel=0.012, smooth=True)
    p.box((0.03, 0.03, 0.008), (-0.08, -0.06, 0.082), rgb("7a1f1c"), mat=GLOSS)
    p.export()


def curtain(name):
    """A 1 m x 1 m pleated sheet hanging in the XZ plane (front +Y); the game scales it to the window."""
    p = Prop(name)
    folds = 7
    base = (0.55, 0.45, 0.36)
    p.surface(28, 4,
              lambda u, v: ((u - 0.5), 0.045 * math.sin(u * folds * math.tau) * (0.4 + 0.6 * v) + 0.0, 1.0 - v),
              lambda u, v: tuple(c * (0.78 + 0.22 * (0.5 + 0.5 * math.sin(u * folds * math.tau))) * (0.85 + 0.15 * (1 - v)) for c in base) + (1.0,),
              smooth=True)
    p.export()


def bookshelf(name, w=0.3, d=1.1, h=1.9):
    """Long axis along X: width w is its depth, d is its length (the game turns it)."""
    p = Prop(name)
    p.box((d, w, h), (0, 0, h / 2), WOOD_D, bevel=0.01)
    rnd = random.Random(7)
    cols = [rgb(c) for c in ("6b2b2b", "2b3b5c", "8a8272", "3a2a1a", "4a4a4e", "26402c", "7a5a2a")]
    for shelf in range(4):
        z0 = 0.08 + shelf * 0.46
        p.box((d - 0.04, w - 0.04, 0.02), (0, 0.0, z0), WOOD, bevel=0.004)
        x = -d / 2 + 0.05
        while x < d / 2 - 0.08:
            th = rnd.uniform(0.022, 0.05)
            hh = rnd.uniform(0.22, 0.34)
            p.box((th, w - 0.1, hh), (x + th / 2, 0.015, z0 + 0.01 + hh / 2), rnd.choice(cols), jitter=0.06)
            x += th + 0.004
    p.export()


def cabinet(name, w, kind="base"):
    p = Prop(name)
    d, h = 0.6, 0.88
    p.box((w, d, h - 0.04), (0, 0, (h - 0.04) / 2), WOOD, bevel=0.01)
    n = 2 if w > 0.7 else 1
    for i in range(n):
        x = (-0.5 + (i + 0.5) / n) * w
        p.box((w / n - 0.02, 0.02, h - 0.12), (x, d / 2 + 0.005, (h - 0.04) / 2), WOOD_L, bevel=0.006)
        p.box((0.012, 0.02, 0.14), (x + (0.0 if n == 1 else (-0.16 if i == 0 else 0.16)), d / 2 + 0.03, h * 0.66), CHROME, mat=METAL, bevel=0.003)
    p.box((w + 0.02, d + 0.03, 0.04), (0, 0.01, h - 0.02), rgb("5a5d61"), mat=GLOSS, bevel=0.006)
    if kind == "sink":
        p.box((0.6, 0.4, 0.03), (0, 0.0, h + 0.003), CHROME, mat=METAL, bevel=0.01)
        p.cyl(0.015, 0.2, (0, -0.2, h + 0.1), CHROME, mat=METAL, segs=8)
        p.box((0.015, 0.1, 0.015), (0, -0.15, h + 0.2), CHROME, mat=METAL)
    if kind == "stove":
        for i in range(4):
            p.cyl(0.095, 0.012, (-0.27 + (i % 2) * 0.54, (0.13 if i < 2 else -0.13), h + 0.008), BLACK, mat=GLOSS, segs=14)
        p.box((0.8, 0.01, 0.52), (0, d / 2 + 0.03, 0.38), BLACK, mat=GLOSS)
    p.export()


def radiator(name):
    p = Prop(name)
    p.box((1.0, 0.06, 0.5), (0, 0, 0.3), WHITE, mat=GLOSS, bevel=0.01)
    for i in range(14):
        p.box((0.034, 0.08, 0.52), (-0.46 + i * 0.07, 0.0, 0.3), OFFWHITE, mat=GLOSS)
    p.export()


def can(name):
    p = Prop(name)
    p.lathe([(0.0, 0.0), (0.03, 0.0), (0.033, 0.01), (0.033, 0.11), (0.03, 0.12), (0.0, 0.12)], (0, 0, 0), rgb("a9acb0"), mat=METAL, segs=10)
    p.export()


def pizza_box(name):
    p = Prop(name)
    p.box((0.36, 0.36, 0.035), (0, 0, 0.0175), rgb("7d6a50"), bevel=0.004)
    p.box((0.36, 0.01, 0.2), (0, -0.18, 0.12), rgb("7d6a50"), rot=(math.radians(-20), 0, 0))
    p.cyl(0.14, 0.012, (0.0, 0.0, 0.04), rgb("6a5230"), segs=14)
    p.cyl(0.05, 0.014, (0.03, 0.02, 0.05), rgb("4a2a1a"), segs=8)
    p.export()


def shoes(name):
    p = Prop(name)
    for i, x in enumerate((-0.07, 0.07)):
        p.box((0.09, 0.26, 0.05), (x, 0.0, 0.03), rgb("1c1411"), mat=GLOSS, bevel=0.02, smooth=True, rot=(0, 0, math.radians(8 * (1 if i else -1))))
        p.box((0.09, 0.12, 0.08), (x, -0.08, 0.07), rgb("1c1411"), mat=GLOSS, bevel=0.025, smooth=True)
    p.export()


if __name__ == "__main__":
    curtain("curtain")
    bookshelf("bookshelf")
    cabinet("cab_1_2_stove", 1.2, "stove")
    cabinet("cab_1_0_sink", 1.0, "sink")
    cabinet("cab_0_6", 0.6)
    radiator("radiator")
    can("can")
    pizza_box("pizza_box")
    shoes("shoes")
    sofa("sofa_2_1", 2.1)
    bed("bed_1_4x2_1", 1.4, 2.1)
    bed("bed_0_95x2", 0.95, 2.0)
    chair("chair")
    table("table_0_9x1_5x0_75", 0.9, 1.5, 0.75)
    table("table_1_3x0_6x0_74", 1.3, 0.6, 0.74)
    table("table_0_6x1_2x0_74", 0.6, 1.2, 0.74)
    table("table_1_0x0_55x0_42", 1.0, 0.55, 0.42)
    fridge("fridge")
    toilet("toilet")
    tub("tub")
    sink("sink")
    wardrobe("wardrobe_1_2x0_6")
    armchair("armchair")
    bottle("bottle")
    for i in range(3):
        bag("bag_%d" % i, i + 5)
    floor_lamp("floor_lamp")
    plate("plate")
    laptop("laptop")
    tv("tv")
    phone("phone")
