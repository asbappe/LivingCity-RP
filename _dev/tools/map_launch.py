"""The bunker forest's control complex up by the silo (24 November).

The owner: "for the bunker itself, can we look at the EP2 white forest rooms and just copy/paste the layout and concepts?
I remember there being a room with tons of control panels at the beginning of the white forest areas", then (with the
launch control room of ep2_outland_12a) "joined up by the silo please; and it is ok to reorganize the bunker to make this
work; so long as the bedroom/bathroom room and the red plant room remain the same inside then they can be moved around".

Two of Valve's rooms, lifted as they are and joined (docs/dev/prefabs.md):
- valve_ep2_control_room: White Forest's control room in ep2_outland_11 (the room the owner pointed to round -65 -9922 77;
  Valve's soundscape there is ep2_silo.techroom), under the ground east of the silo, its floor the bunker's deep level.
  The walkway from the bunker comes in at its south door; its east door opens on a stair up to the launch room.
- valve_ep2_launch_room: Episode Two's launch control room (ep2_outland_12a), turned so its window looks west over the
  launch pad at the silo 1,656 away, as Valve has it; its floor at the bunker door's level.

Everything is in the map's own coordinates. BunkerForest (map_forest.py) calls build() from bunker()."""

import map_prefab as PF
from map_build import MAT, Plan

# White Forest's control room: the piece's frame (its anchor, Valve's -432 -10144 0) put at TECH_AT, not turned. Its box
# in that frame (Valve's z) and so in the map.
TECH_AT = (11456, 5424, 40)
TECH_BOX = (0, 0, 32, 672, 528, 272)
# Episode Two's launch room and everything of ep2_outland_12a: the piece's anchor (the silo's collar's middle, Valve's
# -200 -24 0) on our silo's axis, turned a quarter (Valve's south, the room's side, to our east), Valve's ground (-1280)
# at 344, just over the silo's hull. The room's box in the map.
LR_TURN, LR_AT = 1, (9792, 6304, 1624)
LR_BOX = (11432, 6056, 304, 11904, 6600, 784)
# The stair from the control room's east door up to the launch room's back (where Valve's lift came up): its plan's
# corner, its squares (its own frame), the floors it joins.
STAIR_AT = (12096, 5632)
FLOOR_LOW, FLOOR_HIGH = 104, 424
HULL = 64
# The launch pad (valve_ep2_launch_outside, placed as the launch room): its own sky over the box OUT (from the room's
# window to the silo and past it, between the forest's north wall and the line the ring keeps clear, y 6976), as high
# as the rocket's climb needs (SKY). Valve's ground round the silo (a bowl down to 138, through our silo's top floor) is
# left out: a flat pad at the collar's top (PAD) instead; Valve's ground in front of the window kept (TILE26).
OUT = (9168, 5440, 11432, 6976)
SKY = 4224
TILE26 = (10792, 5480, 11304, 5992)
PAD = 337
SILO = (9792, 6304)
SQUARE = 416            # (the collar's square round the silo's axis: the pad stops there, the collar's apron and sectors fill it)
SILO_HULL = (9184, 5696, 10400, 6976)       # (where the pad is the silo's lid: from its top floor's ceiling, 200)
LOW_GAP = (9600, 5440, 9984, 5696)          # (the corridor's stairs down to the silo pass under here: the pad is thin over them)


def tech_box():
    x1, y1, z1, x2, y2, z2 = TECH_BOX
    ax, ay, az = TECH_AT
    return (ax + x1, ay + y1, az + z1, ax + x2, ay + y2, az + z2)


def shell(v, box, holes, vis, mat=None, skip=()):
    """A sealing shell HULL thick round box (nodraw), with rectangular holes in its sides: holes is [(side, (a1, b1, a2,
    b2))] where a and b run along the side's two axes in the order x, y, z (a "west" side's holes are (y1, z1, y2, z2));
    skip: sides left out (another piece seals there). Returns the boxes."""
    x1, y1, z1, x2, y2, z2 = box
    T, nd = HULL, mat or MAT["nodraw"]
    sides = {"west": (x1 - T, y1 - T, z1 - T, x1, y2 + T, z2 + T), "east": (x2, y1 - T, z1 - T, x2 + T, y2 + T, z2 + T),
             "south": (x1, y1 - T, z1 - T, x2, y1, z2 + T), "north": (x1, y2, z1 - T, x2, y2 + T, z2 + T),
             "bottom": (x1, y1, z1 - T, x2, y2, z1), "top": (x1, y1, z2, x2, y2, z2 + T)}
    axes = {"west": (1, 2), "east": (1, 2), "south": (0, 2), "north": (0, 2), "bottom": (0, 1), "top": (0, 1)}
    out = []
    for name, b in sides.items():
        if name in skip:
            continue
        pieces = [list(b)]
        for side, (a1, b1, a2, b2) in holes:
            if side != name:
                continue
            p, q = axes[name]
            nxt = []
            for c in pieces:
                if a2 <= c[p] or a1 >= c[p + 3] or b2 <= c[q] or b1 >= c[q + 3]:
                    nxt.append(c)
                    continue
                lo, hi = max(a1, c[p]), min(a2, c[p + 3])
                if c[p] < lo:
                    nxt.append(c[:p + 3] + [lo] + c[p + 4:])
                if hi < c[p + 3]:
                    nxt.append(c[:p] + [hi] + c[p + 1:])
                mid = c[:p] + [lo] + c[p + 1:p + 3] + [hi] + c[p + 4:]
                if mid[q] < b1:
                    nxt.append(mid[:q + 3] + [b1] + mid[q + 4:])
                if b2 < mid[q + 3]:
                    nxt.append(mid[:q] + [b2] + mid[q + 1:])
            pieces = nxt
        for c in pieces:
            if all(c[k] < c[k + 3] for k in range(3)):
                v.world_box(tuple(c), nd, vis=vis)
                out.append(tuple(c))
    return out


