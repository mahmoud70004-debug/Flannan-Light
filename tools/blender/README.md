# Blender props

The furniture and clutter models are built in Blender, headless and scripted, then committed as glTF so CI and the game
never need Blender.

```bash
python3.13 -m venv .venv && . .venv/bin/activate
pip install bpy numpy                 # bpy 5.x needs Python 3.13
python build_props.py                 # writes game/assets/models/props/*.glb
```

- `props_lib.py` is a tiny kit over `bmesh`: beveled boxes, cylinders, spheres, lathes and parametric surfaces, with a colour
  per face. Props face +Y in Blender (the game's -Z), stand on the floor at the origin, and use three material slots
  (matte, gloss, metal).
- Colours are stored as **sRGB values in a float vertex colour** (`Col`). The game draws plain colours as sRGB vertex colours
  in three merged batches per room (see `RoomKit.model`), so models add triangles but no draw calls.
- Budgets: a prop is 100–1,800 triangles; the whole flat stays under about 25 k.
- Add a prop: write a function in `build_props.py`, call it from `__main__`, run the script, import in Godot
  (`godot --headless --path game --import`), and place it with `Apartment.place_model(...)` in `furnishings.gd`
  (plus an invisible `collider(...)` so the player cannot walk through it).
