"""Synthesises every sound effect for the game (numpy/scipy only) and writes mono WAVs to ./out.
Run: python make_sfx.py   then   python encode.py   (WAV -> OGG into game/assets/audio)."""
import numpy as np, os
from scipy.signal import butter, sosfilt, fftconvolve
SR = 32000
rng = np.random.default_rng(11)
OUT = os.path.join(os.path.dirname(__file__), "out")
os.makedirs(OUT, exist_ok=True)

def t(sec): return np.arange(int(sec * SR)) / SR
def noise(sec): return rng.normal(0, 1, int(sec * SR))
def bp(x, lo, hi, order=3):
    return sosfilt(butter(order, [lo, hi], btype="band", fs=SR, output="sos"), x)
def lp(x, f, order=3): return sosfilt(butter(order, f, btype="low", fs=SR, output="sos"), x)
def hp(x, f, order=3): return sosfilt(butter(order, f, btype="high", fs=SR, output="sos"), x)
def norm(x, peak=0.8): return x / max(np.abs(x).max(), 1e-9) * peak
def env_exp(n, tau): return np.exp(-np.arange(n) / (tau * SR))
def pad(x, sec): return np.concatenate([x, np.zeros(int(sec * SR))])
def place(base, x, at):
    i = int(at * SR); n = min(len(x), len(base) - i)
    if n > 0: base[i:i + n] += x[:n]
    return base
def loopify(x, fade=0.4):
    """Crossfade the tail into the head so the clip loops without a click."""
    n = int(fade * SR); y = x[: len(x) - n].copy()
    w = np.linspace(0, 1, n)
    y[:n] = y[:n] * w + x[len(x) - n:] * (1 - w)
    return y
def reverb(x, sec=0.6, wet=0.25):
    n = int(sec * SR); ir = noise(sec) * env_exp(n, sec / 4); ir[0] = 0
    y = fftconvolve(x, ir)[: len(x)]
    return x + wet * y / max(np.abs(y).max(), 1e-9) * np.abs(x).max()

def save(name, x, peak=0.85):
    import soundfile as sf
    sf.write(os.path.join(OUT, name + ".wav"), norm(x, peak).astype(np.float32), SR)

# --- footsteps (wooden floor), 4 variants ---------------------------------------------
for i in range(4):
    n = int(0.45 * SR); x = np.zeros(n)
    f0 = 85 - i * 6
    th = np.sin(2 * np.pi * np.cumsum(np.linspace(f0, 38, n)) / SR) * env_exp(n, 0.07)
    nz = bp(noise(0.45), 180, 1500) * env_exp(n, 0.035) * 0.7
    cr = bp(noise(0.45), 700 + 150 * i, 1500 + 200 * i) * env_exp(n, 0.012) * 0.25   # board creak tick
    x = th + nz + cr
    save(f"step_{i}", reverb(x, 0.5, 0.18))

# --- knocks on a door ---------------------------------------------------------------------
def knock():
    n = int(0.3 * SR)
    return (lp(noise(0.3), 900) * env_exp(n, 0.03) + np.sin(2 * np.pi * 150 * t(0.3)) * env_exp(n, 0.05) * 0.8)
k3 = np.zeros(int(1.6 * SR))
for at in (0.05, 0.38, 0.72): place(k3, knock() * (0.9 + 0.2 * rng.random()), at)
# knock3 / knock1 / flies_loop now come from real recordings (make_user_sounds.py); the synthetic ones are not saved
_ = reverb(k3, 0.5, 0.2)

bang = np.zeros(int(1.4 * SR)); place(bang, lp(noise(0.6), 700) * env_exp(int(0.6 * SR), 0.12) + np.sin(2 * np.pi * 70 * t(0.6)) * env_exp(int(0.6 * SR), 0.18), 0.0)
save("door_slam", reverb(bang, 0.9, 0.35))

