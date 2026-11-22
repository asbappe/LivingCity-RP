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

# the piece's brushes left out: the fake door at level B's south end (131; its north twin is the func_brush
# brush_fake_cit_door_1, dropped with the wiring) and the bottom level's outer wall behind the bedroom (577), rebuilt
# round the secret door
SKIP = {131, 577}
# props of the piece left out: the static door into the bedroom (a working door now) and the big cooling tank in the
# office (it filled the office's east half)
DROP_PROPS = (("silo_door01_static", (16, 388, 324)), ("horizontalcoolingtank04", (284, 484, 374)))


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
    def hatch_rail(self):
        """The hole Valve's hatch left in the gantry over the ladder (x -19..19, y -245..-209, the ladder on its wall
        side): a rail 44 high round its west and north sides, open on the east, where the ladder's top lets you off
        (Valve's dismount 41 east of it; the other two are behind the rail and the engine passes over them)."""
        z1, z2, rail, cap = 1408, 1452, "METAL/METALRAIL012C", "METAL/METALWALL031A"
        self.detail([prism(self.d, [(-23, -251), (-21, -251), (-21, -205), (-23, -205)], z1, z2, rail, top=cap, bottom=cap),
                     prism(self.d, [(-21, -207), (23, -207), (23, -205), (-21, -205)], z1, z2, rail, top=cap, bottom=cap)])

    # -- 3. the floors ----------------------------------------------------------------------------------------------
    def level_b_doors(self):
        """Level B's two fake doors (a slab painted as a door at each end of the hall by the lift) become working doors
        into the rest of the ring: Episode Two's silo door as every other in the bunker (SILO_DOOR), carried by an unseen
        func_door on the doorway's slant, sliding 64 toward the shaft into the wall. Valve's keypads beside them stay."""
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
                "targetname": name + "_model", "model": "models/props_silo/silo_door01.mdl", "angles": "0 %d 0" % wyaw(yaw), "parentname": name, "skin": "0",
                "solid": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255",
                "rendercolor": "255 255 255", "modelscale": "1.0", "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0",
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
        self.light(-170, 390, z + 160, "253 230 159", 35)

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
EXIT_HOLE = (9020, 9132, F_EXIT, F_EXIT + 80)     # the way out through the rock face: x from, to; z from, to (at y 5184)
CUT = (8840, 9184)           # the forest's north wall is cut between these x (the face of rock fills it)
FACE_TOP = F_EXIT + 176
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


