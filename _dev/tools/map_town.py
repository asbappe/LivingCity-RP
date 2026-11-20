#!/usr/bin/env python3
"""
Living City: the Resistance's town (run it through map_build.py)

The owner, 20 November: the Resistance's modules "need to be moved to a new area that isn't the canals ...
a small, very small, little abandoned town outside the main city that acts as a sort of main rebel HQ, and
there the Resistance leader would have their office/command and all these little modules could fit in
together into a little town ... the road and the canals both can lead to the little resistance town and be
alternate routes to it." And: "do the town map piece with all the modules plugged into it ... I would
expect it to sit somewhere near the top of the map."

    python3 map_build.py chain --layout map_layouts/town.txt            lc_town.vmf
    python3 map_build.py chain --layout map_layouts/town.txt --test     lc_town_test.vmf, to compile and walk alone
    python3 map_build.py chain --layout map_layouts/town.txt --ascii    ...and a plan of it in letters (free to read)

The town is one street built as the city's own are (read from the owner's map, 20 November: pavements at
z 664 with a kerb, gutters at 648, a cobbled roadway rising to a crown at 656), with a module on each side
of every stretch. Each module is built as it is in the canal, lifted 264: its canal is the street, its left
wall the building line, its floors at the pavement's height. The building line is then dressed as houses of
the city are: lots of different heights, each with a plinth, a ground floor, a string course, upper floors
and a cornice in walls the owner's own streets use, windows in the owner's own glass (laid as theirs),
doors, downpipes, lampposts. A layout whose first line is "ground street" is a town; then each line is

    LEFT | RIGHT        two modules facing each other across the street (the right one is built turned round)
    LEFT                one module, a blank brick front opposite

"landing" is the canal's way in: a real canal gate (the same as every canal piece's), a basin at the
canal's own height on the street's right, and a broad flight of steps from its floor up to a quay on the street. The street's start is the road's
way in: a wall in a visgroup of its own to delete where a road is joined.
"""

from map_build import CELL, GATE_HIGH, MAT, prism

FLATS_DOC = "a house to live in: a front door that opens, a hall, and two flats of a kitchen and a bedroom each (stove, sink, fridge, table, bed)"
HQ_DOC = "the Resistance leader's office: a briefing room and an office behind it (the game puts the flagpole at its door)"

# What the owner's own streets are made of (counted in their map), and how their windows are laid.
R = {"road": "stone/stonefloor006d_c17", "strip": "stone/stonefloor006f_c17", "walk": "concrete/concretefloor016a", "kerb": "concrete/concretefloor039b",
     "plinth": "concrete/concretewall002c", "trim": "stone/stonewall050f", "frame": "wood/woodbeam001a"}
STYLES = (   # a house's ground floor and its upper floors: the commonest walls of the owner's own streets
    ("brick/brickwall053e", "concrete/concretewall074c"), ("plaster/plasterwall047b", "plaster/plasterwall042c"), ("brick/brickwall037a", "brick/brickwall037c"),
    ("concrete/concretewall059e", "concrete/concretewall055b"), ("brick/brickwall045d", "brick/brickwall040c"), ("stone/stonewall040f", "plaster/plasterwall046b"),
    ("brick/brickwall014l", "brick/brickwall017b"), ("concrete/concretewall037a", "brick/brickwall040b"),
)
GLASS = {   # kind: (material, wide, high, the texture's scale across and down, the sheet's pixel at the pane's edge and at its top).
            # Each is a fit read from the owner's own map (how many faces there are laid exactly so): never a guess.
    "sash":  ("glass/glasswindow010a", 64, 96, 0.25, 0.25, 0, 128),                                             # 9 faces
    "panes": ("glass/glasswindow042a", 56, 88, 0.4375, 88 / 224.0, 1, 32),                                      # 20
    "tall":  ("building_template/building_trainstation_window001a", 72, 88, 72 / 256.0, 88 / 512.0, 0, 0),      # 2 (the whole sheet)
    "small": ("glass/glasswindow007a", 32, 48, 0.25, 0.25, 320, 224),                                           # 12
    "shop":  ("glass/glasswindow041a", 152, 64, 152 / 256.0, 0.5, 0, 384),                                      # 4
    "front": ("glass/glasswindow015a", 152, 64, 152 / 256.0, 0.25, 0, 0),                                       # 4 (the whole sheet)
}
UPPER = ("sash", "panes", "tall", "small")
HEIGHTS = (312, 376, 440)           # a house's cornice over the pavement
DOOR = "models/props_c17/door01_left.mdl"
PIPE = "models/props_pipes/gutter_256_001a.mdl"
BOARD = "models/props_debris/wood_board05a.mdl"
POST = "models/props_c17/lamppost03a_on.mdl"
RAIL = "models/props_c17/handrail04_long.mdl"


