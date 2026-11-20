#!/usr/bin/env python3
"""
map_merge.py: one VMF out of the owner's map and the pieces

The owner, 20 November: "why do you need me to stitch together the vmfs? Can't you just do it and
consolidate it all under one vmf file? So long as the main c18 map doesn't move or shift its existing
coordinates since the game mode's editor has tons of data placed reliant in the existing coordinates."

    python3 map_merge.py c18_lc.vmf lc_canal.vmf lc_ring.vmf lc_forest_bunker.vmf lc_forest_cave.vmf \
        lc_ravenholm.vmf --out c18_lc_merged.vmf

What it does, and what it never does:

- It never changes the owner's file. It reads it and writes a NEW one.
- In the new file everything of the owner's is where it was, character for character, in the same
  order, with the same ids. Nothing is moved, renumbered or rewritten. The pieces were built at their
  place in the map's own coordinates, so they go in as they are.
- The only things of the owner's that are left out are the brushes each piece was built to replace
  (REPLACES below: the same ones docs/dev/map-building.md asked the owner to delete by hand). Each is
  checked to be where it was when the piece was made; if one is not, the map has changed since and
  nothing is written.
- Where two pieces meet, the cap that shut each of them is left out (the visgroups named
  "... gate's cap (delete to join ...)", when the two caps touch). A cap with nothing against it stays.
- The pieces' brushes go at the end of the world, their entities after the owner's last one, their
  visgroups after the owner's. Their ids are renumbered above the owner's highest (brushes and
  entities from one count, faces from another, as Hammer does), so nothing shares an id.
- A test file (lc_*_test.vmf) is refused: it has a sun, a spawn and walls that must never be in the
  real map.
- Two things for the gamemode's day and night and its dreams (the owner, 20 November: "hook into the
  lights in the map"; --plain leaves both out): the owner's light_environment is given a name
  (SUN_NAME, only if it has none: one line added to it), which is what lets the sun be faded while
  the map runs; and beside each of the dream room's own lights (the ones named evr_l) a second, red
  one that starts dark (TWINS), so a dream can turn the room red. Nothing else of the owner's gains
  or loses a line.

Afterwards it reads its own output back and checks it (CHECKS at the end of the run): the braces, the
ids, the path node numbers, that every block of the owner's is still there unchanged, and names used
by both. It cannot compile: a leak, if there is one, shows on the owner's first compile.
"""
import argparse
import hashlib
import os
import re
import sys

# What each piece stands in the place of: the owner's brush id and its box (x1 y1 z1 x2 y2 z2, whole
# units) as it was when the piece was made. A brush that is no longer there, or not in that box, stops
# the merge: the ids would mean something else in a map that has changed.
REPLACES = {
    "canal": {"15074": None},
    "ring": {"14734": None, "15630": None},
    "ravenholm": {"65929": None, "51870": None, "62363": None, "15623": None, "33530": None, "28290": None, "34874": None},
    "forest_bunker": {},
    "forest_cave": {},
}
BOXES = {   # (from the owner's map of 19 November, mapversion 39)
    "15074": (3328, 1856, 648, 3968, 1872, 2784),       # the sky wall at the east road's end
    "14734": (-2624, 1920, 832, -2608, 2560, 2336),     # the sky wall at the west road's end
    "15630": (-2608, 1920, 832, -2440, 2560, 2336),     # the unseen wall before it
    "65929": (94, -2526, 648, 108, -2188, 944),         # the Combine wall's slab
    "51870": (78, -2526, 708, 94, -2357, 740),          # its two rails
    "62363": (78, -2357, 840, 94, -2188, 856),
    "15623": (66, -2639, 648, 198, -2075, 1280),        # the unseen wall round it
    "33530": (99, -2558, 764, 103, -2151, 1128),        # the black sheet in it
    "28290": (1216, 393, 239, 1536, 401, 448),          # the sewer wall
    "34874": (1216, -5184, 655, 1472, -2293, 656),      # the bare strip of road
}
# The sun's name, and the lights that get a twin: (the owner's lights' name, the twins' name, the twins' colour and
# brightness). A named light can be switched and faded while the map runs; a light's colour is fixed when the map is
# compiled, which is why a red room needs red lights of its own.
SUN_NAME = "lc_sun"
TWINS = [("evr_l", "lc_dream_red", "255 48 32 160")]
CAP = re.compile(r"gate's cap \(delete to join")
PLANE = re.compile(r'"plane" "\(([-\d.e]+) ([-\d.e]+) ([-\d.e]+)\) \(([-\d.e]+) ([-\d.e]+) ([-\d.e]+)\) \(([-\d.e]+) ([-\d.e]+) ([-\d.e]+)\)"')
KEY = re.compile(r'^"([^"]*)" "(.*)"$')


