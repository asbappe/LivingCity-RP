"""Canal modules for the canal ring round City 18 (the owner, 22 November: "map all of them into the big canal ring
that will go around C18 ... keep the scale correct for us to plug directly into the c18 points").

roadend: the west road's end, where the ring's north half meets the city a second time (the first is the first canal's
quay): the platform at the road's height, the stairs down to the canal's floor, and a side gate in the far wall where
the ring's south half leaves (map_layouts/ring_north.txt ends with it; ring_south.txt starts at its side gate).
"""

from map_build import GATE_HIGH, MAT, gate_cap
from map_modules import BASE, F, SCAPES, canal_grime

ROAD_W = 840          # the west road's surface (184 higher than the east one: map_ring.py)
ROAD_SKY = 2336       # the sky over the west road (the owner's brush 14734 reached it)


def m_roadend(m, opt):
    """The west road's end (the owner's brushes 14734, the sky wall, and 15630, the unseen wall before it, are what it
    stands in the place of: map_merge.py leaves them out). Built for one place: heading south at x -3136, from y 2752
    to 1664 (map_layouts/ring_north.txt), with the road's opening at x -2608, y 1920..2560, its surface z 840.

    On the left bank a platform at the road's height (256 by 640, open to the sky as the old ring's was) carries the
    road on to the canal's edge; a flight of 28 steps (16 up, 24 along) runs south down the left wall from its north
    end to the canal's floor, filled under and railed on its open side, and the platform's edge is railed. The far
    (right) wall has a standard gate (512 wide, 256 high, capped until the ring's south half is joined to it): the way
    on round the south of the city. The canal ends past the platform, as the old ring's did (the city stands 64 beyond).
    A lamppost on the platform, a caged lamp over the stairs' foot, a puddle and trash; the courtyard's soundscape.
    With --test the road's opening is shut by a wall of sky (the city is not there to close it).
    Unchecked: nothing new (the old ring's platform, stairs and threshold, rebuilt to fit one module)."""
    from map_mods_c import cage_lamp, handrail
    b = m.b
    L = m.fr.length
    cw, quay, sky = MAT["canal_wall"], MAT["quay_floor"], MAT["sky"]
    m.open(0, -256, L, 256)
    # the platform: the road carried on to the canal's edge; nothing of this module east of the road's opening
    m.open(192, 256, 832, 512, floor=ROAD_W, mat=quay)
    b.plan.keep_out.append(m.fr.rect(0, 512, L, 4096))
    b.replaces |= {"14734", "15630"}      # (the sky wall at the west road's end and the unseen wall before it)
    m.side(192, 256, 832, 512)
    m.no_bank(128, 120, 900, 320)
    # where brush 14734 was (x -2624..-2608): the platform's floor carried on to the road, a wall each side, a lid, and
    # above the lid the sky the road sees (as map_ring.py did)
    base = BASE
    m.world((192, 512, base, 832, 528, ROAD_W), cw, top=quay)
    m.world((128, 512, base, 192, 528, b.sky + 16), cw)
    m.world((832, 512, base, 896, 528, b.sky + 16), cw)
    m.world((192, 512, b.sky, 832, 528, b.sky + 16), sky)
    m.world((192, 512, b.sky + 16, 832, 528, ROAD_SKY), sky)
    m.portal(192, 494, ROAD_W, 832, 496, b.sky)
    b.stoppers.append(m.fr.box(128, 528, BASE, 896, 592, b.sky + 16))     # (the road: by itself this file is open there)
    if b.test:
        m.world((128, 528, base, 896, 592, b.sky + 16), sky, vis=b.vis + ": for testing alone (never in the real map)")
    # the stairs: from the canal's floor at the south up to the platform's north end, against the left wall
    run = m.steps(852, 136, 256, F, ROAD_W, "u", -1)        # (clear of the parapet's own face: two faces in one plane flicker)
    top = 852 - run
    m.stair_side(852, run, 128, 136, F, ROAD_W, sign=-1, high=40)     # (its open side a parapet 40 over the treads)
    m.taken(top - 8, 120, F, 860, 256, ROAD_W + 48)
    m.blocked(top, 128, 852, 256)
    m.grime("stain", 360, 128, F + 160, 3)                 # (the parapet's long face: water down it, a tag at eye height)
    m.grime("graffiti", 640, 128, F + 110, 5)
    m.grime("stain", 760, 128, F + 60, 8)
    handrail(m, (top + 96, 260), (832 - 32, 260), ROAD_W)  # the platform's edge, clear of the stairs' top
    m.lane(top + 40, 192, ROAD_W - 16)
    m.lane((top + 852) // 2, 192, (F + ROAD_W) // 2)
    m.lane(880, 160, F)
    m.lane(512, 384, ROAD_W)
    m.static("models/props_c17/lamppost03a_on.mdl", 704, 480, 180, ROAD_W)
    m.light(704, 440, ROAD_W + 300, "255 214 170 300")
    cage_lamp(m, 900, 252, F + 200, 180)
    # the side gate in the right wall: where the south half of the ring begins
    m.low(576, -512, L, -256, F + GATE_HIGH)
    gate_cap(b.vmf, m.fr.box(576, -512, F, L, -448, F + GATE_HIGH), m.fr.box(576, -432, F, L, -424, F + GATE_HIGH), m.fr.ax("u"),
             "%s: %s side gate's cap (delete to join the south half)" % (b.vis, m.tag))
    m.portal(576, -384, F, L, -382, F + GATE_HIGH)
    b.plan.keep_out.append(m.fr.rect(512, -4096, L + 64, -512))
    b.allow.append(m.fr.box(448, -640, BASE, L + 128, -384, b.sky + 64))
    m.blocked(576, -512, L, -384)
    m.side(576, -512, L, -256)
    m.grime("number", 576 - 8, -320, F + 180, 77)
    from map_modules import TRIM
    m.det([(576, -256, TRIM + 128, L, -248, TRIM + 136)], "stone/stonewall050f")      # a course over the gate
    m.grime("stain", 760, -256, F + GATE_HIGH + 80, 78)
    x, y = m.fr.pt(0, 0)
    canal_grime(m, 0, L, 4000 + (x * 7 + y * 13) % 997)
    m.soundscape(SCAPES["courtyard"], L // 2, 0, F, radius=900)
    m.view(900, -60, F, 140, 8, "the platform and its stairs")
    m.view(400, 384, ROAD_W, 270, 10, "from the road's end")
    gx, gy = m.fr.pt((576 + L) // 2, -512)
    b.notes.append("%s: its side gate is at (%d %d), heading %s: the ring's south half starts there" % (
        (m.tag, gx, gy) + ({(1, 0): "E", (0, 1): "N", (-1, 0): "W", (0, -1): "S"}[m.fr.way(270)],)))


MODULES = {
    "roadend": (1088, m_roadend, "the west road's end: a platform at the road's height, stairs down, and a side gate on (the ring's north half ends here)"),
}


# ---------------------------------------------------------------------------
# the church behind the crypt (the owner, 22 November: "we are going to put the ravenholm church in the crypt module
# (but not literally on top of the crypt; the crypt is between the church and the canal, with the exposed wall going
# into the canal, and then the crypt tunnel leads to the basement of the church)")
# ---------------------------------------------------------------------------

CHURCH_G = F + 256          # the churchyard's ground (656: the street's height beside a canal)
CHURCH_NF = CHURCH_G + 16   # the nave's floor, a step up from the yard
CHURCH_WT = CHURCH_NF + 384 # the nave's walls' top, where Valve's roof sits (1056)
CHURCH_TT = CHURCH_WT + 288 # the tower's top, where Valve's belfry sits (1344)
CHURCH_SKY = CHURCH_TT + 320  # the yard's own sky, over the belfry's cap (1664)
CHURCH_REACH = 2368         # how far the yard's wall stands from the canal's middle
PLASTER_OUT, PLASTER_IN = "plaster/plasterwall029a", "plaster/plasterwall042c"
PLINTH, YARD_WALL, NAVE_FLOOR = "stone/stonewall036b", "stone/stonewall036b", "wood/woodfloor005a"
DIRT, CELLAR_FLOOR, SCREEN, CROSS = "nature/dirtfloor005c", "stone/stonefloor006d_c17", "wood/woodwall006a", "wood/woodbeam001a"


def church(m, cz, ceil, tunnel_u):
    """Ravenholm's church, behind the crypt (called by m_crypt): Valve's church roof with its little octagonal lantern
    and Valve's belfry (the pieces valve_raven_roof_a and valve_raven_belfry_a, lifted from d1_town_03) on walls of
    Ravenholm's plaster over a stone plinth, 704 by 448 (the roof's own), standing in a walled churchyard with its own
    sky. Valve's church is only a shell (nobody goes in it in Half-Life 2); inside is ours, Russian Orthodox as the
    owner chose (21 November): an iconostasis (a wooden screen of icons, the Royal Doors in its middle) across the east
    end, the altar behind it under a three-bar cross with its lowest bar slanted, benches along the walls and no pews,
    hanging oil lamps and candles, light through the boarded windows. The front doors under the tower are boarded and
    never open; a side door (the city's own, that opens) lets out into the graveyard: gravestones scattered and turned,
    never in rows (Valve's), two dead trees, a stone wall round it. The tower stands at the west end through the roof,
    a ladder inside it up to the belfry's floor: a lookout. The way in is from the canal: the crypt's old stair at
    `tunnel_u` runs on as a tunnel under the yard into the church's basement (the Resistance's stores: crates, bedding,
    a radio; no cells, the owner said), and a stair climbs from the basement into the nave.
    Named for the game: lc_church_altar (an info_target before the iconostasis), lc_church_grigori (where Father Grigori
    stands while the Resistance holds the church: docs TODO), lc_church_side_door (the door to the graveyard).
    Left as brushes: the walls, plinth, floors, ceiling, the iconostasis's screen and the cross (no model of either).
    Unchecked: no bell exists among Half-Life 2's models (the belfry has none); the roof's underside is hidden by a flat
    ceiling; the look of the plaster's inside (plasterwall042c, the owner's map's); which way the benches and frames face.
    The lint's note on the front doors (a door model that does not open) is expected: they are boarded on purpose."""
    from map_prefab import place
    from map_mods_b import candle, mattress
    from map_town import door_hole
    from map_build import prism
    b = m.b
    G, NF, WT, TT, SKY = CHURCH_G, CHURCH_NF, CHURCH_WT, CHURCH_TT, CHURCH_SKY
    u1, u2, v1, v2 = 160, 864, 1280, 1728          # the nave's outside (the roof's 704 by 448)
    t = 32                                         # its walls' thickness
    tu1, tu2, tv1, tv2 = u1, u1 + 192, 1408, 1600  # the tower, at the west end, through the roof
    mid = (v1 + v2) // 2                           # 1504: the church's axis
    # --- the squares: the yard open to its own sky; the tunnel and the basement under it; the stair's well ---
    m.open(64, 1024, 960, CHURCH_REACH - 64, floor=G, mat=DIRT, sky=SKY)
    m.cellar(tunnel_u, 960, tunnel_u + 128, 1344, cz, ceil, G, mat=CELLAR_FLOOR, upper_mat=DIRT, sky=SKY)
    m.cellar(192, 1344, 832, 1664, cz, G, NF, mat=CELLAR_FLOOR, upper_mat=NAVE_FLOOR, sky=SKY)
    m.open(576, 1536, 832, 1664, floor=cz, mat=CELLAR_FLOOR, sky=SKY)            # the stair's well, open to the nave
    m.side(64, 960, 960, CHURCH_REACH)
    m.portal(tunnel_u, 1006, cz, tunnel_u + 128, 1008, ceil)                      # (the church is not drawn from the canal)
    # the nave's floor carried over the strips its basement leaves by the walls, and under the tower
    m.det([(u1 + t, v1 + t, G, 832, 1344, NF), (u1 + t, 1664, G, 832, v2 - t, NF)], CELLAR_FLOOR, top=NAVE_FLOOR)
    # --- the walls: plaster over a stone plinth, windows in the long walls, the doors ---
    def wall(a1, b1, a2, b2, gaps, along):
        """A wall from (a1, b1) to (a2, b2) (one of them t thick), G up to WT, with gaps (lo, hi, z_lo, z_hi) along it."""
        lo_a, hi_a = (a1, a2) if along == "u" else (b1, b2)
        cuts = sorted(gaps)
        boxes, p = [], lo_a
        for g0, g1, z0, z1 in cuts:
            if g0 > p:
                boxes.append((p, G, g0, WT))
            boxes.append((g0, G, g1, z0))
            boxes.append((g0, z1, g1, WT))
            p = g1
        if p < hi_a:
            boxes.append((p, G, hi_a, WT))
        out = []
        for c0, z0, c1, z1 in boxes:
            if z1 > z0 and c1 > c0:
                out.append((c0, b1, z0, c1, b2, z1) if along == "u" else (a1, c0, z0, a2, c1, z1))
        m.det(out, PLASTER_OUT, faces=None)
    wins = [(224, 272), (448, 496), (576, 624), (736, 784)]
    wz0, wz1 = NF + 112, NF + 272
    wall(u1, v1, u2, v1 + t, [(a, c, wz0, wz1) for a, c in wins], "u")                                        # the front (the crypt's side)
    wall(u1, v2 - t, u2, v2, [(a, c, wz0, wz1) for a, c in wins if a != 448] + [(352, 416, NF - 16, NF + 128)], "u")   # the back: the side door
    wall(u2 - t, v1 + t, u2, v2 - t, [(mid - 24, mid + 24, wz0 + 32, wz1 + 32)], "v")                              # the east end, a window over the altar
    wall(u1, v1 + t, u1 + t, v2 - t, [(mid - 48, mid + 48, NF - 16, NF + 160)], "v")                              # the west end: the front doors
    m.det([(u1 - 8, v1 - 8, G - 8, u2 + 8, v2 + 8, G + 48)], PLINTH)                                             # the plinth, proud of the walls
    m.det([(u1 - 4, v1 - 4, WT - 24, u2 + 4, v2 + 4, WT - 8)], "plaster/plasterwall029d")                        # a band under the eaves
    for a, c in wins:                                                                                            # stone sills
        m.det([(a - 4, v1 - 6, wz0 - 8, c + 4, v1 + t + 4, wz0 + 2)], PLINTH)
        if a != 448:
            m.det([(a - 4, v2 - t - 4, wz0 - 8, c + 4, v2 + 6, wz0 + 2)], PLINTH)
    # inside: two tones, a dado of the floor's wood to 112, plaster over it (City 18's interiors)
    m.det([(u1 + t, v1 + t, NF, u2 - t, v1 + t + 2, NF + 108), (u1 + t, v2 - t - 2, NF, 352, v2 - t, NF + 108), (416, v2 - t - 2, NF, u2 - t, v2 - t, NF + 108)], SCREEN)
    m.det([(u1 + t, v1 + t + 2, WT - 32, u2 - t, v2 - t - 2, WT - 16)], "wood/woodfloor005a")                  # the flat ceiling (Valve's roof is over it)
    # the doors: the front pair boarded shut; the side door the city's own, that opens
    m.static("models/props_c17/door02_double.mdl", u1 + 12, mid - 45, 0, NF)
    for k, (dz, roll) in enumerate(((40, 8), (92, -6), (140, 4))):
        m.static("models/props_debris/wood_board04a.mdl", u1 - 2, mid - 32 + k * 30, 90, NF + dz - 32, roll=90 + roll)
    door_hole(m, "u", 352, v2 - t, v2, NF, NF + 128, mat=SCREEN, name="lc_church_side_door", yaw=270)
    m.det([(336, v2, G, 432, v2 + 48, NF)], PLINTH, top=PLINTH)                                                 # a stone step out to the yard
    # boards over the outer windows, two to each (Ravenholm's boarded openings)
    for a, c in wins:
        for vv, yaw in ((v1 - 2, 0), (v2 + 2, 180)):
            if a == 448 and vv > mid:
                continue
            m.static("models/props_debris/wood_board04a.mdl", (a + c) // 2, vv, yaw, wz0 + 40, roll=80)
            m.static("models/props_debris/wood_board04a.mdl", (a + c) // 2, vv, yaw, wz0 + 104, roll=100)
    # --- the tower: walls up through the roof to Valve's belfry; inside, the porch and a ladder up ---
    m.det([(tu2 - t, tv1, NF + 160, tu2, tv2, TT)], PLASTER_OUT)                                                 # its east wall, over the arch into the nave
    m.det([(tu1, tv1, WT, tu2 - t, tv1 + t, TT), (tu1, tv2 - t, WT, tu2 - t, tv2, TT), (tu1, tv1 + t, WT, tu1 + t, tv2 - t, TT)], PLASTER_OUT)
    m.det([(tu1 + t, tv1, NF, tu2 - t, tv1 + t, WT), (tu1 + t, tv2 - t, NF, tu2 - t, tv2, WT)], PLASTER_IN)     # the porch's side walls
    m.det([(tu1 - 4, tv1 - 4, TT - 24, tu2 + 4, tv2 + 4, TT - 8)], "plaster/plasterwall029d")
    m.det([(tu1 + t, tv1 + t, TT - 16, tu2 - t - 48, tv2 - t, TT)], NAVE_FLOOR)                                  # the belfry's floor, the ladder's hole beside it
    place(m, "valve_raven_belfry_a", (tu1 + tu2) // 2, mid, TT, 0)
    place(m, "valve_raven_roof_a", (u1 + u2) // 2, mid, WT, 0)
    m.ladder(tu2 - t - 16, mid, NF, TT - 8, 180)
    m.lane((tu1 + tu2) // 2, mid, NF)
    m.lane((tu1 + tu2) // 2 - 24, mid, TT)
    m.view(tu1 + 60, mid, TT, 0, 10, "from the belfry")
    # --- inside the nave: the iconostasis, the altar and the cross, benches, lamps ---
    sc = 720                                                                                                    # the screen's face
    royal = (mid - 40, mid + 40)
    m.det([(sc, v1 + t, NF, sc + 16, royal[0], NF + 224), (sc, royal[1], NF, sc + 16, v2 - t, NF + 224),
           (sc, royal[0], NF + 176, sc + 16, royal[1], NF + 224)], SCREEN)
    m.det([(sc - 4, v1 + t, NF + 224, sc + 20, v2 - t, NF + 236)], CROSS)                                       # its cornice
    for row, z in ((0, NF + 80), (1, NF + 140)):                                                                # the icons, in two rows
        for vv in [1352, 1400, 1448] + [1560, 1608, 1656]:
            m.static("models/props_c17/frame002a.mdl", sc - 1, vv + (12 if row else 0), 180, z)
    m.det([(744, mid - 56, NF, 800, mid + 56, NF + 8)], PLINTH)                                                 # the altar's step
    m.static("models/lostcoast/props_monastery/altar.mdl", 776, mid, 180, NF + 8)
    for vv in (mid - 64, mid + 64):
        m.dynamic("models/lostcoast/props_monastery/candlestick.mdl", 776, vv, 180, NF + 8)
        m.glow(776, vv, NF + 112, "255 190 110", 0.12)
        m.light(776, vv, NF + 108, "255 170 90 12")
    cw, cx = 4, u2 - t - 2                                                                                      # the cross on the east wall
    m.det([(cx, mid - cw, NF + 132, cx + 2, mid + cw, NF + 260)], CROSS)                                        # (the bars stand 1 proud of the upright: no two faces in one plane)
    m.det([(cx - 1, mid - 20, NF + 236, cx + 1, mid + 20, NF + 242), (cx - 1, mid - 32, NF + 208, cx + 1, mid + 32, NF + 216)], CROSS)
    m.shapes([prism([(mid - 22, NF + 166), (mid + 22, NF + 182), (mid + 22, NF + 190), (mid - 22, NF + 174)], "x", cx - 1, cx + 1, CROSS)])
    m.spot(744, mid, WT - 40, "255 230 190 60", 0, pitch=40, cone=30)
    for k, uu in enumerate((288, 464, 624)):                                                                    # benches along the walls, no pews
        m.static("models/props_c17/bench01a.mdl", uu, v1 + t + 16, 90, NF)
        if uu != 464:
            m.static("models/props_c17/bench01a.mdl", uu, v2 - t - 16, 270, NF)
    for uu in (432, 560, 672):                                                                                  # oil lamps on chains from the ceiling
        m.static("models/lostcoast/props_monastery/hanging_oil_lamp.mdl", uu, mid, 0, WT - 32 - 56)
        m.light(uu, mid, WT - 100, "255 190 120 45")
    for (cu, cv, ch) in ((700, 1340, 6), (700, 1350, 9), (700, 1664, 7), (560, 1330, 5), (420, 1680, 8)):
        candle(m, cu, cv, NF, ch)
    for a, c in wins:                                                                                           # day through the boards
        if a in (224, 576):
            m.spot((a + c) // 2, v1 + t + 8, wz1 - 16, "200 215 235 70", 90, pitch=45, cone=35)
    m.target("lc_church_altar", 690, mid, NF, 0)
    m.target("lc_church_grigori", 640, mid - 96, NF, 180)
    m.blocked(sc - 16, v1 + t, u2 - t, v2 - t)
    m.blocked(240, v1 + t, 680, v1 + t + 40)
    m.blocked(240, v2 - t - 40, 680, v2 - t)
    for (uu, vv) in ((320, mid), (512, mid), (640, mid), (384, v2 - t - 48)):
        m.lane(uu, vv, NF)
    m.soundscape(SCAPES["house"], 512, mid, NF, radius=420)
    m.view(tu2 + 24, mid, NF, 0, 2, "the nave from the tower's arch: the iconostasis")
    m.view(690, mid - 120, NF, 0, 0, "the Royal Doors and the altar")
    # --- the basement: the stair up, the Resistance's stores ---
    m.steps(792, 1544, 1656, cz, NF, "u", -1)
    m.det([(576, 1536, NF, 832, 1544, NF + 40)], SCREEN)                                                        # a rail of boards round the well
    m.det([(578, 1537, cz, 830, 1543, NF - 8)], CELLAR_FLOOR)                                                   # its side, filled
    m.blocked(576, 1536, 832, 1664)
    m.lane(800, 1600, cz)
    m.lane(520, 1600, NF)
    things = [("models/props_junk/wood_crate001a.mdl", 236, 1388, 8), ("models/props_junk/wood_crate001a.mdl", 236, 1432, 82),
              ("models/props_junk/wood_crate002a.mdl", 284, 1390, 3), ("models/props_c17/furniturecupboard001a.mdl", 520, 1360, 90),
              ("models/props_lab/citizenradio.mdl", 404, 1360, 90)]
    for mdl, uu, vv, yaw in things:
        m.static(mdl, uu, vv, yaw, cz)
    m.static("models/props_junk/wood_crate001a.mdl", 236, 1410, 45, cz + 40)
    mattress(m, 300, 1600, 0, cz)
    mattress(m, 420, 1610, 6, cz)
    m.lamp(400, 1504, G - 8, "255 210 160 45")
    m.blocked(192, 1344, 320, 1460)
    for (uu, vv) in ((400, 1450), (640, 1400)):
        m.lane(uu, vv, cz)
    m.lane(tunnel_u + 64, 1100, cz)
    m.lane(tunnel_u + 64, 1300, cz)
    m.lamp(tunnel_u + 64, 1160, ceil - 8, "255 210 160 30")
    m.soundscape(SCAPES["tunnel"], 480, 1500, cz, radius=360)
    m.view(tunnel_u + 64, 980, cz, 90, 2, "the tunnel to the church")
    m.view(700, 1400, cz, 150, 4, "the church's basement: the stores, the stair up")
    # --- the churchyard: gravestones scattered and turned, two dead trees, a stone wall round it ---
    m.det([(64, 1024, G, 72, CHURCH_REACH - 64, G + 144), (952, 1024, G, 960, CHURCH_REACH - 64, G + 144),
           (72, 1024, G, 952, 1032, G + 144), (72, CHURCH_REACH - 72, G, 952, CHURCH_REACH - 64, G + 144)], YARD_WALL)
    stones = ["gravestone001a", "gravestone002a", "gravestone003a", "gravestone004a", "gravestone_cross001a", "gravestone_cross001b",
              "gravestone_coffinpiece001a", "gravestone_coffinpiece002a"]
    import random
    rnd = random.Random(4417)
    placed = [(260, 2060), (300, 2000), (836, 1180), (640, 2080), (100, 1100), (100, 1160)]      # (the trees and the statue: no stone inside them)
    spots = [(u, v) for u in range(120, 920, 72) for v in range(1800, CHURCH_REACH - 112, 72)] + \
            [(u, v) for u in range(120, 920, 96) for v in (1104, 1188)] + [(u, v) for u in (104, 920) for v in range(1300, 1760, 110)]
    rnd.shuffle(spots)
    for (u, v) in spots:
        if len(placed) >= 24:
            break
        if abs(u - 384) < 96 and v < 2000:          # (the path from the side door)
            continue
        if any(abs(u - a) < 60 and abs(v - c) < 60 for a, c in placed):
            continue
        su, sv = u + rnd.randint(-14, 14), v + rnd.randint(-14, 14)
        m.static("models/props_c17/%s.mdl" % stones[rnd.randrange(len(stones))], su, sv, 90 + rnd.randint(-25, 25) + (180 if rnd.random() < 0.15 else 0), G,
                 pitch=rnd.choice((0, 0, 0, 4, -6)), roll=rnd.choice((0, 0, 3, -5)))
        placed.append((u, v))
    m.static("models/props_c17/gravestone_statue001a.mdl", 640, 2080, 100, G)
    m.static("models/props_foliage/tree_dead02.mdl", 260, 2060, 30, G)
    m.static("models/props_foliage/tree_dead04.mdl", 836, 1180, 200, G)
    for (uu, vv) in ((384, 1800), (384, 2050), (640, 1900), (200, 1500), (920, 1500), (512, 1120)):
        m.lane(uu, vv, G)
    m.soundscape(SCAPES["courtyard"], 512, 2000, G, radius=600)
    m.view(384, 1780, G, 300, 6, "the graveyard from the side door")
    m.view(860, 2240, G, 150, 12, "the church from the graveyard's corner")
    m.view(100, 1100, G, 30, 14, "the church's front and its tower")
    b.notes.append("%s: the church: the yard's ground z %d, the nave's floor z %d, its basement's z %d; the tunnel from the crypt at u %d" % (m.tag, G, NF, cz, tunnel_u))