# --- cough (2 variants) ----------------------------------------------------------------------
def cough(variant):
    n = int(0.9 * SR); x = np.zeros(n)
    for k, at in enumerate((0.03, 0.27) if variant == 0 else (0.03, 0.22, 0.42)):
        m = int(0.16 * SR)
        src = noise(0.16) * 0.7 + np.sin(2 * np.pi * (95 + 6 * k) * t(0.16)) * 0.5   # breath + voiced pulse
        body = bp(src, 350, 1800) + 0.7 * bp(src, 900, 2600)
        e = np.exp(-((np.arange(m) / SR - 0.05) ** 2) / (2 * 0.04 ** 2))
        place(x, body * e * (1.0 - 0.15 * k), at)
    return reverb(lp(x, 4500), 0.5, 0.15)
save("cough_0", cough(0)); save("cough_1", cough(1))

# --- door creak ---------------------------------------------------------------------------------
n = int(1.6 * SR); fr = np.linspace(160, 230, n) * (1 + 0.04 * np.sin(2 * np.pi * 7 * t(1.6)))
saw = ((np.cumsum(fr) / SR) % 1.0) * 2 - 1
creak = bp(saw, 300, 1800) * (0.4 + 0.6 * np.abs(lp(noise(1.6), 20, 1))) * np.hanning(n)
save("door_creak", reverb(creak, 0.5, 0.2))

# --- flies (loop) -----------------------------------------------------------------------------------
n = int(4.0 * SR); tt = t(4.0)
wob = np.cumsum(180 + 40 * np.sin(2 * np.pi * 3.1 * tt) + 25 * lp(noise(4.0), 8, 1)) / SR
wing = np.sin(2 * np.pi * wob) + 0.5 * np.sin(4 * np.pi * wob)
gate = np.clip(lp(np.abs(noise(4.0)), 6, 1) * 4 - 0.4, 0, 1) ** 0.7                    # flies come and go
fl = (wing * 0.6 + bp(noise(4.0), 1500, 3800) * 0.35) * (0.35 + 0.65 * gate)
fl *= 1 + 0.5 * np.sin(2 * np.pi * 38 * tt)
_ = loopify(fl)

# --- ambience ----------------------------------------------------------------------------------------
n = 10.0
br = np.cumsum(noise(n)); br -= np.linspace(br[0], br[-1], len(br)); br = lp(norm(br), 300)
room = br * 0.8 + np.sin(2 * np.pi * 50 * t(n)) * 0.04 + bp(noise(n), 1500, 4000) * 0.01
save("room_tone", loopify(room, 0.8), 0.35)
fr_ = sum(np.sin(2 * np.pi * (100 * k) * t(6.0) + 0.3 * np.sin(2 * np.pi * 0.35 * t(6.0))) / k for k in (1, 2, 3, 5))
save("fridge_hum", loopify(fr_ * (1 + 0.04 * np.sin(2 * np.pi * 0.5 * t(6.0)))), 0.45)
street = lp(np.cumsum(noise(20.0)) * 0, 1) + lp(noise(20.0), 500) * 0.2
for at in (3.0, 11.5):                                              # a car passes
    m = int(4.0 * SR); sw = bp(noise(4.0), 200, 1200) * np.sin(np.pi * np.arange(m) / m) ** 2
    place(street, sw * 0.9, at)
save("street", loopify(street, 1.0), 0.3)
dr = np.zeros(int(6 * SR))
for at in (0.4, 2.1, 4.3):
    m = int(0.25 * SR); place(dr, np.sin(2 * np.pi * (1300 + 80 * rng.random()) * t(0.25)) * env_exp(m, 0.03), at)
save("drip", loopify(reverb(dr, 0.6, 0.3), 0.3), 0.5)
dn = t(12.0)
dro = (np.sin(2 * np.pi * 55.0 * dn) + np.sin(2 * np.pi * 55.9 * dn) + 0.5 * np.sin(2 * np.pi * 110.4 * dn)) * (0.6 + 0.4 * np.sin(2 * np.pi * dn / 12.0 * 1))
dro += lp(noise(12.0), 180) * 0.4
save("drone", loopify(dro, 1.0), 0.5)

