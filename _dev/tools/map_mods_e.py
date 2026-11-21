#!/usr/bin/env python3
"""
Living City: the wide canal (map_modules.py picks these up by itself)

The owner, 21 November, of Valve's canals against ours: Valve's city canal is 512 wide, as ours, and its airboat
canals 1024. So the chain can now widen: "widen" takes the canal from 512 to 1024 in two steps, "narrow" brings it
back, and between them run the wide modules ("wide", "widetee"), whose ends are 1024 wide. A layout says when it
widens (map_layouts/wide.txt); map_build.py fails a chain whose modules' widths do not meet, and a turn inside the
wide canal is 1024 square. "basin" is the same widening and narrowing in one module, with 512 at both ends, so it
goes anywhere a plain stretch does.

The wide canal's walls stand upright, as Valve's do (the 45 degree banks are kept on the city canal, which the owner
asked for): m.upright keeps the bank off and the rest of the dressing on (lip, ribs, outfalls flush in the wall, the
caged lamps). Its floor sags about 42 at its middle (the dish, map_modules.dish_plan). Where it widens, the banks wrap
round the steps and stop against the wide canal's walls.
"""

from map_build import CELL, GATE_HIGH, MAT, gate_cap
from map_modules import CANAL_W, F, SCAPES, WIDE_W, CANAL_JUNK, canal_grime, walk_ledge

HALF, WHALF = CANAL_W // 2, WIDE_W // 2


def wide_walls(m, u1, u2):
    """The wide canal's walls upright from u1 to u2 (the rectangles reach 8 past the walls' lines, not past the ends)."""
    m.upright(u1, -WHALF - 64, u2, -WHALF + 8)
    m.upright(u1, WHALF - 8, u2, WHALF + 64)


