#!/usr/bin/env python3
"""
Living City: the cistern by itself, lifted out of the canal ring (run it through map_build.py)

    python3 map_build.py cistern --test     lc_cistern_test.vmf: the technical test map, to compile and walk alone
    python3 map_build.py cistern            lc_cistern.vmf: the same without the spawn point, the sky and the sun
    python3 map_build.py cistern --test --views pics     ...and pictures of it (map_view.py)

The owner, 26 November: "please lift the cistern out of the canal ring and save it as it's own technical testing map; I
want to 'propper++' as much of it as possible, but first we need to add a lift to one corner that goes a walkway on the
cistern to above the cistern, where the street level will be (cistern will be below the street of the infested
quarter)".

What it is: the ring's cistern (map_modules.m_cistern: the round tank for the hive boss, its ledge, kerb, gallery, plank
walks, pillars, pipes and island under a grated shaft) without its stretch of canal. The tall passage with the stair
stays, ending in a wall where the canal was. Over all of it lies a flat plate at the street's height, 64 over the tank's
roof (STREET_OVER), open to the sky: where the infested quarter's street will be. The island's shaft comes up through
it under a second grating, level with the street.

THE LIFT, in the corner at 315 degrees (south-east as built, the far side from the passage): a doorway 128 wide through
the round wall off the gallery (one of the wall's 36 segments left out, a lintel over it), a small lobby behind it, and
beyond the lobby a shaft 192 square that comes up through the street into a head house. The lift itself is Valve's
(the owner, 26 November, of a first one made of brushes: "USE THE ELEVATORS IN HL2 STOP USING BRUSHES"): Black Mesa
East's freight lift (d1_eli_01, the prefab valve_eli_lift_ride). The cage is Half-Life 2's freightelevator model riding
on Valve's own unseen collision brushes (lc_cistern_lift, a func_movelinear built at the top, where it waits: people
come from the street); each landing's gate is Valve's elevatordoor model over their two unseen sliding clips
(lc_cistern_lift_gate_low / _top), shut while the cage is elsewhere; the buttons are Half-Life 2's lift button model,
one beside each gate (lc_cistern_lift_call_low / _top) and one in the cage (lc_cistern_lift_button); the sounds are
that lift's own. A press shuts the gate where the cage stands; the gate fully shut sends the cage; the cage's arrival
opens the gate there. So nothing moves while somebody stands in a gate (it presses on them without hurting and
waits), nobody can stand under the cage or walk into the empty shaft, and nothing crushes (no block damage anywhere).
For the game: lc_cistern_lift_down and lc_cistern_lift_up (logic_relays: fire Trigger) send it down or up.

Heights, as built (the tank's ledge is the canals' floor, 400; the whole piece moves as one when it is placed under the
quarter, whose roadway is z 656: its ledge would then be z 240): basin 368, ledge 400, gallery 528, the lift's lower
landing 530, the tank's roof 752, the street 816; the car travels 286 in about four and a half seconds.

Named for the game: lc_hive_boss_spot (the island), lc_cistern_gallery (the head of the stair), lc_cistern_lift_top
and lc_cistern_lift_low (info_targets on the two landings), and the lift's own names above.
Unchecked: which way the button model faces (taken from where Valve put theirs), a button model riding in the cage,
and what m_cistern itself leaves unchecked (its water sound, chains, pouring water and dust).
The ring's own cistern (map_modules.m_cistern, "cistern" in ring.txt) is left exactly as it was: the ring is another
chat's work. When it is dropped from the ring, this file is the cistern.
"""
import math

from map_build import CELL, MAT, check, octagon, prism, test_extras
from map_modules import F, MM, SCAPES, Build, Frame, Mod, take_views

STREET_OVER = 64                     # the street's surface over the tank's roof
CAR = "lc_cistern_lift"
LIFT_SPEED = 64