class Escape:
    def __init__(self, silo):
        self.s, self.f, self.v, self.d = silo, silo.f, silo.v, silo.d
        self.vis = self.f.vis("the leader's way out (tunnel)")
        self.xvis = self.f.vis("the leader's way out (cave, rock face, rock)")
        self.rock = "nature/blendrockdirt_tunnel03a"

    def disp_box(self, box, face, target, alpha, mat=None, sides=None, vis=None):
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
                               disp={face: (3, tg, al)})
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
            dirt_floor = lambda p: 230
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
                self.disp_box((X1, Y1, zmin - T, X2, Y2, zmin), "top", floor_pt, dirt_floor)
                self.disp_box((X1, Y1, zmax, X2, Y2, zmax + T), "bottom", roof_pt, roof_alpha)
                if ax in ("x", None):
                    if "n" not in S["open"]:
                        self.disp_box((X1, Y2, zmin, X2, Y2 + T, zmax), "south", wall_pt(0, -1), wall_alpha)
                    if "s" not in S["open"]:
                        self.disp_box((X1, Y1 - T, zmin, X2, Y1, zmax), "north", wall_pt(0, 1), wall_alpha)
                if ax in ("y", None):
                    if "e" not in S["open"]:
                        self.disp_box((X2, Y1, zmin, X2 + T, Y2, zmax), "west", wall_pt(-1, 0), wall_alpha)
                    if "w" not in S["open"]:
                        self.disp_box((X1 - T, Y1, zmin, X1, Y2, zmax), "east", wall_pt(1, 0), wall_alpha)
        # dim light along it: warm, steady, every 400 or so along each run, two thirds up (lesson valve-cave-lighting:
        # no walking spot far from one)
        for S in _segments():
            if not S["axis"]:
                continue
            x1, y1, x2, y2 = S["box"]
            a, b = (x1, x2) if S["axis"] == "x" else (y1, y2)
            for k in range(max(1, int((b - a) // 400))):
                s_ = a + (k + 0.5) * (b - a) / max(1, int((b - a) // 400))
                x, y = (s_, (y1 + y2) / 2.0) if S["axis"] == "x" else ((x1 + x2) / 2.0, s_)
                z = S["floor"](s_) + 0.6 * S["height"](s_)
                self.v.point("light", (int(x), int(y), int(z)), {"_light": "255 190 120 35", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.s.lv)

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
        for p in pf["points"]:
            o = p["origin"]
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
            w = [a + b for a, b in zip(PF.rot(o, q), d)]
            v.point(cls, (int(round(w[0])), int(round(w[1])), int(round(w[2]))), keys, self.xvis if cls != "light" else self.s.lv)
            kept += 1
        return kept

    def exit_room(self):
        """What joins the cave to the tunnel and to the forest: its west wall with the last squeeze's hole; the floor
        under its north half; a porch from its mouth to the forest's wall; the face of rock on the forest's side (on the
        rim, where the wall is cut) with the way out through it; the big rock that shuts it; the lever inside."""
        f, v, F = self.f, self.v, F_EXIT
        cliff = "nature/blendcliffdirt001a"
        wall_mat = "nature/blendrockdirt_tunnel03a"

        def bulge(axis_n, amp, edges):
            """A displaced face pushed along axis_n (a unit vector) by noise, nothing on the box's own edges."""
            (ea1, ea2, ia), (eb1, eb2, ib) = edges

            def f_(p):
                w = _taper(p[ia], ea1, ea2, 32) * _taper(p[ib], eb1, eb2, 32)
                k = amp * _noise(p[0], p[1], p[2], 5) * w
                return (p[0] + axis_n[0] * k, p[1] + axis_n[1] * k, p[2] + axis_n[2] * k)
            return f_
        flat_alpha = lambda p: 120
        floor_alpha = lambda p: 230
        # the cave's west wall (ours), on the line of Valve's south wall: three pieces round the squeeze's hole
        for (y1, y2, z1, z2) in ((5192, 5380, F - 8, F + 200), (5460, 5656, F - 8, F + 200), (5380, 5460, F + 48, F + 200)):
            self.disp_box((8724, y1, z1, 8740, y2, z2), "east", bulge((1, 0, 0), 10, ((y1, y2, 1), (z1, z2, 2))), lambda p: 60, mat=wall_mat, vis=self.xvis)
        # the floor under the cave's north half and the porch (Valve's hillside floor in their map)
        self.disp_box((8932, 5184, F - 17, 9156, 5712, F - 1), "top", bulge((0, 0, 1), 3, ((8932, 9156, 0), (5184, 5712, 1))), floor_alpha, mat="nature/blendgrassdirt01", sides={"south": wall_mat}, vis=self.xvis)
        # the porch: from the cave's mouth to the forest's wall, as high as the cave (Valve's roof covers most of it)
        # (its west side is the end of Valve's own wall, which ran out to the mouth)
        for box, face, n in (((9156, 5184, F, 9172, 5392, F + 192), "west", (-1, 0, 0)), ((9140, 5392, F, 9172, 5408, F + 192), "south", (0, -1, 0))):
            ax_ = (1, 2) if face in ("west", "east") else (0, 2)
            self.disp_box(box, face, bulge(n, 9, ((box[ax_[0]], box[ax_[0] + 3], ax_[0]), (box[2], box[5], 2))), flat_alpha, mat=wall_mat, vis=self.xvis)
        for box in ((9124, 5184, F + 192, 9172, 5392, F + 208), (8980, 5184, F + 192, 9124, 5200, F + 208)):
            self.disp_box(box, "bottom", bulge((0, 0, -1), 6, ((box[0], box[3], 0), (box[1], box[4], 1))), lambda p: 0, mat=wall_mat, vis=self.xvis)
        # the face of rock on the forest's side, round the way out (hole x 9024..9128, z F..F+76): pushed toward the
        # forest by noise, straight along every edge, so that its three pieces meet
        hx1, hx2, hz1, hz2 = EXIT_HOLE
        for (x1, x2, z1, z2, seen) in ((CUT[0], hx1, F - 48, FACE_TOP, ("west", "east")), (hx2, CUT[1], F - 48, FACE_TOP, ("west", "east")), (hx1, hx2, hz2, FACE_TOP, ("bottom",))):
            self.disp_box((x1, 5168, z1, x2, 5184, z2), "south", bulge((0, -1, 0), 22, ((x1, x2, 0), (z1, z2, 2))), lambda p: 40, mat=cliff,
                          sides=dict((n, cliff) for n in seen), vis=self.xvis)
        # the wall's cut: sealed under the porch, sky over the face
        nd, sky = MAT["nodraw"], MAT["sky"]
        v.world_box((CUT[0], 5184, f.zb, CUT[1], 5312, F - 17), nd, vis=self.xvis)
        v.world_box((CUT[0], 5184, FACE_TOP, CUT[1], 5312, f.lid), sky, sky, sky, vis=self.xvis)
        # the rock: a func_button that only the lever moves (no use, no touch, no damage: nothing outside opens it), a
        # forest boulder (props_foliage/rock_forest04, drawn a third larger) riding it, filling the hole; it slides 160
        # west to open, at 40 a second (4 s), and stops against whoever is in its way. The unseen brush is what blocks.
        rock, lever = "lc_escape_rock", "lc_escape_lever"
        mid = (hx1 + hx2) // 2
        v.brush_entity("func_button", {"targetname": rock, "movedir": "0 180 0", "speed": "40", "lip": "38", "wait": "-1", "spawnflags": "0", "sounds": "0",
                                       "health": "0", "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255"},
                       [(mid - 100, 5100, F - 22, mid + 100, 5166, F + 84)], nd, self.xvis)
        v.point("prop_dynamic_override", (mid, 5150, F + 30), {
            "targetname": rock + "_model", "model": "models/props_foliage/rock_forest04.mdl", "angles": "0 90 0", "parentname": rock, "solid": "0", "skin": "0",
            "disableshadows": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "spawnflags": "0", "renderamt": "255",
            "rendercolor": "255 255 255", "modelscale": "1.3", "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0",
            "PerformanceMode": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0"}, self.xvis)
        v.point("ambient_generic", ((hx1 + hx2) // 2, 5190, F + 40), {"targetname": rock + "_sound", "message": "physics/concrete/rock_scrape_rough_loop1.wav",
                                                                      "health": "10", "pitch": "90", "pitchstart": "90", "radius": "1500", "spawnflags": "16"}, self.xvis)
        # the lever: Valve's, as in the leader's office (a func_rot_button pulled down 45 degrees; Use pulls it and
        # pushes it back), on the porch's east wall facing in
        lx, ly, lz = 9155, 5300, F + 52
        v.brush_entity("func_rot_button", {"targetname": lever, "angles": "0 0 0", "distance": "-45", "speed": "35", "wait": "-1", "spawnflags": str(1024 | 32 | 128),
                                           "sounds": "0", "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255",
                                           "origin": "%d %d %d" % (lx, ly, lz)},
                       [(lx - 9, ly - 4, lz, lx + 6, ly + 4, lz + 16)], nd, self.xvis,
                       connections=[("OnPressed", lever + "_sound", "PlaySound", "", 0), ("OnIn", rock, "PressIn", "", 0.3), ("OnIn", rock + "_sound", "PlaySound", "", 0.3),
                                    ("OnIn", rock + "_sound", "StopSound", "", 4.3), ("OnOut", rock, "PressOut", "", 0.3), ("OnOut", rock + "_sound", "PlaySound", "", 0.3),
                                    ("OnOut", rock + "_sound", "StopSound", "", 4.3)])
        for model, ang, parent in (("panel_leverbase001a", "0 180 0", None), ("panel_leverhandle001a", "15 180 0", lever)):
            keys = {"model": "models/props_wasteland/%s.mdl" % model, "angles": ang, "solid": "0", "skin": "0", "disableshadows": "1", "fademindist": "-1",
                    "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "spawnflags": "0"}
            if parent:
                keys["parentname"] = parent
            v.point("prop_dynamic", (lx, ly, lz), keys, self.xvis)
        v.point("ambient_generic", (lx, ly, lz + 10), {"targetname": lever + "_sound", "message": "streetwar.drawbridge_lever_start", "health": "10", "pitch": "100",
                                                       "pitchstart": "100", "radius": "1250", "spawnflags": "48"}, self.xvis)
        v.point("light", (9080, 5260, F + 120), {"_light": "255 196 130 45", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, self.s.lv)

    def container(self):
        """The sealed box round the tunnel and the cave (nodraw world brushes 16 thick): what keeps the map shut, since
        displaced faces seal nothing. Its south side is the forest's own north wall and slab, down to the slab's foot,
        and a wall of ours under that; its east side has the hole the first squeeze comes through from the silo."""
        x1, y1, z1, x2, y2, z2 = CONTAINER
        nd, v, T = MAT["nodraw"], self.v, 16
        hy1, hy2, hz1, hz2 = 6200, 6280, -1240, -1192
        for b in ((x1, y1, z1, x2, y2, z1 + T), (x1, y1, z2 - T, x2, y2, z2), (x1, y2 - T, z1, x2, y2, z2), (x1, y1, z1, x1 + T, y2, z2),
                  (x1, y1, z1, x2, y1 + T, self.f.zb - 64),
                  (x2 - T, y1, z1, x2, hy1, z2), (x2 - T, hy2, z1, x2, y2, z2), (x2 - T, hy1, z1, x2, hy2, hz1), (x2 - T, hy1, hz2, x2, hy2, z2)):
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
    own concrete) that Use slides 76 east into the wall, and back: a func_button used as a mover (Use, toggle), so the
    gamemode's door rules (kicks, picks, NPCs) never touch it. Behind it the bedroom's outer wall (Valve's 577, rebuilt
    round the opening) and the hull, then the cave tunnel."""
    v, z = self.v, self.FLOOR
    wall = "CONCRETE/CONCRETEWALL010A"
    face = {"east": "CONCRETE/EP2_CONCRETEWALL01B"}      # (the piece's -y face, toward the bedroom, is the map's east)
    for b in ((-141, 500, 320, -104, 544, 416), (-24, 500, 320, 0, 544, 416), (-104, 500, 368, -24, 544, 416)):
        v.world_box(wbox(self.d, b), wall, top=wall, bottom=wall, vis=self.vis, faces=face)
    name = "lc_silo_secret_panel"
    v.brush_entity("func_button", {"targetname": name, "movedir": "0 %d 0" % wyaw(0), "speed": "30", "lip": "4", "wait": "-1", "spawnflags": str(1024 | 32),
                                   "sounds": "0", "health": "0", "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"},
                   [(wbox(self.d, (-104, 500, 320, -24, 504, 368)), {"east": "CONCRETE/EP2_CONCRETEWALL01B"})], MAT["nodraw"], self.vis,
                   connections=[("OnPressed", name + "_sound", "PlaySound", "", 0)])
    v.point("ambient_generic", self.P(-64, 490, 344), {"targetname": name + "_sound", "message": "doors/doormove2.wav", "health": "8", "pitch": "80", "pitchstart": "80",
                                                       "radius": "600", "spawnflags": "48"}, self.vis)
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
