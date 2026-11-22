# Hallucination director: implementation

**Updated:** 2026-11-22 · [design](design.md)

- `game/scripts/director.gd`: one `_ev_<name>` coroutine per event (cough, footsteps, knock, door creak/open, lights flicker/out, phone ring, whisper, laugh, breath, TV static, stranger far/near/hall); the day's data in `days.gd` chooses which are allowed and how often. Scripted events fire at fixed times; the bed waits until they have.
- `game/scripts/stranger.gd`: the figure, its look-away rules and stop-motion pose; `director._spawn_stranger` places it only where it is unseen but in line of sight.
- `game/scripts/ambience.gd`: room tone, fridge, drip, clock tick, drone and heartbeat that follow fear, and hushes before scares.
- Fear: `Story.fear` (a day's base value, a rise through the day, spikes from events) drives the pixel/dither filter, lamp flicker, camera shake, blinks and heartbeat throb. "Flashing effects: reduced" in the pause menu turns the strobing parts down.
