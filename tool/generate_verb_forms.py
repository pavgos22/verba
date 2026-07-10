"""Fill firstPerson + verbType for verbs in the course JSON files.

Requires: pip install pymorphy3 pymorphy3-dicts-ru

For every word whose category is "czasowniki" this derives:
  - firstPerson: the 1st-person singular present/future form (unstressed).
  - verbType: conjugation class "1" or "2", from the 3rd-person plural ending
    (-ут/-ют = 1st conjugation, -ат/-ят = 2nd).

Forms carry no stress marks yet (morphology has no stress); they can be
accented later from a stressed dictionary. Irregular / mixed-conjugation verbs
and anything the analyzer could not resolve are written to a review report.

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
SUSPECT_ROOTS = ("бежать", "хотеть", "дать", "есть", "идти", "ехать", "чтить")
OVERRIDES = {"быть": ("буду", "1")}

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
        return first, vtype, ""
    cands = [p for p in morph.parse(inf) if p.tag.POS in ("INFN", "VERB")]
    exact = [p for p in cands if p.normal_form == inf]
    cands = exact or cands
    if not cands:
        return None, None, "no-parse"
    p = cands[0]
    tenses = ["futr", "pres"] if "perf" in p.tag else ["pres", "futr"]
    first = third = None
    for tense in tenses:
        one = p.inflect({"1per", "sing", tense})
        if one is None:
            continue
        first = one.word
        plur = p.inflect({"3per", "plur", tense})
        third = plur.word if plur is not None else None
        break
    if first is None:
        return None, None, "no-1sg"
    vtype = None
    if third:
        stem = strip_reflexive(third)
        if stem.endswith(("ут", "ют")):
            vtype = "1"
        elif stem.endswith(("ат", "ят")):
            vtype = "2"
    return first, vtype, "" if vtype else "no-conj"


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
    verbs = filled = 0
    review = []
    for word in data["words"]:
        if word.get("category") != "czasowniki":
            continue
        verbs += 1
        first, vtype, reason = analyze(word["ru"])
        if first:
            word["firstPerson"] = first
        if vtype:
            word["verbType"] = vtype
        if first and vtype:
            filled += 1
        flag = reason or ("suspect" if is_suspect(word["ru"]) else "")
        if flag:
            review.append((word["ru"], first, vtype, flag))
    if write:
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(dump_matching(data, original))
    report.write("\n=== %s: verbs=%d filled=%d review=%d ===\n" % (path, verbs, filled, len(review)))
    for ru, first, vtype, flag in review:
        report.write("  %-24s 1sg=%-16s type=%-4s %s\n" % (ru, first, vtype, flag))
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
