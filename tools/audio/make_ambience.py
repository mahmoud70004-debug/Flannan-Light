"""The island's weather, synthesised (numpy/scipy): sea against rock, wind, rain. Mono WAV loops in ./out.
Run: python make_ambience.py   then   python encode.py   (WAV -> OGG into game/assets/audio)."""
import os
import numpy as np
from scipy.signal import butter, sosfilt

SR = 32000
rng = np.random.default_rng(1900)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
os.makedirs(OUT, exist_ok=True)


def t(sec): return np.arange(int(sec * SR)) / SR
def noise(sec): return rng.normal(0, 1, int(sec * SR))
def bp(x, lo, hi, o=3): return sosfilt(butter(o, [lo, hi], btype="band", fs=SR, output="sos"), x)
def lp(x, f, o=3): return sosfilt(butter(o, f, btype="low", fs=SR, output="sos"), x)
def norm(x, peak): return x / max(np.abs(x).max(), 1e-9) * peak


def loopify(x, fade=1.0):
    n = int(fade * SR)
    y = x[: len(x) - n].copy()
    w = np.linspace(0, 1, n)
    y[:n] = y[:n] * w + x[len(x) - n:] * (1 - w)
    return y


def save(name, x, peak):
    import soundfile as sf
    sf.write(os.path.join(OUT, name + ".wav"), norm(x, peak).astype(np.float32), SR)
    print(name, round(len(x) / SR, 1), "s")


# Sea: a deep wash that swells and breaks every few seconds, with a hiss of foam running back.
L = 16.0
tt = t(L)
swell = np.zeros(len(tt))
for at in [0.4, 4.1, 7.3, 10.9, 13.6]:
    k = (tt - at)
    env = np.where(k > 0, np.exp(-k / 1.6) * np.minimum(1, k / 0.35), 0)
    swell += env * rng.uniform(0.7, 1.0)
swell += np.roll(swell, int(L * SR))        # wrap the tail of the last wave round to the start
deep = lp(noise(L), 220) * (0.35 + 0.65 * swell)
foam = bp(noise(L), 900, 5000) * (0.15 + 0.85 * np.roll(swell, int(0.6 * SR))) * 0.35
save("sea", loopify(deep + foam, 1.2), 0.6)

# Wind: band noise with slow gusts and a faint whistle.
L = 14.0
g = 0.45 + 0.55 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.11 * t(L) + 0.7)) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.27 * t(L)))
w = bp(noise(L), 200, 1300) * g + bp(noise(L), 1500, 1700) * 0.12 * g ** 2
save("wind", loopify(w, 1.2), 0.5)

# Rain: a dense hiss with scattered heavier drops.
L = 8.0
r = bp(noise(L), 1200, 8000) * 0.6 + lp(noise(L), 500) * 0.2
drops = np.zeros(int(L * SR))
for i in range(260):
    p = rng.integers(0, len(drops) - 400)
    k = np.arange(400)
    drops[p:p + 400] += np.sin(2 * np.pi * rng.uniform(1800, 3500) * k / SR) * np.exp(-k / 60.0) * rng.uniform(0.2, 0.6)
save("rain", loopify(r + drops, 0.8), 0.45)
