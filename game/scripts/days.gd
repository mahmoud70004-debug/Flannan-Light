class_name Days
## The story as data: ten days, each a flat that is a little wrong, a few tasks that walk Martin through it,
## a playable night, and the morning after in a place he did not go to sleep in.
##
## Truth (never stated, only inferable): Martin walks in his sleep and does not remember it. Everything "someone"
## does in the flat is him. He lost his job after being found at 3 a.m. standing in the archive, awake and not
## answering. Dr. Hale gave him rules; he stopped keeping them. Nobody asks after him, so nobody finds him.
##
## day: title/sub/intro; wake (where he finds himself: a WAKE spot); lit (rooms lit when the day starts);
##   anomalies (what is out of place today: see ANOMALY); tasks; flies; fear; events (RARE ambient only);
##   scripted [{after: task|"start", delay, do}]; night {cue, at, target, think, obj, found, evidence, stranger, dark};
##   sleep_line; vm (the day's phone message); final.
## task: {id, text, steps: [use ids in order], think, obj: [per step], say, doc, vm}

const COUNT := 10
const PHOTO_STEP := "photo"           ## a task step satisfied by taking a photo with the phone

## Things out of place. `notice`: where to look from (position, how close, which way is "toward it" is automatic).
## Looking at one for a moment makes Martin notice it: one line, a note in his notebook, a small sting.
const ANOMALY := {
	"door_bed1": {"at": Vector3(-4.9, 1.0, -5.6), "radius": 3.2, "lines": ["The bedroom door is open."], "evidence": "My bedroom door was open when I woke. I shut it. Rule two."},
	"kitchen_light": {"at": Vector3(2.4, 1.2, -1.2), "radius": 6.0, "lines": ["The kitchen light is on."], "evidence": "The kitchen light was on. I never go in there at night."},
	"hall_chair": {"at": Vector3(-3.7, 0.5, -4.5), "radius": 3.2, "lines": ["A chair, in the hall.", "Facing my door."], "evidence": "A dining chair stood in the hall, facing my bedroom door."},
	"prints": {"at": Vector3(-1.0, 0.0, -5.0), "radius": 3.5, "lines": ["Bare feet. Grey with dust.", "From my door to here."], "evidence": "Bare footprints, grey with dust, from my bedroom door to the living room."},
	"coat_floor": {"at": Vector3(0.1, 0.1, -0.9), "radius": 2.6, "lines": ["My coat. On the floor."], "evidence": "My coat was on the floor inside the front door, not on its hook."},
	"boxes_out": {"at": Vector3(-3.0, 0.3, -3.0), "radius": 3.0, "lines": ["Dad's boxes. Opened.", "Half of it is on the floor."], "evidence": "Dad's boxes were open and emptied onto the floor. I don't remember opening them."},
	"tub_water": {"at": Vector3(-5.2, 0.0, -2.6), "radius": 3.0, "lines": ["The tub is overflowing.", "My feet are wet."], "evidence": "The tub was running over and my feet were wet. I had not run a bath."},
	"coat_bed": {"at": Vector3(-1.55, 0.6, -7.8), "radius": 3.4, "lines": ["My coat. On Jack's bed.", "Folded."], "evidence": "My coat was folded on Jack's bed."},
	"table_set": {"at": Vector3(3.9, 0.8, -5.5), "radius": 3.0, "lines": ["The table is set.", "Two places. Both clean."], "evidence": "The dining table was set for two. The plates were clean."},
	"all_lit": {"at": Vector3(1.0, 1.0, -4.5), "radius": 99.0, "lines": ["Every light is on.", "Every door is open."], "evidence": "Every light in the flat was on and every door was open."},
}

## Where Martin finds himself when a day begins (see Apartment.WAKE). He is standing, awake, mid-step.
const WAKE_EVIDENCE := {
	"bed1": "",
	"tv": "I woke standing in front of the TV, in the dark.",
	"door": "I woke standing at the front door with my hand on the chain.",
	"storage": "I woke standing in the storage room.",
	"bath": "I woke standing in the bathroom, by the tub.",
	"bed2": "I woke in Jack's doorway.",
	"table": "I woke sitting at the dining table.",
}