# --- phone and machine ------------------------------------------------------------------------------
def bell(sec):
    tt_ = t(sec); am = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 22 * tt_))
    return (np.sin(2 * np.pi * 1450 * tt_) + 0.8 * np.sin(2 * np.pi * 1950 * tt_)) * am * np.hanning(len(tt_)) ** 0.3
ring = np.zeros(int(4.0 * SR)); place(ring, bell(0.55), 0.0); place(ring, bell(0.55), 0.7)
save("phone_ring", reverb(ring, 0.5, 0.2), 0.6)
save("machine_beep", np.sin(2 * np.pi * 1000 * t(0.4)) * np.minimum(1, np.arange(int(0.4 * SR)) / 200) * 0.8, 0.5)
click = np.zeros(int(0.12 * SR)); place(click, bp(noise(0.03), 1500, 6000) * env_exp(int(0.03 * SR), 0.004), 0.0); place(click, bp(noise(0.03), 800, 4000) * env_exp(int(0.03 * SR), 0.006), 0.05)
save("click", click, 0.7)
sh = np.zeros(int(0.5 * SR)); place(sh, bp(noise(0.05), 1200, 7000) * env_exp(int(0.05 * SR), 0.008), 0.0); place(sh, bp(noise(0.05), 1200, 7000) * env_exp(int(0.05 * SR), 0.01), 0.12)
save("shutter", sh, 0.7)
pick = np.zeros(int(0.5 * SR)); place(pick, lp(noise(0.12), 900) * env_exp(int(0.12 * SR), 0.03), 0.0); place(pick, np.sin(2 * np.pi * 110 * t(0.3)) * env_exp(int(0.3 * SR), 0.08) * 0.5, 0.02)
save("handset", pick, 0.6)

# --- body: heartbeat, breath, electric buzz ------------------------------------------------------------
hb = np.zeros(int(1.0 * SR))
for at, a in ((0.0, 1.0), (0.22, 0.7)):
    m = int(0.2 * SR); place(hb, np.sin(2 * np.pi * np.cumsum(np.linspace(62, 38, m)) / SR) * env_exp(m, 0.05) * a, at)
