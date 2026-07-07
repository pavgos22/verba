import glob
import json
import os
import subprocess
import sys

SCRATCH = sys.argv[1]
PIPER = rf"{SCRATCH}\piperbin\piper\piper.exe"
PROJECT = r"D:\Dev\FlutterProjects\Verba"

VOICES = {
    "dmitri": rf"{SCRATCH}\piperbin\voice.onnx",
    "irina": rf"{SCRATCH}\piperbin\irina.onnx",
    "ruslan": rf"{SCRATCH}\piperbin\ruslan.onnx",
}

def fnv1a(text):
    h = 14695981039346656037
    for b in text.encode("utf-8"):
        h ^= b
        h = (h * 1099511628211) % (2**64)
    return format(h, "016x")

accents = json.load(open(rf"{SCRATCH}\accents.json", encoding="utf-8"))
texts = {}
for path in glob.glob(rf"{PROJECT}\assets\data\course_*.json"):
    course = json.load(open(path, encoding="utf-8"))
    for w in course["words"]:
        texts[fnv1a(w["ru"])] = accents.get(w["ru"], w["ru"])
print(f"unique words: {len(texts)}")

for voice, model in VOICES.items():
    out_dir = rf"{PROJECT}\assets\lector\{voice}"
    wav_dir = rf"{SCRATCH}\lector_wav_{voice}"
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(wav_dir, exist_ok=True)

    payload = "\n".join(
        json.dumps({"text": ru, "output_file": rf"{wav_dir}\{key}.wav"}) for key, ru in texts.items()
    ).encode("utf-8")
    print(f"[{voice}] piper...")
    p = subprocess.run([PIPER, "--model", model, "--json-input"], input=payload, capture_output=True)
    if p.returncode != 0:
        print(p.stderr.decode("utf-8", "replace")[-500:])
        raise SystemExit(1)

    print(f"[{voice}] mp3...")
    for key in texts:
        r = subprocess.run([
            "ffmpeg", "-y", "-loglevel", "error", "-i", rf"{wav_dir}\{key}.wav",
            "-af", "adelay=60:all=1,apad=pad_dur=0.25", "-ac", "1", "-b:a", "64k", rf"{out_dir}\{key}.mp3",
        ], capture_output=True)
        if r.returncode != 0:
            print(f"ffmpeg failed {voice}/{key}: {r.stderr.decode('utf-8', 'replace')[:200]}")
            raise SystemExit(1)
    total = sum(os.path.getsize(rf"{out_dir}\{k}.mp3") for k in texts)
    print(f"[{voice}] done: {len(texts)} files, {total // 1024 // 1024} MB")