def read(path):
    with open(path, errors="surrogateescape", newline="") as f:
        text = f.read()
    eol = "\r\n" if "\r\n" in text[:4096] else "\n"
    return text.split(eol), eol


def top_blocks(lines):
    """Every block at the file's top level: (name, first line, last line), line numbers from 0."""
    out, depth, prev, start, name = [], 0, None, None, None
    for i, raw in enumerate(lines):
        l = raw.strip()
        if l == "{":
            if depth == 0:
                name, start = lines[prev].strip(), prev
            depth += 1
        elif l == "}":
            depth -= 1
            if depth == 0:
                out.append((name, start, i))
            if depth < 0:
                raise SystemExit("braces do not match at line %d" % (i + 1))
        elif l:
            prev = i
    if depth:
        raise SystemExit("braces do not match at the end of the file")
    return out


def children(lines, a, b):
    """The blocks directly inside the block that runs from line a to line b."""
    out, depth, prev, start, name = [], 0, None, None, None
    for i in range(a + 2, b):
        l = lines[i].strip()
        if l == "{":
            if depth == 0:
                name, start = lines[prev].strip(), prev
            depth += 1
        elif l == "}":
            depth -= 1
            if depth == 0:
                out.append((name, start, i))
        elif l:
            prev = i
    return out


def own_id(lines, a, b):
    """The id of the block from a to b (its own "id", not one of a block inside it)."""
    depth = 0
    for i in range(a + 1, b):
        l = lines[i].strip()
        if l == "{":
            depth += 1
        elif l == "}":
            depth -= 1
        elif depth == 1:
            m = KEY.match(l)
            if m and m.group(1) == "id":
                return m.group(2)
    return None


def box_of(lines, a, b):
    xs, ys, zs = [], [], []
    for i in range(a, b + 1):
        m = PLANE.search(lines[i])
        if m:
            p = [float(v) for v in m.groups()]
            xs += p[0::3]
            ys += p[1::3]
            zs += p[2::3]
    if not xs:
        return None
    return (min(xs), min(ys), min(zs), max(xs), max(ys), max(zs))


def touching(a, b):
    """Do two boxes meet face to face (or overlap)?"""
    if a is None or b is None:
        return False
    overlap = [min(a[k + 3], b[k + 3]) - max(a[k], b[k]) for k in range(3)]
    return sum(1 for o in overlap if o > 1) >= 2 and all(o >= -1 for o in overlap)


def highest_ids(lines):
    """The highest object id, face id and visgroup id in a file, and its path node numbers."""
    obj = side = vis = 0
    nodes, stack, prev = [], [], ""
    for raw in lines:
        l = raw.strip()
        if l == "{":
            stack.append(prev)
        elif l == "}":
            stack.pop()
        elif l:
            m = KEY.match(l)
            if m:
                k, v = m.group(1), m.group(2)
                if k == "id" and v.isdigit():
                    if stack and stack[-1] == "side":
                        side = max(side, int(v))
                    else:
                        obj = max(obj, int(v))
                elif k == "visgroupid" and v.isdigit():
                    vis = max(vis, int(v))
                elif k == "nodeid" and v.isdigit():
                    nodes.append(int(v))
            prev = l
    return obj, side, vis, nodes


