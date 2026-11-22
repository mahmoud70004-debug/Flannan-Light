# Narrative

**Status:** implemented · **Updated:** 2026-11-21 · [GDD](../../GDD.md)

How the story is told. The player must not learn that Martin is ill from a character saying so; they should work it out after the fact, from clues they already saw.

## Method (recommended)
1. **Spine: in-engine, first-person, never cutaways.** Scripted moments keep the player's camera (a short lock, a slow turn): the phone ringing, a door that closes, the stranger in the room.
2. **Martin's inner voice:** short lines (max ~12 words) shown on screen when he examines something or reacts (`Hud.say`). Plain, tired, defensive. It is his point of view, so it may be wrong.
3. **Found documents and devices:** the dismissal letter, laptop emails, phone messages, landline voicemails from Jack, appointment cards. These carry the facts and the clues.
4. **Cutscenes only three times:** the opening (the day he was fired), the midpoint (Jack's call), the ending (the flat, weeks later). All in-engine with a controlled camera. [ASSUMPTION]

## Story timeline (as implemented in `scripts/days.gd`)
| Day | Martin's tasks | What happens | Clue to the truth |
|---|---|---|---|
| 1 | Read the letter, eat, apply for a job | A cough from a room he isn't in | The letter: "psychological problems"; Jack's unread email |
| 2 | Shower, eat, check the inbox | Footsteps; at night, steps at the bedroom door | Prescription mentioned by a recruiter |
| 3 | Eat, read Whitmore's email, take the trash out | Knocking; the chain on the front door can't be passed | Whitmore describes "calls you swore you never made" |
| 4 | Eat, the answering machine (voicemail 1), apply | Lights flicker; the stranger at the end of the hall at night | Dr. Hale's missed appointment |
| 5 | Search the rooms, photograph the hall twice, eat | Whispers, lights out, the phone (voicemail 2) | Two plates on the table, one person; the photos |
| 6 | Check the door and the windows, eat | Laughter, a door opens by itself, the stranger at the foot of the bed | "Locked from the inside. Always." |
| 7 | Voicemail 3 (doctor, pills), the medicine cabinet, inbox | Lights out, the stranger | The unopened pill bottle; the pharmacy and Dr. Hale emails |
| 8 | Find the coat, find something to eat | TV static, the stranger close | The coat is gone: the stranger is wearing it |
| 9 | Voicemail 4, look through the photos | The stranger close, nights in the hall | Fourteen photos of empty rooms |
| 10 | Call Jack (his greeting; Martin says nothing), look at Mom and Dad | The stranger waits in the living room; its face is his | Ending, then 41 days later |

## Edge cases
- The player who explores everything sees the clues first; the one who only follows tasks still gets the ending.
- No document says "schizophrenia" or any diagnosis; the word in the letter is only "psychological".

## Open questions
- Voice acting or text only for Jack's voicemails? Text-on-screen with a muffled voice is cheaper. [ASSUMPTION]
