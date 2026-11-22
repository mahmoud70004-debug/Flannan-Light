"""WAV (./out and ../tts/out_game) -> OGG Vorbis in game/assets/audio. Run after the generators."""
import glob, os, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.abspath(os.path.join(HERE, "../../game/assets/audio"))
os.makedirs(DEST, exist_ok=True)
for src_dir in (os.path.join(HERE, "out"), os.path.join(HERE, "../tts/out_game")):
    for f in sorted(glob.glob(os.path.join(src_dir, "*.wav"))):
        out = os.path.join(DEST, os.path.basename(f)[:-4] + ".ogg")
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", f, "-ac", "1", "-c:a", "libvorbis", "-q:a", "3", out], check=True)
print(len(glob.glob(os.path.join(DEST, "*.ogg"))), "ogg files in", DEST)