def m_hq(m, opt):
    """The Resistance leader's office. A doorway in the left wall into a briefing room (a long table and benches, a
    cork board, a lamp), and behind a partition the leader's own office: a desk and chair, a filing cabinet, a steel
    closet, a bed. The flagpole is the game's own: it stands it at lc_hq_setup, by the door.
    Named for the game: lc_hq_setup (the doorstep: where the pole goes and the leader stands to set the headquarters
    up), lc_hq_desk, lc_hq_table, lc_hq_map.
    Unchecked: which way the cork board, the closet and the bed face."""
    from map_modules import F, MM
    wood = MM["wood"]
    m.open(0, -256, 768, 256)
    m.low(320, 256, 448, 320, F + 128)                       # the doorway
    m.low(128, 320, 640, 704, F + 176)                       # the briefing room
    m.low(384, 704, 640, 960, F + 160)                       # the office
    m.side(128, 256, 640, 960)
    m.portal(320, 286, F, 448, 288, F + 128)
    m.det([(308, 244, F, 320, 256, F + 140), (448, 244, F, 460, 256, F + 140), (308, 244, F + 128, 460, 256, F + 140)], MAT["beam"])
    m.taken(300, 232, F, 468, 256, F + 148)
    m.det([(384, 696, F, 472, 704, F + 160), (552, 696, F, 640, 704, F + 160), (472, 696, F + 112, 552, 704, F + 160)], wood)    # the partition, with its door gap
    # the briefing room
    m.static("models/props_wasteland/cafeteria_table001a.mdl", 384, 512, 90)
    m.static("models/props_wasteland/cafeteria_bench001a.mdl", 384, 462, 90)
    m.static("models/props_wasteland/cafeteria_bench001a.mdl", 384, 562, 90)
    m.blocked(310, 440, 460, 590)
    m.static("models/props_lab/corkboard001.mdl", 128, 480, 0, F + 48)                    # the map board, on the end wall
    m.decal("decals/decalposter014a", 129, 600, F + 96)
    m.target("lc_hq_map", 180, 480, F + 8, 180)
    m.target("lc_hq_table", 384, 512, F + 36)
    m.lamp(384, 512, F + 150, "255 205 150 55", hang=18)
    m.static("models/props_junk/wood_crate001a.mdl", 600, 360, 20)
    m.static("models/props_c17/lockers001a.mdl", 628, 600, 180)
    # the office
    m.static("models/props_wasteland/controlroom_desk001a.mdl", 512, 860, 90)
    m.static("models/props_wasteland/controlroom_chair001a.mdl", 512, 910, 270)
    m.static("models/props_wasteland/controlroom_filecabinet002a.mdl", 620, 930, 180)
    m.static("models/props_wasteland/controlroom_storagecloset001a.mdl", 412, 934, 270)   # the steel closet
    m.static("models/props_c17/furniturebed001a.mdl", 412, 764, 90)                       # a bed
    m.target("lc_hq_desk", 512, 880, F + 36, 270)
    m.lamp(512, 830, F + 134, "255 200 140 40", hang=18)
    m.blocked(440, 820, 590, 940)
    m.target("lc_hq_setup", 500, 200, F + 8, 270)
    for u, v in ((384, 290), (240, 400), (560, 640), (512, 760)):
        m.lane(u, v)
    m.view(384, 60, F, 90, 0, "the door")


