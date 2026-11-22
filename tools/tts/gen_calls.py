"""Jack's voicemails and the phone calls Martin picks up (replaces the VM table of gen_game_voices.py).

Why this exists: the first takes sounded like a text-to-speech read. Every sentence was synthesised on its own
at 0.9x speed with the same gap and the same level, and the whole clip was pitched down (which slows it too).
Here a worried voice comes from short broken phrases and breaths, not from slowness: speed stays at or above
1.0, every chunk gets its own small speed, pitch and level jitter, gaps are jittered, and nothing is stretched.

Martin (am_adam) answers some calls, flatly and late, a little stranger each time. Writes WAV and JSON to
./out_game (run encode.py afterwards). Set KOKORO_DIR to the folder holding kokoro.onnx and voices.bin.

JSON: {"duration": s, "call": bool, "lines": [{"t", "d", "who": "JACK"|"MARTIN", "text"}]}
"""
import os, json, numpy as np, soundfile as sf
from fractions import Fraction
from scipy.signal import butter, sosfilt, resample_poly, fftconvolve
from kokoro_onnx import Kokoro

D = os.environ.get("KOKORO_DIR", ".")
k = Kokoro(os.path.join(D, "kokoro.onnx"), os.path.join(D, "voices.bin"))
SR = 24000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out_game")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(21)


def sos_bp(lo, hi, o=3): return butter(o, [lo, hi], btype="band", fs=SR, output="sos")
def silence(s): return np.zeros(int(s * SR), dtype=np.float32)


def breath(level=0.05, dur=0.5):
    n = int(dur * SR); e = np.sin(np.pi * np.arange(n) / n) ** 2
    return (sosfilt(sos_bp(400, 3000), rng.normal(0, 1, n)) * e * level).astype(np.float32)


def sigh(level=0.05, dur=0.7):
    n = int(dur * SR); e = np.exp(-np.arange(n) / (0.3 * SR)) * np.minimum(1, np.arange(n) / 800)
    return (sosfilt(sos_bp(300, 2400), rng.normal(0, 1, n)) * e * level).astype(np.float32)


def retune(x, ratio):
    f = Fraction(ratio).limit_denominator(200)
    return resample_poly(x, f.denominator, f.numerator).astype(np.float32)


def speak(text, who, speed):
    """One chunk of speech. Jack: am_onyx, varied. Martin: am_adam, lowered, flattened and quiet."""
    if who == "J":
        a, _ = k.create(text, voice="am_onyx", speed=speed * rng.uniform(0.97, 1.04), lang="en-us")
        a = retune(a.astype(np.float32), rng.uniform(0.985, 1.015))       # a different pitch each time
        return a * rng.uniform(0.82, 0.95)
    a, _ = k.create(text, voice="am_adam", speed=speed, lang="en-us")
    a = retune(a.astype(np.float32), 0.955)                               # lower, slower, no life in it
    a = sosfilt(butter(2, 2600, btype="low", fs=SR, output="sos"), a)     # dull
    a = np.tanh(a * 2.4) / 2.4 * 1.6                                      # squashed dynamics: monotone-ish
    return (a * 0.42).astype(np.float32)


def reverb(x, sec=0.3, wet=0.07):
    n = int(sec * SR); ir = rng.normal(0, 1, n) * np.exp(-np.arange(n) / (sec / 4 * SR)); ir[0] = 0
    y = fftconvolve(x, ir)[: len(x)]
    return x + wet * y / max(np.abs(y).max(), 1e-9) * max(np.abs(x).max(), 1e-9)


def phone(x, hiss=0.003):
    y = sosfilt(butter(4, [300, 3400], btype="band", fs=SR, output="sos"), x)
    y = np.tanh(y * 1.8) / 1.5 + rng.normal(0, hiss, len(y))
    return y.astype(np.float32)


def build(name, segs, call=False, lead=0.5, tail=0.3, under=None):
    """segs: (who, text, gap_before, speed, tag) with tag in "", "breath", "sigh".
    under: (from_seg_index, level): a second, quiet breath on the line from that segment on."""
    parts = [silence(lead)]; cur = lead; lines = []; under_at = None
    for i, (who, text, gap, speed, tag) in enumerate(segs):
        g = gap * rng.uniform(0.85, 1.15)
        parts.append(silence(g)); cur += g
        if under and i == under[0]:
            under_at = cur
        if tag == "breath":
            b = breath(); parts.append(b); cur += len(b) / SR
        a = speak(text, who, speed)
        lines.append({"t": round(cur, 2), "d": round(len(a) / SR, 2), "who": "JACK" if who == "J" else "MARTIN",
                      "text": text})
        parts.append(a); cur += len(a) / SR
        if tag == "sigh":
            s = sigh(); parts.append(s); cur += len(s) / SR
    parts.append(silence(tail))
    x = np.concatenate(parts)
    if under_at is not None:                                              # someone else, breathing, on the line
        n = len(x) - int(under_at * SR)
        t = np.arange(n) / SR
        env = (0.5 - 0.5 * np.cos(2 * np.pi * t / 4.3)) ** 2 * np.minimum(1, t / 2.0)
        x[len(x) - n:] += (sosfilt(sos_bp(250, 2200), rng.normal(0, 1, n)) * env * under[1]).astype(np.float32)
    json.dump({"duration": round(len(x) / SR, 2), "call": call, "lines": lines},
              open(os.path.join(OUT, name + ".json"), "w"), ensure_ascii=False)
    y = phone(reverb(x))
    sf.write(os.path.join(OUT, name + ".wav"), (y / max(np.abs(y).max(), 1e-9) * 0.8).astype(np.float32), SR)
    print(name, round(len(x) / SR, 1), "s", "call" if call else "")


