#!/usr/bin/env python3
"""
Living City: canal modules, set D (the firing wall, the substation, the breach)

Run them through map_build.py; how a module is written: docs/dev/map-modules.md.
"""

import math

from map_build import CELL, GATE_HIGH, MAT, octagon, prism
from map_modules import F, TRIM, MM, SCAPES, chain_link

CMB = "metal/metalcombine002"
DIRT = "nature/dirtfloor005c"


def m_execwall(m, opt):
    """The firing wall: where the Combine shoots people. A recess in the left wall under the open sky, its floor a
    slab 8 high: a row of concrete barriers along the back wall, the wall above them pocked with bullet holes and
    stained, three timber posts (the docks' poles) with a rope's end on each, a grating down the middle to the canal, a
    barrier at each front corner, one hard Combine floodlight in the back corner throwing its beam along the posts, two
    of the Combine's wall lights over the barriers. The Combine's marks: a loudspeaker high on the back wall to read the
    sentence, a camera over the recess, Breen's poster on the side wall facing the posts, a number stencilled on the
    wall. What is left behind, still sober: a dark stain at the grating, a shoe, a dropped ration bag, a candle someone
    lit at night. The squad stands in the canal, behind a yellow line painted on its floor. Silent but for the
    floodlight's hum and the wind (the soundscape "Nothing", as the owner's map uses it).
    Named for the game: lc_execwall_post_1 to _3 (at the posts, facing out), lc_execwall_line (where the squad stands,
    facing the wall), lc_execwall_lamp (the lamp's beam: LightOff, LightOn).
    Left as brushes: the slab, the grating, the painted line (dev_hazzardstripe01a, 1 high, as the owner's map paints
    its edges), the candle (no model of one).
    Unchecked: the rope ends (move_rope), point_spotlight and light_spot keys; which way combine_light001b,
    speakercluster01a and combinecamera001 face (their fronts taken as the models' +x); ambient/machines/
    combine_terminal_loop1.wav for the floodlight's hum."""
    m.open(0, -256, 768, 256)
    m.open(128, 256, 576, 448)
    m.no_bank(120, 248, 584, 456)
    m.side(128, 256, 576, 448)                                                    # (no mud on the slab)
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
    m.det([(208, 28, F, 496, 36, F + 1)], "dev/dev_hazzardstripe01a")             # (a line painted on the floor, not a kerb to trip on)
    m.side(208, 0, 496, 64)
    m.target("lc_execwall_line", 352, 0, F + 8, 90)
    m.static("models/props_c17/concrete_barrier001a.mdl", 200, 290, 90, z=z)
    m.static("models/props_c17/concrete_barrier001a.mdl", 504, 290, 90, z=z)
    # one hard lamp: a Combine floodlight in the back corner, its beam along the posts
    m.static("models/props_combine/combine_light001b.mdl", 166, 396, 0, z=z)
    m.spot(172, 396, z + 66, "235 240 255 500", 0, pitch=10, cone=60, name="lc_execwall_lamp")
    m.decal("decals/decalstain002a", 352, 330, z + 1)
    m.decal("decals/decalstain002a", 268, 380, z + 1)
    m.decal("decals/decalstain002a", 352, 262, z + 1)                             # (dark at the grating's mouth)
    # the Combine's marks: the loudspeaker, the camera, two wall lights, Breen's poster facing the posts, a number
    from map_mods_c import combine_lamp
    m.static("models/props_wasteland/speakercluster01a.mdl", 352, 432, 270, z=z + 196)
    m.static("models/props_combine/combinecamera001.mdl", 560, 440, 225, z=z + 230)
    for u in (296, 408):
        combine_lamp(m, u, 448, z + 110, 270, "147 226 240 40")
    m.decal("decals/decal_posterbreen", 576, 360, z + 96)
    m.grime("number", 128, 400, z + 150, 1)
    # what is left behind: a shoe, a dropped ration bag, a candle someone lit at night
    m.loose("models/props_junk/shoe001a.mdl", 300, 340, 40, z=z)
    m.dynamic("models/weapons/w_package.mdl", 420, 320, 110, z=z, solid=False)
    from map_mods_b import candle
    candle(m, 240, 400, z, high=5)
    m.sound("ambient/machines/combine_terminal_loop1.wav", 166, 396, z + 60, radius=500, volume=3)
    m.soundscape("Nothing", 352, 300, z, radius=500)
    m.taken(120, 232, F, 584, 256, F + 16)
    m.blocked(184, 400, 520, 448)
    for u, v in ((352, 300), (208, 340), (508, 340), (352, 100)):
        m.lane(u, v, z if v > 256 else F)
    m.view(352, -60, F, 90, 0, "from the squad's line")
    m.view(352, 380, z, 270, 0, "from the posts")
    m.view(640, 120, F, 150, 0, "from the side")


