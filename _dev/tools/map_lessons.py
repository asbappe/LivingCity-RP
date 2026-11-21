#!/usr/bin/env python3
"""
Living City: the lessons for building map pieces, and the City 18 reference pictures.

    python3 map_lessons.py                 every lesson, one line each
    python3 map_lessons.py --tag doors     the lessons with that tag, in full
    python3 map_lessons.py --find glass    the lessons that mention a word, in full
    python3 map_lessons.py --tags          the tags and how many lessons each has
    python3 map_lessons.py --md            rewrite docs/dev/city18-reference.md from the files below
    python3 map_lessons.py --merge FILE    add proposed lessons from FILE to lessons.json, then rewrite the page

The lessons are in _dev/reference/lessons.json (one entry each: what to do, why, how the tools do it, what checks
it); the reference pictures of the owner's City 18 map are in _dev/reference/city18/, described in
_dev/reference/city18/pictures.json. Every other picture set is found by itself: each _dev/reference/valve_*/
pictures.json, titled by its "title" key (else the folder name), in folder order after City 18. A set still
marked "draft": true (map_ingest.py writes those) is left out of the page until a reviewer has filled it in.
Add a lesson whenever the owner corrects a piece: it is how the next piece starts right. Read the lessons before
building a piece (--tag for the kind of piece).

--merge FILE takes a JSON list (or {"lessons": [...]}) of whole new lessons (id, tags, title, rule, why, how,
check) and of additions to existing ones: {"id": "an-existing-id", "extra": {"how": "a sentence"}} appends the
sentence to that field. It refuses em dashes and an id that is already taken, and prints what changed.
"""
import argparse
import glob
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REF = os.path.join(HERE, "..", "reference")
LESSONS = os.path.join(REF, "lessons.json")
PICTURES = os.path.join(REF, "city18", "pictures.json")
DOC = os.path.join(HERE, "..", "..", "docs", "dev", "city18-reference.md")


FIELDS = ("id", "tags", "title", "rule", "why", "how", "check")


def sets(quiet=False):
    """Every picture set beside City 18: (folder, title, its pictures.json), drafts left out."""
    out, drafts = [], []
    for f in sorted(glob.glob(os.path.join(REF, "valve_*", "pictures.json"))):
        folder = os.path.basename(os.path.dirname(f))
        ps = json.load(open(f))
        if ps.get("draft"):
            drafts.append(folder)
            continue
        out.append((folder, ps.get("title") or folder, ps))
    if drafts and not quiet:
        print("left out (still drafts): %s" % ", ".join(drafts))
    return out


def load(quiet=False):
    lessons = json.load(open(LESSONS))["lessons"]
    pictures = json.load(open(PICTURES)) if os.path.exists(PICTURES) else {"pictures": [], "numbers": []}
    pictures["sets"] = sets(quiet)
    return lessons, pictures


def merge(path):
    """Proposed lessons into lessons.json: new ids added, {"id", "extra": {field: sentence}} appended. Rewrites the page."""
    text = open(path).read()
    if chr(0x2014) in text:
        raise SystemExit("an em dash in %s: take it out" % path)
    P = json.loads(text)
    P = P if isinstance(P, list) else P.get("lessons", [])
    L = json.load(open(LESSONS))
    by = {l["id"]: l for l in L["lessons"]}
    added, extended, refused = [], [], []
    for x in P:
        if "extra" in x:
            l = by.get(x.get("id"))
            if not l:
                refused.append("%s: no such lesson to extend" % x.get("id"))
                continue
            ex = x["extra"] if isinstance(x["extra"], dict) else {"how": x["extra"]}
            for k, v in ex.items():
                if k == "tags":
                    new = [t for t in (v if isinstance(v, list) else [v]) if t not in l["tags"]]
                    l["tags"] += new
                    if new:
                        extended.append("%s tags +%s" % (l["id"], ", ".join(new)))
                elif k not in FIELDS[2:]:
                    refused.append("%s: no field %r" % (l["id"], k))
                elif v.strip() and v.strip() not in l[k]:
                    l[k] = l[k].rstrip() + " " + v.strip()
                    extended.append("%s %s" % (l["id"], k))
        else:
            missing = [k for k in FIELDS if not x.get(k)]
            if missing:
                refused.append("%s: missing %s" % (x.get("id", "?"), ", ".join(missing)))
            elif x["id"] in by:
                refused.append("%s: id taken (to add to it, use extra)" % x["id"])
            else:
                L["lessons"].append({k: x[k] for k in FIELDS})
                by[x["id"]] = L["lessons"][-1]
                added.append(x["id"])
    out = json.dumps(L, indent=1, ensure_ascii=False)
    if chr(0x2014) in out:
        raise SystemExit("an em dash would go into lessons.json: nothing written")
    if added or extended:
        open(LESSONS, "w").write(out)
    for line in ["added: " + a for a in added] + ["extended: " + e for e in extended] + ["refused: " + r for r in refused]:
        print(line)
    print("%d added, %d extended, %d refused; %d lessons in all" % (len(added), len(extended), len(refused), len(L["lessons"])))
    if added or extended:
        write_doc()


