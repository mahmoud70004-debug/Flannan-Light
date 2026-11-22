# No One Home

First-person 3D psychological horror for Android, by Pottsfield Studio. Martin has lost his job, his savings and, over ten days, his grip on what is real. One flat, one long corridor, and someone who may not be there.

**Play the latest build:** https://mahmoud70004-debug.github.io/Flannan-Light/ (updates automatically on every push to `main`; the build number is shown on the title screen; the URL changes when the repository is renamed).

Status: pre-production, phase 1 (look dev). See [docs/GDD.md](docs/GDD.md) and [docs/DEVELOPMENT-PLAN.md](docs/DEVELOPMENT-PLAN.md). Working title. The previous game, Flannan Light, is kept on the branch `archive/flannan-light-v1`.

## Layout
- `game/` Godot 4.7.2 project (GDScript, Compatibility renderer).
- `.github/workflows/deploy.yml` builds the web export and publishes it to GitHub Pages.
- `docs/` design documents, `docs/CREDITS.md` asset credits.

## Run locally
```bash
godot --path game                                             # editor/runtime
godot --headless --path game --script res://tests/smoke.gd    # smoke test
godot --path game res://scenes/world.tscn -- --spawn=living --res=720   # debug spawn and picture height
```

Debug spawns: `door`, `hall`, `phone`, `end`, `hallw`, `bedroom`, `dressing`, `bath`, `dads`, `spare`, `utility`, `kitchen`, `living`, `box`, `study`, and `plan` (top-down, ceilings hidden). On the web build use `?spawn=living&res=720&grade=1&shadows=1&fx=3&fear=0.5`.

All characters in the game are fictional.