def m_substation(m, opt):
    """The substation: what powers the Combine's things in the canals. A concrete quay against the RIGHT wall, 128 high
    with steps up its upstream end; along its front, set back from the edge, the Combine's own fence (combine_fence01b
    and 01a posts, the owner's field between them), and at the steps' head a sliding gate (a chain link panel in a
    short run of Nova Prospekt's fence) players open by hand. Inside, a yard: three of the city's own substation
    transformers (substation_transformer01c) back against the wall, a danger sign over each, cables from them up to an
    arm on the wall and across the canal to an insulator on the far wall's top (where a street runs along the far bank,
    which has no wall top, to one on the yard's own wall's top), a steel switch cabinet (controlroom_storagecloset001a) with the fuse panel on its front and the Combine's meter box beside it, a caged
    warning lamp on the wall over it, two of the Combine's lights on the wall, danger signs on the quay's face, a steady
    hum. The cabinet's panel is a func_breakable (40 health): breaking it fires the relay lc_substation_cut, which stops
    the hum, puts out the lamps (the warning lamp and the Combine's lights), throws sparks from the panel and from each
    transformer's top and lets a wisp of smoke rise: the game can hang more on it (dropping a checkpoint's force field).
    Named for the game: lc_substation_fuse (the panel), lc_substation_cut (the relay: Trigger; give it more wires),
    lc_substation_hum, lc_substation_lamp and lc_substation_glow, lc_substation_spark, lc_substation_gate (a func_door,
    unseen, the gate's panel riding on it), lc_substation_spark_t1 to _t3 (the transformers' sparks), lc_substation_smoke
    (TurnOn), lc_substation_light_1 and _2 (the Combine's lights: TurnOff).
    Left as brushes: the quay and its steps, the steel arm on the wall that carries the cables, the fuse panel (a
    func_breakable: the game needs a thing that breaks, and a model riding on it would outlive it).
    Unchecked: ambient/energy/electric_loop.wav, func_breakable's keys, the cables (move_rope); where on the
    transformers' tops their insulators are (the cables start at the middle of each top); combine_shield_loop3.wav."""
    b = m.b
    top, steel = F + 128, MM["steel"]
    m.open(0, -256, 1024, 256)
    m.open(256, -256, 832, -64, floor=top, mat=MAT["quay_floor"])
    m.side(256, -256, 832, -64)
    m.no_bank(56, -264, 840, -56)
    m.steps(64, -256, -192, F, top, "u", 1)
    m.det([(65, -196, F, 256, -193, F + 8)], MAT["beam"])      # (1 inside the steps: no face in their planes)
    m.det([(16, -256, F, 64, -192, F + 2)], MAT["canal_wall"], top=MAT["quay_floor"])     # a worn apron at their foot (the mud kept level there)
    m.blocked(56, -256, 256, -180)
    m.lane(48, -224, F)
    m.lane(280, -224, top)
    # the fence round the quay (Nova Prospekt's panels), and its gate at the head of the steps: a panel that slides
    # along behind the fence's first panel
    from map_mods_c import combine_field, combine_lamp, named_light, panel_fence, ride
    combine_field(m, (272, -80), (548, -80), top)
    combine_field(m, (556, -80), (824, -80), top, hum=False)
    combine_field(m, (812, -96), (812, -248), top, hum=False)
    panel_fence(m, (258, -192), (258, -64), top)
    b.vmf.brush_entity("func_door", {"targetname": "lc_substation_gate", "movedir": "0 %d 0" % m.fr.yaw(90), "speed": "60", "lip": "4", "wait": "-1", "spawnflags": "288",
                                     "spawnpos": "0", "dmg": "0", "forceclosed": "0", "health": "0", "ignoredebris": "0", "loopmovesound": "0",
                                     "noise1": "MetalGrate.ScrapeSmooth", "noise2": "MetalGrate.ImpactSoft", "renderamt": "0", "rendercolor": "255 255 255",
                                     "renderfx": "0", "rendermode": "10", "disableshadows": "1"}, [m.fr.box(252, -256, top, 256, -192, top + 128)], MAT["nodraw"], m.dv)
    b.names.append(("lc_substation_gate", "func_door", m.tag))
    ride(m, "lc_substation_gate", "models/props_wasteland/interior_fence002b.mdl", 254, -224, 0, top)
    # three transformers (the city's own), a cable from each up to the arm on the wall
    arm_z = b.rim - 48
    m.det([(380, -256, arm_z, 780, -248, arm_z + 8)] + [(u, -256, arm_z - 40, u + 8, -201, arm_z - 1) for u in (380, 772)] + [(382, -208, arm_z - 8, 778, -200, arm_z)], MAT["bars"])
    for k, u in enumerate((460, 600, 740)):
        m.static("models/props_c17/substation_transformer01c.mdl", u, -218, 0, z=top)
        m.rope([(u, -218, top + 154), (u, -206, arm_z - 4)], slack=10, width=1)
        m.blocked(u - 56, -256, u + 56, -176)
        m.grime("danger", u, -256, top + 176, k)
        m.spark(u, -218, top + 156, name="lc_substation_spark_t%d" % (k + 1))
    m.rope([(400, -204, arm_z - 4), (780, -204, arm_z - 4)], slack=12, width=1)
    if m.street_side() == 1:      # (a street along the far bank: no wall top there to take it, so the feed comes in over the yard's own wall)
        m.rope([(580, -204, arm_z), (600, -250, b.rim - 16)], slack=20, width=1)
        m.static("models/props_c17/utilityconnecter006.mdl", 600, -254, 270, z=b.rim - 20)
    else:
        m.rope([(580, -204, arm_z), (600, 250, b.rim - 16)], slack=70, width=1)             # the feed, across the canal
        m.static("models/props_c17/utilityconnecter006.mdl", 600, 254, 90, z=b.rim - 20)    # (an insulator on the far wall, under its top)
    # the switch cabinet, its panel, the lamp
    m.static("models/props_wasteland/controlroom_storagecloset001a.mdl", 320, -238, 90, z=top)
    m.static("models/props_combine/combine_interface002.mdl", 372, -228, 90, z=top)
    b.vmf.brush_entity("func_breakable", {"targetname": "lc_substation_fuse", "health": "40", "material": "2", "spawnflags": "0", "explosion": "0", "gibdir": "0 0 0",
                                          "nodamageforces": "0", "pressuredelay": "0", "spawnobject": "0", "explodemagnitude": "0", "physdamagescale": "1.0",
                                          "PerformanceMode": "0", "propdata": "0", "minhealthdmg": "0", "disablereceiveshadows": "0", "renderamt": "255",
                                          "rendercolor": "255 255 255"}, [m.fr.box(300, -221, top + 30, 340, -217, top + 70)], CMB, m.dv,
                         connections=[("OnBreak", "lc_substation_cut", "Trigger", "", 0)])
    b.names.append(("lc_substation_fuse", "func_breakable", m.tag))
    m.relay("lc_substation_cut", 320, -238, top + 110, [("lc_substation_hum", "StopSound", "", 0), ("lc_substation_lamp", "TurnOff", "", 0),
                                                         ("lc_substation_glow", "HideSprite", "", 0), ("lc_substation_spark", "StartSpark", "", 0),
                                                         ("lc_substation_spark", "StopSpark", "", 6), ("lc_substation_spark_t*", "StartSpark", "", 0.3),
                                                         ("lc_substation_spark_t*", "StopSpark", "", 5), ("lc_substation_smoke", "TurnOn", "", 0.5),
                                                         ("lc_substation_light_*", "TurnOff", "", 0.2)])
    m.point("env_smokestack", 600, -218, top + 160, {"targetname": "lc_substation_smoke", "InitialState": "0", "BaseSpread": "10", "SpreadSpeed": "8", "Speed": "20",
                                                     "StartSize": "12", "EndSize": "40", "Rate": "8", "JetLength": "160", "WindAngle": "0", "WindSpeed": "0",
                                                     "SmokeMaterial": "particle/SmokeStack.vmt", "twist": "4", "roll": "4", "rendercolor": "70 70 70", "renderamt": "120",
                                                     "angles": "0 0 0"})
    for k, u in enumerate((530, 670)):
        m.static("models/props_combine/combine_light002a.mdl", u, -246, 90, z=top + 120)
        named_light(m, "lc_substation_light_%d" % (k + 1), u, -228, top + 140, "147 226 240 50")
    for k, u in enumerate((400, 620)):
        m.grime("danger", u, -64, F + 70, 10 + k)
    m.spark(320, -220, top + 60, name="lc_substation_spark")
    m.sound("ambient/energy/electric_loop.wav", 580, -190, top + 60, radius=800, volume=6, name="lc_substation_hum")
    m.static("models/props_c17/light_cagelight02_on.mdl", 303, -255, 90, z=top + 136)
    m.point("light", 303, -240, top + 144, {"targetname": "lc_substation_lamp", "_light": "255 150 40 60", "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0",
                                            "spawnflags": "0"}, m.lv)
    m.point("env_sprite", 303, -240, top + 146, {"targetname": "lc_substation_glow", "model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "220",
                                                 "rendercolor": "255 150 40", "scale": "0.3", "framerate": "10.0", "GlowProxySize": "2.0", "HDRColorScale": "1.0",
                                                 "renderfx": "0", "spawnflags": "1"}, m.lv)
    m.test_button((352, -236, top + 100, 360, -228, top + 116), [("OnIn", "lc_substation_cut", "Trigger")])
    m.static("models/props_c17/oildrum001.mdl", 780, -120, 0, z=top)
    m.soundscape(SCAPES["combine"], 560, -160, top, radius=420)
    m.taken(256, -256, F, 832, -64, b.rim)
    for u, v in ((330, -120), (520, -110), (760, -150)):
        m.lane(u, v, top)
    m.view(120, 60, F, 325, -12, "from the canal")
    m.view(300, -140, top, 355, 0, "inside the fence: the yard")
    m.view(900, 120, F, 205, -10, "from downstream")


