"""Game voices with kokoro-onnx: Jack's voicemails (am_onyx), the answering-machine greeting and prompts,
whispers (noise-vocoded speech) and a low chuckle. Writes WAVs to ./out_game.
Set KOKORO_DIR to the folder holding kokoro.onnx and voices.bin."""
import os, numpy as np, soundfile as sf
from scipy.signal import butter, sosfilt, resample_poly, stft, istft, fftconvolve
from kokoro_onnx import Kokoro

D = os.environ.get("KOKORO_DIR", ".")
k = Kokoro(os.path.join(D, "kokoro.onnx"), os.path.join(D, "voices.bin"))
SR = 24000
OUT = os.path.join(os.path.dirname(__file__), "out_game")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(5)

def say(text, voice, speed): 
    a, sr = k.create(text, voice=voice, speed=speed, lang="en-us"); assert sr == SR
    return a.astype(np.float32)
def bp(x, lo, hi, o=3): return sosfilt(butter(o, [lo, hi], btype="band", fs=SR, output="sos"), x)
def lp(x, f, o=3): return sosfilt(butter(o, f, btype="low", fs=SR, output="sos"), x)
def silence(s): return np.zeros(int(s * SR), dtype=np.float32)
def inhale(level=0.05, dur=0.55):
    n = int(dur * SR); e = np.sin(np.pi * np.arange(n) / n) ** 2
    return (bp(rng.normal(0, 1, n), 400, 3000) * e * level).astype(np.float32)
def sigh(level=0.05, dur=0.8):
    n = int(dur * SR); e = np.exp(-np.arange(n) / (0.35 * SR)) * np.minimum(1, np.arange(n) / 800)
    return (bp(rng.normal(0, 1, n), 300, 2400) * e * level).astype(np.float32)
def reverb(x, sec=0.5, wet=0.2):
    n = int(sec * SR); ir = rng.normal(0, 1, n) * np.exp(-np.arange(n) / (sec / 4 * SR)); ir[0] = 0
    y = fftconvolve(x, ir)[: len(x)]
    return x + wet * y / max(np.abs(y).max(), 1e-9) * max(np.abs(x).max(), 1e-9)
def phone(x, hiss=0.003):
    y = sosfilt(butter(4, [300, 3400], btype="band", fs=SR, output="sos"), x)
    y = np.tanh(y * 1.8) / 1.5
    y += rng.normal(0, hiss, len(y))
    return y.astype(np.float32)
def pitch(x, ratio):           # ratio < 1 lowers pitch (and lengthens)
    from fractions import Fraction
    f = Fraction(ratio).limit_denominator(100)
    return resample_poly(x, f.denominator, f.numerator).astype(np.float32)
def finish(name, x, peak=0.85):
    sf.write(os.path.join(OUT, name + ".wav"), (x / max(np.abs(x).max(), 1e-9) * peak).astype(np.float32), SR)
    print(name, round(len(x) / SR, 1), "s")

import json
STRETCH = 1 / 0.985                 # pitch() lengthens the clip by this factor

def voicemail(name, segs, voice="am_onyx"):
    parts = [silence(0.5)]
    cursor = 0.5
    lines = []
    for s in segs:
        text, speed, pause = s[0], s[1], s[2]
        tag = s[3] if len(s) > 3 else ""
        if tag == "breath":
            b = inhale(); parts.append(b); cursor += len(b) / SR
        a = say(text, voice, speed)
        lines.append({"t": round(cursor * STRETCH, 2), "d": round(len(a) / SR * STRETCH, 2), "text": text.replace("...", "…")})
        # worried, tired delivery: a touch of pitch drop on the closing words, softer overall
        parts.append(a * 0.9); cursor += len(a) / SR
        if tag == "sigh":
            sg = sigh(); parts.append(sg); cursor += len(sg) / SR
        parts.append(silence(pause)); cursor += pause
    x = np.concatenate(parts)
    x = pitch(x, 0.985)
    json.dump({"duration": round(len(x) / SR, 2), "lines": lines}, open(os.path.join(OUT, name + ".json"), "w"), ensure_ascii=False)
    finish(name, phone(reverb(x, 0.3, 0.08)), 0.8)

