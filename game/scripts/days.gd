class_name Days
## The story as data: ten days, each with its tasks, scripted and random events, how bad the
## flat smells, and what Martin says. Writing a day is writing content, not code.
##
## task: {id, text, steps: [use ids in order], say: [lines when done], doc: document id shown on the last step}
## scripted: [{after: task id | "start", delay: s, do: event}] or {when: task id (it becomes the objective), ...}.
##   They hang on what the player has done, so they land in the quiet stretches between tasks, never on a clock.
## night: events during the sleep sequence.
## events.pool: the random events allowed that day; events.every: [min, max] seconds between them;
##   events.first: how long before the first random one.
## task.think: what Martin says to himself when the task begins (else THINK[id]); task.obj: objective text per step.

const COUNT := 10
const PHOTO_STEP := "photo"           ## a task step satisfied by taking a photo with the phone

const DATA := [
	{
		"title": "DAY 1", "sub": "Monday, 7:14 p.m.",
		"intro": ["They let me go on Friday.", "Three days. I still haven't told anyone."],
		"tasks": [
			{"id": "read_letter", "text": "Read the letter", "steps": ["mail"], "doc": "letter",
				"say": ["\"Psychological problems.\"", "I don't even know what that means."]},
			{"id": "eat", "text": "Eat something", "steps": ["fridge", "sofa"],
				"say": ["It tastes like nothing."]},
			{"id": "job_search", "text": "Apply for a job", "steps": ["laptop"], "doc": "inbox_1",
				"say": ["Another résumé into the void."]},
		],
		"flies": 0.25, "fear": 0.10,
		"events": {"pool": ["cough"], "every": [150.0, 230.0], "first": 170.0},
		"scripted": [{"after": "read_letter", "delay": 45.0, "do": "cough"}, {"after": "eat", "delay": 30.0, "do": "phone_ring"}],
		"vm": "vm0",
		"night": [],
		"sleep_line": "Tomorrow I'll do better.",
	},
	{
		"title": "DAY 2", "sub": "Tuesday",
		"intro": ["Seven hours of sleep and I still feel like I haven't slept."],
		"tasks": [
			{"id": "shower", "text": "Take a shower", "steps": ["shower"], "say": ["The water runs cold before I'm done.", "Good. I deserve it."]},
			{"id": "eat", "text": "Eat something", "steps": ["fridge", "sofa"], "say": ["The bread is hard at the edges."]},
			{"id": "job_search", "text": "Check the inbox", "steps": ["laptop"], "doc": "inbox_2", "say": ["Nobody wants a man who was fired for being \"unwell\"."]},
		],
		"flies": 0.35, "fear": 0.16,
		"events": {"pool": ["cough", "footsteps"], "every": [120.0, 190.0], "first": 120.0},
		"scripted": [{"after": "shower", "delay": 35.0, "do": "footsteps"}, {"after": "eat", "delay": 50.0, "do": "cough"}],
		"night": ["footsteps_door"],
		"sleep_line": "The neighbours must be home.",
	},
	{
		"title": "DAY 3", "sub": "Wednesday",
		"intro": ["The flat smells. I should deal with it.", "I will. Tomorrow."],
		"tasks": [
			{"id": "eat", "text": "Eat something", "steps": ["fridge", "sofa"], "say": ["I'm not hungry. I eat anyway."]},
			{"id": "job_search", "text": "Read Mr. Whitmore's email", "steps": ["laptop"], "doc": "inbox_3", "say": ["He says it's \"for the best\"."]},
			{"id": "trash", "text": "Take the trash out", "steps": ["trash", "front_door"], "obj": ["Take the bag from the kitchen corner", "Take it to the front door"],
				"say": ["The chain is on.", "It's always on. Isn't it?", "I'll do it tomorrow."]},
		],
		"flies": 0.45, "fear": 0.22,
		"events": {"pool": ["cough", "footsteps", "knock", "door_creak"], "every": [105.0, 170.0], "first": 100.0},
		"scripted": [{"after": "eat", "delay": 35.0, "do": "knock"}, {"after": "job_search", "delay": 30.0, "do": "knock_door"}],
		"night": ["knock_front"],
		"sleep_line": "Someone knocked. Or the pipes did.",
	},
	{
		"title": "DAY 4", "sub": "Thursday",
		"intro": ["I keep hearing things.", "It's an old building. Old buildings talk."],
		"tasks": [
			{"id": "eat", "text": "Eat something", "steps": ["fridge", "sofa"], "say": ["Not much left."]},
			{"id": "phone", "text": "Check the answering machine", "steps": ["phone"], "vm": "vm1", "say": ["Jack.", "I can't call him back. What would I say?"]},
			{"id": "job_search", "text": "Apply for a job", "steps": ["laptop"], "doc": "inbox_4", "say": ["Same replies, different logos."]},
		],
		"flies": 0.55, "fear": 0.30,
		"events": {"pool": ["footsteps", "knock", "door_creak", "lights_flicker", "whisper"], "every": [95.0, 150.0], "first": 90.0},
		"scripted": [{"when": "phone", "delay": 6.0, "do": "phone_ring"}, {"after": "job_search", "delay": 30.0, "do": "lights_flicker"}],
		"night": ["stranger_hall"],
		"sleep_line": "There was someone at the end of the hall. There wasn't.",
	},
	{
		"title": "DAY 5", "sub": "Friday",
		"intro": ["A week since they let me go.", "Somebody is in this flat. I'm sure of it."],
		"tasks": [
			{"id": "search", "text": "Search the rooms", "steps": ["wardrobe", "jack_desk", "dad_boxes"], "say": ["Nothing.", "Nobody.", "Then who is breathing?"]},
			{"id": "photo", "text": "Photograph the hall (take 2 photos)", "steps": ["photo", "photo"], "say": ["I'll have proof."]},
			{"id": "eat", "text": "Eat something", "steps": ["fridge", "sofa"], "say": ["I eat standing up. Watching the hall."]},
		],
		"flies": 0.65, "fear": 0.38,
		"events": {"pool": ["footsteps", "knock", "door_creak", "lights_flicker", "whisper", "laugh", "stranger_far"], "every": [85.0, 135.0], "first": 80.0},
		"scripted": [{"after": "search", "delay": 40.0, "do": "whisper"}, {"after": "photo", "delay": 35.0, "do": "lights_out"}, {"after": "eat", "delay": 25.0, "do": "phone_ring"}],
		"night": ["footsteps_door", "knock_front"],
		"sleep_line": "I'm leaving the lamp on.",
		"vm": "vm2",
	},
	{
		"title": "DAY 6", "sub": "Saturday",
		"intro": ["It watches me when I'm not looking.", "I have to keep looking."],
		"tasks": [
			{"id": "check_door", "text": "Check the front door", "steps": ["front_door"], "say": ["Locked. Chained. From the inside.", "So how does it get in?"]},
			{"id": "check_window", "text": "Check the windows", "steps": ["window_living"], "say": ["Four floors up. Nobody climbs that."]},
			{"id": "eat", "text": "Eat something", "steps": ["fridge", "sofa"], "say": ["Crackers. It's all there is."]},
		],
		"flies": 0.75, "fear": 0.46,
		"events": {"pool": ["footsteps", "knock", "door_creak", "lights_flicker", "whisper", "laugh", "stranger_far", "door_open"], "every": [75.0, 120.0], "first": 70.0},
		"scripted": [{"after": "check_door", "delay": 40.0, "do": "laugh"}, {"after": "check_window", "delay": 35.0, "do": "door_open"}, {"after": "eat", "delay": 20.0, "do": "stranger_far"}],
		"night": ["stranger_bed"],
		"sleep_line": "Don't look at the foot of the bed.",
	},
	{
		"title": "DAY 7", "sub": "Sunday",
		"intro": ["Jack called again. I let it ring.", "Eleven rings. I counted."],
		"tasks": [
			{"id": "phone", "text": "Answer the phone", "steps": ["phone"], "vm": "vm3", "say": ["He talked to Whitmore.", "Everyone's talking about me."]},
			{"id": "pills", "text": "Look in the medicine cabinet", "steps": ["pills"], "doc": "pills", "say": ["I don't need them.", "I'm not sick. Somebody else is the problem."]},
			{"id": "job_search", "text": "Check the inbox", "steps": ["laptop"], "doc": "inbox_7", "say": ["Dr. Hale's office. Three missed appointments."]},
		],
		"flies": 0.85, "fear": 0.55,
		"events": {"pool": ["footsteps", "knock", "lights_flicker", "whisper", "laugh", "stranger_far", "door_open", "breath", "lights_out"], "every": [65.0, 105.0], "first": 60.0},
		"scripted": [{"when": "phone", "delay": 8.0, "do": "phone_ring"}, {"after": "pills", "delay": 30.0, "do": "lights_out"}, {"after": "job_search", "delay": 20.0, "do": "stranger_far"}],
		"night": ["stranger_bed", "whisper_bed"],
		"sleep_line": "I took none of them. It's still here.",
		"vm": "vm3",
	},
	{
		"title": "DAY 8", "sub": "Monday",
		"intro": ["My coat is gone.", "It was on the hook. I'm sure."],
		"tasks": [
			{"id": "find_coat", "text": "Find your coat", "steps": ["wardrobe", "dad_boxes", "jack_desk"], "say": ["It's not here. It's not anywhere.", "It took my coat."]},
			{"id": "eat", "text": "Find something to eat", "steps": ["fridge"], "say": ["Everything is rotten.", "I'm not even hungry."]},
		],
		"flies": 0.95, "fear": 0.64,
		"events": {"pool": ["footsteps", "knock", "lights_flicker", "whisper", "laugh", "stranger_far", "stranger_near", "door_open", "breath", "lights_out", "tv_static"], "every": [55.0, 95.0], "first": 55.0},
		"scripted": [{"after": "start", "delay": 70.0, "do": "tv_static"}, {"after": "find_coat", "delay": 35.0, "do": "stranger_near"}, {"after": "eat", "delay": 20.0, "do": "lights_out"}],
		"night": ["stranger_bed", "whisper_bed"],
		"sleep_line": "It's wearing something familiar.",
	},
	{
		"title": "DAY 9", "sub": "Tuesday",
		"intro": ["The phone is ringing.", "It has been ringing for a long time."],
		"tasks": [
			{"id": "phone", "text": "Pick up the phone", "steps": ["phone"], "vm": "vm4", "say": ["Jack. He's pleading.", "Why is he pleading?"]},
			{"id": "gallery", "text": "Look through the photos", "steps": ["laptop"], "doc": "photos", "say": ["Empty rooms. Every one.", "I saw it. I saw it standing right there."]},
		],
		"flies": 1.0, "fear": 0.76,
		"events": {"pool": ["footsteps", "lights_flicker", "whisper", "laugh", "stranger_far", "stranger_near", "door_open", "breath", "lights_out", "tv_static", "knock"], "every": [50.0, 85.0], "first": 50.0},
		"scripted": [{"when": "phone", "delay": 8.0, "do": "phone_ring"}, {"after": "phone", "delay": 45.0, "do": "stranger_near"}, {"after": "gallery", "delay": 25.0, "do": "lights_out"}],
		"night": ["stranger_bed", "whisper_bed", "stranger_hall"],
		"sleep_line": "Tomorrow it ends. One way or the other.",
		"vm": "vm4",
	},
	{
		"title": "DAY 10", "sub": "Wednesday",
		"intro": ["Ten days.", "Ten days of being watched.", "I want it to look at me."],
		"tasks": [
			{"id": "call_jack", "text": "Call Jack", "steps": ["phone"], "say": ["His voicemail.", "I can't say anything.", "I hang up."]},
			{"id": "look_photo", "text": "Look at the photo of Mom and Dad", "steps": ["photo_parents"], "doc": "photo_parents", "say": ["I miss them.", "I never told anyone how much."]},
		],
		"flies": 1.0, "fear": 0.88,
		"events": {"pool": ["footsteps", "lights_flicker", "whisper", "laugh", "stranger_near", "breath", "tv_static"], "every": [45.0, 70.0], "first": 50.0},
		"scripted": [{"after": "start", "delay": 45.0, "do": "tv_static"}],
		"night": [],
		"sleep_line": "",
		"final": true,
	},
]