def m_breach(m, opt):
    """The breach: the canal's floor has fallen into an old cellar. A pit 640 by 256 and 160 deep in the middle of
    the canal: its edge broken, not cut (chunks of the canal's floor slab overhang it unevenly, the slab's thickness
    showing over the cellar's old brick), cracks running out across the canal's floor from it. The cellar's walls are
    old brick, a bricked-up doorway in a stone frame in one of them; its floor earth over old flagstones, with a pool of
    standing water in the low end and drips from the edge. Two slabs of the old floor lean down into it along its
    sides as ramps (one from each end); a third still hangs over the downstream end on two old timber poles and makes a
    dark undercut where things are kept, a lantern burning under it; a shelf of old bottles against the upstream wall,
    crates; reinforcing bars stick out of the broken edge, rubble lies at the bottom, dust hangs in the light from above.
    The canal's banks pass either side, so nobody has to go down.
    Named for the game: lc_breach_bottom (the middle of the pit), lc_breach_stash (under the hanging slab).
    Left as brushes: the pit, its broken edge and brick lining, the doorway's frame, the flagstones and the three slabs
    of fallen floor (the ground itself).
    Unchecked: the look of it; the rebar is stood on its side (pitch 90), centred on its origin so it stays where it is
    put; ambient/water/drip_loop1.wav."""
    import random
    from map_mods_c import dustmotes
    deep = F - 160      # (16 over the bottom of everything)
    m.open(0, -256, 1024, 256)
    m.open(192, -128, 832, 128, floor=deep, mat=DIRT)
    m.side(192, -128, 832, 128)
    slab = MAT["canal_floor"]
    m.shapes([prism([(192, F), (476, deep), (448, deep), (192, F - 22)], "y", -128, -48, slab),            # a ramp down from the upstream end
              prism([(832, F), (832, F - 22), (576, deep), (548, deep)], "y", 48, 128, slab),               # ...and one from the downstream end
              prism([(640, F), (832, F), (832, F - 18), (640, F - 30)], "y", -48, 48, slab)])               # the slab still hanging
    # the cellar's old brick, under the canal floor's broken slab; a bricked-up doorway in a stone frame
    brick, old = "brick/brickwall017b", "brick/brickwall037a"
    m.det([(192, -128, deep, 832, -122, F - 22), (192, 122, deep, 832, 128, F - 22), (192, -122, deep, 198, 122, F - 22), (826, -122, deep, 832, 122, F - 22)], brick)
    m.det([(404, 118, deep, 460, 122, deep + 96)], old)
    m.det([(396, 116, deep, 404, 122, deep + 96), (460, 116, deep, 468, 122, deep + 96), (396, 116, deep + 96, 468, 122, deep + 110)], "stone/stonewall050f")
    m.det([(560, -96, deep, 760, 40, deep + 2)], "stone/stonefloor006f_c17")                               # (old flagstones showing through the earth)
    # the broken edge: chunks of the slab overhanging the pit by uneven amounts, its thickness showing
    rnd = random.Random(73)
    chunks = []
    for s in (1, -1):
        u = 476 if s < 0 else 210
        end = 814 if s < 0 else 548
        while end - u >= 24:
            w = min(end - u, rnd.choice((24, 32, 40, 56, 72)))
            out = rnd.choice((6, 10, 14, 20, 26))
            v1, v2 = (128 - out, 128) if s > 0 else (-128, -128 + out)
            chunks.append((u, v1, F - rnd.choice((14, 18, 22)), u + w, v2, F))
            u += w
    for v1, v2, u1, u2 in ((-46, 122, 198, 210), (-122, -50, 814, 826)):                                  # (the ends, beside the ramps and the hanging slab)
        chunks.append((u1, v1, F - 22, u2, v2, F))
    m.det(chunks, slab)
    for k, (u, v) in enumerate(((150, -60), (180, 90), (880, 40), (860, -100), (520, 170), (600, -170))):    # cracks running out from it
        m.grime("crack", u, v, F + 1, k)
    for v in (-43, 43):                                                                                     # two old poles still holding it up
        m.static("models/props_docks/dock01_pole01a_128.mdl", 641, v, 0, z=deep)
    for k, (v, h, model) in enumerate(((-36, 34, "rebar002c_64"), (-8, 46, "rebar001c_64"), (18, 30, "rebar004c_64"), (44, 40, "rebar002c_64"))):
        m.point("prop_static", 200, v, F - h, {"model": "models/props_debris/%s.mdl" % model, "angles": "90 %d 0" % m.fr.yaw(10 * k - 15), "skin": "0", "solid": "0",
                                                "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, m.pv)
    m.water(290, -44, 440, 44, deep, deep + 5)
    m.sound("ambient/water/drip_loop1.wav", 360, 0, deep + 60, radius=500, volume=4)
    m.static("models/props_debris/concrete_chunk01a.mdl", 520, -90, 40, z=deep)
    m.static("models/props_debris/concrete_chunk02a.mdl", 500, 20, 110, z=deep)
    m.static("models/props_debris/broken_pile001a.mdl", 250, 80, 200, z=deep)
    # the old cellar's things: a shelf of old bottles against the upstream wall, crates in the undercut, a lantern there
    m.static("models/props_c17/shelfunit01a.mdl", 240, 108, 0, z=deep)
    for k in range(3):
        m.static("models/props_junk/glassbottle01a.mdl", 222 + 16 * k, 108, 0, z=deep + 46)
    m.loose("models/props_junk/wood_crate001a.mdl", 760, -14, 20, z=deep)
    m.loose("models/props_junk/wood_crate002a.mdl", 790, 30, 70, z=deep)
    m.static("models/props_c17/lamp001a.mdl", 730, -50, 0, z=deep)
    m.glow(730, -50, deep + 14, "255 190 110", 0.12)
    m.light(730, 0, deep + 70, "255 190 120 14")
    dustmotes(m, (220, -110, deep + 24, 620, 110, F + 120))
    m.target("lc_breach_bottom", 512, 0, deep + 8)
    m.target("lc_breach_stash", 730, 0, deep + 8, 180)
    m.decal("decals/decalstain002a", 120, 0, F + 1)
    m.soundscape(SCAPES["cave"], 512, 0, deep, radius=360)
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
    buildings. Its roof is vaulted (a polygonal barrel springing from the walls 96 under the crown) with a rib every
    256, posts down the walls under each; a raised kerb walk along each wall, the city's handrail along its edge in
    places; the city's pipe (pipeset32d) along the right wall, capped at both ends, a cable slung along over it;
    caged lamps on the left wall between the ribs (one in three dead); in the left wall's middle a maintenance doorway,
    planked over and boarded (nobody goes in); puddles under the roof's joints, drips, the tunnel's own soundscape.
    Left as brushes: the kerbs, the vault and its ribs, the doorway's frame and planking (the tunnel itself)."""
    from map_mods_c import cage_lamp, handrail, pipe_run
    L = m.fr.length
    roof = F + GATE_HIGH
    m.low(0, -256, L, 256, roof)
    m.portal(62, -256, F, 64, 256, roof)
    if L > 256:
        m.portal(L - 64, -256, F, L - 62, 256, roof)
    m.det([(0, -256, F, L, -208, F + 14), (0, 208, F, L, 256, F + 14)], MAT["beam"], top=MAT["quay_floor"])
    # the vault: strips from each wall's spring to the crown, each convex, no two in one plane overlapping
    prof = [(256, roof - 96), (224, roof - 54), (176, roof - 24), (112, roof - 7), (48, roof)]
    vault, ribs = [], []
    for s in (1, -1):
        for k in range(len(prof) - 1):
            (x1, z1), (x2, z2) = prof[k], prof[k + 1]
            q = [(s * x1, z1), (s * x2, z2), (s * x2, roof), (s * x1, roof)] if z2 < roof else [(s * x1, z1), (s * x2, roof), (s * x1, roof)]
            vault.append(prism(q, "x", 0, L, "concrete/concretewall008a"))
            for u in range(128, L - 60, 256):                 # the ribs: the same strips, 6 deep under the vault
                ribs.append(prism([(s * x1, z1 - 6), (s * x2, z2 - 6), (s * x2, z2), (s * x1, z1)], "x", u, u + 16, MAT["beam"]))
    m.shapes(vault + ribs)
    m.det([(u, -256, F + 14, u + 16, -250, roof - 102) for u in range(128, L - 60, 256)] + [(u, 250, F + 14, u + 16, 256, roof - 102) for u in range(128, L - 60, 256)],
          MAT["beam"])
    # the pipe along the right wall, a cable over it; the handrail on the kerbs' edges in places
    p2 = 64 + (L - 128) // 128 * 128                     # (the pipe in 128s, 64 in from each end, a cap on each end)
    if p2 > 64:
        pipe_run(m, (64, -236), (p2, -236), F + 126, "32d")
        m.static("models/props_c17/pipe_cap005.mdl", 64, -236, 180, z=F + 107)
        m.static("models/props_c17/pipe_cap005.mdl", p2, -236, 0, z=F + 107)
        m.rope([(u, -251, F + 160) for u in range(136, L - 60, 256)], slack=24, width=1)
    for u in range(256, L - 255, 512):
        handrail(m, (u, 206), (u + 128, 206), F + 14)
        handrail(m, (u + 256, -206), (u + 384, -206), F + 14) if u + 384 <= L - 64 else None
    # light: caged lamps on the left wall between the ribs, one in three dead
    for k, u in enumerate(range(256, L - 60, 256)):
        cage_lamp(m, u, 256, F + 120, 270, "255 214 160 45", lit=k % 3 != 2)
    # a maintenance doorway in the left wall's middle, planked over and boarded
    if L >= 768:
        du = (L // 2) // 64 * 64
        m.low(du, 256, du + 64, 320, F + 14 + 112, floor=F + 14)
        m.side(du, 256, du + 64, 320)
        m.blocked(du, 256, du + 64, 320)
        m.det([(du, 314, F + 14, du + 64, 320, F + 126)], "wood/woodwall006a")
        m.det([(du - 6, 248, F + 14, du + 2, 256, F + 126), (du + 62, 248, F + 14, du + 70, 256, F + 126), (du - 6, 248, F + 126, du + 70, 256, F + 134)], MAT["beam"])
        from map_town import board
        for z, roll in ((F + 50, 84), (F + 88, 97)):
            board(m, du + 32, 310, z, 270, roll)
        m.taken(du - 16, 240, F, du + 80, 256, F + 150)
    for u in range(192, L - 60, 256):
        m.grime("puddle", u + 8, ((u // 256) % 3 - 1) * 90, F + 1, u)
    m.grime("stain", L // 3, 256, F + 60, 1)
    m.grime("graffiti", 2 * L // 3, -256, F + 70, 2)
    m.sound("ambient/water/drip_loop1.wav", L // 2, 0, F + 120, radius=700, volume=3)
    m.sound("ambient/atmosphere/tunnel1.wav", L // 2, 0, F + 120, radius=900, volume=3)
    m.soundscape(SCAPES["tunnel"], L // 2, 0, F, radius=max(600, L // 2))
    for u in range(96, L - 60, 192):
        m.lane(u, 232, F + 14)
    m.view(100, 0, F, 0, 0, "inside")


def m_wreck(m, opt):
    """The wreck: a Combine dropship's troop container has come down in the canal: Episode One's own wrecked container
    (combine_dropship_container_static, 415 long, hollow: its collision is the hull's own), lying askew as a thing that
    fell from the sky lies: turned 20 degrees across the canal, nose down a few degrees into a ring of thrown earth,
    its tail toward the left bank, a dim red glow still on inside and a red beacon pulsing slowly on its back. Behind it
    the gouge it cut: slabs of the canal's floor lifted and tilted, scorch and debris along its track, a torn-off piece
    of its hull. Round it the crash's leftovers: two dead Combine soldiers, a pulse rifle by one, the Combine's supply
    crates and an ammunition crate spilled from it, a small fire still burning, sparks, thin smoke. A thing to race
    for: the Combine to recover it, the Resistance to strip it.
    Named for the game: lc_wreck_cache (inside, at its middle), lc_wreck_beacon (the beacon's pulsing glow on its back:
    HideSprite, ShowSprite), lc_wreck_spark (StopSpark).
    Left as brushes: the lifted slabs of floor (the ground itself; the earth round its nose is the ground's own bumps).
    Unchecked: env_spark, env_smokestack, env_fire, models/combine_soldier.mdl as a ragdoll. The container is Episode
    One's (players need Episode One's content, as for every Episode One model); whether its door end is open and
    players can get in, and which end is its nose (its size is read, its shape is not: the nose is taken as its +x,
    171 before its origin); container_chunk04 as a torn-off piece."""
    from map_mods_b import fire
    b = m.b
    m.open(0, -256, 1024, 256)
    ou, ov, yaw = 520, -10, 20                     # the container's origin (244 behind it its tail, 171 before it its nose), turned 20 degrees
    t = math.radians(yaw)
    nu, nv = int(ou + 171 * math.cos(t)), int(ov + 171 * math.sin(t))
    tu, tv = int(ou - 244 * math.cos(t)), int(ov - 244 * math.sin(t))
    m.prop("prop_static", "models/combine_dropship_container_static.mdl", ou, ov, yaw, F - 6, {"angles": "4 %d 0" % m.fr.yaw(yaw), "solid": "6",
           "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"})
    cx, cy = m.fr.pt(nu + 20, nv)
    b.bumps.append(lambda x, y: 46 * max(0.0, 1 - abs(((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 - 110) / 80.0))        # a ring of thrown earth round the nose
    m.point("env_sprite", ou, ov, F + 150, {"targetname": "lc_wreck_beacon", "model": "sprites/light_glow03.vmt", "rendermode": "9", "renderamt": "220",
                                            "rendercolor": "255 40 30", "scale": "0.4", "framerate": "10.0", "GlowProxySize": "2.0", "HDRColorScale": "1.0",
                                            "renderfx": "1", "spawnflags": "1"}, m.lv)
    m.glow(ou - 40, ov, F + 60, "255 40 30", 0.2)
    m.light(ou - 50, ov, F + 60, "255 60 40 22")
    m.spark(nu, nv + 30, F + 60, name="lc_wreck_spark")
    m.smoke(nu + 10, nv - 10, F + 90, colour="50 50 55", size=12, length=240, rate=7)
    m.target("lc_wreck_cache", ou - 30, ov - 10, F + 10, 180 + yaw)
    # the gouge behind it: slabs of the floor lifted and tilted, scorch and debris along its track
    slab = MAT["canal_floor"]
    lifted = []
    for k, (du, w, rise) in enumerate(((70, 56, 18), (150, 48, 26), (230, 64, 12))):
        u0, v0 = tu - du, int(tv - du * math.tan(t))
        lifted.append(prism([(u0, F - 4), (u0 + w, F + rise - 4), (u0 + w, F + rise + 4), (u0, F + 4)], "y", v0 - 28, v0 + 28 + 8 * k, slab))
        m.grime("burn" if k % 2 else "debris", u0 + w // 2, v0 + 44, F + 1, k)
    m.shapes(lifted)
    m.grime("burn", tu - 20, tv - 30, F + 1, 7)
    m.grime("burn", nu + 60, nv + 60, F + 1, 8)
    m.static("models/container_chunk04.mdl", tu - 120, tv + 120, 140, z=F)               # (a piece of its hull, torn off as it hit)
    # the crash's leftovers: the dead, a rifle, its cargo spilled, a fire still burning
    m.body("models/combine_soldier.mdl", ou + 40, ov + 120, 200)
    m.body("models/combine_soldier.mdl", tu - 40, tv - 70, 30)
    m.point("prop_dynamic", ou + 70, ov + 140, F + 4, {"model": "models/weapons/w_irifle.mdl", "angles": "0 %d 90" % m.fr.yaw(60), "solid": "0", "skin": "0",
                                                       "disableshadows": "1", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0",
                                                       "renderamt": "255", "rendercolor": "255 255 255"}, m.pv)
    m.dynamic("models/items/ammocrate_ar2.mdl", nu + 60, nv - 110, 70)
    for u, v, yaw2 in ((tu - 30, tv + 60, 30), (ou + 120, ov - 120, 80), (nu + 100, nv + 20, 10)):
        m.loose("models/items/item_item_crate.mdl", u, v, yaw2)
    fire(m, nu + 50, nv + 90, F + 2, size=20, light="255 150 70 60")
    for u, v, yaw2 in ((120, 100, 30), (880, -60, 55)):                                 # (on the floor, off the banks)
        m.loose("models/props_junk/wood_crate001a.mdl", u, v, yaw2)
    m.loose("models/props_debris/concrete_chunk01a.mdl", nu + 90, nv + 110, 40, z=F + 30)       # (loose: they settle on the thrown earth)
    m.loose("models/props_debris/concrete_chunk02a.mdl", nu + 110, nv - 100, 110, z=F + 30)
    m.decal("decals/decalstain002a", ou, ov + 150, F + 1)
    m.soundscape(SCAPES["combine"], ou, 0, F, radius=700)
    m.blocked(tu - 40, -170, nu + 150, 150)
    m.taken(tu - 40, -170, F, nu + 40, 150, F + 220)
    for u, v in ((140, 0), (520, 190), (520, -200), (900, 0)):
        m.lane(u, v)
    m.view(60, 80, F, 350, 0, "coming up to it")
    m.view(140, -60, F, 10, -4, "its tail, the gouge behind it")
    m.view(900, 120, F, 200, 0, "its nose")


def m_morgue(m, opt):
    """The morgue: where the city's dead wait for the cremator. A sliding steel door in the left wall (Nova Prospekt's
    sliding door between steel jambs: players open it by hand), a short passage, a cold room tiled to the waist and
    plastered above: a wall of twelve drawers, two pulled out, a number on each column, three steel tables (the
    hospital's surgery tables), two of the dead laid out on them (they do not move), a drain in the floor, a thin cold
    mist on the floor, three fluorescent tubes; in the right wall the body chute to the cremator (a steel hatch in a
    frame, a roller conveyor up to it: where the dead go to the ash outfall); a clerk's desk with the ledger, a
    clipboard, papers, a radio and a Combine screen for the records; a caged lamp over the door outside; a compressor's
    hum.
    Named for the game: lc_morgue_door (a func_door, unseen, the door's model riding on it), lc_morgue_table_1 to _3
    (the tables), lc_morgue_ledger (the desk), lc_morgue_chute (where the game sends the dead from: on the
    floor at the foot of the conveyor, facing the chute's hatch at its top; a place to stand, not the hatch itself).
    Left as brushes: the room, its tiles and plaster, the door's jambs and head, the drain, the wall of drawers (built
    into the wall: Half-Life 2 has no morgue drawers), the chute's hatch and frame and the conveyor (no model of one).
    Unchecked: models/humans/corpse1.mdl as a ragdoll laid on a table with its motion disabled (spawnflags 16388:
    debris and motion disabled, so it stays where it is laid), func_dustcloud's keys for the mist; which way the
    surgery table's head is (it is the same both ways in its size)."""
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
    m.det([(436, 244, F, 450, 256, F + 128), (574, 244, F, 588, 256, F + 128), (436, 244, F + 128, 588, 256, F + 140)], MAT["beam"])   # (the banks' ends hide in its posts)
    m.taken(428, 232, F, 596, 256, F + 160)
    from map_mods_c import cage_lamp, pipe_v, tube
    cage_lamp(m, 512, 256, F + 146, 270, "200 225 255 40")
    # the room tiled to the waist and plastered above (the back wall is the drawers' bank; the side walls' courses between
    # the front wall's, so no two tops lie in one plane)
    for z1, z2, t, mat in ((F, F + 64, 6, "tile/tilewall009b"), (F + 64, F + 176, 4, "plaster/plasterwall041a")):
        m.det([(256, 384, z1, 448, 384 + t, z2), (576, 384, z1, 768, 384 + t, z2), (256, 384 + 8, z1, 256 + t, 760, z2), (768 - t, 384 + 8, z1, 768, 760, z2)], mat)
        if z2 > F + 128:
            m.det([(448, 384, max(z1, F + 128), 576, 384 + t, z2)], mat)
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
    for i in range(4):
        m.grime("number", 348 + 110 * i, 762, F + 150, i)
    # three tables, the dead on two of them
    for k, (u, v) in enumerate(((340, 520), (512, 520), (684, 520))):
        m.static("models/props_c17/hospital_surgerytable01.mdl", u, v, 90)
        m.target("lc_morgue_table_%d" % (k + 1), u, v, F + 40)
        if k != 1:                                          # (laid out: their motion disabled, they stay on the tables)
            m.point("prop_ragdoll", u, v, F + 40, {"model": "models/humans/corpse1.mdl", "angles": "0 %d 0" % m.fr.yaw(90), "spawnflags": "16388"}, m.b.vis + ": bodies")
        m.blocked(u - 34, v - 68, u + 34, v + 68)
    m.det([(500, 600, F, 524, 624, F + 1)] + [(500 + 5 * k, 600, F + 1, 502 + 5 * k, 624, F + 2) for k in range(5)], MAT["bars"])
    m.static("models/props_wasteland/controlroom_desk001a.mdl", 320, 420, 90)
    m.static("models/props_lab/binderblue.mdl", 330, 430, 100, z=F + 34)
    m.static("models/props_lab/clipboard.mdl", 300, 410, 80, z=F + 34)
    m.static("models/props_c17/paper01.mdl", 318, 448, 20, z=F + 35)
    m.static("models/props_lab/citizenradio.mdl", 334, 466, 180, z=F + 34)
    m.static("models/props_combine/combine_smallmonitor001.mdl", 322, 392, 90, z=F + 34)
    m.static("models/props_wasteland/controlroom_chair001a.mdl", 300, 470, 270)
    m.target("lc_morgue_ledger", 320, 440, F + 36, 270)
    for u, v in ((384, 600), (640, 600), (512, 440)):
        tube(m, u, v, F + 176, "200 222 240 45", along="v")
    # the body chute in the right wall, a roller conveyor up to it
    m.det([(760, 600, F + 48, 768, 608, F + 108), (760, 680, F + 48, 768, 688, F + 108), (760, 600, F + 108, 768, 688, F + 116), (760, 600, F + 40, 768, 688, F + 48)],
          "metal/metalhull010c")
    m.det([(764, 608, F + 48, 766, 680, F + 108)], MAT["black"])
    m.target("lc_morgue_chute", 652, 644, F + 8, 0)                  # (the conveyor's foot: the hatch over its rollers is out of reach)
    m.det([(680, 610, F, 684, 614, F + 44), (680, 674, F, 684, 678, F + 44), (740, 610, F, 744, 614, F + 44), (740, 674, F, 744, 678, F + 44),
           (676, 610, F + 44, 760, 614, F + 48), (676, 674, F + 44, 760, 678, F + 48)], MAT["bars"])
    m.shapes([pipe_v(u, F + 47, 3, 614, 674) for u in range(684, 756, 12)])
    m.ent("func_dustcloud", {"StartDisabled": "0", "Color": "210 225 235", "SpawnRate": "12", "SpeedMax": "4", "LifetimeMin": "4", "LifetimeMax": "8", "DistMax": "700",
                             "Alpha": "18", "SizeMin": "40", "SizeMax": "80", "Frozen": "0"}, [(272, 400, F + 2, 752, 752, F + 26)], MAT["trigger"],
          vis=m.b.vis + ": experiments (delete if they misbehave)")
    m.sound("ambient/atmosphere/tunnel1.wav", 512, 560, F + 80, radius=500, volume=3)
    m.soundscape(SCAPES["laundry"], 512, 560, F, radius=300)
    m.decal("decals/decalstain002a", 512, 612, F + 1)
    for u, v in ((512, 300), (512, 420), (430, 640), (600, 640)):
        m.lane(u, v)
    m.view(512, 120, F, 90, 0, "the door")
    m.view(512, 400, F, 90, 0, "the cold room")
    m.view(290, 700, F, 330, 0, "the drawers")


def m_tramfall(m, opt):
    """The tram under the breach (the owner, 26 November, of the tram's station that could not stand under the street
    and of the breach: "sink the tram line even lower than the canal floor and combine it with the breach module so
    the broken canal floor is above the crashed tram, and the crashed tram is flat on the tracks but the
    rubble/concrete slabs from the breach have fallen onto it so it's still the EP2 model"). The tram's line crosses
    under the canal in a tunnel, its rails 304 under the canal's floor, its roof the canal's floor slab; over it the
    floor has fallen in, a hole 384 by 256: Episode Two's wrecked car (wrecked_train_02) stands level on the rails on
    its two bogies under the hole, as the tram module stands its cars, slabs of the canal's floor leaning on it and
    lying on its roof, rubble and bent bars round it, daylight and dust down the hole. Beside the car a slab of the
    collapsed floor lies as a ramp from the hole's edge down to the tunnel's floor (no steps: the owner, "just make it
    a slab of broken/collapsed concrete: a ramp"). Away from the city the tunnel ends in the dark, black.
    Toward the city the line runs under the street into THE TRAM MODULE'S OWN STATION, copied whole
    (map_mods_a.tram_station: the owner, the same day, of a bare hall first built here: "I told you to take the tram
    module that had the little station and put it in the breach module ... WHY NOT JUST COPY PASTE IT? WHERE IS THE
    STATION? WHERE ARE THE PROPS?"): the hall with its platforms either side of the track's pit, Half-Life 2's
    station columns and arches, the two-tone walls, the wall lamps, the ticket booth, the benches, the clock, the bin,
    the payphone, the signs, the signal, and the barred stair behind the prison's sliding gate; its tunnel's black end
    and the stair's lie directly under the Combine wall (the owner: the "gate/black void side ... directly under a
    combine wall section"), the station set 64 further from the canal than the tram module's to reach it.
    Named for the game: lc_breach_bottom (the tunnel's floor under the hole), lc_tram_exit (the station's, on the
    platform before the barred stair), lc_tram_stash (beside the car: a cache).
    The layout needs "base 64" or lower (the rails are at z 96), and the street on the module's left.
    Left as brushes: the tunnel, the fallen slabs, and what the station leaves as brushes.
    Unchecked: the car and its bogies are Episode Two's; the look of it."""
    import map_corridor
    import map_mods_a
    from map_mods_c import dustmotes
    from map_modules import MM
    b = m.b
    zr = F - 304                                 # the rails' bed (the tram module's zr)
    mouth = zr + 272                             # the tunnel's roof under the canal's floor slab, and the station's mouth's head
    if getattr(b, "base", 224) > zr - 16:
        b.problems.append("%s: the tram's tunnel is at z %d: the layout needs \"base %d\" or lower" % (m.tag, zr, zr - 32))
        return
    if m.street_side() == -1 or m.fr.flip:
        b.problems.append("%s: the station stands on the module's left: lay it unflipped with the street (or none) on its left" % m.tag)
        return
    FR = map_corridor.front_line(b) if m.street_side() else 1088
    dv = FR - 1024                               # (the tram's station ends 1024 from the canal's middle: on to the wall's foot)
    A, B, cu = 384, 768, 512                     # the tunnel under the canal: the track's 256 (its middle cu) and a walk 128 wide beside it
    m.open(0, -256, 1024, 256)
    m.cellar(A, -256, B, 256, zr, mouth, F, mat=MM["gravel"], upper_mat=MAT["canal_floor"])
    m.open(A, -128, B, 128, floor=zr, mat=MM["gravel"])                      # the hole
    m.low(A, -448, 640, -256, mouth, floor=zr, mat=MM["gravel"])              # away from the city: on into the dark
    if dv > 0:
        m.low(A, 256, 640, 256 + dv, mouth, floor=zr, mat=MM["gravel"])      # (the 64 on to the station's mouth)
    m.side(A, -448, B, 256 + dv)
    m.blocked(A - 32, -160, B + 32, 160)
    m.no_bank(A - 64, -264, B + 64, 264)
    m.det([(A, -448, zr, 640, -440, mouth)], MAT["black"])
    m.b.vmf.world_box(m.fr.box(A, -400, zr, 640, -392, mouth), MAT["clip"], MAT["clip"], MAT["clip"], vis=m.dv, seals=False)
    for u in (cu - 32, cu + 28):                                              # the rails under the canal, from the dark to the station's own
        m.det([(u, -440, zr, u + 4, 256 + dv, zr + 3)], MAT["bars"])
    # the station: the tram module's own, in its own coordinates (its mouth at v 256, its track's middle at u 768), so
    # the module's frame is moved for it
    fr = m.fr
    ox, oy = fr.pt(cu - 768, dv)
    m.fr = type(fr)(ox, oy, fr.rot, fr.length, fr.flip, fr.shift, fr.dv, fr.dz)
    map_mods_a.tram_station(m, zr, mouth)
    m.fr = fr
    # the car, level on the rails on its bogies under the hole (as the tram module stands a car: 52 over the bed); what fell on it
    m.dynamic(map_mods_a.WRECK, cu, 40, 0, zr + 52)
    m.static(map_mods_a.BOGIE, cu, 40 + 216, 90, zr)
    m.static(map_mods_a.BOGIE, cu, 40 - 216, 270, zr)
    roof = zr + 52 + 208
    slab = MAT["canal_floor"]
    m.shapes([prism([(-128, F), (-128, F - 28), (40, roof), (60, roof + 26)], "x", 440, 584, slab),            # a slab of the floor leaning from the hole's edge onto its roof
              prism([(128, F), (156, F - 10), (172, roof + 4), (146, roof)], "x", 452, 572, slab)])              # a second, hanging at the other edge, its foot on the roof
    m.det([(456, 60, roof, 566, 118, roof + 18)], slab)                                                         # one lying on the roof
    m.static("models/props_debris/concrete_debris128pile001a.mdl", 690, 150, 30, z=zr)
    m.static("models/props_debris/concrete_chunk01a.mdl", 660, -180, 110, z=zr)
    for k in range(5):
        m.point("prop_static", 404 + 76 * k, -126 + 2 * (k % 2), F - 20 - 6 * (k % 3), {"model": "models/props_debris/rebar00%dc_64.mdl" % (2 if k % 2 else 4),
                                                                                         "angles": "90 %d 0" % m.fr.yaw(90), "skin": "0", "solid": "0"})
    # the way down: a slab of the collapsed floor lying as a ramp beside the car, from the hole's far edge to the tunnel's
    # floor: 304 down over 368, about 40 degrees
    m.shapes([prism([(-128, F), (240, zr), (196, zr), (-128, F - 28)], "x", 648, 760, slab)])
    m.spot(cu + 60, 0, F + 380, "255 240 220 260", 0, -90, 60)                # daylight down the hole
    dustmotes(m, (A + 16, -112, zr + 16, B - 16, 112, F - 8))
    m.target("lc_breach_bottom", 600, 0, zr + 8)
    m.target("lc_tram_stash", 620, -200, zr + 8)
    m.soundscape(SCAPES["tunnel"], cu, 0, zr, radius=420)
    m.lane(200, 0)
    m.lane(860, 0)
    m.lane(600, 180, zr)
    m.view(200, -80, F, 15, -20, "the hole in the canal's floor and the car under it")
    b.notes.append("%s: the tram's rails at z %d under the canal's floor; the tram module's station under the street, its black end at the Combine wall's foot (%d %d)" % (
        (m.tag, zr) + m.fr.pt(cu, FR)))


MODULES = {
    "execwall": (768, m_execwall, "the firing wall: a backstop, three posts, one hard lamp (left)"),
    "substation": (1024, m_substation, "the substation: transformers behind the Combine's fence, a fuse panel to break (right)"),
    "tramfall": (1024, m_tramfall, "the tram under the breach: the canal's floor fallen in over a tram tunnel, the wrecked car under the slabs, a station under the street"),
    "breach": (1024, m_breach, "the breach: the floor fallen into an old cellar, slabs for ramps, an undercut"),
    "tunnel": (1024, m_tunnel, "the canal under the city: a covered stretch of any length (\"tunnel 1536\")", {"stretch": True}),
    "wreck": (1024, m_wreck, "the wreck: a Combine carrier's container down in the canal, hollow, to race for"),
    "morgue": (1024, m_morgue, "the morgue: a cold room of drawers and tables behind a sliding door (left)"),
}
