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

The town is one street at the city's road height (z 656), with a module on each side of every stretch.
Each module is built as it is in the canal, lifted 256: its canal is the street, its left wall the
building line. A layout whose first line is "ground street" is a town; then each line is

    LEFT | RIGHT        two modules facing each other across the street (the right one is built turned round)
    LEFT                one module, a blank brick front opposite

"landing" is the canal's way in: a real canal gate (the same as every canal piece's), a basin at the
canal's own height on the street's right, and stairs up to the street. The street's start is the road's
way in: a wall in a visgroup of its own to delete where a road is joined.
"""

from map_build import CELL, GATE_HIGH, MAT

HQ_DOC = "the Resistance leader's office: a briefing room and an office behind it, a flag outside (left)"


def m_hq(m, opt):
    """The Resistance leader's office. A doorway in the left wall into a briefing room (a long table and benches, a
    map board, a lamp), and behind a partition the leader's own office: a desk and chair, a filing cabinet, a strong
    box, a cot. Outside by the door, a flagpole with a banner the game can show while this is the live headquarters.
    Named for the game: lc_hq_setup (the doorstep: where the leader stands to set the headquarters up), lc_hq_flag
    (the banner, a func_brush: Enable shows it, Disable hides it), lc_hq_desk, lc_hq_table, lc_hq_map.
    Unchecked: a func_brush's rendercolor on plaster (the banner's red)."""
    from map_modules import F, MM
    wood, steel = MM["wood"], MM["steel"]
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
    m.det([(132, 400, F + 48, 136, 560, F + 128)], wood)                                  # the map board
    m.decal("decals/decalposter014a", 137, 440, F + 96)
    m.decal("decals/decal_posters005a", 137, 520, F + 92)
    m.target("lc_hq_map", 180, 480, F + 8, 180)
    m.target("lc_hq_table", 384, 512, F + 36)
    m.lamp(384, 512, F + 150, "255 205 150 55", hang=18)
    m.static("models/props_junk/wood_crate001a.mdl", 600, 360, 20)
    m.static("models/props_c17/lockers001a.mdl", 628, 600, 180)
    # the office
    m.static("models/props_wasteland/controlroom_desk001a.mdl", 512, 860, 90)
    m.static("models/props_wasteland/controlroom_chair001a.mdl", 512, 910, 270)
    m.static("models/props_wasteland/controlroom_filecabinet002a.mdl", 620, 930, 180)
    m.det([(392, 900, F, 424, 952, F + 44)], steel)                                       # the strong box
    m.det([(392, 720, F + 8, 432, 800, F + 22)], wood)                                    # a cot
    m.target("lc_hq_desk", 512, 880, F + 36, 270)
    m.lamp(512, 830, F + 134, "255 200 140 40", hang=18)
    m.blocked(440, 820, 590, 940)
    # outside: the flagpole and the banner
    m.det([(476, 236, F, 482, 242, F + 250), (472, 232, F, 486, 246, F + 6)], MAT["bars"])
    m.ent("func_brush", {"targetname": "lc_hq_flag", "Solidity": "1", "StartDisabled": "0", "solidbsp": "0", "rendermode": "0", "renderamt": "255",
                         "rendercolor": "190 60 40", "renderfx": "0", "spawnflags": "2", "disableshadows": "1", "vrad_brush_cast_shadows": "0"},
          [(482, 238, F + 176, 540, 240, F + 246)], "plaster/plasterwall042c")
    m.target("lc_hq_setup", 384, 200, F + 8, 270)
    for u, v in ((384, 290), (240, 400), (560, 640), (512, 760)):
        m.lane(u, v)
    m.view(384, 60, F, 90, 0, "the door and the flag")


def terrace_slopes(b, fr, L, sign, m):
    """Where a module has open ground a little higher than the street beside its wall (a terrace: in the canal the bank
    was its ramp), a slope up to it from the street. sign: +1 for the frame's left wall, -1 for its right."""
    from map_build import prism
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
                m.shapes([prism([(sign * 256, F), (sign * (256 - was), F), (sign * 256, F + was)], "x", start, u, MAT["canal_wall"])])
            start, was = u, h