def lifted_door(e, PF_):
    """One of Valve's silo doors (func_door with its silo_door01 on it) made to open and shut by Use as the bunker's room
    doors do: it stays open, its wheel unlocks as it opens and locks when it shuts, nothing else fires."""
    k = e["keys"]
    k.update({"spawnflags": str((int(k.get("spawnflags", "0") or 0) | 256) & ~1024), "wait": "-1", "forceclosed": "0", "dmg": "0"})
    prop = [o for o in e["out"] if o[2] == "SetAnimation"]
    name = prop[0][1] if prop else None
    e["out"] = [("OnOpen", name, "SetAnimation", "unlock", 0), ("OnFullyClosed", name, "SetAnimation", "lock", 0)] if name else []


def loose(e):
    """Valve's loose things (prop_physics) stand where Valve put them, solid, as the bunker's furniture does (a
    prop_dynamic_override): nobody knocks the control rooms' kit about, and it stays in step with the room on every
    player's screen."""
    if e["classname"] == "prop_physics":
        e["classname"] = "prop_dynamic_override"
        k = e["keys"]
        for key in ("spawnflags", "massScale", "inertiaScale", "physdamagescale", "minhealthdmg", "shadowcastdist", "forcetoenablemotion", "nodamageforces",
                    "damagetoenablemotion", "Damagetype", "PerformanceMode"):
            k.pop(key, None)
        k.update({"solid": "6", "spawnflags": "0", "StartDisabled": "0"})