J, M = "J", "M"

# Voicemails: Jack alone, short, broken up by worry rather than slowed down.
build("vm0", [
    (J, "Hey, Martin. It's Jack. I heard about the job.", .3, 1.04, ""),
    (J, "Sarah's cousin told us. I'm sorry, man.", .45, 1.03, "breath"),
    (J, "Call me when you can. Anytime.", .6, 1.0, "sigh"),
])
build("vm1", [
    (J, "Martin, it's Jack. I've called a few times now.", .3, 1.05, ""),
    (J, "Sarah and I are worried. You don't pick up. You don't call back.", .5, 1.05, "breath"),
    (J, "It's not like you.", .5, 1.0, ""),
    (J, "Not since Mom and Dad.", .8, 0.98, "sigh"),
    (J, "Just call me, okay? Even if it's late. I'll stay up.", .5, 1.03, ""),
])

# Calls: the phone rings, Martin picks up. His answers are flat and come late; each call is a little worse.
build("vm2", [      # day 5: nearly normal, only tired and short
    (M, "Hello.", .4, 0.92, ""),
    (J, "Martin? Oh, thank God. You picked up.", .5, 1.05, ""),
    (M, "Yeah.", .9, 0.9, ""),
    (J, "How are you doing? Are you eating?", .4, 1.05, ""),
    (M, "I'm fine.", 1.3, 0.9, ""),
    (J, "You sound tired.", .5, 1.04, ""),
    (M, "I'm fine, Jack.", 1.1, 0.9, ""),
    (J, "Okay. Okay. I'm just glad to hear your voice. Call me tomorrow?", .6, 1.05, "breath"),
    (M, "Okay.", 1.4, 0.9, ""),
], call=True)
build("vm3", [      # day 7: slow, repeats Jack's words, a wrong note
    (M, "Hello.", .5, 0.9, ""),
    (J, "Martin, it's Jack. I talked to your old boss today.", .4, 1.06, ""),
    (M, "Okay.", 1.2, 0.9, ""),
    (J, "He said you haven't been right since the funeral. Are you still seeing Doctor Hale?", .4, 1.06, "breath"),
    (M, "Doctor Hale.", 1.4, 0.88, ""),
    (J, "Are you taking the pills?", .4, 1.02, ""),
    (M, "I'm taking them.", 1.3, 0.88, ""),
    (M, "I'm taking the pills.", 1.0, 0.88, ""),
    (J, "Martin, you sound strange.", .6, 1.02, ""),
    (M, "Do I?", 1.5, 0.88, ""),
    (J, "I love you, man. Call me.", .5, 1.02, "sigh"),
], call=True)
build("vm4", [      # day 9: Jack begs, Martin answers like a recording, and says there is someone on the line
    (J, "Martin? Martin, pick up. Please.", .3, 1.08, ""),
    (M, "I'm here.", 1.3, 0.88, ""),
    (J, "I can't get off work till after the holidays. I'm sorry. I'll come as soon as I can.", .4, 1.08, "breath"),
    (M, "It's all right.", 1.5, 0.86, ""),
    (M, "Nobody has come.", 1.6, 0.86, ""),
    (J, "What? What do you mean?", .5, 1.05, ""),
    (M, "There's someone else on the line.", 1.8, 0.86, ""),
    (J, "Martin, it's just me. Stay on the phone with me, okay?", .5, 1.08, ""),
    (M, "He's listening.", 2.0, 0.84, ""),
], call=True, under=(7, 0.05))

# Messages Jack leaves while Martin lies in the flat (the epilogue).
build("vm5", [
    (J, "Martin, it's been two weeks. I called your landlord. He says he'll look in next week.", .3, 1.05, "breath"),
    (J, "Next week.", .5, 0.98, ""),
    (J, "Just say something. Anything.", .6, 1.0, "sigh"),
])
build("vm6", [
    (J, "Okay. I get it. You don't want to talk.", .4, 1.0, ""),
    (J, "I'm not going to keep calling every day. I can't. I've got Emily, I've got a life here.", .7, 1.05, "breath"),
    (J, "But I'm still your brother. I'm still here.", .7, 0.98, ""),
    (J, "If you ever need me.", .9, 0.97, "sigh"),
])
build("vm7", [
    (J, "It's me.", .5, 0.98, ""),
    (J, "Just checking.", 2.0, 0.97, "sigh"),
    (J, "Okay.", 2.2, 0.96, ""),
])
