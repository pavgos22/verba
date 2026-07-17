# Changelog

## 0.12.1 — every clickable control now shows the hand/pointer cursor on hover; icon-only buttons (like the "X" that ends a session) were still showing the plain arrow — fixed app-wide via the theme so future icon buttons get it too

## 0.12.0 — holding Tab on a verb now also reveals its 2nd-person form when that form has the "trap 2" ё shift (e.g. жить → ты живёшь, петь → ты поёшь), shown next to the 1st person with the ё highlighted; verbs without the shift (ехать → едешь) are unaffected. Built-in courses were regenerated (47 verbs got it) and custom courses can set a "2. osoba" field or a "secondPerson" on JSON import. Also: the verb-details line now keeps a fixed reserved height for every word during a session, so the word no longer jumps up or down as you move between verbs and non-verbs

## 0.11.11 — the end-of-session summary is now always shown before the "fix mistakes" pass, in every session type: it used to be possible to shoot straight past it into the retry by holding (or quickly double-tapping) Enter after the last answer; the summary no longer starts the retry from a keypress at all — you choose "Popraw/Powtórz błędne" or "Zakończ" with a deliberate click (or Tab+Enter)

## 0.11.10 — in a custom course the lector picker (both in a session and in Settings) now shows "Systemowy" as the selected voice instead of a greyed-out "Nadia" you can't pick — the system voice was already the one playing; switch back to a built-in course and Nadia returns. Display-only fix

## 0.11.9 — an answer that lists several meanings separated by commas is now accepted (e.g. "ufać, powierzać" for доверять) — each part just has to be one of the word's variants, in any order

## 0.11.8 — the accented-vowel keyboard row now appears only in the custom-course editor, not in learning/practice/test sessions; and in a Polish→Russian exercise, once you answer correctly you can hold Tab to peek at the word's 1st-person form, conjugation type and pronunciation

## 0.11.7 — on a custom course the "Nadia" voice is now greyed out in the session lector picker with a tooltip — its pre-recorded audio only covers the built-in courses, so custom words fall back to the system voice

## 0.11.6 — edit a word in a custom course: a pencil icon on each row opens a dialog to change its Russian (with accent), Polish variants, category, pronunciation and verb fields

## 0.11.5 — a "Zapisz" button at the bottom of the custom-course editor returns to the course list (words already save the moment you add them)

## 0.11.4 — the on-screen Russian keyboard gains a bottom row of accented vowels (above the spacebar) for typing stress marks — in the course editor and during sessions; the custom-course editor also gets an optional "Wymowa" (pronunciation) field

## 0.11.3 — the custom-course word list is now numbered 1…n with the first added word on top (was newest-first and unnumbered), and the delete (trash) icon shows a pointer cursor on hover

## 0.11.2 — the custom-course editor gains an on-screen keyboard with a manual Russian/Polish layout toggle (keys type into the last focused field), a "Kategoria" dropdown listing every category used across the courses, and a "Dodaj" button matched to the input height

## 0.11.1 — the built-in verbs in "Pierwsze kroki" and "1000 słówek" now carry their 1st-person form and conjugation type (1/2), generated with pymorphy3 (tool/generate_verb_forms.py); forms are unstressed for now — stress to follow from a stressed dictionary. A handful of irregular/impersonal verbs were left for manual review

## 0.11.0 — verbs can now carry a 1st-person form and a conjugation type (e.g. е́хать¹ (я е́ду)); a new "Odmiana czasowników" setting shows them never / always / on holding Tab (default: on Tab, next to the pronunciation reveal). Add both fields when building your own course or via JSON import (firstPerson / verbType)

## 0.10.4 — a word can lose at most one point per session no matter how many times it is missed (e.g. in the looping fix-up), so hammering wrong answers on one word can't tank its score

## 0.10.3 — renamed the session scope "Najtrudniejsze" to "Sprawiające trudności" and added it as a filter on the Words screen; a new debug setting (off by default) adds a per-word "Punkty" column (streak − difficulty) coloured red for negative, green for positive, neutral for zero

## 0.10.2 — a word now leaves the "hardest" set once you answer it correctly (cleanly) three times in a row, so practising heals it out — even in the same session; a wrong or "almost" resets that streak and brings the word back

## 0.10.1 — the end-of-session "fix your mistakes" pass now scores only mistakes: missing a word there still counts against it (resets it and adds to its difficulty), but typing a correction right never gives credit or advances the word

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
