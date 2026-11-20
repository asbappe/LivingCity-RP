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

def m_straight(m, opt):
    """Plain canal. "straight 1536": that long. Add "bridge" for a street carried over its middle, "pipes" for a pair of
    pipes across it, "bare" for nothing left lying in it (otherwise a few odds and ends, the same every time)."""
    L = m.fr.length
    m.open(0, -256, L, 256)
    if "bridge" in opt:
        m.bridge(L // 2 - 128, L // 2 + 128, -256, 256)
    if "pipes" in opt:
        at = L // 4 if "bridge" in opt else L // 2
        (x1, y1), (x2, y2) = m.fr.pt(at, -256), m.fr.pt(at, 256)
        m.b.pipes.append(("x", x1, min(y1, y2), max(y1, y2)) if m.fr.ax("u") == "x" else ("y", y1, min(x1, x2), max(x1, x2)))
    if "bare" not in opt and L >= 512:
        x, y = m.fr.pt(0, 0)
        m.scatter(64, -110, L - 64, 110, L // 420, 1000 + (x * 7 + y * 13) % 997)


def m_shed(m, opt):
    """Plain canal, and on the street beside it a brick shed over the tracks, where a train waits out of sight. A
    straight run needs two for a train: one to come out of, one to go into. Only where the layout has a street
    ("upper left"). "shed 2304": that long (by itself it is the length of the train and a little over)."""
    m.open(0, -256, m.fr.length, 256)
    if not m.b.upper:
        m.b.problems.append("%s: a shed needs a street to stand on: add a line \"upper left\" or \"upper right\" to the layout" % m.tag)


def m_corner(m, opt):
    m.open(0, -256, 512, 256)


def jog_shift(opt):
    n = [int(w) for w in opt if w.lstrip("-").isdigit()]
    return (n[0] if n else 768) * (-1 if "right" in opt else 1)


def m_jog(m, opt):
    """The canal steps sideways, to break a long view: "jog left 768" (the default), "jog right 1024"."""
    s = jog_shift(opt)
    m.open(0, -256, 768, 256)
    m.open(256, min(-256, s - 256), 768, max(256, s + 256))
    m.open(256, s - 256, 1024, s + 256)


def m_tee(m, opt):
    """A way off to the left: a standard gate in the left wall (512 wide, 256 high), capped until another piece, or
    another layout's start, is joined to it."""
    b = m.b
    m.open(0, -256, 512, 256)
    m.low(0, 256, 512, 512, F + GATE_HIGH)
    gate_cap(b.vmf, m.fr.box(0, 448, F, 512, 512, F + GATE_HIGH), m.fr.box(0, 424, F, 512, 432, F + GATE_HIGH), m.fr.ax("u"),
             "%s: %s side gate's cap (delete to join)" % (b.vis, m.tag))
    m.portal(0, 382, F, 512, 384, F + GATE_HIGH)
    b.plan.keep_out.append(m.fr.rect(-64, 512, 576, 576))
    m.blocked(0, 384, 512, 512)
    m.side(0, 256, 512, 512)
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
    with a concrete collar and an arched roof; a junction chamber round a railed sump of standing water, two inflow
    pipes, a valve wheel, a lamp; then thirteen steps down to the sewers' height (z 288), a grate, and a cap to delete
    where the owner joins it to a sewer of theirs.
    Named for the game: lc_drain_grate (a func_door: Open lifts it, Close drops it), lc_drain_junction (the chamber).
    Unchecked: ambient/water/water_flow_loop1.wav."""
    from map_build import bar_row
    b = m.b
    m.open(0, -256, 1024, 256)
    m.low(384, 256, 640, 768, F + 192)                       # the mouth and its pipe
    m.low(256, 768, 768, 1280, F + 256)                      # the junction chamber...
    m.low(384, 896, 640, 1152, F + 256, floor=F - 64)        # ...and the sump in its middle
    m.low(384, 1280, 640, 1664, SEWER + 240, floor=SEWER)    # down to the sewers
    m.side(256, 256, 768, 1664)
    m.portal(384, 318, F, 640, 320, F + 192)
    m.det([(368, 240, F, 384, 256, F + 208), (640, 240, F, 656, 256, F + 208), (368, 240, F + 192, 656, 256, F + 208)], MAT["beam"])
    m.shapes([prism([(384, F + 192), (384, F + 128), (448, F + 192)], "y", 256, 768, MAT["canal_wall"]),
              prism([(640, F + 192), (640, F + 128), (576, F + 192)], "y", 256, 768, MAT["canal_wall"])])
    m.taken(360, 232, F, 664, 256, F + 216)
    m.water(384, 896, 640, 1152, F - 64, F - 40)
    rail = [(384, 896, F + 36, 640, 900, F + 40), (384, 1148, F + 36, 640, 1152, F + 40), (384, 896, F + 36, 388, 1152, F + 40), (636, 896, F + 36, 640, 1152, F + 40)]
    rail += [(u, v, F, u + 4, v + 4, F + 36) for u in (384, 448, 508, 572, 636) for v in (896, 1148)] + [(u, v, F, u + 4, v + 4, F + 36) for u in (384, 636) for v in (960, 1022, 1086)]
    m.det(rail, MAT["bars"])
    m.shapes([prism(octagon(1024, F + 150, 40), "x", 256, 300, MAT["bars"], MAT["black"]), prism(octagon(1024, F + 150, 40), "x", 724, 768, MAT["bars"], MAT["black"]),
              prism(octagon(320, F + 70, 18), "y", 768, 774, MAT["bars"])])
    m.det([(316, 768, F + 66, 324, 780, F + 74), (300, 768, F + 20, 340, 772, F + 30)], MAT["bars"])
    m.lamp(512, 840, F + 214, "190 210 170 70", hang=34)
    m.lamp(512, 1216, F + 214, "190 210 170 40", hang=34)
    m.sound("ambient/water/water_flow_loop1.wav", 512, 1024, F, radius=600, volume=3)
    m.target("lc_drain_junction", 512, 832, F + 8, 90)
    run = m.steps(1280 + 12 * 13, 384, 640, SEWER, F - 8, "v", -1)   # 13 steps, tops z 392 down to 296
    m.blocked(384, 1280, 640, 1280 + run + 16)
    m.blocked(384, 896, 640, 1152)
    m.lane(512, 1264, F)
    m.lane(512, 1280 + run + 48, SEWER)
    for u, v in ((320, 832), (320, 1024), (320, 1216), (704, 1024)):
        m.lane(u, v)
    rows = bar_row(m.fr.box(384, 1544, SEWER, 640, 1552, SEWER + 240), m.fr.ax("u"))
    b.vmf.brush_entity("func_door", {"targetname": "lc_drain_grate", "movedir": "-90 0 0", "speed": "30", "lip": "24", "wait": "-1", "spawnflags": "32",
                                     "spawnpos": "0", "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0",
                                     "noise1": "MetalGrate.ScrapeSmooth", "noise2": "MetalGrate.ImpactSoft", "renderamt": "255", "rendercolor": "255 255 255",
                                     "renderfx": "0", "rendermode": "0", "disableshadows": "1"}, rows, MAT["bars"], m.dv)
    b.names.append(("lc_drain_grate", "func_door", m.tag))
    m.test_button((384, 1500, SEWER + 48, 392, 1516, SEWER + 64), [("OnIn", "lc_drain_grate", "Open"), ("OnOut", "lc_drain_grate", "Close")])
    m.world((384, 1600, SEWER, 640, 1664, SEWER + 240), MAT["black"], vis="%s: the drain's sewer end (delete to join a sewer)" % b.vis)
    b.plan.keep_out.append(m.fr.rect(320, 1664, 704, 1728))
    m.blocked(384, 1536, 640, 1664)
    m.static("models/props_junk/wood_pallet001a.mdl", 300, 1230, 20)
    m.static("models/props_c17/oildrum001.mdl", 720, 1230, 0)
    m.loose("models/props_junk/wood_crate001a.mdl", 716, 820, 30)
    m.view(512, 60, F, 90, 0, "the mouth")
    m.view(512, 790, F, 90, 6, "the chamber")
    m.view(320, 1230, F, 20, 12, "to the steps")
    b.notes.append("%s: the sewer end is at %s, floor z %d, 256 wide and 240 high: move or stretch it to a sewer of the map's, then delete its cap" % (
        m.tag, "(%d %d)" % m.fr.pt(512, 1664), SEWER))


def m_overflow(m, opt):
    """2. The overflow toward Ravenholm. A spillway in the left wall, its apron stepping down into the canal, shut by a
    steel sluice plate on two lifting rods under a winch housing, red lamps either side. Behind the plate a ribbed
    channel runs on to a cap ("delete to join Ravenholm"). Driftwood and a body lie against the plate.
    "overflow 1280": how far the channel reaches from the canal's middle (default 1024).
    Named for the game: lc_overflow_sluice (a func_door: Open lifts it), lc_overflow_moan (a sound from beyond the
    plate, silent until told: PlaySound), lc_overflow_far (the channel's far end).
    Unchecked: ambient/creatures/town_zombie_call1.wav, models/humans/charple02.mdl."""
    reach = int(opt[0]) if opt and opt[0].isdigit() else 1024
    steel = MM["steel"]
    m.open(0, -256, 1024, 256)
    m.low(320, 256, 704, 640, F + 192)
    m.low(384, 640, 640, reach, F + 192)
    m.side(320, 256, 704, reach)
    m.det([(320, 256, F, 704, 272, F + 16), (320, 208, F, 704, 256, F + 12), (320, 160, F, 704, 208, F + 6)], MAT["beam"])      # the weir's sill and apron
    m.door("lc_overflow_sluice", [(320, 288, F + 16, 704, 304, F + 192), (440, 293, F + 192, 446, 299, F + 280), (578, 293, F + 192, 584, 299, F + 280)],
           steel, "-90 0 0", speed=24, lip=104)
    m.portal(320, 295, F, 704, 297, F + 192)
    m.test_button((304, 240, F + 48, 320, 248, F + 64), [("OnIn", "lc_overflow_sluice", "Open"), ("OnOut", "lc_overflow_sluice", "Close")])
    m.det([(304, 248, F, 320, 256, F + 224), (704, 248, F, 720, 256, F + 224), (304, 248, F + 208, 720, 256, F + 224)], steel)   # its frame
    m.det([(416, 216, F + 240, 608, 256, F + 304)], steel)                                                                        # the winch housing
    m.shapes([prism(octagon(236, F + 272, 22), "x", 608, 620, MAT["bars"]), prism(octagon(236, F + 272, 22), "x", 404, 416, MAT["bars"])])
    m.taken(296, 200, F, 728, 256, F + 312)
    for u in (280, 744):
        m.det([(u - 6, 244, F + 250, u + 6, 256, F + 262)], steel)
        m.glow(u, 240, F + 256, "255 50 30", 0.25)
        m.light(u, 232, F + 256, "255 60 40 30")
    for v in range(704, reach - 64, 128):                    # the channel's ribs
        m.det([(384, v, F + 176, 640, v + 16, F + 192), (384, v, F, 392, v + 16, F + 176), (632, v, F, 640, v + 16, F + 176)], MAT["beam"])
    m.world((384, reach - 64, F, 640, reach, F + 192), MAT["black"], vis="%s: the overflow's far end (delete to join Ravenholm)" % m.b.vis)
    m.b.plan.keep_out.append(m.fr.rect(320, reach, 704, reach + 64))
    m.blocked(384, reach - 128, 640, reach)
    m.blocked(320, 144, 704, 320)
    m.light(512, reach - 110, F + 150, "255 70 50 35")
    m.light(512, 480, F + 150, "200 120 90 30")
    m.sound("ambient/creatures/town_zombie_call1.wav", 512, reach - 96, F + 60, radius=1400, volume=8, name="lc_overflow_moan", on=False)
    m.target("lc_overflow_far", 512, reach - 80, F + 8, 270)
    m.static("models/props_debris/concrete_chunk01a.mdl", 250, 130, 40)
    m.static("models/props_debris/broken_pile001a.mdl", 780, 150, 200)
    m.det([(430, 170, F + 6, 600, 182, F + 10), (470, 150, F + 6, 482, 250, F + 12), (530, 190, F + 12, 640, 200, F + 16)], MM["wood"])
    m.loose("models/props_junk/wood_pallet001a.mdl", 560, 120, 25)
    m.body("models/humans/charple02.mdl", 520, 420, 70)
    m.body("models/humans/charple02.mdl", 500, 130, 200)
    m.decal("decals/decalstain002a", 512, 100, F + 1)
    m.lane(512, 60)
    m.lane(512, 480)
    m.view(512, -120, F, 90, -6, "the sluice")
    m.view(512, 560, F, 270, 0, "behind the plate")
    m.b.notes.append("%s: the overflow's far end is at (%d %d), floor z %d, 256 wide and 192 high" % ((m.tag,) + m.fr.at(512, reach, F)))


def m_shanty(m, opt):
    """4. The shantytown under a street bridge. The canal widens into a basin on its left; a boardwalk runs along the
    basin's back, with a card room, a trader's stall with a counter and shelves, and a bunk room on it; under the street
    between them, a fire drum with seats round it and a stove. Tin windbreaks along the basin's edge, lamps on a cable
    from pole to pole, washing on a line, a boat pulled up, a notice board.
    Named for the game (places only): lc_shanty_cards (the card room's table), lc_shanty_fund (the stall, for the fund's
    screen), lc_shanty_soup (under the street, for the soup), lc_shanty_fire (the drum), lc_shanty_board (the notices).
    Unchecked: ambient/fire/fire_small_loop2.wav, env_smokestack, the cable (move_rope), sprites/light_glow03.vmt."""
    wood, tin, beam = MM["wood"], MM["tin"], MM["beam_wood"]
    m.open(0, -256, 1536, 256)
    m.open(256, 256, 1280, 640)
    m.no_bank(256, 400, 1280, 648)
    m.bridge(640, 896, -256, 640, far_pier=False)
    # the boardwalk the shacks stand on, and steps down off its ends
    m.det([(264, 400, F, 632, 632, F + 8), (904, 400, F, 1272, 632, F + 8)], wood)
    m.det([(264, 388, F, 632, 400, F + 4), (904, 388, F, 1272, 400, F + 4)], beam)
    z = F + 8
    m.hut(272, 440, 520, 632, z, wood)                                    # the card room
    m.static("models/props_c17/furnituretable002a.mdl", 396, 544, 0, z=z)
    m.static("models/props_c17/furniturechair001a.mdl", 340, 544, 0, z=z)
    m.static("models/props_c17/furniturechair001a.mdl", 452, 544, 180, z=z)
    m.lamp(396, 544, z + 96, "255 190 110 45")
    m.target("lc_shanty_cards", 396, 544, z + 36)
    m.hut(912, 456, 1088, 632, z, tin, open_front=True)                   # the trader's stall
    m.det([(920, 456, z, 1080, 480, z + 40)], beam)
    m.det([(924, 600, z + 40 + 30 * k, 1076, 624, z + 44 + 30 * k) for k in range(2)], wood)
    m.static("models/props_junk/wood_crate001a.mdl", 950, 560, 15, z=z)
    m.static("models/props_c17/shelfunit01a.mdl", 1050, 560, 180, z=z)
    m.lamp(1000, 520, z + 96, "255 190 110 45")
    m.target("lc_shanty_fund", 1000, 560, z + 48, 270)
    m.hut(1104, 432, 1272, 632, z, wood)                                  # the bunk room
    m.loose("models/props_c17/furnituremattress001a.mdl", 1150, 560, 90, z=z)
    m.loose("models/props_c17/furnituremattress001a.mdl", 1226, 560, 90, z=z)
    m.det([(1112, 600, z + 60, 1264, 624, z + 64)], wood)
    m.light(1188, 540, z + 90, "255 180 100 25")
    # under the street: the fire drum and seats, the stove and its pipe, a table for the soup
    m.static("models/props_c17/oildrum001.mdl", 768, 400, 0)
    m.point("env_fire", 768, 400, F + 44, {"health": "30", "firesize": "28", "fireattack": "4", "firetype": "0", "spawnflags": "7", "ignitionpoint": "32", "damagescale": "0.1"})
    m.light(768, 400, F + 90, "255 150 70 110")
    m.sound("ambient/fire/fire_small_loop2.wav", 768, 400, F + 50, radius=500, volume=5)
    m.smoke(768, 400, F + 60, size=10, length=120, rate=8)
    m.target("lc_shanty_fire", 768, 400, F + 8)
    for u, v, yaw in ((700, 360, 20), (830, 350, 150), (760, 480, 260)):
        m.static("models/props_junk/wood_crate001a.mdl", u, v, yaw)
    m.static("models/props_c17/furniturecouch001a.mdl", 690, 596, 270)
    m.static("models/props_c17/furniturestove001a.mdl", 856, 604, 270)
    m.det([(852, 620, F + 40, 860, 628, TRIM - 44)], MAT["bars"])
    m.static("models/props_c17/furnituretable001a.mdl", 780, 560, 0)
    m.target("lc_shanty_soup", 780, 560, F + 40)
    m.blocked(660, 520, 890, 640)
    m.blocked(690, 340, 840, 490)
    # windbreaks of tin along the basin's edge, on posts
    for (a, c) in ((300, 560), (980, 1240)):
        m.det([(a, 264, F, c, 268, F + 88)], tin)
        m.det([(u, 262, F, u + 6, 270, F + 96) for u in range(a, c + 1, 130)], beam)
        m.blocked(a - 8, 248, c + 8, 284)
    # lamps on a cable from pole to pole across the basin; washing on a line
    poles = [(290, 330), (620, 330), (916, 330), (1250, 330)]
    m.det([(u - 3, v - 3, F, u + 3, v + 3, F + 150) for u, v in poles], beam)
    m.rope([(u, v, F + 148) for u, v in poles], slack=30)
    for a, c in zip(poles, poles[1:]):
        u, v = (a[0] + c[0]) // 2, a[1]
        m.glow(u, v, F + 126, "255 200 130", 0.2)
        m.light(u, v, F + 120, "255 190 120 30")
    m.rope([(520, 440, z + 100), (640, 600, F + 150)], slack=20, width=1)
    m.det([(540 + 26 * k, 462 + 34 * k, F + 104 - 2 * k, 544 + 26 * k, 480 + 34 * k, F + 136 - 2 * k) for k in range(4)], wood)
    # a boat pulled up, a notice board, what is left lying
    m.static("models/props_canal/boat001a.mdl", 1340, 150, 20)
    m.blocked(1260, 60, 1420, 250)
    m.det([(560, 262, F, 566, 270, F + 110), (626, 262, F, 632, 270, F + 110), (560, 264, F + 50, 632, 268, F + 108)], wood)
    m.decal("decals/decalposter014a", 580, 263, F + 80)
    m.decal("decals/decal_posters005a", 612, 263, F + 82)
    m.target("lc_shanty_board", 596, 240, F + 8, 90)
    m.scatter(280, 280, 600, 380, 4, 11)
    m.scatter(940, 280, 1250, 380, 4, 12)
    m.static("models/props_junk/wood_crate002a.mdl", 560, 600, 0)
    m.loose("models/props_junk/wood_pallet001a.mdl", 600, 300, 30)
    for u, v in ((396, 360), (600, 440), (768, 290), (1000, 360), (1188, 360), (396, 420), (1000, 420)):
        m.lane(u, v)
    m.view(200, -100, F, 30, 0, "the basin")
    m.view(768, 250, F, 90, 0, "under the street")
    m.view(396, 420, F + 8, 90, 0, "the card room")
    m.view(1000, 380, F + 8, 90, 0, "the stall")
    m.view(1400, -60, F, 150, 0, "looking back")


def m_vort(m, opt):
    """6. The vortigaunt culvert: a low side drain in the left wall with a pipe along its roof, turning twice (nobody
    in the canal can see or shoot into its end), a hanging of strips half across its last turn, and a dead-end chamber:
    a ring of stones round a fire with a pot on a tripod, three mats, a shelf, things drying on a line, a seep of water
    in one corner, a faint green glow in the air.
    Named for the game: lc_vort_fire, lc_vort_seat_1 to _3 (the mats, facing the fire).
    Unchecked: env_fire, ambient/fire/fire_small_loop2.wav, the line (move_rope)."""
    m.open(0, -256, 1024, 256)
    m.low(384, 256, 576, 896, F + 144)
    m.low(576, 704, 896, 896, F + 144)
    m.low(704, 896, 1024, 1280, F + 208)
    m.low(896, 1152, 1024, 1280, F + 208, floor=F - 16)      # the seep
    m.side(384, 256, 1024, 1280)
    m.portal(384, 318, F, 576, 320, F + 144)
    m.water(896, 1152, 1024, 1280, F - 16, F - 6)
    m.shapes([prism(octagon(408, F + 126, 10), "y", 256, 880, MAT["bars"])])
    m.det([(400, 256 + 150 * k, F + 136, 416, 262 + 150 * k, F + 144) for k in range(1, 5)], MAT["bars"])
    m.det([(704 + 24 * k, 892, F + 16 + 6 * (k % 2), 722 + 24 * k, 896, F + 144) for k in range(4)], MM["wood"])     # the hanging
    fu, fv = 864, 1056
    m.det([(fu - 24, fv - 24, F, fu + 24, fv + 24, F + 4)], MAT["beam"])
    ring = [(60, 0), (42, 42), (0, 60), (-42, 42), (-60, 0), (-42, -42), (0, -60), (42, -42)]
    m.det([(fu + a - 9, fv + c - 9, F, fu + a + 9, fv + c + 9, F + 8 + 3 * (k % 2)) for k, (a, c) in enumerate(ring)], MAT["beam"])
    m.shapes([prism([(fu + 40, F), (fu + 46, F), (fu + 4, F + 84), (fu - 2, F + 84)], "y", fv - 3, fv + 3, MAT["bars"]),
              prism([(fu - 40, F), (fu - 46, F), (fu - 4, F + 84), (fu + 2, F + 84)], "y", fv - 3, fv + 3, MAT["bars"]),
              prism([(fv + 40, F), (fv + 46, F), (fv + 4, F + 84), (fv - 2, F + 84)], "x", fu - 3, fu + 3, MAT["bars"])])
    m.det([(fu - 10, fv - 10, F + 36, fu + 10, fv + 10, F + 52), (fu - 1, fv - 1, F + 52, fu + 1, fv + 1, F + 84)], MM["steel"])     # the pot
    m.point("env_fire", fu, fv, F + 6, {"health": "30", "firesize": "30", "fireattack": "4", "firetype": "0", "spawnflags": "7", "ignitionpoint": "32", "damagescale": "0.2"})
    m.light(fu, fv, F + 70, "255 140 60 120")
    m.sound("ambient/fire/fire_small_loop2.wav", fu, fv, F + 30, radius=500, volume=5)
    m.target("lc_vort_fire", fu, fv, F + 8)
    for k, (a, c, yaw) in enumerate(((-110, 60, 330), (20, 130, 260), (110, -70, 150))):
        m.det([(fu + a - 34, fv + c - 22, F, fu + a + 34, fv + c + 22, F + 3)], MM["wood"])
        m.target("lc_vort_seat_%d" % (k + 1), fu + a, fv + c, F + 8, yaw)
    m.det([(712, 1262, F + 56, 860, 1280, F + 60), (712, 1262, F + 96, 860, 1280, F + 100)], MM["wood"])           # a shelf on the back wall
    m.rope([(712, 920, F + 150), (1010, 1010, F + 150)], slack=24, width=1)
    m.det([(770 + 60 * k, 936 + 18 * k, F + 112, 774 + 60 * k, 950 + 18 * k, F + 140) for k in range(4)], MM["wood"])
    for u, v, z in ((760, 1150, F + 120), (960, 980, F + 100), (940, 1210, F + 40)):
        m.glow(u, v, z, "120 255 170", 0.18)
    m.light(940, 1210, F + 50, "110 255 170 14")
    m.static("models/props_junk/wood_crate001a.mdl", 740, 1236, 20)
    m.static("models/props_c17/oildrum001.mdl", 724, 1140, 0)
    m.loose("models/props_c17/furnituremattress001a.mdl", 970, 1000, 30)
    m.blocked(800, 990, 930, 1120)
    m.lane(480, 800)
    m.lane(800, 800)
    m.lane(760, 1100)
    m.view(480, 100, F, 90, 0, "the mouth")
    m.view(640, 800, F, 20, 0, "at the turn")
    m.view(740, 940, F, 45, 4, "the chamber")


def m_relay(m, opt):
    """7. Cubbage's relay. A concrete quay against the right wall, 128 high with steps up its upstream end, and on it a tin hut:
    inside, the set on a bench, a chair, a cot, a map board. Beside it a lattice mast that stands about 350 over the canal's
    walls, with rungs, two dish aerials, guy wires to the pier and the wall, a red lamp at its tip, and an aerial wire
    across the canal to the far wall. A generator built of brushes hums behind the hut; fuel drums beside it.
    Named for the game: lc_relay_radio (the set, a prop_dynamic), lc_relay_hum (the generator's sound: StopSound),
    lc_relay_lamp (the red lamp's glow: HideSprite, ShowSprite), lc_relay_mast (the mast's foot), lc_relay_seat.
    Unchecked: models/props_lab/citizenradio.mdl, ambient/machines/diesel_engine_idle1.wav, the cables (move_rope)."""
    b = m.b
    top, tin, steel = F + 128, MM["tin"], MM["steel"]
    m.open(0, -256, 1024, 256)
    m.open(320, -256, 832, -64, floor=top, mat=MAT["quay_floor"])
    m.side(320, -256, 832, -64)
    m.no_bank(120, -264, 840, -56)                       # (a quay with upright sides, and steps up its upstream end)
    m.steps(128, -256, -192, F, top, "u", 1)
    m.det([(128, -196, F, 320, -192, F + 8)], MAT["beam"])
    m.blocked(120, -256, 320, -180)
    m.lane(112, -224, F)
    m.lane(336, -224, top)
    # the hut
    m.hut(344, -248, 544, -96, top, tin, high=104, front="hi")
    m.det([(352, -240, top, 392, -200, top + 34)], MM["beam_wood"])                        # the bench the set stands on
    m.dynamic("models/props_lab/citizenradio.mdl", 372, -220, 90, z=top + 34, name="lc_relay_radio")
    m.static("models/props_c17/furniturechair001a.mdl", 410, -200, 180, z=top)
    m.target("lc_relay_seat", 410, -200, top + 8, 180)
    m.det([(500, -240, top + 8, 536, -168, top + 20)], MM["wood"])                          # a cot
    m.det([(396, -243, top + 44, 480, -240, top + 96)], MM["wood"])                         # a map board on the back wall
    m.decal("decals/decalposter014a", 430, -241, top + 70)
    m.lamp(444, -170, top + 92, "255 200 130 30")
    # the mast: four legs, braces every 128, rungs up one side, two dishes, a rod and a red lamp on top
    u1, v1, u2, v2, tip = 624, -224, 720, -128, b.rim + 256
    legs = [(u, v, top, u + 8, v + 8, tip) for u in (u1, u2 - 8) for v in (v1, v2 - 8)]
    braces = []
    for z in range(top + 120, tip, 128):
        braces += [(u1, v1 + 2, z, u2, v1 + 6, z + 4), (u1, v2 - 6, z, u2, v2 - 2, z + 4), (u1 + 2, v1, z, u1 + 6, v2, z + 4), (u2 - 6, v1, z, u2 - 2, v2, z + 4)]
    rungs = [(u1 + 30, v2 - 4, z, u1 + 66, v2, z + 3) for z in range(top + 24, tip - 8, 24)]
    m.det(legs + braces + rungs + [(u1, v1, tip, u2, v2, tip + 4), (668, -180, tip + 4, 676, -172, tip + 100)], MAT["bars"])
    m.shapes([prism(octagon(-176, tip - 150, 34), "x", u2, u2 + 10, steel), prism(octagon(672, tip - 280, 28), "y", v2, v2 + 10, steel)])
    m.point("env_sprite", 672, -176, tip + 104, {"targetname": "lc_relay_lamp", "model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "220",
                                                 "rendercolor": "255 40 30", "scale": "0.5", "framerate": "10.0", "GlowProxySize": "2.0", "HDRColorScale": "1.0",
                                                 "renderfx": "0", "spawnflags": "1"}, m.lv)
    for (gu, gv, gz) in ((330, -72, top + 4), (824, -72, top + 4), (824, -250, top + 220)):
        m.rope([(672, -176, tip - 40), (gu, gv, gz)], slack=10, width=1)
    m.rope([(672, -176, tip), (700, 250, b.rim + 90)], slack=60, width=1)                   # the aerial, across to the far wall
    m.rope([(540, -100, top + 100), (628, -132, top + 300)], slack=30, width=1)             # the hut's feed
    m.target("lc_relay_mast", 672, -100, top + 8, 90)
    # the generator and its fuel
    m.det([(752, -240, top, 816, -176, top + 40), (760, -232, top + 40, 808, -184, top + 52)], steel)
    m.shapes([prism(octagon(-200, top + 76, 8), "x", 772, 780, MAT["bars"])])
    m.det([(772, -204, top + 52, 780, -196, top + 76)], MAT["bars"])
    m.sound("ambient/machines/diesel_engine_idle1.wav", 784, -208, top + 30, radius=600, volume=5, name="lc_relay_hum")
    m.rope([(784, -180, top + 44), (544, -150, top + 96)], slack=14, width=1)
    m.static("models/props_c17/oildrum001.mdl", 580, -236, 0, z=top)
    m.loose("models/props_c17/oildrum001.mdl", 590, -196, 0, z=top)
    m.loose("models/props_junk/wood_crate001a.mdl", 780, -110, 30, z=top)
    m.blocked(608, -240, 832, -112)
    m.taken(320, -256, F, 832, -64, tip)
    for u, v in ((580, -90), (444, -80), (760, -90)):
        m.lane(u, v, top)
    m.view(120, 120, F, 325, -14, "the mast")
    m.view(444, -30, top, 270, 0, "into the hut")
    m.view(900, 100, F, 215, -10, "from downstream")
    b.notes.append("%s: the mast's tip is at z %d, %d over the walls' tops" % (m.tag, tip + 100, tip + 100 - b.rim))


def m_ash(m, opt):
    """10. The ash outfall (the owner: "just trash and burnt corpses"). High in the left wall, a chute's mouth: a real
    hole under a concrete hood, barred, black behind, with a steel tray. Under it a heap of ash and rubbish 110 high
    with the burnt dead in it, thin smoke rising from it; a second, smaller heap; a tipped barrow built of brushes.
    No way in or out.
    Named for the game: lc_ash_heap (the top of the heap).
    Unchecked: the garbage pile and garbage bag models, models/humans/charple01..04.mdl, metalbucket01a, env_smokestack."""
    m.open(0, -256, 768, 256)
    lo, hi = F + 208, F + 336
    m.low(320, 256, 448, 320, hi, floor=lo, mat=MAT["black"])
    m.side(320, 256, 448, 320)
    m.blocked(320, 256, 448, 320)
    m.det([(320, 312, lo, 448, 320, hi)], MAT["black"])
    m.bars((320, 258, lo, 448, 266, hi), "u")
    m.det([(304, 184, lo - 16, 320, 256, hi + 16), (448, 184, lo - 16, 464, 256, hi + 16), (304, 184, hi, 464, 256, hi + 16)], MAT["beam"])
    m.shapes([prism([(168, lo - 48), (256, lo), (256, lo - 16), (168, lo - 64)], "x", 320, 448, MM["steel"])])
    m.taken(296, 160, lo - 72, 472, 256, hi + 24)
    m.no_bank(192, 248, 576, 264)
    m.decal("decals/decalstain002a", 384, 256, F + 150)
    m.decal("decals/decalstain002a", 384, 40, F + 1)
    cx, cy = m.fr.pt(384, 110)
    dx, dy = m.fr.pt(580, -60)
    m.b.bumps.append(lambda x, y: 110 * max(0.0, 1 - math.hypot(x - cx, y - cy) / 320.0) ** 1.4 + 44 * max(0.0, 1 - math.hypot(x - dx, y - dy) / 150.0) ** 1.3)
    for model, u, v, yaw, z in (("models/props_junk/garbage256_composite001a.mdl", 384, 60, 0, 36), ("models/props_junk/garbage128_composite001a.mdl", 250, 150, 60, 30),
                                ("models/props_junk/garbage128_composite001a.mdl", 520, 130, 200, 30), ("models/props_junk/garbage128_composite001a.mdl", 580, -60, 130, 14)):
        m.static(model, u, v, yaw, z=F + z)
    for k, (u, v, z) in enumerate(((384, 150, 96), (330, 60, 70), (460, 40, 64), (300, -60, 26), (500, -80, 26), (410, 210, 80), (590, -40, 40))):
        m.body("models/humans/charple0%d.mdl" % (k % 4 + 1), u, v, 55 * k, z=F + z)
    for model, u, v in (("models/props_junk/garbage_bag001a.mdl", 240, 40), ("models/props_junk/garbage_bag001a.mdl", 560, 20),
                        ("models/props_vehicles/tire001c_car.mdl", 470, -150), ("models/props_junk/metalbucket01a.mdl", 330, -140),
                        ("models/props_vehicles/tire001c_car.mdl", 200, -40), ("models/props_junk/garbage_bag001a.mdl", 620, 60)):
        m.loose(model, u, v, 30, z=F + 24)
    m.smoke(384, 110, F + 100, colour="60 58 55", size=14, length=260, rate=6)
    m.smoke(580, -60, F + 40, colour="60 58 55", size=8, length=120, rate=4)
    # a barrow left tipped on its side
    m.shapes([prism([(96, F + 6), (176, F + 6), (196, F + 54), (84, F + 40)], "y", -210, -150, MM["steel"]),
              prism(octagon(136, F + 20, 20), "y", -218, -210, MAT["bars"]), prism(octagon(136, F + 20, 20), "y", -150, -142, MAT["bars"])])
    m.det([(60, -186, F + 36, 96, -180, F + 42), (60, -180, F + 36, 64, -174, F + 42)], MAT["bars"])
    m.blocked(60, -230, 210, -130)
    m.target("lc_ash_heap", 384, 110, F + 110)
    m.blocked(192, -64, 640, 256)
    m.lane(384, -200)
    m.view(384, -100, F, 90, -10, "the heap and the chute")
    m.view(640, 150, F, 190, 0, "along the wall")


def m_sludge(m, opt):
    """11. The sludge tunnel. The canal goes the long way round a block (out to the left and back, about 3,800, under a
    street and past a dumped container), and a low tunnel 768 long cuts straight through, ankle deep in toxic runoff:
    green lamps, six outfall pipes running slime, the start of a plank walk that has rotted away, drums, a body.
    Named for the game: lc_sludge_gas (a trigger filling the tunnel's air: a place for gas masks), lc_sludge_haze (the
    green haze in it, a func_dustcloud: TurnOff, TurnOn).
    Unchecked: nature/toxicslime002a, func_dustcloud and its keys, ambient/levels/canals/toxic_slime_loop1.wav."""
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
    for u in (800, 1024, 1248):
        m.lamp(u, 0, ceil - 10, "120 255 90 40")
    stubs = []
    for k, u in enumerate((780, 1010, 1240)):
        stubs.append(prism(octagon(u, F + 64 + 8 * (k % 2), 26), "y", 100, 128, MAT["bars"], sludge))
        stubs.append(prism(octagon(u + 110, F + 60 + 8 * (k % 2), 22), "y", -128, -104, MAT["bars"], sludge))
    m.shapes(stubs)
    m.det([(704, 92, F - 8, 930, 128, F - 2), (704, 86, floor, 712, 92, F - 8), (816, 86, floor, 824, 92, F - 8), (922, 86, floor, 930, 92, F - 8)], MM["wood"])
    m.det([(960, 96, F - 10, 1010, 128, F - 5)], MM["wood"])
    m.static("models/props_c17/oildrum001.mdl", 900, -96, 0, z=floor)
    m.static("models/props_c17/oildrum001.mdl", 1130, 92, 0, z=floor)
    m.loose("models/props_c17/oildrum001.mdl", 1010, -60, 40, z=floor)
    m.body("models/humans/charple04.mdl", 1180, -40, 120, z=floor)
    m.det([(640, -160, F + 152, 656, 160, F + 176), (1392, -160, F + 152, 1408, 160, F + 176)], MAT["beam"])
    m.det([(628, -150, F + 100, 640, -134, F + 150), (1408, 134, F + 100, 1420, 150, F + 150)], MM["tin"])        # a warning board by each mouth
    m.sound("ambient/levels/canals/toxic_slime_loop1.wav", 1024, 0, F + 40, radius=800, volume=6)
    m.decal("decals/decalstain002a", 600, 0, F + 1)
    m.decal("decals/decalstain002a", 1450, 0, F + 1)
    # the long way round
    m.bridge(896, 1152, 1024, 1536)
    m.static("models/props_wasteland/cargo_container01.mdl", 380, 1250, 12)
    m.blocked(180, 1130, 590, 1380)
    m.static("models/props_vehicles/car002a_physics.mdl", 1660, 1300, 250)
    m.blocked(1560, 1200, 1770, 1400)
    m.scatter(180, 400, 590, 900, 5, 31)
    m.scatter(1460, 400, 1870, 900, 5, 32)
    for u, v in ((384, 700), (384, 1050), (700, 1280), (1300, 1280), (1664, 1050), (1664, 700), (1024, 0)):
        m.lane(u, v, F if v else floor)
    m.view(480, 0, F, 0, 0, "the tunnel's mouth")
    m.view(760, 0, floor, 0, 0, "in the sludge")
    m.view(384, 420, F, 80, -4, "the long way")


def m_cistern(m, opt):
    """12. The cistern, for the hive boss (blind, hunts by sound). Off the RIGHT wall, a tall passage with a stair in
    it leads to a round settling tank 1536 across, ankle deep in water. Two levels: a dry ledge round the tank at the
    canal's height with four plank walks out to an island in the middle, and over the ledge a gallery with a rail,
    128 up, reached by the stair. Four pillars, three inflow pipes high in the wall, chains hanging; the island lies
    under a grated shaft open to the sky, so it stands in daylight while the rest is dim.
    Wading is in the water (the game can tell: a player's water level); the ledge, the planks and the gallery are dry.
    Named for the game: lc_hive_boss_spot (the island), lc_cistern_gallery (the head of the stair).
    Unchecked: ambient/water/water_flow_loop1.wav, the chains (move_rope)."""
    b = m.b
    m.open(0, -256, 1536, 256)
    ceil, basin, cu, cv, R, G = F + 352, F - 32, 768, -1408, 768, F + 128
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
        else:
            m.low(u, v, u + CELL, v + CELL, ceil, floor=F if k == "ring" else basin)
        if k == "wet":
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
        b.vmf.world_box((x1, y1, basin, x2, y2, basin + 12), MAT["nodraw"], top=MM["water"], vis=b.vis + ": water and sludge", seals=False)
    # the gallery: a slab over every square of the ledge, a rail wherever it looks down on the water
    slabs, rails = [], []
    for (i, j), k in sorted(kind.items()):
        if k != "ring":
            continue
        u, v = cu + i * CELL, cv + j * CELL
        slabs.append((u, v, G - 8, u + CELL, v + CELL, G))
        for di, dj, box in ((1, 0, (u + 60, v, u + 64, v + 64)), (-1, 0, (u, v, u + 4, v + 64)), (0, 1, (u, v + 60, u + 64, v + 64)), (0, -1, (u, v, u + 64, v + 4))):
            if kind.get((i + di, j + dj)) == "wet":
                rails.append((box[0], box[1], G + 36, box[2], box[3], G + 40))
                rails.append((box[0], box[1], G, box[0] + 4, box[1] + 4, G + 36))
    m.det(slabs, MAT["beam"], top=MAT["quay_floor"])
    m.det(rails, MAT["bars"])
    # the stair up to it, in the passage
    m.steps(-448, 640, 704, F, G, "v", -1)
    m.shapes([prism([(-448, F + 36), (-448, F + 40), (-640, G + 40), (-640, G + 36)], "x", 704, 708, MAT["bars"])])
    m.det([(704, -640, G, 708, -636, G + 36), (704, -548, F + 64, 708, -544, F + 104)], MAT["bars"])
    m.blocked(640, -660, 720, -430)
    m.target("lc_cistern_gallery", 672, -672, G + 8, 270)
    # plank walks from the ledge to the island, on posts
    planks, posts = [], []
    for (a1, a2, axis) in ((cu + 128, cu + R - 128, "u"), (cu - R + 128, cu - 128, "u"), (cv + 128, cv + R - 128, "v"), (cv - R + 128, cv - 128, "v")):
        planks.append((a1, cv - 32, F - 6, a2, cv + 32, F) if axis == "u" else (cu - 32, a1, F - 6, cu + 32, a2, F))
        for a in range(a1 + 60, a2 - 20, 160):
            posts.append((a, cv - 28, basin, a + 8, cv + 28, F - 6) if axis == "u" else (cu - 28, a, basin, cu + 28, a + 8, F - 6))
    m.det(planks, MM["wood"])
    m.det(posts, MM["beam_wood"])
    # the shaft's grate, the pillars' heads, the inflow pipes, chains
    m.det([(cu - 128, cv - 128 + 32 * k, ceil - 8, cu + 128, cv - 122 + 32 * k, ceil) for k in range(9)] + [(cu - 4, cv - 128, ceil - 14, cu + 4, cv + 128, ceil - 8)], MAT["bars"])
    m.det([(p[0] - 16, p[1] - 16, ceil - 24, p[2] + 16, p[3] + 16, ceil) for p in pillars] + [(p[0] - 12, p[1] - 12, basin, p[2] + 12, p[3] + 12, F + 8) for p in pillars], MAT["beam"])
    m.shapes([prism(octagon(cv, F + 292, 40), "x", cu + R - 40, cu + R, MAT["bars"], MAT["black"]), prism(octagon(cv, F + 292, 40), "x", cu - R, cu - R + 40, MAT["bars"], MAT["black"]),
              prism(octagon(cu, F + 292, 40), "y", cv - R, cv - R + 40, MAT["bars"], MAT["black"])])
    for du, dv in ((-70, -60), (60, -80), (80, 70)):
        m.rope([(cu + du, cv + dv, ceil - 10), (cu + du + 6, cv + dv + 4, F + 70)], slack=6, width=2)
    m.target("lc_hive_boss_spot", cu, cv, F + 8, 90)
    for du, dv in ((-488, -488), (488, -488), (-488, 488), (488, 488)):
        m.lamp(cu + du, cv + dv, G + 150, "150 190 200 45", hang=66)
    m.light(cu, cv, F + 200, "190 210 230 60")
    m.light(768, -448, F + 200, "150 190 200 40")
    for du, dv in ((R - 60, 0), (-R + 60, 0), (0, -R + 60)):
        m.sound("ambient/water/water_flow_loop1.wav", cu + du, cv + dv, F + 100, radius=900, volume=3)
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
    """13. The barnacle underpass: 1024 of canal under a wide road, unlit. Three piers stand down its middle; six
    barnacles hang from the roof between them. Part of the roof has come in by the right wall: daylight down a shaft,
    a fallen slab, rubble. A lorry jammed against a pier, a car, cables hanging, and five of the dead lying where they
    were dropped, one beside a lantern that still burns.
    Named for the game: lc_underpass_body_1 to _5 (where each body lies: things to search).
    Unchecked: npc_barnacle (and whether the game minds NPCs it did not make), models/humans/corpse1.mdl and
    charple01, charple03, ambient/atmosphere/tunnel1.wav, the cables (move_rope)."""
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
    m.shapes([prism([(-256, F + 210), (-256, F + 180), (-130, F), (-108, F)], "x", 836, 950, MAT["beam"])])
    m.static("models/props_debris/concrete_chunk01a.mdl", 820, -110, 40)
    m.static("models/props_debris/concrete_chunk02a.mdl", 960, -150, 110)
    m.static("models/props_debris/broken_pile001a.mdl", 900, -90, 200)
    m.det([(850 + 22 * k, -256, F + 150 + 9 * (k % 3), 853 + 22 * k, -224 + 6 * (k % 2), F + 153 + 9 * (k % 3)) for k in range(5)], MAT["bars"])
    m.blocked(800, -256, 990, -60)
    for u, v in ((380, 10), (576, -130), (640, 120), (832, 70), (1090, -100), (1180, 110)):
        m.point("npc_barnacle", u, v, roof - 1, {"angles": "0 0 0", "spawnflags": "0"}, m.b.vis + ": barnacles (delete them if the game minds)")
    m.static("models/props_vehicles/truck001a.mdl", 580, -160, 12)
    m.static("models/props_vehicles/car004a_physics.mdl", 1060, 160, 200)
    m.static("models/props_debris/barricade_short01a.mdl", 330, 150, 80)
    m.blocked(450, -250, 720, -70)
    m.blocked(960, 70, 1170, 250)
    bodies = (("models/humans/corpse1.mdl", 540, 60), ("models/humans/charple03.mdl", 700, 150), ("models/humans/corpse1.mdl", 930, 40),
              ("models/humans/charple01.mdl", 1100, -150), ("models/humans/corpse1.mdl", 1190, 20))
    for k, (model, u, v) in enumerate(bodies):
        m.body(model, u, v, 70 * k)
        m.target("lc_underpass_body_%d" % (k + 1), u, v, F + 8)
    m.det([(712, 162, F, 720, 170, F + 14)], MM["steel"])                # the lantern
    m.glow(716, 166, F + 18, "255 200 120", 0.15)
    m.light(716, 166, F + 22, "255 190 110 16")
    m.rope([(600, 200, roof - 2), (700, 150, roof - 2)], slack=90, width=1)
    m.rope([(1000, -200, roof - 2), (1130, -40, roof - 2)], slack=110, width=1)
    m.rope([(400, -180, roof - 2), (420, -60, roof - 2)], slack=70, width=1)
    m.loose("models/props_junk/wood_crate001a.mdl", 640, 190, 15)
    m.loose("models/props_junk/wood_crate002a.mdl", 1000, -200, 50)
    m.sound("ambient/atmosphere/tunnel1.wav", 768, 0, F + 120, radius=1000, volume=4)
    m.decal("decals/decalstain002a", 930, 60, F + 1)
    for u, v in ((400, -100), (620, 0), (880, 20), (1136, 0), (1240, -60)):
        m.lane(u, v)
    m.view(190, 0, F, 0, 0, "at the mouth")
    m.view(560, 150, F, 350, -4, "inside")
    m.view(1150, -180, F, 172, -14, "where the roof came in")


def m_checkpoint(m, opt):
    """8. The Combine checkpoint. People come at it from the module's entry (flip it to face the other way): a chicane
    of barriers and dragon's teeth, then a Combine wall across the canal to z 720 with buttresses and one gateway
    (192 wide, 160 high) shut by a force field. Behind the wall, on the left bank, a guard's platform 128 high (the banks
    are its ramps) with a cabin, and stairs from it to a walk along the wall's top with battlements and two searchlights.
    Under the walk on the right bank, a chain link holding pen with a sliding gate.
    Named for the game: lc_checkpoint_field (a func_brush: Disable opens it, Enable shuts it), lc_checkpoint_hum (its
    sound: StopSound, PlaySound), lc_checkpoint_light and lc_checkpoint_light_b (the searchlights: LightOff, LightOn),
    lc_checkpoint_pen (the pen's gate, a func_door: Open, Close), lc_checkpoint_pen_spot (where a prisoner stands),
    lc_checkpoint_post (the guard's place on the wall), lc_checkpoint_queue (where people wait to be seen).
    Unchecked: effects/com_shield003a, ambient/machines/combine_shield_loop3.wav, point_spotlight and light_spot keys."""
    b = m.b
    cmb, steel = "metal/metalcombine002", MM["steel"]
    W1, W2, top, pz = 512, 576, TRIM + 64, F + 128
    m.open(0, -256, 1280, 256)
    m.open(576, 128, 1088, 256, floor=pz, mat=MAT["quay_floor"])
    m.side(576, 128, 1088, 256)
    m.no_bank(448, 248, 576, 264)
    m.no_bank(448, -264, 640, -248)
    m.no_bank(704, -264, 960, -248)
    # the way up to it: barriers set as a chicane, teeth to keep people off the banks
    m.static("models/props_c17/concrete_barrier001a.mdl", 330, 64, 90)
    m.static("models/props_c17/concrete_barrier001a.mdl", 210, -64, 90)
    m.shapes([pyramid(u, v, F, 24, 44, MAT["beam"]) for u in (120, 400) for v in (-104, 104)])
    m.blocked(180, -120, 360, 120)
    # the wall, its buttresses, the gateway and its frame
    m.det([(W1, -256, F, W2, -96, top), (W1, 96, F, W2, 256, top), (W1, -96, F + 160, W2, 96, top)], cmb)
    m.shapes([prism([(W1, F), (W1 - 72, F), (W1, F + 280)], "y", v - 16, v + 16, cmb) for v in (-208, -128, 128, 208)])
    m.det([(W1 - 8, -112, F, W2 + 8, -96, F + 176), (W1 - 8, 96, F, W2 + 8, 112, F + 176), (W1 - 8, -112, F + 160, W2 + 8, 112, F + 176)], steel)
    m.det([(W1 - 12, -108, F + 20 + 44 * k, W1 - 8, -100, F + 28 + 44 * k) for k in range(3)] + [(W1 - 12, 100, F + 20 + 44 * k, W1 - 8, 108, F + 28 + 44 * k) for k in range(3)], MAT["bars"])
    m.ent("func_brush", {"targetname": "lc_checkpoint_field", "Solidity": "0", "StartDisabled": "0", "solidbsp": "0", "rendermode": "0", "renderamt": "255",
                         "rendercolor": "255 255 255", "renderfx": "0", "spawnflags": "2", "disableshadows": "1", "vrad_brush_cast_shadows": "0"},
          [(542, -96, F, 546, 96, F + 160)], "effects/com_shield003a")
    m.sound("ambient/machines/combine_shield_loop3.wav", 544, 0, F + 80, radius=700, volume=6, name="lc_checkpoint_hum")
    m.test_button((W1 - 16, -160, F + 48, W1 - 8, -144, F + 64), [("OnIn", "lc_checkpoint_field", "Disable"), ("OnOut", "lc_checkpoint_field", "Enable")])
    m.light(544, 0, F + 150, "120 200 255 40")
    # the walk along the wall's top: the wall itself and a deck behind it, battlements before, a rail behind
    m.det([(W2, -256, top - 16, 672, 256, top)], steel)
    m.shapes([prism([(W2, top - 16), (W2 + 80, top - 16), (W2, top - 96)], "y", v - 8, v + 8, steel) for v in (-240, -128, 128, 176)])
    m.det([(W1, v, top, W1 + 16, v + 64, top + 56) for v in range(-256, 256, 128)] + [(W1, -256, top, W1 + 16, 256, top + 24)], cmb)
    m.det([(664, -256, top + 36, 672, 256, top + 40)] + [(664, v, top, 672, v + 4, top + 36) for v in range(-256, 256, 64)] + [(664, 252, top, 672, 256, top + 36)], MAT["bars"])
    m.det([(W1, -256, top, 672, -248, top + 40)], cmb)
    # the searchlights, on the wall's two ends
    for v, yaw, name in ((216, 196, "lc_checkpoint_light"), (-216, 164, "lc_checkpoint_light_b")):
        m.det([(W1 + 20, v - 14, top, W1 + 28, v + 14, top + 60), (W1 + 12, v - 16, top + 60, W1 + 44, v + 16, top + 88)], steel)
        m.spot(W1 + 8, v, top + 74, "190 225 255 900", yaw, pitch=16, cone=30, name=name)
    # the guard's platform: stairs to the wall's top along the canal's wall, a cabin, lockers
    m.steps(864, 192, 256, pz, top, "u", -1)
    m.shapes([prism([(864, pz + 36), (864, pz + 40), (W2, top + 40), (W2, top + 36)], "y", 188, 192, MAT["bars"])])
    m.det([(864 - 72 * k, 188, pz + 8 * (6 * k), 868 - 72 * k, 192, pz + 8 * (6 * k) + 38) for k in range(1, 4)], MAT["bars"])
    m.hut(928, 136, 1080, 248, pz, cmb, high=104, front="lo")
    m.static("models/props_combine/combine_interface001.mdl", 1050, 226, 270, z=pz)
    m.static("models/props_c17/lockers001a.mdl", 960, 236, 270, z=pz)
    m.light(1004, 190, pz + 84, "150 210 255 35")
    m.lamp(760, 250, pz + 150, "190 220 255 70")
    m.blocked(576, 176, 880, 256)
    # the holding pen, under the walk on the right bank
    chain_link(m, (720, -128), (800, -128), F, 112)
    chain_link(m, (864, -128), (944, -128), F, 112)
    chain_link(m, (720, -256), (720, -128), F, 112)
    chain_link(m, (944, -256), (944, -128), F, 112)
    m.det([(718, -256, F + 112, 946, -126, F + 114)], MAT["fence"])
    m.door("lc_checkpoint_pen", [(800, -130, F, 866, -126, F + 108)], MAT["fence"], "0 %d 0" % m.fr.yaw(0), speed=60, lip=2)
    m.test_button((936, -124, F + 48, 944, -116, F + 64), [("OnIn", "lc_checkpoint_pen", "Open"), ("OnOut", "lc_checkpoint_pen", "Close")])
    m.static("models/props_trainstation/benchoutdoor01a.mdl", 832, -226, 90)
    m.target("lc_checkpoint_pen_spot", 832, -190, F + 8, 90)
    m.blocked(704, -256, 960, -112)
    m.lamp(832, -100, F + 200, "190 220 255 60")
    m.static("models/props_wasteland/barricade002a.mdl", 1130, -120, 100)
    m.target("lc_checkpoint_post", 620, 0, top + 8, 180)
    m.target("lc_checkpoint_queue", 300, 0, F + 8, 0)
    m.decal("decals/decalstain002a", 400, 30, F + 1)
    m.taken(432, -256, F, 704, 256, top + 90)
    m.blocked(448, -256, 640, -96)
    m.blocked(448, 96, 640, 128)
    for u, v, z in ((544, 0, F), (700, 60, F), (980, 160, pz), (700, 160, pz), (624, 0, top), (624, -180, top), (720, 224, pz + 96)):
        m.lane(u, v, z)
    m.view(400, 0, F, 0, 0, "at the gateway")
    m.view(620, -40, top, 180, 18, "from the wall")
    m.view(1150, 60, F, 180, 0, "from behind")
    m.view(900, 160, pz, 20, 4, "on the platform")
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


for _more in ("map_mods_a", "map_mods_b", "map_mods_c", "map_mods_d", "map_town"):
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
    for n, words in enumerate(steps):
        name, opt = words[0], words[1:]
        flip = "flip" in opt
        if name in ("left", "right"):
            fr = Frame(x, y, rot, 512)
            m_corner(Mod(b, fr, "%d %s turn" % (n, name)), opt)
            elems.append({"kind": name, "frame": fr, "length": 512, "tag": "%d %s turn" % (n, name)})
            shed_n = 0
            x, y = fr.pt(256, 256 if name == "left" else -256)
            rot = (rot + (1 if name == "left" else -1)) % 4
            continue
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
    plan.build(vmf)
    if args.test:
        test_extras(vmf, spawn[0], spawn[1], b.vis + ": for testing alone (never in the real map)")
    canal, walled = plan, plan
    if b.upper:      # (the canal's dressing sees the street as wall; the chain link along the walls' tops stays off it)
        import map_corridor
        canal, walled = map_corridor.canal_view(b), map_corridor.fence_view(b)
    ch = Channel(vmf, canal, F, TRIM, b.vis)
    for axis, at, lo, hi in b.pipes:
        ch.pipes(axis, at, lo, hi, b.taken)
    ch.dress(b.no_bank, b.taken)
    bump = (lambda x, y: sum(f(x, y) for f in b.bumps)) if b.bumps else None
    ch.mud(47, skip=b.no_mud, bump=bump)
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
    names = [n for n in b.names if n[0] != "clash"]
    seen = {}
    for n in names:
        seen[n[0]] = seen.get(n[0], 0) + 1
    for name, k in sorted(seen.items()):
        if k > 1:
            problems.append("%d things are named %s (the same module twice in one chain: the game could not tell them apart)" % (k, name))
    return ch, fences, problems, names


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
        for k, (length, _, what) in MODULES.items():
            print("  %-10s %5d long  %s" % (k, length, what))
        raise SystemExit(1)
    lay = {"name": "mod_" + args.name, "start": tuple(args.origin or (0, 0)), "heading": args.heading or "E", "rim": args.rim or 784, "end": None,
           "modules": [[args.name] + list(args.opt or []) + (["flip"] if args.flip else [])]}
    b, seed, spawn, end = build_chain(lay, args)
    ch, fences, problems, names = finish(b, seed, spawn, args)
    report(b, ch, fences, problems, names, end, "module %s (%s)" % (args.name, MODULES[args.name][2]))
    if args.preview:
        picture(b, args.preview)
    args.expect_overlap = set()
    args.out_name = "lc_mod_%s%s.vmf" % (args.name, "_test" if args.test else "")
    args.after_write = (lambda path: take_views(b, path, args.views, args.name)) if args.views else None
    return b.vmf, problems
