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
CANAL_W, WIDE_W = 512, 1024   # the canal's width (Valve's city canal), and the wide canal's (Valve's airboat canals)
BASE = 224                # the bottom of everything (the storm drain goes down to the city's sewers, feet at z 288)
SEWER = 288
HEADINGS = {"E": 0, "N": 1, "W": 2, "S": 3}
# Soundscapes the owner's own map uses (so they are known to be there): what a place sounds like, by kind.
SCAPES = {"tunnel": "prison.general_dripping_tunnel", "watery": "prison.watery_hallway", "slime": "canals_slime_tunnel", "pump": "d1_canals.waterpuzzleroom",
          "cave": "d1_town.CaveTunnel", "flat": "d1_trainstation.Appartments", "house": "d1_town.WoodBuilding", "inside": "construct.inside",
          "combine": "d3_citadel.generic_moody", "laundry": "prison.laundry", "metal": "coast.util_metalstress", "courtyard": "d1_trainstation.QuietCourtyard",
          "square": "d1_trainstation.TerminalSquare", "rooftop": "d1_town.Rooftop"}
# Decals Half-Life 2 has (checked in Valve's lists), by what they show: m.grime picks one.
GRIME = {"stain": ["decals/decalstain%03da" % n for n in (1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)],
         "drain": ["decals/decalconcretedrain00%da" % n for n in (1, 2, 3)],
         "trash": ["decals/trashdecal0%da" % n for n in (1, 2, 3, 4, 5)],
         "crack": ["decals/plaster%03da" % n for n in (1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20)],
         "poster": ["decals/decal_posterbreen", "decals/decalposter002a", "decals/decalposter002b", "decals/decalposter003a", "decals/decalposter004a",
                    "decals/decalposter007a", "decals/decalposter014a", "decals/decalposter014b", "decals/decalposter014d"],
         "danger": ["decals/decalsigndanger00%s" % k for k in ("1a", "1b", "1c", "1d", "1e", "1f", "2a")],
         "graffiti": ["decals/decalgraffiti%03da" % n for n in (1, 3, 5, 6, 7, 8, 9, 10, 11, 12, 15, 17, 18, 20, 22, 23, 24, 25, 28, 31, 36, 37, 38, 43, 44, 46, 47, 49, 50, 54, 56, 59, 60, 61, 62)],
         "number": ["decals/decalindustrialnumber%s" % k for k in ("00a", "01a", "01b", "02a", "02b", "03a", "03b", "04b", "05a", "05b", "06b", "07b", "08b")],
         "lambda": ["decals/lambdaspray_1a", "decals/lambdaspray_2a"], "burn": ["decals/burn01a", "decals/burn02a", "decals/burn03a"],
         "puddle": ["decals/decalborealispuddle001a"], "grate": ["decals/decalmetalgrate001a", "decals/decalmetalgrate005a"],
         "debris": ["decals/debris_concrete001a", "decals/debris_concrete001b"], "police": ["decals/decal_policeline01a"]}

MM = {
    "wood": "wood/woodfloor007a",          # (these four are in the owner's own map: Ravenholm's recipe was read from it)
    "tin": "metal/metalroof004a",
    "steel": "metal/metalhull003a",
    "beam_wood": "wood/woodbeam001a",
    "water": "nature/water_canals_water_clear",   # hl2 (the bunker forest's pond)
    "sludge": "nature/toxicslime002a",            # hl2: the canals' toxic slime
    "road": "stone/stonefloor006d_c17",           # the owner's own streets' cobbles (Ravenholm's recipe was read from their map)
    "walk": "concrete/concretefloor016a",         # ...and their pavements
    "gravel": "nature/gravelfloor002a",           # hl2: a railway's ballast
    "brick": "brick/brickwall045d",
}


class Frame:
    """Where a module sits: its entry's middle (x, y), the way it heads (rot: 0 east, 1 north, 2 west, 3 south) and its
    length. flip: built from its far end backwards, which puts its left bank on the right."""

    def __init__(self, x, y, rot, length, flip=False, shift=0, dv=0, dz=0):
        self.x, self.y, self.rot, self.length, self.flip, self.shift = x, y, rot % 4, length, flip, shift
        self.dv, self.dz = dv, dz      # (a module lifted to the street: moved this far to the left, and this far up)

    def pt(self, u, v):
        if self.flip:      # (shift: how far to the left of its entry the module's exit is; flipped, its exit is the entry)
            u, v = self.length - u, self.shift - v
        v += self.dv
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
        return (r[0], r[1], min(z1, z2) + self.dz, r[2], r[3], max(z1, z2) + self.dz)

    def at(self, u, v, z):
        """A place in the map (x, y, z) for a place in the module. Use this, never pt() plus a height of your own."""
        return self.pt(u, v) + (z + self.dz,)

    def ax(self, a):
        """The map's axis ("x" or "y") that the module's "u" or "v" runs along."""
        return ("x" if a == "u" else "y") if self.rot % 2 == 0 else ("y" if a == "u" else "x")

    def yaw(self, a):
        return (a + 90 * self.rot + (180 if self.flip else 0)) % 360

    def way(self, a):
        """The map's whole-number direction (dx, dy) of a yaw in the module (0 along u, 90 to the left)."""
        return {0: (1, 0), 90: (0, 1), 180: (-1, 0), 270: (0, -1)}[self.yaw(a)]

    def faces(self, faces):
        return [([self.at(p[0], p[1], p[2]) for p in verts], mat) for verts, mat in faces]


