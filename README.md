# Verba

Russian vocabulary learning app for Windows, built with Flutter.

## Run

```
flutter run -d windows
```

## Lector audio

The neural lectors (Dmitrij, Irina, Rusłan) play pre-generated speech from
`assets/lector/<voice>/` — one `<fnv1a(ru)>.mp3` per unique Russian word across
all courses. To regenerate after editing a course, download Piper + the Russian
voice models and run `tool/generate_lector.py <scratch-dir>` (needs Piper and
ffmpeg on PATH). The "Systemowy" lector falls back to the Windows TTS voice via
flutter_tts.

## Versioning

Semantic versioning (0.x during development), set in `pubspec.yaml`.
The build number equals the commit count of the release commit (`git rev-list --count HEAD`).
Each release commit is tagged `vX.Y.Z`.
