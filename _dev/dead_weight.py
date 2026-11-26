#!/usr/bin/env python3
"""
Living City: dead weight, listed for the owner to approve (TODO.md, "Simpler and better", idea 9: "Functions nothing
calls, net messages never sent, commands with no menu route, items nobody can get. ... it needs a proper pass before
anything is removed"). Nothing is removed by this: it writes docs/dev/dead-weight.md.

    python3 _dev/dead_weight.py            write the list
    python3 _dev/dead_weight.py --print    print the counts only

What counts (a rough pass, by name, so each line is a lead to check by hand, not a verdict):
    a function with no caller  LC.Name / LC_CL.Name defined in the gamemode, its name appearing nowhere else in the
                               gamemode, the tools, the pose recorder or the tests' gamemode stubs (a name built from
                               strings, or called only by tests, still shows: tests are not counted as callers)
    a net message never sent   util.AddNetworkString("x") with no net.Start("x") anywhere, or started with no receiver
    an item nobody can get     an item in the items table whose id appears nowhere else in the gamemode
"""
import os, re, sys, glob

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GM = os.path.join(ROOT, "gamemodes", "livingcity")

def lua_files():
    out = []
    for base in (GM, os.path.join(ROOT, "lua"), os.path.join(ROOT, "pose_recorder")):
        for p in glob.glob(os.path.join(base, "**", "*.lua"), recursive=True):
            out.append(p)
    return out

def strip_comments(src):
    src = re.sub(r"--\[(=*)\[.*?\]\1\]", "", src, flags=re.S)
    return re.sub(r"--[^\n]*", "", src)

def main():
    files = lua_files()
    text = {p: strip_comments(open(p, encoding="utf-8", errors="replace").read()) for p in files}
    allsrc = "\n".join(text.values())
    rel = lambda p: os.path.relpath(p, ROOT)

    # functions with no caller
    defs = []
    for p, s in text.items():
        for m in re.finditer(r"^\s*function\s+(LC_CL|LC)\.([A-Za-z_][A-Za-z0-9_]*)\s*\(", s, re.M):
            defs.append((m.group(1), m.group(2), p, s[:m.start()].count("\n") + 1))
        for m in re.finditer(r"^\s*(LC_CL|LC)\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*function\b", s, re.M):
            defs.append((m.group(1), m.group(2), p, s[:m.start()].count("\n") + 1))
    from collections import Counter
    words = Counter(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", allsrc))
    ndef = Counter(d[1] for d in defs)
    nocall = []
    seen = set()
    for tbl, name, p, line in defs:
        if (tbl, name) in seen:
            continue
        seen.add((tbl, name))
        uses = words[name]
        ndefs = ndef[name]
        # every definition mentions the name once; a guard "if LC.X then" counts as a use (it is checked for)
        if uses <= ndefs:
            nocall.append((tbl + "." + name, rel(p), line))

    # net messages
    added = {}
    for p, s in text.items():
        for m in re.finditer(r'util\.AddNetworkString\(\s*"([^"]+)"', s):
            added.setdefault(m.group(1), rel(p))
    started = set(re.findall(r'net\.Start\(\s*"([^"]+)"', allsrc))
    received = set(re.findall(r'net\.Receive\(\s*"([^"]+)"', allsrc))
    # LC.SendCompressed("name", ...) starts a message by name too
    started |= set(re.findall(r'SendCompressed\(\s*"([^"]+)"', allsrc))
    received |= set(re.findall(r'ReceiveCompressed\(\s*"([^"]+)"', allsrc))
    # a module's own helper sends by name as well: Send(ply, "name", t) (the intake tutor, the interrogation)
    started |= set(re.findall(r'\bSend\(\s*[\w.]+\s*,\s*"([^"]+)"', allsrc))
    never_sent = sorted((n, f) for n, f in added.items() if n not in started)
    never_heard = sorted((n, f) for n, f in added.items() if n in started and n not in received)

    # items
    shop = os.path.join(GM, "gamemode", "modules", "shared", "sh_livingcity_shop.lua")
    ssrc = text.get(shop, "")
    items = re.findall(r"^\s{4}([a-z_][a-z0-9_]*)\s*=\s*\{\s*name\s*=", ssrc, re.M)
    others = Counter(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", "\n".join(s for p, s in text.items() if p != shop)))
    inshop = Counter(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", ssrc))
    # named nowhere else in the gamemode, and only once in the items file (its own definition)
    lonely = [i for i in items if others[i] == 0 and inshop[i] <= 1]

    if "--print" in sys.argv:
        print(f"functions with no caller: {len(nocall)}; net messages never sent: {len(never_sent)}, sent but never received: {len(never_heard)}; items named nowhere else: {len(lonely)}")
        return
    out = ["# Dead weight: leads for the owner to approve (nothing removed)", "",
           "Made by `python3 _dev/dead_weight.py` (TODO.md, \"Simpler and better\", idea 9). A rough pass by name: each line is a lead to "
           "check by hand before anything goes. Tests are not counted as callers. Regenerate it after changes; never hand-edit.", "",
           f"**{len(nocall)} functions with no caller by name, {len(never_sent)} net messages never sent, {len(never_heard)} sent but never "
           f"received, {len(lonely)} items named nowhere but the items table.** Commands no menu names: `python3 _dev/house_rules.py --list`.", ""]
    out += ["## Functions with no caller by name", ""]
    out += [f"- `{n}` ({f}:{l})" for n, f, l in sorted(nocall, key=lambda x: (x[1], x[2]))] or ["- none"]
    out += ["", "## Net messages never sent", ""]
    out += [f"- `{n}` (added in {f})" for n, f in never_sent] or ["- none"]
    out += ["", "## Net messages sent but never received", ""]
    out += [f"- `{n}` (added in {f})" for n, f in never_heard] or ["- none"]
    out += ["", "## Items named nowhere but the items table (nobody can get them, unless by a name built from strings)", ""]
    out += [f"- `{i}`" for i in lonely] or ["- none"]
    path = os.path.join(ROOT, "docs", "dev", "dead-weight.md")
    open(path, "w").write("\n".join(out) + "\n")
    print(f"wrote {os.path.relpath(path, ROOT)}: {len(nocall)} functions, {len(never_sent)} + {len(never_heard)} net messages, {len(lonely)} items")

if __name__ == "__main__":
    main()
