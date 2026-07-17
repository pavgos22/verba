"""Fill verb forms (czasowniki) and adjective gender forms (przymiotniki) in the course JSON files.

Requires: pip install pymorphy3 pymorphy3-dicts-ru

For every word whose category is "przymiotniki" this derives the nominative
feminine / neuter / plural forms (e.g. новый -> новая / новое / новые). The stress
is transferred from the masculine ruAccented: adjectives in -ый/-ий are stem-stressed
(the stem accent stays put), adjectives in -ой are end-stressed. Irregular / pronominal
adjectives that don't fit are stored unstressed and flagged for review.

For every word whose category is "czasowniki" this derives:
  - firstPerson: the 1st-person singular present/future form (unstressed).
  - secondPerson: the 2nd-person singular form, but only when it contains "ё"
    (the stem vowel shifting to a stressed ё is "trap 2"; e.g. жить -> живёшь,
    петь -> поёшь). Verbs without that shift (ехать -> едешь) get no secondPerson.
  - verbType: conjugation class "1" or "2", from the 3rd-person plural ending
    (-ут/-ют = 1st conjugation, -ат/-ят = 2nd).

The 1st-person forms carry no stress marks yet (morphology has no stress); they
can be accented later from a stressed dictionary. The ё in secondPerson already
marks its own stress. Irregular / mixed-conjugation verbs and anything the
analyzer could not resolve are written to a review report.

Usage:
  python tool/generate_verb_forms.py            # write the JSON files
  python tool/generate_verb_forms.py --dry       # report only, no writes
"""

import io
import json
import re
import sys

import pymorphy3

COURSES = ["assets/data/course_ru1000.json", "assets/data/course_starter.json"]
REPORT = "tool/verb_forms_report.txt"
STRESS = "́"
STRESS_JO = "ё"
SUSPECT_ROOTS = ("бежать", "хотеть", "дать", "есть", "идти", "ехать", "чтить")
OVERRIDES = {"быть": ("буду", "1")}
EXCLUDE_SECOND = {"пахнуть", "честь"}

morph = pymorphy3.MorphAnalyzer()


def bare(text):
    return text.replace(STRESS, "").lower().strip()


def strip_reflexive(form):
    for postfix in ("ся", "сь"):
        if form.endswith(postfix):
            return form[: -len(postfix)]
    return form


def analyze(infinitive):
    inf = bare(infinitive)
    if inf in OVERRIDES:
        first, vtype = OVERRIDES[inf]
        return first, None, vtype, ""
    cands = [p for p in morph.parse(inf) if p.tag.POS in ("INFN", "VERB")]
    exact = [p for p in cands if p.normal_form == inf]
    cands = exact or cands
    if not cands:
        return None, None, None, "no-parse"
    p = cands[0]
    tenses = ["futr", "pres"] if "perf" in p.tag else ["pres", "futr"]
    first = second = third = None
    for tense in tenses:
        one = p.inflect({"1per", "sing", tense})
        if one is None:
            continue
        first = one.word
        two = p.inflect({"2per", "sing", tense})
        second = two.word if two is not None else None
        plur = p.inflect({"3per", "plur", tense})
        third = plur.word if plur is not None else None
        break
    if first is None:
        return None, None, None, "no-1sg"
    vtype = None
    if third:
        stem = strip_reflexive(third)
        if stem.endswith(("ут", "ют")):
            vtype = "1"
        elif stem.endswith(("ат", "ят")):
            vtype = "2"
    return first, second, vtype, "" if vtype else "no-conj"


VOWELS = "аеёиоуыэюя"


def _accent_ending(form, stem_len):
    ending = form[stem_len:]
    for i, ch in enumerate(ending):
        if ch in VOWELS:
            cut = stem_len + i + 1
            return form[:cut] + STRESS + form[cut:]
    return form


