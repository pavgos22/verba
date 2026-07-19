import glob
import json
import os
import subprocess
import sys
import tempfile
import time

from gtts import gTTS

PROJECT = r"D:\Dev\FlutterProjects\Verba"

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
        pl = w["pl"][0]
        texts[fnv1a(pl)] = pl
print(f"unique polish words: {len(texts)}", flush=True)

out_dir = rf"{PROJECT}\assets\lector\google_pl"
os.makedirs(out_dir, exist_ok=True)
jobs = []
for key, pl in texts.items():
    out = rf"{out_dir}\{key}.mp3"
    if not os.path.exists(out):
        jobs.append((pl, out))
print(f"jobs to do: {len(jobs)}", flush=True)

done = 0
failed = []
for pl, out in jobs:
    ok = False
    for attempt in range(4):
        try:
            with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
                tmp_path = tmp.name
            gTTS(text=pl, lang="pl").save(tmp_path)
            r = subprocess.run([
                "ffmpeg", "-y", "-loglevel", "error", "-i", tmp_path,
                "-af", "adelay=60:all=1,apad=pad_dur=0.2",
                "-ac", "1", "-b:a", "64k", out,
            ], capture_output=True)
            os.unlink(tmp_path)
            if r.returncode == 0:
                ok = True
                break
            print(f"ffmpeg error for {pl}: {r.stderr.decode('utf-8', 'replace')[:150]}", flush=True)
        except Exception as e:
            wait = 5 * (attempt + 1)
            print(f"retry {attempt + 1} for {pl} ({e}), waiting {wait}s", flush=True)
            time.sleep(wait)
    if not ok:
        failed.append(pl)
    done += 1
    if done % 100 == 0:
        print(f"progress: {done}/{len(jobs)}", flush=True)
    time.sleep(0.25)

print(f"finished: {done - len(failed)}/{len(jobs)} ok, failed: {failed}", flush=True)
sys.exit(1 if failed else 0)
