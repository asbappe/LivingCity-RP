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
SCAPE_TOWN = "d1_trainstation.QuietCourtyard"      # (one the owner's own map uses)
HQ_DOC = "the Resistance leader's office: a briefing room and an office behind it (the game puts the flagpole at its door)"

# What the owner's own streets are made of (counted in their map), and how their windows are laid.
R = {"road": "stone/stonefloor006d_c17", "strip": "stone/stonefloor006f_c17", "walk": "concrete/concretefloor016a", "kerb": "concrete/concretefloor039b",
     "plinth": "concrete/concretewall002c", "trim": "stone/stonewall050f", "frame": "wood/woodwall006a"}
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
CHIMNEY, CHIMNEY_B, STACKS = "models/props_rooftop/chimneypipe01a.mdl", "models/props_rooftop/chimneypipe01b.mdl", "models/props_rooftop/chimneypipe_cluster02a.mdl"
AERIALS = ("models/props_rooftop/antenna01a.mdl", "models/props_rooftop/antenna02a.mdl", "models/props_rooftop/antenna03a.mdl")
DISH, VENT = "models/props_rooftop/satellitedish02.mdl", "models/props_rooftop/roof_vent001.mdl"
RED_ROOF = "metal/metalroof004a"


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
    """A house people can live in, furnished as the owner's city's flats are (stoves, sinks, fridges and beds stand
    backs to the wall). A front door that opens (the city's own door, with its handle) into a hall; off it two flats,
    each behind its own door: a kitchen (stove, sink, fridge, a table and two chairs, a radiator) and through an
    archway a living room (a fireplace, a couch facing it, a dresser). At the hall's end a stair climbs 160 to a landing
    and a passage with a bedroom off each side: the left flat's has the city's iron bed, the right one's a wooden bed
    and mattress; both a dresser and a bedside drawer. (The owner, 20 November: "too cramped, half of that can go in
    the bedroom(s), can we have a few upstairs rooms too?")
    Named for the game: lc_flat_door (the front door), lc_flat_1 and lc_flat_2 (info_targets in the two kitchens). A
    second house in one chain takes a word after its name in the layout ("flats b"): lc_flat_b_door, lc_flat_b_1 ...
    Each bedroom has a bathroom behind it (a toilet, a sink, a bath); the walls are lined in two tones of plaster
    with a dado rail, the living rooms panelled below it; the kitchens have the owner's fluorescent tube.
    Unchecked: the mattress's height on its frame; which way the dresser, drawers, toilet and bath face;
    the living rooms are panelled in wood/woodwall006a (the owner uses it 87 times)."""
    from map_modules import F
    H, D, Z = F + 128, F + 112, F + 160                     # the ground floor's ceiling, a doorway's, the upper floor
    nm = "lc_flat_" + "".join(w + "_" for w in opt[:1] if w.isalnum() and w != "flip")
    wood, tile, wall = "wood/woodfloor007a", "tile/tilefloor018a_c17", "plaster/plasterwall042c"
    m.open(0, -256, 768, 256)
    m.low(320, 256, 384, 320, D, mat=wood)                   # the front doorway
    m.low(320, 320, 448, 640, H, mat=wood)                   # the hall
    m.low(320, 640, 448, 896, Z + 128, mat=wood)             # the stairwell
    m.low(320, 896, 448, 1216, Z + 128, floor=Z, mat=wood)   # the landing and the passage upstairs
    for u1 in (64, 512):
        m.low(u1, 320, u1 + 192, 576, H, mat=tile)           # a kitchen
        m.low(u1, 640, u1 + 192, 896, H, mat=wood)           # a living room
        m.low(u1, 960, u1 + 192, 1216, Z + 128, floor=Z, mat=wood)   # a bedroom upstairs
        m.low(u1, 1280, u1 + 192, 1408, Z + 112, floor=Z, mat=tile)  # its bathroom, through a door at the bedroom's back
        m.low(u1 + 64, 1216, u1 + 128, 1280, Z + 112, floor=Z, mat=tile)
        m.low(u1 + 64, 576, u1 + 128, 640, D, mat=wood)      # the archway between kitchen and living room
    m.low(256, 384, 320, 448, D, mat=wood)                   # the flats' doors off the hall
    m.low(448, 384, 512, 448, D, mat=wood)
    m.low(256, 1024, 320, 1088, Z + 112, floor=Z, mat=wood)  # the bedrooms' doors off the passage
    m.low(448, 1024, 512, 1088, Z + 112, floor=Z, mat=wood)
    m.side(64, 256, 704, 1408)
    m.portal(320, 286, F, 384, 288, D)
    m.taken(308, 232, F, 396, 256, F + 124)
    door_hole(m, "u", 320, 256, 320, F, D, name=nm + "door", yaw=270)
    door_hole(m, "v", 384, 256, 320, F, D, yaw=0)
    door_hole(m, "v", 384, 448, 512, F, D, yaw=180)
    door_hole(m, "v", 1024, 256, 320, Z, Z + 112, yaw=0)
    door_hole(m, "v", 1024, 448, 512, Z, Z + 112, yaw=180)
    m.det([(u1 + 64, 604, F + 104, u1 + 128, 612, D) for u1 in (64, 512)], R["frame"])
    # the stair: 10 steps of 16 and 24, then the landing
    m.det([(320, 640 + 24 * i, F, 448, 640 + 24 * (i + 1), F + 16 * (i + 1)) for i in range(10)] + [(320, 880, F, 448, 896, Z)], wall, top=MAT["stairs"])
    m.blocked(320, 640, 448, 896)
    m.lane(384, 760, F + 80)
    lamp = "255 214 170 45"
    m.lamp(384, 480, H - 8, lamp)
    m.lamp(384, 1040, Z + 120, lamp)
    for n, (wall_u, yaw, far) in enumerate(((64, 0, 1), (704, 180, -1))):    # each flat: its outer wall, the way its things face, and which way is in
        mid = wall_u + far * 96
        back = 180 if far > 0 else 0
        # the kitchen
        m.static("models/props_c17/furniturestove001a.mdl", wall_u + far * 19, 400, yaw)
        m.static("models/props_c17/furnituresink001a.mdl", wall_u + far * 12, 452, yaw)
        m.static("models/props_interiors/refrigerator01a.mdl", wall_u + far * 17, 530, yaw)
        m.static("models/props_c17/furnituretable00%da.mdl" % (n + 1), wall_u + far * 140, 476, 0)
        m.static("models/props_c17/furniturechair001a.mdl", wall_u + far * 140, 530, 270)
        m.static("models/props_c17/furniturechair001a.mdl", wall_u + far * 92, 476, yaw)
        m.static("models/props_c17/furnitureradiator001a.mdl", mid, 327, 90)
        m.static("models/props_lab/lab_flourescentlight002b.mdl", mid, 448, 90, H - 8)     # the kitchen's tube, as the owner's flats have
        m.light(mid, 448, H - 20, "235 240 255 55")
        m.target(nm + str(n + 1), mid, 440, F + 8, 90)
        # the bathroom
        door_hole(m, "u", wall_u + far * 64 if far > 0 else wall_u - 128, 1216, 1280, Z, Z + 112, yaw=270)
        m.static("models/props_c17/furnituretoilet001a.mdl", wall_u + far * 13, 1300, yaw, Z)
        m.static("models/props_c17/furnituresink001a.mdl", wall_u + far * 12, 1370, yaw, Z)
        m.static("models/props_c17/furniturebathtub001a.mdl", wall_u + far * 130, 1390, 0, Z)
        m.lamp(mid, 1340, Z + 104, "255 225 200 30")
        m.lane(mid, 1320, Z)
        # the living room
        m.static("models/props_c17/furniturefireplace001a.mdl", wall_u + far * 16, 790, yaw)
        m.static("models/props_c17/furniturecouch002a.mdl", wall_u + far * 174, 790, back)
        m.static("models/props_c17/furnituredresser001a.mdl", wall_u + far * 60, 877, 270)
        m.lamp(mid, 768, H - 8, "255 205 160 35")
        # the bedroom upstairs
        m.static("models/props_c17/furnituredrawer002a.mdl", wall_u + far * 11, 1196, yaw, Z)
        m.static("models/props_c17/furnituredresser001a.mdl", wall_u + far * 120, 1197, 270, Z)
        m.lamp(mid, 1088, Z + 120, "255 205 160 35")
        for u, v, z in ((mid, 448, F), (mid, 608, F), (mid + far * 30, 720, F), (mid + far * 40, 1000, Z)):
            m.lane(u, v, z)
    for u1 in (64, 512):                                     # the walls lined as the owner's flats are (two tones, a dado rail)
        lining(m, u1, 320, u1 + 192, 576, F, H)
        lining(m, u1, 640, u1 + 192, 896, F, H, low="wood/woodwall006a", high="plaster/plasterwall042c")
        lining(m, u1, 960, u1 + 192, 1216, Z, Z + 128)
    lining(m, 320, 320, 448, 640, F, H)
    m.static("models/props_wasteland/prison_metalbed001a.mdl", 75, 1110, 0, Z)                 # the left flat's bed, as the city's flats have
    m.static("models/props_c17/furniturebed001a.mdl", 681, 1110, 90, Z)                        # the right flat's
    from map_mods_b import mattress
    mattress(m, 681, 1110, 90, Z + 20)
    for u, v, z in ((352, 290, F), (384, 420, F), (288, 416, F), (480, 416, F), (384, 920, Z), (288, 1056, Z), (480, 1056, Z)):
        m.lane(u, v, z)
    m.view(352, 80, F, 90, 0, "the front door")
    m.view(230, 520, F, 200, 4, "a kitchen")
    m.view(384, 600, F, 90, 10, "the stair")


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
            for x1, y1, x2, y2 in self.fill:      # (each house solid 640 deep behind its front: it has a roof to stand things on)
                for i in range(x1 // CELL, x2 // CELL):
                    for j in range(y1 // CELL, y2 // CELL):
                        self.cells.setdefault((i, j), ("solid",))
            Plan.walls(self)
            for c, spec in list(self.cells.items()):
                x, y = c[0] * CELL + 32, c[1] * CELL + 32
                quay = any(x1 <= x < x2 and y1 <= y < y2 for x1, y1, x2, y2 in self.canal)      # (round the basin: a canal's wall and its fence, no house)
                top = self.rim if quay else self.top_of(c)
                if spec[0] == "solid":
                    self.cells[c] = ("solid", top, not quay)
                elif spec[0] == "low" and len(spec) == 4:
                    self.cells[c] = spec + (max(top, spec[3]), not quay)
            for c, spec in list(self.cells.items()):      # (the outermost wall keeps the sky on its top: it seals the map)
                if spec[0] == "solid" and any((c[0] + di, c[1] + dj) not in self.cells for di in (-1, 0, 1) for dj in (-1, 0, 1)):
                    self.cells[c] = spec + ("edge",)

        def build(self, vmf):
            """As the street's plan builds, but over a house's roof the sky starts at the lid: chimneys, aerials and
            pitched roofs stand in the air above the roofs (the module review: a skyline of flat steps). Only the
            outermost wall carries the sky on its top, so the map stays sealed."""
            self.walls()
            cw, sky, brick = MAT["canal_wall"], MAT["sky"], "brick/brickwall045d"
            STREET = mc.STREET
            for x1, y1, x2, y2, spec in self.rectangles():
                if spec[0] != "solid":
                    continue
                top, front, edge = spec[1], spec[2], len(spec) > 3
                if front and top > STREET:
                    vmf.world_box(self.box(x1, y1, self.base, x2, y2, STREET), cw, vis=self.vis)
                    vmf.world_box(self.box(x1, y1, STREET, x2, y2, top), brick, top=self.roof_mat, vis=self.vis)
                else:
                    vmf.world_box(self.box(x1, y1, self.base, x2, y2, top), cw, top=self.roof_mat, vis=self.vis)
                if edge or top >= self.sky:
                    vmf.world_box(self.box(x1, y1, top, x2, y2, self.top), sky, vis=self.vis)
                else:
                    vmf.world_box(self.box(x1, y1, self.sky, x2, y2, self.top), sky, sky, sky, vis=self.vis)
            keep = self.cells
            self.cells = dict((c, sp) for c, sp in keep.items() if sp[0] != "solid")
            self.walled = True
            mc.CorridorPlan.build(self, vmf)
            self.cells = keep

    plan = TownPlan(BASE, b.rim, b.sky, b.vis + ": walls and floors")
    plan.tops, plan.canal, plan.walk, plan.fill = [], [], walk, []
    plan.roof_mat = "concrete/concretefloor026a"      # (a flat roof seen from the street's far side and the chimneys' height)
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


def roof_prop(m, model, u, v, z, yaw=0):
    """A thing standing on a roof at z (above the plan's own squares, so it is placed straight into the map and the
    wall checks, which would call it inside the house, leave it alone)."""
    m.b.vmf.point("prop_static", m.fr.at(u, v, m.stand(model, z)), {"model": model, "angles": "0 %d 0" % m.fr.yaw(yaw), "solid": "6", "skin": "0",
                                                                   "disableshadows": "0", "fademindist": "-1", "fadescale": "1"}, m.pv)


def lining(m, u1, v1, u2, v2, floor, ceil, low="plaster/plasterwall047b", high="plaster/plasterwall042c", rail=None, thick=2):
    """A room's walls lined as the owner's flats are: plaster in two tones split by a dado rail at 40, a skirting at the
    floor. Only where the room's edge meets a wall (never across a doorway): the plan says which squares are open."""
    cells = m.b.plan.cells
    rail = rail or R["frame"]
    boxes_low, boxes_high, boxes_rail = [], [], []
    for u in range(u1, u2, CELL):
        for v, d in ((v1, -1), (v2, 1)):
            x, y = m.fr.pt(u + 32, v + d * 32)
            if (x // CELL, y // CELL) not in cells or cells[(x // CELL, y // CELL)][0] == "solid":
                w = v if d < 0 else v - thick
                boxes_low.append((u, w, floor, u + CELL, w + thick, floor + 40))
                boxes_high.append((u, w, floor + 44, u + CELL, w + thick, ceil))
                boxes_rail.append((u, w - d * 1, floor + 40, u + CELL, w + thick - d * 1, floor + 44))
    for v in range(v1, v2, CELL):
        for u, d in ((u1, -1), (u2, 1)):
            x, y = m.fr.pt(u + d * 32, v + 32)
            if (x // CELL, y // CELL) not in cells or cells[(x // CELL, y // CELL)][0] == "solid":
                w = u if d < 0 else u - thick
                boxes_low.append((w, v, floor, w + thick, v + CELL, floor + 40))
                boxes_high.append((w, v, floor + 44, w + thick, v + CELL, ceil))
                boxes_rail.append((w - d * 1, v, floor + 40, w + thick - d * 1, v + CELL, floor + 44))
    if boxes_low:
        m.det(boxes_low, low)
        m.det(boxes_high, high)
        m.det(boxes_rail, rail)


def board(m, u, v, z, yaw, roll):
    """A plank nailed across (z: its middle). The model is a physics prop, so it is a prop_dynamic_override: as a
    prop_static the compiler deletes it (the owner's compile, 20 November)."""
    m.point("prop_dynamic_override", u, v, z, {"model": BOARD, "angles": "0 %d %d" % (m.fr.yaw(yaw), roll), "skin": "0", "solid": "0", "disableshadows": "1",
                                               "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "StartDisabled": "0", "renderamt": "255", "rendercolor": "255 255 255"}, m.pv)


def real_door(m, u, v, yaw, z, name=None, skin=7):
    """One of the city's own doors, that opens: a prop_door_rotating set up as the owner's 134 are (a handle, opens 90
    either way). Its hinge at (u, v) on the floor z; the leaf reaches 47 to the left of yaw. Its opening, as the owner's
    are (measured round 42 of them): 50 wide from 2 behind the hinge, 110 high (`door_hole` makes one)."""
    k = {"model": DOOR, "angles": "0 %d 0" % m.fr.yaw(yaw), "hardware": "1", "skin": str(skin), "spawnflags": "8192", "distance": "90", "speed": "100", "returndelay": "-1",
         "opendir": "0", "ajarangles": "0 0 0", "dmg": "0", "forceclosed": "0", "health": "0", "spawnpos": "0", "rendercolor": "255 255 255", "fademindist": "-1", "fadescale": "1"}
    if name:
        k["targetname"] = name
        m.b.names.append((name, "prop_door_rotating", m.tag))
    m.b.vmf.point("prop_door_rotating", m.fr.at(u, v, z + 55), k, m.pv)


def door_hole(m, axis, a, lo, hi, z, top, mat=None, name=None, yaw=None):
    """A doorway cell's reveal filled to a door's own opening: the cell runs `axis` ("u" or "v") from a to a + 64 across
    the opening, lo to hi through the wall; jambs fill it to 50 wide and a head from 110 to its ceiling `top`. With a
    name or a yaw, the door itself, its hinge 2 in from the low jamb (yaw 270 or 0) or the high one (90 or 180)."""
    mat = mat or R["frame"]
    j1, j2 = a + 7, a + 57
    if axis == "u":
        boxes = [(a, lo, z, j1, hi, top), (j2, lo, z, a + 64, hi, top), (j1, lo, z + 110, j2, hi, top)]
    else:
        boxes = [(lo, a, z, hi, j1, top), (lo, j2, z, hi, a + 64, top), (lo, j1, z + 110, hi, j2, top)]
    m.det(boxes, mat)
    if yaw is not None:
        mid = (lo + hi) // 2
        h = j1 + 2 if yaw in (270, 0) else j2 - 2
        real_door(m, h, mid, yaw, z, name) if axis == "u" else real_door(m, mid, h, yaw, z, name)


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
    lots, state, lot_holes = [], {}, []
    for i in range(len(cuts) - 1):
        high = rnd.choice([h for h in HEIGHTS if not lots or h != lots[-1][2]])
        lots.append((cuts[i], cuts[i + 1], high, STYLES[(first + i * 3 + rnd.randrange(2)) % len(STYLES)]))
        b.plan.tops.append(fr.rect(cuts[i], 256, cuts[i + 1], 256 + 2048) + (walk + high,))
        b.plan.fill.append(fr.rect(cuts[i], 320, cuts[i + 1], 320 + 640))

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
        lot_holes.append(low_holes + up_holes[0] + (up_holes[1] if len(rows) == 2 else []))
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
    for a, c, high, (ground, upper) in lots:               # on the roofs: chimneys, aerials, dishes, now and then a pitched roof
        roof = F + high
        kind = rnd.random()
        if kind < 0.3 and c - a >= 256:                      # a pitched roof over the front, its gable ends in the house's wall
            depth = 320
            m.shapes([prism([(272, roof), (272 + depth, roof), (272 + depth // 2, roof + 112)], "x", a + 8, c - 8, RED_ROOF, upper)])
            stack = (a + c) // 2 + rnd.choice((-64, 64))
            roof_prop(m, CHIMNEY, stack, 272 + depth // 2, roof + 100)
        else:
            m.det([(a, 256, roof, c, 272, roof + 24)], R["trim"])           # a parapet along the roof's front
            slots = [(u, v) for u in range(a + 64, c - 63, 128) for v in (380, 520, 660)]
            rnd.shuffle(slots)
            things = [rnd.choice((CHIMNEY, CHIMNEY_B, STACKS)) for _ in range(rnd.choice((1, 2, 2, 3)))]
            if rnd.random() < 0.35:
                things.append(rnd.choice(AERIALS))
            if rnd.random() < 0.4:
                things.append(VENT)
            for model, (u, v) in zip(things, slots):       # (one thing to a slot 128 by 140: they never stand in each other)
                roof_prop(m, model, u + rnd.randrange(-16, 17), v + rnd.randrange(-16, 17), roof, rnd.randrange(0, 360, 90) if model != STACKS else 0)
            if rnd.random() < 0.3:
                roof_prop(m, DISH, rnd.randrange(a + 40, c - 40), 300, roof + 24, 270)
    for (a, c, high, styles), holes in zip(lots, lot_holes):  # balconies on some upper floors, awnings over the shop windows
        if high >= 370 and rnd.random() < 0.35:
            row = [h for h in holes if 150 < h[2] < 260]
            for h1, h2, s, t in row[:: max(1, len(row) // 2)] if row else []:
                mid = (h1 + h2) // 2
                m.det([(mid - 48, 212, F + s - 12, mid + 48, 256, F + s - 4)], R["trim"])
                m.static("models/props_c17/handrail04_medium.mdl", mid, 214, 90, F + s - 4)
                for d in (-47, 47):
                    m.static("models/props_c17/handrail04_short.mdl", mid + d, 232, 0, F + s - 4)
        for h1, h2, s, t in holes:
            if s == 44 and h2 - h1 > 140:
                m.static("models/props_c17/awning00%da.mdl" % (1 if h2 - h1 > 140 else 2), (h1 + h2) // 2, 240, 270, F + t + 4)
                m.det([(h1, 250, F + t + 10, h2, 256, F + t + 40)], R["frame"])            # the shop's name board
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
    for u in (448, 704):      # (solid to the floor, and as wide as the bank is cut, so bank and cheek meet: the owner saw gaps)
        low.shapes([prism([(foot, F), (-448, F), (-448, F + dz + 40), (foot, F + 40)], "x", u, u + 64, MAT["beam"])])
    low.no_bank(456, -456, 760, -440)
    low.blocked(448, foot, 768, -448)
    low.taken(440, foot, F, 776, -448, F + dz + 40)
    for model, u in ((RAIL, 320), ("models/props_c17/handrail04_medium.mdl", 415), (RAIL, 833)):     # the handrail along the quay's edge
        up.static(model, u, -445, 90, F)
    up.static(POST, 608, -280, 0, F)                         # (its arm over the street: the owner, 20 November)
    up.light(608, -180, F + 400, "255 214 170 380")
    low.static("models/props_canal/boat001a.mdl", 400, -960, 100)
    low.blocked(300, -1040, 500, -880)
    up.target("lc_town_landing", 608, -400, F + 8, 90)
    low.lane(608, foot - 48, F)
    low.lane(608, (foot - 448) // 2, F + dz // 2)
    up.lane(608, -400, F)
    low.lane(400, -704, F)
    low.view(380, -760, F, 20, -8, "the basin and the steps")
    b.notes.append("%s: the canal's gate is at (%d %d), 512 wide, floor z %d, facing back along the street" % ((tag,) + gf.pt(0, 0) + (F,)))


def corner(b, x, y, rot, right, dz, fronts, n):
    """A street's corner: a square of cobbles 512 across at the roadway's crown, the pavements carried round its outer
    sides and across its inner corner, a house on each outer side and a lamppost at the outer corner. right: it turns
    right (else left). Gives where the next stretch starts, and its heading."""
    from map_modules import F, Frame, Mod
    fr = Frame(x, y, rot, 512, dz=dz)
    m = Mod(b, fr, "the corner %d" % n)
    s = -1 if right else 1                                   # the side the street leaves by (+v is the left)
    o = -s                                                   # the outer side
    m.open(0, -256, 512, 256, floor=F - 4, mat=R["road"])
    m.open(0, min(o * 192, o * 256), 512, max(o * 192, o * 256), mat=R["walk"])
    m.open(448, -256, 512, 256, mat=R["walk"])
    m.open(0, min(s * 192, s * 256), 64, max(s * 192, s * 256), mat=R["walk"])
    m.det([(0, min(o * 160, o * 192), F - 4, 416, max(o * 160, o * 192), F), (416, min(s * 256, o * 160), F - 4, 448, max(s * 256, o * 160), F),
           (0, min(s * 160, s * 192), F - 4, 96, max(s * 160, s * 192), F), (64, min(s * 192, s * 256), F - 4, 96, max(s * 192, s * 256), F)], R["walk"])
    m.static(POST, 470, o * 214, 135 if o > 0 else 45, F)
    m.light(400, o * 144, F + 400, "255 214 170 380")
    m.cubemap(256, 0)
    for u, v in ((128, 0), (256, 0), (256, s * 128), (384, 0)):
        m.lane(u, v, F - 4)
    fronts.append((Frame(x, y, rot, 512, s > 0, dz=dz), 512, "the houses, corner %d" % n))
    fronts.append((Frame(*(Frame(x, y, rot, 0).pt(256, 256) + ((rot - 1) % 4, 512)), dz=dz), 512, "the houses, corner %d, ahead" % n))
    nx, ny = Frame(x, y, rot, 512).pt(256, s * 256)
    return nx, ny, (rot + s) % 4


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
    def known(w):
        return w and (w[0] in ("landing", "houses") or w[0] in MODULES)

    def length_of(w):       # ("houses N": a stretch of house fronts alone, N long; a corner's inner side wants one)
        if w[0] == "houses":
            return int(w[1]) if len(w) > 1 and w[1].isdigit() else 768
        return 1024 if w[0] == "landing" else MODULES[w[0]][0]
    corners = 0
    for n, words in enumerate(lay["modules"]):
        if words[0] == "turn":
            corners += 1
            x, y, rot = corner(b, x, y, rot, words[1:2] != ["left"], dz, fronts, corners)
            continue
        line = " ".join(words)
        left, _, right = [p.split() for p in line.partition("|")]
        sides = [(left, False), (right, True)]
        lengths = [length_of(w) for w, _ in sides if known(w)]
        for w, _ in sides:
            if w and not known(w):
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
        other = -side                                        # on the other pavement: a bench, a bin, now and then a payphone on a wall
        bu = rnd.choice((L // 4, 3 * L // 4))
        street.static("models/props_trainstation/benchoutdoor01a.mdl", bu, other * 236, 90 if other > 0 else 270, F)
        street.static("models/props_trainstation/trashcan_indoor001b.mdl", bu + 96, other * 232, 0, F)
        street.blocked(bu - 60, min(other * 192, other * 256), bu + 120, max(other * 192, other * 256))
        for k in range(3):                                   # what the street has on it: puddles, litter, a drain grate in the gutter
            street.grime("puddle", rnd.randrange(80, L - 80), rnd.randrange(-60, 60), F - 4, n * 10 + k)
            street.grime("trash", rnd.randrange(80, L - 80), rnd.choice((-1, 1)) * rnd.randrange(196, 250), F, n * 10 + k)
        street.grime("grate", rnd.randrange(64, L - 64), rnd.choice((-1, 1)) * 140, F - 8, n)
        if n == 0:
            street.soundscape(SCAPE_TOWN, L // 2, 0, F, 2048)
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
