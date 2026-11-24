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
    F.pf_solids(v, lr, LR_TURN, LR_AT, vis, world=True, skip=lambda s: "taken shut" in s["from"] and "monitor" not in s["from"] and "door" not in s["from"])
    # its props, lights and screens as Valve has them (the launch's wiring: launch())
    def in_room(e):
        p = F.pf_point(e["origin"], LR_TURN, LR_AT)
        return all(LR_BOX[k] <= p[k] <= LR_BOX[k + 3] for k in range(3))
    F.pf_entities(v, lr, LR_TURN, LR_AT, "lc_launch_", vis, wv, keep=lambda e: e["classname"].startswith(("prop_", "light", "env_sprite", "infodecal"))
                  and not e["keys"].get("parentname") and "brushes" not in e and in_room(e), edit=loose, valve_anchor=lr["anchor"])
    x1, y1, z1, x2, y2, z2 = LR_BOX
    shell(v, LR_BOX, [("east", (sy + 448, LR_BOX[2] - HULL, sy + 576, FLOOR_HIGH + 128))], hv)
    air.append(LR_BOX)
    places.append(((x1 + x2) / 2.0, (y1 + y2) / 2.0, FLOOR_HIGH + 64, "launch room"))
    f.launch_piece = lr
    # --- their sound: Half-Life 2's own (Valve's ep2_silo ones may not be loaded in Garry's Mod), as the bunker's rooms ---
    sv = f.vis("soundscapes")
    for (x, y, z), name, radius in ((((tb[0] + tb[3]) / 2.0, (tb[1] + tb[4]) / 2.0, FLOOR_LOW + 64), "prison.control_room_simple", 220),
                                    ((sx + 128, sy + 256, FLOOR_LOW + 160), "eli_01_lower_corridor_1", 120),
                                    (((x1 + x2) / 2.0, (y1 + y2) / 2.0, FLOOR_HIGH + 64), "prison.control_room_simple", 220)):
        v.point("env_soundscape", (int(x), int(y), int(z)), {"soundscape": name, "radius": str(radius), "StartDisabled": "0"}, sv)
    return air, places


def lit_rooms(f):
    """The complex's rooms, as boxes from their floors up 400, for the bunker's check that every room has a light."""
    tb, (sx, sy) = tech_box(), STAIR_AT
    return [("control room", tb[:3] + (tb[3], tb[4], tb[2] + 400)), ("stair to the launch room", (sx - 192, sy, FLOOR_LOW, sx + 192, sy + 576, FLOOR_LOW + 400)),
            ("launch room", LR_BOX[:3] + (LR_BOX[3], LR_BOX[4], LR_BOX[2] + 400))]