def build(f, F):
    """The complex, for BunkerForest f (map_forest.py, passed as F): the control room, the stair, the launch room, each
    sealed by a hull of our own (Valve's brushes do not count for the build's checks). Returns the boxes of air they
    add (for the bunker door's failsafe) and the places the checks must reach."""
    v = f.vmf
    vis, wv, hv = f.vis("control complex (Valve's rooms)"), f.vis("control complex's wiring"), f.vis("control complex's hull (sealed)")
    air, places = [], []
    # --- White Forest's control room -------------------------------------------------------------------------------------
    pf = PF.load("valve_ep2_control_room")
    F.pf_solids(v, pf, 0, TECH_AT, vis, world=True, skip=lambda s: "taken shut" in s["from"])

    def keep(e):
        k = e["keys"]
        if e["classname"] == "func_button" and not any("count_mon_1" in c[1] for c in e.get("connections", [])):
            return False        # (the keypads by the doors: models only, as the bunker's; the doors open by Use)
        if e["classname"] in ("info_target", "info_lighting") and not k.get("targetname", "").startswith("l_"):
            return k.get("targetname", "") in ()
        return e["classname"] not in ("logic_auto",)

    def edit(e):
        k = e["keys"]
        tn = k.get("targetname", "")
        loose(e)
        if e["classname"] == "func_door":
            lifted_door(e, PF)
        if e["classname"] == "prop_dynamic" and "silo_door01" in k.get("model", ""):
            e["classname"] = "prop_dynamic_override"      # (the model has physics data: map_assets.py)
            k["solid"] = "0"
            door = "door_silo_1" if tn.endswith("_1") else "door_silo_2"
            k["parentname"] = door
        if e["classname"] == "func_button":         # (the forest cams' button: steps the screens, as Valve's, without the story)
            e["out"] = [o for o in e["out"] if not o[1].startswith("lcs_")]
        if tn.startswith("r_mon_") and ("thanks" in tn or "react" in tn):
            e["drop"] = True
        if e["classname"] == "math_counter" and tn == "math_mon_hatelife":
            e["drop"] = True
    F.pf_entities(v, pf, 0, TECH_AT, "lc_ctl_", vis, wv, keep=keep, edit=edit, valve_anchor=pf["anchor"])
    tb = tech_box()
    leg = (f.ox + f.B0[0] + f.NE_LEG[0], f.ox + f.B0[0] + f.NE_LEG[1])
    shell(v, tb, [("south", (leg[0], f.zd, leg[1], f.zd + 160)), ("east", (STAIR_AT[1], FLOOR_LOW, STAIR_AT[1] + 128, FLOOR_LOW + 160))], hv)
    air.append(tb)
    places.append(((tb[0] + tb[3]) / 2.0, (tb[1] + tb[4]) / 2.0, FLOOR_LOW + 64, "control room"))
    # --- the stair up to the launch room ------------------------------------------------------------------------------
    sx, sy = STAIR_AT
    look = dict(floor_side=F.FMAT["wf_upper"], ceiling=F.FMAT["wf_ceiling"], vis=f.vis("structures"))
    st = F.WFPlan((sx, sy), FLOOR_LOW - 64, FLOOR_HIGH + 240, **look)
    # (no wall of its own inside the control room or the launch room: their hulls close it there; its walls beside the
    #  passage reach 32 into the control room's box, over Valve's wall there)
    st.keep_out += [(-100000, -100000, 0, tb[4] - sy), (-100000, LR_BOX[1] - sy, LR_BOX[3] - sx, 100000)]
    fm = F.FMAT["wf_floor"]
    st.paint((0, 0, 192, 128), ("low", FLOOR_LOW, fm, FLOOR_LOW + 160))           # the passage from the control room's east door
    for r in ((64, 128, 192, 576), (-192, 448, 64, 576)):                        # the two flights and the landing between them
        st.paint(r, ("low", FLOOR_LOW, fm, FLOOR_HIGH + 176))
    st.walls()
    st.build(v)
    B = st.box
    wall = F.FMAT["wf_floor"]
    v.detail([B(64, 128 + 24 * k, FLOOR_LOW, 192, 152 + 24 * k, FLOOR_LOW + 16 * (k + 1)) for k in range(10)], wall, vis=vis, top=MAT["stairs"])
    v.detail([B(64, 368, FLOOR_LOW, 192, 576, FLOOR_LOW + 160)], wall, vis=vis, top=wall)       # (the landing between the flights)
    v.detail([B(64 - 24 * (k + 1), 448, FLOOR_LOW, 64 - 24 * k, 576, FLOOR_LOW + 160 + 16 * (k + 1)) for k in range(10)], wall, vis=vis, top=MAT["stairs"])
    v.detail([B(-192, 448, FLOOR_LOW, -176, 576, FLOOR_HIGH)], wall, vis=vis, top=wall)          # (the top landing, at the launch room's floor)
    # (where the stair's top meets the launch room, over the gap Valve's lift ran in: a floor at the room's, its end wall
    #  under it down to the stair's foot)
    v.world_box(B(-256, 448, FLOOR_LOW - 64, -192, 576, FLOOR_HIGH), MAT["nodraw"], top=F.FMAT["wf_floor"], vis=hv)
    f.stair_plan = st
    for x1, y1, x2, y2, sp in st.rectangles():
        if sp[0] != "solid":
            air.append(B(x1, y1, sp[1] - 8, x2, y2, sp[3]))
    places.append((sx + 128, sy + 64, FLOOR_LOW + 64, "foot of the stair to the launch room"))
    places.append((sx - 64, sy + 512, FLOOR_HIGH + 64, "top of the stair to the launch room"))
    # --- Episode Two's launch room -------------------------------------------------------------------------------------
    lr = PF.load("valve_ep2_launch_room")
    F.pf_solids(v, lr, LR_TURN, LR_AT, vis, world=True, skip=lambda s: "taken shut" in s["from"] and "door" not in s["from"])      # (its screens are live: cctv())
    # its props, lights and screens as Valve has them (the launch's wiring: launch())
    def in_room(e):
        p = F.pf_point(e["origin"], LR_TURN, LR_AT)
        return all(LR_BOX[k] <= p[k] <= LR_BOX[k + 3] for k in range(3))
    F.pf_entities(v, lr, LR_TURN, LR_AT, "lc_launch_", vis, wv, keep=lambda e: e["classname"].startswith(("prop_", "light", "env_sprite", "infodecal"))
                  and not e["keys"].get("parentname") and not e["keys"].get("targetname") and "brushes" not in e and in_room(e), edit=loose, valve_anchor=lr["anchor"])
    x1, y1, z1, x2, y2, z2 = LR_BOX
    shell(v, LR_BOX, [("east", (sy + 448, LR_BOX[2] - HULL, sy + 576, FLOOR_HIGH + 128))], hv, skip=("west",))     # (its window opens on the pad)
    air.append(LR_BOX)
    air += outside(f, F, lr)
    launch(f, F, lr)
    cctv(f, F, lr)
    places.append(((x1 + x2) / 2.0, (y1 + y2) / 2.0, FLOOR_HIGH + 64, "launch room"))
    f.launch_piece = lr
    # --- their sound: Half-Life 2's own (Valve's ep2_silo ones may not be loaded in Garry's Mod), as the bunker's rooms ---
    sv = f.vis("soundscapes")
    for (x, y, z), name, radius in ((((tb[0] + tb[3]) / 2.0, (tb[1] + tb[4]) / 2.0, FLOOR_LOW + 64), "prison.control_room_simple", 220),
                                    ((sx + 128, sy + 256, FLOOR_LOW + 160), "eli_01_lower_corridor_1", 120),
                                    (((x1 + x2) / 2.0, (y1 + y2) / 2.0, FLOOR_HIGH + 64), "prison.control_room_simple", 220)):
        v.point("env_soundscape", (int(x), int(y), int(z)), {"soundscape": name, "radius": str(radius), "StartDisabled": "0"}, sv)
    return air, places


