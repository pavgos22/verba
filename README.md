# Verba

Russian vocabulary learning app for Windows, built with Flutter.

## Run

```
flutter run -d windows
```

## Lector audio

The "Dmitrij" lector plays pre-generated neural speech from `assets/lector/` —
one `<fnv1a(ru)>.mp3` per unique Russian word across all courses. To regenerate
after editing a course, download Piper + a Russian voice model and run
`tool/generate_lector.py <scratch-dir>` (needs Piper and ffmpeg on PATH). The
"Systemowy" lector falls back to the Windows TTS voice via flutter_tts.

## Versioning

Semantic versioning (0.x during development), set in `pubspec.yaml`.
The build number equals the commit count of the release commit (`git rev-list --count HEAD`).
Each release commit is tagged `vX.Y.Z`.
