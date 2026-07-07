import glob
import json
import os
import subprocess
import sys

SCRATCH = sys.argv[1]
PIPER = rf"{SCRATCH}\piperbin\piper\piper.exe"
MODEL = rf"{SCRATCH}\piperbin\voice.onnx"
PROJECT = r"D:\Dev\FlutterProjects\Verba"
OUT_DIR = rf"{PROJECT}\assets\lector"
WAV_DIR = rf"{SCRATCH}\lector_wav"

def fnv1a(text):
    h = 14695981039346656037
    for b in text.encode("utf-8"):
        h ^= b
        h = (h * 1099511628211) % (2**64)
    return format(h, "016x")

texts = {}
for path in glob.glob(rf"{PROJECT}\assets\data\course_*.json"):
    course = json.load(open(path, encoding="utf-8"))
    for w in course["words"]:
        ru = w["ru"]
        texts[fnv1a(ru)] = ru
print(f"unique words: {len(texts)}")

os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(WAV_DIR, exist_ok=True)

lines = []
for key, ru in texts.items():
    lines.append(json.dumps({"text": ru, "output_file": rf"{WAV_DIR}\{key}.wav"}))
payload = "\n".join(lines).encode("utf-8")

print("generating with piper...")
p = subprocess.run([PIPER, "--model", MODEL, "--json-input"], input=payload, capture_output=True)
if p.returncode != 0:
    print(p.stderr.decode("utf-8", "replace")[-500:])
    raise SystemExit(1)

print("compressing to mp3 with lead-in silence...")
done = 0
for key in texts:
    wav = rf"{WAV_DIR}\{key}.wav"
    mp3 = rf"{OUT_DIR}\{key}.mp3"
    r = subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-i", wav,
        "-af", "adelay=60:all=1",
        "-ac", "1", "-b:a", "64k", mp3,
    ], capture_output=True)
    if r.returncode != 0:
        print(f"ffmpeg failed for {key}: {r.stderr.decode('utf-8', 'replace')[:200]}")
        raise SystemExit(1)
    done += 1
    if done % 100 == 0:
        print(f"  {done}/{len(texts)}")

total = sum(os.path.getsize(rf"{OUT_DIR}\{k}.mp3") for k in texts)
print(f"done: {done} mp3 files, {total // 1024 // 1024} MB total")