## What Martin says to himself when a task begins: the thought comes first, then the objective appears.
const THINK := {
	"read_letter": "That letter by the door. I keep walking past it.",
	"eat": "I have to eat something.",
	"job_search": "Maybe somebody answered. I should look at the inbox.",
	"shower": "I need a shower. I can smell myself.",
	"trash": "The bin is overflowing. I can't keep ignoring it.",
	"phone": "The phone. Is the machine light blinking?",
	"search": "Somebody has been in here. I'll go through every room.",
	"photo": "I need proof. I'll photograph the hall.",
	"check_door": "Did I lock the front door? I have to check.",
	"check_window": "The windows. What if it comes in that way?",
	"pills": "Maybe I should look at what I'm supposed to be taking.",
	"find_coat": "Where is my coat? It was on the hook.",
	"gallery": "The photos I took. I should look at them again.",
	"call_jack": "I should call Jack. I have to say something to him.",
	"look_photo": "I want to see Mom and Dad.",
}

## The objective shown at the top of the screen for each step (a task can override with its own `obj` list).
const OBJ := {
	"mail": "Look at the mail by the front door",
	"fridge": "Go to the kitchen",
	"sofa": "Eat on the sofa",
	"laptop": "Sit down at the laptop in the living room",
	"shower": "Go to the bathroom",
	"trash": "Take the bag from the kitchen corner",
	"front_door": "Go to the front door",
	"phone": "Answer the phone in the hall",
	"wardrobe": "Search the wardrobe in your bedroom",
	"jack_desk": "Search Jack's old desk in the other bedroom",
	"dad_boxes": "Search the boxes in the storage room",
	"photo": "Take a photo of the hall (PHOTO button)",
	"window_living": "Look out of the living room window",
	"pills": "Open the cabinet in the bathroom",
	"photo_parents": "Look at the photo on the TV stand",
}


