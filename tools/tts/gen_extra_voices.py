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
