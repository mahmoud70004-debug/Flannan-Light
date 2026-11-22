# Narrative: implementation

**Updated:** 2026-11-22 · [design](design.md)

- **Content:** `game/scripts/days.gd` (tasks, intros, events, night events, examine lines, reactions, TV news, hints, peephole), `game/scripts/docs.gd` (the letter, inbox, notes, labels, photo captions).
- **Flow:** `game/scripts/story.gd` runs a day: card, waking in bed, the task note, `used(id)` from the flat, documents, the phone and answering machine, sleeping (the bed waits for the day's scripted events), the night, the last day and the epilogue.
- **State and save:** `game/scripts/game_state.gd` (autoload), one slot in `user://save.cfg`, written after each task and each night.
- **Voices:** `tools/tts/gen_game_voices.py` writes the WAV and a caption JSON per voicemail (`vm1`–`vm7`, `jack_greeting`); the game reads the JSON to show timed captions.
- **Debug:** `--day=N`, `--show=<doc|tasks|say|stranger|final|epilogue>` on the Godot command line or in the web URL (see the README).
