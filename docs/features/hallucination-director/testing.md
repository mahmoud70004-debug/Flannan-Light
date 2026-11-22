# Hallucination director: testing

**Updated:** 2026-11-22 · [design](design.md)

- [x] Every event named in the day data has a handler *(tests/smoke.gd › `_check_story_content`)*
- [x] Every random event fires once on every day without errors, and every scripted event fires *(tests/smoke.gd › `_playthrough`)*
- [x] Every stranger spot is free floor for the player's capsule *(tests/smoke.gd)*
- [ ] The scares are unsettling without being cheap *(not proven: needs a playtest)*
- [ ] The stranger never appears in view or closer than it should *(partly: spawn rules are code, the feel needs a playtest)*
