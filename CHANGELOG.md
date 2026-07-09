# Changelog

## 0.10.0 — Practice and Test can now target a subset of words: the newest ones you've started, or your hardest (ranked by misses, with "almost" counting half; mastered words drop off the list). Choose the scope in the session gear. Progress now also tracks when each word was first learned and how often it was almost-right

## 0.9.12 — "Dzisiejsza sesja" can now feed new words in course order or shuffled; set it from the session gear or in Settings → Nauka (default stays shuffled)

## 0.9.11 — Courses screen: an (i) tooltip explaining the JSON import format, plus a "Pobierz przykładowy plik JSON" button that saves a ready-made sample course to disk

## 0.9.10 — Words screen: filter the list by status (New / Learning / Mastered) with live counts, so your active words are one click away

## 0.9.9 — session progress bar and counter now track words, not steps; a new word's presentation + typing no longer double the total, so a 10-word session reads as 10, not 20

## 0.9.8 — synonymous Russian words are now interchangeable in answers (да/так, нет/не); Test summary offers a relaxed "fix mistakes" pass (practice-style, no forced looping) plus a "back to home" button

## 0.9.7 — dropdown menus restyled to match the design (compact rounded card, per-item accent highlight on hover, checkmark on the selected option)

## 0.9.6 — lector dropdown now shows a voice icon and "Lektor:" label; JSON import also available inside the new-course dialog and for existing custom courses (asks whether to replace all words or append); clearer import error messages

## 0.9.5 — import a custom course from a JSON file (course object or bare word array; lenient pl as string or list)

## 0.9.4 — custom animated on/off toggles in Settings (sliding knob with trailing shadow and press-to-widen effect)

## 0.9.3 — restyled the words-per-session slider (thin track, outline thumb, tick marks only on the unfilled part), themed for light and dark

## 0.9.2 — pointer cursor on dropdown menu options

## 0.9.1 — refreshed Words screen with three count tiles (in course / learning / mastered) and progress bars

## 0.9.0 — custom courses: create your own course, add Russian↔Polish words (with the transliteration keyboard), edit and delete; refreshed Courses screen with per-course progress; custom words read by the system voice

## 0.8.11 — "how learning works" info icon (i) on the dashboard header with a hover tooltip

## 0.8.10 — fixed Polish spelling errors in translations (choroba, niebieski, żądać, łączność and glued phrases) found by a dictionary scan of the whole course

## 0.8.9 — removed the translation-direction option from "Today's session" settings (kept for Practice and Test)

## 0.8.8 — Ctrl+Space hotkey to replay pronunciation during a session (works while typing; silent in Polish→Russian so it doesn't reveal the answer)

## 0.8.7 — session settings per mode: words-per-session slider (5–50, step 5, default 20) and category filter, in all modes (Learning, Practice, Test); gear added to the "Today's session" card; loads as many words as available when short

## 0.8.6 — lector renamed to "Nadia"

## 0.8.5 — "Google" lector renamed to the neutral "Wiera"

## 0.8.4 — fixed first-frame flash when switching theme

## 0.8.3 — word categories in the 1000-word course (nouns, verbs, adjectives, adverbs, numerals, questions, phrases, other); fixed 30 glued or wrong translations; replaced 13 remaining prepositions and particles with content words

## 0.8.2 — так also accepts the answer "więc"

## 0.8.1 — removed Piper voices (Dmitrij, Irina, Rusłan); Google and system voices remain; app ~21 MB lighter

## 0.8.0 — Google lector (the Google Translate voice) with two real reading speeds; the "Speech tempo" setting switches to slow recordings

## 0.7.9 — lector picker also on the word presentation screen; pointer cursor on the lector dropdown

## 0.7.8 — fixed the inaudible "almost correct" sound (file normalization + simplified playback)

## 0.7.7 — real-time lector picker in the exercise footer; removed the "Tab — pronunciation" hint from the footer

## 0.7.6 — proper ё spelling across the course (ещё, чёрный, счёт…); typing with "е" still accepted

## 0.7.5 — lectors read with correct stress (input text stress-marked using the openrussian dictionary); fixed clipped recording endings; stress marks visible in the 1000-word course

## 0.7.4 — three selectable Piper lector voices (Dmitrij, Irina, Rusłan)

## 0.7.3 — neural Piper lector with pre-generated audio for all words (offline)

## 0.7.2 — lead-in silence in answer sounds (no more clipped first note)

## 0.7.1 — replaced pronouns, conjunctions and prepositions in the 1000-word course with content words

## 0.7.0 — Courses tab: multiple courses with active-course switching ("Pierwsze kroki" + "1000 rosyjskich słówek na start"); pronunciation shown while holding Tab; dynamic categories in the Words screen

## 0.6.3 — new answer sounds (user-provided)

## 0.6.2 — preloaded sounds and lead-in silence (clipping fix)

## 0.6.1 — "almost correct" counts toward the fix-up list; Enter on the summary starts the retry of mistakes

## 0.6.0 — smooth theme-switch animation (screenshot crossfade, refresh-rate independent); clearer auto-read setting name

## 0.5.1 — mistake retry keeps the translation direction; fixed slot for the result message (no layout jumps)

## 0.5.0 — answer sounds: correct / almost / wrong (with a settings toggle)

## 0.4.2 — Save/Cancel buttons in session settings

## 0.4.1 — random translation direction as the default

## 0.4.0 — mode badge in the session bar; gear with translation-direction settings for Practice and Test (alternating / RU→PL / PL→RU / random)

## 0.3.0 — learning modes: Practice and Test; looping retry of mistakes (until all correct); SRS levels advance only on on-time reviews

## 0.2.5 — instant theme switching (lag fix)

## 0.2.4 — equal card heights on the start screen

## 0.2.3 — pointer cursor on clickable elements; the answer stays in the field for manual correction

## 0.2.2 — stress mark drawn with a font glyph, centered above the letter; accent toggle in settings

## 0.2.1 — fixed stretched filter chips

## 0.2.0 — first playable MVP: 50-word course, learning sessions with the transliteration keyboard (lexilogos), simple SRS, system TTS lector, light/dark theme, Start / Words / Keyboard / Stats / Settings screens
