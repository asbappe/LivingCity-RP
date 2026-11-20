#!/usr/bin/env python3
"""
Living City: canal modules, set D (the firing wall, the substation, the breach)

Run them through map_build.py; how a module is written: docs/dev/map-modules.md.
"""

from map_build import CELL, GATE_HIGH, MAT, octagon, prism
from map_modules import F, TRIM, MM, chain_link

CMB = "metal/metalcombine002"
DIRT = "nature/dirtfloor005c"


def m_execwall(m, opt):
    """The firing wall: where the Combine shoots people. A recess in the left wall under the open sky, its floor a
    slab 8 high: a row of concrete barriers along the back wall, the wall above them pocked with bullet holes and
    stained, three timber posts (the docks' poles) with a rope's end on each, a grating down the middle to the canal, a
    barrier at each front corner, one hard Combine floodlight in the back corner throwing its beam along the posts. The
    squad stands in the canal, behind a low kerb. Sober, not gory.
    Named for the game: lc_execwall_post_1 to _3 (at the posts, facing out), lc_execwall_line (where the squad stands,
    facing the wall), lc_execwall_lamp (the lamp's beam: LightOff, LightOn).
    Left as brushes: the slab, the grating, the kerb (the ground).
    Unchecked: the rope ends (move_rope), point_spotlight and light_spot keys; which way combine_light001b faces (its
    beam is the light_spot's, whichever way the model looks)."""
    m.open(0, -256, 768, 256)
    m.open(128, 256, 576, 448)
    m.no_bank(120, 248, 584, 456)
    z = F + 8
    m.det([(128, 256, F, 576, 448, z)], MAT["beam"], top=MAT["quay_floor"])
    m.det([(128, 240, F, 576, 256, F + 4)], MAT["beam"])
    # the backstop: concrete barriers along the back wall, the wall over them marked by what has hit it
    for u in (240, 352, 464):
        m.static("models/props_c17/concrete_barrier001a.mdl", u, 438, 90, z=z)
    pocks = [(266, 60), (300, 84), (252, 96), (380, 70), (398, 92), (364, 104), (410, 58), (500, 76), (522, 98), (488, 108), (346, 64), (470, 70), (286, 112), (430, 116)]
    for k, (u, h) in enumerate(pocks):
        m.decal("decals/concrete/shot%d" % (1 + k % 5), u - 30, 448, z + h)
    m.decal("decals/decalstain002a", 330, 448, z + 70)
    for k, u in enumerate((224, 352, 480)):
        m.static("models/props_docks/dock01_pole01a_128.mdl", u, 419, 0, z=z)
        m.rope([(u, 410, z + 70), (u + 4, 406, z + 40)], slack=8, width=1)
        m.target("lc_execwall_post_%d" % (k + 1), u, 400, z + 8, 270)
    # the grating to the canal, the kerb the squad stands behind
    m.det([(340, 250, z, 364, 412, z + 1)] + [(340, 256 + 20 * k, z + 1, 364, 258 + 20 * k, z + 2) for k in range(8)], MAT["bars"])
    m.det([(208, 28, F, 496, 36, F + 6)], MAT["beam"])
    m.target("lc_execwall_line", 352, 0, F + 8, 90)
    m.static("models/props_c17/concrete_barrier001a.mdl", 200, 290, 90, z=z)
    m.static("models/props_c17/concrete_barrier001a.mdl", 504, 290, 90, z=z)
    # one hard lamp: a Combine floodlight in the back corner, its beam along the posts
    m.static("models/props_combine/combine_light001b.mdl", 166, 396, 0, z=z)
    m.spot(172, 396, z + 66, "235 240 255 500", 0, pitch=10, cone=60, name="lc_execwall_lamp")
    m.decal("decals/decalstain002a", 352, 330, z + 1)
    m.decal("decals/decalstain002a", 268, 380, z + 1)
    m.taken(120, 232, F, 584, 256, F + 16)
    m.blocked(184, 400, 520, 448)
    for u, v in ((352, 300), (208, 340), (508, 340), (352, 100)):
        m.lane(u, v, z if v > 256 else F)
    m.view(352, -60, F, 90, 0, "from the squad's line")
    m.view(352, 380, z, 270, 0, "from the posts")
    m.view(640, 120, F, 150, 0, "from the side")


