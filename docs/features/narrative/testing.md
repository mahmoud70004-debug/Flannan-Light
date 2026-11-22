# Narrative: testing

**Updated:** 2026-11-22 · [design](design.md)

- [x] Every task step is a prop that exists in the flat; every document, voicemail and sound a day names exists *(tests/smoke.gd › `_check_story_content`)*
- [x] A bot plays days 1–10 (tasks, every random and scripted event once, the nights), the last-day scene, the ending and the epilogue to the end, and the save is marked finished *(tests/smoke.gd › `_playthrough`)*
- [x] Every prop the game uses can be used from a spot the player can stand on *(tests/smoke.gd › `_use_points_work`)*
- [ ] The story reads well and the pacing feels right *(not proven: needs a playtest on the phone)*
- [ ] Jack's voicemails sound sad and worried without being slow *(not proven: needs listening)*
