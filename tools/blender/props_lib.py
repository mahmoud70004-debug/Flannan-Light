"""Tiny modelling kit on top of bmesh: boxes, cylinders, spheres, lathes with bevels and per-face colour.
Props are built facing +Y (front), Z up, origin on the floor at the centre, units in metres. They are
exported as glTF with a FLOAT vertex colour holding the *sRGB* value we want (the game renders vertex
colours as sRGB) and three material slots: matte, gloss, metal (the game merges them into three batches)."""
import bpy, bmesh, math, random, os
from mathutils import Vector, Matrix, Euler

MATTE, GLOSS, METAL = 0, 1, 2
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../game/assets/models/props"))


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)) + (1.0,)


class Prop:
    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.col = self.bm.loops.layers.float_color.new("Col")

    # ---- primitives ----
    def _finish(self, before, verts, color, mat, smooth, jitter=0.0):
        faces = [f for f in self.bm.faces if f not in before]
        rnd = random.Random(hash(self.name) & 0xffff)
        for f in faces:
            f.material_index = mat
            f.smooth = smooth
            c = list(color)
            if jitter:
                k = 1.0 + rnd.uniform(-jitter, jitter)
                c = [min(1.0, c[0] * k), min(1.0, c[1] * k), min(1.0, c[2] * k), 1.0]
            for l in f.loops:
                l[self.col] = c
        return faces

    def _xform(self, verts, size, loc, rot):
        bmesh.ops.scale(self.bm, vec=Vector(size), verts=verts)
        if any(rot):
            bmesh.ops.rotate(self.bm, verts=verts, cent=(0, 0, 0), matrix=Euler(rot).to_matrix())
        bmesh.ops.translate(self.bm, verts=verts, vec=Vector(loc))

    def _bevel(self, verts, r, seg=2):
        if r <= 0:
            return
        edges = list({e for v in verts for e in v.link_edges})
        bmesh.ops.bevel(self.bm, geom=edges, offset=r, offset_type="OFFSET", segments=seg, profile=0.5, affect="EDGES")

    def box(self, size, loc, color, mat=MATTE, bevel=0.0, smooth=False, rot=(0, 0, 0), seg=2, jitter=0.0):
        before = set(self.bm.faces)
        verts = bmesh.ops.create_cube(self.bm, size=1.0)["verts"]
        self._xform(verts, size, loc, rot)
        self._bevel(verts, bevel, seg)
        return self._finish(before, verts, color, mat, smooth, jitter)

    def cyl(self, r, h, loc, color, mat=MATTE, r2=None, segs=14, bevel=0.0, smooth=True, rot=(0, 0, 0), caps=True):
        before = set(self.bm.faces)
        verts = bmesh.ops.create_cone(self.bm, cap_ends=caps, cap_tris=False, segments=segs, radius1=r, radius2=r if r2 is None else r2, depth=h)["verts"]
        self._xform(verts, (1, 1, 1), loc, rot)
        self._bevel(verts, bevel)
        return self._finish(before, verts, color, mat, smooth)

    def sphere(self, size, loc, color, mat=MATTE, segs=14, rings=8, smooth=True, rot=(0, 0, 0)):
        before = set(self.bm.faces)
        verts = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=rings, radius=1.0)["verts"]
        self._xform(verts, size, loc, rot)
        return self._finish(before, verts, color, mat, smooth)

    def lathe(self, profile, loc, color, mat=MATTE, segs=14, smooth=True):
        """profile: [(radius, z), ...] from the bottom up, spun around Z."""
        before = set(self.bm.faces)
        bm = self.bm
        verts = [bm.verts.new((r, 0.0, z)) for r, z in profile]
        edges = [bm.edges.new((verts[i], verts[i + 1])) for i in range(len(verts) - 1)]
        bmesh.ops.spin(bm, geom=verts + edges, cent=(0, 0, 0), axis=(0, 0, 1), angle=math.tau, steps=segs, use_merge=True)
        new_faces = [f for f in bm.faces if f not in before]
        bmesh.ops.translate(bm, verts=list({v for f in new_faces for v in f.verts}), vec=Vector(loc))
        bmesh.ops.recalc_face_normals(bm, faces=new_faces)
        return self._finish(before, None, color, mat, smooth)

    def surface(self, nx, ny, pos_fn, color_fn, mat=MATTE, smooth=True):
        """A grid of (nx+1) x (ny+1) vertices: pos_fn(u, v) -> (x, y, z), color_fn(u, v) -> rgba; u, v in 0..1."""
        before = set(self.bm.faces)
        bm = self.bm
        grid = [[bm.verts.new(pos_fn(i / nx, j / ny)) for j in range(ny + 1)] for i in range(nx + 1)]
        for i in range(nx):
            for j in range(ny):
                f = bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
                f.material_index = mat
                f.smooth = smooth
                for l in f.loops:
                    u = (l.vert.co.x - grid[0][0].co.x)
                    l[self.col] = color_fn(i / nx, j / ny)
        bmesh.ops.recalc_face_normals(bm, faces=[f for f in bm.faces if f not in before])

    def displace(self, faces, amp, seed=1, axis=2):
        rnd = random.Random(seed)
        vs = {v for f in faces for v in f.verts}
        for v in vs:
            v.co[axis] += rnd.uniform(-amp, amp)

    # ---- export ----
    def export(self):
        os.makedirs(OUT, exist_ok=True)
        mesh = bpy.data.meshes.new(self.name)
        self.bm.normal_update()
        self.bm.to_mesh(mesh)
        mesh.color_attributes.active_color = mesh.color_attributes[0] if len(mesh.color_attributes) else None
        for slot in ("matte", "gloss", "metal"):
            m = bpy.data.materials.get(slot) or bpy.data.materials.new(slot)
            mesh.materials.append(m)
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        path = os.path.join(OUT, self.name + ".glb")
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                                  export_vertex_color="NAME", export_vertex_color_name="Col", export_all_vertex_colors=True, export_yup=True,
                                  export_materials="EXPORT", export_cameras=False, export_lights=False)
        tris = sum(len(p.vertices) - 2 for p in mesh.polygons)
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(mesh)
        self.bm.free()
        print("%-22s %5d tris  %s" % (self.name, tris, os.path.relpath(path)))
        return tris