const DATA := [
	{
		"title": "DAY 1", "sub": "Monday, 7:14 p.m.",
		"intro": ["I slept through the whole day again.", "They let me go on Friday. I still haven't told anyone."],
		"wake": "bed1", "lit": ["bed1", "living", "hall"], "anomalies": [],
		"tasks": [
			{"id": "rules", "text": "Read Dr. Hale's sheet", "steps": ["fridge"], "doc": "hale_rules",
				"think": "Dr. Hale's sheet is still on the fridge. I should read it again.", "obj": ["Go to the kitchen"],
				"say": ["Five rules. I keep three of them."]},
			{"id": "read_letter", "text": "Read the letter", "steps": ["mail"], "doc": "letter",
				"say": ["\"Psychological problems.\"", "I don't even know what that means."]},
			{"id": "lock_up", "text": "Lock up for the night", "steps": ["front_door"],
				"think": "Chain on. That's rule one.", "obj": ["Check the front door"],
				"say": ["Chain on. Door locked.", "Hall light on. Bedroom door shut. Good."]},
		],
		"flies": 0.2, "fear": 0.08,
		"events": {"pool": [], "every": [999.0, 999.0], "first": 999.0},
		"scripted": [{"after": "read_letter", "delay": 30.0, "do": "phone_ring"}],
		"night": {"cue": "tap", "at": "bath", "target": "shower", "think": "Running water. Is that the bathroom tap?", "obj": "Check the bathroom",
			"found": ["The tap is running.", "I turned it off. I always turn it off."], "evidence": "The bathroom tap was running at 3 a.m. I had turned it off.", "dark": false},
		"sleep_line": "Chain on. Hall light on. Door shut.",
		"vm": "vm0",
	},
	{
		"title": "DAY 2", "sub": "Tuesday, 6:52 p.m.",
		"intro": ["Seven hours of sleep and I still feel like I haven't slept."],
		"wake": "bed1", "lit": ["living", "hall", "kitchen"], "anomalies": ["door_bed1", "kitchen_light"],
		"tasks": [
			{"id": "eat", "text": "Eat something", "steps": ["fridge", "sofa"], "say": ["It tastes like nothing."]},
			{"id": "job_search", "text": "Check the inbox", "steps": ["laptop"], "doc": "inbox_2", "say": ["Nobody wants a man who was fired for being \"unwell\"."]},
			{"id": "lock_up", "text": "Lock up for the night", "steps": ["front_door"], "think": "Chain on. Hall light on. Door shut.", "obj": ["Check the front door"],
				"say": ["Chain on. Door locked."]},
		],
		"flies": 0.3, "fear": 0.14,
		"events": {"pool": [], "every": [999.0, 999.0], "first": 999.0},
		"scripted": [],
		"night": {"cue": "knock", "at": "front", "target": "front_door", "think": "Knocking. At the front door.", "obj": "Look through the peephole",
			"found": ["Nobody in the corridor.", "The chain is still on. Nobody came in."], "evidence": "Three knocks at 3 a.m. Nobody in the corridor. The chain was on.", "dark": false},
		"sleep_line": "I shut the door. I know I shut the door.",
	},
	{
		"title": "DAY 3", "sub": "Wednesday, 7:30 p.m.",
		"intro": ["There's a chair in the hall.", "It is facing my bedroom door."],
		"wake": "bed1", "lit": ["living", "hall"], "anomalies": ["hall_chair"],
		"tasks": [
			{"id": "trash", "text": "Take the trash out", "steps": ["trash", "front_door"], "obj": ["Take the bag from the kitchen corner", "Take it to the front door"],
				"say": ["The chain is on.", "It's always on. Isn't it?", "I'll do it tomorrow."]},
			{"id": "job_search", "text": "Read Mr. Whitmore's email", "steps": ["laptop"], "doc": "inbox_3", "say": ["He says it's \"for the best\"."]},
			{"id": "lock_up", "text": "Lock up for the night", "steps": ["front_door"], "think": "Chain on. Hall light on. Door shut.", "obj": ["Check the front door"],
				"say": ["Chain on."]},
		],
		"flies": 0.4, "fear": 0.2,
		"events": {"pool": [], "every": [999.0, 999.0], "first": 999.0},
		"scripted": [{"after": "trash", "delay": 45.0, "do": "knock"}],
		"night": {"cue": "chair", "at": "dining", "target": "dining_food", "think": "A chair scraping. In the living room.", "obj": "Check the dining table",
			"found": ["Both chairs are pulled out.", "Facing each other.", "I only ever sit on one side."], "evidence": "Both dining chairs were pulled out, facing each other, at 3 a.m.", "dark": true},
		"sleep_line": "Someone knocked. Or the pipes did.",
	},
	{
		"title": "DAY 4", "sub": "Thursday, 6:40 p.m.",
		"intro": ["I'm standing in the living room.", "The TV is hissing. I don't remember getting up."],
		"wake": "tv", "lit": ["living"], "anomalies": ["prints"], "tv_on": true,
		"tasks": [
			{"id": "photo", "text": "Photograph the prints", "steps": ["photo", "photo"], "think": "Somebody should see this. I'll take pictures.", "obj": ["Photograph the footprints (PHOTO button)", "Take another from the hall"],
				"say": ["Proof. In case I'm wrong."]},
			{"id": "phone", "text": "Check the answering machine", "steps": ["phone"], "vm": "vm1", "say": ["Jack.", "I can't call him back. What would I say?"]},
			{"id": "lock_up", "text": "Lock up for the night", "steps": ["front_door"], "think": "Chain on. Hall light on. Door shut.", "obj": ["Check the front door"],
				"say": ["Chain on. I checked twice."]},
		],
		"flies": 0.5, "fear": 0.28,
		"events": {"pool": [], "every": [999.0, 999.0], "first": 999.0},
		"scripted": [{"when": "phone", "delay": 6.0, "do": "phone_ring"}],
		"night": {"cue": "phone", "at": "phone", "target": "phone", "think": "The phone. It's off the hook. I can hear the tone from here.", "obj": "Go to the phone, at the end of the hall",
			"found": ["The handset is off the hook.", "The last call out was at 3:07."], "evidence": "The phone was off the hook. The last call out was at 3:07 a.m.", "figure": Vector3(-2.2, 0, -4.9), "dark": true},
		"sleep_line": "There was someone at the end of the hall. There wasn't.",
	},
	{
		"title": "DAY 5", "sub": "Friday, 7:05 p.m.",
		"intro": ["The front door is in front of me.", "My hand is on the chain."],
		"wake": "door", "lit": ["entry", "living", "hall"], "anomalies": ["coat_floor"],
		"tasks": [
			{"id": "check_door", "text": "Put the chain back on", "steps": ["front_door"], "think": "The chain is off. I didn't take it off.", "obj": ["Put the chain back on"],
				"say": ["Chain on.", "Nobody has a key but me."]},
			{"id": "search", "text": "Search the rooms", "steps": ["wardrobe", "jack_desk", "dad_boxes"], "think": "Somebody has been in here. I'll go through every room.",
				"say": ["Nothing.", "Nobody.", "Then who left my coat on the floor?"]},
			{"id": "lock_up", "text": "Lock up for the night", "steps": ["front_door"], "think": "Chain on. Hall light on. Door shut.", "obj": ["Check the front door"],
				"say": ["Chain on. Watching it."]},
		],
		"flies": 0.6, "fear": 0.36,
		"events": {"pool": [], "every": [999.0, 999.0], "first": 999.0},
		"scripted": [{"after": "search", "delay": 25.0, "do": "phone_ring"}],
		"night": {"cue": "steps", "at": "bed1door", "target": "photo_parents", "think": "Someone just walked past my door. Towards the living room.", "obj": "Check the living room",
			"found": ["Mom and Dad's photo is lying face down.", "I never touch it."], "evidence": "The photo of Mom and Dad was lying face down at 3 a.m.", "figure": Vector3(2.4, 0, -3.4), "dark": true},
		"sleep_line": "I'm leaving the lamp on.",
		"vm": "vm2",
	},
	{
		"title": "DAY 6", "sub": "Saturday, 6:48 p.m.",
		"intro": ["It's cold. I'm in the storage room.", "I'm standing among Dad's things."],
		"wake": "storage", "lit": ["storage", "living", "hall"], "anomalies": ["boxes_out"],
		"tasks": [
			{"id": "dad_boxes", "text": "Look through Dad's things", "steps": ["dad_boxes"], "doc": "dad_boxes", "think": "These are the things I couldn't throw away.", "obj": ["Look at what is on the floor"],
				"say": ["Mom's handwriting. I haven't read it since the funeral."]},
			{"id": "check_window", "text": "Check the windows", "steps": ["window_living"], "think": "The windows. What if it comes in that way?", "say": ["Four floors up. Nobody climbs that."]},
			{"id": "lock_up", "text": "Lock up for the night", "steps": ["front_door"], "think": "Chain on. Hall light on. Door shut.", "obj": ["Check the front door"],
				"say": ["Chain on. The chain is always on."]},
		],
		"flies": 0.7, "fear": 0.44,
		"events": {"pool": [], "every": [999.0, 999.0], "first": 999.0},
		"scripted": [{"after": "dad_boxes", "delay": 40.0, "do": "door_creak"}],
		"night": {"cue": "clock", "at": "living", "target": "clock", "think": "The ticking stopped. The clock in the living room.", "obj": "Look at the clock in the living room",
			"found": ["3:07.", "It said 3:07 yesterday too."], "evidence": "The wall clock has stopped at 3:07.", "figure": Vector3(2.4, 0, -3.4), "dark": true},
		"sleep_line": "Don't look at the foot of the bed.",
	},
	{
		"title": "DAY 7", "sub": "Sunday, 7:22 p.m.",
		"intro": ["My feet are wet.", "I'm standing in the bathroom, and the tub is running over."],
		"wake": "bath", "lit": ["bath", "living", "hall"], "anomalies": ["tub_water"],
		"tasks": [
			{"id": "pills", "text": "Look in the medicine cabinet", "steps": ["pills"], "doc": "pills", "think": "The tablets. Where are the tablets?", "obj": ["Open the cabinet"],
				"say": ["I don't need them.", "I'm not the one who's ill."]},
			{"id": "phone", "text": "Answer the phone", "steps": ["phone"], "vm": "vm3", "say": ["He talked to Whitmore.", "Everyone's talking about me."]},
			{"id": "job_search", "text": "Check the inbox", "steps": ["laptop"], "doc": "inbox_7", "say": ["Dr. Hale's office. Three missed appointments."]},
			{"id": "lock_up", "text": "Lock up for the night", "steps": ["front_door"], "think": "Chain on. Hall light on. Door shut.", "obj": ["Check the front door"],
				"say": ["Chain on."]},
		],
		"flies": 0.8, "fear": 0.52,
		"events": {"pool": [], "every": [999.0, 999.0], "first": 999.0},
		"scripted": [{"when": "phone", "delay": 8.0, "do": "phone_ring"}, {"after": "pills", "delay": 30.0, "do": "lights_out"}],
		"night": {"cue": "steps", "at": "bed2", "target": "jack_desk", "think": "Footsteps in Jack's room. Nobody's slept there in two years.", "obj": "Check Jack's room",
			"found": ["Jack's bed. The sheets are warm.", "Somebody has been lying here."], "evidence": "Jack's bed was warm at 3 a.m. Nobody has slept in it for two years.", "figure": Vector3(-2.2, 0, -6.3), "dark": true},
		"sleep_line": "I took none of them. It's still here.",
		"vm": "vm3",
	},
	{
		"title": "DAY 8", "sub": "Monday, 6:30 p.m.",
		"intro": ["I'm standing in Jack's doorway.", "My coat is on his bed."],
		"wake": "bed2", "lit": ["bed2", "living", "hall"], "anomalies": ["coat_bed"],
		"tasks": [
			{"id": "read_notes", "text": "Read the file on the laptop", "steps": ["laptop"], "doc": "notes_8", "think": "The laptop is open. There's a file I don't remember making.", "obj": ["Sit at the laptop"],
				"say": ["That's my handwriting.", "I mean my typing."]},
			{"id": "eat", "text": "Find something to eat", "steps": ["fridge"], "say": ["Everything is rotten.", "I'm not even hungry."]},
			{"id": "lock_up", "text": "Lock up for the night", "steps": ["front_door"], "think": "Chain on. Hall light on. Door shut.", "obj": ["Check the front door"],
				"say": ["Chain on."]},
		],
		"flies": 0.9, "fear": 0.6,
		"events": {"pool": [], "every": [999.0, 999.0], "first": 999.0},
		"scripted": [{"after": "start", "delay": 80.0, "do": "tv_static"}],
		"night": {"cue": "tv", "at": "tv", "target": "tv", "think": "A voice. From the TV. It's saying my name.", "obj": "Go to the TV",
			"found": ["Static.", "It was saying my name. I'm sure it was saying my name."], "evidence": "At 3 a.m. the TV was on and someone was saying my name.", "figure": Vector3(4.3, 0, -8.2), "dark": true},
		"sleep_line": "It's wearing something familiar.",
	},
	{
		"title": "DAY 9", "sub": "Tuesday, 7:10 p.m.",
		"intro": ["I'm sitting at the dining table.", "It's set for two."],
		"wake": "table", "lit": ["living", "hall"], "anomalies": ["table_set"],
		"tasks": [
			{"id": "note", "text": "Read the note on the table", "steps": ["note"], "doc": "note_9", "think": "There's a note by the plate.", "obj": ["Pick up the note"],
				"say": ["I don't remember writing that."]},
			{"id": "phone", "text": "Pick up the phone", "steps": ["phone"], "vm": "vm4", "say": ["Jack.", "I want to tell him. I don't know what."]},
			{"id": "gallery", "text": "Look through the photos", "steps": ["laptop"], "doc": "photos", "say": ["Empty rooms. Every one.", "And one of me, standing in the hall."]},
			{"id": "lock_up", "text": "Lock up for the night", "steps": ["front_door"], "think": "Chain on. Hall light on. Door shut.", "obj": ["Check the front door"],
				"say": ["Chain on."]},
		],
		"flies": 1.0, "fear": 0.7,
		"events": {"pool": [], "every": [999.0, 999.0], "first": 999.0},
		"scripted": [{"when": "phone", "delay": 8.0, "do": "phone_ring"}, {"after": "gallery", "delay": 25.0, "do": "lights_out"}],
		"night": {"cue": "chain", "at": "front", "target": "front_door", "think": "The chain. Someone is working the chain.", "obj": "Go to the front door",
			"found": ["The chain is off. The door is unlocked.", "Nobody could reach it from outside."], "evidence": "The chain was off again. Only someone inside can take it off.", "figure": Vector3(0.1, 0, -3.3), "dark": true},
		"sleep_line": "Tomorrow it ends. One way or the other.",
		"vm": "vm4",
	},
	{
		"title": "DAY 10", "sub": "Wednesday, 7:00 p.m.",
		"intro": ["Every light is on. Every door is open.", "The flat is perfectly quiet."],
		"wake": "bed1", "lit": ["bed1", "bed2", "bath", "storage", "entry", "kitchen", "living", "hall"], "anomalies": ["all_lit"], "all_open": true,
		"tasks": [
			{"id": "call_jack", "text": "Call Jack", "steps": ["phone"], "think": "I should call Jack. I have to say something to him.", "obj": ["Call Jack from the hall phone"], "say": ["His voicemail.", "I can't say anything.", "I hang up."]},
			{"id": "look_photo", "text": "Look at the photo of Mom and Dad", "steps": ["photo_parents"], "doc": "photo_parents", "obj": ["Look at the photo on the TV stand"], "say": ["I miss them.", "I never told anyone how much."]},
		],
		"flies": 1.0, "fear": 0.8,
		"events": {"pool": [], "every": [999.0, 999.0], "first": 999.0},
		"scripted": [{"after": "start", "delay": 60.0, "do": "tv_static"}],
		"night": {},
		"sleep_line": "",
		"final": true,
	},
]


## What Martin says to himself when a task begins: the thought comes first, then the objective appears.
const THINK := {
	"read_letter": "That letter by the door. I keep walking past it.",
	"eat": "I have to eat something.",
	"job_search": "Maybe somebody answered. I should look at the inbox.",
	"trash": "The bin is overflowing. I can't keep ignoring it.",
	"phone": "The phone. Is the machine light blinking?",
	"check_window": "The windows. What if it comes in that way?",
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
	"note": "Pick up the note on the table",
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
	"note": "There's a note on the dining table.",
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


## Martin rarely explains a scare: explaining it takes the fear out of it. Only a few things earn a word.
const REACT := {
	"knock": [[3, ["Hello?"]]],
	"first_seen": [[4, ["Someone's there."]], [8, ["Don't move."]]],
}


static func react(event_name: String, day: int) -> String:
	var best: Array = []
	for entry in REACT.get(event_name, []):
		if day >= entry[0]:
			best = entry[1]
	return "" if best.is_empty() else str(best[randi() % best.size()])