def landing(b, x, y, rot, L, tag):
    """The canal's way into the town: on the street's right a basin at the canal's own height, entered through a
    standard canal gate facing back the way the street came, with stairs up its wall to a quay along the street."""
    from map_modules import F, Frame, Mod, chain_link, m_gate
    import map_corridor as mc
    dz = mc.LIFT_Z
    up = Mod(b, Frame(x, y, rot, L, dz=dz), tag)             # (the street's height)
    low = Mod(b, Frame(x, y, rot, L), tag + " (the canal)")  # (the canal's height)
    up.open(0, -448, L, -256)                                # the quay: the street widened toward the basin
    gf = Frame(*(Frame(x, y, rot, L).pt(0, -704) + (rot, 256)))
    m_gate(Mod(b, gf, tag + " (the canal gate)"), ["canal"])
    low.open(256, -960, 896, -448)                           # the basin
    low.side(0, -960, 256, -448)
    run = low.steps(832, -512, -448, F, F + dz, "u", -1)     # 32 steps, up toward the gate's end, along the quay's wall
    low.no_bank(832 - run - 8, -456, 840, -440)
    low.blocked(832 - run, -512, 832, -448)
    low.taken(832 - run, -512, F, 832, -448, F + dz)
    top = 832 - run
    for a, c in ((256, top - 64), (top + 64, 896)):          # a parapet along the quay's edge, open at the stairs' head
        if c > a:
            up.det([(a, -448, F, c, -436, F + 40)], MAT["beam"])
            chain_link(up, (a, -442), (c, -442), F + 40, 72)
    up.det([(896, -448, F, 908, -256, F + 40)], MAT["beam"])
    low.static("models/props_canal/boat001a.mdl", 640, -800, 10)
    low.blocked(520, -850, 760, -750)
    up.lamp(600, -300, F + 180, "255 205 150 70")
    up.target("lc_town_landing", top + 16, -400, F + 8, 90)
    low.lane(860, -480, F)
    low.lane(832 - run // 2, -480, F + dz // 2)
    up.lane(top + 16, -400, F)
    low.lane(576, -640, F)
    low.view(600, -800, F, 150, -14, "the basin and the stairs")
    b.notes.append("%s: the canal's gate is at (%d %d), 512 wide, floor z %d, facing back along the street" % ((tag,) + gf.pt(0, 0) + (F,)))


def build(lay, args):
    """A layout that says "ground street": the town. Gives what build_chain gives."""
    import random
    import map_corridor as mc
    from map_modules import F, HEADINGS, MODULES, MM, Build, Frame, Mod
    dz = mc.LIFT_Z
    b = Build(lay["name"], lay["rim"], args.first_node or 7000, "left")
    b.test = bool(args.test)
    x, y = lay["start"]
    rot = HEADINGS[lay["heading"]]
    rnd = random.Random(17)
    # the road's way in: the street's first 64, and across its start a wall to delete where a road is joined
    fr = Frame(x, y, rot, 64, dz=dz)
    m = Mod(b, fr, "the road's end")
    m.open(0, -256, 64, 256)
    m.world((0, -256, BASE_UNDER(b, dz), 16, 256, b.sky + 16 - dz), "brick/brickwall045d", vis="%s: the town's road end (delete to join a road)" % b.vis)
    b.plan.keep_out.append(fr.rect(-64, -256, 0, 256))
    seed = fr.at(40, 0, F + 32)
    spawn = (fr.at(48, 0, F + 16), fr.yaw(0))
    b.notes.append("the road's end is at (%d %d), 512 wide, at z %d" % (fr.pt(0, 0) + (F + dz,)))
    x, y = Frame(x, y, rot, 64).pt(64, 0)
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
            if not w or (w[0] != "landing" and w[0] not in MODULES):
                continue
            tag = "%d %s" % (n + 1, w[0])
            if w[0] == "landing":
                landing(b, x, y, rot, L, tag)
                continue
            length = MODULES[w[0]][0]
            mf = Frame(x, y, rot, length, flip, dz=dz)
            mod = Mod(b, mf, tag)
            MODULES[w[0]][1](mod, w[1:])
            terrace_slopes(b, mf, length, 1, mod)
            b.labels.append(mf.pt(length // 2, 300) + (w[0],))
        # the street itself: left abandoned
        if rnd.random() < 0.6:
            street.static("models/props_vehicles/car00%da_physics.mdl" % rnd.choice((2, 4, 5)), rnd.randrange(200, L - 200), rnd.randrange(-60, 60), rnd.randrange(0, 360, 15))
        street.scatter(100, -90, L - 100, 90, 2, 300 + n)
        street.cubemap(L // 2, 0)
        if n % 2 == 0:
            street.view(60, 0, F, 0, 2, "stretch %d, along the street" % (n + 1))
        for u in range(128, L, 256):
            street.lane(u, 0)
        x, y = Frame(x, y, rot, L).pt(L, 0)
    cells = b.plan.cells
    b.lifted = set(c for c, spec in cells.items() if spec[0] != "solid" and spec[1] >= F + dz)
    xs, ys = [c[0] for c in cells], [c[1] for c in cells]
    for i in range(min(xs) - 2, max(xs) + 3):
        for j in range(min(ys) - 2, max(ys) + 3):
            b.plan.front.add((i, j))
    return b, seed, spawn, (x, y, "ENWS"[rot])


def BASE_UNDER(b, dz):
    """The bottom of everything, in a lifted module's own heights."""
    return b.plan.base - dz


def ascii_plan(b):
    """The plan in letters, north up, one letter for 128 by 128: free to read, where a picture is not.
    # wall   . street   ~ the canal's floor   o a roofed room   : open ground above the street   _ open ground below it"""
    from map_modules import F
    cells = b.plan.cells
    b.plan.walls()
    xs, ys = [c[0] for c in cells], [c[1] for c in cells]
    street = F + 256
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
                elif spec[1] == street:
                    kinds.add(".")
                elif spec[1] == F:
                    kinds.add("~")
                else:
                    kinds.add(":" if spec[1] > street else "_")
            row += next(k for k in "o:_~.# " if k in kinds)
        out.append(row.rstrip())
    return "\n".join(out)


MODULES = {"hq": (768, m_hq, HQ_DOC)}