static func think_for(t: Dictionary) -> String:
	return str(t.get("think", THINK.get(t["id"], "")))


static func objective(t: Dictionary, idx: int) -> String:
	var steps: Array = t["steps"]
	idx = clampi(idx, 0, steps.size() - 1)
	var text := ""
	if t.has("obj") and (t["obj"] as Array).size() > idx:
		text = str(t["obj"][idx])
	else:
		text = str(OBJ.get(steps[idx], t["text"]))
	if steps[idx] == PHOTO_STEP and steps.size() > 1:
		text += " (%d/%d)" % [idx + 1, steps.size()]
	return text


static func get_day(n: int) -> Dictionary:
	return DATA[clampi(n, 1, COUNT) - 1]


## What Martin says when he looks at something that is not part of a task. Day ranges pick the line.
const EXAMINE := {
	"front_door": [[1, ["I'm not going out today."]], [3, ["The chain is on. I never take it off."]], [6, ["Locked from the inside. Always."]]],
	"mail": [[1, ["More envelopes. I've read enough of them."]]],
	"fridge": [[1, ["Not hungry."]], [5, ["Something in there is moving. It's only the light."]]],
	"trash": [[1, ["I should take this out. Later."]], [4, ["The flies don't bother me anymore."]], [8, ["I don't smell it anymore. That's the worst part."]]],
	"kitchen_food": [[1, ["Last week's dinner."]], [4, ["It's growing fur. It's almost alive."]]],
	"dining_food": [[1, ["I'll clear the table. Soon."]], [4, ["Two plates. Why are there two plates?"]]],
	"tv": [[1, ["Nothing on but the news."]], [7, ["I only get static now."]]],
	"sofa": [[1, ["I'll sit down when I'm hungry."]]],
	"laptop": [[1, ["Nothing new."]], [5, ["The inbox is empty. Is that better or worse?"]]],
	"window_living": [[1, ["The street looks the same as it always did."]], [6, ["Nobody's down there. Nobody is ever down there."]]],
	"photo_parents": [[1, ["Mom and Dad. At the lake."]]],
	"bed1": [[1, ["I'm not tired yet."]]],
	"wardrobe": [[1, ["Just my clothes."]]],
	"dad_boxes": [[1, ["Dad's things. I haven't opened them since the funeral."]]],
	"jack_desk": [[1, ["Jack's old desk. He drew on it with a compass."]]],
	"pills": [[1, ["A bathroom cabinet. Razor, aspirin, nothing else."]], [7, ["The pills are still in the bag."]]],
	"shower": [[1, ["Later."]]],
	"phone": [[1, ["The machine light isn't blinking."]], [4, ["The machine light is blinking."]]],
	"clock": [[1, ["The clock on the wall is right. For now."]], [5, ["It says 3:07. It says 3:07 every time I look."]], [9, ["The second hand hasn't moved in days."]]],
	"calendar": [[1, ["The calendar. Friday is circled in red."]], [5, ["More days are crossed off than have passed."]], [8, ["Every square is crossed off. Even the ones that haven't happened yet."]]],
	"mirror_entry": [[1, ["A tired man looks back at me."]], [6, ["My reflection is a half-second behind me."]], [9, ["There's someone standing behind me in the glass. I turn. Nobody."]]],
}