def cistern(args):
    from map_mods_c import cage_lamp, centred, chain, dustmotes, pour, ring_rail, ring_segments, vprism
    ceil, basin, cu, cv, R, G = F + 352, F - 32, 768, -1408, 768, F + 128
    ST = ceil + STREET_OVER              # the street
    HT = ST + 176                        # the head house's ceiling (a roof 16 thick over it): Valve's cage is 166 over its landing
    LZ = G + 2                           # the lift's lower landing: the lobby's floor, the car's floor when it is down
    DH = 112                             # the doorway's height through the round wall
    RW, RG, RK = 736, 672, 576           # the round wall's face, the gallery's inner edge, the kerb's inner edge
    b = Build("cistern", ST + 208, args.first_node or 6000)
    b.test = bool(args.test)
    m = Mod(b, Frame(0, 0, 0, 1536), "cistern")
    vmf = b.vmf
    road = MM["road"]

    def at(du, dv):                      # (a place given from the tank's middle)
        return cu + du, cv + dv

    def room(u1, v1, u2, v2, floor, top, mat=None, over=ST, over_mat=road):
        """A room under the street: floor to top, then solid up to the street (or to `over`), then the open air."""
        m.cellar(u1, v1, u2, v2, floor, top, over, mat=mat, upper_mat=over_mat)

    # --- the squares: the passage, the tank, the lift's lobby and shaft, and the street's plate over the rest ---
    room(640, -640, 896, -320, F, ceil)
    pillars = [(cu + du - 64, cv + dv - 64, cu + du + 64, cv + dv + 64) for du in (-384, 384) for dv in (-384, 384)]
    kind = {}
    for i in range(-12, 12):
        for j in range(-12, 12):
            u, v = cu + i * CELL, cv + j * CELL
            d = math.hypot(i + 0.5, j + 0.5) * CELL
            if d >= R or any(p[0] <= u < p[2] and p[1] <= v < p[3] for p in pillars):
                continue
            kind[(i, j)] = "island" if (abs(i + 0.5) < 2 and abs(j + 0.5) < 2) else "ring" if d >= R - 150 else "wet"
    # the lift: a way through the round wall on the diagonal, a lobby behind it 128 deep and 192 wide (du 576..704,
    # dv -768..-576), and Valve's shaft beyond, 192 square (du 704..896: 128 past the tank's own square)
    way = set(c for c in ((7, -10), (8, -10), (8, -9), (9, -9), (9, -8)) if c not in kind)
    lobby = set((i, j) for i in (9, 10) for j in (-12, -11, -10))
    shaft = set((i, j) for i in (11, 12, 13) for j in (-12, -11, -10))
    for (i, j) in sorted(shaft):           # (its pit 16 under the landing; its roof is the head house's)
        room(cu + i * CELL, cv + j * CELL, cu + (i + 1) * CELL, cv + (j + 1) * CELL, LZ - 16, HT, mat=MAT["canal_floor"], over=HT + 16, over_mat=MAT["beam"])
    wet = []
    for i in range(-12, 12):
        for j in range(-12, 12):
            u, v = cu + i * CELL, cv + j * CELL
            k = kind.get((i, j))
            if (i, j) in shaft:
                continue
            elif (i, j) in lobby:
                room(u, v, u + CELL, v + CELL, LZ, LZ + 128, mat="concrete/concretefloor031a")
            elif (i, j) in way:
                room(u, v, u + CELL, v + CELL, LZ, LZ + DH + 2, mat="concrete/concretefloor031a")
            elif k == "island":            # (the shaft over it: open to the sky, through the street)
                m.open(u, v, u + CELL, v + CELL)
            elif k == "ring":              # (iron grating in every fourth square of the ledge: it rings underfoot)
                room(u, v, u + CELL, v + CELL, F, ceil, mat="metal/metalgrate016a" if (i * 3 + j) % 4 == 0 else "concrete/concretefloor031a")
            elif k == "wet":
                room(u, v, u + CELL, v + CELL, basin, ceil)
                wet.append(m.fr.rect(u, v, u + CELL, v + CELL))
            else:                          # (solid ground under the street: the pillars' squares, the square's corners)
                m.open(u, v, u + CELL, v + CELL, floor=ST, mat=road)
    wet.sort(key=lambda r: (r[1], r[0]))
    runs = []
    for r in wet:
        if runs and runs[-1][1] == r[1] and runs[-1][2] == r[0]:
            runs[-1][2] = r[2]
        else:
            runs.append([r[0], r[1], r[2], r[3]])
    for x1, y1, x2, y2 in runs:
        vmf.world_box((x1, y1, basin, x2, y2, basin + 12), MAT["nodraw"], top=MM["water"], vis=b.vis + ": water and sludge", seals=False)

    # --- the round wall: 36 segments, damp concrete to a water line, the owner's concrete above; open where the passage
    # comes in (80 to 100 degrees) and, from the gallery up to a lintel, where the lift's doorway is (310 to 320) ---
    gap, door = (8, 9), 31
    rest = tuple(k for k in range(36) if k != door)
    m.shapes(ring_segments(cu, cv, RW, 820, F, F + 96, "concrete/concretewall059c", 36, skip=gap + (door,)) +
             ring_segments(cu, cv, RW, 820, F + 96, ceil, "concrete/concretewall008a", 36, skip=gap + (door,)) +
             ring_segments(cu, cv, RW, 820, F, F + 96, "concrete/concretewall059c", 36, skip=rest) +
             ring_segments(cu, cv, RW, 820, G + DH, ceil, "concrete/concretewall008a", 36, skip=rest))
    out_r = 820 / math.cos(math.pi / 36)

    def rim_pt(r, k):
        a = 2 * math.pi * k / 36
        return (int(round(cu + r * math.cos(a))), int(round(cv + r * math.sin(a))))
    sill = [rim_pt(RW, door), rim_pt(out_r, door), rim_pt(out_r, door + 1), rim_pt(RW, door + 1)]
    m.shapes([vprism(sill, F + 96, LZ + 1, "concrete/concretewall008a", end_mat="metal/metalhull010c")])      # (its top: a steel sill, 1 proud of the lobby's floor)
    m.det([(896, -700, F, 912, -640, ceil), (624, -700, F, 640, -640, ceil)], "concrete/concretewall008a")
    # the kerb round the water: stone, 1 proud of the ledge, from the water's edge to under the gallery
    m.shapes(ring_segments(cu, cv, RK, 676, basin, F + 1, "stone/stonewall050f", 36, phase=0.5, alt=True))
    # the gallery: a smooth ring of slab, a landing where the stair comes up, the handrail round its inner edge
    m.shapes(ring_segments(cu, cv, RG - 8, RW + 8, G - 8, G, MAT["beam"], 40, phase=0.5, alt=True))
    m.det([(640, -684, G - 7, 896, -640, G + 2)], "metal/metalhull010c")                   # (a steel landing, 2 proud of the ring)
    ring_rail(m, cu, cv, RG + 2, G, 42, skip=(20, 41))                                       # (open over the two ladders' heads)
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
    KI = int(math.ceil(RK * math.cos(math.pi / 36)))                                       # (the kerb's inner face, flat across each axis)
    for (a1, a2, axis, zk) in ((cu + KI, cu + 640, "u", F + 2), (cu - 640, cu - KI, "u", F + 2), (cv + KI, cv + 640, "v", F + 1), (cv - 640, cv - KI, "v", F + 1)):
        planks.append((a1, cv - 32, zk, a2, cv + 32, zk + 3) if axis == "u" else (cu - 32, a1, zk, cu + 32, a2, zk + 3))
    m.det(planks, "wood/woodfloor006b")
    m.det(posts, "wood/woodwall006a")
    # and steps down off the kerb into the water beside each walk, one flight in each quarter of it, for wading (and out)
    steps = []
    for k in range(4):
        def turn(u, v, k=k):
            for _ in range(k):
                u, v = -v, u
            return u, v
        for d1, d2, z in ((-KI, -KI + 32, F - 10), (-KI + 32, -KI + 56, F - 21)):
            (u1, v1), (u2, v2) = turn(d1, 32), turn(d2, 96)
            steps.append((cu + min(u1, u2), cv + min(v1, v2), basin, cu + max(u1, u2), cv + max(v1, v2), z))
    m.det(steps, MAT["canal_wall"], top=MAT["stairs"])
    # the shaft's grate under the roof and a second one level with the street (walked over, looked down through), the
    # pillars' heads and feet, the inflow pipes, the chains
    for top, bars in ((ceil, 9), (ST, 8)):      # (the street's: every bar inside the hole, none lying in the roadway beside it)
        m.det([(cu - 128, cv - 128 + 32 * k, top - 8, cu + 128, cv - 122 + 32 * k, top) for k in range(bars)] + [(cu - 4, cv - 128, top - 14, cu + 4, cv + 128, top - 8)], MAT["bars"])
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
    m.spot(cu, cv, ceil + 40, "230 236 240 300", 0, pitch=90, cone=60)
    dustmotes(m, (cu - 120, cv - 120, F + 16, cu + 120, cv + 120, ceil - 24))
    for k, (pu, pv) in enumerate(((cu - 320, cv - 384), (cu + 320, cv - 384), (cu - 320, cv + 384), (cu + 320, cv + 384))):
        cage_lamp(m, pu, pv, F + 220, 0 if pu < cu else 180, "190 205 210 45", lit=k in (1, 2))
        m.grime("number", pu, pv - 30, F + 70, 2 + k)
        m.grime("stain", pu, pv + 30, F + 40, 7 + k)
    m.light(768, -448, F + 200, "150 190 200 40")
    for k, (du, dv) in enumerate(((RW, 300), (-RW, -200), (300, -RW), (-420, RW - 140))):      # stains down the wall, a water line's marks
        a = math.atan2(dv, du)
        m.grime("stain", cu + int(round((RW - 2) * math.cos(a))), cv + int(round((RW - 2) * math.sin(a))), F + 110, 20 + k)
    # what floats, what lies about to be thrown (nothing on the gallery before the lift's doorway)
    m.loose("models/props_wasteland/dockplank01a.mdl", cu + 260, cv + 200, 30, z=basin + 12)
    m.loose("models/props_c17/oildrum001.mdl", cu - 300, cv + 160, 0, z=basin + 12)
    m.body("models/humans/corpse1.mdl", cu + 180, cv - 120, 160, z=basin + 2)
    for k, (model, du, dv, z) in enumerate((("models/props_junk/metalbucket01a.mdl", 690, 90, F), ("models/props_junk/garbage_metalcan001a.mdl", -700, 120, F),
                                            ("models/props_junk/garbage_glassbottle001a.mdl", 120, 700, F), ("models/props_junk/plasticbucket001a.mdl", 290, -640, G),
                                            ("models/props_junk/garbage_metalcan001a.mdl", -500, 500, G), ("models/props_junk/garbage_glassbottle001a.mdl", -680, -60, G))):
        m.loose(model, cu + du, cv + dv, 40 * k, z=z)
    m.soundscape(SCAPES["tunnel"], cu, cv, F, radius=900)
    m.soundscape(SCAPES["watery"], 768, -448, F, radius=200)

    lift(m, at, G, LZ, DH, ST, HT)

    # --- path nodes: one line down the middle of everything walked on below (the ledge, the water, the island, the
    # passage), and the gallery's by hand ---
    m.lane(768, -448)
    for du, dv in ((-488, -488), (488, -488), (-488, 488), (488, 488), (700, 0), (-700, 0), (0, -700), (-96, 716)):
        m.lane(cu + du, cv + dv, G)
    m.blocked(cu + 448, cv - 768, cu + 896, cv - 448)          # (none in the lift, its lobby or its doorway)
    m.view(800, -500, F, 270, 0, "coming in, on the ledge")
    m.view(672, -690, G, 285, 14, "from the gallery")
    m.view(cu + 40, cv + 40, F, 135, -20, "on the island, looking up")
    m.view(cu + 600, cv, F, 180, 0, "on a plank walk")
    m.view(cu + 492, cv - 492, G, 315, 0, "on the gallery, before the lift's doorway")
    m.view(cu + 600, cv - 672, LZ, 0, 0, "in the lobby, before the lift's gate")
    m.view(cu + 520, cv - 672, ST, 0, 0, "on the street, before the lift's head house")
    b.notes.append("the tank's middle is at (%d %d); its floor is z %d under 12 of water, its ledge, planks and island z %d, its gallery z %d, its roof z %d, the street z %d" % (
        m.fr.pt(cu, cv) + (basin, F, G, ceil, ST)))
    b.notes.append("the lift: lower landing z %d, upper z %d, travel %d at %d (%.1f s)" % (LZ, ST, ST - LZ, LIFT_SPEED, (ST - LZ) / float(LIFT_SPEED)))

    # --- the walls, the sky, what a test map needs, the nodes, the checks ---
    plan = b.plan
    plan.walls()
    if args.test:      # (on the street beside the head house, looking at it: the lift waits at the top)
        test_extras(vmf, m.fr.at(cu + 480, cv - 672, ST + 16), m.fr.yaw(0), b.vis + ": for testing alone (never in the real map)")
    plan.build(vmf)
    from map_build import lift_ladder_feet
    from map_ring import lane_cells

    def floor_of(c):
        spec = plan.cells.get(c)
        if not spec or spec[0] == "solid" or spec[1] > F:      # (below only: the street is the quarter's own to lay)
            return None
        return spec[1]
    ground, _line = lane_cells(sorted(plan.cells), floor_of, lambda c: plan.cells[c][0] == "cellar", b.blocked)
    for (nx, ny, nz, _roofed) in ground:
        b.node(nx, ny, nz)
    for (nx, ny, nz) in b.lanes:
        b.node(nx, ny, nz)
    b.notes += lift_ladder_feet(vmf)
    problems, _air = check(vmf, m.fr.at(cu, cv, F + 64), [])
    problems = b.problems + problems
    nodes = sum(1 for cls, _ in vmf.points if cls == "info_node")
    print("cistern (the hive boss's tank by itself, with the lift to the street): %d entities, %d path nodes (ids %d to %d)" % (
        len(vmf.ents), nodes, b.first_node, b.node_id - 1))
    print("  named for the game: " + ", ".join("%s (%s)" % (n[0], n[1]) for n in sorted(set(b.names))))
    for line in b.notes:
        print("  " + line)
    for p in problems:
        print("  PROBLEM: " + p)
    if not problems:
        print("  checked: every corner on the grid; sealed by itself")
    args.view_list = list(b.views)
    args.expect_overlap = set()
    args.out_name = "lc_cistern%s.vmf" % ("_test" if args.test else "")
    args.after_write = (lambda path: take_views(b, path, args.views, "cistern", cut=F + 300)) if args.views else None
    return vmf, problems


