#!/usr/bin/env python3
"""
Living City: canal modules (run them through map_build.py)

The owner, 19 November: "Can you start building them? They should be modular so we can move them
and their order or position easily."

A module is a stretch of canal with one thing in it (a storm drain, a shantytown, a cistern ...).
Every module starts and ends on the same cross-section as every canal piece: 512 wide, floor z 400.
So any module follows any other, in any order, facing any of the four ways.

    python3 map_build.py module --name cistern           lc_mod_cistern.vmf: one module by itself, a gate at each end
    python3 map_build.py module --name cistern --test    ...with a spawn point and a sun, to compile and walk alone
    python3 map_build.py chain --layout map_layouts/south.txt     lc_south.vmf: the modules of a layout, joined in its order
    python3 map_build.py chain --layout map_layouts/south.txt --preview south.png     ...and a picture from above

A layout is a short text file (map_layouts/south.txt): where the chain starts, which way it heads,
then one module on each line. To move a module, move its line; to move the whole chain, change
"start"; to put a module's side room on the other side of the canal, add "flip".

A module is written in its own coordinates: u along the canal from its entry (0) to its exit
(its length), v across it (the canal is v -256..256; +v is the LEFT bank as you walk along u).
A Frame turns those into the map's.
"""

import math
import random

from map_build import CELL, GATE_HIGH, MAT, Plan, Vmf, check, fence, gate_cap, octagon, prism, test_extras
from map_forest import noise
from map_ring import BANK, Channel

F, TRIM = 400, 656        # the canals' floor and the trim line on their walls: the same as the first canal and the ring
BASE = 224                # the bottom of everything (the storm drain goes down to the city's sewers, feet at z 288)
SEWER = 288
HEADINGS = {"E": 0, "N": 1, "W": 2, "S": 3}
MM = {
    "wood": "wood/woodfloor007a",          # (these four are in the owner's own map: Ravenholm's recipe was read from it)
    "tin": "metal/metalroof004a",
    "steel": "metal/metalhull003a",
    "beam_wood": "wood/woodbeam001a",
    "water": "nature/water_canals_water_clear",   # hl2 (the bunker forest's pond)
    "sludge": "nature/toxicslime002a",            # hl2: the canals' toxic slime. NOT checked against a file list
}


class Frame:
    """Where a module sits: its entry's middle (x, y), the way it heads (rot: 0 east, 1 north, 2 west, 3 south) and its
    length. flip: built from its far end backwards, which puts its left bank on the right."""

    def __init__(self, x, y, rot, length, flip=False):
        self.x, self.y, self.rot, self.length, self.flip = x, y, rot % 4, length, flip

    def pt(self, u, v):
        if self.flip:
            u, v = self.length - u, -v
        r = self.rot
        if r == 0:
            return (self.x + u, self.y + v)
        if r == 1:
            return (self.x - v, self.y + u)
        if r == 2:
            return (self.x - u, self.y - v)
        return (self.x + v, self.y - u)

    def rect(self, u1, v1, u2, v2):
        (a, b), (c, d) = self.pt(u1, v1), self.pt(u2, v2)
        return (min(a, c), min(b, d), max(a, c), max(b, d))

    def box(self, u1, v1, z1, u2, v2, z2):
        r = self.rect(u1, v1, u2, v2)
        return (r[0], r[1], min(z1, z2), r[2], r[3], max(z1, z2))

    def ax(self, a):
        """The map's axis ("x" or "y") that the module's "u" or "v" runs along."""
        return ("x" if a == "u" else "y") if self.rot % 2 == 0 else ("y" if a == "u" else "x")

    def yaw(self, a):
        return (a + 90 * self.rot + (180 if self.flip else 0)) % 360

    def faces(self, faces):
        return [([self.pt(p[0], p[1]) + (p[2],) for p in verts], mat) for verts, mat in faces]


class Build:
    """One file being made: its plan, and what the modules leave for the dressing and the checks."""

    def __init__(self, name, rim, first_node):
        self.name, self.rim, self.sky = name, rim, rim + 384
        self.vmf = Vmf()
        self.vis = "LC %s" % name
        self.plan = Plan((0, 0), [(BASE, rim, MAT["canal_wall"]), (rim, self.sky + 16, MAT["sky"])], sky=self.sky, vis=self.vis + ": walls and floors")
        self.taken, self.blocked, self.no_bank, self.no_mud, self.lanes = [], [], [], [], []
        self.after, self.bumps, self.notes, self.names, self.problems = [], [], [], [], []
        self.owner = {}       # square -> the module that painted it
        self.labels = []      # (x, y, text) for the picture
        self.node_id = first_node
        self.first_node = first_node

    def node(self, x, y, z):
        self.vmf.point("info_node", (x, y, z + 40), {"nodeid": self.node_id}, self.vis + ": path nodes")
        self.node_id += 1


