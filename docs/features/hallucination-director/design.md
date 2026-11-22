# Hallucination director

**Status:** implemented · **Updated:** 2026-11-21 · [GDD](../../GDD.md)

Schedules small wrong things inside the player's tasks. Nothing it does hurts Martin or blocks him; a scare is a sound, a light, or a figure that was not there a second ago.

## Rules
1. An event is data: trigger (task started, room entered, time in room, idle seconds), effect, tier, and `once` or `repeat`.
2. Effects available (all cheap, none change the layout of the flat, see D-002): play a spatial sound at a point; flicker or cut a room's lamps; open or close a door; show the stranger at a point; ring the landline; show a monologue line.
3. **Look-away rule:** the stranger appears or moves only when it is outside the camera frustum, and holds still while seen. Never closer than 3 m on days 1–5.
4. **No attack.** The stranger never touches Martin. After lights return, it is gone.
5. Tier rises by day (1 a sound, 2 a thing moved, 3 a figure seen, 4 the figure moves, 5 close and still); it never goes down, only quiet days by authored silence.
6. A cooldown of at least 40 s between events, and a guaranteed quiet minute after any lights-out, so the player can breathe.

## Numbers [ASSUMPTION]
| Day | Tier | Events per day |
|---|---|---|
| 1–2 | 1 | 2–3 sounds |
| 3–4 | 2 | 3–4 |
| 5–6 | 3 | 4–5 incl. first figure |
| 7–8 | 4 | 5 |
| 9–10 | 5 | 4, longer |

## Open questions
- The stranger's model: scanned/MPFB base or hand-modelled, stop-motion at 12 fps. To decide in M3.