class Piece:
    def __init__(self, path):
        self.path = path
        base = os.path.basename(path)
        m = re.match(r"lc_(.+?)\.vmf$", base)
        if not m:
            raise SystemExit("%s: a piece is a file named lc_NAME.vmf" % base)
        self.name = m.group(1)
        if self.name.endswith("_test"):
            raise SystemExit("%s is a test file (a sun, a spawn, walls that close it): never in the real map" % base)
        self.lines, _ = read(path)
        tops = top_blocks(self.lines)
        self.vis = {}                                   # id -> (name, colour)
        self.solids, self.ents = [], []                 # each: (first line, last line, visgroup ids, box)
        for name, a, b in tops:
            if name == "visgroups":
                for cn, ca, cb in children(self.lines, a, b):
                    kv = dict(KEY.match(self.lines[i].strip()).groups() for i in range(ca + 2, cb) if KEY.match(self.lines[i].strip()))
                    self.vis[kv["visgroupid"]] = (kv["name"], kv.get("color", "200 200 200"))
            elif name == "world":
                for cn, ca, cb in children(self.lines, a, b):
                    if cn != "solid":
                        raise SystemExit("%s: its world holds a '%s' block, which this tool does not carry" % (base, cn))
                    self.solids.append((ca, cb, self.groups(ca, cb), box_of(self.lines, ca, cb)))
            elif name == "entity":
                self.ents.append((a, b, self.groups(a, b), box_of(self.lines, a, b)))
        self.caps = {}                                  # visgroup id -> the box of what is in it
        for vid, (vname, _) in self.vis.items():
            if CAP.search(vname):
                boxes = [c[3] for c in self.solids + self.ents if vid in c[2] and c[3]]
                if boxes:
                    self.caps[vid] = (min(b[0] for b in boxes), min(b[1] for b in boxes), min(b[2] for b in boxes),
                                      max(b[3] for b in boxes), max(b[4] for b in boxes), max(b[5] for b in boxes))
        self.dropped = set()                            # the caps that meet another piece's

    def groups(self, a, b):
        out = set()
        for i in range(a, b + 1):
            m = KEY.match(self.lines[i].strip())
            if m and m.group(1) == "visgroupid":
                out.add(m.group(2))
        return out

    def renumbered(self, a, b, ids, vismap):
        """The block from a to b with new ids (ids: [next object id, next face id]) and its visgroups' new numbers."""
        out, stack, prev = [], [], ""
        for i in range(a, b + 1):
            raw = self.lines[i]
            l = raw.strip()
            if l == "{":
                stack.append(prev)
            elif l == "}":
                stack.pop()
            elif l:
                m = KEY.match(l)
                if m and m.group(1) == "id" and stack and stack[-1] in ("side", "solid", "entity", "group"):
                    which = 1 if stack[-1] == "side" else 0
                    raw = raw[:len(raw) - len(raw.lstrip())] + '"id" "%d"' % ids[which]
                    ids[which] += 1
                elif m and m.group(1) == "visgroupid":
                    raw = raw[:len(raw) - len(raw.lstrip())] + '"visgroupid" "%d"' % vismap[m.group(2)]
                prev = l
            out.append(raw)
        return out


def digest(chunk):
    return hashlib.md5("\n".join(chunk).encode("utf-8", "surrogateescape")).hexdigest()


