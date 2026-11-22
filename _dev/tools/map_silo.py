#!/usr/bin/env python3
"""
Living City: White Forest's silo made playable (the owner, 21 November: "there are whole floors/areas that are just
nodraw ... I'd like the whole thing to be usable with a Resistance Leader office in here somewhere"), and the leader's
way out (the secret door in his bedroom, the cave tunnel and the hidden exit on the forest's rim).

BunkerForest.silo (map_forest.py) places the lifted piece valve_ep2_silo and calls these. Everything here is written in
the piece's own frame (Valve's, the anchor at the shaft's axis on the pit floor) and turned into the map's by W(): the
silo is placed turned a quarter, so the piece's +x is the map's north and its +y the map's west.

What the silo's floors are (heights over the anchor): the pit (covered at the bottom level by a grate, pit_cover); the
bottom level, 320 (the shaft's floor round the flag's pole, a ring hall round the shaft, the leader's office behind the
lab door and his bedroom beside it); the solid ring, 576 to 896; level A, 896 (a ring hall, the lift's middle stop);
the ring slab; level B, 1152 (the lift's top stop: a hall by the lift and, through two doors, the rest of the ring:
the quarters); the gantry, 1408 (where the corridor from the bunker comes in; the ladder down to level B).
"""
import math

from map_build import MAT

# a nodraw face of the piece that players can now see gets a real face: the levels' ring halls (Valve left the far half
# of level A, most of level B and the bottom level's outer faces bare) and the gantry's tunnel. (r1, r2, z1, z2) round
# the shaft's axis, or a box; a face is finished when the point 6 in front of its middle lies in one.
FINISH_RINGS = ((240, 780, 316, 580), (240, 780, 890, 1094), (240, 780, 1146, 1350))
FINISH_BOXES = ((-544, -130, 1400, -250, 130, 1570),)
FINISH_MAT = {"floor": "CONCRETE/CONCRETEWALL036A", "ceiling": "CONCRETE/CONCRETEWALL073A", "wall": "CONCRETE/CONCRETEWALL010A"}

# Valve's lever wall outside the lab door, moved whole into the office (the owner, 22 November: "move the little
# control/fuse box above it with the lights and the little recess that the switch sat in ... all together on the inside
# of the office"): the box with its two lights (1234 to 1236), the plate inside the recess (1322) and the recess's
# striped lining (1378 to 1380, 1382). The hole they leave in the hall's wall is filled (LEVER_RECESS).
LEVER_BRUSHES = (1234, 1235, 1236, 1322, 1378, 1379, 1380, 1382)
LEVER_RECESS = (272, 210, 362, 284, 234, 395)
LEVER_FROM, LEVER_TO = (280, 222, 374), (261, 288, 374)      # Valve's lever, and where it goes on the office's wall east of the door
# the piece's brushes left out: the fake door at level B's south end (131; its north twin is the func_brush
# brush_fake_cit_door_1, dropped with the wiring), the bottom level's outer wall behind the bedroom (577), rebuilt
# round the secret door, and the lever wall's parts (placed again in the office)
SKIP = {131, 577} | set(LEVER_BRUSHES)
# props of the piece left out: the static door into the bedroom (a working door now), the big cooling tank in the
# office (it filled the office's east half), the bottom level fence's static gate (a swinging one now: fence_gate) and
# the two flat bundles of pipes across the bedroom, 61 over its floor at their lowest (the owner, 22 November: "the
# pipes in his bedroom are so low I hit my head on them": pipes under its ceiling instead, bedroom())
DROP_PROPS = (("silo_door01_static", (16, 388, 324)), ("horizontalcoolingtank04", (284, 484, 374)), ("interior_fence001g", (-156, -280, 383)),
              ("pipecluster08d_006a", (-186, 232, 502)), ("pipecluster08d_006a", (-164, 228, 326)))
# the two soundscapes of the silo (the owner, 22 November: "the soundscape in the silo is subtly clicking and cutting in
# and out"): one for the whole shaft (every floor, the gantry, the lift, the ring halls), and one for the leader's
# rooms; soundscapes() places them
SCAPE_SHAFT, SCAPE_ROOM, SCAPE_CAVE = "ep2_silobattle.silo_shut", "ep2_silo.concreteroom", "d1_town.CaveTunnel"
# the walkway from the gantry's floor up to the rocket's hatch (Valve's stair, its landing and the platform by the
# hatch), in the piece's frame: kept out of the shaft's player clips (BunkerForest.silo)
WALKWAY = (-81, 78, 37, 170)


def lever_in(p):
    """A point of Valve's lever wall outside the lab door (its face at x 272, looking -x) on the office's side of the wall
    east of the door, looking +y: turned a quarter clockwise, Valve's face landing 12 in front of the office's wall (y
    296), so that the recess's back is the wall itself (y 284)."""
    import map_prefab as PF
    r3 = PF.rot(list(LEVER_FROM), 3)
    x, y, z = PF.rot(list(p), 3)
    return [x + LEVER_TO[0] - r3[0], y + LEVER_TO[1] - r3[1], z + LEVER_TO[2] - r3[2]]


def lever_in_sides(sides):
    """A brush's sides (a lifted piece's) moved as lever_in moves points."""
    import map_prefab as PF
    r3 = PF.rot(list(LEVER_FROM), 3)
    ld = (LEVER_TO[0] - r3[0], LEVER_TO[1] - r3[1], LEVER_TO[2] - r3[2])
    out = []
    for s in sides:
        s = dict(s, plane=[lever_in(p) for p in s["plane"]], verts=[lever_in(p) for p in s.get("verts", [])],
                 uaxis=PF.turn_axis(s["uaxis"], 3, ld), vaxis=PF.turn_axis(s["vaxis"], 3, ld))
        if s.get("corners"):
            s["corners"] = [lever_in(p) for p in s["corners"]]
        out.append(s)
    return out


def clip_poly(pts, a, b, c):
    """A convex polygon cut by a line: the part where a*x + b*y <= c, its new corners rounded to whole units (they lie
    on the line, which runs along x or y)."""
    out = []
    for k in range(len(pts)):
        p, q = pts[k], pts[(k + 1) % len(pts)]
        fp, fq = a * p[0] + b * p[1] - c, a * q[0] + b * q[1] - c
        if fp <= 0:
            out.append(p)
        if (fp < 0 < fq) or (fq < 0 < fp):
            t = fp / float(fp - fq)
            out.append((int(round(p[0] + (q[0] - p[0]) * t)), int(round(p[1] + (q[1] - p[1]) * t))))
    clean = []
    for p in out:
        if not clean or tuple(p) != tuple(clean[-1]):
            clean.append(tuple(p))
    if len(clean) > 1 and clean[0] == clean[-1]:
        clean.pop()
    return clean if len(clean) >= 3 else None


def W(d, p):
    """A point of the piece (its own frame) in the map."""
    return (d[0] - p[1], d[1] + p[0], d[2] + p[2])


def wyaw(a):
    return (a + 90) % 360


def wbox(d, b):
    """A box of the piece as a box of the map."""
    x1, y1, z1, x2, y2, z2 = b
    return (d[0] - y2, d[1] + x1, d[2] + z1, d[0] - y1, d[1] + x2, d[2] + z2)


# the piece's faces as the map's: its +x is north, +y west
WFACE = {"px": "north", "nx": "south", "py": "west", "ny": "east", "top": "top", "bottom": "bottom"}


def prism(d, poly, z1, z2, side, top=None, bottom=None, sides=None):
    """A convex prism over a polygon of the piece (anticlockwise seen from above), as faces for convex_text. sides: a
    material for each edge (poly[k] to poly[k+1]) where it differs."""
    pts = [W(d, (x, y, 0)) for x, y in poly]
    faces = [([(x, y, z1 + d[2]) for x, y, _ in pts][::-1], bottom or side), ([(x, y, z2 + d[2]) for x, y, _ in pts], top or side)]
    for k in range(len(pts)):
        (xa, ya, _), (xb, yb, _) = pts[k], pts[(k + 1) % len(pts)]
        faces.append(([(xa, ya, z1 + d[2]), (xb, yb, z1 + d[2]), (xb, yb, z2 + d[2]), (xa, ya, z2 + d[2])], (sides or {}).get(k, side)))
    return faces


def ngon(r, n, start=0.0):
    return [(int(round(r * math.cos(math.radians(start + 360.0 * k / n)))), int(round(r * math.sin(math.radians(start + 360.0 * k / n))))) for k in range(n)]


def brush_ent(v, cls, keys, solids, vis, connections=None):
    """A brush entity whose brushes are any convex shapes (faces lists for convex_text)."""
    s = 'entity\n{\n\t"id" "%d"\n\t"classname" "%s"\n' % (v.new_id(), cls)
    for k, val in keys.items():
        s += '\t"%s" "%s"\n' % (k, val)
    s += v.wires(connections)
    for faces in solids:
        s += v.convex_text(faces, vis)
    s += v.editor(vis, "220 30 220") + "}\n"
    v.ents.append(s)


