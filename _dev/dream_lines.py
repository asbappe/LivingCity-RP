#!/usr/bin/env python3
"""Makes docs/features/dream-lines.md: every line said in a dream you play, for the owner to record
(ElevenLabs or anything else). Read from the code, so it's never out of date: rerun after adding lines.

    python3 _dev/dream_lines.py
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
SV = os.path.join(ROOT, "gamemodes", "livingcity", "gamemode", "modules", "server")
OUT = os.path.join(ROOT, "docs", "features", "dream-lines.md")

STR = r'"((?:[^"\\]|\\.)*)"'
THREE = re.compile(r'^\s*(\w+)\s*=\s*\{\s*' + STR + r'\s*,\s*' + STR + r'\s*,\s*' + STR + r'\s*\},?\s*$')
TWO = re.compile(r'^\s*(\w+)\s*=\s*\{\s*' + STR + r'\s*,\s*' + STR + r'\s*\},?\s*$')
ONE = re.compile(r'^\s*(\w+)\s*=\s*' + STR + r',?\s*$')

NAMES = {
    "cheese": "The Cheese Dream", "chairs": "Musical Chairs", "flying": "Wings", "melons": "It's Raining Melons",
    "horse": "Hooves and All", "boxing": "The Main Event", "exam": "The Exam", "train": "The Last Train", "lamarr": "Where's Lamarr?",
    "molasses": "Running in Molasses", "potato": "Hot Potato", "simon": "Overwatch Says", "dance": "Dance Marathon", "sheep": "Counting Headcrabs",
    "adore": "Kneel Before Her", "roses": "Roses for Her", "mirror": "Mirror, Mirror", "saviour": "The Saviour", "quiz": "The Loyalty Quiz",
    "harvest": "Record Harvest", "shift": "The Stakhanov Shift", "spy": "Careless Talk", "newsreel": "The Newsreel", "hate": "Two Minutes of Hate",
    "massgames": "The Mass Games", "guidance": "On-the-Spot Guidance", "scrap": "The Scrap Drive", "flowers": "Flowers for the Liberators",
    "duck": "Duck and Cover", "ravenholm": "Ravenholm",
}


def unq(s):
    return s.replace('\\"', '"').replace("\\'", "'")


def read(name):
    with open(os.path.join(SV, name), encoding="utf-8") as f:
        return f.read().split("\n")


def strange():
    out = []
    for name in ("sv_livingcity_strangedreams.lua", "sv_livingcity_strangedreams2.lua"):
        inside = False
        for line in read(name):
            if "LC.StrangeAddCues({" in line:
                inside = True
                continue
            if inside and line.startswith("})"):
                inside = False
            if inside:
                m = THREE.match(line)
                if m:
                    out.append((m.group(1), unq(m.group(2)), unq(m.group(3)), unq(m.group(4))))
    return out


def propaganda():
    out = []
    inside = False
    for line in read("sv_livingcity_propagandadreams.lua"):
        if line.startswith("LC.PropagandaCues = {"):
            inside = True
            continue
        if inside and line.startswith("}"):
            break
        m = inside and ONE.match(line)
        if m:
            out.append((m.group(1), "The Administrator", unq(m.group(2)), "her own voice: warm, regal, a little vain"))
    inside = False
    for line in read("sv_livingcity_propagandamore.lua"):
        if re.match(r"^\s*local (CUES|LINES) = \{", line):
            inside = True
            continue
        if inside and re.match(r"^\s*\}", line):
            inside = False
        m = inside and TWO.match(line)
        if m:
            out.append((m.group(1), unq(m.group(2)), unq(m.group(3)), "her own voice" if m.group(2) == "The Administrator" else ""))
    return out


def group(rows):
    by = {}
    order = []
    for r in rows:
        key = r[0].split("_")[0]
        if key not in by:
            by[key] = []
            order.append(key)
        by[key].append(r)
    return order, by


def table(rows):
    lines = ["| File | Who | Words | How it should sound |", "|---|---|---|---|"]
    for cue, who, words, how in rows:
        lines.append("| `%s1.mp3` | %s | %s | %s |" % (cue, who, words.replace("|", "/"), how.replace("|", "/")))
    return lines


def main():
    doc = [
        "# Dream lines to record",
        "",
        "Every line said in the dreams you play, made from the code by `python3 _dev/dream_lines.py` (never edit by hand: rerun it).",
        "",
        "**How to use a recording:** save it as the file name below (`.mp3`, `.ogg` or `.wav`; a second take can be `...2.mp3`, one is picked at random) in the server's "
        "`garrysmod/sound/livingcity/dreams/voice/`. If the words you recorded differ, put them in a `.txt` of the same name (`horse_grigori1.txt`) and those show on screen "
        "instead. Then FastDL sync and a map change, as with every new sound. Without a recording, the words still come up at the bottom of the screen.",
        "",
        "**Music** for any dream goes in `garrysmod/sound/livingcity/dreams/`, named for the dream's codeword (the word in brackets below): `horse1.mp3`, `boxing1.mp3`. "
        "Dance Marathon follows its song's tempo: put the BPM in `dance1.txt` (just the number, like `120`).",
        "",
        "**The voices in the dark:** The Cheese Dream uses Half-Life 2's own citizens (\"Sometimes I dream about cheese\"). Hooves and All uses Half-Life 2's hungry line too, "
        "unless you record `horse_intro_male1.mp3` and `horse_intro_female1.mp3`, which take its place. Either way they echo, far off, in the dark.",
        "",
        "## The strange dreams",
        "",
    ]
    order, by = group(strange())
    for key in order:
        doc.append("### %s (`%s`)" % (NAMES.get(key, key), key))
        doc.append("")
        doc += table(by[key])
        doc.append("")
    doc += ["## The propaganda dreams", "", "(The Loyalty Quiz's questions, `quiz_q1` onwards, are read out too: each is its question.)", ""]
    order, by = group(propaganda())
    for key in order:
        doc.append("### %s (`%s`)" % (NAMES.get(key, key), key))
        doc.append("")
        doc += table(by[key])
        doc.append("")
    text = "\n".join(doc).rstrip("\n") + "\n"
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    print("wrote docs/features/dream-lines.md: %d lines to record" % sum(1 for l in doc if l.startswith("| `")))


if __name__ == "__main__":
    main()