def write_doc():
    lessons, pictures = load()
    text = markdown(lessons, pictures)
    if chr(0x2014) in text:
        raise SystemExit("an em dash in the lessons or pictures: take it out")
    open(DOC, "w").write(text)
    print("written: %s (%d lessons, %d pictures)" % (os.path.relpath(DOC), len(lessons), len(pictures.get("pictures", [])) + sum(len(ps.get("pictures", [])) for _, _, ps in pictures.get("sets", []))))


def full(l):
    return "%s  [%s]\n  %s\n  Why: %s\n  How: %s\n  Checked by: %s\n" % (l["title"], ", ".join(l["tags"]), l["rule"], l["why"], l["how"], l["check"])


def markdown(lessons, pictures):
    by_id = {l["id"]: l for l in lessons}
    out = ["# City 18 reference and the lessons for map pieces", "",
           "Generated by `python3 _dev/tools/map_lessons.py --md` from `_dev/reference/lessons.json` (the lessons) and "
           "`_dev/reference/city18/pictures.json` (the pictures): edit those, not this page. The owner asked for both, "
           "20 November: \"Take 30 reference pictures of the city 18 map. Make a database or reference for lessons and "
           "concepts learned\".", "",
           "**Before building or changing a map piece:** `python3 _dev/tools/map_lessons.py --tag KIND` (doors, stairs, "
           "streets, facades, interiors, lighting, grime, sound, combine, props, geometry...) and look at the pictures "
           "of the same kind of place below. **When the owner corrects a piece:** add a lesson to `lessons.json` and "
           "rerun `--md`.", "",
           "The pictures are drawn by `map_view.py` (flat colours; props as boxes of their true size, so orange slabs "
           "are lampposts, teal and orange boxes furniture): they show shape, massing, light and layout, not textures. "
           "Each costs usage to look at: read only the ones for the kind of place at hand.", ""]
    if pictures.get("numbers"):
        out += ["## City 18 in numbers (counted in c18_lc.vmf)", ""]
        out += ["- %s" % n for n in pictures["numbers"]]
        out += [""]
    if pictures.get("pictures"):
        out += ["## The pictures (`_dev/reference/city18/`)", "",
                "| # | File | Where | What it teaches | Lessons |", "|---|---|---|---|---|"]
        for p in pictures["pictures"]:
            out.append("| %s | `%s` | %s | %s | %s |" % (p["n"], p["file"], p["where"], p["teaches"], ", ".join(p.get("lessons", []))))
        out += [""]
    for folder, title, ps in pictures.get("sets", []):
        out += ["## %s (`_dev/reference/%s/`)" % (title, folder), "", ps.get("about", ""), ""]
        out += ["- %s" % n for n in ps.get("numbers", [])]
        out += ["", "| # | File | Where | What it teaches | Lessons |", "|---|---|---|---|---|"]
        for p in ps.get("pictures", []):
            out.append("| %s | `%s/%s` | %s | %s | %s |" % (p["n"], folder, p["file"], p["where"], p["teaches"], ", ".join(p.get("lessons", []))))
        out += [""]
    out += ["## The lessons", ""]
    tags = []
    for l in lessons:
        for t in l["tags"]:
            if t not in tags:
                tags.append(t)
    out += ["Tags: " + ", ".join("`%s`" % t for t in tags), ""]
    for l in lessons:
        out += ["### %s (`%s`)" % (l["title"], l["id"]), "",
                "%s" % l["rule"], "",
                "- **Why:** %s" % l["why"],
                "- **How:** %s" % l["how"],
                "- **Checked by:** %s" % l["check"],
                "- **Tags:** %s" % ", ".join(l["tags"]), ""]
        pics = [p["file"] for p in pictures.get("pictures", []) if l["id"] in p.get("lessons", [])]
        pics += ["%s/%s" % (folder, p["file"]) for folder, _, ps in pictures.get("sets", []) for p in ps.get("pictures", []) if l["id"] in p.get("lessons", [])]
        if pics:
            out += ["- **See:** %s" % ", ".join("`%s`" % f for f in pics), ""]
    every = pictures.get("pictures", []) + [p for _, _, ps in pictures.get("sets", []) for p in ps.get("pictures", [])]
    missing = [i for p in every for i in p.get("lessons", []) if i not in by_id]
    if missing:
        raise SystemExit("pictures.json names lessons that do not exist: %s" % ", ".join(sorted(set(missing))))
    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser(description="The lessons for map pieces, and the City 18 reference.")
    ap.add_argument("--tag")
    ap.add_argument("--find")
    ap.add_argument("--tags", action="store_true")
    ap.add_argument("--md", action="store_true")
    ap.add_argument("--merge", metavar="FILE")
    a = ap.parse_args()
    if a.merge:
        return merge(a.merge)
    if a.md:
        return write_doc()
    lessons, pictures = load(quiet=True)
    if a.tags:
        counts = {}
        for l in lessons:
            for t in l["tags"]:
                counts[t] = counts.get(t, 0) + 1
        for t, n in sorted(counts.items(), key=lambda kv: -kv[1]):
            print("%-12s %d" % (t, n))
        return
    if a.tag or a.find:
        for l in lessons:
            if (a.tag and a.tag in l["tags"]) or (a.find and a.find.lower() in json.dumps(l).lower()):
                print(full(l))
        return
    for l in lessons:
        print("%-22s %s" % (l["id"], l["title"]))


if __name__ == "__main__":
    main()
