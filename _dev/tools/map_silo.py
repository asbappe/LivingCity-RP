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
FINISH_RINGS = ((240, 530, 316, 580), (240, 530, 890, 1094), (240, 530, 1146, 1350))
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
        self.detail([prism(self.d, ngon(108, 16), 314, 322, "METAL/METALHULL003A", top="METAL/METALGRATE_SILO01B", bottom="METAL/METALGRATE013A2")])

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
            self.prop("props_junk/wood_crate001a", *(at(ang, r[ang] - 26) + (za + dz, ang + 7 * k, "d")))
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
        self.prop("props_lab/frame002a", 345 * math.cos(a) - 12, 345 * math.sin(a) - 4, z + 82, 112.5, "s")
        self.prop("props_junk/garbage_coffeemug001a", 345 * math.cos(a) + 10, 345 * math.sin(a) + 6, z + 82, 40, "d")
        self.light(-170, 390, z + 160, "253 230 159", 35)
