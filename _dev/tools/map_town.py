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

HQ_DOC = "the Resistance leader's office: a briefing room and an office behind it (the game puts the flagpole at its door)"

# What the owner's own streets are made of (counted in their map), and how their windows are laid.
R = {"road": "stone/stonefloor006d_c17", "strip": "stone/stonefloor006f_c17", "walk": "concrete/concretefloor016a", "kerb": "concrete/concretefloor039b",
     "plinth": "concrete/concretewall002c", "trim": "stone/stonewall050f", "frame": "wood/woodbeam001a"}
STYLES = (   # a house's ground floor and its upper floors: the commonest walls of the owner's own streets
    ("brick/brickwall053e", "concrete/concretewall074c"), ("plaster/plasterwall047b", "plaster/plasterwall042c"), ("brick/brickwall037a", "brick/brickwall037c"),
    ("concrete/concretewall059e", "concrete/concretewall055b"), ("brick/brickwall045d", "brick/brickwall040c"), ("stone/stonewall040f", "plaster/plasterwall046b"),
    ("brick/brickwall014l", "brick/brickwall017b"), ("concrete/concretewall037a", "brick/brickwall040b"),
)
GLASS = "glass/glasswindow010a"     # in the owner's map a face 64 wide and 96 high shows one whole window: 256 by 384 of the sheet, starting 128 down it
WIN_W, WIN_H = 64, 96
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
                if spec[0] == "solid":
                    self.cells[c] = ("solid", self.top_of(c), True)
                elif spec[0] == "low" and len(spec) == 4:
                    self.cells[c] = spec + (max(self.top_of(c), spec[3]), True)

    plan = TownPlan(BASE, b.rim, b.sky, b.vis + ": walls and floors")
    plan.tops, plan.walk = [], walk
    return plan