def analyze_adjective(ru, ru_accented):
    b = bare(ru)
    cands = [p for p in morph.parse(b) if p.tag.POS == "ADJF"]
    exact = [p for p in cands if p.normal_form == b]
    cands = exact or cands
    if not cands:
        return None, None, None, "no-adjf"
    p = cands[0]
    fem = p.inflect({"femn", "sing", "nomn"})
    neut = p.inflect({"neut", "sing", "nomn"})
    plur = p.inflect({"plur", "nomn"})
    if fem is None or neut is None or plur is None:
        return None, None, None, "no-forms"
    forms = [fem.word, neut.word, plur.word]
    if b.endswith("ой"):
        stem = b[:-2]
        if all(f.startswith(stem) for f in forms):
            out = [_accent_ending(f, len(stem)) for f in forms]
            return out[0], out[1], out[2], ""
        return None, None, None, "irregular"
    if b.endswith(("ый", "ий")):
        stem_bare = b[:-2]
        if not all(f.startswith(stem_bare) for f in forms):
            return None, None, None, "irregular"
        stem_accented = ru_accented[:-2] if ru_accented else stem_bare
        if STRESS not in stem_accented and STRESS_JO not in stem_accented:
            return forms[0], forms[1], forms[2], "no-stress"
        out = [stem_accented + f[len(stem_bare):] for f in forms]
        return out[0], out[1], out[2], ""
    return None, None, None, "irregular"


def is_suspect(infinitive):
    b = bare(infinitive)
    return any(b.endswith(root) for root in SUSPECT_ROOTS)


def dump_matching(data, original):
    if not re.search(r"^\s*\{\"", original, re.M):
        return json.dumps(data, ensure_ascii=False, indent=1) + "\n"
    lines = ["{"]
    for key, value in data.items():
        if key == "words":
            continue
        lines.append(" %s: %s," % (json.dumps(key, ensure_ascii=False), json.dumps(value, ensure_ascii=False)))
    lines.append(' "words": [')
    words = data["words"]
    for i, word in enumerate(words):
        sep = "," if i < len(words) - 1 else ""
        lines.append("  %s%s" % (json.dumps(word, ensure_ascii=False), sep))
    lines.append(" ]")
    lines.append("}")
    return "\n".join(lines) + "\n"


def process(path, report, write):
    original = open(path, encoding="utf-8").read()
    data = json.loads(original)
    verbs = filled = adjs = adjs_filled = 0
    review = []
    adj_review = []
    for word in data["words"]:
        cat = word.get("category")
        if cat == "czasowniki":
            verbs += 1
            first, second, vtype, reason = analyze(word["ru"])
            if first:
                word["firstPerson"] = first
            if second and STRESS_JO in second and bare(word["ru"]) not in EXCLUDE_SECOND:
                word["secondPerson"] = second
            elif "secondPerson" in word:
                del word["secondPerson"]
            if vtype:
                word["verbType"] = vtype
            if first and vtype:
                filled += 1
            flag = reason or ("suspect" if is_suspect(word["ru"]) else "")
            if flag:
                review.append((word["ru"], first, vtype, flag))
        elif cat == "przymiotniki":
            adjs += 1
            fem, neut, plur, reason = analyze_adjective(word["ru"], word.get("ruAccented", word["ru"]))
            if fem and neut and plur:
                word["feminine"] = fem
                word["neuter"] = neut
                word["plural"] = plur
                adjs_filled += 1
            else:
                for key in ("feminine", "neuter", "plural"):
                    word.pop(key, None)
            if reason:
                adj_review.append((word["ru"], fem, reason))
    if write:
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(dump_matching(data, original))
    report.write(
        "\n=== %s: verbs=%d filled=%d review=%d | adjs=%d filled=%d review=%d ===\n"
        % (path, verbs, filled, len(review), adjs, adjs_filled, len(adj_review))
    )
    for ru, first, vtype, flag in review:
        report.write("  V %-22s 1sg=%-16s type=%-4s %s\n" % (ru, first, vtype, flag))
    for ru, fem, flag in adj_review:
        report.write("  A %-22s f=%-16s %s\n" % (ru, fem, flag))
    return verbs, filled, len(review)


def main():
    write = "--dry" not in sys.argv
    total = done = flagged = 0
    with io.open(REPORT, "w", encoding="utf-8") as report:
        for path in COURSES:
            v, f, r = process(path, report, write)
            total += v
            done += f
            flagged += r
    print("verbs=%d filled=%d review=%d write=%s" % (total, done, flagged, write))
    print("report:", REPORT)


if __name__ == "__main__":
    main()
