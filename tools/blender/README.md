# Blender asset pipeline

The island and the lighthouse are authored in Blender (headless, scripted) and exported as
glTF for Godot. The generated files are committed, so CI and the game never need Blender.

```bash
python -m venv .venv && . .venv/bin/activate
pip install bpy numpy scipy pillow          # bpy 5.x needs Python 3.13
python build_island.py                      # game/assets/models/island.glb + island_meta.json + shore_mask.png
python build_lighthouse.py                  # game/assets/models/lighthouse.glb + lighthouse_meta.json
```

- `data/planform.json` is the island's outline, simplified from a real aerial photograph of Eilean Mòr
  (Canmore collection) by `trace_planform.py`. Only the outline polygon is stored; **the photo itself is
  not in the repository** (it is someone else's copyright) and the outline is a loose guide.
- `island_data.py` is the heightfield: cliffs, a gentle approach path from the quay to the lighthouse
  gate (about 4 degrees on average), vertex colours (grass, rock, strata, path, wet rock, cavity shading).
- `build_lighthouse.py` models a 17.8 m tower (plinth, string courses, gallery with balustrade, glazed
  lantern room, dome), the keepers' building (door, windows, hipped roof, chimney), a compound wall with
  gate piers, and an oil store. Exterior only: interiors are built in the game (`scripts/lighthouse.gd`)
  so indoor and outdoor lighting stay separate.

Budgets: terrain about 25 k triangles (flat shaded), lighthouse about 1.7 k, whole scene under 100 draw calls.
Change the numbers in the scripts, re-run, commit the regenerated assets.