def m_flats(m, opt):
    """A house people can live in, as the flats of the owner's city are furnished (their stoves, sinks, fridges and beds
    stand backs to the wall: so do these). A front door that opens (the city's own door, with its handle) into a hall;
    off it two flats, each behind its own door: a kitchen (stove, sink, fridge, a table and chairs, a radiator, a
    window on the street) and through an archway a bedroom (a bed, a dresser, a bedside drawer). The left flat has
    the city's iron bed, the right one a wooden bed and mattress, a couch and a fireplace.
    Named for the game: lc_flat_door (the front door), lc_flat_1 and lc_flat_2 (info_targets in the two kitchens). A
    second house in one chain takes a word after its name in the layout ("flats b"): lc_flat_b_door, lc_flat_b_1 ...
    Unchecked: which way the doors' leaves swing clear; the mattress's height on its frame."""
    from map_modules import F
    H, D = F + 128, F + 112
    nm = "lc_flat_" + "".join(w + "_" for w in opt[:1] if w.isalnum() and w != "flip")
    m.open(0, -256, 768, 256)
    m.low(320, 256, 384, 320, D)                             # the front doorway
    m.low(320, 320, 448, 896, H)                             # the hall
    m.low(64, 320, 256, 576, H)                              # flat 1: kitchen, bedroom
    m.low(64, 640, 256, 896, H)
    m.low(512, 320, 704, 576, H)                             # flat 2
    m.low(512, 640, 704, 896, H)
    m.low(256, 384, 320, 448, D)                             # the flats' doorways off the hall
    m.low(448, 384, 512, 448, D)
    m.low(128, 576, 192, 640, D)                             # the archways to the bedrooms
    m.low(576, 576, 640, 640, D)
    m.side(64, 256, 704, 896)
    m.portal(320, 286, F, 384, 288, D)
    m.taken(308, 232, F, 396, 256, F + 124)
    fr = R["frame"]
    m.det([(320, 280, F, 328, 296, D), (376, 280, F, 384, 296, D), (328, 280, F + 108, 376, 296, D)], fr)
    real_door(m, 328, 288, 270, F, nm + "door")
    for u, hinge, yaw in ((288, 392, 0), (480, 440, 180)):
        m.det([(u - 8, 384, F, u + 8, 392, D), (u - 8, 440, F, u + 8, 448, D), (u - 8, 392, F + 108, u + 8, 440, D)], fr)
        real_door(m, u, hinge, yaw, F)
    for u in (128, 576):
        m.det([(u, 604, F + 104, u + 64, 612, D)], fr)
    lamp = "255 214 170 45"
    m.lamp(384, 600, H - 8, lamp)
    m.static("models/props_c17/furnitureradiator001a.mdl", 384, 888, 270)
    for n, (wall, yaw, far) in enumerate(((64, 0, 1), (704, 180, -1))):        # each flat: its outer wall, the way its things face, and which way is in
        mid = wall + far * 96
        m.static("models/props_c17/furniturestove001a.mdl", wall + far * 19, 420, yaw)
        m.static("models/props_c17/furnituresink001a.mdl", wall + far * 12, 484, yaw)
        m.static("models/props_interiors/refrigerator01a.mdl", wall + far * 17, 540, yaw)
        m.static("models/props_c17/furnituretable00%da.mdl" % (n + 1), mid + far * 30, 500, 90 * n)
        m.static("models/props_c17/furniturechair001a.mdl", mid + far * 30, 452, 90)
        m.static("models/props_c17/furniturechair001a.mdl", mid + far * 68, 506, 180 if far > 0 else 0)
        m.static("models/props_c17/furnitureradiator001a.mdl", mid - far * 40, 327, 90)
        glass_pane(m, mid - 32, mid + 32, F + 40, F + 136, "sash", v=320)     # the kitchen's window, from inside
        m.det([(mid - 36, 320, F + 35, mid + 36, 326, F + 40)], R["trim"])
        m.lamp(mid, 448, H - 8, lamp)
        m.lamp(mid, 768, H - 8, "255 205 160 35")
        m.target(nm + str(n + 1), mid, 448, F + 8, 90)
        m.static("models/props_c17/furnituredresser001a.mdl", mid + far * 40, 877, 270)
        m.static("models/props_c17/furnituredrawer002a.mdl", wall + far * 11, 730, yaw)
        for u, v in ((mid, 448), (mid, 608), (mid, 768)):
            m.lane(u, v)
    m.static("models/props_wasteland/prison_metalbed001a.mdl", 75, 810, 0)                  # flat 1's bed, as the city's flats have
    m.static("models/props_c17/furniturebed001a.mdl", 681, 810, 90)                         # flat 2's
    m.static("models/props_c17/furnituremattress001a.mdl", 681, 810, 90, F + 20)
    m.static("models/props_c17/furniturecouch002a.mdl", 529, 530, 0)
    m.static("models/props_c17/furniturefireplace001a.mdl", 560, 560, 270)
    m.blocked(64, 380, 110, 576)
    m.blocked(660, 380, 704, 576)
    for u, v in ((352, 290), (384, 416), (288, 416), (480, 416)):
        m.lane(u, v)
    m.view(352, 80, F, 90, 0, "the front door")
    m.view(230, 540, F, 215, 4, "flat 1's kitchen")


def town_plan(b, walk):
    """The town's squares: the street's own plan, but each house as high as its lot says (tops: (x1, y1, x2, y2, top))."""
    import map_corridor as mc
    from map_build import Plan
    from map_modules import BASE

    class TownPlan(mc.CorridorPlan):
        def top_of(self, c):
            x, y = c[0] * CELL + 32, c[1] * CELL + 32
            for x1, y1, x2, y2, top in self.tops:
                if x1 <= x < x2 and y1 <= y < y2:
                    return top
            return self.walk + HEIGHTS[0]

        def walls(self):
            if self.walled:
                return
            Plan.walls(self)
            for c, spec in list(self.cells.items()):
                x, y = c[0] * CELL + 32, c[1] * CELL + 32
                quay = any(x1 <= x < x2 and y1 <= y < y2 for x1, y1, x2, y2 in self.canal)      # (round the basin: a canal's wall and its fence, no house)
                top = self.rim if quay else self.top_of(c)
                if spec[0] == "solid":
                    self.cells[c] = ("solid", top, not quay)
                elif spec[0] == "low" and len(spec) == 4:
                    self.cells[c] = spec + (max(top, spec[3]), not quay)

    plan = TownPlan(BASE, b.rim, b.sky, b.vis + ": walls and floors")
    plan.tops, plan.canal, plan.walk = [], [], walk
    return plan