def odds(m, u1, u2, v, seed):
    """What the wide canal's floor collects: odds and ends from CANAL_JUNK, puddles and trash, the same every build."""
    m.scatter(u1 + 64, -v, u2 - 64, v, max(1, (u2 - u1) // 384), seed, kinds=CANAL_JUNK)
    canal_grime(m, u1, u2, seed + 1)


def seed_of(m, k):
    x, y = m.fr.pt(0, 0)
    return k + (x * 7 + y * 13) % 997


def m_widen(m, opt):
    """The canal widens from 512 to 1024 (Valve's airboat canals' width): 256 of the city canal, then its walls step out
    128 each side, and again 256 on, so it is 1024 wide for its last 256. The banks wrap round both steps (a slope up
    each step's face, a quarter pyramid on each corner) and stop against the wide canal's upright walls. The next
    module must be a wide one ("wide", "widetee", a turn) or "narrow"."""
    m.open(0, -HALF, 256, HALF)
    m.open(256, -HALF - 128, 512, HALF + 128)
    m.open(512, -WHALF, 768, WHALF)
    wide_walls(m, 520, 832)       # (from 8 past the second step: its slope keeps its last square)
    odds(m, 512, 768, 300, seed_of(m, 4100))
    m.soundscape(SCAPES["courtyard"], 512, 0, F, radius=900)


def m_narrow(m, opt):
    """The wide canal narrows back to 512: the mirror of "widen" (256 of the wide canal, two steps in, 256 of the city
    canal), the banks starting again round the steps."""
    m.open(0, -WHALF, 256, WHALF)
    m.open(256, -HALF - 128, 512, HALF + 128)
    m.open(512, -HALF, 768, HALF)
    wide_walls(m, -64, 248)
    odds(m, 0, 256, 300, seed_of(m, 4200))
    m.soundscape(SCAPES["courtyard"], 256, 0, F, radius=900)


def m_wide(m, opt):
    """The wide canal: 1024 between upright walls, the floor sagging about 42 to its middle, any length ("wide 2048").
    From 2048 long a walk along its left wall (walk_ledge: 102 wide, 320 up, stairs at each end; "flip" puts it on the
    right, "noledge" leaves it out). "bridge": a street carried over its middle; "pipes": a pair of pipes across it.
    Odds and ends lying in it, puddles and trash, the quiet courtyard's soundscape; the lamps and outfalls come with
    its walls (dress_canal_walls)."""
    L = m.fr.length
    m.open(0, -WHALF, L, WHALF)
    wide_walls(m, -64, L + 64)
    cut = (L // 2 - 192, L // 2 + 192) if "bridge" in opt or "pipes" in opt else None
    if L >= 2048 and "noledge" not in opt:
        spans = [(256, L - 256)] if not cut else [(256, cut[0] // 64 * 64), (-(-cut[1] // 64) * 64, L - 256)]
        a, b = max(spans, key=lambda p: p[1] - p[0])
        if b - a >= 640:
            walk_ledge(m, a, b, 1, wide=True, stairs=2 if b - a >= 1152 else 1)
    if "bridge" in opt:
        m.bridge(L // 2 - 128, L // 2 + 128, -WHALF, WHALF)
    if "pipes" in opt:
        (x1, y1), (x2, y2) = m.fr.pt(L // 2, -WHALF), m.fr.pt(L // 2, WHALF)
        m.b.pipes.append(("x", x1, min(y1, y2), max(y1, y2)) if m.fr.ax("u") == "x" else ("y", y1, min(x1, x2), max(x1, x2)))
    if "bare" not in opt:
        odds(m, 0, L, 360, seed_of(m, 4300))
    m.soundscape(SCAPES["courtyard"], L // 2, 0, F, radius=max(900, L // 2))


def m_widetee(m, opt):
    """A way off the wide canal's left wall: the same standard gate as "tee" (512 wide, 256 high), capped until another
    piece or another layout's start is joined to it, a number painted beside it. The canal is 1024 wide at both ends."""
    b = m.b
    m.open(0, -WHALF, 512, WHALF)
    wide_walls(m, -64, 576)
    m.low(0, WHALF, 512, WHALF + 256, F + GATE_HIGH)
    gate_cap(b.vmf, m.fr.box(0, WHALF + 192, F, 512, WHALF + 256, F + GATE_HIGH), m.fr.box(0, WHALF + 168, F, 512, WHALF + 176, F + GATE_HIGH), m.fr.ax("u"),
             "%s: %s side gate's cap (delete to join)" % (b.vis, m.tag))
    m.portal(0, WHALF + 126, F, 512, WHALF + 128, F + GATE_HIGH)
    b.plan.keep_out.append(m.fr.rect(-64, WHALF + 256, 576, WHALF + 320))
    m.blocked(0, WHALF + 128, 512, WHALF + 256)
    m.side(0, WHALF, 512, WHALF + 256)
    x, y = m.fr.pt(0, 0)
    canal_grime(m, 0, 512, 3100 + (x * 7 + y * 13) % 997)
    m.grime("number", 512, WHALF + 64, F + 180, x + y)
    m.soundscape(SCAPES["courtyard"], 256, 0, F, radius=900)
    dx, dy = m.fr.way(90)
    b.notes.append("%s: its side gate is at (%d %d), heading %s: a layout may start there" % ((m.tag,) + m.fr.pt(256, WHALF + 256) + ({(1, 0): "E", (0, 1): "N", (-1, 0): "W", (0, -1): "S"}[(dx, dy)],)))


def m_basin(m, opt):
    """The canal widens into a basin 1024 wide and narrows again within one module, so it starts and ends on the plain
    512 section and goes anywhere a plain stretch does ("basin 2560": that long, 2048 at least). Its steps are those of
    "widen" and "narrow" (the banks wrap round them); between them the wide canal's upright walls and deeper dish, a
    walk along the left wall where the basin is 2560 or longer ("flip": the right; "noledge": none), odds and ends."""
    L = m.fr.length
    if L < 2048:
        m.open(0, -HALF, L, HALF)
        m.b.problems.append("%s: a basin is 2048 long at least" % m.tag)
        return
    m.open(0, -HALF, 256, HALF)
    m.open(256, -HALF - 128, 512, HALF + 128)
    m.open(512, -WHALF, L - 512, WHALF)
    m.open(L - 512, -HALF - 128, L - 256, HALF + 128)
    m.open(L - 256, -HALF, L, HALF)
    wide_walls(m, 520, L - 520)
    if L >= 2560 and "noledge" not in opt:
        walk_ledge(m, 768, L - 768, 1, wide=True, stairs=2 if L - 1536 >= 1152 else 1)
    odds(m, 512, L - 512, 300, seed_of(m, 4400))
    m.soundscape(SCAPES["courtyard"], L // 2, 0, F, radius=max(900, L // 2))
    m.view(600, -300, F, 20, 2, "the basin")


MODULES = {
    "widen": (768, m_widen, "the canal widens from 512 to 1024 in two steps (its next module must be a wide one)", {"width": (CANAL_W, WIDE_W)}),
    "narrow": (768, m_narrow, "the wide canal narrows back to 512 in two steps", {"width": (WIDE_W, CANAL_W)}),
    "wide": (1024, m_wide, "the wide canal: 1024 between upright walls, any length (\"wide 2048\"), a walk along a wall from 2048", {"width": (WIDE_W, WIDE_W), "stretch": True}),
    "widetee": (512, m_widetee, "a standard gate in the wide canal's left wall, for another piece or layout to join", {"width": (WIDE_W, WIDE_W)}),
    "basin": (2048, m_basin, "the canal widens into a 1024 basin and narrows again (512 at both ends; \"basin 2560\")", {"stretch": True}),
}