VM = {
 "vm1": [("Martin...", .92, .9), ("It's Jack.", .97, .7), ("I... I've called a few times now.", .95, .9, "breath"),
         ("I know you're probably... I don't know. Sleeping. Or whatever.", .98, .8), ("Sarah and I were talking about you last night.", .97, .6),
         ("We're worried, man.", .93, 1.0), ("You don't pick up. You don't call back.", .97, .7), ("It's not like you.", .9, .9, "sigh"),
         ("Not since Mom and Dad.", .9, 1.1), ("Just... call me. Okay? Even if it's late.", .95, .9), ("I'll stay up.", .92, .7),
         ("Talk to you soon, brother.", .93, .3)],
 "vm2": [("Hey. It's me again.", .95, .8), ("Sarah says I should give you space.", .97, .7, "breath"),
         ("But I can't just... do that. I can't.", .93, 1.0), ("Please. Pick up the phone.", .92, .4)],
 "vm3": [("Martin. It's Jack.", .95, .8), ("I talked to your old boss today.", .97, .6), ("I'm not mad, okay? I'm not.", .95, .8),
         ("But he said some things. About work. About how you've been... since the funeral.", .95, .9, "breath"),
         ("Are you still seeing Doctor Hale?", .97, .7), ("Are you taking the pills?", .95, 1.1),
         ("Martin. Just tell me you're taking the pills.", .9, .8, "sigh"), ("I love you, man. Call me.", .92, .3)],
 "vm4": [("Martin, pick up.", .98, .7), ("Please pick up.", .95, 1.2), ("I can't get off work until after the holidays. I'm sorry.", .98, .8),
         ("I tried. I did try.", .92, .9, "breath"), ("I'll come as soon as I can. I promise.", .95, 1.0),
         ("If you pick up... don't hang up. Just stay on the line with me. Okay?", .93, 1.0, "sigh"), ("Please.", .9, .3)],
 "vm5": [("Martin... it's been two weeks.", .93, 1.0), ("I called your landlord. He says he'll look in next week.", .97, .9, "breath"),
         ("Next week.", .92, .8), ("Look, if you're angry at me, fine. Be angry.", .96, .7), ("Just... say something.", .9, .4, "sigh")],
 "vm6": [("Okay.", .9, 1.2), ("I get it.", .9, .9), ("You don't want to talk. That's... okay.", .94, 1.0, "breath"),
         ("I'm not going to keep calling every day. I can't, Martin. I've got Emily, I've got... a life here.", .98, 1.0),
         ("But I'm still your brother.", .92, .9), ("I'm still here.", .9, 1.3), ("If you ever need me.", .9, .4, "sigh")],
 "vm7": [("...It's me.", .9, 2.0), ("Just checking.", .9, 2.5, "sigh"), ("...Okay.", .88, .5)],
}
for n, segs in VM.items():
    voicemail(n, segs)

# answering machine: Martin's old greeting, and the machine's own prompts
g = say("Hey, you've reached Martin. I can't get to the phone right now. Leave a message, and I'll call you back.", "am_adam", 1.04)
finish("greeting", phone(np.concatenate([silence(0.3), g, silence(0.4)]), 0.004), 0.8)
def robot(text):
    a = say(text, "af_nicole", 1.0)
    a = bp(a, 250, 3000); a = np.round(a * 12) / 12                     # crude bit-crush: a small machine voice
    return phone(a)
finish("machine_new", np.concatenate([silence(0.2), robot("You have new messages."), silence(0.3)]), 0.7)
finish("machine_end", np.concatenate([silence(0.2), robot("End of messages."), silence(0.3)]), 0.7)

# whispers: speech envelope applied to noise (a channel vocoder), so it is breath with words in it
def whisper(text, name, speed=0.85):
    a = say(text, "am_onyx", speed)
    f, tt, Z = stft(a, fs=SR, nperseg=512)
    nz = rng.normal(0, 1, len(a)); _, _, N = stft(nz, fs=SR, nperseg=512)
    Y = np.abs(Z) * np.exp(1j * np.angle(N))
    _, w = istft(Y, fs=SR, nperseg=512)
    w = bp(w[: len(a)].astype(np.float32), 500, 7000)
    finish(name, reverb(np.concatenate([silence(0.2), w, silence(0.6)]), 0.9, 0.35), 0.7)
for i, line in enumerate(["Martin.", "Martin... Martin.", "Look at me.", "Behind you.", "You know."]):
    whisper(line, f"whisper_{i}")

# a low chuckle (placeholder: tune by ear)
for i, line in enumerate(["Heh... heh heh.", "Ha. Ha ha ha."]):
    a = say(line, "am_onyx", 0.8)
    a = pitch(a, 0.88)
    finish(f"laugh_{i}", reverb(np.concatenate([silence(0.2), lp(a, 5000), silence(0.5)]), 1.0, 0.3), 0.7)