def lay_street(b, m, L):
    """The street between the building lines (v -256 to 256), as the owner's own: a pavement 96 wide each side with a
    kerb, a gutter 8 under it (the owner, of 16: "sidewalks are not 2 feet tall irl, they are like 6-12 inches"), and
    cobbles rising over 64 to a flat crown 4 over the gutter. Call it AFTER the
    stretch's modules are painted: they paint their canal flat, and this lays the street's profile over it."""
    from map_modules import F, MM
    fr, cells = m.fr, m.b.plan.cells
    flat = ("open", F + fr.dz, MM["road"])

    def put(v1, v2, spec):
        r = fr.rect(0, v1, L, v2)
        for i in range(r[0] // CELL, r[2] // CELL):
            for j in range(r[1] // CELL, r[3] // CELL):
                if cells.get((i, j)) != flat and ("street", (i, j)) not in m.b.names:
                    m.b.names.append(("street", (i, j)))
                    m.b.problems.append("%s: a module paints the street itself at (%d %d): the town's roadway cannot be laid there" % (m.tag, i * CELL, j * CELL))
                cells[(i, j)] = spec
    walk, gut, crown = F + fr.dz, F + fr.dz - 8, F + fr.dz - 4
    for s in (-1, 1):
        put(min(s * 192, s * 256), max(s * 192, s * 256), ("open", walk, R["walk"]))
        put(min(s * 64, s * 192), max(s * 64, s * 192), ("open", gut, R["strip"]))
    put(-64, 64, ("open", crown, R["road"]))
    for s in (-1, 1):
        m.det([(0, min(s * 160, s * 168), F - 8, L, max(s * 160, s * 168), F)], R["kerb"])
        m.det([(0, min(s * 168, s * 192), F - 8, L, max(s * 168, s * 192), F)], R["walk"])
        m.det([(0, min(s * 64, s * 96), F - 8, L, max(s * 64, s * 96), F - 4)], R["road"])
        m.shapes([prism([(s * 160, F - 8), (s * 96, F - 4), (s * 96, F - 8)], "x", 0, L, R["strip"])])


def glass_pane(m, u1, u2, z1, z2, kind, v=255):
    """A window's glass, a sheet 1 thick standing on v, the owner's glass laid exactly as theirs is (GLASS)."""
    mat, wide, high, su, sv, pu, pv = GLASS[kind]
    x1, y1, a, x2, y2, c = m.fr.box(u1, v, z1, u2, v + 1, z2)
    vs = "[0 0 -1 %.3f] %g" % ((pv + c / sv) % 4096, sv)
    if x2 - x1 == 1:
        us, names = "[0 1 0 %.3f] %g" % ((pu - y1 / su) % 4096, su), ("east", "west")
    else:
        us, names = "[1 0 0 %.3f] %g" % ((pu - x1 / su) % 4096, su), ("north", "south")
    m.b.vmf.brush_entity("func_detail", {}, [((x1, y1, a, x2, y2, c), dict((n, mat) for n in names), dict((n, (us, vs)) for n in names))], R["frame"], m.dv)


def board(m, u, v, z, yaw, roll):
    """A plank nailed across (z: its middle). The model is a physics prop, so it is a prop_dynamic_override: as a
    prop_static the compiler deletes it (the owner's compile, 20 November)."""
    m.point("prop_dynamic_override", u, v, z, {"model": BOARD, "angles": "0 %d %d" % (m.fr.yaw(yaw), roll), "skin": "0", "solid": "0", "disableshadows": "1",
                                               "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"}, m.pv)


def real_door(m, u, v, yaw, z, name=None, skin=7):
    """One of the city's own doors, that opens: a prop_door_rotating set up as the owner's 134 are (a handle, opens 90
    either way). Its hinge at (u, v) on the floor z; the leaf reaches 47 to the left of yaw."""
    k = {"model": DOOR, "angles": "0 %d 0" % m.fr.yaw(yaw), "hardware": "1", "skin": str(skin), "spawnflags": "8192", "distance": "90", "speed": "100", "returndelay": "-1",
         "opendir": "0", "ajarangles": "0 0 0", "dmg": "0", "forceclosed": "0", "health": "0", "spawnpos": "0", "rendercolor": "255 255 255", "fademindist": "-1", "fadescale": "1"}
    if name:
        k["targetname"] = name
        m.b.names.append((name, "prop_door_rotating", m.tag))
    m.b.vmf.point("prop_door_rotating", m.fr.at(u, v, z + 54), k, m.pv)


def facade(b, fr, L, rnd, tag, first=0):
    """Dress the frame's left wall (v 256, u 0 to L) as a row of houses. Where a module has a doorway the wall is dressed
    above it; where it has open ground (a yard) there is no wall to dress. Returns how many lots it made."""
    from map_modules import F, Mod
    m = Mod(b, fr, tag)
    cells, walk = b.plan.cells, F + fr.dz
    cols = []        # each 64 of the wall: None (no wall here), or how far over the pavement the wall starts (0: all of it)
    for k in range(L // CELL):
        x, y = fr.pt(k * CELL + 32, 288)
        spec = cells.get((x // CELL, y // CELL))
        cols.append(0 if spec is None else (max(0, spec[3] - walk) if spec[0] == "low" else None))
    n = len(cols)

    def whole(k):
        return 0 <= k < n and cols[k] == 0
    cuts = [0]
    while L - cuts[-1] > 448:
        c = cuts[-1] + rnd.choice((256, 320, 384))
        for d in (0, 64, -64, 128):      # (a house never ends in the middle of a way in)
            k = (c + d) // CELL
            if whole(k - 1) and whole(k) and c + d - cuts[-1] >= 192 and L - (c + d) >= 192:
                c = c + d
                break
        else:
            break
        cuts.append(c)
    cuts.append(L)
    lots, state = [], {}
    for i in range(len(cuts) - 1):
        high = rnd.choice([h for h in HEIGHTS if not lots or h != lots[-1][2]])
        lots.append((cuts[i], cuts[i + 1], high, STYLES[(first + i * 3 + rnd.randrange(2)) % len(STYLES)]))
        b.plan.tops.append(fr.rect(cuts[i], 256, cuts[i + 1], 256 + 2048) + (walk + high,))

    def band(a, c, z1, z2, out, mat, holes=()):
        k = a // CELL
        while k < c // CELL:
            lo = None if cols[k] is None else max(cols[k], z1)
            j = k
            while j < c // CELL and (None if cols[j] is None else max(cols[j], z1)) == lo:
                j += 1
            if lo is not None and lo < z2:
                boxes, at = [], k * CELL
                for h1, h2, s, t in sorted(h for h in holes if k * CELL <= h[0] and h[1] <= j * CELL):
                    if h1 > at:
                        boxes.append((at, lo, h1, z2))
                    if s > lo:
                        boxes.append((h1, lo, h2, s))
                    if t < z2:
                        boxes.append((h1, t, h2, z2))
                    at = h2
                if at < j * CELL:
                    boxes.append((at, lo, j * CELL, z2))
                m.det([(u1, 256 - out, F + za, u2, 256, F + zb) for u1, za, u2, zb in boxes], mat)
            k = j

    def clear(u1, u2, z, z2=None):
        """Is the wall whole from u1 to u2 at this height, and (to z2) free of what a module has hung on it (its `taken`)?"""
        if not all(0 <= k < n and cols[k] is not None and cols[k] <= z for k in range(u1 // CELL, (u2 - 1) // CELL + 1)):
            return False
        if z2 is not None:
            x1, y1, a, x2, y2, c = fr.box(u1, 224, F + z, u2, 264, F + z2)
            if any(x1 < t[3] and t[0] < x2 and y1 < t[4] and t[1] < y2 and a < t[5] and t[2] < c for t in b.taken):
                return False
        return True

    for a, c, high, (ground, upper) in lots:
        bays = (c - a) // 128
        left = a + ((c - a) - bays * 128) // 2
        mids = [left + 64 + 128 * i for i in range(bays)]
        kind = rnd.choice([k for k in UPPER if k != state.get("kind")])      # each house its own glass, never its neighbour's
        state["kind"] = kind
        shop = rnd.choice(("shop", "front")) if rnd.random() < 0.45 else None
        ww, wh = GLASS[kind][1], GLASS[kind][2]
        rows = [172, 300] if high >= 420 else [192 if high >= 370 else 172]
        low_holes, glass, door_done, i = [], {}, False, 0
        while i < len(mids):                                 # the ground floor: a shop's window, a window, a door boarded shut, or a blank bay
            u = mids[i]
            i += 1
            if not clear(u - 64, u + 64, 0, 140):
                continue
            pick = rnd.random()
            if shop and i < len(mids) and pick < 0.7 and clear(u + 64, u + 192, 0, 140):
                i += 1
                low_holes.append((u + 64 - 76, u + 64 + 76, 44, 108))
                glass[low_holes[-1]] = shop
            elif pick < 0.2 and not door_done:
                door_done = True
                low_holes.append((u - 24, u + 24, 0, 108))
            elif pick < 0.85:
                low_holes.append((u - ww // 2, u + ww // 2, 36 + (96 - wh) // 2, 36 + (96 - wh) // 2 + wh))
                glass[low_holes[-1]] = kind
        up_holes = []
        for s in rows:
            s += (96 - wh) // 2
            up_holes.append([(u - ww // 2, u + ww // 2, s, s + wh) for u in mids if clear(u - 40, u + 40, s - 8, s + wh + 8)])
            for h in up_holes[-1]:
                glass[h] = kind
        band(a, c, 0, 24, 9, R["plinth"], [h for h in low_holes if h[2] == 0])
        band(a, c, 24, 136, 6, ground, low_holes)
        band(a, c, 136, 152, 10, R["trim"])
        if len(rows) == 2:
            band(a, c, 152, 284, 6, upper, up_holes[0])
            band(a, c, 284, high - 28, 6, upper, up_holes[1])
        else:
            band(a, c, 152, high - 28, 6, upper, up_holes[0])
        band(a, c, high - 28, high - 12, 11, R["trim"])
        band(a, c, high - 12, high, 16, R["trim"])
        for h1, h2, s, t in low_holes + up_holes[0] + (up_holes[1] if len(rows) == 2 else []):
            if s == 0:      # a doorway nobody uses: planked over and boards nailed across (never the city's door: that one opens)
                m.det([(h1 - 5, 245, F, h1, 256, F + 113), (h2, 245, F, h2 + 5, 256, F + 113), (h1 - 5, 245, F + 108, h2 + 5, 256, F + 113)], R["frame"])
                m.det([(h1, 253, F, h2, 256, F + 108)], R["frame"])
                for z in (34, 74):
                    board(m, (h1 + h2) // 2 + rnd.randrange(-4, 5), 248, F + z + rnd.randrange(-5, 6), 270, 90 + rnd.randrange(-12, 13))
                continue
            glass_pane(m, h1, h2, F + s, F + t, glass[(h1, h2, s, t)])
            m.det([(h1 - 5, 244, F + s - 5, h2 + 5, 256, F + s)], R["trim"])                     # the sill
            m.det([(h1 - 4, 247, F + t, h2 + 4, 256, F + t + 7)], R["trim"])                     # the lintel
            if s < 100 and h2 - h1 < 100 and rnd.random() < 0.2:                                   # a ground floor window boarded up
                for z in (s + (t - s) // 3, s + 2 * (t - s) // 3):
                    board(m, (h1 + h2) // 2 + rnd.randrange(-6, 7), 248, F + z, 270, 90 + rnd.randrange(-7, 8))
    for i, e in enumerate(cuts):                             # between the houses: a pilaster, and here and there a downpipe
        if (e == 0 or whole(e // CELL - 1)) and (e == L or whole(e // CELL)):
            near = [lot[2] for lot in lots if lot[0] == e or lot[1] == e]
            top = min(near) - 28
            m.det([(max(e - 8, 0), 245, F, min(e + 8, L), 256, F + top)], R["trim"])
            if 0 < e < L and i % 2 == 1:
                m.static(PIPE, e + 16, 247, 0, F + top - 256)
                if top > 300:
                    m.static(PIPE, e + 16, 247, 0, F)
    return len(lots)


def terrace_slopes(b, fr, L, sign, m):
    """Where a module has open ground a little higher than the street beside its wall (a terrace: in the canal the bank
    was its ramp), steps up to it along the pavement's back: 16 high and 24 deep, a landing at the top to step off
    sideways, and the city's handrail along the rest of the drop (the owner: "the playground needs stairs to get up
    the slope"). A terrace too short for that keeps a slope. sign: +1 for the frame's left wall, -1 for its right."""
    from map_modules import F
    cells, street = b.plan.cells, F + fr.dz
    lo, hi = min(sign * 192, sign * 256), max(sign * 192, sign * 256)
    start, was = None, 0
    for u in list(range(0, L, CELL)) + [L]:
        h = 0
        if u < L:
            x, y = fr.pt(u + 32, sign * 288)
            spec = cells.get((x // CELL, y // CELL))
            if spec and spec[0] == "open" and street < spec[1] <= street + 128:
                h = spec[1] - street
        if h != was:
            if was > 16:      # (16 or less is a step anyone takes)
                n = -(-was // 16)
                if u - start >= 24 * n + 64:
                    boxes = [(start + 24 * i, lo, F, start + 24 * (i + 1), hi, F + was * (i + 1) // n) for i in range(n)]
                    boxes.append((start + 24 * n, lo, F, start + 24 * n + 64, hi, F + was))
                    m.det(boxes, MAT["canal_wall"], top=MAT["stairs"])
                    m.blocked(start, lo, start + 24 * n + 64, hi)
                    m.lane(start + 12 * n, sign * 224, F + was // 2)
                    m.lane(start + 24 * n + 32, sign * 224, F + was)
                    for ru in range(start + 24 * n + 128, u - 63, 128):
                        m.static(RAIL, ru, sign * 258, 90, F + was)
                    b.notes.append("%s: steps up to its terrace (%d high) from the pavement at u %d" % (m.tag, was, start))
                else:
                    m.shapes([prism([(sign * 256, F - 8), (sign * (248 - was), F - 8), (sign * 256, F + was)], "x", start, u, MAT["canal_wall"])])
            start, was = u, h


def landing(b, x, y, rot, L, tag, dz):
    """The canal's way into the town: on the street's right a basin at the canal's own height, entered through a
    standard canal gate facing back the way the street came. A flight of 17 steps 192 wide (about 16 high, 24 deep)
    climbs from the basin's floor straight up to a quay on the street, between two sloping side walls; the quay's edge
    has the city's handrail, and the basin's other walls end as a canal's do, with the fence along their tops."""
    from map_modules import F, Frame, Mod, m_gate
    up = Mod(b, Frame(x, y, rot, L, dz=dz), tag)             # (the street's height)
    low = Mod(b, Frame(x, y, rot, L), tag + " (the canal)")  # (the canal's height)
    up.open(0, -448, L, -256, mat=R["walk"])                 # the quay: the pavement widened toward the basin
    gf = Frame(*(Frame(x, y, rot, L).pt(0, -704) + (rot, 256)))
    m_gate(Mod(b, gf, tag + " (the canal gate)"), ["canal"])
    low.open(256, -1088, 896, -448)                          # the basin
    low.side(0, -1088, 896, -448)
    b.plan.canal.append(Frame(x, y, rot, L).rect(-128, -1344, L, -448))      # (round it a canal's own wall with its fence, not houses)
    steps, tread = 17, 24                                    # (the owner, of 33 steps of 8: "meant for toddlers ... fewer and larger")
    foot = -448 - tread * steps
    low.det([(512, foot + tread * i, F, 704, foot + tread * (i + 1), F + (dz * (i + 1) + steps // 2) // steps) for i in range(steps)], MAT["canal_wall"], top=MAT["stairs"])
    for u in (504, 704):
        low.shapes([prism([(foot, F), (-448, F + dz), (-448, F + dz + 40), (foot, F + 40)], "x", u, u + 8, MAT["beam"])])
    low.no_bank(488, -456, 728, -440)
    low.blocked(504, foot, 712, -448)
    low.taken(496, foot, F, 720, -448, F + dz + 40)
    for u in (320, 448, 768, 832):                           # the handrail along the quay's edge, open at the steps' head
        up.static(RAIL, u, -445, 90, F)
    up.static(POST, 608, -280, 180, F)
    up.light(608, -380, F + 400, "255 214 170 380")
    low.static("models/props_canal/boat001a.mdl", 400, -960, 100)
    low.blocked(300, -1040, 500, -880)
    up.target("lc_town_landing", 608, -400, F + 8, 90)
    low.lane(608, foot - 48, F)
    low.lane(608, (foot - 448) // 2, F + dz // 2)
    up.lane(608, -400, F)
    low.lane(400, -704, F)
    low.view(380, -760, F, 20, -8, "the basin and the steps")
    b.notes.append("%s: the canal's gate is at (%d %d), 512 wide, floor z %d, facing back along the street" % ((tag,) + gf.pt(0, 0) + (F,)))


def build(lay, args):
    """A layout that says "ground street": the town. Gives what build_chain gives."""
    import random
    import map_corridor as mc
    from map_modules import F, HEADINGS, MODULES, Build, Frame, Mod
    dz = mc.STREET + 8 - F                                   # (floors and pavements 8 over the road's crown, as the city's)
    b = Build(lay["name"], lay["rim"], args.first_node or 7000, "left")
    b.plan = town_plan(b, F + dz)
    b.test = bool(args.test)
    x, y = lay["start"]
    rot = HEADINGS[lay["heading"]]
    rnd = random.Random(17)
    # the road's way in: the street's first 64, and across its start a wall to delete where a road is joined
    fr = Frame(x, y, rot, 64, dz=dz)
    m = Mod(b, fr, "the road's end")
    m.open(0, -256, 64, 256)
    lay_street(b, m, 64)
    m.world((0, -256, BASE_UNDER(b, dz), 16, 256, b.sky + 16 - dz), "brick/brickwall045d", vis="%s: the town's road end (delete to join a road)" % b.vis)
    b.plan.keep_out.append(fr.rect(-64, -256, 0, 256))
    seed = fr.at(40, 0, F + 32)
    spawn = (fr.at(48, 0, F + 16), fr.yaw(0))
    b.notes.append("the road's end is at (%d %d), 512 wide: the roadway's crown at z %d, gutters %d, pavements %d" % (fr.pt(0, 0) + (F + dz - 4, F + dz - 8, F + dz)))
    x, y = Frame(x, y, rot, 64).pt(64, 0)
    fronts = []
    for n, words in enumerate(lay["modules"]):
        line = " ".join(words)
        left, _, right = [p.split() for p in line.partition("|")]
        sides = [(left, False), (right, True)]
        lengths = [1024 if w and w[0] == "landing" else MODULES[w[0]][0] for w, _ in sides if w and (w[0] == "landing" or w[0] in MODULES)]
        for w, _ in sides:
            if w and w[0] != "landing" and w[0] not in MODULES:
                b.problems.append("the layout names a module that does not exist: %s" % w[0])
        if not lengths:
            continue
        L = max(lengths)
        street = Mod(b, Frame(x, y, rot, L, dz=dz), "the street")
        street.open(0, -256, L, 256)
        for w, flip in sides:
            if w and w[0] == "landing":
                landing(b, x, y, rot, L, "%d landing" % (n + 1), dz)
                continue
            fronts.append((Frame(x, y, rot, L, flip, dz=dz), L, "the houses, stretch %d %s" % (n + 1, "right" if flip else "left")))
            if not w or w[0] not in MODULES:
                continue
            tag = "%d %s" % (n + 1, w[0])
            length = MODULES[w[0]][0]
            mf = Frame(x, y, rot, length, flip, dz=dz)
            mod = Mod(b, mf, tag)
            MODULES[w[0]][1](mod, w[1:])
            terrace_slopes(b, mf, length, 1, mod)
            b.labels.append(mf.pt(length // 2, 300) + (w[0],))
        lay_street(b, street, L)
        # the street itself: left abandoned
        if rnd.random() < 0.6:
            street.static("models/props_vehicles/car00%da_physics.mdl" % rnd.choice((2, 4, 5)), rnd.randrange(200, L - 200), rnd.randrange(-40, 40), rnd.randrange(0, 360, 15), F - 4)
        street.scatter(100, -80, L - 100, 80, 2, 300 + n, z=F - 4)
        side = 1 if n % 2 == 0 else -1                       # a lamppost on one pavement, its arm over the road
        px, py = street.fr.pt(L // 2, side * 224)            # (never beside a terrace's steps: they leave the pavement too narrow)
        if any(k[0] - 48 <= px <= k[2] + 48 and k[1] - 48 <= py <= k[3] + 48 for k in b.blocked):
            side = -side
        street.static(POST, L // 2, side * 176, 180 if side > 0 else 0, F)
        street.light(L // 2, side * 80, F + 400, "255 214 170 380")
        street.blocked(L // 2 - 16, min(side * 160, side * 192), L // 2 + 16, max(side * 160, side * 192))
        street.cubemap(L // 2, 0)
        if n % 2 == 0:
            street.view(60, 0, F - 4, 0, 2, "stretch %d, along the street" % (n + 1))
        for u in range(128, L, 256):
            street.lane(u, 0, F - 4)
        x, y = Frame(x, y, rot, L).pt(L, 0)
    # the houses' fronts, once every module is in; and the house that closes the street's far end
    fronts.append((Frame(*(Frame(x, y, rot, 0).pt(-256, 256) + ((rot - 1) % 4, 512)), dz=dz), 512, "the house at the street's end"))
    made = 0
    for fr, L, tag in fronts:
        made += facade(b, fr, L, rnd, tag, made)
    b.notes.append("%d houses along the street" % made)
    cells = b.plan.cells
    b.lifted = set(c for c, spec in cells.items() if spec[0] != "solid" and spec[1] >= F + dz - 16)
    return b, seed, spawn, (x, y, "ENWS"[rot])


def BASE_UNDER(b, dz):
    """The bottom of everything, in a lifted module's own heights."""
    return b.plan.base - dz


def ascii_plan(b):
    """The plan in letters, north up, one letter for 128 by 128: free to read, where a picture is not.
    # wall   . the street (roadway and pavements)   ~ the canal's floor   o a roofed room   : open ground above the street   _ open ground below it"""
    from map_modules import F
    cells = b.plan.cells
    b.plan.walls()
    xs, ys = [c[0] for c in cells], [c[1] for c in cells]
    street = b.plan.walk
    out = []
    for j in range(max(ys) // 2 * 2 + 1, min(ys) // 2 * 2 - 1, -2):
        row = ""
        for i in range(min(xs) // 2 * 2, max(xs) + 2, 2):
            seen = [cells.get((i + a, j - c)) for a in (0, 1) for c in (0, 1)]
            kinds = set()
            for spec in seen:
                if spec is None:
                    kinds.add(" ")
                elif spec[0] == "solid":
                    kinds.add("#")
                elif spec[0] in ("low", "under"):
                    kinds.add("o")
                elif street - 16 <= spec[1] <= street:
                    kinds.add(".")
                elif spec[1] == F:
                    kinds.add("~")
                else:
                    kinds.add(":" if spec[1] > street else "_")
            row += next(k for k in "o:_~.# " if k in kinds)
        out.append(row.rstrip())
    return "\n".join(out)


MODULES = {"hq": (768, m_hq, HQ_DOC), "flats": (768, m_flats, FLATS_DOC)}