def m_substation(m, opt):
    """The substation: what powers the Combine's things in the canals. A concrete quay against the RIGHT wall, 128 high
    with steps up its upstream end, inside a fence of Nova Prospekt's chain link panels with a sliding gate (a panel
    of the same) players open by hand. On it three of the city's own substation transformers
    (substation_transformer01c), cables from them up to an arm on the wall and across the canal to an insulator on the
    far wall's top, a steel switch cabinet (controlroom_storagecloset001a) with the fuse panel on its front, a caged
    warning lamp on the wall over it, and a steady hum.
    The cabinet's panel is a func_breakable (40 health): breaking it fires the relay lc_substation_cut, which stops
    the hum, puts out the lamp and throws sparks: the game can hang more on it (dropping a checkpoint's force field).
    Named for the game: lc_substation_fuse (the panel), lc_substation_cut (the relay: Trigger; give it more wires),
    lc_substation_hum, lc_substation_lamp and lc_substation_glow, lc_substation_spark, lc_substation_gate (a func_door,
    unseen, the gate's panel riding on it).
    Left as brushes: the quay and its steps, the steel arm on the wall that carries the cables, the fuse panel (a
    func_breakable: the game needs a thing that breaks, and a model riding on it would outlive it).
    Unchecked: ambient/energy/electric_loop.wav, func_breakable's keys, the cables (move_rope); where on the
    transformers' tops their insulators are (the cables start at the middle of each top)."""
    b = m.b
    top, steel = F + 128, MM["steel"]
    m.open(0, -256, 1024, 256)
    m.open(256, -256, 832, -64, floor=top, mat=MAT["quay_floor"])
    m.side(256, -256, 832, -64)
    m.no_bank(56, -264, 840, -56)
    m.steps(64, -256, -192, F, top, "u", 1)
    m.det([(64, -196, F, 256, -192, F + 8)], MAT["beam"])
    m.blocked(56, -256, 256, -180)
    m.lane(48, -224, F)
    m.lane(280, -224, top)
    # the fence round the quay (Nova Prospekt's panels), and its gate at the head of the steps: a panel that slides
    # along behind the fence's first panel
    from map_mods_c import panel_fence, ride
    panel_fence(m, (256, -66), (832, -66), top)
    panel_fence(m, (830, -256), (830, -64), top)
    panel_fence(m, (258, -192), (258, -64), top)
    b.vmf.brush_entity("func_door", {"targetname": "lc_substation_gate", "movedir": "0 %d 0" % m.fr.yaw(90), "speed": "60", "lip": "4", "wait": "-1", "spawnflags": "288",
                                     "spawnpos": "0", "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0",
                                     "noise1": "MetalGrate.ScrapeSmooth", "noise2": "MetalGrate.ImpactSoft", "renderamt": "0", "rendercolor": "255 255 255",
                                     "renderfx": "0", "rendermode": "10", "disableshadows": "1"}, [m.fr.box(252, -256, top, 256, -192, top + 128)], MAT["nodraw"], m.dv)
    b.names.append(("lc_substation_gate", "func_door", m.tag))
    ride(m, "lc_substation_gate", "models/props_wasteland/interior_fence002b.mdl", 254, -224, 0, top)
    # three transformers (the city's own), a cable from each up to the arm on the wall
    arm_z = b.rim - 48
    m.det([(380, -256, arm_z, 780, -248, arm_z + 8)] + [(u, -256, arm_z - 40, u + 8, -200, arm_z) for u in (380, 772)] + [(380, -208, arm_z - 8, 780, -200, arm_z)], MAT["bars"])
    for k, u in enumerate((440, 580, 720)):
        m.static("models/props_c17/substation_transformer01c.mdl", u, -190, 0, z=top)
        m.rope([(u, -190, top + 154), (u, -204, arm_z - 4)], slack=10, width=1)
        m.blocked(u - 56, -232, u + 56, -148)
    m.rope([(400, -204, arm_z - 4), (780, -204, arm_z - 4)], slack=12, width=1)
    m.rope([(580, -204, arm_z), (600, 250, b.rim - 16)], slack=70, width=1)                 # the feed, across the canal
    m.static("models/props_c17/utilityconnecter006.mdl", 600, 254, 90, z=b.rim - 20)        # (an insulator on the far wall, under its top)
    # the switch cabinet, its panel, the lamp
    m.static("models/props_wasteland/controlroom_storagecloset001a.mdl", 320, -238, 90, z=top)
    b.vmf.brush_entity("func_breakable", {"targetname": "lc_substation_fuse", "health": "40", "material": "2", "spawnflags": "0", "explosion": "0", "gibdir": "0 0 0",
                                          "nodamageforces": "0", "pressuredelay": "0", "spawnobject": "0", "explodemagnitude": "0", "physdamagescale": "1.0",
                                          "PerformanceMode": "0", "propdata": "0", "minhealthdmg": "0", "disablereceiveshadows": "0", "renderamt": "255",
                                          "rendercolor": "255 255 255"}, [m.fr.box(300, -221, top + 30, 340, -217, top + 70)], CMB, m.dv,
                         connections=[("OnBreak", "lc_substation_cut", "Trigger", "", 0)])
    b.names.append(("lc_substation_fuse", "func_breakable", m.tag))
    m.relay("lc_substation_cut", 320, -238, top + 110, [("lc_substation_hum", "StopSound", "", 0), ("lc_substation_lamp", "TurnOff", "", 0),
                                                         ("lc_substation_glow", "HideSprite", "", 0), ("lc_substation_spark", "StartSpark", "", 0),
                                                         ("lc_substation_spark", "StopSpark", "", 6)])
    m.spark(320, -220, top + 60, name="lc_substation_spark")
    m.sound("ambient/energy/electric_loop.wav", 580, -190, top + 60, radius=800, volume=6, name="lc_substation_hum")
    m.static("models/props_c17/light_cagelight02_on.mdl", 303, -255, 90, z=top + 136)
    m.point("light", 303, -240, top + 144, {"targetname": "lc_substation_lamp", "_light": "255 150 40 60", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0",
                                            "spawnflags": "0"}, m.lv)
    m.point("env_sprite", 303, -240, top + 146, {"targetname": "lc_substation_glow", "model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "220",
                                                 "rendercolor": "255 150 40", "scale": "0.3", "framerate": "10.0", "GlowProxySize": "2.0", "HDRColorScale": "1.0",
                                                 "renderfx": "0", "spawnflags": "1"}, m.lv)
    m.test_button((352, -236, top + 100, 360, -228, top + 116), [("OnIn", "lc_substation_cut", "Trigger")])
    m.static("models/props_c17/oildrum001.mdl", 790, -100, 0, z=top)
    m.taken(256, -256, F, 832, -64, b.rim)
    for u, v in ((330, -120), (520, -110), (760, -150)):
        m.lane(u, v, top)
    m.view(120, 60, F, 325, -12, "from the canal")
    m.view(300, -110, top, 350, 0, "inside the fence")
    m.view(900, 120, F, 205, -10, "from downstream")