class Build:
    """One file being made: its plan, and what the modules leave for the dressing and the checks."""

    def __init__(self, name, rim, first_node, upper=None):
        self.name, self.rim, self.sky = name, rim, rim + 384
        self.vmf = Vmf()
        self.vis = "LC %s" % name
        self.upper = upper    # "left" or "right": the bank built up to the street (map_corridor.py), or None
        self.deck, self.viaduct, self.sheds, self.lifted = set(), set(), set(), set()
        if upper:
            import map_corridor
            self.sky = map_corridor.STREET + 768
            self.plan = map_corridor.CorridorPlan(BASE, rim, self.sky, self.vis + ": walls and floors")
        else:
            self.plan = Plan((0, 0), [(BASE, rim, MAT["canal_wall"]), (rim, self.sky + 16, MAT["sky"])], sky=self.sky, vis=self.vis + ": walls and floors")
        self.taken, self.blocked, self.no_bank, self.no_mud, self.lanes = [], [], [], [], []
        self.upright = []     # rectangles where the canal's walls stand upright: no bank, the rest of the dressing as ever
        self.after, self.bumps, self.notes, self.names, self.problems = [], [], [], [], []
        self.owner = {}       # square -> the module that painted it
        self.labels = []      # (x, y, text) for the picture
        self.node_id = first_node
        self.first_node = first_node
        self.test = False
        self.props = []       # (class, model, place, yaw) of every prop, for the checks
        self.views = []       # (label, eye, yaw, pitch): pictures to take with map_view.py
        self.rope_n = 0
        self.pipes = []       # (axis, where along it, wall, wall): pipes to lay across the canal with the dressing

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
        if self.fr.dz:      # (lifted to the street: its floors and roofs go up with it, and its canal's floor is the road)
            if spec[0] == "open" and spec[1] == F and spec[2] == MAT["canal_floor"]:
                spec = ("open", F, MM["road"])
            spec = spec[:1] + (spec[1] + self.fr.dz,) + spec[2:3] + tuple(z + self.fr.dz for z in spec[3:4]) + spec[4:]
        for i in range(r[0] // CELL, r[2] // CELL):
            for j in range(r[1] // CELL, r[3] // CELL):
                was = self.b.owner.get((i, j))
                if was and was != self.tag and self.b.plan.cells.get((i, j)) == spec:
                    continue      # (the same square painted the same way twice: two modules sharing a street)
                if was and was != self.tag and ("clash", was, self.tag) not in self.b.names:
                    self.b.names.append(("clash", was, self.tag))
                    self.b.problems.append("%s runs into %s near (%d %d): move one of them in the layout" % (self.tag, was, i * CELL, j * CELL))
                self.b.owner[(i, j)] = self.tag
        self.b.plan.paint(r, spec)

    def unpaint(self, u1, v1, u2, v2):
        """Squares taken back out of what was painted: a pillar, a pier (they become solid like any wall)."""
        r = self.fr.rect(u1, v1, u2, v2)
        for i in range(r[0] // CELL, r[2] // CELL):
            for j in range(r[1] // CELL, r[3] // CELL):
                self.b.plan.cells.pop((i, j), None)
                self.b.owner.pop((i, j), None)

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

    def upright(self, u1, v1, u2, v2):
        """The walls stand upright here, as Valve's do (the wide canal, a walk along a wall): no bank where this rectangle
        covers a wall's line; its lip, ribs, outfalls and lamps stay."""
        self.b.upright.append(self.fr.rect(u1, v1, u2, v2))

    def taken(self, *box):
        self.b.taken.append(self.fr.box(*box))

    def lane(self, u, v, z=F):
        self.b.lanes.append(self.fr.at(u, v, z))

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
        """Stairs rising from z_low at `start` in the way of sign along axis ("u" or "v"); lo..hi across. Steps of about 16
        up and 24 along (the owner, 20 November, of steps of 8 and 12: "a stairway meant for toddlers ... these steps
        should be fewer and larger"); the slope and the run are as they were, 12 along for every 8 up, which it returns."""
        rise = z_high - z_low
        run, n = 12 * (rise // 8), max(1, -(-rise // 16))
        out = []
        for i in range(n):
            a, c = start + sign * (run * i // n), start + sign * (run * (i + 1) // n)
            a, c = min(a, c), max(a, c)
            top = z_low + rise * (i + 1) // n
            out.append((a, lo, z_low, c, hi, top) if axis == "u" else (lo, a, z_low, hi, c, top))
        self.det(out, MAT["canal_wall"], top=MAT["stairs"])
        return run

    # --- things ---
    def point(self, cls, u, v, z, keys=None, vis=None, connections=None):
        self.b.vmf.point(cls, self.fr.at(u, v, z), keys or {}, vis or self.dv, connections=connections)
        if keys and keys.get("targetname"):
            self.b.names.append((keys["targetname"], cls, self.tag))

    def stand(self, model, z):
        """The height to put a model's origin at for it to stand ON z (models' origins are often at their middles). Read
        from the model's own build file (map_assets.py); a model whose size is not known is put at z itself."""
        import map_assets
        bb = map_assets.size(model)
        return z - int(math.floor(bb[2])) if bb else z

    def prop(self, cls, model, u, v, yaw, z, keys, vis=None):
        """Any prop, standing on z. Its place and size go to the checks and the pictures."""
        zo = self.stand(model, z)
        wy = self.fr.yaw(yaw)
        k = {"model": model, "angles": "0 %d 0" % wy, "skin": "0"}
        k.update(keys)
        self.point(cls, u, v, zo, k, vis or self.pv)
        self.b.props.append((cls, model, self.fr.at(u, v, zo), wy, self.tag))

    def static(self, model, u, v, yaw=0, z=F):
        """A prop that never moves, standing on z. A model that was not built to be static (map_assets.py knows) is
        placed as a prop_dynamic instead, since the compiler would leave it out."""
        import map_assets
        if map_assets.is_static(model) is False:
            return self.dynamic(model, u, v, yaw, z)
        self.prop("prop_static", model, u, v, yaw, z, {"solid": "6", "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"})

    def loose(self, model, u, v, yaw=0, z=F):
        """A prop that can be pushed about, standing on z."""
        self.prop("prop_physics", model, u, v, yaw, z + 1, {"spawnflags": "0"})

    def dynamic(self, model, u, v, yaw=0, z=F, name=None, solid=True):
        """A prop that stays put but may be named for the game (any model will do), standing on z."""
        k = {"solid": "6" if solid else "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0",
             "renderamt": "255", "rendercolor": "255 255 255"}
        if name:
            k["targetname"] = name
        import map_assets      # (a physics prop standing still is a prop_dynamic_override: as a plain prop_dynamic the game objects to it)
        self.prop("prop_dynamic_override" if map_assets.is_physics_prop(model) else "prop_dynamic", model, u, v, yaw, z, k)

    def body(self, model, u, v, yaw=0, z=F):
        self.point("prop_ragdoll", u, v, z + 16, {"model": model, "angles": "0 %d 0" % self.fr.yaw(yaw), "spawnflags": "4"}, self.b.vis + ": bodies")

    def light(self, u, v, z, colour):
        self.point("light", u, v, z, {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.lv)

    def glow(self, u, v, z, colour="255 220 170", scale=0.3):
        """A soft glow in the air (a lamp seen from afar). No light of its own."""
        self.point("env_sprite", u, v, z, {"model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "200", "rendercolor": colour, "scale": str(scale),
                                           "framerate": "10.0", "GlowProxySize": "2.0", "HDRColorScale": "1.0", "renderfx": "0", "spawnflags": "1"}, self.lv)

    def lamp(self, u, v, z, colour, hang=0):
        """A lamp to be seen, a real fixture of the city's (the owner's map has 151 of the dome light): a dome light flat
        on the ceiling at z + 8, or with hang a bell lamp on a rod this long from above. A glow, and its light under it."""
        rgb = " ".join(colour.split()[:3])
        if hang:
            self.det([(u - 1, v - 1, z + 8, u + 1, v + 1, z + 8 + hang)], MM["steel"])
            self.static("models/props_c17/light_industrialbell01_on.mdl", u, v, 0, z - 15)
            self.glow(u, v, z - 18, rgb, 0.25)
            self.light(u, v, z - 24, colour)
            return
        self.static("models/props_c17/light_domelight02_on.mdl", u, v, 0, z + 1)
        self.glow(u, v, z - 2, rgb, 0.25)
        self.light(u, v, z - 10, colour)

    def soundscape(self, name, u, v, z, radius=768):
        """What the place sounds like: an env_soundscape (the owner's map has 155; a loop alone is not a place). Use the
        names in SCAPES (the ones the owner's own map uses) or another Half-Life 2 soundscape (say it is unchecked)."""
        self.point("env_soundscape", u, v, z + 64, {"soundscape": name, "radius": str(radius), "StartDisabled": "0"})

    def grime(self, kind, u, v, z, seed=0):
        """A decal of a kind (GRIME: stain, drain, trash, crack, poster, danger, graffiti, number, lambda, burn, puddle,
        grate): the point must lie ON the wall or floor it marks, as for m.decal."""
        import random
        self.decal(random.Random(seed * 7919 + u * 31 + v).choice(GRIME[kind]), u, v, z)

    def stair_side(self, start, run, v1, v2, z_low, z_high, sign=1, high=32, mat=None):
        """The open side of a stair that climbs along u, made solid: an upstand from the floor to 'high' over the stair's
        line, from u = start to start + sign * run, standing on v1..v2 (a slab 8 or so thick). A flight then reads as
        one built stair, not a row of blocks (the module review, 20 November)."""
        a, b = sorted((start, start + sign * run))
        za, zb = (z_low, z_high) if sign > 0 else (z_high, z_low)
        self.shapes([prism([(a, z_low), (b, z_low), (b, zb + high), (a, za + high)], "y", v1, v2, mat or MAT["beam"])])

    def spot(self, u, v, z, colour, yaw, pitch=60, cone=40, name=None):
        """A beam: a light that only shines one way (pitch: degrees down), and the beam drawn in the air."""
        wy = self.fr.yaw(yaw)
        self.point("light_spot", u, v, z, {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_inner_cone": str(cone // 2), "_cone": str(cone), "_quadratic_attn": "1",
                                           "angles": "0 %d 0" % wy, "pitch": str(-pitch), "style": "0"}, self.lv)
        keys = {"angles": "%d %d 0" % (pitch, wy), "spawnflags": "1", "spotlightlength": "500", "spotlightwidth": "50",
                "rendercolor": " ".join(colour.split()[:3]), "renderamt": "160", "HDRColorScale": "1.0"}
        if name:
            keys["targetname"] = name
        self.point("point_spotlight", u, v, z, keys, self.lv)

    def sound(self, message, u, v, z, radius=1100, volume=7, name=None, on=True):
        """A sound in the air, playing from the start (on) or waiting to be told (PlaySound). Only a sound file made to
        loop goes on for ever: one that is not plays once."""
        keys = {"message": message, "health": str(volume), "pitch": "100", "pitchstart": "100", "radius": str(radius), "spawnflags": "0" if on else "16",
                "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0", "lfomodpitch": "0", "lfomodvol": "0", "lforate": "0", "lfotype": "0", "preset": "0",
                "spindown": "0", "spinup": "0", "volstart": "0"}
        if name:
            keys["targetname"] = name
        self.point("ambient_generic", u, v, z, keys, self.b.vis + ": sounds")

    def decal(self, texture, u, v, z):
        """A stain or poster: the point must lie ON the wall or floor it marks (within a unit)."""
        self.point("infodecal", u, v, z, {"texture": texture})

    def target(self, name, u, v, z, yaw=0):
        """A place named for the game to find (nothing to see)."""
        self.point("info_target", u, v, z, {"targetname": name, "angles": "0 %d 0" % self.fr.yaw(yaw)})

    def relay(self, name, u, v, z, wires, on=True):
        """A switchboard: Trigger makes it fire every wire, [(the thing's name, the input, a value, seconds later), ...]."""
        self.point("logic_relay", u, v, z, {"targetname": name, "StartDisabled": "0" if on else "1", "spawnflags": "0"},
                   connections=[("OnTrigger", n, i, val, d) for n, i, val, d in wires])

    def rope(self, pts, slack=40, width=2):
        """A cable hung from point to point, [(u, v, z), ...]: it sags by itself."""
        self.b.rope_n += 1
        names = ["lc_rope_%s_%d_%d" % (self.b.name, self.b.rope_n, k) for k in range(len(pts))]
        for k, (u, v, z) in enumerate(pts):
            keys = {"targetname": names[k], "Slack": str(slack), "Type": "0", "Subdiv": "2", "Barbed": "0", "Width": str(width), "TextureScale": "1", "Collide": "0",
                    "Dangling": "0", "Breakable": "0", "RopeMaterial": "cable/cable.vmt", "MoveSpeed": "64", "PositionInterpolator": "2", "NoWind": "1"}
            if k + 1 < len(pts):
                keys["NextKey"] = names[k + 1]
            self.b.vmf.point("move_rope" if k == 0 else "keyframe_rope", self.fr.at(u, v, z), keys, self.b.vis + ": ropes")

    def ladder(self, u, v, z0, z1, out):
        """A ladder against a wall at (u, v), from z0 up to z1 (128 a piece), facing `out` (a yaw in the module: 0 along
        u, 90 left ...): set up the way the owner's own map does its ladders. The floor at the top is behind it."""
        vmf, vis = self.b.vmf, self.dv
        z0, z1 = z0 + self.fr.dz, z1 + self.fr.dz
        x, y = self.fr.pt(u, v)
        dx, dy = self.fr.way(out)
        wy = self.fr.yaw(out)
        z = z0
        while z < z1:
            vmf.point("prop_static", (x, y, z), {"model": "models/props_c17/metalladder002.mdl", "angles": "0 %d 0" % wy, "skin": "0", "solid": "6",
                                                 "fademindist": "-1", "fadescale": "1"}, vis)
            z += 128
        vmf.point("prop_static", (x, y, z1), {"model": "models/props_c17/metalladder002b.mdl", "angles": "0 %d 0" % ((wy + 180) % 360), "skin": "0", "solid": "6",
                                              "fademindist": "-1", "fadescale": "1"}, vis)
        lx, ly = x + 28 * dx, y + 28 * dy
        vmf.point("func_useableladder", (lx, ly, z0 + 130), {"point0": "%d %d %d" % (lx, ly, z0 + 4), "point1": "%d %d %d" % (lx, ly, z1 + 12),
                                                             "spawnflags": "0", "StartDisabled": "0"}, vis)
        vmf.point("info_ladder_dismount", (x + 70 * dx, y + 70 * dy, z0 + 1), {}, vis)
        vmf.point("info_ladder_dismount", (x - 42 * dx, y - 42 * dy, z1 + 1), {}, vis)

    def button(self, name, u, v, z, out, wires, wait="1"):
        """A button players press, on the wall at (u, v), its foot at z, facing `out`. wires: what a press does,
        [(the thing's name, the input, a value, seconds later), ...]. It works in the map by itself: no game code."""
        from map_forest import wall_button
        z += self.fr.dz
        x, y = self.fr.pt(u, v)
        dx, dy = self.fr.way(out)
        box = (min(x - 10 * abs(dy), x + 10 * dx), min(y - 10 * abs(dx), y + 10 * dy), z - 4, max(x + 10 * abs(dy), x + 10 * dx), max(y + 10 * abs(dx), y + 10 * dy), z + 24)
        wall_button(self.b.vmf, (x, y, z), self.fr.yaw(out), name, box, self.dv, [("OnPressed", n, i, val, d) for n, i, val, d in wires], wait)
        self.b.names.append((name, "func_button", self.tag))

    def water(self, u1, v1, u2, v2, z1, z2, mat=None):
        """Standing water (or sludge): never across an areaportal."""
        self.b.vmf.world_box(self.fr.box(u1, v1, z1, u2, v2, z2), MAT["nodraw"], top=mat or MM["water"], vis=self.b.vis + ": water and sludge", seals=False)

    def spark(self, u, v, z, name=None):
        keys = {"MaxDelay": "7", "Magnitude": "2", "TrailLength": "1", "spawnflags": "64"}
        if name:
            keys["targetname"] = name
        self.point("env_spark", u, v, z, keys)

    def smoke(self, u, v, z, colour="70 70 70", size=24, length=220, rate=14):
        """Thin smoke rising from a place."""
        self.point("env_smokestack", u, v, z, {"InitialState": "1", "BaseSpread": "14", "SpreadSpeed": "10", "Speed": "24", "StartSize": str(size), "EndSize": str(size * 3),
                                               "Rate": str(rate), "JetLength": str(length), "WindAngle": "0", "WindSpeed": "0", "SmokeMaterial": "particle/SmokeStack.vmt",
                                               "twist": "4", "roll": "4", "rendercolor": colour, "renderamt": "120", "angles": "0 0 0"})

    def cubemap(self, u, v, z=F):
        self.point("env_cubemap", u, v, z + 72, {"cubemapsize": "0"})

    def scatter(self, u1, v1, u2, v2, n, seed, kinds=None, z=F):
        """Odds and ends left lying in a rectangle (loose things; the same every time for one seed)."""
        rnd = random.Random(seed)
        kinds = kinds or ("models/props_junk/wood_crate001a.mdl", "models/props_junk/wood_pallet001a.mdl", "models/props_vehicles/tire001c_car.mdl",
                          "models/props_c17/oildrum001.mdl", "models/props_junk/wood_crate002a.mdl")
        for _ in range(n):
            self.loose(rnd.choice(kinds), rnd.randrange(u1, u2), rnd.randrange(v1, v2), rnd.randrange(0, 360, 15), z=z)

    def view(self, u, v, z, yaw, pitch=6, label=""):
        """A picture to take when asked (--views): from where a player standing at (u, v) on a floor at z would look."""
        self.b.views.append(((self.tag + " " + label).strip(), self.fr.at(u, v, z + 64), self.fr.yaw(yaw), pitch))

    def door(self, name, boxes, mat, movedir, speed=40, lip=8, vis=None):
        """A brush that slides when the game tells it to (Open, Close): never by a player's Use."""
        self.ent("func_door", {"targetname": name, "movedir": movedir, "speed": str(speed), "lip": str(lip), "wait": "-1", "spawnflags": "32", "spawnpos": "0",
                               "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0", "noise1": "MetalGrate.ScrapeSmooth",
                               "noise2": "MetalGrate.ImpactSoft", "locked_sentence": "0", "unlocked_sentence": "0", "renderamt": "255",
                               "rendercolor": "255 255 255", "renderfx": "0", "rendermode": "0", "disableshadows": "1"}, boxes, mat, vis)

    def test_button(self, box, wires):
        """Only in a --test file: a button a walker presses to work something the game will work later.
        wires: [(the button's output, the thing's name, the input), ...]."""
        if not self.b.test:
            return
        self.b.vmf.brush_entity("func_button", {"movedir": "0 0 0", "speed": "8", "lip": "4", "wait": "-1", "spawnflags": "1056", "sounds": "0", "health": "0",
                                                "rendermode": "0", "renderamt": "255", "rendercolor": "255 60 60"}, [self.fr.box(*box)], MM["steel"],
                                self.b.vis + ": for testing alone (never in the real map)", connections=[(o, n, i, "", 0) for o, n, i in wires])

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

    def bridge(self, a, b, lo, hi, far_pier=True):
        """A street carried over the canal at the trim's height (the ring's road_bridge, in the module's own coordinates).
        far_pier False: no pier wall near the high-v wall (the deck rests on the wall there)."""
        self.det([(a, lo, TRIM - 40, b, hi, TRIM + 8)], MAT["beam"], top=MAT["quay_floor"])
        self.det([(a, lo, TRIM + 8, a + 16, hi, TRIM + 56), (b - 16, lo, TRIM + 8, b, hi, TRIM + 56),
                  (a + 48, lo + 112, F, b - 48, lo + 144, TRIM - 72)] + ([(a + 48, hi - 144, F, b - 48, hi - 112, TRIM - 72)] if far_pier else []), MAT["canal_wall"])
        self.det([(u, lo, TRIM - 72, u + 24, hi, TRIM - 40) for u in range(a + 40, b - 40, 96)], MAT["bars"])
        self.taken(a, lo, F, b, hi, TRIM + 56)
        self.blocked(a + 32, lo + 96, b - 32, lo + 160)
        if far_pier:
            self.blocked(a + 32, hi - 160, b - 32, hi - 96)


# ---------------------------------------------------------------------------
# The modules. Each paints its squares and puts its own things in; the banks, mud, trim, fence and path
# nodes come afterwards for the whole chain at once.
# ---------------------------------------------------------------------------

# What the canal's floor collects (the module review: "the canal's own junk, varied by a seed"): all of Half-Life 2.
CANAL_JUNK = ("models/props_junk/wood_crate001a.mdl", "models/props_junk/wood_pallet001a.mdl", "models/props_vehicles/tire001c_car.mdl",
              "models/props_c17/oildrum001.mdl", "models/props_junk/pushcart01a.mdl", "models/props_junk/trafficcone001a.mdl",
              "models/props_junk/cardboard_box001a.mdl", "models/props_junk/bicycle01a.mdl", "models/props_vehicles/carparts_tire01a.mdl",
              "models/props_c17/furniturewashingmachine001a.mdl", "models/props_junk/plasticcrate01a.mdl", "models/props_debris/wood_board06a.mdl")


def canal_grime(m, u1, u2, seed):
    """Grime on a plain stretch's floor between u1 and u2: a puddle, trash, a stain, where the water stands and the wind
    drops things (the same every build for one seed)."""
    rnd = random.Random(seed)
    for k in range(max(1, (u2 - u1) // 384)):
        u = rnd.randrange(u1 + 32, max(u1 + 33, u2 - 32))
        m.grime(rnd.choice(("puddle", "trash", "stain", "puddle")), u, rnd.randrange(-96, 96), F + 1, seed + k)


CITY_LEDGE, WIDE_LEDGE = (72, 208), (102, 320)      # a walk along a wall: how wide, how high over the floor (Valve: 72 at 212, 102 at 316)


def bank_hip(m, u, s, way, half=CANAL_W // 2):
    """Where a bank stops along a wall that goes on (where a walk's stretch begins): the bank's end sloped down to the
    floor at 45 degrees, BANK on into the stretch (way: 1 or -1 along u), not a cut end standing in the open.
    s: the wall (1 the left, -1 the right)."""
    wall, toe, c = s * half, s * (half - BANK), MAT["canal_wall"]
    w0, w1, t0, e = (u, wall, F), (u, wall, F + BANK), (u, toe, F), (u + way * BANK, wall, F)
    m.shapes([[([w0, w1, t0], c), ([w0, t0, e], c), ([w0, w1, e], c), ([w1, t0, e], c)]])
    m.blocked(min(u, u + way * BANK), min(wall, toe), max(u, u + way * BANK), max(wall, toe))


def walk_ledge(m, u0, u3, s, wide=False, stairs=2):
    """A walk along one wall (s: 1 the left, -1 the right) from u0 to u3, as Valve's canals have them (the owner, 21
    November): 72 wide and 208 up in the city canal, 102 wide and 320 up in the wide one, the city's handrail along its
    open edge; stairs up to it at its start, and at its end (stairs=2) or a rail across its far end (stairs=1), their
    open side solid and railed as the city's stairs are (map_mods_a.wall_stair). Its wall stands upright, so in the
    city canal the bank stops either side, its ends sloped down to the floor (bank_hip). Lamps on the wall over the
    walk, one in three dead. Builds nothing (and gives False) if anything of the module's is in its way."""
    from map_mods_c import cage_lamp, handrail
    half = (WIDE_W if wide else CANAL_W) // 2
    w, h = WIDE_LEDGE if wide else CITY_LEDGE
    wall, edge = s * half, s * (half - w)
    lo, hi = min(wall, edge), max(wall, edge)
    hip = 0 if wide else BANK
    run = 12 * (h // 8)
    a = u0 + hip                                         # the first stair's foot
    w1, w2 = a + run, u3 - hip - (run if stairs > 1 else 0)      # where the walk itself begins and ends
    if w2 - w1 < 128 or m.b.upper or m.fr.dz:
        return False
    reach = s * (half - (w if wide else BANK) - 8)
    r = m.fr.box(u0 - 16, min(reach, wall), F, u3 + 16, max(reach, wall), F + h + 80)

    def meets(t):
        return t[0] < r[3] and t[3] > r[0] and t[1] < r[4] and t[4] > r[1] and t[2] < r[5] and t[5] > r[2]
    vmf = m.b.vmf
    if (any(meets(bx) for bx, _ in vmf.boxes) or any(meets(bx) for bx in vmf.shape_boxes) or any(meets(t) for t in m.b.taken)
            or any(meets(p + p) for _, p in vmf.points)):
        m.b.notes.append("%s: no walk along its %s wall (something of its own is in the way)" % (m.tag, "left" if s > 0 else "right"))
        return False
    m.no_bank(u0, wall - 8, u3, wall + 8)
    if hip:
        bank_hip(m, u0, s, 1, half)
        bank_hip(m, u3, s, -1, half)
    for start, sign in [(a, 1)] + ([(u3 - hip, -1)] if stairs > 1 else []):
        m.steps(start, lo, hi, F, F + h, "u", sign)
        stair_rail(m, start, run, edge, h, sign, s)
        m.blocked(min(start, start + sign * run), lo - 16, max(start, start + sign * run), hi)
        m.lane(start - sign * 48, edge - s * 48)
    m.det([(w1, lo, F, w2, hi, F + h)], MAT["canal_wall"], top=MAT["quay_floor"])
    handrail(m, (w1, edge + s * 3), (w2 - (8 if stairs < 2 else 0), edge + s * 3), F + h)
    if stairs < 2:
        handrail(m, (w2 - 3, lo + (8 if s > 0 else 0)), (w2 - 3, hi - (0 if s > 0 else 8)), F + h)
    for k, u in enumerate(range(w1 + 160, w2 - 96, 512)):
        cage_lamp(m, u, wall, F + h + (88 if not wide else 24), 270 if s > 0 else 90, lit=k % 3 != 1)
    m.taken(u0, lo, F, u3, hi, F + h + 64)
    m.blocked(w1, lo - 16, w2, hi)
    m.lane((w1 + w2) // 2, (lo + hi) // 2, F + h)
    m.view(w1 - 200, edge - s * 120, F, 0, -10, "the walk along the %s wall" % ("left" if s > 0 else "right"))
    return True


def stair_rail(m, start, run, edge, h, sign, s):
    """A walk's stair: its open side (edge, the v of its canal side) solid from the floor, and the city's stair rail on
    it, handrail04_doublerise for each 128 it climbs and handrail04_singlerise for 64 (each 192 or 96 along, as these
    stairs climb 2 in 3), their origins set by hand at their middles as map_mods_a.wall_stair does."""
    from map_mods_a import tilted
    side = (edge - 8, edge) if s > 0 else (edge, edge + 8)
    m.stair_side(start, run, side[0], side[1], F, F + h, sign)
    rv = edge + 2 if s > 0 else edge - 2
    pieces = [("doublerise", 96, 88)] + ([("doublerise", 288, 216)] if h > 256 else []) + [("singlerise", 432 if h > 256 else 240, 312 if h > 256 else 184)]
    for kind, d, z in pieces:
        tilted(m, "prop_static", "models/props_c17/handrail04_%s.mdl" % kind, start + sign * d, rv, F + z, 270 if sign > 0 else 90)


def ledge_span(L, opt):
    """Where a plain stretch's walk can go: the longest part of 256 .. L-256 clear of a bridge or pipes over it."""
    cut = []
    if "bridge" in opt:
        cut.append((L // 2 - 192, L // 2 + 192))
    if "pipes" in opt:
        at = L // 4 if "bridge" in opt else L // 2
        cut.append((at - 192, at + 256))
    free, a = [], 256
    for c1, c2 in sorted(cut):
        if c1 > a:
            free.append((a, c1 // 64 * 64))
        a = max(a, -(-c2 // 64) * 64)
    if L - 256 > a:
        free.append((a, L - 256))
    best = max(free, key=lambda f: f[1] - f[0]) if free else None
    return best if best and best[1] - best[0] >= 832 else None


def m_straight(m, opt):
    """Plain canal. "straight 1536": that long. Add "bridge" for a street carried over its middle, "pipes" for a pair of
    pipes across it, "bare" for nothing left lying in it (otherwise a few odds and ends from CANAL_JUNK, the same every
    time for one place: crates, tyres, a cart, a cone, a bicycle, a washing machine). Puddles and trash on the floor; a
    quiet courtyard's soundscape (wind and the city over the walls). The walls' caged lamps, outfalls, drain stains and
    graffiti come with every canal (dress_canal_walls). From 1536 long a walk along the left wall (walk_ledge: 72 wide,
    208 up, stairs at each end where it is long enough; "flip" puts it on the right, "noledge" leaves it out), clear
    of a bridge or pipes."""
    L = m.fr.length
    m.open(0, -256, L, 256)
    x, y = m.fr.pt(0, 0)
    seed = 1000 + (x * 7 + y * 13) % 997
    span = ledge_span(L, opt) if L >= 1536 and "bare" not in opt and "noledge" not in opt else None
    if span:
        walk_ledge(m, span[0], span[1], 1, stairs=2 if span[1] - span[0] >= 1408 else 1)
    if "bridge" in opt:
        m.bridge(L // 2 - 128, L // 2 + 128, -256, 256)
        m.grime("stain", L // 2, -112, F + 150, seed)           # (water off the deck, down its pier's face)
    if "pipes" in opt:
        at = L // 4 if "bridge" in opt else L // 2
        (x1, y1), (x2, y2) = m.fr.pt(at, -256), m.fr.pt(at, 256)
        m.b.pipes.append(("x", x1, min(y1, y2), max(y1, y2)) if m.fr.ax("u") == "x" else ("y", y1, min(x1, x2), max(x1, x2)))
    if "bare" not in opt and L >= 512:
        m.scatter(64, -110, L - 64, 110, L // 420, seed, kinds=CANAL_JUNK)
    canal_grime(m, 0, L, seed)
    m.soundscape(SCAPES["courtyard"], L // 2, 0, F, radius=max(768, L // 2))


def m_shed(m, opt):
    """Plain canal, and on the street beside it a brick shed over the tracks, where a train waits out of sight. A
    straight run needs two for a train: one to come out of, one to go into. Only where the layout has a street
    ("upper left"). "shed 2304": that long (by itself it is the length of the train and a little over)."""
    m.open(0, -256, m.fr.length, 256)
    if not m.b.upper:
        m.b.problems.append("%s: a shed needs a street to stand on: add a line \"upper left\" or \"upper right\" to the layout" % m.tag)


def m_corner(m, opt):
    if "wide" in opt:      # (a turn in the wide canal: 1024 square, its walls upright as the wide canal's are)
        m.open(0, -512, 1024, 512)
        m.upright(-64, -576, 1088, 576)
        return
    m.open(0, -256, 512, 256)


def widths(name):
    """How wide a module is where it starts and where it ends: (512, 512) for all but the wide canal's own."""
    info = MODULES.get(name)
    return info[3].get("width", (CANAL_W, CANAL_W)) if info and len(info) > 3 else (CANAL_W, CANAL_W)


def alone(name, opt=()):
    """A module by itself, as a layout's lines: with a widening before it and a narrowing after it where it is wide."""
    w_in, w_out = widths(name)
    return ([["widen"]] if w_in > CANAL_W else []) + [[name] + list(opt)] + ([["narrow"]] if w_out > CANAL_W else [])


def jog_shift(opt):
    n = [int(w) for w in opt if w.lstrip("-").isdigit()]
    return (n[0] if n else 768) * (-1 if "right" in opt else 1)


def m_jog(m, opt):
    """The canal steps sideways, to break a long view: "jog left 768" (the default), "jog right 1024". What the floods
    leave in the elbow (two things from CANAL_JUNK), puddles and trash, the courtyard's soundscape."""
    s = jog_shift(opt)
    m.open(0, -256, 768, 256)
    m.open(256, min(-256, s - 256), 768, max(256, s + 256))
    m.open(256, s - 256, 1024, s + 256)
    x, y = m.fr.pt(0, 0)
    seed = 2000 + (x * 7 + y * 13) % 997
    m.scatter(320, s // 2 - 96, 704, s // 2 + 96, 2, seed, kinds=CANAL_JUNK)      # (in the elbow, where the flood leaves things)
    canal_grime(m, 256, 768, seed)
    m.soundscape(SCAPES["courtyard"], 512, s // 2, F, radius=900)


def m_tee(m, opt):
    """A way off to the left: a standard gate in the left wall (512 wide, 256 high), capped until another piece, or
    another layout's start, is joined to it. A number painted beside the gate, puddles and trash, the courtyard's
    soundscape."""
    b = m.b
    m.open(0, -256, 512, 256)
    m.low(0, 256, 512, 512, F + GATE_HIGH)
    gate_cap(b.vmf, m.fr.box(0, 448, F, 512, 512, F + GATE_HIGH), m.fr.box(0, 424, F, 512, 432, F + GATE_HIGH), m.fr.ax("u"),
             "%s: %s side gate's cap (delete to join)" % (b.vis, m.tag))
    m.portal(0, 382, F, 512, 384, F + GATE_HIGH)
    b.plan.keep_out.append(m.fr.rect(-64, 512, 576, 576))
    m.blocked(0, 384, 512, 512)
    m.side(0, 256, 512, 512)
    x, y = m.fr.pt(0, 0)
    canal_grime(m, 0, 512, 3000 + (x * 7 + y * 13) % 997)
    m.grime("number", 512, 320, F + 180, x + y)               # (a number on the gate's cheek, where the side way leaves)
    m.soundscape(SCAPES["courtyard"], 256, 0, F, radius=768)
    dx, dy = m.fr.way(90)
    b.notes.append("%s: its side gate is at (%d %d), heading %s: a layout may start there" % ((m.tag,) + m.fr.pt(256, 512) + ({(1, 0): "E", (0, 1): "N", (-1, 0): "W", (0, -1): "S"}[(dx, dy)],)))


def m_gate(m, opt):
    """The culvert a chain ends in: the same gate as every piece's (512 wide, 256 high), capped until something is joined."""
    b = m.b
    m.low(0, -256, 256, 256, F + GATE_HIGH)
    gate_cap(b.vmf, m.fr.box(0, -256, F, 64, 256, F + GATE_HIGH), m.fr.box(80, -256, F, 88, 256, F + GATE_HIGH), m.fr.ax("v"),
             "%s: %s gate's cap (delete to join)" % (b.vis, opt[0] if opt else "a"))
    m.portal(128, -256, F, 130, 256, F + GATE_HIGH)
    # (nothing of this piece beyond the gate's plane, where the next piece begins; beside a street only the culvert's own width,
    #  since the street needs its end wall)
    b.plan.keep_out.append(m.fr.rect(-64, -256, 0, 256) if b.upper else m.fr.rect(-64, -448, 0, 448))
    m.blocked(0, -256, 128, 256)


def m_drain(m, opt):
    """1. The storm drain junction: a way from the canal down into the city's sewers. In the left wall a drain's mouth
    with a concrete collar and an arched roof, caged lamps along its wall; a junction chamber round a sump of standing
    water behind the city's handrail (steps down into it at one corner, a lost case at its bottom), two inflow pipes
    (concrete pipes out of the side walls, water running from them into the sump), a standing valve, a run of the
    city's pipes along each side wall, a lamp each end; then thirteen steps down to the sewers' height (z 288), a lamp
    at their foot, a grate (the canals' own bar panels, four of them), and beyond it the start of the owner's sewer: a
    channel of dark water between two walks under a round arch, to a cap to delete where the owner joins it to a sewer
    of theirs (their sewers: water about z 267 to 291 in a channel, walks either side, round-arched mouths).
    Grime: drain stains under the inflow pipes, stains down the walls, trash in the corners, a number by the valve, and
    the lambda by the head of the stair (the Resistance's way down, as Half-Life 2 marks its routes).
    Along the right wall a walk (walk_ledge: 72 wide, 208 up, the city's handrail on it, stairs at its near end, its
    far end railed), the bank stopping either side of it in slopes: the drain's keepers' way along the canal.
    Named for the game: lc_drain_grate (a func_door: Open lifts it, Close drops it; unseen, the four bar panels riding
    on it), lc_drain_junction (the chamber), lc_drain_cache (the case at the bottom of the sump: a place the game can
    fill).
    Left as brushes: the mouth, its collar and arch, the chamber, the sump and its steps, the plugs that darken the
    inflow pipes' insides, the stair, the sewer channel's walks and arch, the sewer end's cap.
    Unchecked: ambient/water/water_flow_loop1.wav, ambient/water/drip_loop1.wav; the water running from the pipes is an
    env_steam aimed down and out (as the owner's map aims its jets: Half-Life 2 has no falling-water material), how it
    reads is not seen; that the concrete pipe is open at both ends (a dark plug closes its back, against the wall)."""
    from map_build import bar_row
    from map_mods_b import cage
    from map_mods_c import centred, handrail, pipe_run, pour, round_arch
    b = m.b
    m.open(0, -256, 1024, 256)
    m.low(384, 256, 640, 768, F + 192)                       # the mouth and its pipe
    m.low(256, 768, 768, 1280, F + 256)                      # the junction chamber...
    m.low(384, 896, 640, 1152, F + 256, floor=F - 64)        # ...and the sump in its middle
    m.low(384, 1280, 640, 1536, SEWER + 240, floor=SEWER)    # down to the sewers
    CH = SEWER - 40                                          # the sewer channel's floor; its water's top 2 under the walks
    m.low(384, 1536, 448, 1664, SEWER + 240, floor=SEWER)    # the walks either side of the channel...
    m.low(576, 1536, 640, 1664, SEWER + 240, floor=SEWER)
    m.low(448, 1536, 576, 1664, SEWER + 240, floor=CH)       # ...and the channel
    m.side(256, 256, 768, 1664)
    m.portal(384, 318, F, 640, 320, F + 192)
    m.det([(368, 240, F, 386, 256, F + 192), (638, 240, F, 656, 256, F + 192), (368, 240, F + 192, 656, 256, F + 208)], MAT["beam"])   # (the posts 2 into the mouth: the banks' ends hide in them)
    m.shapes([prism([(384, F + 192), (384, F + 128), (448, F + 192)], "y", 256, 768, MAT["canal_wall"]),
              prism([(640, F + 192), (640, F + 128), (576, F + 192)], "y", 256, 768, MAT["canal_wall"])])
    m.taken(360, 232, F, 664, 256, F + 216)
    for v in (432, 656):                                     # caged lamps along the mouth's left wall, under its chamfer
        cage(m, 384, v, F + 96, 0, "238 226 162 45")
    m.grime("stain", 640, 520, F + 90, 1)
    m.grime("puddle", 512, 600, F + 1, 2)
    # the chamber: the sump, its rails and its steps, the inflow pipes pouring into it
    m.water(384, 896, 640, 1152, F - 64, F - 40)
    m.steps(1056, 392, 440, F - 64, F, "v", 1)               # (four steps up the sump's corner to the chamber's floor)
    for a, e in (((384, 894), (640, 894)), ((448, 1154), (640, 1154)), ((382, 896), (382, 1152)), ((642, 896), (642, 1152))):
        handrail(m, a, e, F)                                 # (round the sump, on the chamber's floor; open over its steps)
    m.static("models/props_c17/suitcase001a.mdl", 560, 960, 35, z=F - 64)     # a case someone lost down there
    m.target("lc_drain_cache", 560, 960, F - 56, 90)
    for u, s in ((256, 1), (768, -1)):                       # the inflow pipes: concrete pipes out of the side walls, their backs against the walls
        centred(m, "models/props_pipes/concrete_pipe001a.mdl", u + s * 56, 1024, 0, F + 150)    # (lit from the room), a dark plug in each at the wall
        m.shapes([prism(octagon(1024, F + 150, 38), "x", min(u, u + s * 3), max(u, u + s * 3), MAT["black"])])
        pour(m, u + s * 108, 1024, F + 112, length=90, yaw=0 if s > 0 else 180, pitch=50)       # (out of the mouth's lip, down into the sump)
        m.grime("drain", u, 1024, F + 70, u)
        m.grime("stain", u, 930, F + 170, u + 1)
        pipe_run(m, (u + s * 6, 768), (u + s * 6, 1280), F + 228)                              # the city's pipes along the side wall, wall to wall
    m.sound("ambient/water/water_flow_loop1.wav", 512, 1024, F, radius=600, volume=3)
    m.static("models/props_pipes/valve002.mdl", 320, 787, 90, z=F)
    m.grime("number", 320, 768, F + 130, 3)
    m.grime("trash", 290, 1240, F + 1, 4)
    m.grime("trash", 736, 800, F + 1, 5)
    m.grime("stain", 720, 1280, F + 170, 6)
    m.grime("lambda", 330, 1280, F + 84, 7)                  # (beside the head of the stair: the way down)
    m.lamp(512, 840, F + 214, "190 210 170 70", hang=34)
    m.lamp(512, 1216, F + 214, "190 210 170 40", hang=34)
    m.target("lc_drain_junction", 512, 832, F + 8, 90)
    m.soundscape(SCAPES["tunnel"], 512, 1024, F, radius=640)
    run = m.steps(1280 + 12 * 13, 384, 640, SEWER, F - 8, "v", -1)   # 13 steps, tops z 392 down to 296
    m.blocked(384, 1280, 640, 1280 + run + 16)
    m.blocked(384, 896, 640, 1152)
    m.lane(512, 1264, F)
    m.lane(512, 1280 + run + 48, SEWER)
    for u, v in ((320, 832), (320, 1024), (320, 1216), (704, 1024)):
        m.lane(u, v)
    cage(m, 384, 1490, SEWER + 110, 0, "238 226 162 40")     # a lamp at the stair's foot, to see the grate by
    m.grime("stain", 640, 1470, SEWER + 150, 8)
    b.vmf.brush_entity("func_door", {"targetname": "lc_drain_grate", "movedir": "-90 0 0", "speed": "30", "lip": "24", "wait": "-1", "spawnflags": "32",
                                     "spawnpos": "0", "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0",
                                     "noise1": "MetalGrate.ScrapeSmooth", "noise2": "MetalGrate.ImpactSoft", "renderamt": "0", "rendercolor": "255 255 255",
                                     "renderfx": "0", "rendermode": "10", "disableshadows": "1"}, [m.fr.box(384, 1544, CH, 640, 1552, SEWER + 240)], MAT["nodraw"], m.dv)
    b.names.append(("lc_drain_grate", "func_door", m.tag))
    from map_mods_c import ride
    for gu in (448, 576):                                    # the canals' bar panels (128 by 124), two by two: the top pair's heads go 8 into the roof
        for gz in (SEWER, SEWER + 124):                      # (under the walks' height the channel's dark water hides the rest; the unseen door reaches its floor)
            ride(m, "lc_drain_grate", "models/props_canal/canal_bars002.mdl", gu, 1548, 0, gz)
    m.test_button((384, 1500, SEWER + 48, 392, 1516, SEWER + 64), [("OnIn", "lc_drain_grate", "Open"), ("OnOut", "lc_drain_grate", "Close")])
    # beyond the grate the start of the owner's sewer: dark water in a channel, a walk each side, a round arch over it
    b.vmf.world_box(m.fr.box(448, 1552, CH, 576, 1640, SEWER - 2), MAT["nodraw"], top="nature/sewer_waterdarkfog2", vis=b.vis + ": water and sludge", seals=False)
    round_arch(m, 384, 640, SEWER + 112, 1556, 1640, axis="y")
    m.det([(440, 1552, CH, 448, 1640, SEWER + 4), (576, 1552, CH, 584, 1640, SEWER + 4)], MAT["beam"])      # the walks' kerbs over the water
    m.sound("ambient/water/drip_loop1.wav", 512, 1600, SEWER + 40, radius=500, volume=4)
    m.soundscape(SCAPES["watery"], 512, 1500, SEWER, radius=400)
    m.world((384, 1640, CH, 640, 1664, SEWER + 240), MAT["black"], vis="%s: the drain's sewer end (delete to join a sewer)" % b.vis)
    b.plan.keep_out.append(m.fr.rect(320, 1664, 704, 1728))
    m.blocked(384, 1536, 640, 1664)
    m.static("models/props_junk/wood_pallet001a.mdl", 300, 1230, 20)
    m.static("models/props_c17/oildrum001.mdl", 720, 1230, 0)
    m.loose("models/props_junk/wood_crate001a.mdl", 716, 820, 30)
    m.view(512, 60, F, 90, 0, "the mouth")
    m.view(512, 790, F, 90, 6, "the chamber")
    m.view(320, 1230, F, 20, 12, "to the steps")
    m.view(512, 1470, SEWER, 90, 0, "the grate and the sewer beyond")
    b.notes.append("%s: the sewer end is at %s, the walks z %d and the channel's floor z %d (its water to z %d), 256 wide and 240 high: move or stretch it to a sewer of the map's, then delete its cap" % (
        m.tag, "(%d %d)" % m.fr.pt(512, 1664), SEWER, CH, SEWER - 2))
    walk_ledge(m, 64, 960, -1, stairs=1)      # (the maintenance walk opposite the drain's mouth: Valve's canal, 21 November)


def m_overflow(m, opt):
    """2. The overflow toward Ravenholm. A spillway in the left wall, its apron stepping down into the canal, shut by a
    steel sluice plate on two lifting rods under two of the canal's winches on a ledge, a chain and padlock slung
    between the winches, caged red lamps either side, danger signs and rust stains on the wall; a lever on the wall
    by it, padlocked like the winches until the game unlocks it. Driftwood (the coast's own), a pallet and two bodies
    lie against the plate. Behind the plate a ribbed channel runs on to a cap ("delete to join Ravenholm"), a shallow
    strip of water down its middle (where the channel is long enough), and it says Ravenholm the moment the plate lifts: Half-Life 2's own Ravenholm sign
    on its wall, blood on the walls and the floor, a headcrab canister come through its roof, a zombie's torso and a
    burnt body under it, a wheelbarrow on its side, rags; one oil lamp still burning low, one caged lamp dead.
    "overflow 1280": how far the channel reaches from the canal's middle (default 1024).
    Along the right wall a walk (walk_ledge: 72 wide, 208 up, the city's handrail on it, stairs at its near end, its
    far end railed), the bank stopping either side of it in slopes: where the sluice keepers watch the plate.
    Named for the game: lc_overflow_sluice (a func_door: Open lifts it), lc_overflow_moan (a sound from beyond the
    plate, silent until told: PlaySound), lc_overflow_far (the channel's far end), lc_overflow_lever (the lever by the
    plate, a button that starts locked: Unlock lets players lift and drop the plate by hand, Lock takes it back;
    lc_overflow_lift and lc_overflow_drop are its two relays, taking turns).
    Left as brushes: the weir, its sill, apron and frame, the ledge the winches stand on, the channel and its ribs, and
    the sluice plate with its rods (a slab of steel 384 wide and 176 high: no model is a plate that size; the canals'
    bar panels are bars, and stacked to that height they would rise out over the wall's top when it lifts).
    Unchecked: ambient/creatures/town_zombie_call1.wav, models/humans/charple02.mdl, the zombie torso as a ragdoll, the
    chain's material (cable/chain.vmt) on a rope; which way winch02 and the Ravenholm sign face."""
    from map_mods_c import cage_lamp, toggle
    reach = int(opt[0]) if opt and opt[0].isdigit() else 1024
    steel = MM["steel"]
    m.open(0, -256, 1024, 256)
    m.low(320, 256, 704, 640, F + 192)
    m.low(384, 640, 640, reach, F + 192)
    wet = reach - 128 >= 832                                          # (a strip of water down the channel, where it is long enough for one)
    if wet:
        m.low(448, 704, 576, reach - 128, F + 192, floor=F - 16)    # the strip the overflow still runs in
    m.side(320, 256, 704, reach)
    m.det([(320, 256, F, 704, 272, F + 16), (320, 208, F, 704, 256, F + 12), (320, 160, F, 704, 208, F + 6)], MAT["beam"])      # the weir's sill and apron
    m.door("lc_overflow_sluice", [(320, 288, F + 16, 704, 304, F + 192), (440, 293, F + 192, 446, 299, F + 280), (578, 293, F + 192, 584, 299, F + 280)],
           steel, "-90 0 0", speed=24, lip=104)
    m.portal(320, 295, F, 704, 297, F + 192)
    m.test_button((304, 240, F + 48, 320, 248, F + 64), [("OnIn", "lc_overflow_sluice", "Open"), ("OnOut", "lc_overflow_sluice", "Close")])
    m.det([(304, 248, F, 322, 256, F + 208), (702, 248, F, 720, 256, F + 208), (304, 248, F + 208, 720, 256, F + 224)], steel)   # its frame (the banks' ends hide in its posts)
    m.det([(408, 200, F + 232, 616, 256, F + 240)], MAT["beam"])                                                                # the ledge for the winches
    for u in (443, 581):                                                                                                          # a winch over each rod
        m.static("models/props_canal/winch02.mdl", u, 226, 270, z=F + 240)
    keys = {"Slack": "40", "Type": "0", "Subdiv": "2", "Barbed": "0", "Width": "2", "TextureScale": "1", "Collide": "0", "Dangling": "0", "Breakable": "0",
            "RopeMaterial": "cable/chain.vmt", "MoveSpeed": "64", "PositionInterpolator": "2", "NoWind": "1"}
    m.b.vmf.point("move_rope", m.fr.at(458, 226, F + 268), dict(keys, targetname="lc_overflow_chain_a", NextKey="lc_overflow_chain_b"), m.b.vis + ": ropes")
    m.b.vmf.point("keyframe_rope", m.fr.at(566, 226, F + 268), dict(keys, targetname="lc_overflow_chain_b"), m.b.vis + ": ropes")
    m.static("models/props_wasteland/prison_padlock001a.mdl", 512, 226, 0, z=F + 241)          # (its lock lies on the ledge under the chain's sag)
    m.taken(296, 200, F, 728, 256, F + 312)
    for u in (280, 744):                                     # caged lamps either side, lit red
        cage_lamp(m, u, 256, F + 224, 270, "255 60 40 30")
        m.glow(u, 245, F + 234, "255 50 30", 0.25)
    toggle(m, "lc_overflow_lift", "lc_overflow_drop", 780, 200, F + 200, [("lc_overflow_sluice", "Open", "", 0)], [("lc_overflow_sluice", "Close", "", 0)], 8)
    m.button("lc_overflow_lever", 780, 256, F + 136, 270, [("lc_overflow_lift", "Trigger", "", 0), ("lc_overflow_drop", "Trigger", "", 0)], wait="8")
    m.taken(760, 236, F + 120, 800, 256, F + 180)
    m.static("models/props_wasteland/prison_padlock001a.mdl", 780, 246, 0, z=F + 120)          # (its padlock, hung under it)
    for kind, u, z, seed in (("danger", 264, F + 150, 1), ("danger", 760, F + 190, 2), ("stain", 380, F + 236, 3), ("stain", 650, F + 236, 4), ("number", 512, F + 290, 5)):
        m.grime(kind, u, 256, z, seed)
    # behind the plate: Ravenholm's threshold
    if wet:
        m.water(448, 704, 576, reach - 128, F - 16, F - 4)
    for v in range(704, reach - 64, 128):                    # the channel's ribs
        m.det([(384, v, F + 176, 640, v + 16, F + 192), (384, v, F, 392, v + 16, F + 176), (632, v, F, 640, v + 16, F + 176)], MAT["beam"])
    m.world((384, reach - 64, F, 640, reach, F + 192), MAT["black"], vis="%s: the overflow's far end (delete to join Ravenholm)" % m.b.vis)
    m.b.plan.keep_out.append(m.fr.rect(320, reach, 704, reach + 64))
    m.blocked(384, reach - 128, 640, reach)
    m.blocked(320, 144, 704, 320)
    back = reach - 64                                                                          # (the cap's face; with a short reach the things stand in the room behind the plate)

    def V(d):
        return max(330, back - d)

    def wall(v, left=True):
        return (320 if left else 704) if v < 640 else (384 if left else 640)
    sv = V(220)
    m.static("models/props_junk/ravenholmsign.mdl", wall(sv) + 11, sv, 0, z=F + 96)            # (nailed to the left wall, facing across)
    cu, cv = 560, V(330)                                                                       # the canister, nose down through the roof
    m.point("prop_static", cu, cv, F + 176, {"model": "models/props_combine/headcrabcannister01a.mdl", "angles": "55 %d 0" % m.fr.yaw(250), "skin": "0", "solid": "6",
                                             "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, m.pv)
    m.static("models/props_debris/concrete_chunk01a.mdl", 590, cv - 40, 30, z=F)
    m.static("models/props_debris/broken_pile001a.mdl", 576, cv + 50, 120, z=F)
    m.body("models/zombie/classic_torso.mdl", 470, cv - 20, 200, z=F)
    m.body("models/humans/charple02.mdl", 430, V(450), 80, z=F)
    m.prop("prop_physics", "models/props_junk/wheebarrow01a.mdl", 606, V(520), 0, F + 24, {"spawnflags": "0", "angles": "0 %d 85" % m.fr.yaw(100)})
    for k, (left, d, z) in enumerate(((True, 380, F + 60), (False, 300, F + 40), (None, 400, F + 1), (None, 350, F + 1), (False, 200, F + 70))):
        v = V(d)
        u = 512 if left is None else wall(v, left)
        m.decal("decals/bloodstain_%s" % ("001", "002", "003", "101", "201")[k], u, v, z)
    lv = V(260)
    m.static("models/props_c17/lamp001a.mdl", wall(lv) + 26, lv, 30, z=F)                     # the one lamp still burning, low
    m.glow(wall(lv) + 26, lv, F + 14, "255 190 110", 0.12)
    m.light(wall(lv) + 26, lv, F + 24, "255 170 90 14")
    dv = V(60)
    cage_lamp(m, wall(dv, False), dv, F + 140, 180, lit=False)                                # (a dead one on the wall)
    m.sound("ambient/creatures/town_zombie_call1.wav", 512, reach - 96, F + 60, radius=1400, volume=8, name="lc_overflow_moan", on=False)
    m.target("lc_overflow_far", 512, reach - 80, F + 8, 270)
    m.soundscape("d1_town.HeadcrabCave", 512, V(300), F, radius=420)                     # (Ravenholm's own: the owner's map uses it)
    m.soundscape(SCAPES["courtyard"], 512, -60, F, radius=600)
    # what the flood left against the plate
    m.static("models/props_debris/concrete_chunk01a.mdl", 250, 96, 40, z=F + 4)
    m.static("models/props_debris/broken_pile001a.mdl", 780, 96, 200, z=F + 4)
    m.static("models/props_foliage/driftwood_03a.mdl", 500, 190, 10, z=F + 6)
    m.static("models/props_foliage/driftwood_03a.mdl", 596, 176, 160, z=F + 6)
    m.loose("models/props_junk/wood_pallet001a.mdl", 690, 70, 25, z=F + 12)
    m.body("models/humans/charple02.mdl", 520, 420, 70)
    m.body("models/humans/charple02.mdl", 470, 60, 200)
    m.decal("decals/decalstain002a", 512, 100, F + 1)
    m.lane(512, 60)
    m.lane(512, 480)
    m.view(512, -120, F, 90, -6, "the sluice")
    m.view(512, 560, F, 270, 0, "behind the plate")
    m.view(512, 680, F, 90, 0, "toward Ravenholm")
    m.b.notes.append("%s: the overflow's far end is at (%d %d), floor z %d, 256 wide and 192 high" % ((m.tag,) + m.fr.at(512, reach, F)))
    walk_ledge(m, 64, 960, -1, stairs=1)      # (the sluice keepers' walk along the opposite wall: Valve's canal, 21 November)


def m_shanty(m, opt):
    """4. The shantytown under a street bridge. The canal widens into a basin on its left; a boardwalk runs along the
    basin's back, with three shacks on it built from pieces (map_mods_c.shack: corner posts, walls of mismatched sheets
    of wood, tin, steel hull and a salvaged door, uneven tops, tin roofs sloping to the front and overhanging on posts of
    their own, a window each, boarded or of cracked glass): a card room (a table, two chairs, a radio on the table, the
    canals' own map on the back wall, a lantern), a trader's stall open at the front (a long table for its counter,
    shelves on its back wall with jars and cans, a painted board over it, a cart and crates outside) and a bunk room
    (two bed frames, mattresses on them, a crate with a lantern between them). Under the street between them, a fire drum
    with seats round it and a stove with its chimney pipe. A plank fence against the wind at the basin's edge east of the
    street; a string of bulbs on a cable from an old dock pole to the bridge's deck and on to a second pole; washing on a
    line from the card room's roof post to a pole; a boat pulled up; a cork notice board on two poles; posters on and in
    the card room, the lambda on the bridge's pier, trash and puddles on the basin's floor. In front of the card room the
    basin's floor is left clear for the Resistance's flag.
    Named for the game (places only): lc_shanty_cards (the card room's table), lc_shanty_fund (the stall, for the fund's
    screen), lc_shanty_soup (under the street, for the soup), lc_shanty_fire (the drum), lc_shanty_board (the notices),
    lc_hq_setup_shanty (where the game stands the Resistance's flagpole when a territory covers the shanty town: the
    basin's open floor, 64 clear all round, open to the sky).
    Left as brushes: the boardwalk, the shacks (sheets, posts, roofs: no model is a shack's wall), the board over the
    stall, the washing on the line (no game has a model of clothes on a line), the street bridge.
    Unchecked: ambient/fire/fire_small_loop2.wav, env_smokestack, the cables (move_rope), sprites/light_glow03.vmt;
    where on prison_bedframe001b a mattress lies (the mattresses are loose: they fall onto the frames)."""
    from map_mods_c import shack
    from map_mods_b import fire, mattress
    wood, beam = MM["wood"], "wood/woodfloor006b"
    m.open(0, -256, 1536, 256)
    m.open(256, 256, 1280, 640)
    m.no_bank(256, 400, 1280, 648)
    m.bridge(640, 896, -256, 640, far_pier=False)
    # the boardwalk the shacks stand on, and its kerb
    m.det([(264, 400, F, 632, 632, F + 8), (904, 400, F, 1272, 632, F + 8)], wood)
    m.det([(264, 388, F, 632, 400, F + 5), (904, 388, F, 1272, 400, F + 5)], beam)
    m.side(256, 384, 640, 640)                                            # (no mud under the boardwalk)
    m.side(896, 384, 1280, 640)
    z = F + 8
    # the card room
    shack(m, 272, 440, 520, 632, z, 41, window="boards")
    m.static("models/props_c17/furnituretable002a.mdl", 396, 560, 0, z=z)
    m.static("models/props_c17/furniturechair001a.mdl", 340, 560, 0, z=z)
    m.static("models/props_c17/furniturechair001a.mdl", 452, 560, 180, z=z)
    m.dynamic("models/props_lab/citizenradio.mdl", 396, 584, 270, z=z + 37)
    m.static("models/props_canal/canalmap001.mdl", 330, 625, 270, z=z + 30)                 # (the canals' own map, on the back wall)
    m.static("models/props_c17/lamp001a.mdl", 410, 540, 0, z=z + 37)
    m.glow(410, 540, z + 50, "255 190 110", 0.12)
    m.light(410, 540, z + 70, "255 180 100 40")
    m.light(470, 600, z + 92, "255 170 90 18")
    m.target("lc_shanty_cards", 396, 560, z + 36)
    m.decal("decals/decalposter014a", 300, 438, z + 64)
    m.decal("decals/decal_posters005a", 330, 438, z + 66)
    m.grime("poster", 470, 626, z + 60, 11)
    # the trader's stall: open at the front, a painted board over it, a cart and crates outside
    shack(m, 912, 456, 1088, 632, z, 42, window=None, open_front=True, roof="metal/metalroof004a")
    m.static("models/props_wasteland/cafeteria_table001a.mdl", 1000, 486, 90, z=z)
    for k, su in enumerate((960, 1032)):                                  # shelves on the back wall, what is for sale on them
        for sz in (z + 44, z + 74):
            m.static("models/props_c17/furnitureshelf001b.mdl", su, 616, 270, z=sz)
        m.static(("models/props_junk/glassjug01.mdl", "models/props_lab/jar01a.mdl")[k], su - 10, 616, 0, z=z + 46)
        m.static(("models/props_junk/metal_paintcan001a.mdl", "models/props_junk/garbage_glassbottle001a.mdl")[k], su + 8, 616, 0, z=z + 76)
    m.static("models/props_junk/wood_crate001a.mdl", 950, 560, 15, z=z)
    m.static("models/props_c17/lamp001a.mdl", 950, 560, 0, z=z + 40)
    m.glow(950, 560, z + 53, "255 190 110", 0.12)
    m.light(1000, 540, z + 70, "255 180 100 40")
    m.det([(930, 452, z + 92, 1070, 455, z + 110)], "wood/woodwall006a")             # the board over the stall
    m.grime("graffiti", 1000, 452, z + 101, 12)
    m.static("models/props_junk/pushcart01a.mdl", 868, 446, 90)                   # (beside the stall, under the bridge's edge)
    m.loose("models/props_junk/wood_crate001a.mdl", 1068, 418, 20, z=z)
    m.target("lc_shanty_fund", 1000, 560, z + 48, 270)
    # the bunk room
    shack(m, 1104, 432, 1272, 632, z, 43, window="glass")
    for bu in (1146, 1230):
        m.static("models/props_wasteland/prison_bedframe001b.mdl", bu, 572, 90, z=z)
        mattress(m, bu, 572, 90, z=z + 30)
    m.static("models/props_junk/wood_crate001a.mdl", 1188, 606, 0, z=z)
    m.static("models/props_c17/lamp001a.mdl", 1188, 606, 0, z=z + 40)
    m.glow(1188, 606, z + 53, "255 190 110", 0.12)
    m.light(1188, 560, z + 80, "255 180 100 30")
    # under the street: the fire drum and seats, the stove and its pipe, a table for the soup
    m.static("models/props_c17/oildrum001.mdl", 768, 400, 0)
    fire(m, 768, 400, F + 45, size=28, drop=False)                        # (it burns in the drum: an env_fire drops to the ground unless told not to)
    m.sound("ambient/fire/fire_small_loop2.wav", 768, 400, F + 50, radius=500, volume=5)
    m.smoke(768, 400, F + 60, size=10, length=120, rate=8)
    m.target("lc_shanty_fire", 768, 400, F + 8)
    for u, v, yaw in ((700, 360, 20), (830, 350, 150), (760, 480, 260)):
        m.static("models/props_junk/wood_crate001a.mdl", u, v, yaw)
    m.static("models/props_c17/furniturecouch001a.mdl", 690, 596, 270)
    m.static("models/props_c17/furniturestove001a.mdl", 856, 604, 270)
    m.static("models/props_rooftop/chimneypipe01b.mdl", 856, 618, 0, z=F + 40)          # its pipe, up from its top, capped, under the street's deck
    m.static("models/props_c17/furnituretable001a.mdl", 780, 560, 0)
    m.target("lc_shanty_soup", 780, 560, F + 40)
    m.blocked(660, 520, 890, 640)
    m.blocked(690, 340, 840, 490)
    m.grime("lambda", 768, -112, F + 130, 13)                             # (on the bridge's pier, facing the basin)
    m.grime("graffiti", 720, -112, F + 70, 14)
    # a plank fence against the wind at the basin's edge east of the street (west of it the floor is the flag's), clear
    # of the bank against the basin's end wall
    m.static("models/props_wasteland/wood_fence01a.mdl", 965, 266, 0, z=F)
    m.static("models/props_wasteland/wood_fence02a.mdl", 1062, 266, 0, z=F)
    m.blocked(892, 248, 1102, 284)
    # a string of bulbs: from a dock pole over the east basin to the bridge's deck, and on to a second pole
    poles = [(916, 330), (1136, 330)]
    for u, v in poles:
        m.static("models/props_docks/dock01_pole01a_128.mdl", u, v, 0)
    m.rope([(1136, 330, F + 124), (916, 330, F + 124), (896, 330, TRIM - 44)], slack=24)
    for u, zz in ((1082, F + 112), (1026, F + 108), (970, F + 112)):
        m.glow(u, 330, zz, "255 214 150", 0.14)
    m.light(1026, 330, F + 96, "255 190 120 30")
    # washing on a line from the card room's roof post to a pole by the notice board
    m.rope([(264, 414, z + 108), (563, 270, F + 120)], slack=2, width=1)
    for k, (t, w, h, mat) in enumerate(((0.25, 22, 30, "props/carpetfloor003a"), (0.45, 16, 24, "props/carpetfloor004a"), (0.65, 26, 34, "props/carpetfloor008a"))):
        cu, cv = int(264 + (563 - 264) * t), int(414 + (270 - 414) * t)
        cz = int(z + 108 + (F + 120 - z - 108) * t)
        m.det([(cu - w // 2, cv - 1, cz - h, cu + w // 2, cv + 1, cz - 1)], mat)
    # the Resistance's flag, when a territory covers the shanty town: the open floor in front of the card room
    m.target("lc_hq_setup_shanty", 480, 330, F, 90)
    # a boat pulled up, a notice board on two poles, what is left lying
    m.static("models/props_canal/boat001a.mdl", 1360, 60, 15)
    m.blocked(1240, -40, 1480, 160)
    for u in (563, 629):
        m.static("models/props_docks/dock01_pole01a_128.mdl", u, 270, 0)
    m.static("models/props_lab/corkboard001.mdl", 596, 262, 270, z=F + 60)
    m.target("lc_shanty_board", 596, 240, F + 8, 90)
    m.scatter(920, 280, 1130, 380, 3, 12)
    m.static("models/props_junk/wood_crate002a.mdl", 560, 600, 0)
    m.loose("models/props_junk/wood_pallet001a.mdl", 600, 300, 30, z=F + 12)
    for kind, u, v, sd in (("trash", 380, 300, 15), ("puddle", 1100, 200, 16), ("trash", 820, 250, 17), ("stain", 200, 150, 18)):
        m.grime(kind, u, v, F + 1, sd)
    m.soundscape(SCAPES["courtyard"], 600, 0, F, radius=900)
    m.soundscape(SCAPES["house"], 396, 540, z, radius=160)
    m.soundscape(SCAPES["house"], 1188, 540, z, radius=150)
    for u, v in ((396, 360), (600, 440), (768, 290), (1000, 360), (1188, 360), (396, 420), (1000, 420)):
        m.lane(u, v)
    m.view(200, -100, F, 30, 0, "the basin")
    m.view(768, 250, F, 90, 0, "under the street")
    m.view(396, 470, F + 8, 90, 0, "the card room")
    m.view(1030, 400, F + 8, 100, 0, "the stall")
    m.view(1400, -60, F, 150, 0, "looking back")


def m_vort(m, opt):
    """6. The vortigaunt culvert: a low side drain in the left wall with the city's pipe along its wall under the roof
    (capped where it starts), turning twice (nobody in the canal can see or shoot into its end); a green glow leaks round
    its first turn to draw people in; a hanging of thin cloth strips on a cord half across its last turn (people brush
    through it); and a dead-end den: damp brick walls, broken through into earth and rock in its back corner; a ring of
    stones round a fire with a pot hung on a tripod, steam rising from it; three old mattresses for mats; shelves on its
    wall with jars and a pot; bones and an antlion's shell by the rocks, firewood, a few candles; a seep of water in one
    corner glowing faintly green (the vortessence pool: small green glows over it, a green beam on the wall behind).
    Named for the game: lc_vort_fire, lc_vort_seat_1 to _3 (the mats, facing the fire), lc_vort_npc (where a
    vortigaunt the game makes would stand, facing the fire).
    Left as brushes: the culvert and the den and their linings, the hearth's slab, the tripod's three sticks and its
    rod, the candles (no model of one), and the hanging of strips (Half-Life 2 has no cloth: a func_illusionary of
    carpet, nobody is stopped by it).
    Unchecked: env_fire, env_steam rising, ambient/fire/fire_small_loop2.wav."""
    from map_mods_b import candle, mattress
    from map_mods_c import cage_lamp
    brick, upper, dirt = "brick/brickwall017b", "concrete/concretewall013f", "nature/dirtfloor005c"
    m.open(0, -256, 1024, 256)
    m.low(384, 256, 576, 896, F + 144)
    m.low(576, 704, 896, 896, F + 144)
    m.low(704, 896, 1024, 1280, F + 208)
    m.low(896, 1152, 1024, 1280, F + 208, floor=F - 16)      # the seep
    m.side(384, 256, 1024, 1280)
    m.portal(384, 318, F, 576, 320, F + 144)
    m.water(896, 1152, 1024, 1280, F - 16, F - 6)
    for k in range(6):                                       # the pipe (16 across) against the culvert's left wall, from a cap inside the mouth to the bend's wall
        m.static("models/props_pipes/pipe03_straight01_long.mdl", 392, 368 + 96 * k, 0, z=F + 118)
    m.static("models/props_pipes/pipe03_connector01.mdl", 392, 319, 90, z=F + 114)
    for kind, u, v, z, sd in (("stain", 576, 520, F + 90, 1), ("drain", 384, 760, F + 70, 2), ("stain", 700, 704, F + 100, 3), ("puddle", 480, 640, F + 1, 4)):
        m.grime(kind, u, v, z, sd)
    cage_lamp(m, 576, 420, F + 100, 180, lit=False)          # (long dead)
    m.light(650, 800, F + 40, "110 255 160 12")              # the glow that leaks round the turn
    m.glow(700, 860, F + 20, "120 255 170", 0.12)
    m.glow(840, 880, F + 30, "120 255 170", 0.1)
    # the hanging: thin strips of cloth on a cord, uneven, a hand's width apart, a foot clear of the floor
    import random
    rnd = random.Random(61)
    strips = []
    for k, u in enumerate(range(706, 800, 10)):
        strips.append((u, 893, F + 12 + rnd.randrange(0, 34), u + 4, 894, F + 142))
    m.ent("func_illusionary", {"rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disableshadows": "1"}, strips, "props/carpetfloor004a")
    m.det([(704, 892, F + 141, 802, 895, F + 143)], MM["steel"])                # the cord
    # the den's walls: damp brick to a band, concrete above; in its back left corner the earth broken through
    m.det([(704, 896, F, 708, 1150, F + 150), (1020, 896, F - 16, 1024, 1276, F + 150), (830, 1276, F - 16, 1024, 1280, F + 150), (896, 896, F, 1020, 900, F + 150)], brick)
    m.det([(704, 896, F + 150, 708, 1276, F + 208), (1020, 896, F + 150, 1024, 1276, F + 208), (708, 1276, F + 150, 1024, 1280, F + 208),
           (896, 896, F + 150, 1020, 900, F + 208)], upper)
    m.det([(704, 1150, F, 712, 1276, F + 150), (708, 1270, F, 830, 1280, F + 146)], dirt)          # (the earth, standing a little proud of the brick)
    m.det([(712, 1190, F, 718, 1250, F + 110), (760, 1266, F, 800, 1270, F + 128)], dirt)
    m.static("models/props_wasteland/rockgranite02a.mdl", 760, 1218, 30, z=F)
    m.static("models/props_wasteland/rockgranite03a.mdl", 830, 1226, 80, z=F)
    m.static("models/props_wasteland/rockgranite03b.mdl", 730, 1150, 140, z=F)
    m.static("models/gibs/antlion_gib_large_1.mdl", 856, 1256, 60, z=F)
    for kind, u, v, z, sd in (("stain", 1020, 1000, F + 140, 5), ("stain", 900, 1276, F + 130, 6), ("drain", 708, 980, F + 120, 7)):
        m.grime(kind, u, v, z, sd)
    # the hearth: stones, a tripod, the pot steaming, the fire
    fu, fv = 864, 1056
    m.det([(fu - 24, fv - 24, F, fu + 24, fv + 24, F + 4)], MAT["beam"])
    ring = [(60, 0), (42, 42), (0, 60), (-42, 42), (-60, 0), (-42, -42), (0, -60), (42, -42)]
    for k, (a, c) in enumerate(ring):                       # the ring of stones (the city's own loose rocks)
        m.static("models/props_junk/rock001a.mdl", fu + a, fv + c, 40 * k)
    m.shapes([prism([(fu + 40, F), (fu + 46, F), (fu + 4, F + 84), (fu - 2, F + 84)], "y", fv - 3, fv + 3, MAT["bars"]),          # (the sticks' ends uneven
              prism([(fu - 40, F), (fu - 46, F), (fu - 4, F + 82), (fu + 2, F + 82)], "y", fv - 2, fv + 4, MAT["bars"]),          #  where they cross)
              prism([(fv + 40, F), (fv + 46, F), (fv + 4, F + 80), (fv - 2, F + 80)], "x", fu - 4, fu + 2, MAT["bars"])])
    m.det([(fu - 1, fv - 1, F + 52, fu + 1, fv + 1, F + 87)], MM["steel"])                                                       # the pot's rod
    m.static("models/props_c17/metalpot001a.mdl", fu, fv, 0, z=F + 38)
    m.point("env_steam", fu, fv, F + 54, {"angles": "-90 0 0", "type": "0", "InitialState": "1", "spawnflags": "0", "Speed": "20", "SpreadSpeed": "6",
                                          "StartSize": "4", "EndSize": "16", "Rate": "10", "JetLength": "60", "rendercolor": "220 220 220", "renderamt": "90", "rollspeed": "4"})
    m.point("env_fire", fu, fv, F + 6, {"health": "30", "firesize": "30", "fireattack": "4", "firetype": "0", "spawnflags": "7", "ignitionpoint": "32", "damagescale": "0.2"})
    m.light(fu, fv, F + 70, "255 140 60 120")
    m.sound("ambient/fire/fire_small_loop2.wav", fu, fv, F + 30, radius=500, volume=5)
    m.target("lc_vort_fire", fu, fv, F + 8)
    m.target("lc_vort_npc", fu + 104, fv - 24, F + 8, 165)
    for k, (a, c, yaw) in enumerate(((-110, 60, 330), (20, 130, 260), (110, -70, 150))):
        mattress(m, fu + a, fv + c, (yaw + 90) % 360)
        m.target("lc_vort_seat_%d" % (k + 1), fu + a, fv + c, F + 8, yaw)
    for u, v, yaw in ((790, 1110, 20), (802, 1122, 75)):     # firewood
        m.loose("models/props_debris/wood_chunk04a.mdl", u, v, yaw, z=F + 2)
    m.loose("models/gibs/hgibs.mdl", 820, 1170, 200, z=F)    # the bones of a meal, or of an enemy
    m.loose("models/gibs/hgibs_rib.mdl", 832, 1160, 30, z=F)
    for sv in (960, 1032):                                   # shelves on the left wall, jars and a pot on them
        for sz in (F + 58, F + 98):
            m.static("models/props_c17/furnitureshelf001b.mdl", 716, sv, 0, z=sz)
    m.static("models/props_lab/jar01a.mdl", 716, 952, 0, z=F + 60)
    m.static("models/props_lab/jar01b.mdl", 716, 1040, 0, z=F + 60)
    m.static("models/props_c17/metalpot002a.mdl", 716, 1032, 120, z=F + 100)
    for u, v in ((728, 1000), (736, 1012), (840, 1262), (870, 1266), (1008, 1100)):
        candle(m, u, v, F, light=(u < 760 or u > 1000))
    # the vortessence pool: green glows over the seep, a green beam on the wall behind it
    for u, v, z in ((930, 1190, F - 2), (990, 1230, F - 3), (960, 1170, F - 1), (1000, 1176, F - 2)):
        m.glow(u, v, z, "120 255 170", 0.16)
    m.spot(960, 1150, F + 180, "110 255 160 40", 90, pitch=45, cone=50)
    m.static("models/props_junk/wood_crate001a.mdl", 1000, 924, 20)
    m.static("models/props_c17/oildrum001.mdl", 1000, 1110, 0)
    m.soundscape(SCAPES["cave"], 864, 1080, F, radius=360)
    m.soundscape(SCAPES["tunnel"], 480, 560, F, radius=300)
    m.blocked(800, 990, 930, 1120)
    m.lane(480, 800)
    m.lane(800, 800)
    m.lane(760, 1100)
    m.view(480, 100, F, 90, 0, "the mouth")
    m.view(640, 800, F, 20, 0, "at the turn")
    m.view(740, 940, F, 45, 4, "the den")
    m.view(980, 960, F, 130, 4, "the den's broken corner")


def m_relay(m, opt):
    """7. Cubbage's relay. A concrete quay against the right wall, 128 high, with a stone coping, three mooring cleats and
    an iron ladder down its face, two tyres for fenders, steps up its upstream end with a solid side; and on it a radio
    shack built from pieces (map_mods_c.shack: mismatched sheets, a tin roof on posts, a boarded window), netting thrown
    over its roof against eyes above: inside, the set on a table under a desk lamp, its dials glowing, a receiver and a
    logbook by it, a chair, a cot (a bed frame), a shelf of car batteries, the canals' map pinned on the back wall, a
    poster beside it. Beside it the mast: one of the city's tall utility poles (utilitypole01a, about 230 over the
    canal's walls) with two small dishes on it, an aerial on the shack's roof, guy wires to the quay and the wall, a red
    lamp at its tip (shielded from above), a long-wire aerial from the tip across the canal to the far wall and the feed
    from the shack up to the pole. A diesel generator (generatortrailer01) hums behind the shack under a lean-to, its
    exhaust pipe up through the lean-to's roof; fuel drums beside it.
    Named for the game: lc_relay_radio (the set, a prop_dynamic), lc_relay_hum (the generator's sound: StopSound),
    lc_relay_lamp (the red lamp's glow: HideSprite, ShowSprite), lc_relay_mast (the mast's foot), lc_relay_seat.
    Left as brushes: the quay, its coping and its steps, the shack, the lean-to, the netting over the roof.
    Unchecked: models/props_lab/citizenradio.mdl, ambient/machines/diesel_engine_idle1.wav, the cables (move_rope);
    where on the pole its cross arm is (the lamp and the wires are at its tip, the dishes on its shaft)."""
    from map_mods_c import shack
    b = m.b
    top, steel = F + 128, "metal/metalhull010c"
    m.open(0, -256, 1024, 256)
    m.open(320, -256, 832, -64, floor=top, mat=MAT["quay_floor"])
    m.side(320, -256, 832, -64)
    m.no_bank(120, -264, 840, -56)                       # (a quay with upright sides, and steps up its upstream end)
    run = m.steps(128, -256, -192, F, top, "u", 1)
    m.stair_side(127, run + 1, -194, -190, F, top, high=36, mat="stone/stonewall050f")     # (the steps' own sides hide in it)
    m.det([(320, -68, top, 832, -60, top + 6)], "stone/stonewall050f")               # the coping along the quay's edge
    for u in (420, 610, 800):                                                         # mooring cleats on it
        m.static("models/props_docks/dock01_cleat01a.mdl", u, -78, 0, z=top)
    m.ladder(700, -64, F, top, 90)
    m.blocked(680, -64, 720, 0)
    for u in (480, 560):                                                              # tyres for fenders, against the quay's face
        m.loose("models/props_vehicles/tire001b_truck.mdl", u, -50, 90, z=F)
    m.blocked(120, -256, 320, -180)
    m.lane(112, -224, F)
    m.lane(336, -224, top)
    # the shack
    shack(m, 344, -248, 544, -100, top, 71, high=100, window="boards", front="hi")
    m.det([(336, -262, top + 116, 552, -76, top + 117)], "metal/metalfence007a")       # netting thrown over the roof
    m.static("models/props_c17/furnituretable001a.mdl", 378, -214, 0, z=top)               # the table the set stands on
    m.dynamic("models/props_lab/citizenradio.mdl", 378, -222, 90, z=top + 37, name="lc_relay_radio")
    m.glow(386, -214, top + 47, "255 170 80", 0.06)                                       # (its dials)
    m.static("models/props_lab/desklamp01.mdl", 368, -196, 300, z=top + 37)
    m.light(372, -200, top + 64, "255 200 140 35")
    m.static("models/props_lab/reciever01a.mdl", 392, -198, 20, z=top + 37)
    m.static("models/props_lab/binderblue.mdl", 360, -228, 90, z=top + 37)
    m.static("models/props_c17/furniturechair001a.mdl", 420, -200, 180, z=top)
    m.target("lc_relay_seat", 420, -200, top + 8, 180)
    m.static("models/props_wasteland/prison_bedframe001a.mdl", 512, -186, 90, z=top)       # a cot
    m.static("models/props_c17/furnitureshelf002a.mdl", 470, -236, 90, z=top + 52)        # batteries on a shelf
    for k in range(3):
        m.static("models/items/car_battery01.mdl", 458 + 12 * k, -236, 90, z=top + 61)
    m.static("models/props_canal/canalmap001.mdl", 430, -241, 90, z=top + 4)               # the canals' map, pinned on the back wall
    m.decal("decals/decalposter014a", 492, -242, top + 30)
    m.light(450, -160, top + 88, "255 190 120 20")
    # the mast: a tall utility pole, two small dishes on its shaft, the red lamp at its tip
    tip = top + 487
    m.static("models/props_c17/utilitypole01a.mdl", 672, -176, 0, z=top)
    m.static("models/props_rooftop/satellitedish02.mdl", 693, -176, 0, z=tip - 190)       # (their backs against the pole's shaft)
    m.static("models/props_rooftop/satellitedish02.mdl", 672, -155, 90, z=tip - 260)
    m.point("env_sprite", 672, -176, tip + 4, {"targetname": "lc_relay_lamp", "model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "220",
                                                 "rendercolor": "255 40 30", "scale": "0.5", "framerate": "10.0", "GlowProxySize": "2.0", "HDRColorScale": "1.0",
                                                 "renderfx": "0", "spawnflags": "1"}, m.lv)
    m.det([(660, -188, tip + 14, 684, -164, tip + 16)], steel)                              # (a cap over the lamp: seen from the canal, not from above)
    m.static("models/props_rooftop/antenna04a.mdl", 520, -232, 0, z=top + 118)             # an aerial on the shack's roof
    for (gu, gv, gz) in ((330, -72, top + 4), (824, -72, top + 4), (824, -256, top + 220)):
        m.rope([(672, -176, tip - 40), (gu, gv, gz)], slack=10, width=1)
    m.rope([(672, -176, tip), (700, 256, b.rim - 24)], slack=60, width=1)                   # the long-wire aerial, across to the far wall (into it, under its top)
    m.rope([(540, -106, top + 98), (667, -171, top + 300)], slack=30, width=1)              # the shack's feed, up to the pole
    m.target("lc_relay_mast", 672, -100, top + 8, 90)
    # the generator under a lean-to against the wall, its exhaust up through the roof, and its fuel
    m.static("models/props_vehicles/generatortrailer01.mdl", 784, -175, 90, z=top)
    m.det([(730, -256, top + 112, 832, -100, top + 116)], "metal/metalroof008a")            # the lean-to's roof...
    m.det([(730, -104, top, 734, -100, top + 112), (828, -104, top, 832, -100, top + 112)], "wood/woodfloor006b")      # ...on two posts
    from map_mods_b import vpipe
    m.shapes([vpipe(800, -150, 3, top + 78, top + 150, steel)])                             # the exhaust
    m.sound("ambient/machines/diesel_engine_idle1.wav", 784, -208, top + 30, radius=600, volume=5, name="lc_relay_hum")
    m.rope([(784, -175, top + 78), (544, -150, top + 96)], slack=14, width=1)
    m.static("models/props_c17/oildrum001.mdl", 580, -236, 0, z=top)
    m.loose("models/props_c17/oildrum001.mdl", 590, -196, 0, z=top)
    m.loose("models/props_junk/gascan001a.mdl", 612, -224, 30, z=top)
    m.blocked(608, -240, 832, -100)
    m.taken(320, -256, F, 832, -64, tip)
    for kind, u, v, z, sd in (("stain", 500, -64, F + 60, 1), ("number", 360, -64, F + 90, 2), ("lambda", 560, -100, top + 50, 3), ("puddle", 600, 60, F + 1, 4)):
        m.grime(kind, u, v, z, sd)
    m.soundscape(SCAPES["courtyard"], 512, 60, F, radius=700)
    m.soundscape(SCAPES["house"], 444, -170, top, radius=110)
    for u, v in ((580, -90), (444, -80), (760, -90)):
        m.lane(u, v, top)
    m.view(120, 120, F, 325, -14, "the mast")
    m.view(444, -40, top, 270, 0, "into the shack")
    m.view(900, 100, F, 215, -10, "from downstream")
    b.notes.append("%s: the mast's tip is at z %d, %d over the walls' tops" % (m.tag, tip + 100, tip + 100 - b.rim))


def m_ash(m, opt):
    """10. The ash outfall (the owner: "just trash and burnt corpses"). High in the left wall, a chute's mouth: a real
    hole under a concrete hood, barred with one of the canals' bar panels, black behind, with a steel tray, soot down the
    wall under it, a danger sign and a number beside it. Under it a heap of ash and rubble 110 high (its own ground,
    Half-Life 2's rubble-and-ash blend: grey ash on its top, rubble at its foot) with the burnt dead lying on it, scorch
    marks, thin smoke rising; a second, smaller heap; garbage, bags and tyres; a wheelbarrow left on its side. Now and
    then (every three to ten minutes) the chute's grate swings open with a burst of grey dust and a clatter, and shuts
    again: everyone in the canal knows where the Combine's dead go. Flies.
    Named for the game: lc_ash_heap (the top of the heap: a place to sift through), lc_ash_grate (the chute's grate, a
    func_door_rotating: Open, Close; unseen, the bar panel riding on it), lc_ash_timer (the logic_timer that tips it:
    Disable, Enable), lc_ash_dust (the dust: SpawnDust), lc_ash_tip (a relay: Trigger tips the grate once).
    Left as brushes: the chute's mouth, its hood and its tray.
    Unchecked: the garbage pile and garbage bag models, models/humans/charple01..04.mdl, metalbucket01a, env_smokestack,
    env_dustpuff, ambient/creatures/flies1.wav, physics/concrete/rock_impact_hard1.wav, nature/blendrubbleash001a
    (which of its two textures shows at alpha 0); which way the grate swings (spawnflags 64 or 128: about the chute's top
    edge); the wheelbarrow is loose and turned on its side (roll 85): it settles as it falls."""
    m.open(0, -256, 768, 256)
    lo, hi = F + 208, F + 336
    m.low(320, 256, 448, 320, hi, floor=lo, mat=MAT["black"])
    m.side(320, 256, 448, 320)
    m.blocked(320, 256, 448, 320)
    m.det([(320, 312, lo, 448, 320, hi)], MAT["black"])
    m.det([(304, 184, lo - 16, 320, 256, hi), (448, 184, lo - 16, 464, 256, hi), (304, 184, hi, 464, 256, hi + 16)], MAT["beam"])
    m.shapes([prism([(168, lo - 48), (256, lo), (256, lo - 16), (168, lo - 64)], "x", 320, 448, "metal/metalhull010c")])
    m.taken(296, 160, lo - 72, 472, 256, hi + 24)
    m.no_bank(192, 248, 576, 264)
    # the chute's grate: the canals' bar panel on an unseen door hinged at the mouth's top, tipped now and then
    ax = 64 if m.fr.ax("u") == "x" else 128
    hx, hy = m.fr.pt(384, 262)
    m.b.vmf.brush_entity("func_door_rotating", {"targetname": "lc_ash_grate", "origin": "%d %d %d" % (hx, hy, hi - 2 + m.fr.dz), "distance": "70", "speed": "120",
                                                 "wait": "3", "lip": "0", "dmg": "0", "forceclosed": "0", "solidbsp": "0", "spawnflags": str(ax + 1024), "health": "0",
                                                 "ignoredebris": "0", "loopmovesound": "0", "noise1": "MetalGrate.ScrapeSmooth", "noise2": "MetalGrate.ImpactHard",
                                                 "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255", "renderfx": "0", "disableshadows": "1"},
                         [m.fr.box(322, 260, lo + 2, 446, 264, hi - 4)], MAT["nodraw"], m.dv)
    m.b.names.append(("lc_ash_grate", "func_door_rotating", m.tag))
    from map_mods_c import ride, sound
    ride(m, "lc_ash_grate", "models/props_canal/canal_bars002.mdl", 384, 262, 90, lo + 2)
    m.point("env_dustpuff", 384, 230, lo - 20, {"targetname": "lc_ash_dust", "scale": "40", "speed": "30", "color": "90 88 84", "angles": "90 0 0"})
    sound(m, "lc_ash_clatter", "physics/concrete/rock_impact_hard1.wav", 384, 230, lo - 20, radius=1600, volume=10)
    m.relay("lc_ash_tip", 384, 200, lo - 40, [("lc_ash_grate", "Open", "", 0), ("lc_ash_dust", "SpawnDust", "", 0.3), ("lc_ash_dust", "SpawnDust", "", 0.9),
                                               ("lc_ash_clatter", "PlaySound", "", 0.4)])
    m.point("logic_timer", 384, 200, lo - 60, {"targetname": "lc_ash_timer", "UseRandomTime": "1", "LowerRandomBound": "180", "UpperRandomBound": "600",
                                              "StartDisabled": "0", "spawnflags": "0"}, connections=[("OnTimer", "lc_ash_tip", "Trigger", "", 0)])
    for kind, u, z, sd in (("stain", 384, F + 160, 1), ("stain", 350, F + 110, 2), ("burn", 410, F + 190, 3), ("danger", 500, F + 260, 4), ("number", 270, F + 260, 5)):
        m.grime(kind, u, 256, z, sd)
    # the heap: its own ground of ash and rubble (the canal's mud kept off it), worked out from one height
    cx, cy = m.fr.pt(384, 110)
    dx, dy = m.fr.pt(580, -60)

    def heap(x, y):
        return 110 * max(0.0, 1 - math.hypot(x - cx, y - cy) / 320.0) ** 1.4 + 44 * max(0.0, 1 - math.hypot(x - dx, y - dy) / 150.0) ** 1.3

    def at(u, v):
        x, y = m.fr.pt(u, v)
        return int(heap(x, y))
    m.side(0, -256, 768, 256)
    r = m.fr.rect(0, -256, 768, 256)
    for x0 in range(r[0], r[2], 256):
        for y0 in range(r[1], r[3], 256):
            zf = F + m.fr.dz
            m.b.vmf.world_box((x0, y0, zf, x0 + 256, y0 + 256, zf + 8), MAT["nodraw"], top="nature/blendrubbleash001a", vis=m.b.vis + ": the ash heap",
                              disp={"top": (3, lambda i, j, x0=x0, y0=y0: (x0 + j * 32, y0 + i * 32, zf + heap(x0 + j * 32, y0 + i * 32) - 6),
                                            lambda i, j, x0=x0, y0=y0: 255 * min(1.0, heap(x0 + j * 32, y0 + i * 32) / 40.0))})
    for model, u, v, yaw in (("models/props_junk/garbage256_composite001a.mdl", 250, -150, 80), ("models/props_junk/garbage128_composite001a.mdl", 120, 90, 60),
                             ("models/props_junk/garbage128_composite001a.mdl", 680, 150, 200), ("models/props_junk/garbage128_composite001a.mdl", 690, -160, 130)):
        m.static(model, u, v, yaw, z=F + at(u, v) - 3)           # (flat litter: round the heap's foot, where the ground is level)
    for k, (u, v) in enumerate(((384, 150), (330, 60), (460, 40), (300, -60), (500, -80), (410, 210), (590, -40))):
        m.body("models/humans/charple0%d.mdl" % (k % 4 + 1), u, v, 55 * k, z=F + at(u, v) - 12)
    for k, (u, v) in enumerate(((420, 120), (300, 120), (520, 20), (360, -20))):
        m.grime("burn", u, v, F + at(u, v) - 6, 10 + k)
    for model, u, v in (("models/props_junk/garbage_bag001a.mdl", 200, 40), ("models/props_junk/garbage_bag001a.mdl", 560, 20),
                        ("models/props_vehicles/tire001c_car.mdl", 470, -150), ("models/props_junk/metalbucket01a.mdl", 330, -140),
                        ("models/props_vehicles/tire001c_car.mdl", 200, -40), ("models/props_junk/garbage_bag001a.mdl", 640, 80)):
        m.loose(model, u, v, 30, z=F + at(u, v) + 4)
    m.smoke(384, 110, F + 100, colour="60 58 55", size=14, length=260, rate=6)
    m.smoke(580, -60, F + 40, colour="60 58 55", size=8, length=120, rate=4)
    # a wheelbarrow left on its side (loose, turned over: it settles as it falls)
    m.prop("prop_physics", "models/props_junk/wheebarrow01a.mdl", 136, -96, 0, F + 24, {"spawnflags": "0", "angles": "0 %d 85" % m.fr.yaw(0)})
    m.blocked(80, -140, 200, -50)
    m.target("lc_ash_heap", 384, 110, F + 110)
    m.blocked(192, -64, 640, 256)
    m.sound("ambient/creatures/flies1.wav", 400, 60, F + 60, radius=500, volume=4)
    m.soundscape(SCAPES["courtyard"], 384, -150, F, radius=700)
    m.lane(384, -200)
    m.view(384, -100, F, 90, -10, "the heap and the chute")
    m.view(680, 40, F, 170, 0, "along the wall")


def m_sludge(m, opt):
    """11. The sludge tunnel. The canal goes the long way round a block (out to the left and back, about 3,800, under a
    street, past a dumped container and a car that went over the edge, a Combine camera watching it), and a low tunnel
    768 long cuts straight through, ankle deep in toxic runoff. The tunnel has a shape: its roof chamfered along both
    sides, ribs every 128, a ledge along its left wall, broken in two places so the slime must be waded. Slime pours
    from three of its five outfalls (the city's pipes out of the walls at the slime's face) with a gurgle; drums stand
    tilted in it, a pallet floats, scum bubbles. The light is the slime's: green from low over it, small green glows on
    it, the roof dark between a caged lamp inside each mouth. At both mouths the warning shown, not told: danger signs, a
    chain slung across, and at one a body that did not make it.
    Named for the game: lc_sludge_gas (a trigger filling the tunnel's air: a place for gas masks), lc_sludge_haze (the
    green haze in it, a func_dustcloud: TurnOff, TurnOn).
    Left as brushes: the tunnel, its chamfers, ribs and ledge, the beams over its mouths, the slime plugs in the pipes,
    the street bridge.
    Unchecked: nature/toxicslime002a, func_dustcloud and its keys, ambient/levels/canals/toxic_slime_loop1.wav,
    ambient/levels/canals/toxic_slime_gurgle2.wav, the slime pouring (an env_steam aimed down and out), the chains'
    material (cable/chain.vmt); that loose planks and pallets float on the slime (they do on water)."""
    from map_mods_c import cage_lamp, combine_lamp, pour
    sludge = MM["sludge"]
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
    m.water(704, -128, 1344, 128, floor, floor + 12, sludge)
    m.ent("trigger_multiple", {"targetname": "lc_sludge_gas", "spawnflags": "1", "StartDisabled": "0", "wait": "1"}, [(704, -128, floor, 1344, 128, ceil)], MAT["trigger"])
    m.ent("func_dustcloud", {"targetname": "lc_sludge_haze", "StartDisabled": "0", "Color": "90 170 60", "SpawnRate": "30", "SpeedMax": "10", "LifetimeMin": "3",
                             "LifetimeMax": "6", "DistMax": "900", "Alpha": "35", "SizeMin": "80", "SizeMax": "160", "Frozen": "0"},
          [(712, -120, floor + 16, 1336, 120, ceil - 8)], MAT["trigger"], vis=m.b.vis + ": experiments (delete if they misbehave)")
    # the tunnel's shape: chamfers along the roof, ribs, a broken ledge on the left
    wall2 = "concrete/concretewall059c"
    m.shapes([prism([(-128, ceil), (-128, ceil - 40), (-88, ceil)], "x", 640, 1408, wall2),
              prism([(128, ceil), (88, ceil), (128, ceil - 40)], "x", 640, 1408, wall2)])
    ribs = []
    for u in range(720, 1344, 128):
        ribs += [(u, -128, floor, u + 12, -122, ceil - 40), (u, 122, F + 8, u + 12, 128, ceil - 40), (u, -88, ceil - 6, u + 12, 88, ceil)]
    m.det(ribs, MAT["beam"])
    m.det([(704, 84, floor, 896, 128, F + 8), (960, 84, floor, 1152, 128, F + 8), (1216, 84, floor, 1344, 128, F + 8)], "concrete/concretefloor031a")
    for u, z in ((672, ceil - 40), (1376, ceil - 40)):
        cage_lamp(m, u, -128, z, 90, "200 230 170 30")
    for u in (820, 1060, 1280):
        m.light(u, 0, floor + 24, "110 220 70 25")
    for u, v in ((760, -60), (880, 40), (1000, -20), (1110, 70), (1200, -80), (1300, 10)):
        m.glow(u, v, floor + 13, "130 255 90", 0.14)
    for u, s in ((1060, 1), (1250, 1), (840, -1), (1080, -1), (1300, -1)):    # the outfalls: the city's pipes (16 across), 64 out of the walls at the
        m.static("models/props_pipes/pipe03_straight01_short.mdl", u, s * 96, 0, z=F + 32)    # slime's face, their backs against the walls, slime in each
        m.shapes([prism(octagon(u, F + 40, 7), "y", min(s * 128, s * 126), max(s * 128, s * 126), sludge)])
    for u, s in ((1250, 1), (840, -1), (1080, -1)):          # three of them still running
        pour(m, u, s * 62, F + 36, length=50, colour="110 150 40", size=5, yaw=270 if s > 0 else 90, pitch=65)
        m.grime("drain", u, s * 128, F + 20, u)
    m.sound("ambient/levels/canals/toxic_slime_gurgle2.wav", 1080, -60, F + 20, radius=500, volume=5)
    for u, v, yaw, pitch, roll in ((900, -96, 0, 8, 14), (1130, 92, 40, -12, 6)):           # drums standing tilted in it
        m.prop("prop_dynamic_override", "models/props_c17/oildrum001.mdl", u, v, yaw, floor + 2, {"angles": "%d %d %d" % (pitch, m.fr.yaw(yaw), roll), "solid": "6",
               "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"})
    m.loose("models/props_c17/oildrum001.mdl", 1010, -60, 40, z=floor)
    for u, v, yaw in ((760, 108, 2), (980, 110, 8)):         # what is left of an old plank walk, floating
        m.loose("models/props_wasteland/dockplank01a.mdl", u, v, (yaw + 90) % 360, z=floor + 12)
    m.loose("models/props_junk/wood_pallet001a.mdl", 1190, 20, 25, z=floor + 12)
    for u, v in ((950, 30), (1220, -50)):                    # scum coming up
        m.smoke(u, v, floor + 10, colour="90 140 40", size=6, length=40, rate=3)
    m.body("models/humans/charple04.mdl", 1180, -40, 120, z=floor)
    m.det([(638, -160, F + 152, 656, 160, F + 176), (1392, -160, F + 152, 1410, 160, F + 176)], MAT["beam"])     # (2 proud of the walls' faces)
    m.sound("ambient/levels/canals/toxic_slime_loop1.wav", 1024, 0, F + 40, radius=800, volume=6)
    # the warnings at both mouths: danger signs, a chain across, a body
    keys = {"Slack": "50", "Type": "0", "Subdiv": "2", "Barbed": "0", "Width": "2", "TextureScale": "1", "Collide": "0", "Dangling": "0", "Breakable": "0",
            "RopeMaterial": "cable/chain.vmt", "MoveSpeed": "64", "PositionInterpolator": "2", "NoWind": "1"}
    for k, u in enumerate((660, 1388)):
        m.b.vmf.point("move_rope", m.fr.at(u, -128, F + 70), dict(keys, targetname="lc_sludge_chain_%d" % k, NextKey="lc_sludge_chain_%db" % k), m.b.vis + ": ropes")
        m.b.vmf.point("keyframe_rope", m.fr.at(u, 128, F + 70), dict(keys, targetname="lc_sludge_chain_%db" % k), m.b.vis + ": ropes")
    for kind, u, v, z, sd in (("danger", 640, -180, F + 100, 1), ("danger", 640, 190, F + 120, 2), ("danger", 1408, -170, F + 110, 3), ("stain", 640, 150, F + 40, 4),
                              ("number", 1408, 180, F + 130, 5)):
        m.grime(kind, u, v, z, sd)
    m.body("models/humans/charple03.mdl", 590, 50, 200)
    m.decal("decals/decalstain002a", 600, 0, F + 1)
    m.decal("decals/decalstain002a", 1450, 0, F + 1)
    # the long way round
    m.bridge(896, 1152, 1024, 1536)
    m.static("models/props_wasteland/cargo_container01.mdl", 380, 1250, 12)
    m.blocked(180, 1130, 590, 1380)
    m.prop("prop_dynamic_override", "models/props_vehicles/car002a_physics.mdl", 1660, 1430, 270, F + 40, {"angles": "-38 %d 4" % m.fr.yaw(90), "solid": "6",
           "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"})
    m.blocked(1560, 1300, 1770, 1536)                        # (gone over the edge: nose down, its tail against the wall)
    m.static("models/props_combine/combinecamera001.mdl", 1425, 940, 0, z=F + 300)           # (on the block's corner, watching the loop)
    combine_lamp(m, 1408, 860, F + 260, 0)
    m.scatter(270, 400, 500, 900, 4, 31)                  # (on the floor between the banks)
    m.scatter(1550, 400, 1780, 900, 4, 32)
    for kind, u, v, z, sd in (("graffiti", 128, 900, F + 160, 6), ("trash", 384, 1000, F + 1, 7), ("puddle", 1664, 600, F + 1, 8), ("graffiti", 1024, 1536, F + 180, 9)):
        m.grime(kind, u, v, z, sd)
    m.soundscape(SCAPES["slime"], 1024, 0, floor, radius=500)
    m.soundscape(SCAPES["courtyard"], 384, 700, F, radius=700)
    m.soundscape(SCAPES["courtyard"], 1664, 700, F, radius=700)
    for u, v in ((384, 700), (384, 1050), (700, 1280), (1300, 1280), (1664, 1050), (1664, 700), (1024, 0)):
        m.lane(u, v, F if v else floor)
    m.view(480, 0, F, 0, 0, "the tunnel's mouth")
    m.view(760, 0, floor, 0, 0, "in the sludge")
    m.view(384, 420, F, 80, -4, "the long way")


def m_cistern(m, opt):
    """12. The cistern, for the hive boss (blind, hunts by sound). Off the RIGHT wall, a tall passage with a stair in
    it leads to a round settling tank 1536 across, ankle deep in water. Its wall is truly round (36 straight segments on
    the squares' line, damp concrete below a water line, the squares behind only seal); a stone kerb rings the water.
    Two levels: a dry ledge round the tank at the canal's height (iron grating in places, which rings underfoot) with
    four plank walks out to an island in the middle, and over the ledge a gallery, a smooth ring of slab 128 up behind
    the city's handrail, reached by the stair (a steel plate along its open side) and by two ladders from the ledge.
    Four pillars with numbers on them and caged lamps (two lit, two long dead), three inflow pipes high in the wall
    (concrete pipes, dark inside), one still pouring into the tank; chains slung from the shaft's grate down to the
    island; the island lies under a grated shaft open to the sky, so it stands in daylight (a beam straight down, dust
    hanging in it) while the rest is dim. A plank, a drum and a body float in the water; buckets, cans and bottles lie
    about the ledge and the gallery, things to throw for a blind thing to chase.
    Wading is in the water (the game can tell: a player's water level); the ledge, the planks and the gallery are dry.
    Named for the game: lc_hive_boss_spot (the island), lc_cistern_gallery (the head of the stair).
    Left as brushes: the tank, its round wall and kerb, its gallery's ring, the landing and the stair and its plate, the
    plank walks and their posts (decks on piers), the shaft's grate, the pillars, the plugs that darken the inflow
    pipes.
    Unchecked: ambient/water/water_flow_loop1.wav, the chains (cable/chain.vmt on ropes), the water pouring (an env_steam
    aimed down and in), func_dustmotes in daylight."""
    from map_mods_c import cage_lamp, centred, chain, dustmotes, pour, ring_rail, ring_segments
    b = m.b
    m.open(0, -256, 1536, 256)
    ceil, basin, cu, cv, R, G = F + 352, F - 32, 768, -1408, 768, F + 128
    RW, RG, RK = 736, 672, 576           # the round wall's face, the gallery's inner edge, the kerb's inner edge
    m.low(640, -640, 896, -256, ceil)
    m.portal(640, -322, F, 896, -320, ceil)
    pillars = [(cu + du - 64, cv + dv - 64, cu + du + 64, cv + dv + 64) for du in (-384, 384) for dv in (-384, 384)]
    kind = {}
    for i in range(-12, 12):
        for j in range(-12, 12):
            u, v = cu + i * CELL, cv + j * CELL
            d = math.hypot(i + 0.5, j + 0.5) * CELL
            if d >= R or any(p[0] <= u < p[2] and p[1] <= v < p[3] for p in pillars):
                continue
            kind[(i, j)] = "island" if (abs(i + 0.5) < 2 and abs(j + 0.5) < 2) else "ring" if d >= R - 150 else "wet"
    wet = []
    for (i, j), k in sorted(kind.items()):
        u, v = cu + i * CELL, cv + j * CELL
        if k == "island":
            m.open(u, v, u + CELL, v + CELL)
        elif k == "ring":                    # (iron grating in every fourth square of the ledge: it rings underfoot)
            m.low(u, v, u + CELL, v + CELL, ceil, mat="metal/metalgrate016a" if (i * 3 + j) % 4 == 0 else "concrete/concretefloor031a")
        else:
            m.low(u, v, u + CELL, v + CELL, ceil, floor=basin)
            wet.append(m.fr.rect(u, v, u + CELL, v + CELL))
    m.side(0, -2176, 1536, -256)
    wet.sort(key=lambda r: (r[1], r[0]))
    runs = []
    for r in wet:
        if runs and runs[-1][1] == r[1] and runs[-1][2] == r[0]:
            runs[-1][2] = r[2]
        else:
            runs.append([r[0], r[1], r[2], r[3]])
    for x1, y1, x2, y2 in runs:
        b.vmf.world_box((x1, y1, basin + m.fr.dz, x2, y2, basin + 12 + m.fr.dz), MAT["nodraw"], top=MM["water"], vis=b.vis + ": water and sludge", seals=False)
    # the round wall: 36 segments, damp concrete to a water line, the owner's concrete above; open where the passage
    # comes in (between 80 and 100 degrees, where the passage's walls meet the circle), a filler each side of that
    gap = (8, 9)
    m.shapes(ring_segments(cu, cv, RW, 820, F, F + 96, "concrete/concretewall059c", 36, skip=gap) +
             ring_segments(cu, cv, RW, 820, F + 96, ceil, "concrete/concretewall008a", 36, skip=gap))
    m.det([(896, -700, F, 912, -640, ceil), (624, -700, F, 640, -640, ceil)], "concrete/concretewall008a")
    # the kerb round the water: stone, 1 proud of the ledge, from the water's edge to under the gallery
    m.shapes(ring_segments(cu, cv, RK, 676, basin, F + 1, "stone/stonewall050f", 36, phase=0.5, alt=True))
    # the gallery: a smooth ring of slab, a landing where the stair comes up, the handrail round its inner edge
    m.shapes(ring_segments(cu, cv, RG - 8, RW + 8, G - 8, G, MAT["beam"], 40, phase=0.5, alt=True))
    m.det([(640, -684, G - 7, 896, -640, G + 2)], "metal/metalhull010c")                   # (a steel landing, 2 proud of the ring)
    ring_rail(m, cu, cv, RG + 2, G, 42, skip=(0, 21))                                        # (open over the two ladders' heads)
    LD = int(round((RG - 8) * math.cos(math.pi / 40)))                                       # (the ring's inner edge, flat across each axis)
    for lu, lv, out in ((cu + LD, cv + 24, 180), (cu - LD, cv - 24, 0)):
        m.ladder(lu, lv, F, G, out)
    # the stair up to it, in the passage
    m.steps(-448, 640, 704, F, G, "v", -1)
    m.shapes([prism([(-448, F), (-448, F + 36), (-640, G + 36), (-640, G)], "x", 704, 708, "metal/metalhull010c")])
    m.blocked(640, -660, 720, -430)
    m.target("lc_cistern_gallery", 672, -672, G + 8, 270)
    # plank walks from the kerb to the island, on posts
    planks, posts = [], []
    for (a1, a2, axis) in ((cu + 128, cu + RK + 24, "u"), (cu - RK - 24, cu - 128, "u"), (cv + 128, cv + RK + 24, "v"), (cv - RK - 24, cv - 128, "v")):
        planks.append((a1, cv - 32, F - 6, a2, cv + 32, F - 1) if axis == "u" else (cu - 32, a1, F - 6, cu + 32, a2, F - 1))
        for a in range(a1 + 60, a2 - 20, 160):
            posts.append((a, cv - 28, basin, a + 8, cv + 28, F - 6) if axis == "u" else (cu - 28, a, basin, cu + 28, a + 8, F - 6))
    m.det(planks, "wood/woodfloor006b")
    m.det(posts, "wood/woodwall006a")
    # the shaft's grate, the pillars' heads and feet, the inflow pipes, the chains
    m.det([(cu - 128, cv - 128 + 32 * k, ceil - 8, cu + 128, cv - 122 + 32 * k, ceil) for k in range(9)] + [(cu - 4, cv - 128, ceil - 14, cu + 4, cv + 128, ceil - 8)], MAT["bars"])
    m.det([(p[0] - 16, p[1] - 16, ceil - 24, p[2] + 16, p[3] + 16, ceil) for p in pillars] + [(p[0] - 12, p[1] - 12, basin, p[2] + 12, p[3] + 12, F + 8) for p in pillars], MAT["beam"])
    for k, (pu, pv, yaw, plug) in enumerate(((cu + RW - 40, cv, 0, (cu + RW - 4, cv, "x")), (cu - RW + 40, cv, 0, (cu - RW + 1, cv, "x")), (cu, cv - RW + 40, 90, (cv - RW + 1, cu, "y")))):
        centred(m, "models/props_pipes/concrete_pipe001a.mdl", pu, pv, yaw, F + 292)      # (its back in the wall, lit from the tank)
        a, c, ax = plug
        m.shapes([prism(octagon(c, F + 292, 38), ax, a, a + 3, MAT["black"])])
    pour(m, cu + RW - 100, cv, F + 254, length=280, colour="190 205 212", size=8, yaw=180, pitch=62)     # (the east pipe still runs)
    m.sound("ambient/water/water_flow_loop1.wav", cu + RW - 160, cv, F + 40, radius=900, volume=5)
    m.grime("drain", cu + RW, cv + 40, F + 200, 1)
    for k, (du, dv) in enumerate(((-70, -60), (60, -80), (80, 70))):
        chain(m, "lc_cistern_chain_%d" % k, [(cu + du * 128 // 90, cv + dv * 128 // 90, ceil - 10), (cu + du, cv + dv, F + 4)], slack=20)
    m.target("lc_hive_boss_spot", cu, cv, F + 8, 90)
    # light: the daylight shaft (a beam straight down, dust in it), caged lamps on the pillars' inner faces
    m.spot(cu, cv, ceil + 60, "230 236 240 300", 0, pitch=90, cone=60)
    dustmotes(m, (cu - 120, cv - 120, F + 16, cu + 120, cv + 120, ceil - 24))
    for k, (pu, pv) in enumerate(((cu - 320, cv - 384), (cu + 320, cv - 384), (cu - 320, cv + 384), (cu + 320, cv + 384))):
        cage_lamp(m, pu, pv, F + 220, 0 if pu < cu else 180, "190 205 210 45", lit=k in (1, 2))
        m.grime("number", pu, pv - 30, F + 70, 2 + k)
        m.grime("stain", pu, pv + 30, F + 40, 7 + k)
    m.light(768, -448, F + 200, "150 190 200 40")
    for k, (du, dv) in enumerate(((RW, 300), (-RW, -200), (300, -RW), (-420, RW - 140))):      # stains down the wall, a water line's marks
        a = math.atan2(dv, du)
        m.grime("stain", cu + int(round((RW - 2) * math.cos(a))), cv + int(round((RW - 2) * math.sin(a))), F + 110, 20 + k)
    # what floats, what lies about to be thrown
    m.loose("models/props_wasteland/dockplank01a.mdl", cu + 260, cv + 200, 30, z=basin + 12)
    m.loose("models/props_c17/oildrum001.mdl", cu - 300, cv + 160, 0, z=basin + 12)
    m.body("models/humans/corpse1.mdl", cu + 180, cv - 120, 160, z=basin + 2)
    for k, (model, du, dv, z) in enumerate((("models/props_junk/metalbucket01a.mdl", 690, 90, F), ("models/props_junk/garbage_metalcan001a.mdl", -700, 120, F),
                                            ("models/props_junk/garbage_glassbottle001a.mdl", 120, 700, F), ("models/props_junk/plasticbucket001a.mdl", 520, -480, G),
                                            ("models/props_junk/garbage_metalcan001a.mdl", -500, 500, G), ("models/props_junk/garbage_glassbottle001a.mdl", -680, -60, G))):
        m.loose(model, cu + du, cv + dv, 40 * k, z=z)
    m.soundscape(SCAPES["tunnel"], cu, cv, F, radius=900)
    m.soundscape(SCAPES["watery"], 768, -448, F, radius=200)
    m.lane(768, -448)
    for du, dv in ((0, 0), (400, 0), (-400, 0), (0, 400), (0, -400)):
        m.lane(cu + du, cv + dv)
    for du, dv in ((-488, -488), (488, -488), (-488, 488), (488, 488), (700, 0), (-700, 0), (0, -700), (-96, 716)):
        m.lane(cu + du, cv + dv, G)
    m.view(800, -500, F, 270, 0, "coming in, on the ledge")
    m.view(672, -690, G, 285, 14, "from the gallery")
    m.view(cu + 40, cv + 40, F, 135, -20, "on the island, looking up")
    m.view(cu + 600, cv, F, 180, 0, "on a plank walk")
    b.notes.append("%s: the tank's middle is at (%d %d); its floor is z %d under 12 of water, its ledge, planks and island z %d, its gallery z %d, its roof z %d" % (
        (m.tag,) + m.fr.pt(cu, cv) + (basin, F, G, ceil)))


def m_underpass(m, opt):
    """13. The barnacle underpass: 1024 of canal under a wide road, unlit. Three piers stand down its middle, chamfered
    (as City 18's columns are) under wider caps, and a concrete girder crosses the canal on each, the road's deck resting
    on them; the road's drains come down the piers in gutter pipes, puddles under them. Six barnacles hang from the deck
    between them, and under each Half-Life 2's tell: bones and a stain on the floor, two of the dead lying where they
    were dropped. Part of the deck has come in by the right wall: daylight straight down a shaft (dust hanging in it,
    now and then more dust and grit falling off the broken edge), a fallen slab with its bars sticking out, rubble, a
    street sign and its pole come down with it. A lorry jammed against a pier, its load of crates spilled behind it, a
    car, cables hanging, five of the dead in all, one beside a lantern (the city's oil lamp, lamp001a) that still
    burns. Graffiti on the piers, a danger sign by the hole.
    Named for the game: lc_underpass_body_1 to _5 (where each body lies: things to search), lc_underpass_dust (the dust
    off the broken edge: SpawnDust; a logic_timer, lc_underpass_dust_timer, works it).
    Left as brushes: the road over it, the piers, their caps and the girders, the fallen slab.
    Unchecked: npc_barnacle (and whether the game minds NPCs it did not make), models/humans/corpse1.mdl and
    charple01, charple03, ambient/atmosphere/tunnel1.wav, env_dustpuff, the cables (move_rope); the rebar is laid on its
    side (pitch 90), centred on its origin; the sign and its pole are loose, laid on their sides, and settle."""
    from map_mods_b import vprism
    from map_mods_c import centred, dustmotes
    roof = F + GATE_HIGH
    m.open(0, -256, 256, 256)
    m.low(256, -256, 1280, 256, roof)
    m.open(1280, -256, 1536, 256)
    for u in (448, 704, 960):                               # the piers
        m.unpaint(u, -64, u + 64, 64)
    m.open(832, -256, 960, -128)                            # where the roof came in
    m.no_bank(824, -264, 968, -248)
    m.portal(318, -256, F, 320, 256, roof)
    m.portal(1216, -256, F, 1218, 256, roof)

    def octo(u1, v1, u2, v2, e, c):
        return [(u1 - e, v1 - e + c), (u1 - e + c, v1 - e), (u2 + e - c, v1 - e), (u2 + e, v1 - e + c), (u2 + e, v2 + e - c), (u2 + e - c, v2 + e),
                (u1 - e + c, v2 + e), (u1 - e, v2 + e - c)]
    piers = []
    for u in (448, 704, 960):                               # each pier clad chamfered, a wider cap, a girder across on it
        piers.append(vprism(octo(u, -64, u + 64, 64, 16, 16), F, roof - 24, "concrete/concretewall008a"))
        piers.append(vprism(octo(u, -64, u + 64, 64, 32, 24), roof - 24, roof, MAT["beam"]))
    m.shapes(piers)
    girders = []
    for u in (448, 704, 960):
        cu = u + 32
        for v1, v2 in ((-256, -96), (96, 256)):
            girders.append(prism([(cu - 20, roof), (cu + 20, roof), (cu + 20, roof - 20), (cu + 12, roof - 30), (cu - 12, roof - 30), (cu - 20, roof - 20)], "y", v1, v2, MAT["beam"]))
    m.shapes(girders)
    for u in (448, 704, 960):                               # the road's drains down the piers' sides, a puddle under each
        centred(m, "models/props_pipes/gutter_256_001a.mdl", u + 20, -86, 0, F + 128)        # (its head in the cap)
        m.grime("puddle", u + 20, -110, F + 1, u)
        m.grime("graffiti", u + 44, -80, F + 90, u + 1)
    m.grime("graffiti", 736, 80, F + 120, 7)
    # where the roof came in: the slab, its bars, rubble, a sign and its pole, daylight and dust
    m.shapes([prism([(-256, F + 210), (-256, F + 180), (-130, F), (-108, F)], "x", 836, 950, MAT["beam"])])
    m.static("models/props_debris/concrete_chunk01a.mdl", 820, -110, 40)
    m.static("models/props_debris/concrete_chunk02a.mdl", 960, -150, 110)
    m.static("models/props_debris/broken_pile001a.mdl", 900, -90, 200)
    for k in range(4):                                       # bars sticking out of the fallen slab's upper part
        m.point("prop_static", 860 + 26 * k, -200 + 4 * (k % 2), F + 132 + 7 * (k % 3), {"model": "models/props_debris/rebar00%dc_64.mdl" % (2 if k % 2 else 4),
                "angles": "90 %d 0" % m.fr.yaw(90 + 8 * k), "skin": "0", "solid": "0", "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1",
                "fademaxdist": "0", "fadescale": "1"}, m.pv)
    m.prop("prop_physics", "models/props_c17/signpole001.mdl", 990, -170, 0, F + 4, {"spawnflags": "0", "angles": "0 %d 90" % m.fr.yaw(30)})
    m.prop("prop_physics", "models/props_c17/streetsign004f.mdl", 1010, -120, 0, F + 14, {"spawnflags": "0", "angles": "0 %d 90" % m.fr.yaw(70)})
    m.spot(896, -192, roof + 120, "230 236 240 220", 0, pitch=90, cone=50)
    dustmotes(m, (840, -250, F + 16, 952, -136, roof + 100))
    m.point("env_dustpuff", 896, -128, roof - 8, {"targetname": "lc_underpass_dust", "scale": "16", "speed": "10", "color": "120 116 108", "angles": "90 0 0"})
    m.point("logic_timer", 896, -100, roof - 40, {"targetname": "lc_underpass_dust_timer", "UseRandomTime": "1", "LowerRandomBound": "20", "UpperRandomBound": "70",
                                                 "StartDisabled": "0", "spawnflags": "0"}, connections=[("OnTimer", "lc_underpass_dust", "SpawnDust", "", 0)])
    m.grime("danger", 840, -128, F + 180, 8)
    m.blocked(800, -256, 990, -60)
    # the barnacles, and under each the tell
    for k, (u, v) in enumerate(((380, 10), (576, -130), (640, 120), (832, 70), (1090, -100), (1180, 110))):
        m.point("npc_barnacle", u, v, roof - 1, {"angles": "0 0 0", "spawnflags": "0"}, m.b.vis + ": barnacles (delete them if the game minds)")
        m.decal("decals/bloodstain_%s" % ("001", "002", "003", "101", "201", "001")[k], u + 6, v - 4, F + 1)
        if k % 2 == 0:
            m.loose("models/gibs/hgibs.mdl", u + 14, v + 10, 40 * k, z=F)
        else:
            m.loose("models/gibs/hgibs_rib.mdl", u - 12, v + 6, 50 * k, z=F)
    m.static("models/props_vehicles/truck001a.mdl", 580, -160, 12)
    for u, v, yaw in ((430, -140, 20), (418, -196, 60), (452, -230, 5)):    # its load, spilled out of its back
        m.loose("models/props_junk/wood_crate001a.mdl", u, v, yaw)
    m.static("models/props_vehicles/car004a_physics.mdl", 1060, 160, 200)
    m.static("models/props_debris/barricade_short01a.mdl", 330, 150, 80)
    m.blocked(450, -250, 720, -70)
    m.blocked(960, 70, 1170, 250)
    bodies = (("models/humans/corpse1.mdl", 395, 30), ("models/humans/charple03.mdl", 700, 150), ("models/humans/corpse1.mdl", 845, 90),
              ("models/humans/charple01.mdl", 1100, -150), ("models/humans/corpse1.mdl", 1190, 20))
    for k, (model, u, v) in enumerate(bodies):
        m.body(model, u, v, 70 * k)
        m.target("lc_underpass_body_%d" % (k + 1), u, v, F + 8)
    m.static("models/props_c17/lamp001a.mdl", 716, 186, 30)                # the lantern
    m.glow(716, 186, F + 14, "255 200 120", 0.15)
    m.light(716, 186, F + 22, "255 190 110 16")
    m.rope([(600, 200, roof - 2), (700, 150, roof - 2)], slack=90, width=1)
    m.rope([(1000, -200, roof - 2), (1130, -40, roof - 2)], slack=110, width=1)
    m.rope([(400, -180, roof - 2), (420, -60, roof - 2)], slack=70, width=1)
    m.loose("models/props_junk/wood_crate001a.mdl", 640, 200, 15)
    m.sound("ambient/atmosphere/tunnel1.wav", 768, 0, F + 120, radius=1000, volume=4)
    m.soundscape(SCAPES["tunnel"], 768, 0, F, radius=700)
    m.decal("decals/decalstain002a", 930, 60, F + 1)
    for u, v in ((400, -100), (620, 0), (880, 20), (1136, 0), (1240, -60)):
        m.lane(u, v)
    m.view(190, 0, F, 0, 0, "at the mouth")
    m.view(560, 150, F, 350, -4, "inside")
    m.view(1150, -180, F, 172, -14, "where the roof came in")


def m_checkpoint(m, opt):
    """8. The Combine checkpoint, in the Combine's own kit. People come at it from the module's entry (flip it to face
    the other way): a chicane of concrete barriers and Combine barricades, a queue marked on the floor in hazard stripes,
    then a Combine wall across the canal to z 720 (the owner's Combine metal, buttresses and a cap of the Citadel's
    plate) with one gateway (192 wide, 160 high) shut by a force field between two of the Combine's fence posts
    (combine_fence01b and 01a, 192 high, the owner's own field between them); a camera on the wall over the gateway, the
    Combine's lights either side, Breen's poster and numbers on the wall's face. Behind the wall, on the left bank, a
    guard's platform 128 high (the banks are its ramps) with one of the Combine's booths (combine_booth_short01a), a
    console, a monitor and a health charger on the wall; stairs from it to a walk along the wall's top behind the
    Combine's railing, a parapet before it, two Combine floodlights on its ends for the searchlights. Under the walk on
    the right bank, a chain link holding pen with a sliding gate, the police line on its wall.
    Named for the game: lc_checkpoint_field (a func_brush: Disable opens it, Enable shuts it), lc_checkpoint_hum (its
    sound: StopSound, PlaySound), lc_checkpoint_light and lc_checkpoint_light_b (the searchlights: LightOff, LightOn),
    lc_checkpoint_pen (the pen's gate, a func_door: Open, Close; unseen, a panel of the pen's fence riding on it),
    lc_checkpoint_pen_spot (where a prisoner stands), lc_checkpoint_post (the guard's place on the wall),
    lc_checkpoint_queue (where people wait to be seen).
    The health charger is a working item_healthcharger (it heals whoever uses it): delete it if the game's medics should
    be the only healing.
    Left as brushes: the wall, its buttresses and cap, the gateway's frame, the walk, its deck, brackets and parapet,
    the stairs and their plate, the pen's mesh roof, the queue's stripes (dev_hazzardstripe01a, as the owner's map
    paints its edges).
    Unchecked: ambient/machines/combine_shield_loop3.wav, point_spotlight and light_spot keys; which way
    combine_light001b, combinecamera001 and the booth face (their fronts taken as the models' +x)."""
    from map_mods_c import combine_field, combine_lamp, combine_rail, panel_fence, ride, SHIELD
    b = m.b
    cmb, cmb1, plate, steel = "metal/metalcombine002", "metal/metalcombine001", "metal/citadel_metalwall072c", "metal/metalhull010c"
    W1, W2, top, pz = 512, 576, TRIM + 64, F + 128
    m.open(0, -256, 1280, 256)
    m.open(576, 128, 1088, 256, floor=pz, mat=MAT["quay_floor"])
    m.side(576, 128, 1088, 256)
    m.side(128, -96, 512, 96)                                # (no mud over the queue's stripes)
    m.no_bank(448, 248, 576, 264)
    m.no_bank(448, -264, 640, -248)
    m.no_bank(704, -264, 960, -248)
    # the way up to it: barriers set as a chicane, teeth to keep people off the banks, the queue painted on the floor
    m.static("models/props_c17/concrete_barrier001a.mdl", 330, 64, 90)
    m.static("models/props_c17/concrete_barrier001a.mdl", 210, -64, 90)
    for u in (120, 400):                                     # Combine barricades to keep people off the banks
        for v in (-104, 104):
            m.static("models/props_combine/combine_barricade_short02a.mdl", u, v, 0, z=F)
    m.blocked(180, -120, 360, 120)
    m.det([(400, -40, F, 488, -36, F + 1), (400, 36, F, 488, 40, F + 1), (396, -40, F, 400, 40, F + 1)], "dev/dev_hazzardstripe01a")
    # the wall, its buttresses and cap, the gateway and its frame
    m.det([(W1, -256, F, W2, -96, top), (W1, 96, F, W2, 256, top), (W1, -96, F + 160, W2, 96, top)], cmb)
    m.det([(W1 - 4, -256, top - 24, W1 + 4, 256, top - 20)], cmb1)                      # (a band of the darker plate under the top)
    m.shapes([prism([(W1, F), (W1 - 72, F), (W1, F + 280)], "y", v - 16, v + 16, plate) for v in (-208, -136, 136, 208)])
    m.det([(W1 - 8, -112, F, W2 + 8, -95, F + 160), (W1 - 8, 95, F, W2 + 8, 112, F + 160), (W1 - 8, -112, F + 159, W2 + 8, 112, F + 176)], steel)   # (1 proud of the opening)
    combine_field(m, (W1 - 24, -96), (W1 - 24, 96), F, name="lc_checkpoint_field", hum=False)
    m.sound("ambient/machines/combine_shield_loop3.wav", 544, 0, F + 80, radius=700, volume=6, name="lc_checkpoint_hum")
    m.test_button((W1 - 16, -160, F + 48, W1 - 8, -144, F + 64), [("OnIn", "lc_checkpoint_field", "Disable"), ("OnOut", "lc_checkpoint_field", "Enable")])
    m.light(500, 0, F + 120, "120 200 255 40")
    m.static("models/props_combine/combinecamera001.mdl", W1 - 4, 0, 180, z=F + 214)        # (watching the queue)
    for v in (-168, 168):
        combine_lamp(m, W1, v, F + 196, 180)
    m.grime("poster", W1, -184, F + 110, 21)
    m.decal("decals/decal_posterbreen", W1, 184, F + 120)
    m.grime("number", W1, -130, F + 150, 22)
    m.grime("number", W1, 130, F + 150, 23)
    # the walk along the wall's top: the wall itself and a deck behind it, brackets under it, a parapet before it, the
    # Combine's railing behind it (the stairs come up onto the walk at its left end)
    m.det([(W2, -256, top - 16, 672, 188, top)], steel)                                 # (from v 188 on the stairs are the floor)
    m.shapes([prism([(W2, top - 16), (W2 + 80, top - 16), (W2, top - 96)], "y", v - 8, v + 8, steel) for v in (-240, -128, 128, 176)])
    m.det([(W1 - 1, v, top, W1 + 17, v + 64, top + 40) for v in range(-256, 256, 128)] + [(W1, -256, top, W1 + 16, 256, top + 24)], cmb)   # (chest high: a guard sees over it)
    m.det([(W1 + 16, -256, top, 672, -192, top + 40)], cmb)
    combine_rail(m, (668, -192), (668, 192), top)
    # the searchlights, on the wall's two ends against the canal's walls (the middle of the walk left clear to look over)
    for v, yaw, name in ((224, 196, "lc_checkpoint_light"), (-160, 164, "lc_checkpoint_light_b")):
        m.static("models/props_combine/combine_light001b.mdl", W1 + 50, v, yaw, z=top)
        m.spot(W1 + 20, v, top + 60, "190 225 255 900", yaw, pitch=16, cone=30, name=name)
    # the guard's platform: stairs to the wall's top along the canal's wall, the Combine's booth, a console, a monitor
    m.steps(864, 192, 256, pz, top, "u", -1)
    m.shapes([prism([(864, pz), (864, pz + 36), (W2, top + 36), (W2, top)], "y", 188, 192, steel)])
    m.static("models/props_combine/combine_booth_short01a.mdl", 1010, 212, 270, z=pz)
    m.blocked(936, 128, 1088, 256)
    m.static("models/props_combine/combine_interface001.mdl", 900, 162, 270, z=pz)
    m.static("models/props_combine/combine_intmonitor001.mdl", 920, 246, 270, z=pz)
    m.point("item_healthcharger", 1080, 255, pz + 48, {"angles": "0 %d 0" % m.fr.yaw(270)})
    combine_lamp(m, 760, 256, pz + 150, 270)
    combine_lamp(m, 1040, 256, pz + 150, 270)
    m.blocked(576, 176, 880, 256)
    # the holding pen, under the walk on the right bank
    panel_fence(m, (704, -128), (800, -128), F)
    panel_fence(m, (864, -128), (960, -128), F)
    panel_fence(m, (707, -256), (707, -128), F)              # (just inside the cut in the bank, clear of its faces)
    panel_fence(m, (957, -256), (957, -128), F)
    m.det([(702, -256, F + 129, 962, -126, F + 130)], MAT["fence"])
    from map_mods_b import slide_door                        # the gate: a panel sliding along in front of the fence's right part
    slide_door(m, "lc_checkpoint_pen", [((800, -126, F, 864, -122, F + 128), MAT["fence"])], "0 %d 0" % m.fr.yaw(0), speed=60, lip=2,
               sounds=("MetalGrate.ScrapeSmooth", "MetalGrate.ImpactSoft"), unseen=True)
    ride(m, "lc_checkpoint_pen", "models/props_wasteland/interior_fence002b.mdl", 832, -124, 0, F)
    m.test_button((936, -124, F + 48, 944, -116, F + 64), [("OnIn", "lc_checkpoint_pen", "Open"), ("OnOut", "lc_checkpoint_pen", "Close")])
    m.static("models/props_trainstation/benchoutdoor01a.mdl", 832, -226, 90)
    m.target("lc_checkpoint_pen_spot", 832, -190, F + 8, 90)
    m.blocked(704, -256, 960, -112)
    combine_lamp(m, 832, -256, F + 136, 90)
    m.grime("police", 760, -256, F + 70, 24)
    m.grime("stain", 900, -256, F + 40, 25)
    m.static("models/props_wasteland/barricade002a.mdl", 1130, -120, 100)
    m.target("lc_checkpoint_post", 620, 0, top + 8, 180)
    m.target("lc_checkpoint_queue", 300, 0, F + 8, 0)
    m.decal("decals/decalstain002a", 300, 120, F + 1)
    m.soundscape("d1_trainstation.Turnstyle", 400, 0, F, radius=700)          # (the station's checkpoint: the owner's map uses it)
    m.soundscape(SCAPES["combine"], 900, 180, pz, radius=300)
    m.taken(432, -256, F, 704, 256, top + 90)
    m.blocked(448, -256, 640, -96)
    m.blocked(448, 96, 640, 128)
    for u, v, z in ((544, 0, F), (700, 60, F), (980, 160, pz), (700, 160, pz), (624, 0, top), (624, -180, top), (720, 224, pz + 96)):
        m.lane(u, v, z)
    m.view(400, 0, F, 0, 0, "at the gateway")
    m.view(620, -40, top, 180, 18, "from the wall")
    m.view(1200, -40, F, 180, 0, "from behind")
    m.view(640, 170, pz, 0, 4, "on the platform")
    b.notes.append("%s: the gateway is 192 wide and 160 high in a wall to z %d; people come at it from the module's entry (flip it to face the other way)" % (m.tag, top))


def chain_link(m, a, b, z, high=96, post=128):
    """A run of chain link fence from a to b (each (u, v); the run along u or along v), standing on z: a sheet, posts, a top rail."""
    (u1, v1), (u2, v2) = a, b
    along_u = v1 == v2
    lo, hi = (min(u1, u2), max(u1, u2)) if along_u else (min(v1, v2), max(v1, v2))
    if along_u:
        m.det([(lo, v1 - 1, z, hi, v1 + 1, z + high)], MAT["fence"])
        bars = [(lo, v1 - 2, z + high - 4, hi, v1 + 2, z + high)] + [(min(p, hi - 4), v1 - 2, z, min(p, hi - 4) + 4, v1 + 2, z + high - 4) for p in range(lo, hi + 1, post)]
    else:
        m.det([(u1 - 1, lo, z, u1 + 1, hi, z + high)], MAT["fence"])
        bars = [(u1 - 2, lo, z + high - 4, u1 + 2, hi, z + high)] + [(u1 - 2, min(p, hi - 4), z, u1 + 2, min(p, hi - 4) + 4, z + high - 4) for p in range(lo, hi + 1, post)]
    m.det(bars, MAT["bars"])


def pyramid(u, v, z, half, high, mat):
    """A four-sided point standing on z (a dragon's tooth): the faces for m.shapes."""
    a, b, c, d, top = (u - half, v - half, z), (u + half, v - half, z), (u + half, v + half, z), (u - half, v + half, z), (u, v, z + high)
    return [([a, b, c, d], mat), ([a, b, top], mat), ([b, c, top], mat), ([c, d, top], mat), ([d, a, top], mat)]


# name: (length, how to build it, what it is)
MODULES = {
    "straight": (1024, m_straight, "plain canal (\"straight 1536\", \"straight 1024 bridge\")"),
    "jog": (1024, m_jog, "the canal steps sideways to break a long view (\"jog left 768\", \"jog right 1024\")"),
    "tee": (512, m_tee, "a standard gate in the left wall, for another piece or layout to join"),
    "shed": (2112, m_shed, "plain canal with a train's shed on the street beside it (two to a straight run; needs \"upper left\")", {"stretch": True}),
    "drain": (1024, m_drain, "1. the storm drain junction, down to the city's sewers (left)"),
    "overflow": (1024, m_overflow, "2. the overflow toward Ravenholm, behind a sluice plate (left)"),
    "shanty": (1536, m_shanty, "4. the shantytown under a street bridge (left)"),
    "vort": (1024, m_vort, "6. the vortigaunt culvert (left)"),
    "relay": (1024, m_relay, "7. Cubbage's relay shack and mast, on a pier (right)"),
    "checkpoint": (1280, m_checkpoint, "8. the Combine checkpoint: a wall, a force field gateway, a guard's platform and searchlight"),
    "ash": (768, m_ash, "10. the ash outfall: trash and burnt corpses (left)"),
    "sludge": (2048, m_sludge, "11. the sludge tunnel: a shortcut through the long way round (left)"),
    "cistern": (1536, m_cistern, "12. the cistern for the hive boss (right)"),
    "underpass": (1536, m_underpass, "13. the barnacle underpass"),
}


for _more in ("map_mods_a", "map_mods_b", "map_mods_c", "map_mods_d", "map_mods_e", "map_town"):
    try:
        MODULES.update(__import__(_more).MODULES)
    except ImportError as e:
        if _more not in str(e):
            print("  (%s could not be loaded: %s)" % (_more, e))
    except Exception as e:      # (a file half written must not take the others down with it)
        print("  (%s could not be loaded: %s: %s)" % (_more, type(e).__name__, e))


def take_views(b, vmf_path, folder, name, cut=None):
    """Pictures of what was just written (map_view.py): from above, from above with the roofs off, and every view the
    modules asked for; then all of them on one sheet."""
    import os
    import map_view
    os.makedirs(folder, exist_ok=True)
    shots = []
    kinds = [("above", {"iso": "SW"}, ""), ("open", {"iso": "NE", "cut": cut or F + 150}, ", roofs off")]
    high = max([spec[1] for spec in b.plan.cells.values() if spec[0] != "solid" and spec[1] >= F + 200] or [0])
    if high:      # (rooms well above the canal's floor: a second cut, over them)
        kinds.append(("upper", {"iso": "NE", "cut": high + 150}, ", cut over the upper floors"))
    for tag, kw, said in kinds:
        shots.append(map_view.render(vmf_path, os.path.join(folder, "%s_%s.png" % (name, tag)), size=(640, 400), title="%s: from above%s" % (name, said), **kw))
    for k, (label, eye, yaw, pitch) in enumerate(b.views):
        shots.append(map_view.render(vmf_path, os.path.join(folder, "%s_%02d.png" % (name, k)), eye=eye, yaw=yaw, pitch=pitch, size=(640, 400),
                                     title="%s (eye %d %d %d, looking %d)" % ((label,) + tuple(eye) + (yaw,))))
    out = map_view.sheet(shots, os.path.join(folder, "%s_sheet.png" % name))
    print("  pictures: %s (and %d single ones beside it)" % (out, len(shots)))


def read_layout(path):
    """A layout: "start X Y", "heading E|N|W|S", "rim Z", "end X Y HEADING" (where it must come out), then a module a line."""
    lay = {"name": path.replace("\\", "/").split("/")[-1].rsplit(".", 1)[0], "start": (0, 0), "heading": "E", "rim": 784, "end": None, "modules": [],
           "upper": None, "cars": 2}
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
        elif words[0] == "ground":
            lay["ground"] = words[1].lower()     # ("ground street": a town, map_town.py)
        elif words[0] == "upper":
            lay["upper"] = words[1].lower()      # (the street beside the canal: "upper left" or "upper right")
        elif words[0] == "cars":
            lay["cars"] = int(words[1])           # (how many cars the trains pull behind the engine)
        else:
            lay["modules"].append(words)
    return lay


def build_chain(lay, args):
    upper = lay.get("upper")
    b = Build(lay["name"], lay["rim"], args.first_node or 6000, upper)
    b.test = bool(args.test)
    elems, shed_n = [], 0
    if upper:
        import map_corridor
        s = 1 if upper == "left" else -1
    x, y = lay["start"]
    rot = HEADINGS[lay["heading"]]
    for v in (x, y):
        if v % CELL:
            b.problems.append("the start (%d %d) is off the %d grid" % (x, y, CELL))
    steps = [["gate", "start"]] + lay["modules"] + [["gate", "end"]]
    count = {}
    width = CANAL_W       # (how wide the canal is where the chain has got to: 512, or 1024 between a widen and a narrow)
    for n, words in enumerate(steps):
        name, opt = words[0], words[1:]
        flip = "flip" in opt
        if name in ("left", "right"):
            size = width      # (a turn as wide as the canal: 512 square, or 1024 in the wide canal)
            fr = Frame(x, y, rot, size)
            m_corner(Mod(b, fr, "%d %s turn" % (n, name)), opt + (["wide"] if size > CANAL_W else []))
            elems.append({"kind": name, "frame": fr, "length": size, "tag": "%d %s turn" % (n, name)})
            shed_n = 0
            x, y = fr.pt(size // 2, size // 2 if name == "left" else -size // 2)
            rot = (rot + (1 if name == "left" else -1)) % 4
            continue
        if name == "gate" and opt[0] == "end" and width != CANAL_W:
            b.problems.append("the chain ends %d wide: put a narrow before its end (its gate is %d wide)" % (width, CANAL_W))
        if name == "gate":
            fr = Frame(x, y, rot, 256, flip=(opt[0] == "end"))
            m_gate(Mod(b, fr, "the %s gate" % opt[0]), opt)
            if opt[0] == "start":
                seed = fr.at(192, 0, F + 32)
                spawn = (fr.at(224, 0, F + 16), fr.yaw(0))
            b.labels.append(fr.pt(128, 0) + ("gate",))
            elems.append({"kind": "leg", "frame": Frame(x, y, rot, 256), "length": 256, "tag": "the %s gate" % opt[0]})
            x, y = Frame(x, y, rot, 256).pt(256, 0)
            continue
        if name not in MODULES:
            b.problems.append("the layout names a module that does not exist: %s" % name)
            continue
        length = MODULES[name][0]
        info = MODULES[name]
        w_in, w_out = widths(name)
        if w_in != width:
            b.problems.append("%s starts %d wide, but the canal there is %d wide: put a %s before it" % (name, w_in, width, "widen" if w_in > width else "narrow"))
        if upper and max(w_in, w_out) > CANAL_W:
            b.problems.append("%s is wide: the wide canal cannot run beside a street" % name)
        width = w_out
        if (name == "straight" or (len(info) > 3 and info[3].get("stretch"))) and opt and opt[0].isdigit():
            length = int(opt[0])      # (a module that can be any length: "tunnel 1536")
        if name == "shed" and not (opt and opt[0].isdigit()):
            import map_corridor
            length = (map_corridor.train_len(lay.get("cars", 2)) + 128 + 63) // 64 * 64
        if length % CELL:
            b.problems.append("%s %d: a length must be a multiple of %d" % (name, length, CELL))
            continue
        count[name] = count.get(name, 0) + 1
        tag = name if name in ("straight", "jog", "tee", "shed") else "%s%s" % (name, " %d" % count[name] if count[name] > 1 else "")
        shift = jog_shift(opt) if name == "jog" else 0
        lifted = bool(upper) and "up" in opt
        if upper:
            if name == "jog":
                b.problems.append("a jog cannot be used where the street runs beside the canal (the street would break): use turns")
            e = {"kind": "leg", "frame": Frame(x, y, rot, length), "length": length, "tag": "%d %s" % (n, tag), "lifted": lifted,
                 "stairs": (lifted and "nostairs" not in opt) or "stairs" in opt}
            if name == "shed":
                shed_n += 1
                e["shed"] = "start" if shed_n == 1 else "end"
            elems.append(e)
        elif "up" in opt:
            b.problems.append("%s is to be lifted to the street (\"up\"), but the layout has no street: add a line \"upper left\" or \"upper right\"" % tag)
        if lifted:      # (the module is built on the street; the canal passes below it as a plain stretch)
            m_straight(Mod(b, Frame(x, y, rot, length), "%d the canal under %s" % (n, tag)), ["bare"])
            fr = Frame(x, y, rot, length, flip != (s < 0), shift, dv=s * map_corridor.LIFT_V, dz=map_corridor.LIFT_Z)
        else:
            fr = Frame(x, y, rot, length, flip, shift)
        mod = Mod(b, fr, "%d %s" % (n, tag))
        if name not in ("straight", "jog", "tee", "shed"):
            mod.view(40, 0, F, 0, 4, "coming in")
            mod.cubemap(length // 2, 0)
        MODULES[name][1](mod, opt)
        if name != "straight":
            b.labels.append(fr.pt(length // 2, 0) + (tag,))
        x, y = Frame(x, y, rot, length).pt(length, shift)
    if upper:
        map_corridor.lay(b, elems, upper, lay.get("cars", 2))
    end = (x, y, "ENWS"[rot])
    if lay["end"] and tuple(lay["end"]) != end:
        b.problems.append("the chain comes out at (%d %d) heading %s, not at (%d %d) heading %s as the layout says it must" % (end + tuple(lay["end"])))
    return b, seed, spawn, end


def finish(b, seed, spawn, args):
    vmf, plan = b.vmf, b.plan
    standing = standing_things(b)          # (what the modules stood on the canal's floor, before the dressing adds its own)
    plan.walls()
    if args.test:
        test_extras(vmf, spawn[0], spawn[1], b.vis + ": for testing alone (never in the real map)")
    canal, walled = plan, plan
    if b.upper:      # (the canal's dressing sees the street as wall; the chain link along the walls' tops stays off it)
        import map_corridor
        canal, walled = map_corridor.canal_view(b), map_corridor.fence_view(b)
    ch = Channel(vmf, canal, F, TRIM, b.vis)
    for axis, at, lo, hi in b.pipes:
        ch.pipes(axis, at, lo, hi, b.taken)
    ch.dress(b.no_bank, b.taken, outfalls=True, upright=b.upright, avoid=standing["props"])
    bump = (lambda x, y: sum(f(x, y) for f in b.bumps)) if b.bumps else None
    dish_plan(b, ch, standing["flat"], bump)
    plan.build(vmf)
    dress_canal_walls(b, ch, standing["props"])
    ch.mud(47, skip=b.no_mud, bump=bump)
    settle(b, ch, standing["loose"])
    fences = fence(vmf, walled, 96, b.vis + ": fence along the walls' tops", top=b.rim)
    for (i, j), spec in plan.cells.items():      # (no path node where nobody can stand: a crawl duct)
        if spec[0] == "low" and spec[3] - spec[1] < 72:
            b.blocked.append((i * CELL, j * CELL, (i + 1) * CELL, (j + 1) * CELL))
    ch.nodes(b.node, b.blocked)
    for (i, j) in sorted(b.lifted):       # (what was lifted to the street: its own path nodes, as the canal's rooms get)
        spec = plan.cells.get((i, j))
        if spec and spec[0] != "solid" and i % 2 == 1 and j % 2 == 1 and (i + j) % 4 == 0:
            nx, ny = i * CELL + 32, j * CELL + 32
            if not any(k[0] <= nx < k[2] and k[1] <= ny < k[3] for k in b.blocked):
                b.node(nx, ny, spec[1])
    for (nx, ny, nz) in b.lanes:
        b.node(nx, ny, nz)
    problems, air = check(vmf, seed, [])
    problems = b.problems + problems
    look_at_props(b)
    args.view_list = list(b.views)      # (map_build.py checks them with map_lint.py once the file is written)
    names = [n for n in b.names if n[0] != "clash"]
    seen = {}
    for n in names:
        seen[n[0]] = seen.get(n[0], 0) + 1
    for name, k in sorted(seen.items()):
        if k > 1:
            problems.append("%d things are named %s (the same module twice in one chain: the game could not tell them apart)" % (k, name))
    return ch, fences, problems, names


DISH_DEEP, DISH_REACH = 44, 162      # the canal's floor sags 44 * (1 - e^(-e/162)) at e from its edge: 24 at a 512 canal's middle, 42 at a 1024's
DISH_FLOOR = F - 64                  # the concrete under a dished square (the mud's skin is the floor over it)
LAMP_STEP, LAMP_Z = 768, 300         # the canal's caged lamps: one every 768 along a wall (the walls facing each other take turns), 300 up


def standing_things(b):
    """What the modules stood on the canal's floor: the dish keeps flat round it. Gives {"flat": rectangles seen from
    above, "loose": physics props to settle onto the mud (they would fall there anyway), "props": the box of every
    prop (the outfalls and lamps keep clear of them)}."""
    import re
    import map_assets
    vmf = b.vmf
    flat, loose, props = [], [], []
    for box in [bx for bx, _ in vmf.boxes] + list(getattr(vmf, "shape_boxes", [])):
        if box[2] <= F + 4 and box[5] >= DISH_FLOOR and box[3] > box[0] and box[4] > box[1]:
            flat.append((box[0], box[1], box[3], box[4]))
    for k, text in enumerate(vmf.ents):
        cls = re.search(r'"classname" "(prop_[a-z_]+)"', text)
        if not cls or cls.group(1) == "prop_ragdoll":
            continue
        model = re.search(r'"model" "([^"]+)"', text)
        o = re.search(r'"origin" "(-?\d+) (-?\d+) (-?\d+)"', text)
        if not model or not o:
            continue
        ang = re.search(r'"angles" "(-?[\d.]+) (-?[\d.]+) (-?[\d.]+)"', text)
        x, y, z = (int(t) for t in o.groups())
        bb = map_assets.size(model.group(1))
        if not bb:
            props.append((x - 32, y - 32, z - 32, x + 32, y + 32, z + 32))
            if DISH_FLOOR - 32 <= z <= F + 36:
                flat.append((x - 32, y - 32, x + 32, y + 32))
            continue
        yaw = math.radians(float(ang.group(2)) if ang else 0.0)
        c, sn = math.cos(yaw), math.sin(yaw)
        xs = [x + px * c - py * sn for px in (bb[0], bb[3]) for py in (bb[1], bb[4])]
        ys = [y + px * sn + py * c for px in (bb[0], bb[3]) for py in (bb[1], bb[4])]
        box = (min(xs), min(ys), z + bb[2], max(xs), max(ys), z + bb[5])
        props.append(box)
        if box[2] <= F + 4 and box[5] >= DISH_FLOOR:
            if cls.group(1) == "prop_physics" and "parentname" not in text:
                loose.append((k, box))
            else:
                flat.append((box[0] - 8, box[1] - 8, box[3] + 8, box[4] + 8))
    return {"flat": flat, "loose": loose, "props": props}


def dish_plan(b, ch, flat, bump=None):
    """The canal's floor falls to its middle (the owner, 21 November: Valve's Route Kanal, the lesson valve-canal-dish):
    every square of plain canal floor that no bank stands on, nothing stands on and the mud covers has its concrete
    lowered to DISH_FLOOR, and the mud's skin over it sags with the distance from the dish's edge (the banks' feet, an
    upright wall's foot, a gate, anything standing): 24 at a 512 canal's middle, 42 at a 1024 canal's. The edges stay
    at F, so modules still meet on the plain section. Sets ch.dished and ch.dish; lowers the squares in the plan."""
    cells = ch.cells
    plain = ("open", F, MAT["canal_floor"])
    banks = ch.made.get("bank_rects", [])
    skip = b.no_mud

    def hit(rects, x1, y1, x2, y2):
        return any(r[0] < x2 and r[2] > x1 and r[1] < y2 and r[3] > y1 for r in rects)
    low = set()
    for (i, j), spec in cells.items():
        if spec != plain or (i, j) in b.lifted:
            continue
        x1, y1 = i * CELL, j * CELL
        bx, by = (i // 4) * 256, (j // 4) * 256
        if hit(skip, bx, by, bx + 256, by + 256) or hit(banks, x1, y1, x1 + CELL, y1 + CELL) or hit(flat, x1, y1, x1 + CELL, y1 + CELL):
            continue
        if bump and any(abs(bump(x, y)) > 0.5 for x in (x1, x1 + CELL // 2, x1 + CELL) for y in (y1, y1 + CELL // 2, y1 + CELL)):
            continue
        low.add((i, j))
    sag = {}
    for (i, j) in low:
        for (x, y) in ((i * CELL, j * CELL), ((i + 1) * CELL, j * CELL), (i * CELL, (j + 1) * CELL), ((i + 1) * CELL, (j + 1) * CELL)):
            if (x, y) in sag:
                continue
            gi, gj, k = x // CELL, y // CELL, 0
            while k < 10:      # (how many squares out the nearest one that is not lowered lies)
                ring = [(gi - 1 - k + a, gj - 1 - k + c) for a in range(2 * k + 2) for c in range(2 * k + 2) if a in (0, 2 * k + 1) or c in (0, 2 * k + 1)]
                if any(q not in low for q in ring):
                    break
                k += 1
            sag[(x, y)] = round(DISH_DEEP * (1 - math.exp(-k * CELL / float(DISH_REACH))), 1)
    for c in low:
        b.plan.cells[c] = cells[c] = ("open", DISH_FLOOR, MAT["canal_floor"])
    ch.dished, ch.dish, ch.dish_floor = low, {pt: d for pt, d in sag.items() if d > 0}, DISH_FLOOR
    if low:
        b.notes.append("the canal's floor is dished on %d squares: %d deep at most" % (len(low), max(sag.values()) if sag else 0))


def settle(b, ch, loose):
    """Loose things and floor stains over the dish, brought down onto the mud (a physics prop would fall there; a stain
    must lie on what it marks): a prop by the lowest point under it, a stain moved to the nearest corner of the grid."""
    import re
    surf = ch.surface
    if not surf:
        return

    def height(x, y):
        if (int(x // CELL), int(y // CELL)) not in ch.dished:
            return None      # (on the concrete: a thing partly there stays as it is)
        x0, y0 = int(x // CELL) * CELL, int(y // CELL) * CELL
        q = [surf.get(p) for p in ((x0, y0), (x0 + CELL, y0), (x0, y0 + CELL), (x0 + CELL, y0 + CELL))]
        if None in q:
            return None
        fx, fy = (x - x0) / float(CELL), (y - y0) / float(CELL)
        return (q[0] * (1 - fx) + q[1] * fx) * (1 - fy) + (q[2] * (1 - fx) + q[3] * fx) * fy
    moved = {}
    for k, box in loose:
        hs = [height(min(max(x, box[0] + 1), box[3] - 1), min(max(y, box[1] + 1), box[4] - 1))
              for x in (box[0], (box[0] + box[3]) / 2.0, box[3]) for y in (box[1], (box[1] + box[4]) / 2.0, box[4])]
        if None in hs:
            continue
        drop = int(math.ceil(box[2] - min(min(hs), box[2])))
        if drop < 1:
            continue
        text = b.vmf.ents[k]
        o = re.search(r'"origin" "(-?\d+) (-?\d+) (-?\d+)"', text)
        x, y, z = (int(t) for t in o.groups())
        b.vmf.ents[k] = text.replace(o.group(0), '"origin" "%d %d %d"' % (x, y, z - drop))
        moved[(x, y, z)] = z - drop
    if moved:
        b.props = [(c, mdl, (p[0], p[1], moved.get(p, p[2])), yw, tag) for (c, mdl, p, yw, tag) in b.props]
    for k, text in enumerate(b.vmf.ents):
        if '"classname" "infodecal"' not in text:
            continue
        o = re.search(r'"origin" "(-?\d+) (-?\d+) (-?\d+)"', text)
        x, y, z = (int(t) for t in o.groups())
        if not (F - 1 <= z <= F + 2) or (x // CELL, y // CELL) not in ch.dished:
            continue
        gx, gy = int(round(x / float(CELL))) * CELL, int(round(y / float(CELL))) * CELL
        if (gx, gy) in surf:
            b.vmf.ents[k] = text.replace(o.group(0), '"origin" "%d %d %d"' % (gx, gy, int(round(surf[(gx, gy)])) + 1))


def dress_canal_walls(b, ch, avoid=()):
    """What every stretch of canal gets on its walls (the module review, 20 November: the canal had no light of its own
    and its drains left no mark; then Valve's spacing, 21 November): a caged lamp every 768 along each wall, 300 up,
    the walls facing each other taking turns (about 600 from one lamp to the next across the canal), one in three dead
    (the _off model, no light), each lit one with its own light 30 out; Valve's canal_cap001 ring round every outfall
    (Channel.outfalls), a dark stain under it; graffiti and stains here and there by the ribs, the same every build."""
    import random
    rnd = random.Random(len(b.name) * 977)
    made = getattr(ch, "made", {})

    def yaw_of(axis, side):
        return (90 if side > 0 else 270) if axis == "x" else (0 if side > 0 else 180)

    def at_wall(axis, line, side, along, out):
        return (along, line + side * out) if axis == "x" else (line + side * out, along)
    keep = list(b.taken) + list(avoid)

    def wall_top(axis, line, side, p):
        """How high the wall behind a place on it goes (a street beside the canal is a wall only to its own height)."""
        c = (p // CELL, line // CELL - (1 if side > 0 else 0)) if axis == "x" else (line // CELL - (1 if side > 0 else 0), p // CELL)
        spec = ch.cells.get(c)
        return spec[1] if spec and spec[0] == "solid" and len(spec) > 1 else b.rim
    for (axis, line, side, a, b2) in made.get("walls", []):
        off = 0 if side > 0 else LAMP_STEP // 2
        p = a + 160 + (off - (a + 160)) % LAMP_STEP
        while p <= b2 - 160:
            if wall_top(axis, line, side, p) < F + LAMP_Z + 32:
                p += LAMP_STEP
                continue
            x, y = at_wall(axis, line, side, p, 1)
            lo, hi = min(line, line + side * 16), max(line, line + side * 16)
            box = (p - 12, lo, F + LAMP_Z - 16, p + 12, hi, F + LAMP_Z + 8) if axis == "x" else (lo, p - 12, F + LAMP_Z - 16, hi, p + 12, F + LAMP_Z + 8)
            if not any(box[0] < t[3] + 8 and box[3] > t[0] - 8 and box[1] < t[4] + 8 and box[4] > t[1] - 8 and box[2] < t[5] + 8 and box[5] > t[2] - 8 for t in keep):
                lit = random.Random(p * 31 + line * 17 + side).random() > 0.33
                model = "models/props_c17/light_cagelight02_%s.mdl" % ("on" if lit else "off")
                b.vmf.point("prop_static", (x, y, F + LAMP_Z), {"model": model, "angles": "0 %d 0" % yaw_of(axis, side), "solid": "0", "disableshadows": "1",
                                                                 "fademindist": "-1", "fadescale": "1"}, b.vis + ": canal lamps")
                if lit:
                    lx, ly = at_wall(axis, line, side, p, 30)
                    b.vmf.point("light", (lx, ly, F + LAMP_Z - 10), {"_light": "255 214 170 70", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"},
                                b.vis + ": canal lamps")
            p += LAMP_STEP
    for k, (axis, line, side, at) in enumerate(made.get("ribs", [])):
        if rnd.random() < 0.18:
            wx, wy = (at + 120, line) if axis == "x" else (line, at + 120)
            b.vmf.point("infodecal", (wx, wy, F + 200 + rnd.randrange(0, 120)), {"texture": rnd.choice(GRIME["graffiti"] + GRIME["stain"])}, b.vis + ": canal grime")
    for (axis, line, side, at, z, out) in made.get("outfalls", []):
        x, y = at_wall(axis, line, side, at, out + 7 if not out else out - 5)
        b.vmf.point("prop_static", (x, y, z), {"model": "models/props_canal/canal_cap001.mdl", "angles": "0 %d 0" % yaw_of(axis, side), "solid": "6",
                                               "disableshadows": "1", "fademindist": "-1", "fadescale": "1"}, b.vis + ": canal outfalls")
        if out:      # (the stain runs down the bank's slope under the pipe's mouth)
            wx, wy = at_wall(axis, line, side, at, 96)
            b.vmf.point("infodecal", (wx, wy, F + BANK - 96), {"texture": rnd.choice(GRIME["drain"])}, b.vis + ": canal grime")
        else:
            wx, wy = at_wall(axis, line, side, at, 0)
            b.vmf.point("infodecal", (wx, wy, F + 48), {"texture": rnd.choice(GRIME["drain"])}, b.vis + ": canal grime")
    for (axis, line, side, at, z) in made.get("stubs", []):
        wx, wy = (at, line) if axis == "x" else (line, at)
        b.vmf.point("infodecal", (wx, wy, z - 44), {"texture": rnd.choice(GRIME["drain"])}, b.vis + ": canal grime")


def look_at_props(b):
    """Every prop whose size is known: does it stand in a wall, or under the floor? Said as "LOOK" lines (a model's box is
    often bigger than the model, so these are things to look at, not failures)."""
    import map_assets
    cells = b.plan.cells
    for cls, model, (x, y, z), yaw, tag in b.props:
        bb = map_assets.size(model)
        if not bb:
            continue
        c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
        xs = [x + px * c - py * s for px in (bb[0], bb[3]) for py in (bb[1], bb[4])]
        ys = [y + px * s + py * c for px in (bb[0], bb[3]) for py in (bb[1], bb[4])]
        x1, x2, y1, y2 = min(xs) + 6, max(xs) - 6, min(ys) + 6, max(ys) - 6
        bad = None
        for i in range(int(x1 // CELL), int(x2 // CELL) + 1):
            for j in range(int(y1 // CELL), int(y2 // CELL) + 1):
                spec = cells.get((i, j))
                if spec is None or spec[0] == "solid":
                    bad = "reaches into the wall at (%d %d)" % (i * CELL, j * CELL)
                elif spec[0] in ("low", "under") and z + bb[5] > spec[3] + 6 and z < spec[3]:
                    bad = "is %d taller than the roof over it" % (z + bb[5] - spec[3])
        here = cells.get((int(x // CELL), int(y // CELL)))
        if here and here[0] != "solid" and z + bb[2] < here[1] - 6:
            bad = "is %d under the floor" % (here[1] - (z + bb[2]))
        if bad:
            b.notes.append("LOOK: %s's %s at (%d %d %d) %s (it is %d by %d and %d high)" % (
                tag, model.split("/")[-1], x, y, z, bad, bb[3] - bb[0], bb[4] - bb[1], bb[5] - bb[2]))


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
    if lay.get("ground") == "street":
        import map_town
        b, seed, spawn, end = map_town.build(lay, args)
    else:
        b, seed, spawn, end = build_chain(lay, args)
    ch, fences, problems, names = finish(b, seed, spawn, args)
    report(b, ch, fences, problems, names, end, "chain %s (%d modules)" % (lay["name"], len(lay["modules"])))
    if getattr(args, "ascii", False):
        import map_town
        print(map_town.ascii_plan(b))
    if args.preview:
        picture(b, args.preview)
    args.expect_overlap = set()
    args.out_name = "lc_%s%s.vmf" % (lay["name"], "_test" if args.test else "")
    args.after_write = (lambda path: take_views(b, path, args.views, lay["name"])) if args.views else None
    return b.vmf, problems


def module(args):
    if args.name not in MODULES:
        print("modules: ")
        for k, info in MODULES.items():
            print("  %-10s %5d long  %s" % (k, info[0], info[2]))
        raise SystemExit(1)
    lay = {"name": "mod_" + args.name, "start": tuple(args.origin or (0, 0)), "heading": args.heading or "E", "rim": args.rim or 784, "end": None,
           "modules": alone(args.name, list(args.opt or []) + (["flip"] if args.flip else []))}
    b, seed, spawn, end = build_chain(lay, args)
    ch, fences, problems, names = finish(b, seed, spawn, args)
    report(b, ch, fences, problems, names, end, "module %s (%s)" % (args.name, MODULES[args.name][2]))
    if args.preview:
        picture(b, args.preview)
    args.expect_overlap = set()
    args.out_name = "lc_mod_%s%s.vmf" % (args.name, "_test" if args.test else "")
    args.after_write = (lambda path: take_views(b, path, args.views, args.name)) if args.views else None
    return b.vmf, problems