def cut(rect, hole):
    """rect minus hole, as up to four rectangles (x1, y1, x2, y2)."""
    x1, y1, x2, y2 = rect
    a1, b1, a2, b2 = max(hole[0], x1), max(hole[1], y1), min(hole[2], x2), min(hole[3], y2)
    if a1 >= a2 or b1 >= b2:
        return [rect]
    out = [(x1, y1, x2, b1), (x1, b2, x2, y2), (x1, b1, a1, b2), (a2, b1, x2, b2)]
    return [r for r in out if r[0] < r[2] and r[1] < r[3]]


def split(rects, area):
    """Each rectangle cut along area: [(rectangle, inside area?)]."""
    out = []
    for r in rects:
        a1, b1, a2, b2 = max(area[0], r[0]), max(area[1], r[1]), min(area[2], r[2]), min(area[3], r[3])
        if a1 < a2 and b1 < b2:
            out.append(((a1, b1, a2, b2), True))
        out += [(q, False) for q in cut(r, area)]
    return out


def prism(poly, z1, z2, side, top, bottom, sides=None):
    """A convex prism over the polygon poly (in order round it), its faces' materials: each side's own from sides (by
    its first corner's index) or side."""
    faces = [([(x, y, z2) for x, y in poly], top), ([(x, y, z1) for x, y in reversed(poly)], bottom)]
    for k in range(len(poly)):
        (xa, ya), (xb, yb) = poly[k], poly[(k + 1) % len(poly)]
        faces.append(([(xa, ya, z1), (xb, yb, z1), (xb, yb, z2), (xa, ya, z2)], (sides or {}).get(k, side)))
    return faces


def ray_square(ax, ay, ang, half):
    """Where a ray from (ax, ay) at angle ang (degrees) leaves the square of half-side half round (ax, ay)."""
    import math
    c, s_ = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    t = min(half / abs(c) if abs(c) > 1e-9 else 1e9, half / abs(s_) if abs(s_) > 1e-9 else 1e9)
    return (ax + c * t, ay + s_ * t)


