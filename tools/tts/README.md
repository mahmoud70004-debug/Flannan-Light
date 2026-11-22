# Voice generation (Jack's voicemails)

Candidate voices are generated offline with [kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx)
(Apache-2.0 model). Nothing here ships in the game build; chosen clips are copied into `game/assets/audio/` later.

```bash
python -m venv .venv && . .venv/bin/activate
pip install kokoro-onnx soundfile numpy scipy
# model files: https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0
#   kokoro-v1.0.onnx -> kokoro.onnx, voices-v1.0.bin -> voices.bin (run from this folder)
python gen_voicemail.py            # writes out/<voice>_clean.wav and out/<voice>_phone.wav
ffmpeg -i out/x.wav -ac 1 -b:a 56k out/x.mp3
```

`_phone` is the same read band-passed to 320–3300 Hz with mild saturation and hiss. Edit `SEG` for new lines
(day 7: the doctor and the pills). Candidates for the first round are in `docs/audio-candidates/jack/`.
