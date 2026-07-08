# Verba

Russian vocabulary learning app for Windows, built with Flutter.

## Run

```
flutter run -d windows
```

## Lector audio

The "Google" lector plays pre-generated speech from `assets/lector/google/`
(normal speed) and `assets/lector/google_slow/` — one `<fnv1a(ru)>.mp3` per
unique Russian word across all courses, generated with gTTS. To regenerate
after editing a course, run `tool/generate_google_lector.py` (needs gTTS and
ffmpeg; resumable, only fetches missing files). The "Systemowy" lector falls
back to the Windows TTS voice via flutter_tts.

## Importing a custom course (JSON)

On the Courses screen, "Importuj kurs z pliku JSON" accepts either a course object
or a bare array of words:

```json
{
  "name": "My animals",
  "description": "optional",
  "words": [
    {"ru": "кот", "pl": ["kot"]},
    {"ru": "собака", "pl": "pies, piesek"}
  ]
}
```

`ru` and `pl` are required (`pl` may be a string with comma-separated variants or an
array); `ruAccented`, `category`, `pronunciation` are optional. If the top level is an
array of words, the file name becomes the course name.

## Versioning

Semantic versioning (0.x during development), set in `pubspec.yaml`.
The build number equals the commit count of the release commit (`git rev-list --count HEAD`).
Each release commit is tagged `vX.Y.Z`.
