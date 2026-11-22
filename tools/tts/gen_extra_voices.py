"""Extra voice lines (Jack's own greeting, for the day-10 call). Same helpers as gen_game_voices.py."""
import os, json, numpy as np, soundfile as sf
from scipy.signal import butter, sosfilt
from kokoro_onnx import Kokoro
D = os.environ.get("KOKORO_DIR", ".")
k = Kokoro(os.path.join(D, "kokoro.onnx"), os.path.join(D, "voices.bin"))
SR = 24000
OUT = os.path.join(os.path.dirname(__file__), "out_game")
rng = np.random.default_rng(9)
def phone(x):
    y = sosfilt(butter(4, [300, 3400], btype="band", fs=SR, output="sos"), x)
    return (np.tanh(y * 1.8) / 1.5 + rng.normal(0, 0.003, len(y))).astype(np.float32)
text = "Hey, you've reached Jack. I can't pick up right now. Leave a message, and I'll get back to you."
a, _ = k.create(text, voice="am_onyx", speed=1.02, lang="en-us")
x = np.concatenate([np.zeros(int(0.4 * SR), dtype=np.float32), a.astype(np.float32), np.zeros(int(0.5 * SR), dtype=np.float32)])
sf.write(os.path.join(OUT, "jack_greeting.wav"), phone(x) / max(np.abs(phone(x)).max(), 1e-9) * 0.8, SR)
json.dump({"duration": round(len(x) / SR, 2), "lines": [{"t": 0.4, "d": round(len(a) / SR, 2), "text": text}]}, open(os.path.join(OUT, "jack_greeting.json"), "w"))
print("ok", round(len(x) / SR, 1))


# --- vm0: Jack's first message, the day the game starts (he has heard about the job) ---
def inhale(level=0.05, dur=0.55):
    n = int(dur * SR); e = np.sin(np.pi * np.arange(n) / n) ** 2
    return (sosfilt(butter(3, [400, 3000], btype="band", fs=SR, output="sos"), rng.normal(0, 1, n)) * e * level).astype(np.float32)

def sigh(level=0.05, dur=0.8):
    n = int(dur * SR); e = np.exp(-np.arange(n) / (0.35 * SR)) * np.minimum(1, np.arange(n) / 800)
    return (sosfilt(butter(3, [300, 2400], btype="band", fs=SR, output="sos"), rng.normal(0, 1, n)) * e * level).astype(np.float32)

SEG = [("Hey, Martin. It's Jack.", .97, .7), ("I heard about the job.", .95, .8, "breath"), ("Sarah's cousin works at Halverson. She... told us.", .96, .8),
       ("I'm sorry, man. I really am.", .93, 1.0, "sigh"), ("Call me when you can. Anytime. I mean that.", .95, .4)]
parts = [np.zeros(int(0.5 * SR), dtype=np.float32)]
cursor = 0.5
lines = []
STRETCH = 1 / 0.985
for sg in SEG:
    text, speed, pause = sg[0], sg[1], sg[2]
    tag = sg[3] if len(sg) > 3 else ""
    if tag == "breath":
        b = inhale(); parts.append(b); cursor += len(b) / SR
    a, _ = k.create(text, voice="am_onyx", speed=speed, lang="en-us")
    a = a.astype(np.float32)
    lines.append({"t": round(cursor * STRETCH, 2), "d": round(len(a) / SR * STRETCH, 2), "text": text.replace("...", "…")})
    parts.append(a * 0.9); cursor += len(a) / SR
    if tag == "sigh":
        g = sigh(); parts.append(g); cursor += len(g) / SR
    parts.append(np.zeros(int(pause * SR), dtype=np.float32)); cursor += pause
x = np.concatenate(parts)
from scipy.signal import resample_poly
x = resample_poly(x, 200, 197).astype(np.float32)              # the same slight pitch drop as the other messages
y = phone(x)
sf.write(os.path.join(OUT, "vm0.wav"), y / max(np.abs(y).max(), 1e-9) * 0.8, SR)
json.dump({"duration": round(len(x) / SR, 2), "lines": lines}, open(os.path.join(OUT, "vm0.json"), "w"), ensure_ascii=False)
print("vm0", round(len(x) / SR, 1))
