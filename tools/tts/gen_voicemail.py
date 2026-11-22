import numpy as np, soundfile as sf
from scipy.signal import butter, sosfilt
from kokoro_onnx import Kokoro
k = Kokoro('kokoro.onnx', 'voices.bin')
SR = 24000
# (text, pause after in seconds)
SEG = [
 ("Martin... it's Jack. Again.", 0.7),
 ("I've left you three messages this week.", 0.5),
 ("Look, I'm not trying to nag you.", 0.4),
 ("Sarah and I are just... worried, okay?", 0.6),
 ("You never pick up anymore. Not since Mom and Dad.", 0.9),
 ("Just call me back. Even if it's late. I'll stay up.", 0.8),
 ("Alright. Talk to you soon, brother.", 0.3),
]
VOICES = ["am_adam", "am_eric", "am_liam", "am_michael", "am_onyx", "am_fenrir"]
rng = np.random.default_rng(7)
def phone(x):
    sos = butter(4, [320, 3300], btype='band', fs=SR, output='sos')
    y = sosfilt(sos, x)
    y = np.tanh(y * 2.2) / 1.6
    y += rng.normal(0, 0.0025, len(y))
    return (y / max(np.abs(y).max(), 1e-6) * 0.85).astype(np.float32)
for v in VOICES:
    parts = []
    for text, pause in SEG:
        a, sr = k.create(text, voice=v, speed=0.9, lang="en-us")
        assert sr == SR
        parts.append(a.astype(np.float32)); parts.append(np.zeros(int(pause * SR), dtype=np.float32))
    x = np.concatenate([np.zeros(int(0.4 * SR), dtype=np.float32)] + parts)
    x = x / max(np.abs(x).max(), 1e-6) * 0.85
    sf.write(f'out/{v}_clean.wav', x, SR)
    sf.write(f'out/{v}_phone.wav', phone(x), SR)
    print(v, round(len(x) / SR, 1), 's')