def outside(f, F, lr):
    """The launch pad as Episode Two's launch room sees it (valve_ep2_launch_outside): Valve's fences, walls, steps,
    lights, debris and the silo's collar, and the room's front round its window; a flat pad for Valve's ground round
    the silo; the collar's apron and the join to our silo's top (its ring carried up to the collar, the silo's lid gone);
    the hatch over the mouth; a sky of its own. Returns its air (for the bunker door's failsafe)."""
    import math
    v = f.vmf
    vis, sv = f.vis("launch pad (Valve's ep2_outland_12a)"), f.vis("launch pad's sky (sealed)")
    pf = PF.load("valve_ep2_launch_outside")

    def sig(sol):
        return tuple(sorted(tuple(round(c, 1) for p in sd["plane"] for c in p) for sd in sol["sides"]))
    in_room = set(sig(sol) for sol in lr["solids"])      # (the room's front, lifted with both pieces: placed once, with the room)

    def mbox(sol):
        pts = [F.pf_point(c, LR_TURN, LR_AT) for sd in sol["sides"] for c in (sd.get("corners") or sd["plane"])]
        return [min(p[k] for p in pts) for k in range(3)] + [max(p[k] for p in pts) for k in range(3)]
    tiles_out = set()
    for i, sol in enumerate(pf["solids"]):
        if any(sd.get("disp") for sd in sol["sides"]):
            b = mbox(sol)
            if not ((b[0] >= TILE26[0] - 2 and b[4] <= TILE26[3] + 2) or b[2] > 400):
                tiles_out.add(i)        # (Valve's ground round the silo, a bowl through its top floor: the pad instead)
    index = dict((id(sol), i) for i, sol in enumerate(pf["solids"]))
    F.pf_solids(v, pf, LR_TURN, LR_AT, vis, world=True, skip=lambda sol: sig(sol) in in_room or index[id(sol)] in tiles_out)
    # Valve's props: those that stood on the ground left out are set on the pad as high over it as they stood over Valve's
    # ground (the room's own, lifted with both pieces, are placed with the room; Valve's tower is left out, as asked)
    ground = []
    for i in tiles_out:
        ground += [F.pf_point(q, LR_TURN, LR_AT) for _, q in F.pf_disp_points({"solids": [pf["solids"][i]]})]

    def keep(e):
        if not e["classname"].startswith(("prop_", "light", "env_sprite", "infodecal")) or "brushes" in e:
            return False
        q = F.pf_point(e["origin"], LR_TURN, LR_AT)
        return q[0] < OUT[2] - 4 and "silo_tower" not in e["keys"].get("model", "")

    def edit(e):
        loose(e)
        q = F.pf_point(e["origin"], LR_TURN, LR_AT)
        if ground and q[2] < PAD + 80 and not (TILE26[0] <= q[0] <= TILE26[2] and TILE26[1] <= q[1] <= TILE26[3]):
            g = min(ground, key=lambda c: (c[0] - q[0]) ** 2 + (c[1] - q[1]) ** 2)
            if (g[0] - q[0]) ** 2 + (g[1] - q[1]) ** 2 < 96 ** 2:
                e["origin"] = [e["origin"][0], e["origin"][1], e["origin"][2] + PAD - g[2]]
    F.pf_entities(v, pf, LR_TURN, LR_AT, "lc_pad_", vis, vis, keep=keep, edit=edit, valve_anchor=pf["anchor"])
    # the pad: flat at the collar's top; over the silo's hull from its top floor's ceiling (200, where Valve's silo had its
    # lid); over the corridor's stairs down to the silo only from their roof (328)
    nd, grass, lid = MAT["nodraw"], "nature/blendgrassdirt01", "concrete/concretewall010a"
    ax, ay = SILO
    rects = [OUT]
    for hole in (TILE26, (ax - SQUARE, ay - SQUARE, ax + SQUARE, ay + SQUARE)):
        rects = [r for q in rects for r in cut(q, hole)]
    for r, over_hull in split(rects, SILO_HULL):
        for q, over_stairs in split([r], LOW_GAP):
            v.world_box((q[0], q[1], 328 if over_stairs and not over_hull else 200, q[2], q[3], PAD), nd, top=grass, bottom=lid, vis=vis)
    v.world_box(TILE26[:2] + (200,) + TILE26[2:] + (288,), nd, vis=sv)     # (under Valve's ground kept there: a displaced face seals nothing)
    # the collar's square: our silo's ring (128 to 384 from the axis, up to 200) carried up to the collar (288), out to
    # the square, in 24 pieces as the ring's; round the collar (384) its apron, flush with the collar's top
    ring, apron = "concrete/concretewall073a", "concrete/concretefloor006a"
    for k in range(24):
        a1, a2 = 15 * k, 15 * (k + 1)
        for r_in, z1, z2, inner in ((128, 200, 288, ring), (384, 288, PAD, nd)):
            pin = [(ax + r_in * math.cos(math.radians(a)), ay + r_in * math.sin(math.radians(a))) for a in (a1, a2)]
            pout = [ray_square(ax, ay, a, SQUARE) for a in (a1, a2)]
            poly = [(int(round(x)), int(round(y))) for x, y in (pin[0], pout[0], pout[1], pin[1])]      # (on the grid, as Valve's ring's corners)
            v.world.append(v.convex_text(prism(poly, z1, z2, nd, apron, lid, sides={3: inner}), vis))
    # its sky: walls round OUT (the room's face left open: its window), a lid over the rocket's climb
    sky = MAT["sky"]
    x1, y1, x2, y2 = OUT
    T = HULL
    walls = [(x1 - T, y1 - T, 200, x1, y2 + T, SKY), (x1, y1 - T, 328, x2, y1, SKY), (x1, y2, 328, x2, y2 + T, SKY)]
    for (ya, za, yb, zb) in ((y1 - T, 200, LR_BOX[1], SKY), (LR_BOX[4], 200, y2 + T, SKY), (LR_BOX[1], 200, LR_BOX[4], LR_BOX[2]), (LR_BOX[1], LR_BOX[5], LR_BOX[4], SKY)):
        walls.append((x2, ya, za, x2 + T, yb, zb))
    for b in walls:
        v.world_box(b, sky, sky, sky, vis=sv)
    v.world_box((x1 - T, y1 - T, SKY, x2 + T, y2 + T, SKY + 16), sky, sky, sky, vis=sv)
    # the window's player clip, as Valve's (nobody climbs out onto the pad), and the clerestory's over it
    for b in ((11429, 6088, 408, 11460, 6536, 624), (11456, 6208, 624, 11472, 6416, 688)):
        v.world_box(b, "tools/toolsplayerclip", top="tools/toolsplayerclip", bottom="tools/toolsplayerclip", vis=f.vis("launch room's window clip"), seals=False)
    return [(x1, y1, PAD, x2, y2, SKY), TILE26[:2] + (288,) + TILE26[2:] + (PAD,), (ax - SQUARE, ay - SQUARE, 200, ax + SQUARE, ay + SQUARE, PAD)]


