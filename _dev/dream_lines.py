#!/usr/bin/env python3
"""Reads every line said in a dream you play, from the code. They go in VOICE_LINES.md, section 4, with every
other voice line (_dev/voice_lines.py; the owner, 10 November: all in a single document). Running this file
remakes VOICE_LINES.md.

    python3 _dev/dream_lines.py   (the same as python3 _dev/voice_lines.py)
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
SV = os.path.join(ROOT, "gamemodes", "livingcity", "gamemode", "modules", "server")

STR = r'"((?:[^"\\]|\\.)*)"'
THREE = re.compile(r'^\s*(\w+)\s*=\s*\{\s*' + STR + r'\s*,\s*' + STR + r'\s*,\s*' + STR + r'\s*\},?\s*$')
TWO = re.compile(r'^\s*(\w+)\s*=\s*\{\s*' + STR + r'\s*,\s*' + STR + r'\s*\},?\s*$')
ONE = re.compile(r'^\s*(\w+)\s*=\s*' + STR + r',?\s*$')

NAMES = {
    "cheese": "The Cheese Dream", "chairs": "Musical Chairs", "flying": "Wings", "melons": "It's Raining Melons", "rally": "The Midnight Rally",
    "horse": "Hooves and All", "boxing": "The Main Event", "exam": "The Exam", "train": "The Last Train", "lamarr": "Where's Lamarr?",
    "molasses": "Running in Molasses", "potato": "Hot Potato", "simon": "Overwatch Says", "dance": "Dance Marathon", "sheep": "Counting Headcrabs",
    "clocks": "Stop the Clocks", "tea": "The Tea Party", "derby": "The Headcrab Derby", "photo": "Say Cheese", "doors": "The Doors", "paint": "Splat!",
    "conga": "Conga!", "shh": "Shh!", "bubbles": "Bubbles", "watchers": "The Watchers",
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
    for name in ("sv_livingcity_strangedreams.lua", "sv_livingcity_strangedreams2.lua", "sv_livingcity_strangedreams3.lua"):
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
    for name in ("sv_livingcity_propagandamore.lua", "sv_livingcity_battleline.lua", "sv_livingcity_vortwar.lua"):
        inside = False
        for line in read(name):
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
    import voice_lines
    voice_lines.main()


if __name__ == "__main__":
    main()