def finish(pf):
    """Give every nodraw face of the piece that faces into a place players now reach a real face (FINISH_*): floors
    Valve's level floor (concretewall036a), ceilings its 073a, walls the silo's own concrete (010a). The faces keep
    their texture alignment. Returns how many were changed."""
    n = 0
    for s in pf["solids"]:
        if "taken shut" in s["from"]:
            continue
        pts = [p for sd in s["sides"] for p in (sd.get("verts") or sd.get("corners") or sd["plane"])]
        c = [sum(p[k] for p in pts) / float(len(pts)) for k in range(3)]
        for sd in s["sides"]:
            if sd["material"].upper() != "TOOLS/TOOLSNODRAW":
                continue
            P = sd.get("verts") or sd.get("corners")
            if not P or len(P) < 3:
                continue
            p0, p1, p2 = sd["plane"]
            a = [p1[k] - p0[k] for k in range(3)]
            b = [p2[k] - p0[k] for k in range(3)]
            nn = [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
            ln = math.sqrt(sum(x * x for x in nn)) or 1.0
            nn = [x / ln for x in nn]
            if sum(nn[k] * (c[k] - p0[k]) for k in range(3)) > 0:
                nn = [-x for x in nn]
            fc = [sum(p[k] for p in P) / float(len(P)) for k in range(3)]
            q = [fc[k] + 6 * nn[k] for k in range(3)]
            r = math.hypot(q[0], q[1])
            if not (any(r1 <= r <= r2 and z1 <= q[2] <= z2 for r1, r2, z1, z2 in FINISH_RINGS)
                    or any(b[0] <= q[0] <= b[3] and b[1] <= q[1] <= b[4] and b[2] <= q[2] <= b[5] for b in FINISH_BOXES)):
                continue
            sd["material"] = FINISH_MAT["floor" if nn[2] > 0.7 else "ceiling" if nn[2] < -0.7 else "wall"]
            n += 1
    return n


def dropped_prop(e):
    k = e["keys"]
    o = e.get("origin") or (0, 0, 0)
    return any(m in k.get("model", "") and all(abs(o[i] - p[i]) < 2 for i in range(3)) for m, p in DROP_PROPS)


class Silo:
    """The playable silo's own pieces, in the piece's frame. f: the BunkerForest; d: where the piece's anchor is."""
    FLOOR, LEVEL_A, LEVEL_B, GANTRY = 320, 896, 1152, 1408

    def __init__(self, f, d):
        self.f, self.v, self.d = f, f.vmf, d
        self.vis = f.vis("silo made playable (floors, office, bedroom)")
        self.lv = f.vis("lights")

    def P(self, x, y, z):
        return W(self.d, (x, y, z))

    def detail(self, shapes):
        self.v.detail_shapes(shapes, self.vis)

    def world(self, faces):
        self.v.world.append(self.v.convex_text(faces, self.vis))

    def light(self, x, y, z, colour, power):
        self.v.point("light", self.P(x, y, z), {"_light": "%s %d" % (colour, power), "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.lv)

    def prop(self, model, x, y, z, yaw, kind="s", pitch=0, extra=None):
        """kind: s a prop_static, d a physics model standing still (prop_dynamic_override, solid), f a lamp (no shadow,
        not solid)."""
        m = "models/%s.mdl" % model
        keys = {"model": m, "angles": "%d %d 0" % (pitch, wyaw(yaw)), "solid": "6", "skin": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}
        if kind in ("s", "f"):
            keys.update({"disableshadows": "1" if kind == "f" else "0", "screenspacefade": "0"})
            if kind == "f":
                keys["solid"] = "0"
            self.v.point("prop_static", self.P(x, y, z), dict(keys, **(extra or {})), self.vis)
            return
        keys.update({"disableshadows": "0", "StartDisabled": "0", "spawnflags": "0", "renderamt": "255", "rendercolor": "255 255 255", "modelscale": "1.0",
                     "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0", "PerformanceMode": "0", "pressuredelay": "0",
                     "ExplodeDamage": "0", "ExplodeRadius": "0"})
        self.v.point("prop_dynamic_override", self.P(x, y, z), dict(keys, **(extra or {})), self.vis)

    # -- 1. the pit ------------------------------------------------------------------------------------------------
    def pit_cover(self):
        """The pit's mouth at the bottom level (inside the ring of grating 108 from the axis) covered by a plate of the
        same grating on the same hull steel, its top flush with the bottom level (322): nobody falls in, and the shaft's
        middle, round the flag's pole, is floor. Valve's low rail round the mouth stays, with its gap on the lab's side."""
        grate = dict(top="METAL/METALGRATE_SILO01B", bottom="METAL/METALGRATE013A2")
        shapes = [prism(self.d, ngon(108, 16), 314, 322, "METAL/METALHULL003A", **grate)]
        # (and the two pieces of the grating ring Valve left out on the lab's side, 90 to 135 degrees round, where the
        # rocket's service ladder went down: a hole into the pit)
        for a0, a1 in ((90, 112.5), (112.5, 135)):
            pts = [(int(round(r * math.cos(math.radians(a)))), int(round(r * math.sin(math.radians(a))))) for r, a in ((108, a0), (160, a0), (160, a1), (108, a1))]
            shapes.append(prism(self.d, pts, 314, 322, "METAL/METALHULL003A", **grate))
        shapes.append(prism(self.d, [(0, 107), (9, 107), (9, 138), (0, 138)], 314, 322, "METAL/METALHULL003A", **grate))     # (and the slot beside them)
        self.detail(shapes)

    # -- 2. the gantry's hatch --------------------------------------------------------------------------------------
    # The hole Valve's hatch left in the gantry over the ladder (x -19..19, y -245..-209) is open, as Valve's was with
    # the hatch up: the rail put round it on 21 November is gone (the owner, 22 November: "why are there railings around
    # the ladder? there isn't even enough room to walk between the railings and the control panel").

    # -- 3. the floors ----------------------------------------------------------------------------------------------
    def level_b_doors(self):
        """Level B's two fake doors (a slab painted as a door at each end of the hall by the lift) become working doors
        into the rest of the ring: Episode Two's silo door as every other in the bunker (SILO_DOOR), carried by an unseen
        func_door on the doorway's slant, sliding 64 toward the shaft into the wall. Valve's keypads beside them stay.
        The model's lever and handle are on its own +x side, so it slides toward its -x (as Valve's lab door does): the
        model faces the other way from the slide, and the handle stays in the doorway (the owner, 22 November: "the
        doors open the wrong direction for the model (the lever/handle portion are stuck in the wall)"). Valve's doorway
        is 97 clear between its frame's posts and the model's leaf 96.4 wide, so light showed down both edges (the owner:
        "a slight crack of open/light between the door and the doorframe"): the model is drawn 3 per cent larger (99.3
        wide, 1.1 into each post; 128 high, inside the frame's head)."""
        f, v = self.f, self.v
        for k, (a, b, yaw) in enumerate((((-320, -331), (-250, -263), 45), ((-250, 263), (-320, 331), 315))):
            name = "lc_silo_levelb_door_%d" % (k + 1)
            ux, uy = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
            nx, ny = -uy * 2, ux * 2
            leaf = [(int(round(a[0] - nx)), int(round(a[1] - ny))), (int(round(b[0] - nx)), int(round(b[1] - ny))),
                    (int(round(b[0] + nx)), int(round(b[1] + ny))), (int(round(a[0] + nx)), int(round(a[1] + ny)))]
            leaf = leaf if (leaf[1][0] - leaf[0][0]) * (leaf[2][1] - leaf[0][1]) - (leaf[1][1] - leaf[0][1]) * (leaf[2][0] - leaf[0][0]) > 0 else leaf[::-1]
            slide = yaw      # (toward the shaft: the doorway's inner end)
            brush_ent(v, "func_door", dict(f.SILO_DOOR, **{
                "targetname": name, "movedir": "0 %d 0" % wyaw(slide), "wait": "-1", "spawnflags": "288", "forceclosed": "0", "ignoredebris": "1",
                "loopmovesound": "0", "dmg": "0", "health": "0", "locked_sentence": "0", "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255",
                "rendercolor": "255 255 255", "renderfx": "0", "disableshadows": "1", "disablereceiveshadows": "0"}),
                [prism(self.d, leaf, 1152, 1276, MAT["nodraw"])], self.vis,
                connections=[("OnOpen", name + "_model", "SetAnimation", "unlock", 0), ("OnFullyClosed", name + "_model", "SetAnimation", "lock", 0)])
            mx, my = (a[0] + b[0]) / 2.0, (a[1] + b[1]) / 2.0
            v.point("prop_dynamic_override", self.P(mx, my, 1152), {
                "targetname": name + "_model", "model": "models/props_silo/silo_door01.mdl", "angles": "0 %d 0" % wyaw(yaw + 180), "parentname": name, "skin": "0",
                "solid": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255",
                "rendercolor": "255 255 255", "modelscale": "1.03", "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0",
                "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0"}, self.vis)

    # how far the outer wall is from the shaft's axis on each level, every 15 degrees from +x (measured in the piece)
    WALL_A = dict(zip(range(0, 360, 15), (504, 506, 510, 510, 510, 506, 504, 506, 510, 510, 510, 390, 546, 390, 510, 510, 416, 374, 362, 374, 416, 510, 510, 506)))
    WALL_B = dict(zip(range(0, 360, 15), (504, 506, 510, 510, 510, 506, 504, 506, 300, 300, 510, 390, 546, 390, 510, 300, 300, 506, 506, 506, 510, 510, 510, 506)))

    def ring_dress(self):
        """Light and things for the ring halls Valve left bare: level A's far half (from 285 round to 75 degrees, the
        side away from the lift) becomes the base's work hall (a bench, a desk with a console, shelves, crates, drums),
        level B behind its doors the quarters (four bunks, each with a locker and a footlocker), each lit by Episode Two's
        tube lamps on the outer wall (props_silo/wall_light, a light at each) in White Forest's colours."""
        cold, warm = "224 254 248", "253 230 159"

        def at(ang, r):
            a = math.radians(ang)
            return r * math.cos(a), r * math.sin(a)
        za, zb = self.LEVEL_A, self.LEVEL_B
        for ang in (300, 345, 30, 75):
            r = self.WALL_A[ang]
            self.prop("props_silo/wall_light", *(at(ang, r - 2) + (za + 120, ang + 180, "f")))
            self.light(*(at(ang, r - 40) + (za + 130, warm, 90)))
        r = self.WALL_A
        self.prop("props_wasteland/kitchen_shelf001a", *(at(285, r[285] - 18) + (za, 285 + 90, "d")))
        self.prop("props_silo/silo_workspace1", *(at(330, r[330] - 24) + (za, 330 - 90, "s")))
        self.prop("props_wasteland/controlroom_desk001a", *(at(15, r[15] - 24) + (za + 17, 15 + 180, "d")))
        self.prop("props_silo/desk_console1", *(at(15, r[15] - 24) + (za + 34, 15 + 180, "s")))
        self.prop("props_wasteland/controlroom_chair001a", *(at(15, r[15] - 70) + (za + 20, 15 + 180, "d")))
        self.prop("props_forest/shelves", *(at(0, r[0] - 2) + (za + 64, 0 + 90, "s")))
        for k, (ang, dz) in enumerate(((45, 20), (52, 20), (48, 60))):
            self.prop("props_junk/wood_crate001a", *(at(ang, r[45] - 26) + (za + dz, ang + 7 * k, "d")))
        self.prop("props_wasteland/kitchen_shelf001a", *(at(60, r[60] - 18) + (za, 60 + 90, "d")))
        for ang in (68, 71):
            self.prop("props_silo/barrelwarning", *(at(ang, r[ang // 15 * 15] - 50) + (za, ang, "d")))
        r = self.WALL_B
        for ang in (270, 315, 0, 45, 90):
            self.prop("props_silo/wall_light", *(at(ang, r[ang] - 2) + (zb + 120, ang + 180, "f")))
            self.light(*(at(ang, r[ang] - 40) + (zb + 130, cold if ang in (270, 90) else warm, 80)))
        for ang in (285, 330, 15, 60):
            self.prop("props_forest/bunkbed", *(at(ang, r[ang] - 30) + (zb, ang, "s")))
            self.prop("props_lab/lockers", *(at(ang + 12, r[ang] - 14) + (zb, ang + 12 + 180, "s")))
            self.prop("props_forest/footlocker01_closed", *(at(ang, r[ang] - 76) + (zb + 12, ang, "s")))
        self.prop("props_wasteland/kitchen_shelf002a", *(at(100, r[105] - 18) + (zb, 100 + 180, "d")))
        self.prop("props_wasteland/kitchen_shelf002a", *(at(255, r[255] - 18) + (zb, 255 + 180, "d")))
        self.f.notes.append("the silo's ring halls: level A's far half the work hall, level B behind its two doors the quarters (4 bunks), lit by 9 tube lamps")

    # -- 4. the leader's office and bedroom -------------------------------------------------------------------------
    def office(self):
        """The Resistance leader's office behind the lab door, dressed as the commander's office of the Resistance base
        (the same kit: security monitors, a desk and chair, shelves, servers, a board; Valve's own bench in its corner
        stays as the lab bench). The big cooling tank Valve had along its east side is left out to make room."""
        z = self.FLOOR
        self.prop("props_lab/securitybank", 287, 382, z, 180, "s")              # against the machine block, screens facing the room
        self.prop("props_wasteland/controlroom_desk001a", 150, 370, z + 17, 90, "d")
        self.prop("props_wasteland/controlroom_chair001a", 150, 412, z + 20, 270, "d")
        self.prop("props_lab/servers", 250, 527, z, 270, "s")                   # against the north wall
        self.prop("props_wasteland/kitchen_shelf002a", 68, 301, z, 90, "d")       # against the south wall, west of the door
        self.prop("props_lab/corkboard001", 49, 492, z + 82, 0, "s")             # on the west wall over the bench
        self.prop("props_lab/desklamp01", 128, 362, z + 44, 300, "d")
        self.prop("props_lab/bindergreen", 172, 358, z + 34, 95, "d")
        self.light(150, 370, z + 90, "253 230 159", 40)

    BED_WALL = ((-230, 193), (-398, 334))     # the bedroom's new west wall, on the line 140 degrees round from +x

    def bedroom(self):
        """The leader's bedroom (the owner, 21 November: "expand the resistance leader's office via the static door prop
        that is there: that could become a working door that opens to ... his bedroom"): the corner of the bottom
        level's ring hall beyond the office's west doorway, walled off from the rest of the hall by a new wall from the
        shaft's wall to the outer wall, 140 degrees round. Valve's static door in that doorway is a working one now
        (SILO_DOOR, Use opens and shuts it). In it: a bed, a footlocker, a floor lamp, a locker and a dresser."""
        f, v, z = self.f, self.v, self.FLOOR
        (ax, ay), (bx, by) = self.BED_WALL
        ln = math.hypot(bx - ax, by - ay)
        nx, ny = (by - ay) / ln * 16, -(bx - ax) / ln * 16       # (toward the hall, away from the bedroom)
        nx, ny = -nx, -ny
        wall = [(ax, ay), (bx, by), (int(round(bx + nx)), int(round(by + ny))), (int(round(ax + nx)), int(round(ay + ny)))]
        if (wall[1][0] - wall[0][0]) * (wall[2][1] - wall[0][1]) - (wall[1][1] - wall[0][1]) * (wall[2][0] - wall[0][0]) < 0:
            wall = wall[::-1]
        self.world(prism(self.d, wall, z - 8, 512, "CONCRETE/CONCRETEWALL010A"))
        # the door: Valve's static door in the office's west doorway made a working one (it slides north into the wall)
        name = "lc_silo_bedroom_door"
        v.brush_entity("func_door", dict(f.SILO_DOOR, **{
            "targetname": name, "movedir": "0 %d 0" % wyaw(90), "wait": "-1", "spawnflags": "288", "forceclosed": "0", "ignoredebris": "1", "loopmovesound": "0",
            "dmg": "0", "health": "0", "locked_sentence": "0", "unlocked_sentence": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255",
            "renderfx": "0", "disableshadows": "1", "disablereceiveshadows": "0"}), [wbox(self.d, (14, 340, 324, 18, 439, 448))], MAT["nodraw"], self.vis,
            connections=[("OnOpen", name + "_model", "SetAnimation", "unlock", 0), ("OnFullyClosed", name + "_model", "SetAnimation", "lock", 0)])
        v.point("prop_dynamic_override", self.P(16, 388, 324), {
            "targetname": name + "_model", "model": "models/props_silo/silo_door01.mdl", "angles": "0 %d 0" % wyaw(270), "parentname": name, "skin": "0", "solid": "0",
            "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255",
            "modelscale": "1.0", "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0", "PerformanceMode": "0", "pressuredelay": "0",
            "ExplodeDamage": "0", "ExplodeRadius": "0"}, self.vis)
        # the room: the bed along the outer wall, its footlocker at the foot, a floor lamp at its head; the locker and the
        # dresser against the shaft's wall
        tx, ty = math.cos(math.radians(37.5)), math.sin(math.radians(37.5))
        bx0, by0 = -300, 372
        self.prop("props_c17/furniturebed001a", bx0, by0, z + 19, 37.5, "d")
        self.prop("props_forest/footlocker01_closed", bx0 + 62 * tx, by0 + 62 * ty, z + 12, 127.5, "s")
        self.prop("props_lab/citizenradio", bx0 + 62 * tx, by0 + 62 * ty, z + 25, 307.5, "d")
        self.prop("props_interiors/furniture_lamp01a", -338, 322, z + 34, 0, "d")
        self.light(-338, 322, z + 70, "253 220 160", 55)
        for ang, model, depth, zz, kind in ((127.5, "props_lab/lockers", 12, 0, "s"), (112.5, "props_c17/furnituredresser001a", 18, 41, "d")):
            a = math.radians(ang)
            self.prop(model, (322 + depth) * math.cos(a), (322 + depth) * math.sin(a), z + zz, ang, kind)
        a = math.radians(112.5)
        self.prop("props_lab/frame002a", 345 * math.cos(a) - 12, 345 * math.sin(a) - 4, z + 83, 112.5, "s")
        self.prop("props_junk/garbage_coffeemug001a", 345 * math.cos(a) + 10, 345 * math.sin(a) + 6, z + 86, 40, "d")
        # its ceiling light: a hanging tube lamp as in the office (its light had none), the light just under it
        self.prop("props_wasteland/prison_flourescentlight001a", -170, 390, z + 156, 30, "f")
        self.light(-170, 390, z + 116, "253 230 159", 40)
        # pipes under its ceiling (508), where Valve's two bundles crossed it low (DROP_PROPS): a run of them from the
        # shaft's wall to the outer wall, 157 over the floor at their lowest (a player stands 72 tall)
        a = math.radians(120)
        self.prop("props_pipes/pipeset08d_256_001a", 420 * math.cos(a), 420 * math.sin(a), z + 172, 120, "s")

    def lever_box(self, pf):
        """Valve's lever wall, moved whole from the hall outside the lab door to the office's side of the wall east of the
        door (lever_in): the recess's striped lining and the plate at its back, the box with its two lights over it,
        set in a block of the same concrete standing 12 out from the office's wall, so the recess is a recess; the
        lever itself and the lights' sprites move with it (BunkerForest.silo). The hole they leave in the hall's wall
        is filled with its concrete."""
        from map_forest import pf_solid
        v = self.v
        det = ""
        for i in LEVER_BRUSHES:
            det += pf_solid(v, lever_in_sides(pf["solids"][i]["sides"]), 1, self.d, self.vis)[0]
        v.ents.append('entity\n{\n\t"id" "%d"\n\t"classname" "func_detail"\n' % v.new_id() + det + v.editor(self.vis, "0 180 0") + "}\n")
        # the block round the recess (Valve's recess, 24 wide and 33 high, lands at x 249..273, z 362..395)
        x1, x2, z1, z2 = 237, 292, 350, 411       # (to brush 43, which stands out from the wall at x 292)
        hx1, hx2, hz1, hz2 = 249, 273, 362, 395
        cw = "CONCRETE/CONCRETEWALL028A"
        self.v.detail([wbox(self.d, b) for b in ((x1, 284, z1, hx1, 296, z2), (hx2, 284, z1, x2, 296, z2), (hx1, 284, z1, hx2, 296, hz1),
                                                 (hx1, 284, hz2, hx2, 296, z2))], cw, vis=self.vis)
        # the hole in the hall's wall, filled
        v.world_box(wbox(self.d, LEVER_RECESS), cw, top=cw, bottom=cw, vis=self.vis)

    GATE = (-156, -280, 383, 150)      # Valve's static gate in the bottom level's fence (its middle, its height, its yaw)

    def fence_gate(self):
        """The little gate in the fence across the bottom level's ring hall (Valve's interior_fence001g, a static prop
        that never opened) swings now (the owner, 22 November: "the little gate doesn't open, can function as a
        gate/door that swings open please?"): the same model on an unseen func_door_rotating hinged at its end by the
        fence's long panel; Use swings it 90 degrees away from whoever opens it, and back. To the gamemode it is a door
        like the bunker's (the cave's gate is made the same way)."""
        v = self.v
        cx, cy, cz, yaw = self.GATE
        ux, uy = math.cos(math.radians(yaw + 90)), math.sin(math.radians(yaw + 90))      # along the leaf (the model's +y)
        tx, ty = math.cos(math.radians(yaw)) * 2, math.sin(math.radians(yaw)) * 2         # half its thickness, through it
        a, b = (cx - 23 * ux, cy - 23 * uy), (cx + 23 * ux, cy + 23 * uy)              # (b: by the long panel, the hinge)
        leaf = [(int(round(p[0] + s * tx)), int(round(p[1] + s * ty))) for p, s in ((a, -1), (b, -1), (b, 1), (a, 1))]
        if (leaf[1][0] - leaf[0][0]) * (leaf[2][1] - leaf[0][1]) - (leaf[1][1] - leaf[0][1]) * (leaf[2][0] - leaf[0][0]) < 0:
            leaf = leaf[::-1]
        name = "lc_silo_fence_gate"
        hinge = self.P(b[0], b[1], 374)
        brush_ent(v, "func_door_rotating", {
            "targetname": name, "origin": "%d %d %d" % tuple(int(round(c)) for c in hinge), "distance": "90", "speed": "100", "wait": "-1", "lip": "0",
            "dmg": "0", "forceclosed": "0", "solidbsp": "0", "spawnflags": "288", "noise1": "doors/gate_move1.wav", "rendermode": "0", "renderamt": "255",
            "rendercolor": "255 255 255", "disableshadows": "1"}, [prism(self.d, leaf, 324, 426, MAT["nodraw"])], self.vis)
        v.point("prop_dynamic", self.P(cx, cy, cz), {
            "targetname": name + "_model", "model": "models/props_wasteland/interior_fence001g.mdl", "angles": "0 %d 0" % wyaw(yaw), "parentname": name,
            "solid": "0", "skin": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "spawnflags": "0"},
            self.vis)

    def lights(self):
        """Light for the silo's rooms that had none: the bottom level's ring hall west of the bedroom (a hanging tube lamp
        as the office's) and level A's near half, round the lift (Episode Two's tube lamps on the outer wall, as on the
        far half). The bedroom's lamp is in bedroom()."""
        warm = "253 230 159"
        z = self.FLOOR
        self.prop("props_wasteland/prison_flourescentlight001a", -400, 200, z + 156, 63, "f")
        self.light(-400, 200, z + 116, warm, 60)
        za = self.LEVEL_A
        for ang in (120, 225):
            r, a = self.WALL_A[ang], math.radians(ang)
            self.prop("props_silo/wall_light", (r - 2) * math.cos(a), (r - 2) * math.sin(a), za + 120, ang + 180, "f")
            self.light((r - 40) * math.cos(a), (r - 40) * math.sin(a), za + 130, warm, 90)

    def soundscapes(self):
        """The silo's sound (the owner, 22 November: "the soundscape in the silo is subtly clicking and cutting in and
        out"). It had Valve's four soundscapes, each heard only 98 to 236 from where it stands, given three different
        sounds when Valve's rocket ones were taken out: a lab's beeping equipment over the whole top of the shaft
        (ep2_silo.techroom), the shut silo's hum in the lift and at the bottom, and a small room's tone in the hall by the
        lab door; walking about, the game kept handing you from one to the next, each fading out as the next came in.
        Now the whole shaft (the gantry, every floor, the lift, the ring halls) has one sound, the shut silo's hum
        (SCAPE_SHAFT), from soundscapes that reach each floor; passing from one to another of them changes nothing. The
        leader's office and bedroom have a concrete room's tone (SCAPE_ROOM), heard once you are inside, and the way out
        the mine tunnel's (SCAPE_CAVE). Valve's four are left out (BunkerForest.silo)."""
        G, B, A, F = self.GANTRY, self.LEVEL_B, self.LEVEL_A, self.FLOOR
        for x, y, z, r, s in ((-420, 0, G + 72, 260, SCAPE_SHAFT),     # (260: short of the bunker corridor's own soundscape at the tunnel) (0, -200, G + 72, 640, SCAPE_SHAFT), (-380, 0, B + 72, 380, SCAPE_SHAFT),
                              (380, 0, B + 72, 420, SCAPE_SHAFT), (-380, 0, A + 72, 380, SCAPE_SHAFT), (380, 0, A + 72, 420, SCAPE_SHAFT),
                              (-480, 0, A - 120, 120, SCAPE_SHAFT), (-480, 0, A + 128, 120, SCAPE_SHAFT), (-360, 0, F + 72, 420, SCAPE_SHAFT),
                              (0, -200, F + 72, 520, SCAPE_SHAFT),
                              (200, 430, F + 64, 200, SCAPE_ROOM), (-200, 400, F + 64, 200, SCAPE_ROOM)):
            self.v.point("env_soundscape", self.P(x, y, z), {"soundscape": s, "radius": str(r), "StartDisabled": "0"}, self.f.vis("silo's wiring"))

# ---------------------------------------------------------------------------------------------------------------------
# 5. The leader's way out (the owner, 21 November: "have a secret escape in his room that goes to a small cave tunnel,
# just like the Antlion tunnels from EP2, one where you have to crouch to get through, and it leads to a little tiny
# hollowed out room somewhere on the other side of this little forest area and a button/lever on the inside moves a big
# rock out of the way as a secret escape that can only be opened from the inside ... NOT near the bunker entrance, so
# the resistance can run away behind any invaders going into the bunker")
# ---------------------------------------------------------------------------------------------------------------------
# All in the map's own frame from here. The tunnel runs in a sealed box of its own (CONTAINER: nodraw world brushes)
# north of the forest's north wall and west of the silo, where nothing else is: out of the silo's west side at the
# bottom level, four ramps up in switchbacks (each about 35 degrees, 784 long), then south to the exit: Episode Two's
# little cache cave (valve_ep2_cache_cave), set into the forest's north rim at its lowest point west of the silo, its
# mouth through the forest's north wall (cut there) behind a big rock that only a lever inside moves.
TW = 80                      # the tunnel's width (everywhere)
LOW, CROUCH = 112, 48        # its height, and in the two squeezes (players stand 72 tall, crouch 36)
F_EXIT = 828                 # the exit's floor: the forest's ground where its rim is lowest west of the silo (826 at the wall)
CAVE_AT = (9060, 5328, F_EXIT)   # where the cave piece's anchor (its mouth's middle on the floor) goes; turned three quarters
EXIT_HOLE = (9020, 9132, F_EXIT, F_EXIT + 80)     # the way out through the rock face: x from, to; z from, to (at y 5168 to 5200)
CUT = (8720, 9312)           # the forest's north wall is cut between these x (as far west as the cave reaches, and east of the way out as far as the rock slides)
FACE_TOP = F_EXIT + 212      # the top of the face of rock, of the wall behind it and of the seal over the roofs (sky above)
CONTAINER = (8016, 5312, -1272, 9200, 6328, 1072)    # the sealed box round the tunnel (its walls 16 thick inside these)


def _ramp(a, b, za, zb):
    """A floor that is za up to a, zb from b, and straight between (a, b along the run's axis, either order)."""
    def f(s):
        t = (s - a) / float(b - a)
        return za + (zb - za) * min(1.0, max(0.0, t))
    return f


# the tunnel: air boxes (x1, y1, x2, y2), the axis a run follows (None for a turn), its floor along that axis, its height
# along it, and the sides left open (to the next piece). From the silo outward.
def _segments():
    S = []

    def run(box, axis, floor, height, open_):
        S.append({"box": box, "axis": axis, "floor": floor, "height": height, "open": set(open_)})
    flat = lambda z: (lambda s: z)
    low = lambda s: LOW
    run((9120, 6200, 9184, 6280), "x", flat(-1240), lambda s: CROUCH, "ew")                                  # the first squeeze
    run((8128, 6200, 9120, 6280), "x", _ramp(8976, 8192, -1240, -692), lambda s: min(LOW, CROUCH + (9120 - s)), "ew")
    run((8048, 6200, 8128, 6280), None, flat(-692), low, "es")
    run((8048, 6136, 8128, 6200), "y", flat(-692), low, "ns")
    run((8048, 6056, 8128, 6136), None, flat(-692), low, "ne")
    run((8128, 6056, 9040, 6136), "x", _ramp(8192, 8976, -692, -144), low, "we")
    run((9040, 6056, 9120, 6136), None, flat(-144), low, "ws")
    run((9040, 5992, 9120, 6056), "y", flat(-144), low, "ns")
    run((9040, 5912, 9120, 5992), None, flat(-144), low, "nw")
    run((8128, 5912, 9040, 5992), "x", _ramp(8976, 8192, -144, 404), low, "ew")
    run((8048, 5912, 8128, 5992), None, flat(404), low, "es")
    run((8048, 5848, 8128, 5912), "y", flat(404), low, "ns")
    run((8048, 5768, 8128, 5848), None, flat(404), low, "ne")
    run((8128, 5768, 8580, 5848), "x", _ramp(8192, 8516, 404, 631), low, "we")
    run((8580, 5768, 8660, 5848), None, flat(631), low, "ws")
    run((8580, 5460, 8660, 5768), "y", _ramp(5768, 5460, 631, F_EXIT), low, "ns")
    run((8580, 5380, 8660, 5460), None, flat(F_EXIT), low, "ne")
    run((8660, 5380, 8740, 5460), "x", flat(F_EXIT), lambda s: max(CROUCH, LOW - (s - 8660) * 1.6), "we")       # the last squeeze, into the cave
    return S


def _noise(x, y, z, seed):
    v = 0.0
    for k, (fx, fy, fz) in enumerate(((0.021, 0.017, 0.025), (0.047, 0.039, 0.051), (0.093, 0.081, 0.088))):
        v += math.sin(fx * x + 1.7 * k + seed) * math.cos(fy * y - 0.9 * k + 2 * seed) * math.sin(fz * z + 0.3 * k + seed) / (1.6 ** k)
    return v


def _taper(s, a, b, w=40.0):
    """1 in the middle of a..b, falling smoothly to 0 at both ends (within w)."""
    d = min(s - a, b - s) / w
    return 0.0 if d <= 0 else 1.0 if d >= 1 else 0.5 - 0.5 * math.cos(math.pi * d)


# the tunnel's lamp cable (Escape.lamps): set off at least this far from a wall and this far under the roof, hooked up
# every CABLE_SPAN or less with this slack (it sags about sqrt(3 * span * slack / 8): 14 over 128)
CABLE_OFF, CABLE_DROP, CABLE_SPAN, CABLE_SLACK, CABLE_CLEAR = 8, 8, 128, 4, 4
# where a run's roof bends (a ramp's ends, a squeeze's end), so the cable follows it
CABLE_KINKS = {1: (9056, 8976, 8192), 5: (8192, 8976), 9: (8976, 8192), 13: (8192, 8516), 17: (8700,)}
# its way, from the panel to the cave: ("leg", segment, wall, from, to) along a wall of a run ("n", "s", "e", "w"),
# ("corner", segment, corner) round a turn's outer corner, ("cross", segment, at, wall) over the roof to the other wall
# on the line where the run meets the next piece
CABLE_WAY = (("leg", 0, "n", 9180, 9120), ("leg", 1, "n", 9120, 8128), ("corner", 2, "nw"), ("leg", 3, "w", 6200, 6136), ("corner", 4, "sw"),
             ("leg", 5, "s", 8128, 9040), ("cross", 5, 9040, "n"), ("corner", 6, "ne"), ("leg", 7, "e", 6056, 5992), ("corner", 8, "se"),
             ("leg", 9, "s", 9040, 8128), ("cross", 9, 8128, "n"), ("corner", 10, "nw"), ("leg", 11, "w", 5912, 5848), ("corner", 12, "sw"),
             ("leg", 13, "s", 8128, 8580), ("cross", 13, 8580, "n"), ("corner", 14, "ne"), ("leg", 15, "e", 5768, 5460), ("cross", 15, 5460, "w"),
             ("corner", 16, "sw"), ("leg", 17, "s", 8660, 8736))
WALL_NORMAL = {"n": (0, -1), "s": (0, 1), "e": (-1, 0), "w": (1, 0)}      # (into the tunnel from that wall)


def _wall_of(S, side):
    x1, y1, x2, y2 = S["box"]
    return {"n": y2, "s": y1, "e": x2, "w": x1}[side]


def _wall_push(S, side, x, y, z):
    """How far the tunnel's rock comes in from the nominal wall `side` of piece S at the point (x, y) of that wall and
    height z: the same sum tunnel() hangs that wall's displaced face by (12 x noise x a sine over its height x its
    ends' taper). Positive: into the tunnel."""
    x1, y1, x2, y2 = S["box"]
    ax, fl, hh = S["axis"], S["floor"], S["height"]
    s = x if ax == "x" else y if ax == "y" else 0
    t = (z - fl(s)) / float(hh(s))
    w = math.sin(math.pi * min(1.0, max(0.0, t)))
    ny = side in ("n", "s")
    if ax == "x":
        ends = _taper(x, x1, x2)
    elif ax == "y":
        ends = _taper(y, y1, y2)
    else:
        ends = _taper(x, x1, x2) if ny else _taper(y, y1, y2)
    bx, by = (x, _wall_of(S, side)) if ny else (_wall_of(S, side), y)
    return 12 * _noise(bx, by, z, 3) * w * ends


def _closed(S):
    sides = ("n", "s") if S["axis"] == "x" else ("e", "w") if S["axis"] == "y" else ("n", "s", "e", "w")
    return [c for c in sides if c not in S["open"]]


TIMBER_EVERY, TIMBER_MAX_INSET, TIMBER_CAP = 256, 6, 80      # a set every so often, its posts at most this far off the wall, its cap this far over the floor


def _lamp_spots(S):
    """Where the tunnel's lamps are: every 400 or so along each run (its pieces with an axis), {piece: [along, ...]}."""
    lamps = {}
    for i, sg in enumerate(S):
        if not sg["axis"]:
            continue
        x1, y1, x2, y2 = sg["box"]
        a, b = (x1, x2) if sg["axis"] == "x" else (y1, y2)
        n = max(1, int((b - a) // 400))
        lamps[i] = [a + (k + 0.5) * (b - a) / n for k in range(n)]
    return lamps


def _timber_sets():
    """The tunnel's timber sets (Escape.timbers): along each run 112 high, near every TIMBER_EVERY (nudged up to 96 to a
    spot where the rock's bulge leaves both posts within TIMBER_MAX_INSET of the wall, and not within 48 of a lamp or the
    run's ends). Each: its piece, where along, the posts' places (a struts_single model's foot is its north-east corner)
    and models, the posts' foot, the cap's box, and how far the cable must stand off its wall there."""
    S = _segments()
    lamps = _lamp_spots(S)
    out = []
    for i, sg in enumerate(S):
        if not sg["axis"]:
            continue
        x1, y1, x2, y2 = sg["box"]
        ax, fl, hh = sg["axis"], sg["floor"], sg["height"]
        a, b = (x1, x2) if ax == "x" else (y1, y2)
        sides = ("s", "n") if ax == "x" else ("w", "e")
        k = 0
        while a + TIMBER_EVERY * (k + 0.5) < b - 48:
            nominal = a + TIMBER_EVERY * (k + 0.5)
            k += 1
            for off in (0, 32, -32, 64, -64, 96, -96):
                sp = nominal + off
                if not (a + 48 <= sp <= b - 48) or any(abs(sp - l) < 48 for l in lamps.get(i, ())) or min(hh(sp - 8), hh(sp + 8)) < 100:
                    continue
                insets = {}
                for side in sides:
                    worst = 0.0
                    for ds in (-8, 0, 8):
                        q = sp + ds
                        for dz in range(4, 108, 8):
                            z = fl(q) + dz
                            px, py = (q, _wall_of(sg, side)) if ax == "x" else (_wall_of(sg, side), q)
                            worst = max(worst, _wall_push(sg, side, px, py, z))
                    insets[side] = int(math.ceil(worst)) + 1
                if max(insets.values()) > TIMBER_MAX_INSET:
                    continue
                lo_f, hi_f = min(fl(sp - 8), fl(sp + 8)), max(fl(sp - 8), fl(sp + 8))
                foot = int(math.floor(lo_f)) - 4
                cz = int(math.ceil(hi_f)) + TIMBER_CAP
                posts = []
                for n_, side in enumerate(sides):
                    ins = insets[side]
                    model = "struts_single0%d" % (1 + (len(out) + n_) % 2)
                    if ax == "x":
                        yy = y1 + ins + 16 if side == "s" else y2 - ins
                        posts.append(((int(round(sp + 8)), yy), model))
                    else:
                        xx = x1 + ins + 16 if side == "w" else x2 - ins
                        posts.append(((xx, int(round(sp + 8))), model))
                c0, c1 = int(round(sp - 6)), int(round(sp + 6))
                cap = (c0, y1 - 8, cz, c1, y2 + 8, cz + 12) if ax == "x" else (x1 - 8, c0, cz, x2 + 8, c1, cz + 12)
                out.append({"seg": i, "at": sp, "posts": posts, "foot": foot, "cap": cap, "cap_top": cz + 12, "insets": insets})
                break
    return out


def _tunnel_ways():
    """The tunnel's middle as ways kept clear (Vmf.keep_way_clear): along each run, a box 32 wide on the centre line every
    32, from just over the floor to a standing player's height (its floor rises along a ramp)."""
    out = []
    for i, sg in enumerate(_segments()):
        if not sg["axis"]:
            continue
        x1, y1, x2, y2 = sg["box"]
        ax, fl = sg["axis"], sg["floor"]
        a, b = (x1, x2) if ax == "x" else (y1, y2)
        c = (y1 + y2) // 2 if ax == "x" else (x1 + x2) // 2
        for s0 in range(int(a), int(b), 32):
            s1 = min(int(b), s0 + 32)
            zl, zh = max(fl(s0), fl(s1)) + 4, min(fl(s0), fl(s1)) + 60
            if zh <= zl:
                continue
            box = (s0, c - 16, zl, s1, c + 16, zh) if ax == "x" else (c - 16, s0, zl, c + 16, s1, zh)
            out.append((tuple(int(round(v)) for v in box), "the way out's tunnel"))
    return out


def _cable_nodes():
    """The lamp cable's points (CABLE_WAY), each {x, y, z} and, at a lamp, its wall point and the wall's normal. Every
    point is first set CABLE_OFF from its wall(s) and CABLE_DROP under the roof; then each span is walked (with its sag)
    and where the rock's bulge would come within CABLE_CLEAR of it, both its ends are moved off that wall by as much."""
    S = _segments()
    roof = lambda i, s: S[i]["floor"](s) + S[i]["height"](s)
    lamps = _lamp_spots(S)
    timber = _timber_sets()
    nodes = []      # {"x", "y", "z", "walls": [(seg, side)], "lamp": side or None}

    def add(x, y, z, walls, lamp=None):
        if nodes and abs(nodes[-1]["x"] - x) < 1 and abs(nodes[-1]["y"] - y) < 1:
            nodes[-1]["walls"] = list(set(nodes[-1]["walls"]) | set(walls))
            nodes[-1]["lamp"] = nodes[-1]["lamp"] or lamp
            return
        nodes.append({"x": float(x), "y": float(y), "z": float(z), "walls": list(walls), "lamp": lamp})
    for step in CABLE_WAY:
        if step[0] == "leg":
            _, i, side, s0, s1 = step
            sg, (nx, ny) = S[i], WALL_NORMAL[step[2]]
            wall = _wall_of(sg, side)
            at_sets = dict((st["at"], st) for st in timber if st["seg"] == i and min(s0, s1) < st["at"] < max(s0, s1))
            stops = sorted(set([s0, s1] + [k for k in CABLE_KINKS.get(i, ()) if min(s0, s1) < k < max(s0, s1)]
                               + [l for l in lamps.get(i, ()) if min(s0, s1) <= l <= max(s0, s1)] + list(at_sets)), reverse=s0 > s1)
            full = [stops[0]]
            for s in stops[1:]:
                m = int(math.ceil(math.hypot(s - full[-1], roof(i, s) - roof(i, full[-1])) / float(CABLE_SPAN)))
                full += [full[-1] + (s - full[-1]) * q / float(m) for q in range(1, m)] + [s]
            for s in full:
                is_lamp = any(abs(s - l) < 0.5 for l in lamps.get(i, ()))
                off, zc = CABLE_OFF, roof(i, s) - CABLE_DROP
                if is_lamp:      # (through the middle of the lamp's cage, 6 out from the rock it is on)
                    px, py = (s, wall) if side in ("n", "s") else (wall, s)
                    off = _wall_push(sg, side, px, py, zc) + 6
                st = next((t for a_, t in at_sets.items() if abs(a_ - s) < 0.5), None)
                if st:           # (over a timber set: on its cap, just in front of its post)
                    off, zc = st["insets"][side] + 16 + 4, st["cap_top"] + 2
                x, y = (s, wall + ny * off) if side in ("n", "s") else (wall + nx * off, s)
                add(x, y, zc, [(i, side)], side if is_lamp else None)
                if st:
                    nodes[-1]["timber"] = True
        elif step[0] == "corner":
            _, i, c = step
            sg = S[i]
            x1, y1, x2, y2 = sg["box"]
            x = x1 + CABLE_OFF if "w" in c else x2 - CABLE_OFF
            y = y1 + CABLE_OFF if "s" in c else y2 - CABLE_OFF
            add(x, y, roof(i, 0) - CABLE_DROP, [(i, c[0]), (i, c[1])])
        else:
            _, i, at, side = step
            sg = S[i]
            wall = _wall_of(sg, side)
            nx, ny = WALL_NORMAL[side]
            x, y = (at, wall + ny * CABLE_OFF) if side in ("n", "s") else (wall + nx * CABLE_OFF, at)
            add(x, y, roof(i, at) - CABLE_DROP, [(i, side)])
    # set each point off from the rock by enough: walk every span (and its sag) through the pieces it passes
    need = [dict() for _ in nodes]       # per node: {side: how much further off that wall}

    def pieces_at(x, y):
        return [k for k, sg in enumerate(S) if sg["box"][0] - 0.5 <= x <= sg["box"][2] + 0.5 and sg["box"][1] - 0.5 <= y <= sg["box"][3] + 0.5]
    for k in range(len(nodes) - 1):
        a, b = nodes[k], nodes[k + 1]
        L = math.dist((a["x"], a["y"], a["z"]), (b["x"], b["y"], b["z"]))
        sag = math.sqrt(3 * L * CABLE_SLACK / 8.0)
        for q in range(11):
            t = q / 10.0
            x, y = a["x"] + (b["x"] - a["x"]) * t, a["y"] + (b["y"] - a["y"]) * t
            zc = a["z"] + (b["z"] - a["z"]) * t - sag * 4 * t * (1 - t)
            for i in pieces_at(x, y):
                sg = S[i]
                for side in _closed(sg):
                    wall = _wall_of(sg, side)
                    dist = (wall - y) if side == "n" else (y - wall) if side == "s" else (wall - x) if side == "e" else (x - wall)
                    if dist > 40:
                        continue
                    for zz in (zc, zc + sag * 4 * t * (1 - t)):
                        deficit = _wall_push(sg, side, x, y, zz) + CABLE_CLEAR - dist
                        if deficit > 0:
                            for nd_i in (k, k + 1):
                                need[nd_i][side] = max(need[nd_i].get(side, 0), deficit)
    for nd, extra in zip(nodes, need):
        if nd.get("timber"):
            extra = {}
        for side, e in extra.items():
            nx, ny = WALL_NORMAL[side]
            nd["x"] += nx * e
            nd["y"] += ny * e
        if nd["lamp"]:
            # the lamp sits on the rock itself (where its bulge is) under the cable, facing into the tunnel
            i, side = [w for w in nd["walls"] if w[1] == nd["lamp"]][0]
            sg = S[i]
            nx, ny = WALL_NORMAL[side]
            wall = _wall_of(sg, side)
            px, py = (nd["x"], wall) if side in ("n", "s") else (wall, nd["y"])
            push = _wall_push(sg, side, px, py, nd["z"])
            nd["lamp"], nd["normal"] = (px + nx * push, py + ny * push), (nx, ny)
    return nodes


class Escape:
    def __init__(self, silo):
        self.s, self.f, self.v, self.d = silo, silo.f, silo.v, silo.d
        self.vis = self.f.vis("the leader's way out (tunnel)")
        self.xvis = self.f.vis("the leader's way out (cave, rock face, rock)")
        self.rock = "nature/rockwall015a"                    # the tunnel's walls and roof: the old mines' rock (Ravenholm's, Episode Two's)
        self.floor = "nature/blenddirtrock_mine01a"          # its floor: Episode Two's mine dirt and rock (both at 0.5, as Valve lays them)

    def disp_box(self, box, face, target, alpha, mat=None, sides=None, vis=None, tex=0.25):
        """(sides: {face: material} for the faces players see besides the displaced one; the rest are nodraw)"""
        """A world brush with one displaced face (power 3, lightmapscale 16): its points from target(base point)."""
        from map_build import face_corners
        p0, p1, p2, p3 = face_corners(box, face)
        n = 8

        def tg(i, j):
            b = [p0[k] + (p1[k] - p0[k]) * i / float(n) + (p3[k] - p0[k]) * j / float(n) for k in range(3)]
            return target(b)

        def al(i, j):
            b = [p0[k] + (p1[k] - p0[k]) * i / float(n) + (p3[k] - p0[k]) * j / float(n) for k in range(3)]
            return alpha(b)
        nd = MAT["nodraw"]
        text = self.v.box_text(box, nd, nd, nd, vis or self.vis, faces=dict(sides or {}, **{face: mat or self.rock}),
                               disp={face: (3, tg, al)}, tex=tex)
        self.v.world.append(text.replace('"lightmapscale" "32"', '"lightmapscale" "16"'))
        self.v.boxes.append((box, False))

    def tunnel(self):
        """The cave tunnel's skin: each piece's floor, roof and walls (on its closed sides) a displaced face of
        Episode Two's antlion-tunnel rock (blendrockdirt_tunnel03a, dirt on the floor), in lengths of at most 160 along a
        run. The walls bulge and the roof hangs by a few inches here and there (the same noise wherever two faces meet,
        and none on the edges where a wall meets the floor or roof or the next piece), so the faces meet without gaps."""
        T, seg = 16, 160
        for k, S in enumerate(_segments()):
            x1, y1, x2, y2 = S["box"]
            ax, fl, hh = S["axis"], S["floor"], S["height"]
            along = (lambda p: p[0]) if ax == "x" else (lambda p: p[1])
            if ax is None:
                along = lambda p, c=fl: 0
            lo_s, hi_s = ((x1, x2) if ax == "x" else (y1, y2)) if ax else (0, 1)
            zs = [fl(s) for s in (range(int(lo_s), int(hi_s) + 1, 8) if ax else [0])]
            hs = [hh(s) for s in (range(int(lo_s), int(hi_s) + 1, 8) if ax else [0])]
            zmin, zmax = int(min(zs)), int(max(z + h for z, h in zip(zs, hs))) + 1
            # (pieces along the run: equal lengths on 8)
            L = (x2 - x1) if ax == "x" else (y2 - y1) if ax == "y" else 0
            m = max(1, int(math.ceil(L / float(seg)))) if ax else 1
            a0 = x1 if ax == "x" else y1
            cuts = ([a0] + [int(round((a0 + L * q / float(m)) / 8.0)) * 8 for q in range(1, m)] + [a0 + L]) if ax else None

            def across_taper(p):
                return _taper(p[1], y1, y2) if ax == "x" else _taper(p[0], x1, x2) if ax == "y" else _taper(p[0], x1, x2) * _taper(p[1], y1, y2)

            def end_taper(p):
                if ax == "x":
                    return _taper(p[0], x1, x2)
                if ax == "y":
                    return _taper(p[1], y1, y2)
                return 1.0

            def floor_pt(p):
                s = along(p)
                return (p[0], p[1], fl(s) + 3 * _noise(p[0], p[1], 0, 1) * across_taper(p) * end_taper(p))

            def roof_pt(p):
                s = along(p)
                return (p[0], p[1], fl(s) + hh(s) - 10 * abs(_noise(p[0], p[1], 7, 2)) * across_taper(p) * end_taper(p))

            def wall_pt(nx, ny):
                def f(p):
                    s = along(p)
                    t = (p[2] - zmin) / float(zmax - zmin)
                    z = fl(s) + t * hh(s)
                    w = math.sin(math.pi * min(1.0, max(0.0, t)))
                    ends = end_taper(p) if ax else (_taper(p[0], x1, x2) if ny else _taper(p[1], y1, y2))
                    push = 12 * _noise(p[0], p[1], z, 3) * w * ends
                    return (p[0] + nx * push, p[1] + ny * push, z)
                return f
            def dirt_floor(p):          # (dirt down the middle, more rock toward the walls)
                return 250 - 170 * across_taper(p)
            roof_alpha = lambda p: 0

            def wall_alpha(p):
                t = (p[2] - zmin) / float(zmax - zmin)
                return 200 * max(0.0, 1 - t * 3)
            pieces = [(cuts[q], cuts[q + 1]) for q in range(m)] if ax else [None]
            for pc in pieces:
                if ax == "x":
                    a, b = pc
                    bx = (a, y1, b, y2)
                elif ax == "y":
                    a, b = pc
                    bx = (x1, a, x2, b)
                else:
                    bx = (x1, y1, x2, y2)
                X1, Y1, X2, Y2 = bx
                self.disp_box((X1, Y1, zmin - T, X2, Y2, zmin), "top", floor_pt, dirt_floor, mat=self.floor, tex=0.5)
                self.disp_box((X1, Y1, zmax, X2, Y2, zmax + T), "bottom", roof_pt, roof_alpha, tex=0.5)
                if ax in ("x", None):
                    if "n" not in S["open"]:
                        self.disp_box((X1, Y2, zmin, X2, Y2 + T, zmax), "south", wall_pt(0, -1), wall_alpha, tex=0.5)
                    if "s" not in S["open"]:
                        self.disp_box((X1, Y1 - T, zmin, X2, Y1, zmax), "north", wall_pt(0, 1), wall_alpha, tex=0.5)
                if ax in ("y", None):
                    if "e" not in S["open"]:
                        self.disp_box((X2, Y1, zmin, X2 + T, Y2, zmax), "west", wall_pt(-1, 0), wall_alpha, tex=0.5)
                    if "w" not in S["open"]:
                        self.disp_box((X1 - T, Y1, zmin, X1, Y2, zmax), "east", wall_pt(1, 0), wall_alpha, tex=0.5)
        self.timbers()
        self.lamps()

    def timbers(self):
        """Timber sets along the tunnel, as Ravenholm's and Episode Two's mines have them (the owner, 22 November: "could we
        just make it like the EP2 and ravenholm tunnels out of dirt and dirt/rock mix textures and have wooden supports
        along the tunnel? so long as I can still walk in there"): every 256 or so along each tall run, two of Episode Two's
        timber posts (props_mining/struts_single01 and _02, 16 square, 176 high: their tops go up into the rock) stood
        against the walls, and a cap of Ravenholm's timber (woodfloor005a, 12 square) across under the roof, 80 over the
        floor; the lamps' cable rests on the caps. A set stands only where the rock's bulge leaves the posts within 6 of
        the wall (_timber_sets), so the middle 32 stays clear the whole way (map_build's ways check holds it: the tunnel's
        middle is a way kept clear)."""
        v, vis = self.v, self.vis
        sets = _timber_sets()
        caps = []
        for st in sets:
            for (px, py), model in st["posts"]:
                v.point("prop_static", (px, py, st["foot"]), {"model": "models/props_mining/%s.mdl" % model, "angles": "0 0 0", "skin": "0", "solid": "6",
                                                            "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, vis)
            caps.append(st["cap"])
        if caps:
            v.detail(caps, "wood/woodfloor005a", vis=vis)
        for box, label in _tunnel_ways():
            v.keep_way_clear(box, label)
        self.f.notes.append("the way out's tunnel: Valve's mine rock (rockwall015a) and floor (blenddirtrock_mine01a), %d timber sets" % len(sets))

    def lamps(self):
        """The tunnel's lamps and their cable (the owner, 22 November: "please put little cage lights or whatever on the
        walls with ropes/wires connecting them in a chain from the beginning to the end"). Dim warm light every 400 or so
        along each run (lesson valve-cave-lighting: no walking spot far from one), each from a cage lamp
        (props_c17/light_cagelight02_on) on the wall just under the roof; one cable (cable/cable.vmt, as Valve's) runs
        from the panel to the cave along the wall's top corner, through every lamp, hooked up every 128 or less so it
        hangs only a little; at each turn it goes round the outer corner, and where it must change walls it crosses
        the roof on the line where two pieces meet (no bulge there). Each point is set off from the rock by how far the
        rock's own bulges come in there (_wall_push), so the cable never runs inside the rock."""
        v, lv, vis = self.v, self.s.lv, self.vis
        nodes = _cable_nodes()
        for k, nd in enumerate(nodes):
            name = "lc_escape_cable_%d" % k
            keys = {"targetname": name, "RopeMaterial": "cable/cable.vmt", "Slack": str(CABLE_SLACK), "Subdiv": "4", "Width": "1", "TextureScale": "1",
                    "MoveSpeed": "64", "NoWind": "1", "Collide": "0", "Barbed": "0", "Breakable": "0", "Dangling": "0", "Type": "0"}
            if k + 1 < len(nodes):
                keys["NextKey"] = "lc_escape_cable_%d" % (k + 1)
            if k == 0:
                keys["PositionInterpolator"] = "2"
            v.point("move_rope" if k == 0 else "keyframe_rope", (int(round(nd["x"])), int(round(nd["y"])), int(round(nd["z"]))), keys, vis)
            if nd.get("lamp"):
                (mx, my), (nx, ny) = nd["lamp"], nd["normal"]
                yaw = int(round(math.degrees(math.atan2(ny, nx)))) % 360
                v.point("prop_static", (int(round(mx)), int(round(my)), int(round(nd["z"]))), {
                    "model": "models/props_c17/light_cagelight02_on.mdl", "angles": "0 %d 0" % yaw, "solid": "0", "skin": "0", "disableshadows": "1",
                    "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, vis)
                v.point("light", (int(round(mx + nx * 16)), int(round(my + ny * 16)), int(round(nd["z"] - 18))), {
                    "_light": "255 190 120 40", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, lv)
        self.f.notes.append("the way out's tunnel: %d cage lamps on its walls, one cable through them (%d points) from the panel to the cave"
                            % (sum(1 for n in nodes if n.get("lamp")), len(nodes)))

    # -- the exit ------------------------------------------------------------------------------------------------------
    def cave(self):
        """Episode Two's cache cave (valve_ep2_cache_cave) as the exit room, turned three quarters so that its mouth
        faces south-east, its floor the exit's floor, set north of the forest's north wall: its rock skin (displaced
        faces, written as world brushes with their grids turned) but its south wall, which becomes its west wall here
        and is ours (with the squeeze's hole); the things that were inside it (two open footlockers, a pot, a mug,
        cans and cartons, shoes, rocks) and its light; left out: the radar crate and its beacon, the skeletons, the
        health vials, the lambda (an overlay on a face) and what lay outside on the hillside. The floor under its north
        half (the hillside's in Valve's map) is ours."""
        import map_prefab as PF
        v, q, d = self.v, 3, CAVE_AT
        pf = PF.load("valve_ep2_cache_cave")
        t = "\t"
        for sol in pf["solids"]:
            pts = [p for sd in sol["sides"] for p in (sd.get("verts") or sd.get("corners") or sd["plane"])]
            if min(p[1] for p in pts) < -330 and max(p[1] for p in pts) < -310:
                continue        # (Valve's south wall: ours below)
            text = '%ssolid\n%s{\n%s\t"id" "%d"\n' % (t, t, t, v.new_id())
            for sd in sol["sides"]:
                pl = [[a + b for a, b in zip(PF.rot(p, q), d)] for p in sd["plane"]]
                vs = [[a + b for a, b in zip(PF.rot(p, q), d)] for p in sd["verts"]]
                text += '%s\tside\n%s\t{\n%s\t\t"id" "%d"\n%s\t\t"plane" "%s"\n' % (t, t, t, v.new_id(), t, " ".join("(%s %s %s)" % tuple(PF.fmt(c) for c in p) for p in pl))
                if vs:
                    text += '%s\t\tvertices_plus\n%s\t\t{\n%s%s\t\t}\n' % (t, t, "".join('%s\t\t\t"v" "%s %s %s"\n' % ((t,) + tuple(PF.fmt(c) for c in p)) for p in vs), t)
                text += '%s\t\t"material" "%s"\n%s\t\t"uaxis" "%s"\n%s\t\t"vaxis" "%s"\n%s\t\t"rotation" "0"\n%s\t\t"lightmapscale" "%s"\n%s\t\t"smoothing_groups" "0"\n' % (
                    t, sd["material"], t, PF.turn_axis(sd["uaxis"], q, d), t, PF.turn_axis(sd["vaxis"], q, d), t, t, sd["lightmapscale"], t)
                if sd.get("disp"):
                    text += PF.disp_side_text(sd["disp"], q, d, t + "\t\t")
                    v.disp_count += 1
                text += '%s\t}\n' % t
            text += v.editor(self.xvis, indent=t + "\t") + "%s}\n" % t
            v.world.append(text)
        kept = 0
        # Valve's rocks along the wall that is ours here (the squeeze's hole is in it): the one leaning on it across the
        # hole is left out and the two beside the hole moved off it (the owner, 22 November: "the rocks are blocking the
        # way in from the tunnels and I can't crawl out of the tunnel"); keyed by where they lie in Valve's frame
        rock_out = {(-112, -272, 16)}
        rock_moved = {(16, -232, -8): (0, -32, 0), (-188, -272, 72): (0, 24, 0)}
        for p in pf["points"]:
            o = p["origin"]
            here = tuple(int(round(c)) for c in o)
            if here in rock_out:
                continue
            if p["classname"] == "env_sprite" or "rock_forest" in p["keys"].get("model", "") or o[0] + o[1] > -16 or o[2] > 180:
                continue        # (outside the mouth, up on the hillside, or the beacon's glow)
            keys = dict(p["keys"])
            keys.pop("classname", None)
            if "angles" in keys:
                a = [float(c) for c in keys["angles"].split()]
                keys["angles"] = "%s %s %s" % (PF.fmt(a[0]), PF.fmt((a[1] + 90 * q) % 360), PF.fmt(a[2]))
            cls = p["classname"]
            if cls == "prop_physics":      # (still life: nothing in the leader's cache rolls about)
                cls = "prop_dynamic_override"
                keys.update({"solid": "6", "spawnflags": "0", "StartDisabled": "0"})
            w = [a + b + m for a, b, m in zip(PF.rot(o, q), d, rock_moved.get(here, (0, 0, 0)))]
            v.point(cls, (int(round(w[0])), int(round(w[1])), int(round(w[2]))), keys, self.xvis if cls != "light" else self.s.lv)
            kept += 1
        return kept

    def exit_room(self):
        """What joins the cave to the tunnel and to the forest, rebuilt shut tight (the owner, 22 November: "that 'hidden'
        rock entrance has TONS of holes and gaps and I don't even see the button/lever to open/slide the rock out of the
        way? It's kind of just a disaster"). Before, the forest's wall was cut only from x 8840, so the cave's south-west
        corner stood inside the wall's sky; the sky over the cut came down to 1004, into the porch under its roof (1020);
        and the face of rock and the porch's walls were displaced faces with nothing behind them (displaced faces seal
        nothing and are drawn from one side only), so you saw the sky and the void through and behind them. Now, where the
        wall is cut (CUT: as far west as the cave reaches), everything from the sealed floor up to the sky (FACE_TOP) is
        solid world brushes but the room's air, faced with rock wherever they can be seen: a wall 16 thick on the forest's
        side with the way out through it, a wall behind the porch's east side, a seal over the cave's and the porch's
        roofs and one behind the cave's west wall. The displaced rock (the face toward the forest, the porch's walls and
        roof, the cave's west wall) hangs in front of them, so a crack between two displaced faces shows rock. The rock
        that shuts the way out is a plug that fills the hole exactly (a func_button only the lever moves, rock-faced both
        sides), with Valve's forest boulder riding it outside; it slides 176 east into the wall (the cut runs on east for
        it), far enough for the boulder to clear the hole, so the way west along the hollow in front of it stays free. The
        hollow is the forest's ground (BunkerForest.natural: a ridge in front of the face and on its east, so neither the
        valley nor the bunker sees the hole). The lever is on the porch's east wall right by the hole, on a striped plate
        under a lamp."""
        f, v, F = self.f, self.v, F_EXIT
        cliff, rock, dirt = "nature/blendcliffdirt001a", "nature/blendrockdirt_tunnel03a", "nature/blendgrassdirt01"
        nd, sky = MAT["nodraw"], MAT["sky"]
        T = FACE_TOP
        hx1, hx2, hz1, hz2 = EXIT_HOLE
        x1, x2 = CUT

        def bulge(axis_n, amp, edges, calm=None):
            """A displaced face pushed along axis_n (a unit vector) by noise, nothing on the box's own edges (nor round
            calm: (y1, y2, z1, z2), flat for the lever's plate and lamp, easing out over 24)."""
            (ea1, ea2, ia), (eb1, eb2, ib) = edges

            def f_(p):
                w = _taper(p[ia], ea1, ea2, 32) * _taper(p[ib], eb1, eb2, 32)
                if calm:
                    cy1, cy2, cz1, cz2 = calm
                    dy, dz = max(cy1 - p[1], 0, p[1] - cy2), max(cz1 - p[2], 0, p[2] - cz2)
                    w *= min(1.0, math.hypot(dy, dz) / 24.0)
                k = amp * _noise(p[0], p[1], p[2], 5) * w
                return (p[0] + axis_n[0] * k, p[1] + axis_n[1] * k, p[2] + axis_n[2] * k)
            return f_
        # -- the solid shell (it seals; rock where it can be seen) --
        # under all of it, and the sky over it
        v.world_box((x1, 5184, f.zb, x2, 5312, F - 17), nd, vis=self.xvis)
        v.world_box((x1, 5184, T, x2, 5312, f.lid), sky, sky, sky, vis=self.xvis)
        # the wall on the forest's side (5184 to 5200) with the way out through it: the face of rock hangs in front of it
        face_side = {"south": cliff, "north": rock}
        for b, extra in (((x1, 5184, F - 17, hx1, 5200, T), {"east": cliff}), ((hx2, 5184, F - 17, x2, 5200, T), {"west": cliff}),
                         ((hx1, 5184, F - 17, hx2, 5200, hz1), {"top": dirt}), ((hx1, 5184, hz2, hx2, 5200, T), {"bottom": cliff})):
            v.world_box(b, nd, vis=self.xvis, faces=dict(face_side, **extra))
        # behind the cave's west wall where the forest's wall was (the cave's west wall is displaced: its cracks show this)
        v.world_box((x1, 5200, F - 17, 8724, 5312, T), nd, vis=self.xvis, faces={"east": rock})
        # behind the porch's east wall and its north-east corner
        v.world_box((9172, 5200, F - 17, x2, 5424, T), nd, vis=self.xvis, faces={"west": rock})
        v.world_box((9140, 5408, F - 17, 9172, 5424, T), nd, vis=self.xvis, faces={"south": rock})
        # over the cave's and the porch's roofs (their displaced roofs hang under it)
        v.world_box((x1, 5200, F + 208, x2, 5424, T), nd, vis=self.xvis, faces={"bottom": rock})
        # -- the displaced rock --
        flat_alpha = lambda p: 120
        floor_alpha = lambda p: 230
        # the cave's west wall (ours), on the line of Valve's south wall: three pieces round the squeeze's hole
        for (y1, y2, z1, z2) in ((5192, 5380, F - 8, F + 208), (5460, 5656, F - 8, F + 208), (5380, 5460, F + 48, F + 208)):
            self.disp_box((8724, y1, z1, 8740, y2, z2), "east", bulge((1, 0, 0), 10, ((y1, y2, 1), (z1, z2, 2))), lambda p: 60, mat=rock, vis=self.xvis)
        # the floor under the cave's north half and the porch (Valve's hillside floor in their map)
        self.disp_box((8932, 5200, F - 17, 9156, 5712, F - 1), "top", bulge((0, 0, 1), 3, ((8932, 9156, 0), (5200, 5712, 1))), floor_alpha, mat=dirt, vis=self.xvis)
        # the porch: from the cave's mouth to the wall on the forest's side, as high as the cave (Valve's roof covers most
        # of it); its east wall flat where the lever's plate and lamp are
        lever_calm = (5208, 5264, F + 16, F + 140)
        for box, face, n, calm in (((9156, 5200, F, 9172, 5392, F + 192), "west", (-1, 0, 0), lever_calm), ((9140, 5392, F, 9172, 5408, F + 192), "south", (0, -1, 0), None)):
            ax_ = (1, 2) if face in ("west", "east") else (0, 2)
            self.disp_box(box, face, bulge(n, 9, ((box[ax_[0]], box[ax_[0] + 3], ax_[0]), (box[2], box[5], 2)), calm), flat_alpha, mat=rock, vis=self.xvis)
        box = (9124, 5200, F + 192, 9172, 5392, F + 208)
        self.disp_box(box, "bottom", bulge((0, 0, -1), 6, ((box[0], box[3], 0), (box[1], box[4], 1))), lambda p: 0, mat=rock, vis=self.xvis)
        # the face of rock on the forest's side, round the way out: pushed toward the forest by noise, straight along
        # every edge, so that its four pieces meet; its ends, its top and the hole's sides are cliff too
        for (bx1, bx2, z1, z2, seen) in ((x1, hx1, F - 48, T, ("west", "east", "top")), (hx2, x2, F - 48, T, ("west", "east", "top")), (hx1, hx2, hz2, T, ("bottom", "top")),
                                         (hx1, hx2, F - 48, hz1, ("top",))):
            self.disp_box((bx1, 5168, z1, bx2, 5184, z2), "south", bulge((0, -1, 0), 22, ((bx1, bx2, 0), (z1, z2, 2))), lambda p: 40, mat=cliff,
                          sides=dict((s_, cliff) for s_ in seen), vis=self.xvis)
        # -- the rock: a plug that fills the hole (2 inside each face), only the lever moves it (no use, touch or damage),
        # Valve's forest boulder (props_foliage/rock_forest04, drawn a third larger) riding it outside; it slides 176 east
        # into the wall at 44 a second (4 s) and stops against whoever is in its way --
        rock_n, lever = "lc_escape_rock", "lc_escape_lever"
        mid = (hx1 + hx2) // 2
        v.brush_entity("func_button", {"targetname": rock_n, "movedir": "0 0 0", "speed": "44", "lip": str(hx2 - hx1 - 176), "wait": "-1", "spawnflags": "0",
                                       "sounds": "0", "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"},
                       [((hx1, 5170, hz1, hx2, 5198, hz2), {"north": rock, "south": cliff})], cliff, self.xvis)
        v.point("prop_dynamic_override", (mid, 5150, F + 24), {
            "targetname": rock_n + "_model", "model": "models/props_foliage/rock_forest04.mdl", "angles": "0 90 0", "parentname": rock_n, "solid": "0", "skin": "0",
            "disableshadows": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "spawnflags": "0", "renderamt": "255",
            "rendercolor": "255 255 255", "modelscale": "1.3", "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0",
            "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0"}, self.xvis)
        v.point("ambient_generic", (mid, 5210, F + 40), {"targetname": rock_n + "_sound", "message": "physics/concrete/rock_scrape_rough_loop1.wav",
                                                         "health": "10", "pitch": "90", "pitchstart": "90", "radius": "1500", "spawnflags": "16"}, self.xvis)
        # -- the lever: Valve's, as in the leader's office (a func_rot_button pulled down 45 degrees; Use pulls it and
        # pushes it back), on a striped plate on the porch's east wall right by the hole, facing in, at hand height,
        # under a cage lamp --
        lx, ly, lz = 9152, 5236, F + 52
        v.detail([(9154, ly - 20, F + 24, 9156, ly + 20, F + 84)], "METAL/METALWALL031A", vis=self.xvis, faces={"west": "DEV/DEV_HAZZARDSTRIPE01A"})
        # the lever: Ravenholm's propeller trap lever (the owner, 22 November: "can we use
        # models/props_c17/trappropeller_lever.mdl instead?"), hung as d1_town_03 hangs it: the handle (13 long) on an
        # unseen mover pivoting 4 from its end, here at the plate, 35 degrees about the wall's line. Pulled, the rock opens;
        # 30 s later it shuts by itself (the owner: "the rock exit should close itself 30 seconds after opening"), the lever
        # going back with it; pushed back sooner, it shuts then. In the last moments of the rock's close a shove pushes
        # whoever stands in the hole out of it, into the porch or out to the hollow (shove()).
        auto = "lc_escape_autoclose"
        v.brush_entity("func_rot_button", {"targetname": lever, "angles": "0 0 0", "distance": "35", "speed": "50", "wait": "-1", "spawnflags": str(1024 | 32 | 128),
                                           "sounds": "0", "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255",
                                           "origin": "%d %d %d" % (lx, ly, lz)},
                       [(lx - 12, ly - 5, lz - 5, lx + 2, ly + 5, lz + 5)], nd, self.xvis,
                       connections=[("OnPressed", lever + "_sound", "PlaySound", "", 0), ("OnIn", rock_n, "PressIn", "", 0.3), ("OnIn", rock_n + "_sound", "PlaySound", "", 0.3),
                                    ("OnIn", rock_n + "_sound", "StopSound", "", 4.3), ("OnIn", auto, "Trigger", "", 0),
                                    ("OnOut", auto, "CancelPending", "", 0), ("OnOut", rock_n, "PressOut", "", 0.3), ("OnOut", rock_n + "_sound", "PlaySound", "", 0.3),
                                    ("OnOut", rock_n + "_sound", "StopSound", "", 4.3), ("OnOut", rock_n + "_shove", "Enable", "", 3.7),
                                    ("OnOut", rock_n + "_shove", "Disable", "", 4.6)])
        v.point("prop_dynamic", (lx - 4, ly, lz), {"model": "models/props_c17/trappropeller_lever.mdl", "angles": "0 270 0", "parentname": lever, "solid": "0", "skin": "0",
                                                   "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "spawnflags": "0"},
                self.xvis)
        v.point("logic_relay", (lx - 40, ly, lz + 40), {"targetname": auto, "StartDisabled": "0", "spawnflags": "0"}, self.xvis,
                connections=[("OnTrigger", lever, "PressOut", "", 30)])
        v.point("ambient_generic", (lx, ly, lz + 10), {"targetname": lever + "_sound", "message": "streetwar.drawbridge_lever_start", "health": "10", "pitch": "100",
                                                       "pitchstart": "100", "radius": "1250", "spawnflags": "48"}, self.xvis)
        f.shove(rock_n + "_shove", [((hx1, 5120, F, hx2, 5184, F + 80), 270, 200), ((hx1, 5184, F, hx2, 5250, F + 80), 90, 300)], self.xvis)
        v.point("prop_static", (9156, ly, F + 120), {"model": "models/props_c17/light_cagelight02_on.mdl", "angles": "0 180 0", "solid": "0", "skin": "0",
                                                    "disableshadows": "1", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, self.xvis)
        v.point("light", (9138, ly, F + 100), {"_light": "255 196 130 50", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.s.lv)
        v.point("light", (9080, 5260, F + 120), {"_light": "255 196 130 45", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.s.lv)

    def container(self):
        """The sealed box round the tunnel and the cave (nodraw world brushes 16 thick): what keeps the map shut, since
        displaced faces seal nothing. Its south side is the forest's own north wall and slab, down to the slab's foot,
        and a wall of ours under that; its east side has the hole the first squeeze comes through from the silo."""
        x1, y1, z1, x2, y2, z2 = CONTAINER
        nd, v, T = MAT["nodraw"], self.v, 16
        # (its east side stops where the silo's hull begins, y 5760, under the hull's top, z 232: the hull is the wall there,
        # and the squeeze's hole through it is the hull's own, faced with concrete; a second wall in the hull's thickness
        # put nodraw faces in that hole: the owner, 22 November: "the entrance to the tunnel has nodraw/gaps/cracks all over it")
        hull_y, hull_top = 5760, 232
        for b in ((x1, y1, z1, x2, y2, z1 + T), (x1, y1, z2 - T, x2, y2, z2), (x1, y2 - T, z1, x2, y2, z2), (x1, y1, z1, x1 + T, y2, z2),
                  (x1, y1, z1, x2, y1 + T, self.f.zb - 64),
                  (x2 - T, y1, z1, x2, hull_y, z2), (x2 - T, hull_y, hull_top, x2, y2, z2)):
            v.world_box(b, nd, vis=self.vis)


HULL_HOLE = (6200, 6280, -1240, -1192)      # where the first squeeze passes the silo's hull (map y from, to; z from, to)


def split_box(box, hole):
    """A box less a hole through it along x (hole: y from, to; z from, to): the four boxes round the hole."""
    x1, y1, z1, x2, y2, z2 = box
    hy1, hy2, hz1, hz2 = hole
    return [(x1, y1, z1, x2, hy1, z2), (x1, hy2, z1, x2, y2, z2), (x1, hy1, z1, x2, hy2, hz1), (x1, hy1, hz2, x2, hy2, z2)]


def _escape(self):
    """5. The leader's way out: the secret door in his bedroom, the squeeze through the silo's wall, the tunnel, the
    cave and the rock (Escape above). The secret door: a low panel of the bedroom's wall (80 wide, 48 high, the wall's
    own concrete on every face) that slides 76 sideways into the wall and back: a func_button used as a mover, so the
    gamemode's door rules (kicks, picks, NPCs) never touch it. Use on the panel itself does nothing (the owner, 22
    November: "can we please also make it so that E doesn't open/close the door when pressed on it directly?"): Kleiner's
    crooked picture in the bedroom works it, and a button on the tunnel's side just beyond it (the owner: "on the inside
    just inside beyond the secret door, can we please get a button to close the door?") turns the picture, so the two
    stay in step: straight while the panel is open, tilted while it is shut. Behind it the bedroom's outer wall (Valve's
    577, rebuilt round the opening) and the hull, then the cave tunnel."""
    v, z = self.v, self.FLOOR
    wall = "CONCRETE/CONCRETEWALL010A"
    face = {"east": "CONCRETE/EP2_CONCRETEWALL01B"}      # (the piece's -y face, toward the bedroom, is the map's east)
    for b in ((-141, 500, 320, -104, 544, 416), (-24, 500, 320, 0, 544, 416), (-104, 500, 368, -24, 544, 416)):
        v.world_box(wbox(self.d, b), wall, top=wall, bottom=wall, vis=self.vis, faces=face)
    name = "lc_silo_secret_panel"
    v.brush_entity("func_button", {"targetname": name, "movedir": "0 %d 0" % wyaw(0), "speed": "30", "lip": "4", "wait": "-1", "spawnflags": "32",
                                   "sounds": "0", "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"},
                   [(wbox(self.d, (-104, 500, 320, -24, 504, 368)), {"east": "CONCRETE/EP2_CONCRETEWALL01B"})], wall, self.vis,
                   connections=[("OnPressed", name + "_sound", "PlaySound", "", 0)])
    v.point("ambient_generic", self.P(-64, 490, 344), {"targetname": name + "_sound", "message": "doors/doormove2.wav", "health": "8", "pitch": "80", "pitchstart": "80",
                                                       "radius": "600", "spawnflags": "48"}, self.vis)
    # the hints (the owner, 22 November: "the escape tunnel needs some sort of hint as to the fact that there is an
    # entrance there ... like maybe a lambda spraypainted on the little door and a switch somewhere in the room? Maybe you
    # could steal the little crooked picture from Dr Kleiner's office"): Half-Life 2's lambda sprayed on the panel (it
    # rides it), and Kleiner's crooked picture as d1_trainstation_05 has it (props_lab/frame001a, 9 degrees off true, on
    # an unseen func_door_rotating 2 by 2 by 4 that turns it about its own face) on the bedroom's west wall at eye
    # height. Use straightens it and the panel slides open; Use again tilts it back and the panel shuts.
    v.point("infodecal", self.P(-64, 500, 344), {"texture": "decals/lambdaspray_1a", "LowPriority": "0"}, self.vis)
    (ax, ay), (bx, by) = self.BED_WALL
    ln = math.hypot(bx - ax, by - ay)
    ux, uy = (bx - ax) / ln, (by - ay) / ln
    nx, ny = uy, -ux
    if nx * (0 - ax) + ny * (400 - ay) < 0:      # (into the bedroom)
        nx, ny = -nx, -ny
    px, py = ax + 98 * ux + nx, ay + 98 * uy + ny
    facing = int(round(math.degrees(math.atan2(ny, nx))))
    pic = "lc_silo_crooked_picture"
    at = tuple(int(round(c)) for c in self.P(px, py, z + 60))
    brush_ent(v, "func_door_rotating", {
        "targetname": pic, "origin": "%d %d %d" % at, "angles": "0 %d 0" % wyaw(facing), "distance": "9", "speed": "100", "wait": "-1", "lip": "0", "dmg": "0",
        "health": "0", "forceclosed": "0", "spawnflags": str(2 | 8 | 16 | 32 | 64 | 256 | 512), "noise1": "physics/wood/wood_box_impact_soft1.wav",
        "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disableshadows": "1"},
        [[([(at[0] - 1, at[1] - 1, at[2] - 2), (at[0] + 1, at[1] - 1, at[2] - 2), (at[0] + 1, at[1] + 1, at[2] - 2), (at[0] - 1, at[1] + 1, at[2] - 2)], MAT["nodraw"]),
          ([(at[0] - 1, at[1] - 1, at[2] + 2), (at[0] + 1, at[1] - 1, at[2] + 2), (at[0] + 1, at[1] + 1, at[2] + 2), (at[0] - 1, at[1] + 1, at[2] + 2)], MAT["nodraw"])]
         + [([(xa, ya, at[2] - 2), (xb, yb, at[2] - 2), (xb, yb, at[2] + 2), (xa, ya, at[2] + 2)], MAT["nodraw"])
            for (xa, ya), (xb, yb) in (((at[0] - 1, at[1] - 1), (at[0] + 1, at[1] - 1)), ((at[0] + 1, at[1] - 1), (at[0] + 1, at[1] + 1)),
                                       ((at[0] + 1, at[1] + 1), (at[0] - 1, at[1] + 1)), ((at[0] - 1, at[1] + 1), (at[0] - 1, at[1] - 1)))]],
        self.vis, connections=[("OnOpen", name, "PressIn", "", 0), ("OnOpen", name + "_sound", "PlaySound", "", 0),
                               ("OnClose", name, "PressOut", "", 0), ("OnClose", name + "_sound", "PlaySound", "", 0)])
    v.point("prop_dynamic", at, {"targetname": pic + "_model", "model": "models/props_lab/frame001a.mdl", "angles": "0 %d 9" % wyaw(facing), "parentname": pic,
                                 "solid": "0", "skin": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0",
                                 "spawnflags": "0"}, self.vis)
    # the button on the tunnel's side: Episode Two's mine lift button (the bunker's wall_button) on the passage's north
    # wall in the silo's hull, 10 over the passage's floor (the passage is 48 high: crouched, it is at hand); it turns the
    # picture, which works the panel
    from map_forest import wall_button
    hx = 9216
    wall_button(v, (hx, 6280, -1230), 270, "lc_silo_secret_button", (hx - 10, 6270, -1234, hx + 10, 6280, -1206), self.vis,
                [("OnPressed", pic, "Toggle", "", 0)], "2")
    # an areaportal in the opening, behind the panel (always open): the way out joins the bunker to the forest a second
    # way, so without it the main door's areaportal no longer parts two areas (the owner's compile of 22 November:
    # "Brush 2754: areaportal brush doesn't touch two areas ... AREAPORTAL LEAKED", 2754 being lc_bunker_portal)
    v.world_box(wbox(self.d, (-141, 500, 304, 0, 544, 320)), wall, top=wall, bottom=wall, vis=self.vis, faces=face)     # (the sill under it: our own, so it is sealed below)
    v.areaportal(wbox(self.d, (-104, 524, 320, -24, 526, 368)), self.vis, name + "_portal")
    e = Escape(self)
    # (the skin check: the tunnel's faces must meet each other but at its two ends, the squeezes' mouths: 28 edge points
    # each; the cave's own pieces meet Valve's faces and brushes, which the check does not see)
    self.f.skin_skip = {e.xvis}
    self.f.skin_free = 2 * 28
    e.tunnel()
    kept = e.cave()
    e.exit_room()
    e.container()
    # the way out's sound: the mine tunnel's (Ravenholm's), from the first squeeze and in the cave (soundscapes())
    for at, r in (((9100, 6240, -1210), 240), ((8880, 5450, F_EXIT + 72), 400)):
        v.point("env_soundscape", at, {"soundscape": SCAPE_CAVE, "radius": str(r), "StartDisabled": "0"}, self.f.vis("silo's wiring"))
    self.f.notes.append("the leader's way out: a secret panel in his bedroom, a crouch squeeze, a cave tunnel of four ramps up in switchbacks and one south, "
                        "a squeeze into Episode Two's cache cave (%d of its things) on the forest's north rim, and a rock a lever inside slides away" % kept)


Silo.escape = _escape


def route_picture(path):
    """A plan of the leader's way out for the owner: the forest's north half shaded by height, the gate and the trail to
    the bunker's door, the bunker's deep level and the corridor to the silo, the silo, and the tunnel from the bedroom
    (its pieces coloured by height, the squeezes red) to the cave and the rock on the rim (white)."""
    from PIL import Image, ImageDraw
    import map_forest as M
    f = M.BunkerForest("forest (bunker, pond)", (8064, 1088), 400, 31, 4400, ("west", 3072))
    f.setup()
    X1, Y1, X2, Y2, k = 7800, 3000, 11400, 7000, 3.0
    img = Image.new("RGB", (int((X2 - X1) / k), int((Y2 - Y1) / k)), (24, 24, 28))
    dr = ImageDraw.Draw(img, "RGBA")
    P = lambda x, y: ((x - X1) / k, (Y2 - y) / k)
    for gx in range(int(X1), int(X2), 24):
        for gy in range(int(Y1), int(Y2), 24):
            lx, ly = gx - f.ox, gy - f.oy
            if 0 <= lx <= f.W and 0 <= ly <= f.D:
                h = f.natural(lx, ly)
                c = int(60 + (h - 380) / 560.0 * 150)
                a, b = P(gx, gy + 24), P(gx + 24, gy)
                dr.rectangle((a[0], a[1], b[0], b[1]), fill=(40, max(40, min(230, c)), 40))
    a, b = P(f.ox, f.oy + f.D), P(f.ox + f.W, f.oy)
    dr.rectangle((a[0], a[1], b[0], b[1]), outline=(200, 200, 200), width=2)
    for tr in f.trails:
        dr.line([P(f.ox + x, f.oy + y) for x, y in tr], fill=(210, 180, 120), width=3)
    side, g = f.gate
    dr.line((P(f.ox, f.oy + g), P(f.ox, f.oy + g + 512)), fill=(255, 220, 60), width=6)
    dr.text(P(f.ox + 20, f.oy + g + 560), "gate (invaders come in here)", fill=(255, 220, 60))
    bx, by = f.ox + f.B0[0], f.oy + f.B0[1]
    for plan in (f.deep, f.low):
        for (i, j), spec in plan.cells.items():
            if spec[0] != "solid":
                a, b = P(bx + i * 64, by + (j + 1) * 64), P(bx + (i + 1) * 64, by + j * 64)
                dr.rectangle((a[0], a[1], b[0], b[1]), fill=(120, 120, 130))
    dr.ellipse((P(bx + 640, by)[0] - 6, P(bx + 640, by)[1] - 6, P(bx + 640, by)[0] + 6, P(bx + 640, by)[1] + 6), fill=(255, 90, 60))
    dr.text((P(bx + 680, by)[0], P(bx + 680, by)[1] - 6), "bunker door", fill=(255, 120, 90))
    sx, sy = 9792, 6304
    a, b = P(sx - 544, sy + 544), P(sx + 544, sy - 544)
    dr.rectangle((a[0], a[1], b[0], b[1]), outline=(170, 170, 200), width=2)
    dr.ellipse((P(sx, sy)[0] - 85, P(sx, sy)[1] - 85, P(sx, sy)[0] + 85, P(sx, sy)[1] + 85), outline=(170, 170, 200), width=2)
    dr.text(P(sx - 120, sy + 60), "silo", fill=(200, 200, 230))
    bed = W((sx, sy, -1560), (-150, 380, 0))
    dr.text((P(bed[0], bed[1])[0] - 30, P(bed[0], bed[1])[1] - 30), "bedroom", fill=(255, 255, 255))
    for S in _segments():
        x1, y1, x2, y2 = S["box"]
        s0 = (x1 + x2) / 2.0 if S["axis"] == "x" else (y1 + y2) / 2.0
        z = S["floor"](s0)
        squeeze = S["height"](s0) < 72
        t = (z + 1240) / 2068.0
        col = (230, 40, 40) if squeeze else (int(80 + 150 * t), int(60 + 60 * t), int(230 - 150 * t))
        a, b = P(x1, y2), P(x2, y1)
        dr.rectangle((a[0], a[1], b[0], b[1]), fill=col)
    for x, y, lab in ((8300, 6300, "z -1240"), (8300, 6156, "-692"), (8300, 6012, "-144"), (8300, 5868, "404"), (8640, 5650, "+828")):
        dr.text(P(x, y + 40), lab, fill=(255, 255, 255))
    cave = [(8740, 5200), (8996, 5264), (9124, 5392), (9060, 5712), (8740, 5648)]
    dr.polygon([P(*p) for p in cave], fill=(150, 110, 70), outline=(255, 255, 255))
    hx = (EXIT_HOLE[0] + EXIT_HOLE[1]) / 2.0
    c = P(hx, 5150)
    dr.ellipse((c[0] - 9, c[1] - 9, c[0] + 9, c[1] + 9), fill=(255, 255, 255))
    dr.text((c[0] + 14, c[1] - 4), "the rock (way out, on the rim)", fill=(255, 255, 255))
    dr.text((8, 8), "The leader's way out, from above (north up; 1 px = 3 units). Red: crouch squeezes; blue to tan: the tunnel rising.", fill=(255, 255, 255))
    img.save(path)
    print("picture: " + path)


if __name__ == "__main__":
    import sys
    if len(sys.argv) == 3 and sys.argv[1] == "--route":
        route_picture(sys.argv[2])
    else:
        print("python3 map_silo.py --route OUT.png    a plan of the leader's way out")
