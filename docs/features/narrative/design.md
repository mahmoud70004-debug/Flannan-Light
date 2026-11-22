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

## Phone calls Martin answers (v0.4)

Jack's messages were shortened (voicemails 9 to 18 s, calls 23 to 32 s) and re-recorded with `tools/tts/gen_calls.py`.
The first takes sounded synthetic: every sentence was read at 0.9x with the same gap and level, then pitched down.
Now speed stays at or above 1.0, every chunk has its own speed, pitch and level jitter, gaps vary, and the worry comes
from short broken phrases, breaths and sighs.

Three messages are live calls (`"call": true` in their JSON): the phone rings and Martin picks up. His first take
(lowered, dulled, squashed, 0.9x) sounded robotic, so Martin is now voiced like Jack: am_adam at normal speed with the
same jitter, only quicker and tenser. The dialogue is short and gets worse each time; he tells Jack what he sees and hears.

| Day | Call | Martin |
|---|---|---|
| 5 | vm2 | Hides it: "It's just the building. Something knocks, at night." "It's the pipes. Forget it." |
| 7 | vm3 | Admits it: he stopped seeing Dr. Hale; sees someone at the end of the hall who is gone when he looks again; hears laughing, footsteps, knocking with nobody there; "I don't know. I think so. They don't help." |
| 9 | vm4 | Frantic: "It stands there, and when I look it's gone, and then I hear it laughing." The phone rings with nobody there, the TV comes on, it whispered his name. Then, whispering: "There's someone else on the line. He's listening." A second breath joins the line. |

Voicemails (vm0, vm1, vm5 to vm7) are still Jack alone, through the machine. Captions carry the speaker (`who`).