class Mod:
    """One module being built: everything in the module's own coordinates."""

    def __init__(self, b, fr, tag):
        self.b, self.fr, self.tag = b, fr, tag
        self.dv, self.pv, self.lv = b.vis + ": details", b.vis + ": props", b.vis + ": lights"

    # --- the squares ---
    def paint(self, u1, v1, u2, v2, spec):
        r = self.fr.rect(u1, v1, u2, v2)
        for i in range(r[0] // CELL, r[2] // CELL):
            for j in range(r[1] // CELL, r[3] // CELL):
                was = self.b.owner.get((i, j))
                if was and was != self.tag and ("clash", was, self.tag) not in self.b.names:
                    self.b.names.append(("clash", was, self.tag))
                    self.b.problems.append("%s runs into %s near (%d %d): move one of them in the layout" % (self.tag, was, i * CELL, j * CELL))
                self.b.owner[(i, j)] = self.tag
        self.b.plan.paint(r, spec)

    def open(self, u1, v1, u2, v2, floor=F, mat=None):
        self.paint(u1, v1, u2, v2, ("open", floor, mat or MAT["canal_floor"]))

    def low(self, u1, v1, u2, v2, ceil, floor=F, mat=None):
        self.paint(u1, v1, u2, v2, ("low", floor, mat or MAT["canal_floor"], ceil))

    def side(self, u1, v1, u2, v2):
        """A side room: no canal mud in it."""
        self.b.no_mud.append(self.fr.rect(u1, v1, u2, v2))

    def blocked(self, u1, v1, u2, v2):
        self.b.blocked.append(self.fr.rect(u1, v1, u2, v2))

    def no_bank(self, u1, v1, u2, v2):
        self.b.no_bank.append(self.fr.rect(u1, v1, u2, v2))

    def taken(self, *box):
        self.b.taken.append(self.fr.box(*box))

    def lane(self, u, v, z=F):
        self.b.lanes.append(self.fr.pt(u, v) + (z,))

    # --- brushes ---
    def det(self, boxes, mat, top=None, vis=None, faces=None):
        self.b.vmf.detail([self.fr.box(*x) for x in boxes], mat, vis=vis or self.dv, top=top, faces=faces)

    def shapes(self, shapes, vis=None):
        self.b.vmf.detail_shapes([self.fr.faces(s) for s in shapes], vis or self.dv)

    def world(self, box, mat, top=None, vis=None, seals=True):
        self.b.vmf.world_box(self.fr.box(*box), mat, top=top or mat, bottom=mat, vis=vis or self.b.vis + ": walls and floors", seals=seals)

    def portal(self, *box):
        self.b.vmf.areaportal(self.fr.box(*box), self.b.vis + ": areaportals")

    def ent(self, cls, keys, boxes, mat, vis=None):
        self.b.vmf.brush_entity(cls, keys, [self.fr.box(*x) for x in boxes], mat, vis or self.dv)
        if keys.get("targetname"):
            self.b.names.append((keys["targetname"], cls, self.tag))

    def bars(self, slab, along, vis=None):
        """Bars nobody fits between: 8 thick, 24 apart, across the thin slab (along: "u" or "v", the way the row runs)."""
        from map_build import barred
        barred(self.b.vmf, self.fr.box(*slab), self.fr.ax(along), vis or self.dv)

    def steps(self, start, lo, hi, z_low, z_high, axis, sign):
        """Steps of 8 up and 12 along, rising from z_low at `start` in the way of sign along axis ("u" or "v"); lo..hi across."""
        out = []
        for i in range((z_high - z_low) // 8):
            a, c = start + sign * 12 * i, start + sign * 12 * (i + 1)
            out.append((a, lo, z_low, c, hi, z_low + 8 * (i + 1)) if axis == "u" else (lo, a, z_low, hi, c, z_low + 8 * (i + 1)))
        self.det(out, MAT["canal_wall"], top=MAT["stairs"])
        return 12 * len(out)

    # --- things ---
    def point(self, cls, u, v, z, keys=None, vis=None):
        self.b.vmf.point(cls, self.fr.pt(u, v) + (z,), keys or {}, vis or self.dv)
        if keys and keys.get("targetname"):
            self.b.names.append((keys["targetname"], cls, self.tag))

    def static(self, model, u, v, yaw=0, z=F):
        self.point("prop_static", u, v, z, {"model": model, "angles": "0 %d 0" % self.fr.yaw(yaw), "skin": "0", "solid": "6", "disableshadows": "0",
                                            "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, self.pv)

    def loose(self, model, u, v, yaw=0, z=F):
        self.point("prop_physics", u, v, z + 24, {"model": model, "angles": "0 %d 0" % self.fr.yaw(yaw), "skin": "0", "spawnflags": "0"}, self.pv)

    def body(self, model, u, v, yaw=0, z=F):
        self.point("prop_ragdoll", u, v, z + 16, {"model": model, "angles": "0 %d 0" % self.fr.yaw(yaw), "spawnflags": "4"}, self.b.vis + ": bodies")

    def light(self, u, v, z, colour):
        self.point("light", u, v, z, {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.lv)

    def door(self, name, boxes, mat, movedir, speed=40, lip=8, vis=None):
        """A brush that slides when the game tells it to (Open, Close): never by a player's Use."""
        self.ent("func_door", {"targetname": name, "movedir": movedir, "speed": str(speed), "lip": str(lip), "wait": "-1", "spawnflags": "32", "spawnpos": "0",
                               "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0", "noise1": "MetalGrate.ScrapeSmooth",
                               "noise2": "MetalGrate.ImpactSoft", "locked_sentence": "0", "unlocked_sentence": "0", "renderamt": "255",
                               "rendercolor": "255 255 255", "renderfx": "0", "rendermode": "0", "disableshadows": "1"}, boxes, mat, vis)

    def hut(self, u1, v1, u2, v2, z, mat, high=112, front="lo", open_front=False, door=56):
        """A shack: walls 8 thick, a tin roof, a way in on its front (the low-v or the high-v side)."""
        walls = [(u1, v1, z, u1 + 8, v2, z + high), (u2 - 8, v1, z, u2, v2, z + high)]
        fv, bv = ((v1, v1 + 8), (v2 - 8, v2)) if front == "lo" else ((v2 - 8, v2), (v1, v1 + 8))
        walls.append((u1 + 8, bv[0], z, u2 - 8, bv[1], z + high))
        if not open_front:
            mid = (u1 + u2) // 2
            walls += [(u1 + 8, fv[0], z, mid - door // 2, fv[1], z + high), (mid + door // 2, fv[0], z, u2 - 8, fv[1], z + high),
                      (mid - door // 2, fv[0], z + 88, mid + door // 2, fv[1], z + high)]
        self.det(walls, mat)
        over = (v1 - 24, v2) if front == "lo" else (v1, v2 + 24)
        self.det([(u1 - 12, over[0], z + high, u2 + 12, over[1], z + high + 6)], MM["tin"])
        self.blocked(u1 - 16, v1 - 16, u2 + 16, v2 + 16)
        self.taken(u1 - 12, v1 - 24, z, u2 + 12, v2 + 24, z + high + 6)

    def bridge(self, a, b, lo, hi):
        """A street carried over the canal at the trim's height (the ring's road_bridge, in the module's own coordinates)."""
        self.det([(a, lo, TRIM - 40, b, hi, TRIM + 8)], MAT["beam"], top=MAT["quay_floor"])
        self.det([(a, lo, TRIM + 8, a + 16, hi, TRIM + 56), (b - 16, lo, TRIM + 8, b, hi, TRIM + 56),
                  (a + 48, lo + 112, F, b - 48, lo + 144, TRIM - 72), (a + 48, hi - 144, F, b - 48, hi - 112, TRIM - 72)], MAT["canal_wall"])
        self.det([(u, lo, TRIM - 72, u + 24, hi, TRIM - 40) for u in range(a + 40, b - 40, 96)], MAT["bars"])
        self.taken(a, lo, F, b, hi, TRIM + 56)
        self.blocked(a + 32, lo + 96, b - 32, lo + 160)
        self.blocked(a + 32, hi - 160, b - 32, hi - 96)


# ---------------------------------------------------------------------------
# The modules. Each paints its squares and puts its own things in; the banks, mud, trim, fence and path
# nodes come afterwards for the whole chain at once.
# ---------------------------------------------------------------------------

def m_straight(m, opt):
    """Plain canal. "straight 1536": that long. "straight 1024 bridge": with a street carried over its middle."""
    L = m.fr.length
    m.open(0, -256, L, 256)
    if "bridge" in opt:
        m.bridge(L // 2 - 128, L // 2 + 128, -256, 256)


def m_corner(m, opt):
    m.open(0, -256, 512, 256)


def m_gate(m, opt):
    """The culvert a chain ends in: the same gate as every piece's (512 wide, 256 high), capped until something is joined."""
    b = m.b
    m.low(0, -256, 256, 256, F + GATE_HIGH)
    gate_cap(b.vmf, m.fr.box(0, -256, F, 64, 256, F + GATE_HIGH), m.fr.box(80, -256, F, 88, 256, F + GATE_HIGH), m.fr.ax("v"),
             "%s: %s gate's cap (delete to join)" % (b.vis, opt[0] if opt else "a"))
    m.portal(128, -256, F, 130, 256, F + GATE_HIGH)
    b.plan.keep_out.append(m.fr.rect(-64, -448, 0, 448))
    m.blocked(0, -256, 128, 256)


def m_drain(m, opt):
    """1. The storm drain junction: a way from the canal down into the city's sewers. A drain mouth in the left wall, a
    junction chamber, steps down to the sewers' height, a grate the game can lift (lc_drain_grate), and a cap to delete
    where the owner joins it to a sewer of theirs."""
    m.open(0, -256, 1024, 256)
    m.low(384, 256, 640, 768, F + 192)                       # the mouth and its pipe
    m.low(256, 768, 768, 1280, F + 256)                      # the junction chamber
    m.low(384, 1280, 640, 1664, SEWER + 240, floor=SEWER)    # down to the sewers
    m.side(256, 256, 768, 1664)
    m.portal(384, 318, F, 640, 320, F + 192)
    run = m.steps(1280 + 12 * 13, 384, 640, SEWER, F - 8, "v", -1)   # 13 steps, tops z 392 down to 296
    m.blocked(384, 1280, 640, 1280 + run + 16)
    m.lane(512, 1264, F)
    m.lane(512, 1280 + run + 48, SEWER)
    # the grate, shut: the game lifts it (Open) or drops it (Close)
    from map_build import bar_row
    grate = [m.fr.box(384, 1544, SEWER, 640, 1552, SEWER + 240)]
    rows = bar_row(grate[0], m.fr.ax("u"))
    m.b.vmf.brush_entity("func_door", {"targetname": "lc_drain_grate", "movedir": "-90 0 0", "speed": "30", "lip": "24", "wait": "-1", "spawnflags": "32",
                                       "spawnpos": "0", "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0",
                                       "noise1": "MetalGrate.ScrapeSmooth", "noise2": "MetalGrate.ImpactSoft", "renderamt": "255", "rendercolor": "255 255 255",
                                       "renderfx": "0", "rendermode": "0", "disableshadows": "1"}, rows, MAT["bars"], m.dv)
    m.b.names.append(("lc_drain_grate", "func_door", m.tag))
    m.world((384, 1600, SEWER, 640, 1664, SEWER + 240), MAT["black"], vis="%s: the drain's sewer end (delete to join a sewer)" % m.b.vis)
    m.b.plan.keep_out.append(m.fr.rect(320, 1664, 704, 1728))
    m.blocked(384, 1536, 640, 1664)
    m.light(512, 1024, F + 200, "190 210 170 60")
    m.static("models/props_junk/wood_pallet001a.mdl", 330, 850, 20)
    m.static("models/props_c17/oildrum001.mdl", 700, 1200, 0)
    m.loose("models/props_junk/wood_crate001a.mdl", 690, 860, 30)
    m.b.notes.append("%s: the sewer end is at %s, floor z %d, 256 wide and 240 high: move or stretch it to a sewer of the map's, then delete its cap" % (
        m.tag, "(%d %d)" % m.fr.pt(512, 1664), SEWER))


def m_overflow(m, opt):
    """2. The overflow toward Ravenholm: a spillway in the left wall behind a steel sluice plate (lc_overflow_sluice,
    shut; the game lifts it), and a channel on to a cap. "overflow 1280": how far the channel reaches from the canal's
    middle (default 1024)."""
    reach = int(opt[0]) if opt and opt[0].isdigit() else 1024
    m.open(0, -256, 1024, 256)
    m.low(320, 256, 704, 640, F + 192)
    m.low(384, 640, 640, reach, F + 192)
    m.side(320, 256, 704, reach)
    m.det([(320, 256, F, 704, 272, F + 16)], MAT["beam"])                    # the weir's sill
    m.door("lc_overflow_sluice", [(320, 288, F + 16, 704, 304, F + 192)], MM["steel"], "-90 0 0", speed=24, lip=16)
    m.portal(320, 295, F, 704, 297, F + 192)
    m.det([(304, 248, F, 320, 256, F + 224), (704, 248, F, 720, 256, F + 224), (304, 248, F + 208, 720, 256, F + 224)], MM["steel"])   # its frame
    m.taken(304, 240, F, 720, 256, F + 224)
    m.world((384, reach - 64, F, 640, reach, F + 192), MAT["black"], vis="%s: the overflow's far end (delete to join Ravenholm)" % m.b.vis)
    m.b.plan.keep_out.append(m.fr.rect(320, reach, 704, reach + 64))
    m.blocked(384, reach - 128, 640, reach)
    m.blocked(320, 256, 704, 320)
    m.static("models/props_debris/concrete_chunk01a.mdl", 420, 150, 40)
    m.static("models/props_debris/broken_pile001a.mdl", 600, 170, 200)
    m.body("models/humans/charple02.mdl", 520, 420, 70)
    m.light(512, 520, F + 150, "200 120 90 40")
    m.b.notes.append("%s: the overflow's far end is at (%d %d), floor z %d, 256 wide and 192 high" % ((m.tag,) + m.fr.pt(512, reach) + (F,)))


def m_shanty(m, opt):
    """4. The shantytown under a street bridge: the canal widens into a basin on its left; three shacks along the
    basin's back wall (a card room, a trader's stall with a counter, a bunk room) and the street's shelter between."""
    m.open(0, -256, 1536, 256)
    m.open(256, 256, 1280, 640)
    m.no_bank(256, 400, 1280, 648)
    m.bridge(640, 896, -256, 640)
    wood, tin = MM["wood"], MM["tin"]
    m.hut(272, 432, 520, 632, F, wood)                                   # the card room
    m.static("models/props_c17/furnituretable002a.mdl", 396, 540, 0)
    m.static("models/props_c17/furniturechair001a.mdl", 340, 540, 0)
    m.static("models/props_c17/furniturechair001a.mdl", 452, 540, 180)
    m.light(396, 540, F + 90, "255 190 110 50")
    m.hut(912, 456, 1088, 632, F, tin, open_front=True)                  # the trader's stall
    m.det([(920, 456, F, 1080, 480, F + 40)], MM["beam_wood"])
    m.static("models/props_c17/shelfunit01a.mdl", 1000, 610, 270)
    m.static("models/props_junk/wood_crate001a.mdl", 950, 560, 15)
    m.light(1000, 540, F + 90, "255 190 110 40")
    m.hut(1104, 424, 1272, 632, F, wood)                                 # the bunk room
    m.loose("models/props_c17/furnituremattress001a.mdl", 1150, 560, 90)
    m.loose("models/props_c17/furnituremattress001a.mdl", 1226, 560, 90)
    m.static("models/props_c17/lockers001a.mdl", 1188, 616, 270)
    # under the street: somewhere to sit round a fire drum, somewhere to cook
    m.static("models/props_c17/oildrum001.mdl", 768, 380, 0)
    m.light(768, 380, F + 70, "255 150 70 120")
    m.static("models/props_c17/furniturecouch001a.mdl", 700, 590, 270)
    m.static("models/props_c17/furniturestove001a.mdl", 850, 600, 270)
    m.static("models/props_c17/furnituretable001a.mdl", 780, 470, 20)
    m.loose("models/props_junk/wood_pallet001a.mdl", 600, 330, 30)
    m.static("models/props_junk/wood_crate002a.mdl", 560, 600, 0)
    m.blocked(660, 540, 890, 640)
    for u, v in ((396, 380), (600, 420), (768, 300), (1000, 400), (1188, 380)):
        m.lane(u, v)
    m.b.notes.append("%s: room for the card table in the card room at (%d %d), for the fund's screen in the stall at (%d %d), for the soup under the street at (%d %d): place them with the editor" % (
        (m.tag,) + m.fr.pt(396, 540) + m.fr.pt(1000, 560) + m.fr.pt(820, 480)))


def m_vort(m, opt):
    """6. The vortigaunt culvert: a low side drain in the left wall that turns twice (nobody in the canal can see or shoot into its end) and
    ends in a small dead-end chamber with a fire and a cooking pot."""
    m.open(0, -256, 1024, 256)
    m.low(384, 256, 576, 896, F + 144)
    m.low(576, 704, 896, 896, F + 144)
    m.low(704, 896, 1024, 1280, F + 208)
    m.side(384, 256, 1024, 1280)
    m.portal(384, 318, F, 576, 320, F + 144)
    m.point("env_fire", 864, 1088, F + 4, {"health": "30", "firesize": "36", "fireattack": "4", "firetype": "0", "spawnflags": "7", "ignitionpoint": "32",
                                           "damagescale": "0.2"})
    m.light(864, 1088, F + 60, "255 140 60 140")
    m.det([(840, 1064, F, 888, 1112, F + 4)], MAT["beam"])
    m.loose("models/props_c17/metalpot001a.mdl", 908, 1100, 0)
    m.loose("models/props_c17/furnituremattress001a.mdl", 964, 1200, 0)
    m.static("models/props_junk/wood_crate001a.mdl", 752, 1230, 20)
    m.static("models/props_junk/wood_pallet001a.mdl", 760, 960, 70)
    m.static("models/props_c17/oildrum001.mdl", 984, 940, 0)
    m.blocked(816, 1040, 912, 1136)
    m.lane(480, 800)
    m.lane(800, 800)


def m_relay(m, opt):
    """7. Cubbage's relay shack: a concrete pier against the right wall (the banks round it are its ramps), a tin hut
    with the set (lc_relay_radio) on a bench, and a lattice mast that stands above the canal's walls."""
    b = m.b
    top = F + 128
    m.open(0, -256, 768, 256)
    m.open(256, -256, 640, -64, floor=top, mat=MAT["quay_floor"])
    m.side(256, -256, 640, -64)
    m.hut(280, -248, 464, -96, top, MM["tin"], high=104, front="hi")
    m.det([(288, -240, top, 328, -200, top + 34)], MM["beam_wood"])                       # the bench the set stands on
    m.point("prop_dynamic", 308, -220, top + 34, {"targetname": "lc_relay_radio", "model": "models/props_lab/citizenradio.mdl", "angles": "0 %d 0" % m.fr.yaw(90),
                                                  "solid": "6", "skin": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1",
                                                  "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"}, m.pv)
    m.static("models/props_c17/furniturechair001a.mdl", 360, -200, 180, z=top)
    m.light(372, -170, top + 84, "255 200 130 30")
    # the mast: four legs, a ring of braces every 128, a rod on top
    u1, v1, u2, v2, tip = 512, -224, 608, -128, b.rim + 256
    legs = [(u, v, top, u + 8, v + 8, tip) for u in (u1, u2 - 8) for v in (v1, v2 - 8)]
    braces = []
    for z in range(top + 120, tip, 128):
        braces += [(u1, v1 + 2, z, u2, v1 + 6, z + 4), (u1, v2 - 6, z, u2, v2 - 2, z + 4), (u1 + 2, v1, z, u1 + 6, v2, z + 4), (u2 - 6, v1, z, u2 - 2, v2, z + 4)]
    m.det(legs + braces + [(u1, v1, tip, u2, v2, tip + 4), (556, -180, tip + 4, 564, -172, tip + 100)], MAT["bars"])
    m.blocked(496, -240, 624, -112)
    m.taken(256, -256, F, 640, -64, tip)
    m.lane(540, -90, top)
    b.notes.append("%s: the mast's tip is at z %d, %d over the walls' tops" % (m.tag, tip + 100, tip + 100 - b.rim))


def m_ash(m, opt):
    """10. The ash outfall (the owner: "just trash and burnt corpses"): a chute's mouth high in the left wall, shut by
    bars, and under it a heap of ash and rubbish with the burnt dead in it. No way in or out."""
    m.open(0, -256, 768, 256)
    lo, hi = F + 208, F + 336
    m.det([(304, 200, lo - 16, 320, 256, hi + 16), (448, 200, lo - 16, 464, 256, hi + 16), (304, 200, hi, 464, 256, hi + 16)], MAT["beam"])
    m.shapes([prism([(184, lo - 40), (256, lo), (256, lo - 16), (184, lo - 56)], "x", 320, 448, MAT["bars"])])     # the tray it slides down
    m.det([(320, 248, lo, 448, 256, hi)], MAT["black"])
    m.det([(320 + 16 * k, 240, lo, 324 + 16 * k, 248, hi) for k in range(8)], MAT["bars"])
    m.taken(296, 176, lo - 64, 472, 256, hi + 24)
    m.no_bank(192, 248, 576, 264)
    cx, cy = m.fr.pt(384, 120)
    m.b.bumps.append(lambda x, y: 96 * max(0.0, 1 - math.hypot(x - cx, y - cy) / 300.0) ** 1.4)
    for model, u, v, yaw, z in (("models/props_junk/garbage256_composite001a.mdl", 384, 60, 0, 30), ("models/props_junk/garbage128_composite001a.mdl", 250, 150, 60, 30),
                                ("models/props_junk/garbage128_composite001a.mdl", 520, 130, 200, 30), ("models/props_junk/garbage128_composite001a.mdl", 400, -110, 130, 4)):
        m.static(model, u, v, yaw, z=F + z)
    for k, (u, v, z) in enumerate(((384, 150, 86), (330, 60, 60), (460, 40, 56), (300, -60, 22), (500, -80, 20), (410, 210, 80))):
        m.body("models/humans/charple0%d.mdl" % (k % 4 + 1), u, v, 55 * k, z=F + z)
    for model, u, v in (("models/props_junk/garbage_bag001a.mdl", 240, 40), ("models/props_junk/garbage_bag001a.mdl", 560, 20),
                        ("models/props_vehicles/tire001c_car.mdl", 470, -150), ("models/props_junk/metalbucket01a.mdl", 330, -140)):
        m.loose(model, u, v, 30, z=F + 20)
    m.blocked(192, -64, 576, 256)
    m.lane(384, -200)


def m_sludge(m, opt):
    """11. The sludge tunnel: the canal goes the long way round a block (out to the left and back), and a low tunnel
    cuts straight through it, ankle deep in toxic runoff. lc_sludge_gas is a trigger filling the tunnel's air, there for
    the game to make it a place for gas masks."""
    m.open(0, -256, 640, 256)
    m.open(128, 256, 640, 1536)
    m.open(640, 1024, 1408, 1536)
    m.open(1408, 256, 1920, 1536)
    m.open(1408, -256, 2048, 256)
    floor, ceil = F - 16, F + 144
    m.low(640, -128, 704, 128, ceil)                       # a dry lip at each mouth (an areaportal must not stand in the sludge)
    m.low(704, -128, 1344, 128, ceil, floor=floor)
    m.low(1344, -128, 1408, 128, ceil)
    m.side(640, -128, 1408, 128)
    m.portal(670, -128, F, 672, 128, ceil)
    m.portal(1376, -128, F, 1378, 128, ceil)
    m.b.vmf.world_box(m.fr.box(704, -128, floor, 1344, 128, floor + 12), MAT["nodraw"], top=MM["sludge"], vis=m.b.vis + ": water and sludge", seals=False)
    m.ent("trigger_multiple", {"targetname": "lc_sludge_gas", "spawnflags": "1", "StartDisabled": "0", "wait": "1"}, [(704, -128, floor, 1344, 128, ceil)], MAT["trigger"])
    for u in (832, 1216):
        m.light(u, 0, ceil - 12, "120 255 90 45")
    m.static("models/props_c17/oildrum001.mdl", 900, 96, 0, z=floor)
    m.static("models/props_c17/oildrum001.mdl", 1130, -92, 0, z=floor)
    m.loose("models/props_c17/oildrum001.mdl", 1010, 60, 40, z=floor)
    m.det([(640, -160, F + 152, 656, 160, F + 176)], MAT["beam"])
    m.det([(1392, -160, F + 152, 1408, 160, F + 176)], MAT["beam"])
    for u, v in ((384, 800), (1024, 1280), (1664, 800)):
        m.lane(u, v)


def m_cistern(m, opt):
    """12. The cistern, for the hive boss (blind, hunts by sound): off the RIGHT wall, a passage to a round settling
    tank 1536 across, ankle deep in water. A dry ledge runs round it and plank walks cross to an island in its middle
    (lc_hive_boss_spot). Wading is in the water (the game can tell: a player's water level); the ledge and planks are dry."""
    b = m.b
    m.open(0, -256, 1536, 256)
    ceil, basin, cu, cv, R = F + 352, F - 32, 768, -1408, 768
    m.low(640, -640, 896, -256, F + 160)
    m.portal(640, -322, F, 896, -320, F + 160)
    pillars = [(cu + du - 64, cv + dv - 64, cu + du + 64, cv + dv + 64) for du in (-384, 384) for dv in (-384, 384)]
    wet = []
    for i in range(-12, 12):
        for j in range(-12, 12):
            u, v = cu + i * CELL, cv + j * CELL
            d = math.hypot(i + 0.5, j + 0.5) * CELL
            if d >= R or any(p[0] <= u < p[2] and p[1] <= v < p[3] for p in pillars):
                continue
            island = abs(i + 0.5) < 2 and abs(j + 0.5) < 2
            dry = d >= R - 150 or island
            m.low(u, v, u + CELL, v + CELL, ceil, floor=F if dry else basin)
            if not dry:
                wet.append(m.fr.rect(u, v, u + CELL, v + CELL))
    m.side(0, -2176, 1536, -256)
    # the water: one sheet for every run of wet squares
    wet.sort(key=lambda r: (r[1], r[0]))
    runs = []
    for r in wet:
        if runs and runs[-1][1] == r[1] and runs[-1][2] == r[0]:
            runs[-1][2] = r[2]
        else:
            runs.append([r[0], r[1], r[2], r[3]])
    for x1, y1, x2, y2 in runs:
        b.vmf.world_box((x1, y1, basin, x2, y2, basin + 12), MAT["nodraw"], top=MM["water"], vis=b.vis + ": water and sludge", seals=False)
    # plank walks from the ledge to the island, on posts
    planks, posts = [], []
    for (a1, a2, axis) in ((cu + 128, cu + R - 128, "u"), (cu - R + 128, cu - 128, "u"), (cv + 128, cv + R - 128, "v"), (cv - R + 128, cv - 128, "v")):
        planks.append((a1, cv - 32, F - 6, a2, cv + 32, F) if axis == "u" else (cu - 32, a1, F - 6, cu + 32, a2, F))
        for a in range(a1 + 60, a2 - 20, 160):
            posts.append((a, cv - 28, basin, a + 8, cv + 28, F - 6) if axis == "u" else (cu - 28, a, basin, cu + 28, a + 8, F - 6))
    m.det(planks, MM["wood"])
    m.det(posts, MM["beam_wood"])
    m.point("info_target", cu, cv, F + 8, {"targetname": "lc_hive_boss_spot", "angles": "0 %d 0" % m.fr.yaw(90)})
    for du, dv in ((0, 0), (-520, 0), (520, 0), (0, -520), (0, 520)):
        m.light(cu + du, cv + dv, ceil - 16, "150 190 200 70" if (du or dv) else "170 200 210 110")
    m.lane(768, -448)
    for du, dv in ((0, 0), (400, 0), (-400, 0), (0, 400), (0, -400)):
        m.lane(cu + du, cv + dv)
    b.notes.append("%s: the tank's middle is at (%d %d); its floor is z %d under %d of water, its ledge, planks and island z %d, its roof z %d" % (
        (m.tag,) + m.fr.pt(cu, cv) + (basin, 12, F, ceil)))


def m_underpass(m, opt):
    """13. The barnacle underpass: 1024 of canal under a wide road, unlit, barnacles on its roof, a wreck, and the dead
    lying where they were dropped (things to search)."""
    m.open(0, -256, 256, 256)
    m.low(256, -256, 1280, 256, F + GATE_HIGH)
    m.open(1280, -256, 1536, 256)
    m.portal(318, -256, F, 320, 256, F + GATE_HIGH)
    m.portal(1216, -256, F, 1218, 256, F + GATE_HIGH)
    for u, v in ((470, 40), (600, -110), (730, 90), (860, -30), (990, 120), (1110, -80)):
        m.point("npc_barnacle", u, v, F + GATE_HIGH - 1, {"angles": "0 0 0", "spawnflags": "0"}, m.b.vis + ": barnacles (delete them if the game minds)")
    m.static("models/props_vehicles/car004a_physics.mdl", 800, -150, 25)
    m.static("models/props_debris/barricade_short01a.mdl", 520, 150, 80)
    m.blocked(690, -250, 910, -60)
    for k, (model, u, v) in enumerate((("models/humans/corpse1.mdl", 560, -40), ("models/humans/charple03.mdl", 700, 110), ("models/humans/corpse1.mdl", 930, 60),
                                       ("models/humans/charple01.mdl", 1060, -120), ("models/humans/corpse1.mdl", 1150, 40))):
        m.body(model, u, v, 70 * k)
    m.loose("models/props_junk/wood_crate001a.mdl", 640, 170, 15)
    m.loose("models/props_junk/wood_crate002a.mdl", 1000, -170, 50)
    for u in (400, 768, 1136):
        m.lane(u, 0)


# name: (length, how to build it, what it is)
MODULES = {
    "straight": (1024, m_straight, "plain canal (\"straight 1536\", \"straight 1024 bridge\")"),
    "drain": (1024, m_drain, "1. the storm drain junction, down to the city's sewers (left)"),
    "overflow": (1024, m_overflow, "2. the overflow toward Ravenholm, behind a sluice plate (left)"),
    "shanty": (1536, m_shanty, "4. the shantytown under a street bridge (left)"),
    "vort": (1024, m_vort, "6. the vortigaunt culvert (left)"),
    "relay": (768, m_relay, "7. Cubbage's relay shack and mast, on a pier (right)"),
    "ash": (768, m_ash, "10. the ash outfall: trash and burnt corpses (left)"),
    "sludge": (2048, m_sludge, "11. the sludge tunnel: a shortcut through the long way round (left)"),
    "cistern": (1536, m_cistern, "12. the cistern for the hive boss (right)"),
    "underpass": (1536, m_underpass, "13. the barnacle underpass"),
}


def read_layout(path):
    """A layout: "start X Y", "heading E|N|W|S", "rim Z", "end X Y HEADING" (where it must come out), then a module a line."""
    lay = {"name": path.replace("\\", "/").split("/")[-1].rsplit(".", 1)[0], "start": (0, 0), "heading": "E", "rim": 784, "end": None, "modules": []}
    for raw in open(path):
        words = raw.split("#")[0].split()
        if not words:
            continue
        if words[0] == "start":
            lay["start"] = (int(words[1]), int(words[2]))
        elif words[0] == "heading":
            lay["heading"] = words[1].upper()
        elif words[0] == "rim":
            lay["rim"] = int(words[1])
        elif words[0] == "end":
            lay["end"] = (int(words[1]), int(words[2]), words[3].upper())
        else:
            lay["modules"].append(words)
    return lay


def build_chain(lay, args):
    b = Build(lay["name"], lay["rim"], args.first_node or 6000)
    x, y = lay["start"]
    rot = HEADINGS[lay["heading"]]
    for v in (x, y):
        if v % CELL:
            b.problems.append("the start (%d %d) is off the %d grid" % (x, y, CELL))
    steps = [["gate", "start"]] + lay["modules"] + [["gate", "end"]]
    count = {}
    for n, words in enumerate(steps):
        name, opt = words[0], words[1:]
        flip = "flip" in opt
        if name in ("left", "right"):
            fr = Frame(x, y, rot, 512)
            m_corner(Mod(b, fr, "%d %s turn" % (n, name)), opt)
            x, y = fr.pt(256, 256 if name == "left" else -256)
            rot = (rot + (1 if name == "left" else -1)) % 4
            continue
        if name == "gate":
            fr = Frame(x, y, rot, 256, flip=(opt[0] == "end"))
            m_gate(Mod(b, fr, "the %s gate" % opt[0]), opt)
            if opt[0] == "start":
                seed = fr.pt(192, 0) + (F + 32,)
                spawn = (fr.pt(224, 0) + (F + 16,), fr.yaw(0))
            b.labels.append(fr.pt(128, 0) + ("gate",))
            x, y = Frame(x, y, rot, 256).pt(256, 0)
            continue
        if name not in MODULES:
            b.problems.append("the layout names a module that does not exist: %s" % name)
            continue
        length = MODULES[name][0]
        if name == "straight" and opt and opt[0].isdigit():
            length = int(opt[0])
        if length % CELL:
            b.problems.append("%s %d: a length must be a multiple of %d" % (name, length, CELL))
            continue
        count[name] = count.get(name, 0) + 1
        tag = name if name == "straight" else "%s%s" % (name, " %d" % count[name] if count[name] > 1 else "")
        fr = Frame(x, y, rot, length, flip)
        mod = Mod(b, fr, "%d %s" % (n, tag))
        MODULES[name][1](mod, opt)
        if name != "straight":
            b.labels.append(fr.pt(length // 2, 0) + (tag,))
        x, y = Frame(x, y, rot, length).pt(length, 0)
    end = (x, y, "ENWS"[rot])
    if lay["end"] and tuple(lay["end"]) != end:
        b.problems.append("the chain comes out at (%d %d) heading %s, not at (%d %d) heading %s as the layout says it must" % (end + tuple(lay["end"])))
    return b, seed, spawn, end


def finish(b, seed, spawn, args):
    vmf, plan = b.vmf, b.plan
    plan.build(vmf)
    if args.test:
        test_extras(vmf, spawn[0], spawn[1], b.vis + ": for testing alone (never in the real map)")
    ch = Channel(vmf, plan, F, TRIM, b.vis)
    ch.dress(b.no_bank, b.taken)
    bump = (lambda x, y: sum(f(x, y) for f in b.bumps)) if b.bumps else None
    ch.mud(47, skip=b.no_mud, bump=bump)
    fences = fence(vmf, plan, 96, b.vis + ": fence along the walls' tops", top=b.rim)
    ch.nodes(b.node, b.blocked)
    for (nx, ny, nz) in b.lanes:
        b.node(nx, ny, nz)
    problems, air = check(vmf, seed, [])
    problems = b.problems + problems
    names = [n for n in b.names if n[0] != "clash"]
    seen = {}
    for n in names:
        seen[n[0]] = seen.get(n[0], 0) + 1
    for name, k in sorted(seen.items()):
        if k > 1:
            problems.append("%d things are named %s (the same module twice in one chain: the game could not tell them apart)" % (k, name))
    return ch, fences, problems, names


def report(b, ch, fences, problems, names, end, what):
    vmf = b.vmf
    seals = sum(1 for _, s in vmf.boxes if s)
    xs = [bx[0] for bx, _ in vmf.boxes] + [bx[3] for bx, _ in vmf.boxes]
    ys = [bx[1] for bx, _ in vmf.boxes] + [bx[4] for bx, _ in vmf.boxes]
    st = ch.stats
    print("%s: %d sealing brushes, %d sloped or round shapes, %d mud patches, %d entities (%d path nodes, ids %d to %d)" % (
        what, seals, vmf.shapes, st["mud"], len(vmf.ents), b.node_id - b.first_node, b.first_node, b.node_id - 1))
    print("  dressing: %d banks, %d corner fills, %d ribs, %d drain stubs, %d runs of fence" % (st["banks"], st["fills"], st["ribs"], st["stubs"], fences))
    print("  it fills x %d to %d, y %d to %d, z %d to %d; floor z %d; the walls' concrete ends at z %d; it comes out at (%d %d) heading %s" % (
        min(xs), max(xs), min(ys), max(ys), BASE, b.sky + 16, F, b.rim, end[0], end[1], end[2]))
    if names:
        print("  named for the game: " + ", ".join("%s (%s)" % (n[0], n[1]) for n in names))
    for note in b.notes:
        print("  " + note)
    if problems:
        for p in problems:
            print("  PROBLEM: " + p)
    else:
        print("  checked: every corner on the grid; sealed by itself with its caps in; no module runs into another; every areaportal walled all round")


def picture(b, path):
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print("  no picture: Pillow is not installed (pip install pillow)")
        return
    cells = b.plan.cells
    xs, ys = [c[0] for c in cells], [c[1] for c in cells]
    x0, y0, x1, y1 = min(xs), min(ys), max(xs) + 1, max(ys) + 1
    s = max(2, min(8, 2400 // max(x1 - x0, y1 - y0)))
    img = Image.new("RGB", ((x1 - x0) * s, (y1 - y0) * s), (24, 26, 30))
    d = ImageDraw.Draw(img)
    for (i, j), spec in cells.items():
        if spec[0] == "solid":
            col = (70, 72, 78)
        elif spec[0] == "open":
            col = (150, 160, 170) if spec[1] <= F else (200, 190, 150)
        else:
            col = (60, 110, 150) if spec[1] < F else (100, 105, 125)
        d.rectangle([(i - x0) * s, (y1 - 1 - j) * s, (i - x0 + 1) * s - 1, (y1 - j) * s - 1], fill=col)
    for (x, y, text) in b.labels:
        d.text(((x / CELL - x0) * s + 4, (y1 - y / CELL) * s - 6), text, fill=(255, 220, 90))
    img.save(path)
    print("  picture (north up; light: open canal; grey-blue: under a roof; blue: lower than the canal (water, sludge, the sewer end); sand: a pier): " + path)


def chain(args):
    lay = read_layout(args.layout)
    if args.origin:
        lay["start"], lay["end"] = tuple(args.origin), None
    if args.heading:
        lay["heading"], lay["end"] = args.heading, None
    if args.rim:
        lay["rim"] = args.rim
    b, seed, spawn, end = build_chain(lay, args)
    ch, fences, problems, names = finish(b, seed, spawn, args)
    report(b, ch, fences, problems, names, end, "chain %s (%d modules)" % (lay["name"], len(lay["modules"])))
    if args.preview:
        picture(b, args.preview)
    args.expect_overlap = set()
    args.out_name = "lc_%s%s.vmf" % (lay["name"], "_test" if args.test else "")
    return b.vmf, problems


def module(args):
    if args.name not in MODULES:
        print("modules: ")
        for k, (length, _, what) in MODULES.items():
            print("  %-10s %5d long  %s" % (k, length, what))
        raise SystemExit(1)
    lay = {"name": "mod_" + args.name, "start": tuple(args.origin or (0, 0)), "heading": args.heading or "E", "rim": args.rim or 784, "end": None,
           "modules": [[args.name] + (["flip"] if args.flip else [])]}
    b, seed, spawn, end = build_chain(lay, args)
    ch, fences, problems, names = finish(b, seed, spawn, args)
    report(b, ch, fences, problems, names, end, "module %s (%s)" % (args.name, MODULES[args.name][2]))
    if args.preview:
        picture(b, args.preview)
    args.expect_overlap = set()
    args.out_name = "lc_mod_%s%s.vmf" % (args.name, "_test" if args.test else "")
    return b.vmf, problems
