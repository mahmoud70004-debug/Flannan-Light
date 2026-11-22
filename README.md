# No One Home

First-person 3D psychological horror for Android, by Pottsfield Studio. Martin has lost his job, his savings and, over ten days, his grip on what is real. One flat, one long corridor, and someone who may not be there.

**Play the latest build:** https://mahmoud70004-debug.github.io/Flannan-Light/ (updates automatically on every push to `main`; the build number is shown on the title screen; the URL changes when the repository is renamed).

Status: the whole game is playable on the `dev` branch (ten days, ending, save). `main` deploys the web build and is only updated on request. See [docs/GDD.md](docs/GDD.md) and [docs/DEVELOPMENT-PLAN.md](docs/DEVELOPMENT-PLAN.md). Working title. The previous game, Flannan Light, is kept on the branch `archive/flannan-light-v1`.

## Branches
- `main` builds and deploys the web build to GitHub Pages on every push.
- `dev` is where work happens: every push runs the import, the smoke test (a bot plays all ten days and the ending) and a web-export check, without deploying.
- `archive/flannan-light-v1` is the previous game.

## Layout
- `game/` Godot 4.7.2 project (GDScript, Compatibility renderer).
- `.github/workflows/deploy.yml` builds the web export and publishes it to GitHub Pages.
- `docs/` design documents, `docs/CREDITS.md` asset credits.
- `tools/audio`, `tools/tts` generators for every sound and voice (numpy, kokoro-onnx); outputs are committed under `game/assets/audio`.

## Run locally
```bash
godot --path game                                             # editor/runtime
godot --headless --path game --script res://tests/smoke.gd    # smoke test
godot --path game res://scenes/world.tscn -- --spawn=living --res=720   # debug spawn and picture height
```

Debug spawns: `door`, `hall`, `phone`, `end`, `hallw`, `bedroom`, `dressing`, `bath`, `dads`, `spare`, `utility`, `kitchen`, `living`, `box`, `study`, and `plan` (top-down, ceilings hidden). On the web build use `?spawn=living&res=720&grade=1&shadows=1&fx=3&fear=0.5`.

All characters in the game are fictional.
