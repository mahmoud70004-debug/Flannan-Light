class_name Docs
## Everything Martin reads: the letter, the inbox, labels, the photos on his phone. Plain text,
## shown in the document panel. Clues to the truth are in here and in the flat, never stated outright.

const LIST := {
	"letter": {"title": "Letter", "body": "HALVERSON & GRAY LOGISTICS\nHuman Resources\n\nRe: Termination of employment\n\nDear Mr. Reed,\n\nThis letter confirms that your employment as Senior Operations Analyst ends with immediate effect.\n\nThe decision follows repeated incidents of misconduct and the findings of the occupational health review, which cited ongoing psychological problems that, in the company's assessment, prevent you from carrying out the duties of your role.\n\nPlease return all company property within five working days. Your final pay is enclosed.\n\nWe wish you well.\n\nD. Whitmore\nDirector of People"},
	"inbox_1": {"title": "Inbox (3)", "body": "From: Corvin Freight\nRe: Your application\n\"Thank you for your interest. After careful review we have decided to move forward with other candidates.\"\n\nFrom: Northline Supply\nAutomatic reply: \"Your application is being processed.\"\n\nFrom: Jack\nSubject: call me\n(unread, 4 days)"},
	"inbox_2": {"title": "Inbox (2)", "body": "From: Northline Supply\n\"We will not be proceeding with your application at this time.\"\n\nFrom: Recruiter Bay Staffing\n\"We heard about your situation. Perhaps another field?\"\n\nFrom: Jack\nSubject: call me\n(unread, 5 days)"},
	"inbox_3": {"title": "Inbox (1)", "body": "From: D. Whitmore\nSubject: Following up\n\nMartin,\n\nI know this is hard. You were one of the best analysts we had until last spring. Then the incidents began: the meeting where you stopped mid-sentence, the calls you swore you never made. We were worried about you.\n\nPlease see someone. Dr. Hale's office has your file.\n\nD.W."},
	"inbox_4": {"title": "Inbox (2)", "body": "From: Corvin Freight\nAutomatic reply.\n\nFrom: Dr. Hale's office\nSubject: Appointment reminder\n\"Mr. Reed, you have missed your appointment on the 2nd. Please call to reschedule.\""},
	"inbox_7": {"title": "Inbox (4)", "body": "From: Dr. Hale's office\n\"Mr. Reed, this is the third appointment you have missed. We are concerned. Please call us.\"\n\nFrom: Pharmacy\n\"Your prescription is ready for collection. (Ready since the 12th.)\"\n\nFrom: Jack\nSubject: please\n(unread, 12 days)"},
	"pills": {"title": "Pill bottle", "body": "REED, MARTIN\nTake one tablet twice daily.\nDr. A. Hale\n\nFilled 19 days ago.\nQty: 60\n\nThe seal on the cap is unbroken."},
	"photos": {"title": "Photos (14)", "body": "Hall, 11:42 p.m. — empty.\nHall, 11:43 p.m. — empty.\nLiving room, 3:07 a.m. — empty.\nBedroom doorway — empty.\nBathroom mirror — just me.\nKitchen — the plates. Two of them.\nThe sofa — empty.\nThe hall again — empty.\n\n...\n\nI saw it in every one of these.\nIt isn't in any of them."},
	"photo_parents": {"title": "Mom and Dad", "body": "Lake George, summer 2011.\n\nDad's squinting into the sun. Mom's laughing at something just out of the frame.\n\nThey died eight months apart. I stopped answering the phone after the second funeral. I haven't really stopped since."},
	"dad_boxes": {"title": "Dad's things", "body": "A wristwatch, stopped. A folded flag. A hospital bracelet with Dad's name.\n\nAt the bottom, a note in Mom's handwriting:\n\"Martin, look after Jack. Look after yourself. We are proud of you both.\""},
	"notes_5": {"title": "notes.txt", "body": "tuesday 3:07 am\nsomeone walks the hall at night. i counted. 41 steps. it stops at my door\n\nwednesday 3:07 am\n41 steps\n\nthursday\ni took photos. the hall is empty in the photos. it is there when i look\n\nfriday\nit knows when i look. it waits until i look away\n\nwho is it"},
	"notes_6": {"title": "notes.txt", "body": "saturday\nthe chain is on. the windows are shut. the door has not opened in 6 days.\nit does not need the door.\n\nit stands at the foot of the bed. i dont sleep. i close my eyes for a second and it is closer.\n\ndont look at it dont look at it dont look at it\nlook at it\n\nthere are two plates on the table. why"},
	"notes_8": {"title": "notes.txt", "body": "monday\nmy coat is gone\nmy coat is gone\nmy coat is gone\n\nit is wearing my coat\n\ni said hello. it did not say hello back. it tilted its head the way i do when jack talks too much\n\nwhy is the way it stands the way i stand\n\nhelp"},
	"jack_desk": {"title": "Jack's desk", "body": "Carved into the wood with a compass point:\n\nJ + M 1998\n\nWe built a fort in the garden that summer. We said we'd never leave each other."},
}


static func get_doc(id: String) -> Dictionary:
	return LIST.get(id, {"title": id, "body": ""})
