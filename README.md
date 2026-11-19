# Flannan Light

First-person 3D psychological horror for Android, by Pottsfield Studio. You are a new lighthouse keeper in the early 1900s. The routine is calm, until it is not.

**Play the latest build:** https://mahmoud70004-debug.github.io/Flannan-Light/ (updates automatically on every push to `main`; the build number is shown on the title screen).

Status: pre-production, phase 0 (pipeline). See [docs/GDD.md](docs/GDD.md) and [docs/DEVELOPMENT-PLAN.md](docs/DEVELOPMENT-PLAN.md).

## Layout
- `game/` Godot 4.7.2 project (GDScript, Compatibility renderer).
- `.github/workflows/deploy.yml` builds the web export and publishes it to GitHub Pages.
- `docs/` design documents.

## Run locally
```bash
godot --path game                                             # editor/runtime
godot --headless --path game --script res://tests/smoke.gd    # smoke test
```

Inspired by the 1900 disappearance of the Flannan Isles keepers. All characters in the game are fictional.