# The launch (Valve's relay_launch in ep2_outland_12a, as Valve times it): the red button starts it, the countdown panels
# run 30 seconds, the hatch over the silo opens at 3, the warnings, rumble, debris and the room's shaking build, and at 30
# the rocket rises on its train out of the shaft past the hatch, Valve's smoke at the hatch as it starts, its engines'
# flame and the blast up the hatch as its foot nears it, its sound to the whole map; at the top of its climb, out of
# sight from the window, it is killed (nothing is left in the silo or the sky). One launch a map: the button and the
# relay lock themselves. Our silo's own rocket (Valve's White Forest rocket, valve_ep2_rocket: its stages, engines, nose
# and hatch) is the one that rises: on the train, not Valve's distant model of it. The ending hooks into LAUNCH_RELAY.
LAUNCH_RELAY = "lc_rocket_launch"
ROCKET_FOOT = -1232                 # the rocket's foot (its engines' bottom) in the silo, and the train's start
# Valve's path above its start (ptrack_1 3 9 6 7 4), its rocket's top 86 into the hatch at the start; ours starts 169
# under it, so each comes 255 later; killed (ptrack_8) when its foot is at 2500, its top at 4130, under the sky (SKY)
PATH = (("ptrack_1", 0), ("ptrack_3", 315), ("ptrack_9", 571), ("ptrack_6", 1451), ("ptrack_7", 1931), ("ptrack_4", 3583), ("ptrack_8", 2500 - ROCKET_FOOT))


