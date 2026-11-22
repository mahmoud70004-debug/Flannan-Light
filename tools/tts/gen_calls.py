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


def whisperize(a):
    """Speech envelope on noise (a channel vocoder): breath with words in it."""
    from scipy.signal import stft, istft
    f, tt, Z = stft(a, fs=SR, nperseg=512)
    _, _, N = stft(rng.normal(0, 1, len(a)), fs=SR, nperseg=512)
    _, w = istft(np.abs(Z) * np.exp(1j * np.angle(N)), fs=SR, nperseg=512)
    w = sosfilt(sos_bp(500, 6500), w[: len(a)].astype(np.float32))
    return (w * 2.2).astype(np.float32)


def speak(text, who, speed):
    """One chunk of speech. J: Jack (am_onyx). M: Martin (am_adam), jittered the same way so he sounds like
    a person, quick and tense. W: Martin whispering."""
    voice = "am_onyx" if who == "J" else "am_adam"
    a, _ = k.create(text, voice=voice, speed=speed * rng.uniform(0.97, 1.04), lang="en-us")
    a = retune(a.astype(np.float32), rng.uniform(0.985, 1.015))
    if who == "W":
        return whisperize(a) * 0.42
    if who == "M":
        a = sosfilt(butter(1, 5200, btype="low", fs=SR, output="sos"), a)   # a little closed-in, nothing more
        return a * rng.uniform(0.82, 0.95) * 0.62                           # am_adam is louder than am_onyx
    return a * rng.uniform(0.82, 0.95)


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


J, M, W = "J", "M", "W"

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

# Calls: the phone rings, Martin picks up. He is quick and tense, and tells Jack what he sees and hears.
# Each call he admits more, and the last one ends with someone else on the line.
build("vm2", [      # day 5: he tries to hide it
    (M, "Hello?", .4, 1.08, ""),
    (J, "Martin? Oh, thank God. You picked up.", .4, 1.05, ""),
    (M, "Hey, Jack. Yeah. Sorry. I've been... busy.", .5, 1.08, "breath"),
    (J, "Busy? Martin, you sound awful. Are you sleeping?", .4, 1.05, ""),
    (M, "Not really. It's just the building. Something knocks, at night.", .5, 1.1, ""),
    (J, "Knocks?", .4, 1.02, ""),
    (M, "It's nothing. It's the pipes. Forget it.", .5, 1.12, ""),
    (J, "Okay. Okay. Call me tomorrow?", .5, 1.04, "breath"),
    (M, "Yeah. Tomorrow.", .7, 1.05, ""),
], call=True)
build("vm3", [      # day 7: he admits it
    (M, "Hello? Jack?", .3, 1.1, ""),
    (J, "Martin, it's me. I talked to your old boss today. He says you haven't been right since the funeral. Are you still seeing Doctor Hale?", .4, 1.06, "breath"),
    (M, "No. I stopped going. What would I even tell her?", .6, 1.08, ""),
    (J, "Tell her what?", .4, 1.02, ""),
    (M, "That I see things, Jack. Someone at the end of the hall. And when I look again, he's gone.", .6, 1.1, "breath"),
    (J, "Martin...", .5, 1.0, ""),
    (M, "And I hear worse. Laughing. Footsteps. Someone knocking, and nobody there.", .5, 1.12, ""),
    (J, "Are you taking the pills?", .5, 1.02, ""),
    (M, "I don't know. I think so. They don't help.", .8, 1.05, "sigh"),
    (J, "Call Doctor Hale tomorrow. Please. I love you, man.", .5, 1.04, ""),
    (M, "Okay.", .8, 1.0, ""),
], call=True)
build("vm4", [      # day 9: frantic, and then not alone on the line
    (J, "Martin? Martin, pick up. Please.", .3, 1.08, ""),
    (M, "Jack. Jack, I'm here. Don't hang up.", .3, 1.15, "breath"),
    (J, "I can't get off work till after the holidays. I'm sorry. I'll come as soon as I can.", .4, 1.08, ""),
    (M, "It's in the flat, Jack. Every night. It stands there, and when I look it's gone, and then I hear it laughing.", .4, 1.16, ""),
    (J, "Martin, listen to me. There's nobody there.", .5, 1.05, ""),
    (M, "The phone rings and nobody's there. The TV comes on by itself. Last night it whispered my name.", .4, 1.16, "breath"),
    (J, "Stay on the phone with me, okay? Just stay with me.", .5, 1.06, ""),
    (W, "There's someone else on the line.", 1.0, 0.95, ""),
    (W, "He's listening.", 1.4, 0.9, ""),
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