def lift(m, at, G, LZ, DH, ST, HT):
    """The lift in the corner at 315 degrees (the module's +u, -v): see the top of the file. It is Valve's own, Black
    Mesa East's freight lift (d1_eli_01, the prefab valve_eli_lift_ride), with nothing of it drawn by brushes: the cage is
    Half-Life 2's freightelevator model on Valve's own 38 unseen collision brushes, the gates are its elevatordoor
    models over Valve's two unseen sliding clips, the buttons its freightelevatorbutton models, the sounds its own.
    Valve's piece has its doorway's middle at (0, 0) and its shaft toward -y; ours has the landings' edge at du FX, the
    cage's middle at dv CY and the shaft toward +u (Valve's turned a quarter turn left). Everything is given from the
    tank's middle (at)."""
    import json
    import os
    b, vmf, fr = m.b, m.b.vmf, m.fr
    vis = b.vis + ": the lift"
    FX, CY = 704, -672
    pf = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "reference", "prefabs", "valve_eli_lift_ride.json")))

    def box(du1, dv1, z1, du2, dv2, z2):
        (x1, y1), (x2, y2) = fr.pt(*at(du1, dv1)), fr.pt(*at(du2, dv2))
        return (min(x1, x2), min(y1, y2), z1, max(x1, x2), max(y1, y2), z2)

    def valve(x1, y1, z1, x2, y2, z2, z0):
        """A box of Valve's piece where ours stands, on a landing at z0."""
        return box(FX - y2, CY + x1, z0 + z1, FX - y1, CY + x2, z0 + z2)

    def place(x, y, z, z0):
        return fr.at(*at(FX - y, CY + x), z0 + z)

    def turned(yaw):                 # (a yaw of Valve's piece, as ours)
        return fr.yaw((yaw + 90) % 360)

    prop_keys = {"skin": "0", "disableshadows": "1", "fademindist": "-1", "fadescale": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255",
                 "MinAnimTime": "5", "MaxAnimTime": "10", "RandomAnimation": "0", "SetBodyGroup": "0", "pressuredelay": "0", "ExplodeDamage": "0", "ExplodeRadius": "0"}
    # the cage, built at the top (where it waits): Valve's collision brushes, unseen, and their model riding on them
    cage = [w for w in pf["wiring"] if w["keys"].get("targetname") == "elevator_lab"][0]
    boxes = []
    for brush in cage["brushes"]:
        vs = [v for side in brush for v in side["corners"]]
        boxes.append(valve(*([int(round(min(v[k] for v in vs))) for k in range(3)] + [int(round(max(v[k] for v in vs))) for k in range(3)]), z0=ST))
    vmf.brush_entity("func_movelinear", {"targetname": CAR, "movedir": "90 0 0", "speed": str(LIFT_SPEED), "movedistance": str(ST - LZ), "startposition": "0",
                                         "spawnflags": "0", "blockdamage": "0", "startsound": "eli_lab.elevator_move", "stopsound": "eli_lab.elevator_stop",
                                         "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255", "disableshadows": "1"},
                     boxes, MAT["nodraw"], vis, connections=[("OnFullyOpen", "lc_cistern_lift_gate_low", "Open", "", 0.3), ("OnFullyClosed", "lc_cistern_lift_gate_top", "Open", "", 0.3)])
    b.names.append((CAR, "func_movelinear", m.tag))
    vmf.point("prop_dynamic", place(0, -88, -8, ST), dict(prop_keys, targetname=CAR + "_cage", model="models/props_lab/freightelevator.mdl", angles="0 %d 0" % turned(90),
                                                         solid="0", parentname=CAR), vis)

    def button(name, x, y, z, yaw, z0, wires, parent=None):
        """Half-Life 2's lift button on a wall's face at Valve's (x, y), facing yaw, and an unseen func_button over it."""
        more = {"parentname": parent} if parent else {}
        vmf.point("prop_dynamic", place(x, y, z, z0), dict(prop_keys, targetname=name + "_model", model="models/props_lab/freightelevatorbutton.mdl",
                                                          angles="0 %d 0" % turned(yaw), solid="0", **more), vis)
        dx, dy = int(round(math.cos(math.radians(yaw)))), int(round(math.sin(math.radians(yaw))))
        bb = (min(x - 1 * dx, x + 8 * dx) - 6 * abs(dy), min(y - 1 * dy, y + 8 * dy) - 6 * abs(dx), z + 2, max(x - 1 * dx, x + 8 * dx) + 6 * abs(dy), max(y - 1 * dy, y + 8 * dy) + 6 * abs(dx), z + 22)
        vmf.brush_entity("func_button", dict({"targetname": name, "spawnflags": "1025", "wait": "2", "speed": "5", "lip": "0", "movedir": "0 0 0", "sounds": "15", "health": "0",
                                              "rendermode": "10", "renderamt": "0", "rendercolor": "255 255 255"}, **more),
                         [valve(*bb, z0=z0)], MAT["nodraw"], vis, connections=[("OnPressed", n, i, val, d) for n, i, val, d in wires])
        b.names.append((name, "func_button", m.tag))
    # the cage's own button, on its right wall inside (it sends the cage to the other landing: only the gate where it
    # stands is open, so only that one shuts and sends it)
    button("lc_cistern_lift_button", 78, -50, 32, 180, ST, [("lc_cistern_lift_down", "Trigger", "", 0), ("lc_cistern_lift_up", "Trigger", "", 0)], parent=CAR)

    # each landing: Valve's gate model, their two unseen clips that slide apart behind it (the clips are what stops
    # people, and what tells the cage the gate is shut: the first one carries that wire), a call button on the pier to
    # the gate's right, and the front the gate stands in (two piers and a lintel)
    door = {"speed": "100", "lip": "16", "wait": "-1", "spawnpos": "0", "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0",
            "noise1": "eli_lab.elevatordoor_move", "noise2": "eli_lab.elevatordoor_stop", "locked_sentence": "0", "unlocked_sentence": "0", "renderamt": "255",
            "rendercolor": "255 255 255", "renderfx": "0", "rendermode": "0", "disableshadows": "1"}
    wall = "concrete/concretewall008a"
    for tag, z0, top, send in (("low", LZ, LZ + 128, "Close"), ("top", ST, HT + 16, "Open")):
        gate = "lc_cistern_lift_gate_" + tag
        vmf.point("prop_dynamic", place(0, -4, 1, z0), dict(prop_keys, targetname=gate + "_model", model="models/props_lab/elevatordoor.mdl", angles="0 %d 0" % turned(90),
                                                           solid="6"), vis)
        for n, (leaf, way) in enumerate(((valve(0, -12, 0, 96, -2, 160, z0), 0), (valve(-96, -12, 0, 0, -2, 160, z0), 180))):
            wires = [("OnFullyClosed", CAR, send, "", 0.5), ("OnClose", gate + "_model", "SetAnimation", "close", 0), ("OnOpen", gate + "_model", "SetAnimation", "open", 0)]
            vmf.brush_entity("func_door", dict(door, targetname=gate, movedir="0 %d 0" % turned(way), spawnflags="0" if n == 0 else "4096"), [leaf], MAT["clip"], vis,
                             connections=wires if n == 0 else None)
        b.names.append((gate, "func_door", m.tag))
        button("lc_cistern_lift_call_" + tag, 74, 8, 40, 90, z0, [("lc_cistern_lift_down" if tag == "low" else "lc_cistern_lift_up", "Trigger", "", 0)])
        vmf.detail([valve(-96, 0, 0, -52, 8, top - z0, z0), valve(52, 0, 0, 96, 8, top - z0, z0), valve(-52, 0, 116, 52, 8, top - z0, z0)], wall, vis=vis)
        m.target("lc_cistern_lift_" + tag, *at(FX - 64, CY), z0 + 8, 0)
        vmf.keep_way_clear(valve(-96, 0, 0, 96, 128, 112, z0), "the lift's %s landing" % ("lower" if tag == "low" else "upper"))
    # the head house on the street: its front is the upper landing's; a wall on the side toward the street (the other
    # two sides are the piece's own outer wall); its roof is the shaft's own
    vmf.detail([box(FX - 8, CY + 96, ST, 768, CY + 104, HT + 16)], wall, vis=vis)
    # the wiring: the cage waits at the top with that gate open
    m.point("logic_auto", *at(FX + 72, CY), HT - 24, {"spawnflags": "1"}, vis=vis, connections=[("OnMapSpawn", "lc_cistern_lift_gate_top", "Open", "", 0.5)])
    m.point("logic_relay", *at(FX + 88, CY), HT - 24, {"targetname": "lc_cistern_lift_down", "StartDisabled": "0", "spawnflags": "0"}, vis=vis,
            connections=[("OnTrigger", "lc_cistern_lift_gate_top", "Close", "", 0)])
    m.point("logic_relay", *at(FX + 104, CY), HT - 24, {"targetname": "lc_cistern_lift_up", "StartDisabled": "0", "spawnflags": "0"}, vis=vis,
            connections=[("OnTrigger", "lc_cistern_lift_gate_low", "Close", "", 0)])
    m.light(*at(FX + 88, CY + 60), HT - 40, "255 214 160 60")
    m.light(*at(FX - 64, CY), LZ + 104, "255 214 160 40")
    m.light(*at(552, -552), LZ + 92, "255 200 140 25")                              # (in the doorway off the gallery: it glows onto the walk)
    vmf.keep_way_clear(box(512, -640, G, 640, -512, G + DH), "the lift's doorway off the gallery")