def lay_street(b, m, L):
    """The street between the building lines (v -256 to 256), as the owner's own: a pavement 96 wide each side with a
    kerb, a gutter 16 under it, and cobbles rising over 64 to a flat crown 8 under the pavement. Call it AFTER the
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
    walk, gut, crown = F + fr.dz, F + fr.dz - 16, F + fr.dz - 8
    for s in (-1, 1):
        put(min(s * 192, s * 256), max(s * 192, s * 256), ("open", walk, R["walk"]))
        put(min(s * 64, s * 192), max(s * 64, s * 192), ("open", gut, R["strip"]))
    put(-64, 64, ("open", crown, R["road"]))
    for s in (-1, 1):
        m.det([(0, min(s * 160, s * 168), F - 16, L, max(s * 160, s * 168), F)], R["kerb"])
        m.det([(0, min(s * 168, s * 192), F - 16, L, max(s * 168, s * 192), F)], R["walk"])
        m.det([(0, min(s * 64, s * 96), F - 16, L, max(s * 64, s * 96), F - 8)], R["road"])
        m.shapes([prism([(s * 160, F - 16), (s * 96, F - 8), (s * 96, F - 16)], "x", 0, L, R["strip"])])


def glass_pane(m, u1, u2, z1, z2):
    """A window's glass, a sheet 1 thick on the wall itself, the owner's glass laid exactly as theirs is."""
    x1, y1, a, x2, y2, c = m.fr.box(u1, 255, z1, u2, 256, z2)
    vs = "[0 0 -1 %d] 0.25" % ((128 + 4 * c) % 512)
    if x2 - x1 == 1:
        us, names = "[0 1 0 %d] 0.25" % ((-4 * y1) % 256), ("east", "west")
    else:
        us, names = "[1 0 0 %d] 0.25" % ((-4 * x1) % 256), ("north", "south")
    m.b.vmf.brush_entity("func_detail", {}, [((x1, y1, a, x2, y2, c), dict((n, GLASS) for n in names), dict((n, (us, vs)) for n in names))], R["frame"], m.dv)


def flat_prop(m, model, u, v, z, yaw, roll):
    """A prop_static turned on its side (a board nailed across): z is its middle."""
    m.point("prop_static", u, v, z, {"model": model, "angles": "0 %d %d" % (m.fr.yaw(yaw), roll), "skin": "0", "solid": "0", "disableshadows": "1",
                                     "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, m.pv)


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
    lots = []
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
        rows = [172, 300] if high >= 420 else [192 if high >= 370 else 172]
        low_holes, doors, door_done = [], [], False
        for u in mids:                                       # the ground floor: a window, a door, or a blank bay
            if not clear(u - 64, u + 64, 0, 140):
                continue
            pick = rnd.random()
            if pick < 0.22 and not door_done:
                door_done = True
                low_holes.append((u - 24, u + 24, 0, 108))
                doors.append(u)
            elif pick < 0.85:
                low_holes.append((u - WIN_W // 2, u + WIN_W // 2, 36, 36 + WIN_H))
        up_holes = [[(u - WIN_W // 2, u + WIN_W // 2, s, s + WIN_H) for u in mids if clear(u - 40, u + 40, s - 8, s + WIN_H + 8)] for s in rows]
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
            if s == 0:                                       # a door: its frame, and the city's own door shut in it
                m.det([(h1 - 5, 245, F, h1, 256, F + 113), (h2, 245, F, h2 + 5, 256, F + 113), (h1 - 5, 245, F + 108, h2 + 5, 256, F + 113)], R["frame"])
                m.dynamic(DOOR, h1, 253, 270, F)
                continue
            glass_pane(m, h1, h2, F + s, F + t)
            m.det([(h1 - 5, 244, F + s - 5, h2 + 5, 256, F + s)], R["trim"])                     # the sill
            m.det([(h1 - 4, 247, F + t, h2 + 4, 256, F + t + 7)], R["trim"])                     # the lintel
            m.det([((h1 + h2) // 2 - 1, 253, F + s, (h1 + h2) // 2 + 1, 255, F + t)], R["frame"])   # the bar down its middle
            if rnd.random() < (0.45 if s < 100 else 0.18):                                         # boarded up
                for z in rnd.sample((s + 20, s + 44, s + 70), rnd.choice((2, 3))):
                    flat_prop(m, BOARD, (h1 + h2) // 2 + rnd.randrange(-6, 7), 248, F + z, 270, 90 + rnd.randrange(-7, 8))
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
    was its ramp), a slope up to it from the pavement. sign: +1 for the frame's left wall, -1 for its right."""
    from map_modules import F
    cells, street = b.plan.cells, F + fr.dz
    start, was = None, 0
    for u in list(range(0, L, CELL)) + [L]:
        h = 0
        if u < L:
            x, y = fr.pt(u + 32, sign * 288)
            spec = cells.get((x // CELL, y // CELL))
            if spec and spec[0] == "open" and street < spec[1] <= street + 128:
                h = spec[1] - street
        if h != was:
            if was:
                m.shapes([prism([(sign * 256, F - 16), (sign * (240 - was), F - 16), (sign * 256, F + was)], "x", start, u, MAT["canal_wall"])])      # (down to the gutter's height: a high terrace's slope crosses the kerb)
            start, was = u, h


def landing(b, x, y, rot, L, tag, dz):
    """The canal's way into the town: on the street's right a basin at the canal's own height, entered through a
    standard canal gate facing back the way the street came. A flight of steps 192 wide climbs from the basin's floor
    straight up to a quay on the street, between two sloping side walls; the quay's edge has the city's handrail."""
    from map_modules import F, Frame, Mod, m_gate
    up = Mod(b, Frame(x, y, rot, L, dz=dz), tag)             # (the street's height)
    low = Mod(b, Frame(x, y, rot, L), tag + " (the canal)")  # (the canal's height)
    up.open(0, -448, L, -256, mat=R["walk"])                 # the quay: the pavement widened toward the basin
    gf = Frame(*(Frame(x, y, rot, L).pt(0, -704) + (rot, 256)))
    m_gate(Mod(b, gf, tag + " (the canal gate)"), ["canal"])
    low.open(256, -1088, 896, -448)                          # the basin
    low.side(0, -1088, 896, -448)
    steps = dz // 8
    foot = -448 - 12 * steps
    low.steps(foot, 512, 704, F, F + dz, "v", 1)             # up toward the street, ending flush with the quay's edge
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
    low.lane(608, -448 - 6 * steps, F + dz // 2)
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
    b.notes.append("the road's end is at (%d %d), 512 wide: the roadway's crown at z %d, gutters %d, pavements %d" % (fr.pt(0, 0) + (F + dz - 8, F + dz - 16, F + dz)))
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
            street.static("models/props_vehicles/car00%da_physics.mdl" % rnd.choice((2, 4, 5)), rnd.randrange(200, L - 200), rnd.randrange(-40, 40), rnd.randrange(0, 360, 15), F - 8)
        street.scatter(100, -80, L - 100, 80, 2, 300 + n, z=F - 8)
        side = 1 if n % 2 == 0 else -1                       # a lamppost on one pavement, its arm over the road
        street.static(POST, L // 2, side * 176, 180 if side > 0 else 0, F)
        street.light(L // 2, side * 80, F + 400, "255 214 170 380")
        street.blocked(L // 2 - 16, min(side * 160, side * 192), L // 2 + 16, max(side * 160, side * 192))
        street.cubemap(L // 2, 0)
        if n % 2 == 0:
            street.view(60, 0, F - 8, 0, 2, "stretch %d, along the street" % (n + 1))
        for u in range(128, L, 256):
            street.lane(u, 0, F - 8)
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


MODULES = {"hq": (768, m_hq, HQ_DOC)}
