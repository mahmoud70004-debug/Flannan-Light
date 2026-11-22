class_name Docs
## Everything Martin reads: the letter, the inbox, labels, the photos on his phone. Plain text,
## shown in the document panel. Clues to the truth are in here and in the flat, never stated outright.

const LIST := {
	"letter": {"title": "Letter", "body": "HALVERSON & GRAY LOGISTICS\nHuman Resources\n\nRe: Termination of employment\n\nDear Mr. Reed,\n\nThis letter confirms that your employment as Senior Operations Analyst ends with immediate effect.\n\nThe decision follows repeated incidents of misconduct and the findings of the occupational health review, which cited ongoing psychological problems that, in the company's assessment, prevent you from carrying out the duties of your role.\n\nPlease return all company property within five working days. Your final pay is enclosed.\n\nWe wish you well.\n\nD. Whitmore\nDirector of People"},
	"inbox_1": {"title": "Inbox (3)", "body": "From: Corvin Freight\nRe: Your application\n\"Thank you for your interest. After careful review we have decided to move forward with other candidates.\"\n\nFrom: Northline Supply\nAutomatic reply: \"Your application is being processed.\"\n\nFrom: Jack\nSubject: call me\n(unread, 4 days)"},
	"inbox_2": {"title": "Inbox (2)", "body": "From: Northline Supply\n\"We will not be proceeding with your application at this time.\"\n\nFrom: Recruiter Bay Staffing\n\"We heard about your situation. Perhaps another field?\"\n\nFrom: Jack\nSubject: call me\n(unread, 5 days)"},
	"inbox_3": {"title": "Inbox (1)", "body": "From: D. Whitmore\nSubject: Following up\n\nMartin,\n\nI know this is hard. You were one of the best analysts we had until last spring. Then the incidents began: the meeting where you stopped mid-sentence, the calls you swore you never made, and the night security found you in the archive at 3 a.m. standing in front of the shelves with your eyes open. You did not answer when they spoke to you. You did not remember it the next day.\n\nPlease see someone. Dr. Hale's office has your file.\n\nD.W."},
	"hale_rules": {"title": "From Dr. Hale", "body": "AT HOME\n\n1. Chain on the front door before bed.\n2. Bedroom door shut.\n3. Leave the hall light on.\n4. Tablets with food, twice a day.\n5. Write down anything unusual. Anything at all.\n\nCall me if it gets worse.\n\n- A. Hale"},
	"note_9": {"title": "A note, in pencil", "body": "I waited up.\nNobody came.\nI laid the table anyway.\n\n- M"},
	"inbox_4": {"title": "Inbox (2)", "body": "From: Corvin Freight\nAutomatic reply.\n\nFrom: Dr. Hale's office\nSubject: Appointment reminder\n\"Mr. Reed, you have missed your appointment on the 2nd. Please call to reschedule.\""},
	"inbox_7": {"title": "Inbox (4)", "body": "From: Dr. Hale's office\n\"Mr. Reed, this is the third appointment you have missed. We are concerned. Please call us.\"\n\nFrom: Pharmacy\n\"Your prescription is ready for collection. (Ready since the 12th.)\"\n\nFrom: Jack\nSubject: please\n(unread, 12 days)"},
	"pills": {"title": "Pill bottle", "body": "REED, MARTIN\nTake one tablet twice daily.\nDr. A. Hale\n\nFilled 19 days ago.\nQty: 60\n\nThe seal on the cap is unbroken."},
	"photos": {"title": "Photos (14)", "body": "Hall, 11:42 p.m. — empty.\nPrints on the floor — grey, bare, small.\nLiving room, 3:07 a.m. — empty.\nBedroom doorway — empty.\n\nThe last one was taken at 3:07 this morning.\nI did not take it.\n\nThe hall, from the bedroom door. And at the bottom edge of the frame, a hand holding the phone, in my grey sleeve."},
	"photo_parents": {"title": "Mom and Dad", "body": "Lake George, summer 2011.\n\nDad's squinting into the sun. Mom's laughing at something just out of the frame.\n\nThey died eight months apart. I stopped answering the phone after the second funeral. I haven't really stopped since."},
	"dad_boxes": {"title": "Dad's things", "body": "A wristwatch, stopped. A folded flag. A hospital bracelet with Dad's name.\n\nAt the bottom, a note in Mom's handwriting:\n\"Martin, look after Jack. Look after yourself. We are proud of you both.\""},
	"notes_8": {"title": "notes.txt", "body": "saturday 3:07\nstorage. dads box. i dont know why\n\nsunday 3:07\nbathroom. tap. i dont know why\n\nmonday\nthe coat is on jacks bed\n\nnobody else has a key\nnobody else is here\n\nthe file was last edited 3:07 am"},
	"jack_desk": {"title": "Jack's desk", "body": "Carved into the wood with a compass point:\n\nJ + M 1998\n\nWe built a fort in the garden that summer. We said we'd never leave each other."},
}


static func get_doc(id: String) -> Dictionary:
	return LIST.get(id, {"title": id, "body": ""})
