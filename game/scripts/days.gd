class_name Days
## The story as data: ten days, each with its tasks, scripted and random events, how bad the
## flat smells, and what Martin says. Writing a day is writing content, not code.
##
## task: {id, text, steps: [use ids in order], say: [lines when done], doc: document id shown on the last step}
## scripted: [{at: seconds into the day, do: event name}]; night: events during the sleep sequence.
## events.pool: the random events allowed that day; events.every: [min, max] seconds between them.

const COUNT := 10
const PHOTO_STEP := "photo"           ## a task step satisfied by taking a photo with the phone

const DATA := [
	{
		"title": "DAY 1", "sub": "Monday, 9:14 a.m.",
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
		"events": {"pool": ["cough"], "every": [70.0, 110.0], "first": 60.0},
		"scripted": [{"at": 150.0, "do": "cough"}],
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
		"events": {"pool": ["cough", "footsteps"], "every": [60.0, 100.0], "first": 50.0},
		"scripted": [{"at": 90.0, "do": "footsteps"}, {"at": 300.0, "do": "cough"}],
		"night": ["footsteps_door"],
		"sleep_line": "The neighbours must be home.",
	},
	{
		"title": "DAY 3", "sub": "Wednesday",
		"intro": ["The flat smells. I should deal with it.", "I will. Tomorrow."],
		"tasks": [
			{"id": "eat", "text": "Eat something", "steps": ["fridge", "sofa"], "say": ["I'm not hungry. I eat anyway."]},
			{"id": "job_search", "text": "Read Mr. Whitmore's email", "steps": ["laptop"], "doc": "inbox_3", "say": ["He says it's \"for the best\"."]},
			{"id": "trash", "text": "Take the trash out", "steps": ["trash", "front_door"],
				"say": ["The chain is on.", "It's always on. Isn't it?", "I'll do it tomorrow."]},
		],
		"flies": 0.45, "fear": 0.22,
		"events": {"pool": ["cough", "footsteps", "knock", "door_creak"], "every": [55.0, 90.0], "first": 45.0},
		"scripted": [{"at": 100.0, "do": "knock"}, {"at": 260.0, "do": "knock_door"}],
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
		"events": {"pool": ["footsteps", "knock", "door_creak", "lights_flicker", "whisper"], "every": [50.0, 80.0], "first": 40.0},
		"scripted": [{"at": 80.0, "do": "phone_ring"}, {"at": 260.0, "do": "lights_flicker"}],
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
		"events": {"pool": ["footsteps", "knock", "door_creak", "lights_flicker", "whisper", "laugh", "stranger_far"], "every": [45.0, 75.0], "first": 35.0},
		"scripted": [{"at": 70.0, "do": "whisper"}, {"at": 200.0, "do": "lights_out"}, {"at": 330.0, "do": "phone_ring"}],
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
		"events": {"pool": ["footsteps", "knock", "door_creak", "lights_flicker", "whisper", "laugh", "stranger_far", "door_open"], "every": [40.0, 70.0], "first": 30.0},
		"scripted": [{"at": 60.0, "do": "laugh"}, {"at": 180.0, "do": "door_open"}, {"at": 300.0, "do": "stranger_far"}],
		"night": ["stranger_bed"],
		"sleep_line": "Don't look at the foot of the bed.",
	},
	{
		"title": "DAY 7", "sub": "Sunday",
		"intro": ["Jack called again. I let it ring.", "Eleven rings. I counted."],
		"tasks": [
			{"id": "phone", "text": "Play the new message", "steps": ["phone"], "vm": "vm3", "say": ["He talked to Whitmore.", "Everyone's talking about me."]},
			{"id": "pills", "text": "Look in the medicine cabinet", "steps": ["pills"], "doc": "pills", "say": ["I don't need them.", "I'm not sick. Somebody else is the problem."]},
			{"id": "job_search", "text": "Check the inbox", "steps": ["laptop"], "doc": "inbox_7", "say": ["Dr. Hale's office. Three missed appointments."]},
		],
		"flies": 0.85, "fear": 0.55,
		"events": {"pool": ["footsteps", "knock", "lights_flicker", "whisper", "laugh", "stranger_far", "door_open", "breath", "lights_out"], "every": [35.0, 60.0], "first": 30.0},
		"scripted": [{"at": 50.0, "do": "phone_ring"}, {"at": 240.0, "do": "lights_out"}, {"at": 340.0, "do": "stranger_far"}],
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
		"events": {"pool": ["footsteps", "knock", "lights_flicker", "whisper", "laugh", "stranger_far", "stranger_near", "door_open", "breath", "lights_out", "tv_static"], "every": [30.0, 55.0], "first": 25.0},
		"scripted": [{"at": 40.0, "do": "tv_static"}, {"at": 160.0, "do": "stranger_near"}, {"at": 300.0, "do": "lights_out"}],
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
		"events": {"pool": ["footsteps", "lights_flicker", "whisper", "laugh", "stranger_far", "stranger_near", "door_open", "breath", "lights_out", "tv_static", "knock"], "every": [25.0, 45.0], "first": 20.0},
		"scripted": [{"at": 40.0, "do": "phone_ring"}, {"at": 220.0, "do": "stranger_near"}, {"at": 320.0, "do": "lights_out"}],
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
		"events": {"pool": ["footsteps", "lights_flicker", "whisper", "laugh", "stranger_near", "breath", "tv_static"], "every": [25.0, 40.0], "first": 20.0},
		"scripted": [{"at": 30.0, "do": "tv_static"}],
		"night": [],
		"sleep_line": "",
		"final": true,
	},
]


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
}


static func examine(id: String, day: int) -> Array:
	var best: Array = []
	for entry in EXAMINE.get(id, []):
		if day >= entry[0]:
			best = entry[1]
	return best


## What he says when the bed is not ready for him yet.
const NOT_YET := ["I can't sleep yet. There's still something I have to do.", "Not yet.", "Something's left undone."]