def m_breach(m, opt):
    """The breach: the canal's floor has fallen into an old cellar. A pit 640 by 256 and 160 deep in the middle of
    the canal, its bottom earth with standing water. Two slabs of the old floor lean down into it along its sides as
    ramps (one from each end); a third still hangs over the downstream end on two old timber poles and makes a dark
    undercut where things are kept; reinforcing bars stick out of the broken edge, rubble lies at the bottom. The
    canal's banks pass either side, so nobody has to go down.
    Named for the game: lc_breach_bottom (the middle of the pit), lc_breach_stash (under the hanging slab).
    Left as brushes: the pit and the three slabs of fallen floor (the ground itself).
    Unchecked: the look of it; the rebar is stood on its side (pitch 90), centred on its origin so it stays where it is
    put."""
    deep = F - 160      # (16 over the bottom of everything)
    m.open(0, -256, 1024, 256)
    m.open(192, -128, 832, 128, floor=deep, mat=DIRT)
    m.side(192, -128, 832, 128)
    slab = MAT["canal_floor"]
    m.shapes([prism([(192, F), (476, deep), (448, deep), (192, F - 22)], "y", -128, -48, slab),            # a ramp down from the upstream end
              prism([(832, F), (832, F - 22), (576, deep), (548, deep)], "y", 48, 128, slab),               # ...and one from the downstream end
              prism([(640, F), (832, F), (832, F - 18), (640, F - 30)], "y", -48, 48, slab)])               # the slab still hanging
    for v in (-43, 43):                                                                                     # two old poles still holding it up
        m.static("models/props_docks/dock01_pole01a_128.mdl", 641, v, 0, z=deep)
    for k, (v, h, model) in enumerate(((-36, 34, "rebar002c_64"), (-8, 46, "rebar001c_64"), (18, 30, "rebar004c_64"), (44, 40, "rebar002c_64"))):
        m.point("prop_static", 200, v, F - h, {"model": "models/props_debris/%s.mdl" % model, "angles": "90 %d 0" % m.fr.yaw(10 * k - 15), "skin": "0", "solid": "0",
                                                "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, m.pv)
    m.water(290, -44, 440, 44, deep, deep + 5)
    m.static("models/props_debris/concrete_chunk01a.mdl", 520, -90, 40, z=deep)
    m.static("models/props_debris/concrete_chunk02a.mdl", 500, 20, 110, z=deep)
    m.static("models/props_debris/broken_pile001a.mdl", 250, 80, 200, z=deep)
    m.loose("models/props_junk/wood_crate001a.mdl", 760, -14, 20, z=deep)
    m.loose("models/props_junk/wood_crate002a.mdl", 790, 30, 70, z=deep)
    m.light(730, 0, deep + 70, "255 190 120 14")
    m.target("lc_breach_bottom", 512, 0, deep + 8)
    m.target("lc_breach_stash", 730, 0, deep + 8, 180)
    m.decal("decals/decalstain002a", 120, 0, F + 1)
    m.blocked(192, -128, 832, 128)
    for u, v, z in ((334, -88, F - 80), (690, 88, F - 80), (512, -10, deep), (700, 0, deep), (512, 190, F), (512, -190, F)):
        m.lane(u, v, z)
    m.view(80, 0, F, 0, 14, "at the edge")
    m.view(330, 0, deep, 0, -6, "from the bottom")
    m.view(940, 60, F, 190, 16, "from downstream")


def use_door(m, name, box, mat, yaw, speed=70, unseen=False):
    """A door that slides aside when a player uses it (and when the game tells it to), back again on the next use.
    unseen: the brush is not drawn (it blocks, slides and takes the Use; a model rides on it: map_mods_c.ride)."""
    m.b.vmf.brush_entity("func_door", {"targetname": name, "movedir": "0 %d 0" % m.fr.yaw(yaw), "speed": str(speed), "lip": "6", "wait": "-1", "spawnflags": "288",
                                       "spawnpos": "0", "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0",
                                       "noise1": "Doors.Move5", "noise2": "Doors.FullClose5", "renderamt": "0" if unseen else "255", "rendercolor": "255 255 255",
                                       "renderfx": "0", "rendermode": "10" if unseen else "0", "disableshadows": "1"}, [m.fr.box(*box)],
                         MAT["nodraw"] if unseen else mat, m.dv)
    m.b.names.append((name, "func_door", m.tag))


def m_tunnel(m, opt):
    """The canal under the city: a covered stretch of any length ("tunnel 1536"), for passing under streets and
    buildings. A raised kerb walk along each wall, roof beams, the city's pipe (pipeset32d) along the right wall,
    capped at both ends, a dim dome lamp every 256 on one side then the other.
    Left as brushes: the kerbs and the roof beams (the tunnel itself)."""
    L = m.fr.length
    roof = F + GATE_HIGH
    m.low(0, -256, L, 256, roof)
    m.portal(62, -256, F, 64, 256, roof)
    if L > 256:
        m.portal(L - 64, -256, F, L - 62, 256, roof)
    m.det([(0, -256, F, L, -208, F + 14), (0, 208, F, L, 256, F + 14)], MAT["beam"], top=MAT["quay_floor"])
    m.det([(u, -256, roof - 24, u + 16, 256, roof) for u in range(120, L - 60, 256)], MAT["beam"])
    from map_mods_c import pipe_run
    p2 = 64 + (L - 128) // 128 * 128                     # (the pipe in 128s, 64 in from each end, a cap on each end)
    if p2 > 64:
        pipe_run(m, (64, -236), (p2, -236), F + 170, "32d")
        m.static("models/props_c17/pipe_cap005.mdl", 64, -236, 180, z=F + 151)
        m.static("models/props_c17/pipe_cap005.mdl", p2, -236, 0, z=F + 151)
    for k, u in enumerate(range(128, L - 60, 256)):
        m.lamp(u, 214 if k % 2 else -214, roof - 32, "255 210 150 45")     # (its dome against the roof beam over it)
    m.sound("ambient/atmosphere/tunnel1.wav", L // 2, 0, F + 120, radius=900, volume=3)
    for u in range(96, L - 60, 192):
        m.lane(u, 232, F + 14)
    m.view(100, 0, F, 0, 0, "inside")


def m_wreck(m, opt):
    """The wreck: a Combine dropship's troop container has come down in the canal and lies on its belly: Episode One's
    own wrecked container (combine_dropship_container_static, 415 long, hollow: its collision is the hull's own), a
    dim red glow still on inside. Earth thrown up round its nose, sparks, thin smoke, its cargo scattered down the
    canal. A thing to race for: the Combine to recover it, the Resistance to strip it.
    Named for the game: lc_wreck_cache (inside, at its middle), lc_wreck_beacon (the red lamp's glow: HideSprite),
    lc_wreck_spark (StopSpark).
    Left as brushes: nothing (the earth round its nose is the ground's own bumps).
    Unchecked: env_spark, env_smokestack. The container is Episode One's (players need Episode One's content, as for
    every Episode One model); whether its door end is open and players can get in, and which end is its nose (it is
    laid with its long side along the canal; its size is read, its shape is not)."""
    b = m.b
    m.open(0, -256, 1024, 256)
    a, c = 300, 715                                  # its two ends along the canal (the model's box: 244 behind its origin, 171 before)
    m.static("models/combine_dropship_container_static.mdl", a + 244, -3, 0, z=F)
    cx, cy = m.fr.pt(c + 10, 0)
    b.bumps.append(lambda x, y: 46 * max(0.0, 1 - abs(((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 - 110) / 80.0))        # a ring of thrown earth round the nose
    m.point("env_sprite", 500, 0, F + 70, {"targetname": "lc_wreck_beacon", "model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "200",
                                              "rendercolor": "255 40 30", "scale": "0.25", "framerate": "10.0", "GlowProxySize": "2.0", "HDRColorScale": "1.0",
                                              "renderfx": "0", "spawnflags": "1"}, m.lv)
    m.light(470, 0, F + 60, "255 60 40 22")
    m.spark(c + 2, 30, F + 60, name="lc_wreck_spark")
    m.smoke(c + 20, -10, F + 90, colour="50 50 55", size=12, length=240, rate=7)
    m.target("lc_wreck_cache", 520, 0, F + 10, 180)
    for u, v, yaw in ((120, 100, 30), (200, -96, 80), (840, 110, 10), (900, -60, 55), (780, -104, 0)):       # (on the floor, off the banks)
        m.loose("models/props_junk/wood_crate001a.mdl", u, v, yaw)
    m.loose("models/props_debris/concrete_chunk01a.mdl", c + 90, 110, 40, z=F + 30)       # (loose: they settle on the thrown earth)
    m.loose("models/props_debris/concrete_chunk02a.mdl", c + 110, -100, 110, z=F + 30)
    m.decal("decals/decalstain002a", 500, 150, F + 1)
    m.blocked(a - 20, -70, c + 150, 70)
    m.taken(a - 20, -70, F, c + 20, 70, F + 220)
    for u, v in ((240, 0), (500, 160), (500, -160), (860, 0)):
        m.lane(u, v)
    m.view(60, 80, F, 350, 0, "coming up to it")
    m.view(a - 120, 0, F, 0, -4, "its tail")
    m.view(900, 120, F, 200, 0, "its nose")


def m_morgue(m, opt):
    """The morgue: where the city's dead wait for the cremator. A sliding steel door in the left wall (Nova Prospekt's
    sliding door between steel jambs: players open it by hand), a short passage, a tiled cold room: a wall of twelve
    drawers, two pulled out, three steel tables (the hospital's surgery tables), a drain in the floor, a clerk's desk
    with the ledger and a clipboard on it, cold lamps, a caged lamp over the door outside, a hum. The dead on the tables
    are props.
    Named for the game: lc_morgue_door (a func_door, unseen, the door's model riding on it), lc_morgue_table_1 to _3
    (the tables), lc_morgue_ledger (the desk).
    Left as brushes: the room, the door's jambs and head, the drain, and the wall of drawers (built into the wall:
    Half-Life 2 has no morgue drawers).
    Unchecked: models/humans/corpse1.mdl as a ragdoll lying on a table (it may slide off), ambient/machines/...; which
    way the surgery table's head is (it is the same both ways in its size)."""
    tile, steel = "tile/tilefloor018a_c17", MM["steel"]
    m.open(0, -256, 1024, 256)
    m.low(448, 256, 576, 384, F + 128, mat=tile)
    m.low(256, 384, 768, 768, F + 176, mat=tile)
    m.side(256, 256, 768, 768)
    from map_mods_c import ride
    m.det([(448, 304, F, 455, 336, F + 128), (569, 304, F, 576, 336, F + 128), (455, 304, F + 120, 569, 336, F + 128)], steel)
    use_door(m, "lc_morgue_door", (455, 314, F, 569, 326, F + 120), steel, 0, unseen=True)
    ride(m, "lc_morgue_door", "models/props_wasteland/prison_slidingdoor001a.mdl", 512, 320, 90, F)
    m.portal(448, 319, F, 576, 321, F + 128)
    m.det([(436, 244, F, 448, 256, F + 140), (576, 244, F, 588, 256, F + 140), (436, 244, F + 128, 588, 256, F + 140)], MAT["beam"])
    m.taken(428, 232, F, 596, 256, F + 160)
    m.static("models/props_c17/light_cagelight02_on.mdl", 512, 255, 270, z=F + 146)
    m.light(512, 240, F + 152, "200 225 255 40")
    # the drawers: three high and four along the back wall, two of them pulled out
    fronts = []
    for i in range(4):
        for k in range(3):
            u, z = 300 + 110 * i, F + 8 + 50 * k
            out = (i, k) in ((1, 0), (3, 1))
            v2 = 768 - (84 if out else 0)
            fronts.append((u, v2 - 6, z, u + 96, v2, z + 44))
            fronts.append((u + 40, v2 - 10, z + 18, u + 56, v2 - 6, z + 24))
            if out:
                fronts.append((u + 6, v2, z + 4, u + 90, 768, z + 10))
    m.det(fronts, steel)
    m.det([(288, 764, F + 158, 752, 768, F + 164), (288, 764, F, 752, 768, F + 8)], MAT["beam"])
    # three tables, the dead on two of them
    for k, (u, v) in enumerate(((340, 520), (512, 520), (684, 520))):
        m.static("models/props_c17/hospital_surgerytable01.mdl", u, v, 90)
        m.target("lc_morgue_table_%d" % (k + 1), u, v, F + 40)
        if k != 1:
            m.body("models/humans/corpse1.mdl", u, v, 90, z=F + 30)
        m.blocked(u - 34, v - 68, u + 34, v + 68)
    m.det([(500, 600, F, 524, 624, F + 1)] + [(500 + 5 * k, 600, F + 1, 502 + 5 * k, 624, F + 2) for k in range(5)], MAT["bars"])
    m.static("models/props_wasteland/controlroom_desk001a.mdl", 320, 420, 90)
    m.static("models/props_lab/binderblue.mdl", 330, 430, 100, z=F + 34)
    m.static("models/props_lab/clipboard.mdl", 300, 410, 80, z=F + 34)
    m.static("models/props_wasteland/controlroom_chair001a.mdl", 300, 470, 270)
    m.target("lc_morgue_ledger", 320, 440, F + 36, 270)
    for u, v in ((384, 600), (640, 600), (512, 440)):
        m.lamp(u, v, F + 150, "190 220 255 45", hang=18)
    m.sound("ambient/atmosphere/tunnel1.wav", 512, 560, F + 80, radius=500, volume=3)
    m.decal("decals/decalstain002a", 512, 612, F + 1)
    for u, v in ((512, 300), (512, 420), (430, 640), (600, 640)):
        m.lane(u, v)
    m.view(512, 120, F, 90, 0, "the door")
    m.view(512, 400, F, 90, 0, "the cold room")
    m.view(290, 700, F, 330, 0, "the drawers")


MODULES = {
    "execwall": (768, m_execwall, "the firing wall: a backstop, three posts, one hard lamp (left)"),
    "substation": (1024, m_substation, "the substation: transformers behind chain link, a fuse panel to break (right)"),
    "breach": (1024, m_breach, "the breach: the floor fallen into an old cellar, slabs for ramps, an undercut"),
    "tunnel": (1024, m_tunnel, "the canal under the city: a covered stretch of any length (\"tunnel 1536\")", {"stretch": True}),
    "wreck": (1024, m_wreck, "the wreck: a Combine carrier's container down in the canal, hollow, to race for"),
    "morgue": (1024, m_morgue, "the morgue: a cold room of drawers and tables behind a sliding door (left)"),
}