def main():
    ap = argparse.ArgumentParser(description="Write one new VMF: the owner's map with the pieces in it. The owner's file is only read.")
    ap.add_argument("owner", help="the owner's VMF (read, never written)")
    ap.add_argument("pieces", nargs="+", help="the pieces: lc_canal.vmf lc_ring.vmf ... (never a _test file)")
    ap.add_argument("--out", required=True, help="the new VMF to write")
    ap.add_argument("--keep-caps", action="store_true", help="leave every gate's cap in (the pieces stay shut off from each other)")
    ap.add_argument("--plain", action="store_true", help="do not name the sun and do not add the dream room's red lights")
    args = ap.parse_args()
    if os.path.abspath(args.out) == os.path.abspath(args.owner):
        raise SystemExit("the new file must not be the owner's own")

    lines, eol = read(args.owner)
    tops = top_blocks(lines)
    names = [t[0] for t in tops]
    for need in ("visgroups", "world"):
        if names.count(need) != 1:
            raise SystemExit("the owner's file should have one '%s' block, it has %d" % (need, names.count(need)))
    obj, side, vis, nodes = highest_ids(lines)
    print("the owner's map: %d lines, %d entities, %d path nodes (highest %d); highest ids: object %d, face %d, visgroup %d" % (
        len(lines), names.count("entity"), len(nodes), max(nodes or [0]), obj, side, vis))

    pieces = [Piece(p) for p in args.pieces]
    seen = set()
    for p in pieces:
        if p.name not in REPLACES:
            raise SystemExit("%s: not a piece this tool knows what it replaces (add it to REPLACES)" % p.name)
        if p.name in seen:
            raise SystemExit("%s is given twice" % p.name)
        seen.add(p.name)

    # --- the owner's brushes the pieces replace: found, checked to be where they were, left out ---
    wanted = {}
    for p in pieces:
        for bid in REPLACES[p.name]:
            wanted[bid] = p.name
    world = next(t for t in tops if t[0] == "world")
    drop = []                                       # (first line, last line) of what is left out
    found = {}
    for cn, ca, cb in children(lines, world[1], world[2]):
        inner = [(cn, ca, cb)] if cn == "solid" else [(n, a, b) for n, a, b in children(lines, ca, cb) if n == "solid"] if cn == "hidden" else []
        for n, a, b in inner:
            bid = own_id(lines, a, b)
            if bid in wanted:
                found[bid] = ("the world", box_of(lines, a, b))
                drop.append((ca, cb) if cn == "hidden" else (a, b))
    emptied = 0
    for name, a, b in tops:
        if name != "entity":
            continue
        kids = [(n, ca, cb) for n, ca, cb in children(lines, a, b) if n == "solid"]
        if not kids:
            continue
        hit = [(ca, cb, own_id(lines, ca, cb)) for n, ca, cb in kids]
        hit = [h for h in hit if h[2] in wanted]
        if not hit:
            continue
        cls = next((KEY.match(lines[i].strip()).group(2) for i in range(a + 2, b) if KEY.match(lines[i].strip()) and KEY.match(lines[i].strip()).group(1) == "classname"), "?")
        for ca, cb, bid in hit:
            found[bid] = ("a %s" % cls, box_of(lines, ca, cb))
        if len(hit) == len(kids):
            drop.append((a, b))                     # nothing of it is left: the entity goes with its brushes
            emptied += 1
        else:
            drop += [(ca, cb) for ca, cb, _ in hit]
    stop = False
    for bid, piece in sorted(wanted.items(), key=lambda kv: int(kv[0])):
        if bid not in found:
            print("  STOP: brush %s (which %s replaces) is not in the owner's map" % (bid, piece))
            stop = True
            continue
        where, box = found[bid]
        was = BOXES.get(bid)
        got = tuple(int(round(v)) for v in box) if box else None
        if was and got and any(abs(got[k] - was[k]) > 1 for k in range(6)):
            print("  STOP: brush %s is not where it was (%s, was %s): the map has changed since %s was made" % (bid, got, was, piece))
            stop = True
        else:
            print("  left out: the owner's brush %s (in %s, %s), which %s stands in the place of" % (bid, where, "x %d..%d y %d..%d z %d..%d" % (got[0], got[3], got[1], got[4], got[2], got[5]), piece))
    if stop:
        raise SystemExit("nothing written")

    # --- the caps where two pieces meet ---
    if not args.keep_caps:
        caps = [(p, vid, box) for p in pieces for vid, box in p.caps.items()]
        for i, (p, vid, box) in enumerate(caps):
            for q, wid, other in caps[i + 1:]:
                if p is not q and touching(box, other):
                    p.dropped.add(vid)
                    q.dropped.add(wid)
                    print("  joined: %s to %s (their two caps at x %d..%d y %d..%d left out)" % (p.name, q.name, min(box[0], other[0]), max(box[3], other[3]), min(box[1], other[1]), max(box[4], other[4])))
        for p, vid, box in caps:
            if vid not in p.dropped:
                print("  a cap stays: '%s' (nothing is against it)" % p.vis[vid][0])

    # --- the gamemode's hooks into the owner's lights: the sun's name, the dream room's red twins ---
    add_after = {}                                  # line number in the owner's file -> a line to put after it
    twins = []                                      # (the keys and values of each light to copy)
    if not args.plain:
        for name, a, b in tops:
            if name != "entity":
                continue
            kv, at = {}, None
            depth = 0
            for i in range(a + 1, b):
                l = lines[i].strip()
                if l == "{":
                    depth += 1
                elif l == "}":
                    depth -= 1
                elif depth == 1:
                    m = KEY.match(l)
                    if m:
                        kv[m.group(1)] = m.group(2)
                        if m.group(1) == "classname":
                            at = i
            cls = kv.get("classname", "")
            if cls == "light_environment":
                if kv.get("targetname"):
                    print("  the sun already has a name: %s (left as it is)" % kv["targetname"])
                else:
                    add_after[at] = '\t"targetname" "%s"' % SUN_NAME
                    print("  the sun: the owner's light_environment (entity %s) is named %s: one line added to it" % (kv.get("id"), SUN_NAME))
            elif cls in ("light", "light_spot"):
                for theirs, ours, colour in TWINS:
                    if kv.get("targetname") == theirs:
                        twins.append((kv, ours, colour))
        for theirs, ours, colour in TWINS:
            n = sum(1 for t in twins if t[1] == ours)
            if n:
                print("  the dream room: beside each of the %d lights named %s, a red one named %s that starts dark" % (n, theirs, ours))

    # --- the pieces, renumbered ---
    ids = [obj + 1, side + 1]
    new_vis, new_solids, new_ents = [], [], []
    if twins:
        vis += 1
        new_vis += ["\tvisgroup", "\t{", '\t\t"name" "LC lights: the dream room\'s red set"', '\t\t"visgroupid" "%d"' % vis, '\t\t"color" "220 60 50"', "\t}"]
        for kv, ours, colour in twins:
            keys = dict(kv)
            keys.update({"targetname": ours, "_light": colour, "spawnflags": "1", "style": "0"})
            keys.pop("id", None)
            keys.pop("_lightHDR", None)
            new_ents += ["entity", "{", '\t"id" "%d"' % ids[0]] + ['\t"%s" "%s"' % (k, v) for k, v in keys.items()] + [
                "\teditor", "\t{", '\t\t"color" "220 30 220"', '\t\t"visgroupid" "%d"' % vis, '\t\t"visgroupshown" "1"', '\t\t"visgroupautoshown" "1"',
                '\t\t"logicalpos" "[0 0]"', "\t}", "}"]
            ids[0] += 1
    for p in pieces:
        vismap = {}
        for vid in sorted(p.vis, key=int):
            if vid in p.dropped:
                continue
            vis += 1
            vismap[vid] = vis
            vname, colour = p.vis[vid]
            colour = " ".join(str(min(255, max(0, int(float(c))))) for c in colour.split())
            new_vis += ["\tvisgroup", "\t{", '\t\t"name" "%s"' % vname, '\t\t"visgroupid" "%d"' % vis, '\t\t"color" "%s"' % colour, "\t}"]
        ns = ne = 0
        for a, b, groups, _ in p.solids:
            if groups & p.dropped:
                continue
            new_solids += p.renumbered(a, b, ids, vismap)
            ns += 1
        for a, b, groups, _ in p.ents:
            if groups & p.dropped:
                continue
            new_ents += p.renumbered(a, b, ids, vismap)
            ne += 1
        print("  in: %s, %d brushes of the world and %d entities, %d visgroups" % (p.name, ns, ne, len(vismap)))

    # --- the new file: the owner's lines in order, with the three places things go in ---
    skip = [False] * len(lines)
    for a, b in drop:
        for i in range(a, b + 1):
            skip[i] = True
    visgroups = next(t for t in tops if t[0] == "visgroups")
    after_ents = max([t[2] for t in tops if t[0] in ("entity", "hidden", "world")])
    out = []
    for i, raw in enumerate(lines):
        if i == visgroups[2]:
            out += new_vis
        if i == world[2]:
            out += new_solids
        if not skip[i]:
            out.append(raw)
            if i in add_after:
                out.append(add_after[i])
        if i == after_ents:
            out += new_ents
    with open(args.out, "w", errors="surrogateescape", newline="") as f:
        f.write(eol.join(out))

    # --- CHECKS: the new file read back ---
    merged, _ = read(args.out)
    problems = []
    mtops = top_blocks(merged)                      # (stops by itself if the braces do not match)
    seen_obj, seen_side, seen_nodes, stack, prev = {}, {}, {}, [], ""
    for raw in merged:
        l = raw.strip()
        if l == "{":
            stack.append(prev)
        elif l == "}":
            stack.pop()
        elif l:
            m = KEY.match(l)
            if m and m.group(2).isdigit():
                k, v = m.group(1), m.group(2)
                if k == "id" and stack and stack[-1] == "side":
                    seen_side[v] = seen_side.get(v, 0) + 1
                elif k == "id" and stack and stack[-1] in ("solid", "entity", "group"):
                    key = ("s" if stack[-1] == "solid" else "e" if stack[-1] == "entity" else "g") + v
                    seen_obj[key] = seen_obj.get(key, 0) + 1
                elif k == "nodeid":
                    seen_nodes[v] = seen_nodes.get(v, 0) + 1
            prev = l
    # (the owner's own file may already repeat an id; only what the merge added is held to it)
    def repeats(d):
        return sorted(k for k, n in d.items() if n > 1)
    base_obj, base_side, base_nodes = {}, {}, {}
    stack, prev = [], ""
    for raw in lines:
        l = raw.strip()
        if l == "{":
            stack.append(prev)
        elif l == "}":
            stack.pop()
        elif l:
            m = KEY.match(l)
            if m and m.group(2).isdigit():
                k, v = m.group(1), m.group(2)
                if k == "id" and stack and stack[-1] == "side":
                    base_side[v] = base_side.get(v, 0) + 1
                elif k == "id" and stack and stack[-1] in ("solid", "entity", "group"):
                    key = ("s" if stack[-1] == "solid" else "e" if stack[-1] == "entity" else "g") + v
                    base_obj[key] = base_obj.get(key, 0) + 1
                elif k == "nodeid":
                    base_nodes[v] = base_nodes.get(v, 0) + 1
            prev = l
    for what, now, was in (("brush or entity id", seen_obj, base_obj), ("face id", seen_side, base_side), ("path node number", seen_nodes, base_nodes)):
        new = [k for k in repeats(now) if k not in repeats(was)]
        if new:
            problems.append("%d %ss are now used twice (first: %s)" % (len(new), what, new[0]))
    # every block of the owner's that was not left out is in the new file, unchanged and in the same order
    def chunks(ls, tp):
        out = []
        for name, a, b in tp:
            if name == "world":
                for cn, ca, cb in children(ls, a, b):
                    out.append(("world/" + cn, digest(ls[ca:cb + 1])))
            else:
                out.append((name, digest(ls[a:b + 1])))
        return out
    kept_lines = []                                 # (the owner's file as it should now read: without what was left out, with the lines added)
    for i, raw in enumerate(lines):
        if not skip[i]:
            kept_lines.append(raw)
            if i in add_after:
                kept_lines.append(add_after[i])
    before = chunks(kept_lines, top_blocks(kept_lines))
    after = chunks(merged, mtops)
    # (in the same order: each of the owner's blocks is looked for after the one before it)
    missing, at = 0, 0
    for k in before:
        if k[0] == "visgroups":
            continue                                # (it has the pieces' visgroups added: checked below)
        while at < len(after) and after[at] != k:
            at += 1
        if at == len(after):
            missing += 1
            break
        at += 1
    if missing:
        problems.append("a block of the owner's is not in the new file as it was, or not in its place")
    ours = [raw for raw in merged[mtops[names.index("visgroups")][1]:mtops[names.index("visgroups")][2] + 1]]
    theirs = lines[visgroups[1]:visgroups[2]]
    if ours[:len(theirs)] != theirs:
        problems.append("the owner's visgroups are not as they were")
    # names used on both sides
    def targetnames(ls):
        out = set()
        for raw in ls:
            m = KEY.match(raw.strip())
            if m and m.group(1) == "targetname" and m.group(2):
                out.add(m.group(2))
        return out
    both = targetnames(lines) & targetnames(new_ents)
    if both:
        problems.append("names used by the owner's map and by a piece: " + ", ".join(sorted(both)[:8]))
    n_world = sum(1 for k in after if k[0] == "world/solid")
    n_ents = sum(1 for k in after if k[0] == "entity")
    print("written: %s (%d lines; %d brushes in the world, %d entities, %d path nodes, %d displacements)" % (
        args.out, len(merged), n_world, n_ents, len(seen_nodes), sum(1 for raw in merged if raw.strip() == "dispinfo")))
    print("  left out of the owner's: %d brushes%s; everything else of theirs: %d blocks, each one unchanged%s" % (
        len(wanted), " (%d brush entities went with their last brush)" % emptied if emptied else "", len(before),
        " but for %d line added (the sun's name)" % len(add_after) if add_after else ""))
    if problems:
        for p in problems:
            print("  PROBLEM: " + p)
        sys.exit(1)
    print("  CHECKS passed: braces, ids, path node numbers, the owner's blocks unchanged, no shared names")


if __name__ == "__main__":
    main()
