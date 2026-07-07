import glob
import wave

LEAD_MS = 60

for path in sorted(glob.glob(r"D:\Dev\FlutterProjects\Verba\assets\sounds\*.wav")):
    with wave.open(path, "rb") as w:
        params = w.getparams()
        frames = w.readframes(w.getnframes())
    lead_frames = int(params.framerate * LEAD_MS / 1000)
    silence = b"\x00" * (lead_frames * params.sampwidth * params.nchannels)
    with wave.open(path, "wb") as w:
        w.setparams(params)
        w.writeframes(silence + frames)
    print(f"{path.split(chr(92))[-1]}: +{LEAD_MS}ms lead-in")