def launch(f, F, lr):
    """The launch's wiring (valve_ep2_launch_room's), on our silo's own axis and rocket."""
    v = f.vmf
    vis, wv = f.vis("launch (the rocket, the hatch, the countdown)"), f.vis("launch's wiring")
    rocket = PF.load("valve_ep2_rocket")
    sx, sy, sz = f.silo_at
    dz = sz - LR_AT[2]          # (the rocket piece's frame to the launch piece's: both turned alike round the silo's axis)
    extra = []
    for e in rocket["points"]:
        k = dict(e["keys"])
        if e["classname"] == "env_steam" and k.get("targetname") != "rocket_nose_jet":
            continue
        k.update({"targetname": "rocket", "parentname": "train_rocket"})
        cls = e["classname"]
        if cls.startswith("prop_"):
            cls = "prop_dynamic_override"
            k.update({"solid": "0", "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "StartDisabled": "0", "spawnflags": "0"})
        extra.append({"classname": cls, "origin": [e["origin"][0], e["origin"][1], e["origin"][2] + dz], "keys": k, "ours": True})
    extra.append({"classname": "logic_auto", "origin": [-4, -1908, FLOOR_HIGH + 120 - LR_AT[2]], "keys": {"spawnflags": "1"}, "ours": True,      # (in the launch room)
                  "out": [("OnMapSpawn", "relay.countdown.init", "Trigger", "", 1)]})
    foot = ROCKET_FOOT - LR_AT[2]
    path = dict(PATH)

    def keep(e):
        k, cls = e["keys"], e["classname"]
        tn = k.get("targetname", "")
        if e.get("ours"):
            return True
        if k.get("model", "").endswith("rocket_low.mdl"):
            return False        # (Valve's distant model of its rocket: our silo's own rises instead)
        if cls in ("func_monitor", "logic_auto", "env_microphone", "info_target"):
            return False        # (the screens: the camera's, cctv(); Valve's start-up and story)
        if tn in ("door_launchbunker_exit_a", "brush_launchbunker_exit_a") or (tn.startswith("ptrack_") and tn not in path):
            return False        # (the room's way out stays shut)
        if cls == "func_button":
            return tn == "button_launch" or any("hulla" in c[1] for c in e.get("connections", []))
        if cls.startswith("prop_") or cls in ("light", "light_spot", "env_sprite", "infodecal"):
            return bool(tn)     # (the room's other props: build())
        return True

    def edit(e):
        k, cls = e["keys"], e["classname"]
        tn = k.get("targetname", "")
        loose(e)
        if tn == "train_rocket":        # (our silo's axis, straight up, not turning: the rocket stands as it stands in the silo)
            e["origin"] = [0, 0, foot]
            e["brushes"] = [[{"plane": pl, "verts": [], "corners": [], "material": "TOOLS/TOOLSNODRAW", "uaxis": "[1 0 0 0] 0.25", "vaxis": "[0 -1 0 0] 0.25",
                              "lightmapscale": "16"} for pl in box_planes((-8, -8, foot - 8, 8, 8, foot + 8))]]
            k.update({"orientationtype": "0", "dmg": "0", "spawnflags": str(int(k.get("spawnflags", "0") or 0) | 8)})     # (8: not solid)
        if tn.startswith("ptrack_"):
            e["origin"] = [0, 0, foot + path[tn]]
            order = [n for n, _ in PATH]
            i = order.index(tn)
            k["target"] = order[i + 1] if i + 1 < len(order) else ""
            if not k["target"]:
                del k["target"]
                e["out"] = [o for o in e["out"]] + [("OnPass", "train_rocket", "Kill", "", 0.1)]
        if tn == "particle_rocket":
            e["origin"] = [0, 0, foot]
        if cls == "ambient_generic":
            k["spawnflags"] = str(int(k.get("spawnflags", "0") or 0) & ~1)
        if cls == "env_shake":          # (Valve's shook the whole world; here the room)
            k.update({"spawnflags": str(int(k.get("spawnflags", "0") or 0) & ~1), "radius": "640"})
        if tn == "relay_launch":        # (one launch a map; the ending hooks in here: LAUNCH_RELAY)
            e["out"] = [o for o in e["out"] if o[1] not in ("birds", "logic_start_redlight")] + [
                ("OnTrigger", "!self", "Disable", "", 0.1), ("OnTrigger", "button_launch", "Lock", "", 0)]
    names = F.pf_entities(v, lr, LR_TURN, LR_AT, "lc_launch_", vis, wv, keep=keep, edit=edit, extra=extra, valve_anchor=lr["anchor"])
    # its relay named plainly, for the ending to hook into
    old = "lc_launch_relay_launch"
    for i in range(len(v.ents)):
        if old in v.ents[i]:
            v.ents[i] = v.ents[i].replace('"%s"' % old, '"%s"' % LAUNCH_RELAY).replace(old + "\x1b", LAUNCH_RELAY + "\x1b")
    f.notes.append("the launch: the red button (lc_launch_button_launch) or %s runs Valve's launch: countdown, the silo's doors shut and locked, the "
                   "hatch opening, and at 30 s the silo's rocket rising out of the shaft on lc_launch_train_rocket, its fire killing anyone in the launch "
                   "tube (%s) until it is killed at z 2500, out of sight; one launch a map" % (LAUNCH_RELAY, TUBE_FIRE))
    return names


# The silo during a launch (the owner, 24 November: "can we please also ensure the silo doors close automatically during a
# launch? And anyone inside the silo launch tube during a launch is, when the rocket actually fires and begins to rise, is
# killed? there is no way to survive a hecking rocket launch inside the silo itself", and "(not inside the resistance
# leaders office if the door is shut, or in his bedroom if the door is shut)"). At the countdown the silo's round blast
# door runs its own close (its shove at the close: the door itself still never kills) and the office's lab door shuts;
# both locked (their buttons, the lab door's Use and its lever) until the rocket is gone, then as before. When the rocket
# fires (30 s) the launch tube burns: a trigger_hurt from the hull's floor through the shaft, the pit and the gantry's level
# to the collar's mouth, never the office, the bedroom or the tunnel beyond the blast door (all outside the hull's first
# square), off when the rocket is gone. The owner's own exception to lesson owner-doors-shove-never-kill.
TUBE_FIRE = "lc_launch_tube_fire"
TUBE = ((9248, 5760, -1304, 10336, 6848, 200), (9648, 6160, 200, 9936, 6448, 337))    # (the hull's first square, inside its walls; the mouth over it)
DOORS_SHUT = (("lc_silo_blast_close", "Trigger", 0), ("lc_silo_blast_locked", "SetValue", 0), ("lc_silo_blast_button_corridor", "Lock", 0),
              ("lc_silo_blast_button_silo", "Lock", 0), ("lc_silo_door_silo_lab_outside_1", "Close", 0), ("lc_silo_door_silo_lab_outside_1", "Lock", 0.1),
              ("lc_silo_exit_airlock_blastdoor_lever", "Lock", 0))
DOORS_FREE = (("lc_silo_blast_button_corridor", "Unlock", 1), ("lc_silo_blast_button_silo", "Unlock", 1), ("lc_silo_door_silo_lab_outside_1", "Unlock", 1),
              ("lc_silo_exit_airlock_blastdoor_lever", "Unlock", 1))


def add_outputs(v, name, outs):
    """Outputs added to the entity named name already in the map's text: [(output, target, input, value, delay)]."""
    import map_build
    key = '"targetname" "%s"' % name
    for i, e in enumerate(v.ents):
        if key not in e:
            continue
        block = map_build.Vmf.wires(outs)
        head = "\tconnections\n\t{\n"
        if head in e:
            v.ents[i] = e.replace(head, block[:-len("\t}\n")], 1)
        else:
            v.ents[i] = e.replace(key + "\n", key + "\n" + block, 1)
        return True
    raise ValueError("no entity named %s" % name)


def safety(f):
    """The silo during a launch (after BunkerForest.silo() has placed the silo's doors)."""
    v = f.vmf
    fire = ("trigger_hurt", {"targetname": TUBE_FIRE, "StartDisabled": "1", "spawnflags": "3", "damage": "10000", "damagecap": "20000", "damagetype": "8",
                             "damagemodel": "0", "nodmgforce": "0"})
    v.brush_entity(fire[0], fire[1], list(TUBE), MAT["trigger"], f.vis("launch tube's fire (kills while the rocket burns out of the silo)"))
    add_outputs(v, LAUNCH_RELAY, [("OnTrigger", t, i, "0" if i == "SetValue" else "", d) for t, i, d in DOORS_SHUT]
                + [("OnTrigger", TUBE_FIRE, "Enable", "", 30), ("OnTrigger", TUBE_FIRE, "Disable", "", 45)])
    add_outputs(v, "lc_launch_ptrack_8", [("OnPass", TUBE_FIRE, "Disable", "", 0.5)] + [("OnPass", t, i, "", d) for t, i, d in DOORS_FREE])
    # (a door the wiring shuts sends itself Close again a second after it is blocked: lesson valve-door-retry; the
    #  Close input works on it locked, so locked at once it still shuts the moment the way is clear)
    add_outputs(v, "lc_silo_door_silo_lab_outside_1", [("OnBlockedClosing", "!self", "Close", "", 1)])


# The bunker's camera (the owner, 24 November: "copy the big massive screen ... and use it as CCTV footage of the outside
# of the bunker? A camera mounted on the front of the bunker looking down the path in the forest would be amazing"; then
# "our CCTV instead" on the launch room's screens): Episode Two's own security camera (props_silo/camera.mdl, White
# Forest's) on the east face of the bunker's front by its corner, a point_camera at its lens looking down the path from
# the door, and the launch room's two big screens (Valve's func_monitors, monitor.controlroom2 and 3, that showed Eli's
# camera) showing it. On from the start, nothing to press: the engine draws a camera only for a player who has one of
# its screens in sight (the gamemode draws its own screens to targets of its own, never the engine's camera picture).
CCTV_NAME = "lc_bunker_cctv"
CCTV_PROP = (896, 22, 216)          # (the bunker's own frame: on its front block's east face, 22 north of its front; over the door's floor)
CCTV_EYE = (918, -4, 214, 16, 220)  # (where it looks from, its pitch down and its yaw: down the path from the door)
CCTV_FOV = 60


def cctv(f, F, lr):
    v = f.vmf
    bx, by = f.ox + f.B0[0], f.oy + f.B0[1]
    u, w, z = CCTV_PROP
    v.point("prop_static", (bx + u, by + w, f.zp + z), {"model": "models/props_silo/camera.mdl", "angles": "0 270 0", "solid": "6", "skin": "0",
                                                        "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "screenspacefade": "0"},
            f.vis("bunker's camera"))
    eu, ew, ez, pitch, yaw = CCTV_EYE
    ex, ey, ezz = bx + eu, by + ew, f.zp + ez
    cam = {"classname": "point_camera", "origin": [ey - LR_AT[1], -(ex - LR_AT[0]), ezz - LR_AT[2]], "ours": True,     # (in the launch piece's frame: q 1)
           "keys": {"targetname": "cctv", "angles": "%d %d 0" % (pitch, (yaw - 90 * LR_TURN) % 360), "FOV": str(CCTV_FOV), "UseScreenAspectRatio": "0",
                    "fogEnable": "0", "fogColor": "0 0 0", "fogStart": "2048", "fogEnd": "4096", "fogMaxDensity": "1", "spawnflags": "0"}}

    def keep(e):
        return e.get("ours") or e["keys"].get("targetname") in ("monitor.controlroom2", "monitor.controlroom3")

    def edit(e):
        if e["classname"] == "func_monitor":
            e["keys"].update({"target": "cctv", "StartDisabled": "0", "spawnflags": "2", "disableshadows": "1"})
    F.pf_entities(v, lr, LR_TURN, LR_AT, "lc_launch_", f.vis("launch room's screens"), f.vis("bunker's camera"), keep=keep, edit=edit, extra=[cam],
                  valve_anchor=lr["anchor"])
    for i in range(len(v.ents)):
        if "lc_launch_cctv" in v.ents[i]:
            v.ents[i] = v.ents[i].replace("lc_launch_cctv", CCTV_NAME)
    f.notes.append("the bunker's camera (%s): Episode Two's security camera on the bunker's front at (%d %d %d), looking down the path; shown on the "
                   "launch room's two big screens" % (CCTV_NAME, ex, ey, ezz))


def box_planes(b):
    """A box's six planes as three corners each, wound as Hammer writes them (each face clockwise seen from outside)."""
    x1, y1, z1, x2, y2, z2 = b
    return [[[x1, y2, z2], [x2, y2, z2], [x2, y1, z2]], [[x1, y1, z1], [x2, y1, z1], [x2, y2, z1]],
            [[x1, y2, z2], [x1, y1, z2], [x1, y1, z1]], [[x2, y2, z1], [x2, y1, z1], [x2, y1, z2]],
            [[x2, y2, z2], [x1, y2, z2], [x1, y2, z1]], [[x2, y1, z1], [x1, y1, z1], [x1, y1, z2]]]


def lit_rooms(f):
    """The complex's rooms, as boxes from their floors up 400, for the bunker's check that every room has a light."""
    tb, (sx, sy) = tech_box(), STAIR_AT
    return [("control room", tb[:3] + (tb[3], tb[4], tb[2] + 400)), ("stair to the launch room", (sx - 192, sy, FLOOR_LOW, sx + 192, sy + 576, FLOOR_LOW + 400)),
            ("launch room", LR_BOX[:3] + (LR_BOX[3], LR_BOX[4], LR_BOX[2] + 400))]
