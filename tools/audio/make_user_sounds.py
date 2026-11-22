"""Turns the three Freesound recordings supplied by the project owner into game sounds.

    flies_loop   <- fly-1 (Freesound 82077, benboncan): a steady 8 s section, mono, loop-crossfaded, quiet
    knock1/knock3 <- knocking-1 (Freesound 501705, awrecordingit): one knock and three knocks; knock3_front is the
                    same muffled, as heard through the front door
    switch       <- light-switch-on (Freesound 788643, philip_berger): trimmed

Usage: SRC=<folder with the three wavs> python make_user_sounds.py   (writes WAVs to ./out; run encode.py next)
The source WAVs are not in the repository (6.8 MB); only the processed OGGs are. See docs/CREDITS.md for licences.
"""
import os, glob, numpy as np, soundfile as sf
from scipy.signal import butter, sosfilt, resample_poly, fftconvolve

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.environ.get("SRC", ".")
OUT = os.path.join(HERE, "out")
os.makedirs(OUT, exist_ok=True)


def find(part):
    return glob.glob(os.path.join(SRC, "*" + part + "*.wav"))[0]


def mono(x): return x.mean(1) if x.ndim > 1 else x
def bp(x, sr, lo, hi, o=3): return sosfilt(butter(o, [lo, hi], btype="band", fs=sr, output="sos"), x)
def lp(x, sr, f, o=3): return sosfilt(butter(o, f, btype="low", fs=sr, output="sos"), x)
def hp(x, sr, f, o=3): return sosfilt(butter(o, f, btype="high", fs=sr, output="sos"), x)
def peak(x, p): return (x / max(np.abs(x).max(), 1e-9) * p).astype(np.float32)
def rms_to(x, db): return (x * 10 ** (db / 20) / max(np.sqrt((x ** 2).mean()), 1e-9)).astype(np.float32)


def fade(x, sr, ms=6):
    n = int(sr * ms / 1000)
    x = x.copy(); x[:n] *= np.linspace(0, 1, n); x[-n:] *= np.linspace(1, 0, n)
    return x


# --- flies: seconds 2 to 10 of the recording are the steadiest; crossfade the tail into the head
f, sr = sf.read(find("fly"))
f = hp(lp(mono(f), sr, 9000), sr, 180)
seg = f[int(2.0 * sr):int(10.0 * sr)]
xf = int(1.2 * sr)
head, tail = seg[:xf], seg[-xf:]
ramp = np.linspace(0, 1, xf)
loop = np.concatenate([seg[xf:-xf], tail * (1 - ramp) + head * ramp])      # the last second blends into the first
loop = resample_poly(loop, 1, 2)                                            # 22 kHz is plenty for a buzz
sf.write(os.path.join(OUT, "flies_loop.wav"), rms_to(loop, -30.0), sr // 2)
print("flies_loop", len(loop) / (sr // 2), "s")

# --- knocks
k, sr = sf.read(find("knocking"))
k = mono(k)
def cut(a, b): return fade(k[int(a * sr):int(b * sr)], sr)
knock3 = cut(0.20, 0.93)
knock1 = cut(0.95, 1.42)
sf.write(os.path.join(OUT, "knock3.wav"), peak(knock3, 0.85), sr)
sf.write(os.path.join(OUT, "knock1.wav"), peak(knock1, 0.85), sr)
n = int(0.5 * sr)
ir = np.random.default_rng(3).normal(0, 1, n) * np.exp(-np.arange(n) / (0.12 * sr)); ir[0] = 0
muffled = lp(knock3, sr, 1400)
muffled = muffled + 0.35 * fftconvolve(muffled, ir)[: len(muffled)] / max(np.abs(ir).sum() * 0.05, 1e-9)
sf.write(os.path.join(OUT, "knock3_front.wav"), peak(muffled, 0.8), sr)
print("knock3", len(knock3) / sr, "knock1", len(knock1) / sr)

# --- the light switch
s, sr = sf.read(find("switch"))
s = mono(s)
env = np.abs(s)
idx = np.where(env > env.max() * 0.04)[0]
s = fade(s[max(idx[0] - int(0.005 * sr), 0): idx[-1] + int(0.02 * sr)], sr, 3)
sf.write(os.path.join(OUT, "switch.wav"), peak(s, 0.85), sr)
print("switch", len(s) / sr)
