# Narrative

**Status:** designed · **Updated:** 2026-11-21 · [GDD](../../GDD.md)

How the story is told. The player must not learn that Martin is ill from a character saying so; they should work it out after the fact, from clues they already saw.

## Method (recommended)
1. **Spine: in-engine, first-person, never cutaways.** Scripted moments keep the player's camera (a short lock, a slow turn): the phone ringing, a door that closes, the stranger in the room.
2. **Martin's inner voice:** short lines (max ~12 words) shown on screen when he examines something or reacts (`Hud.say`). Plain, tired, defensive. It is his point of view, so it may be wrong.
3. **Found documents and devices:** the dismissal letter, laptop emails, phone messages, landline voicemails from Jack, appointment cards. These carry the facts and the clues.
4. **Cutscenes only three times:** the opening (the day he was fired), the midpoint (Jack's call), the ending (the flat, weeks later). All in-engine with a controlled camera. [ASSUMPTION]

## Story timeline [ASSUMPTION]
| Day | Martin's tasks | What happens | Clue to the truth |
|---|---|---|---|
| 1 | Read the letter, eat, apply for jobs | A cough in the corridor; he shrugs | The letter says "psychological problems"; he does not understand it |
| 2 | Shower, shop list, laptop | Footsteps at night | Prescription bottle on the shelf, never touched |
| 3 | Eat, laptop | Knocking at the closet | The chain is on the front door; nobody came in |
| 4 | Call Jack (voicemail) | A figure at the end of the corridor, gone when the light flickers | The phone log shows no incoming calls he heard |
| 5 | Eat, search for the intruder | Lights go out; laughter | Two plates on the table, one person |
| 6 | Check the flat, barricade | The stranger stands in the bedroom, still | Phone photos show empty rooms |
| 7 | Jack finally calls | Jack's side does not match what Martin answers | Jack asks about a doctor and about the pills |
| 8–9 | Hide, no tasks work | The stranger is closer; its clothes are Martin's | The "intruder" never leaves any trace |
| 10 | Face it | Martin stops; the screen holds; cut | Epilogue: weeks later, mail on the floor, the phone ringing and nobody answers |

## Edge cases
- The player who explores everything sees the clues first; the one who only follows tasks still gets the ending.
- No document says "schizophrenia" or any diagnosis; the word in the letter is only "psychological".

## Open questions
- Voice acting or text only for Jack's voicemails? Text-on-screen with a muffled voice is cheaper. [ASSUMPTION]