save("heartbeat", loopify(np.tile(hb, 2), 0.05), 0.8)
inh = bp(noise(1.3), 400, 3200) * np.sin(np.pi * np.arange(int(1.3 * SR)) / int(1.3 * SR)) ** 2
exh = bp(noise(1.7), 300, 2600) * np.sin(np.pi * np.arange(int(1.7 * SR)) / int(1.7 * SR)) ** 1.5 * 0.8
save("breath", np.concatenate([inh, np.zeros(int(0.25 * SR)), exh]), 0.5)
bz = np.zeros(int(0.9 * SR)); tb = t(0.9)
buzz = (np.sign(np.sin(2 * np.pi * 100 * tb)) * 0.5 + np.sin(2 * np.pi * 200 * tb) * 0.3 + bp(noise(0.9), 2000, 5000) * 0.1) * (np.random.default_rng(3).random(len(tb)) > 0.002)
buzz *= np.minimum(1, np.arange(len(tb)) / 300) * np.minimum(1, (len(tb) - np.arange(len(tb))) / 600)
buzz *= 0.5 + 0.5 * (np.sin(2 * np.pi * 17 * tb) > -0.3)
save("lamp_buzz", buzz, 0.5)
thump = np.zeros(int(1.2 * SR)); place(thump, np.sin(2 * np.pi * np.cumsum(np.linspace(70, 30, int(0.5 * SR))) / SR) * env_exp(int(0.5 * SR), 0.15), 0.0)
save("thump", reverb(thump, 0.8, 0.3), 0.9)
# TV static: hiss with a mains hum and slow bands of interference
ts = t(6.0)
tvs = noise(6.0) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.7 * ts)) + np.sin(2 * np.pi * 50 * ts) * 0.08
tvs = hp(tvs, 400)
save("tv_static", loopify(tvs), 0.45)
# --- small ambient bits (not events: they are background life that may or may not mean anything) ---
n = int(2.2 * SR); fr = np.linspace(70, 140, n) * (1 + 0.05 * np.sin(2 * np.pi * 9 * t(2.2)))
pipe = bp(((np.cumsum(fr) / SR) % 1.0 * 2 - 1) * 0.7 + noise(2.2) * 0.2, 120, 900) * np.hanning(n) ** 0.6
save("pipe_creak", reverb(pipe, 0.7, 0.25), 0.6)
wnd = bp(noise(8.0), 300, 1500) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.23 * t(8.0) + 1.0)) ** 2 + bp(noise(8.0), 900, 1100) * 0.2 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.31 * t(8.0)))
save("wind", loopify(wnd, 1.0), 0.4)
tk = np.zeros(int(1.0 * SR)); place(tk, bp(noise(0.02), 2000, 6000) * env_exp(int(0.02 * SR), 0.004), 0.0)
place(tk, bp(noise(0.02), 1500, 5000) * env_exp(int(0.02 * SR), 0.003) * 0.5, 0.5)
save("tick", np.tile(tk, 4), 0.35)
sy = noise(4.0); syl = np.abs(lp(noise(4.0), 6, 1)) * 6
mur = bp(sy, 200, 900) * np.clip(syl, 0, 1) ** 1.5 * (0.6 + 0.4 * np.sin(2 * np.pi * 3.7 * t(4.0)))
save("murmur", reverb(lp(mur, 700), 0.5, 0.3), 0.45)
bump = np.zeros(int(1.0 * SR)); place(bump, np.sin(2 * np.pi * np.cumsum(np.linspace(60, 38, int(0.4 * SR))) / SR) * env_exp(int(0.4 * SR), 0.1), 0.0)
save("neighbor_bump", lp(bump, 200), 0.8)

# --- v2: sounds for the nights (a tap, a chair, a chain, a dial tone) ---
tp = bp(noise(4.0), 900, 7000) * (0.7 + 0.3 * np.abs(lp(noise(4.0), 18, 2)) * 6) + bp(noise(4.0), 150, 400) * 0.25
save("tap_run", loopify(tp, 0.5), 0.5)
n = int(1.1 * SR); cs = np.zeros(n); tcs = np.arange(n) / SR
scr = bp(noise(1.1), 180, 1400) * (0.4 + 0.6 * np.abs(np.sin(2 * np.pi * 7 * tcs))) * np.sin(np.pi * np.arange(n) / n) ** 0.7
scr += np.sin(2 * np.pi * np.cumsum(np.linspace(190, 95, n)) / SR) * 0.15 * np.sin(np.pi * np.arange(n) / n)
save("chair_scrape", reverb(scr, 0.5, 0.2), 0.7)
ch = np.zeros(int(1.4 * SR))
for at, f in [(0.0, 3100), (0.17, 3900), (0.33, 3400), (0.62, 4300), (0.8, 3600), (1.05, 3000)]:
    k = int(0.18 * SR); tk_ = np.arange(k) / SR
    place(ch, (np.sin(2 * np.pi * f * tk_) * 0.5 + bp(noise(0.18), 2500, 9000) * 0.6) * env_exp(k, 0.03), at)
save("chain_rattle", reverb(ch, 0.4, 0.15), 0.6)
dt = (np.sin(2 * np.pi * 350 * t(3.0)) + np.sin(2 * np.pi * 440 * t(3.0))) * 0.5
save("dial_tone", loopify(dt, 0.1), 0.35)
print("sfx done:", sorted(os.listdir(OUT)))
