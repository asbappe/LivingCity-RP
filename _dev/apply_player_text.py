#!/usr/bin/env python3
"""Put corrected wording from an edited PLAYER_TEXT.md back into the code.

    python3 _dev/apply_player_text.py EDITED.md [ORIGINAL.md]

EDITED.md is a copy of PLAYER_TEXT.md with the text inside the quotes changed (DELETE
inside the quotes leaves the line as it is and lists it for a person to remove, since
taking text out of the code needs care; NOTE: after a line is printed for the reader).
ORIGINAL.md is the PLAYER_TEXT.md it was made from (default: the one at the version
named in its "Made from version" line, else the current file). Lines are matched by
file, line number and order, and each changed text is found in the code by its old
wording, so it still works after the code has moved on. Prints what it changed and
anything it couldn't place.
"""
import os, re, subprocess, sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINE = re.compile(r'^- "(.*)"  \((.*?), line (\d+)\)(.*)$')
STR = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
PH = re.compile(r"\{[^{}]*\}")

def parse(text):
    out, cur = [], None
    for l in text.split("\n"):
        m = re.match(r"^`(gamemodes/[^`]+)`", l.strip())
        if m: cur = m.group(1); continue
        m = LINE.match(l)
        if m and cur: out.append((cur, int(m.group(3)), m.group(1).replace("\\|", "|"), m.group(4).strip())) # (the file escapes | for its tables)
    return out

def unesc(s): return re.sub(r"\\(.)", lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), s)
def esc(s): return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")

NEAR = 8 # (how many lines from where the list says a text is, it may have moved)

def line_of(src, pos): return src.count("\n", 0, pos) + 1

def matches(src, text):
    """Every string in the code that is this text (a line break shows as " / " in the list)."""
    return [m for m in STR.finditer(src) if unesc(m.group(1)) in (text, text.replace(" / ", "\n")) or unesc(m.group(1)).replace("\n", " / ") == text]

def put(src, m, new):
    if "\n" in unesc(m.group(1)): new = new.replace(" / ", "\n")
    return src[:m.start()] + '"' + esc(new) + '"' + src[m.end():]

def replace_whole(src, old, new, line=None):
    """The string at (or near) its line. Only if the list is from an older version and it isn't
    there: the same text wherever it is (the whole text, never a piece of one)."""
    hits = matches(src, old)
    if line:
        near = [m for m in hits if abs(line_of(src, m.start()) - line) <= NEAR]
        if near: hits = near
    for m in sorted(hits, key=lambda m: -m.start()):
        src = put(src, m, new)
    return src, len(hits)

def replace_pieces(src, old, new, line=None):
    """Text joined from several pieces in the code ({name} parts in between): each piece, only
    the one nearest the line (a piece like "." is everywhere)."""
    op, np_ = PH.split(old), PH.split(new)
    if PH.findall(old) != PH.findall(new) or len(op) != len(np_) or not line: return src, 0
    todo = []
    for a, b in zip(op, np_):
        if a == b: continue
        if not a.strip(): return src, 0 # (nothing in the code to change: a new piece can't be added)
        hits = [m for m in matches(src, a) if abs(line_of(src, m.start()) - line) <= NEAR]
        if not hits: return src, 0
        todo.append((min(hits, key=lambda m: abs(line_of(src, m.start()) - line)), b))
    for m, b in sorted(todo, key=lambda t: -t[0].start()):
        src = put(src, m, b)
    return src, len(todo)

def main():
    edited = open(sys.argv[1], encoding="utf-8").read()
    if len(sys.argv) > 2:
        original = open(sys.argv[2], encoding="utf-8").read()
    else:
        m = re.search(r"Made from version (\w+)", edited)
        original = None
        if m:
            try:
                for c in subprocess.check_output(["git", "-C", ROOT, "log", "--format=%h", "--", "PLAYER_TEXT.md"], text=True).split():
                    t = subprocess.check_output(["git", "-C", ROOT, "show", c + ":PLAYER_TEXT.md"], text=True)
                    if ("Made from version " + m.group(1)) in t: original = t; break
            except Exception: pass
        original = original or open(os.path.join(ROOT, "PLAYER_TEXT.md"), encoding="utf-8").read()
    o = defaultdict(list)
    for f, ln, t, _ in parse(original): o[(f, ln)].append(t)
    used = defaultdict(int)
    changed, missing, deletes, notes = 0, [], [], []
    for f, ln, t, rest in parse(edited):
        k = (f, ln); i = used[k]; used[k] += 1
        if "NOTE:" in rest: notes.append((f, ln, rest[rest.index("NOTE:"):]))
        if i >= len(o[k]) or o[k][i] == t: continue
        old = o[k][i]
        if t.strip().upper() == "DELETE": deletes.append((f, ln, old)); continue
        path = os.path.join(ROOT, f)
        src = open(path, encoding="utf-8").read()
        new, n = replace_whole(src, old, t, ln)
        if n == 0: new, n = replace_pieces(src, old, t, ln)
        if n == 0: missing.append((f, ln, old)); continue
        open(path, "w", encoding="utf-8").write(new)
        changed += 1
    print(f"{changed} lines changed in the code")
    for f, ln, old in missing: print(f"COULD NOT PLACE {f}:{ln}: {old}")
    for f, ln, old in deletes: print(f"DELETE asked {f}:{ln}: {old}")
    for f, ln, note in notes: print(f"{f}:{ln} {note}")

if __name__ == "__main__":
    main()