static func examine(id: String, day: int) -> Array:
	var best: Array = []
	for entry in EXAMINE.get(id, []):
		if day >= entry[0]:
			best = entry[1]
	return best


## What he says when the bed is not ready for him yet.
const NOT_YET := ["I can't sleep yet. There's still something I have to do.", "Not yet.", "Something's left undone."]


## Martin thinking aloud when the player has been idle for a while: what the next step is and where.
const HINT := {
	"mail": "There's a pile of mail by the front door I haven't touched.",
	"fridge": "I should find something to eat. The kitchen.",
	"sofa": "I'll eat on the sofa, like always.",
	"laptop": "The laptop is on the desk in the living room.",
	"shower": "A shower. The bathroom is down the hall.",
	"trash": "The kitchen bin is overflowing.",
	"front_door": "The front door.",
	"phone": "The phone, at the far end of the hall.",
	"wardrobe": "My wardrobe, in the bedroom.",
	"jack_desk": "Jack's old room, next to mine.",
	"dad_boxes": "Dad's boxes in the storage room.",
	"pills": "The medicine cabinet in the bathroom.",
	"window_living": "The windows in the living room.",
	"photo_parents": "The photo of Mom and Dad on the TV stand.",
	"photo": "I could photograph the hall with my phone.",
}

## What is on the TV each day (shown as captions).
const TV := [
	"...rain expected through Thursday, with temperatures falling overnight.",
	"...a man was found by his neighbours after, in the words of one, \"nobody had seen him for weeks.\"",
	"...police are asking anyone with information to come forward. Anyone at all.",
	"...for the third night in a row, residents report knocking from empty flats.",
	"...do not open your door to strangers. We repeat, do not open your door.",
	"...the missing man was last seen at home. He had no friends. No one came looking.",
	"...Martin. Martin. Are you there, Martin?",
	"...[static]  ...is behind you...  [static]",
	"...we are sorry. There is no one left to tell.",
	"...[static]",
]


static func peephole(day: int) -> Array:
	if day < 4:
		return ["I look through the peephole.", "Nobody. Just the hallway light, humming."]
	if day < 8:
		return ["I look through the peephole.", "Nobody. But the hall light is flickering.", "Somebody was just there."]
	return ["I look through the peephole.", "A tall shape stands in the corridor, very still.", "I blink. It's gone."]


## Martin reacting out loud when something happens: [from day, [lines]] per event; the latest set that applies is used.
const REACT := {
	"cough": [[1, ["Hello?", "...Did someone just cough?"]], [6, ["Again.", "I know you're there."]]],
	"footsteps": [[1, ["The neighbours."]], [4, ["Those aren't the neighbours' steps."]], [8, ["Walk. Walk all you like."]]],
	"knock": [[3, ["Hello?", "Who is it?"]], [6, ["I'm not opening it."]]],
	"knock_door": [[3, ["Hello?"]], [6, ["Inside the flat. It knocks from inside."]]],
	"door_creak": [[2, ["The draught."]], [6, ["It wants me to look."]]],
	"door_open": [[2, ["The draught."]], [6, ["It wants me to look."]]],
	"lights_flicker": [[4, ["The wiring. It's only the wiring."]], [7, ["Stop it."]]],
	"lights_out": [[5, ["Not again."]], [8, ["I'm not afraid of the dark. I'm afraid of what's in it."]]],
	"whisper": [[5, ["Who said that?"]], [8, ["I hear you."]]],
	"laugh": [[5, ["What's so funny?"]], [8, ["Laugh. Go on."]]],
	"breath": [[7, ["I can hear it breathe."]]],
	"tv_static": [[8, ["It's talking to me."]]],
	"first_seen": [[4, ["Someone's there. Someone's there."]], [6, ["Don't move. Don't blink."]], [8, ["It's wearing my coat."]], [9, ["Why does it look so familiar?"]]],
}


static func react(event_name: String, day: int) -> String:
	var best: Array = []
	for entry in REACT.get(event_name, []):
		if day >= entry[0]:
			best = entry[1]
	return "" if best.is_empty() else str(best[randi() % best.size()])
