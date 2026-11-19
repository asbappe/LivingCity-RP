#!/usr/bin/env python3
"""
Living City: a Ravenholm quarter behind the Combine wall at the city's south end, and a tunnel from
it to the sewers (run it through map_build.py)

    python3 map_build.py ravenholm            lc_ravenholm.vmf
    python3 map_build.py ravenholm --test     lc_ravenholm_test.vmf, to compile and walk by itself

The owner, 19 November: "I want to attach a ravenholm-esque section of the city to the south end
that I put a sealed off wall near ... that could be opened by resistance to flood the city with
zombies/headcrabs, and also to attach an underground tunnel between this new ravenholm section and
the existing tunnels/sewers in the map so that the combine can open that tunnel (it would be sealed
by default) and flood the resistance underground". Where: "right behind the wall"; the tunnel comes
out of the sewer wall they marked (320 x 8 x 209 at 1376 397 344: brush 28290).

What is there (read from c18_lc.vmf): the wall is brush 65929 (x 93..107, y -2526..-2188) with two
rails (51870, 62363), across an east-west street whose roadway is y -2549..-2293 at z 656. Behind it
the street is finished for about 1,000 units (houses to x 1024 on the south side, 1152 on the
north); then only the roadway runs on to x 1472, and a bare strip of road (34874) hangs south from
there in empty space. That empty space is where this piece stands.

The piece, all in the map's own coordinates:
- THE GATE: the owner's wall, made to open as they asked: the smaller brushes in it "recede and
  move into their respective sides, as if they are reinforcing the main wall brush, and once they
  have moved then the main wall can open by lowering itself straight down into the ground". Its
  four brushes again (the slab, the two rails, the black outline above), every texture laid as
  theirs: the rails draw back into their pillars, then the slab goes down, the outline with it.
  With the unseen wall the owner has round it (gone while the gate is open). The owner deletes
  65929, 51870, 62363, 15623 and 33530; the pillars stay.
- THE APPROACH: walls, pavements and road edges along the unfinished last stretch of the owner's
  street (x 1024..1472), so it has sides.
- THE QUARTER (a plan whose corner is at 1472 -2613, so its rows lie on the street's own lines).
  The owner, of the first one: "Please use the other streets and sidewalks and building facades on
  the map as guidance: the one in the new ravenholm quarter is unfinished and missing lots. Would it
  be possible to have little abandoned in-buildings and old shops and such along the street". So it
  is built to the recipe of the owner's own streets (taken from the one at 138 -951): a cobbled
  roadway 256 wide, an edge strip of setts each side, a kerb, pavements raised 8; every building
  its own two wall materials, the owner's commonest; on every facade a plinth, a ledge, a band of
  strip windows (glass on black), a cornice, two rows of windows above; lamp posts, benches, a
  payphone, street decals, posters. The street runs east to a square; an alley and a yard behind
  each row of buildings; a street south to a lower yard. FOUR BUILDINGS TO GO INTO, each with walls
  8 or 16 thick, the city's own doors, a back door onto its alley: a shop, a cafe, a second shop,
  and a tenement with a stair to an upper room whose windows look onto the street.
- THE TUNNEL HOUSE, on the north side of the approach: a door, 45 steps down north, and a tunnel
  (z 304..448) straight north under the city to the sewer wall, 1,966 long. A vent duct of the
  owner's crosses 4 units behind that wall from x 1256 east, so the tunnel's last 128 are a passage
  36 wide along the west side. In the sewer wall's west end is THE HATCH (lc_raven_hatch): a steel
  door anyone opens by hand. Across the tunnel 145 before the narrow passage is THE COMBINE DOOR:
  two leaves of the Combine's metal that only the wiring parts; it is what seals the tunnel, and
  opening it opens the hatch too. The piece carries the whole sewer wall again with the hatch in
  it: the owner deletes 28290.
- The owner also deletes 34874 (the bare strip): the approach's south side stands where it starts.

Nothing in the gamemode knows of this yet. Who may open the gate and the hatch is the gamemode's to
say: the map only has lc_raven_gate_open / _shut and lc_raven_door_open / _shut (logic_relays: fire
Trigger), and fires lc_raven_gate_opened, lc_raven_door_opened and their _closed for it to hear.
While the gate is open zombies and headcrabs are made in the quarter and walk out through it; while
the Combine door is open, in the tunnel, and walk to the sewer (the makers are in their own visgroup:
delete it if the gamemode is to send them itself).
"""

import random

from map_build import CELL, MAT, Plan, Vmf, check, test_extras
from map_forest import crusher

R = {   # (the owner's own, from their streets and their sewer, but the last three)
    "road": "stone/stonefloor006d_c17", "strip_s": "stone/stonefloor006f_c17", "strip_n": "stone/stonefloor006e_c17", "walk": "concrete/concretefloor016a",
    "kerb": "concrete/concretefloor039b", "dirt": "nature/dirtfloor005c", "plinth": "concrete/concretewall002c", "trim": "stone/stonewall050f",
    "glass": "glass/glasswindow041a", "gate": "metal/citadel_metalwall077a", "gate_rail": "metal/citadel_metalwall101b", "sewer_wall": "concrete/concretewall056c",
    "tunnel_wall": "brick/brickwall027a", "tunnel_floor": "concrete/concretefloor010b", "room_wall": "plaster/plasterwall047b", "tile": "tile/tilefloor018a_c17",
    "room_floor": "wood/woodfloor007a", "shop_floor": "concrete/concretefloor031a", "board": "wood/woodbeam001a", "steel": "metal/metalhull003a",
}
STYLES = (   # each building's ground floor and upper floors: the commonest walls of the owner's own streets
    ("brick/brickwall053e", "concrete/concretewall074c"),       # 0: the first shop (as the owner's last house on that side)
    ("plaster/plasterwall047b", "plaster/plasterwall042c"),     # 1: the cafe
    ("brick/brickwall037a", "brick/brickwall037c"),             # 2: the tenement
    ("concrete/concretewall059e", "concrete/concretewall055b"), # 3: the second shop
    ("brick/brickwall045d", "brick/brickwall040c"),             # 4: east of the square
    ("stone/stonewall040f", "plaster/plasterwall046b"),         # 5: north of the square
    ("brick/brickwall014l", "brick/brickwall017b"),             # 6: the south blocks
    ("concrete/concretewall037a", "brick/brickwall040b"),       # 7: the rest
)
DELETE = ("65929", "51870", "62363", "15623", "33530", "28290", "34874")   # the owner's brushes this piece stands in the place of: they delete these
# (65929, 51870, 62363: the Combine wall and its two rails. 15623: the unseen wall round it, which would still stop
#  everyone when the gate is down; the gate carries its own, that goes when it opens. 33530: a thin black sheet standing in
#  the wall, to z 1128. 28290: the sewer wall. 34874: the bare strip of road hanging south of the street's end.)
STANDS_IN = ("20571", "20578", "34853", "49820", "52305")   # the pavement and roadway the owner's wall itself stands in, and the two pillars its
#                                                              black outline's ends reach into: the gate's pieces do the same, and these stay


class TownPlan(Plan):
    """A quarter's squares: every wall square (and the floors over a room) takes its building's two looks, look_of(u, v)."""

    def __init__(self, origin, base, sky, street, look_of, vis):
        Plan.__init__(self, origin, [(base, sky + 16, MAT["canal_wall"])], sky=sky, floor_side=R["kerb"], vis=vis)
        self.street, self.look_of = street, look_of

    def room(self, rect, floor, mat, ceiling):
        self.paint(rect, ("low", floor, mat, ceiling, self.look_of(rect[0], rect[1])))

    def walls(self):
        Plan.walls(self)
        for c, spec in list(self.cells.items()):
            if spec[0] == "solid":
                self.cells[c] = ("solid", self.look_of(c[0] * CELL, c[1] * CELL))

    def looks(self, k, z_from):
        out = []
        for lo, hi, mat in ((self.base, self.street + 240, STYLES[k][0]), (self.street + 240, self.street + 752, STYLES[k][1]), (self.street + 752, self.top, MAT["sky"])):
            if max(lo, z_from) < hi:
                out.append((max(lo, z_from), hi, mat))
        return out

    def build(self, vmf):
        self.walls()
        sky = MAT["sky"]
        for x1, y1, x2, y2, spec in self.rectangles():
            if spec[0] == "solid":
                for a, b, mat in self.looks(spec[1], self.base):
                    vmf.world_box(self.box(x1, y1, a, x2, y2, b), mat, vis=self.vis)
                continue
            vmf.world_box(self.box(x1, y1, self.base, x2, y2, spec[1]), self.floor_side, top=spec[2], vis=self.vis)
            if spec[0] == "open":
                vmf.world_box(self.box(x1, y1, self.sky, x2, y2, self.top), sky, sky, sky, vis=self.vis)
            else:
                first = True
                for a, b, mat in self.looks(spec[4], spec[3]):
                    vmf.world_box(self.box(x1, y1, a, x2, y2, b), mat, bottom=self.ceiling if first else None, vis=self.vis)
                    first = False


def ravenholm(args):
    vmf = Vmf()
    X0, Y0 = 1472, -2613                 # the plan's corner: where the owner's roadway ends, its rows on that street's own lines
    Z, SKY = 656, 1536                   # the roadway; this piece's own sky (under brushes of the owner's that hang over its north end from z 1560)
    ZS = Z + 8                           # the pavements, and the floors of the buildings on them
    base = Z - 64
    BIG = 10 ** 6
    sky = MAT["sky"]
    wv, dv, pv, tv = "LC ravenholm: walls and floors", "LC ravenholm: facades", "LC ravenholm: props", "LC ravenholm: tunnel"
    gv, mv = "LC ravenholm: gate, hatch and their wiring", "LC ravenholm: zombie makers (delete if the gamemode is to send them itself)"
    uv, lv = "LC ravenholm: buildings to go into", "LC ravenholm: lights"
    test = bool(args.test)

    # --- the quarter ---------------------------------------------------------------------------------------------
    def look_of(u, v):
        if v >= 512 and u < 352:
            return 2
        if v >= 512 and u < 768:
            return 3
        if -512 <= v < -128 and u < 416:
            return 0
        if -512 <= v < -128 and u < 768:
            return 1
        if u >= 1216:
            return 4
        if v >= 576:
            return 5
        return 6 if v < -640 else 7
    plan = TownPlan((X0, Y0), base, SKY, Z, look_of, wv)
    plan.keep_out.append((-BIG, -BIG, 0, BIG))               # west of it is the owner's street
    road, dirt = ("open", Z, R["road"]), ("open", Z, R["dirt"])
    plan.paint((0, -128, 768, 512), ("open", ZS, R["walk"])) # the street, carried on east: pavements raised 8...
    plan.paint((0, 0, 768, 64), ("open", Z, R["strip_s"]))   # ...an edge strip of setts each side...
    plan.paint((0, 320, 768, 384), ("open", Z, R["strip_n"]))
    plan.paint((0, 64, 768, 320), road)                      # ...and the roadway, on the owner's own (rows 64..320)
    plan.paint((768, -192, 1216, 576), road)                 # the square
    plan.paint((832, -896, 1024, -192), road)                # a street south...
    plan.paint((512, -1088, 1216, -896), road)               # ...to the lower yard
    plan.paint((64, -640, 832, -512), dirt)                  # the alley behind the south row
    plan.paint((832, 576, 960, 832), dirt)                   # an alley north off the square...
    plan.paint((64, 832, 1088, 960), dirt)                   # ...to the yard behind the north row
    HIGH = ZS + 144                                          # a room's ceiling
    plan.room((64, -512, 384, -128), ZS, R["room_floor"], HIGH)      # the shop
    plan.room((448, -512, 704, -128), ZS, R["tile"], HIGH)           # the cafe
    plan.room((384, 512, 704, 832), ZS, R["shop_floor"], HIGH)       # the second shop
    plan.room((64, 512, 320, 832), ZS, R["room_floor"], ZS + 296)    # the tenement: two floors
    plan.build(vmf)
    B, W, cells = plan.box, plan.world, plan.cells

    # --- the approach: sides for the owner's street where it has none (x 1024..1472) -------------------------------
    def wall_like(x1, y1, x2, y2, k):
        for a, b, m in plan.looks(k, base):
            vmf.world_box((x1, y1, a, x2, y2, b), m, vis=wv)
    wall_like(1024, Y0 - 191, X0, Y0 - 128, 0)                                                     # the south side, from the owner's last house (1 short of a poster board of theirs)
    vmf.world_box((1024, Y0 - 128, base, X0, Y0, ZS), R["kerb"], top=R["walk"], vis=wv)            # its pavement
    vmf.world_box((1216, Y0, base, X0, Y0 + 64, Z), R["kerb"], top=R["strip_s"], vis=wv)           # the south edge strip, from where the owner's stops
    vmf.world_box((1024, Y0 + 320, base, X0, Y0 + 384, Z), R["kerb"], top=R["strip_n"], vis=wv)    # the north edge strip
    vmf.world_box((1152, Y0 + 384, base, X0, Y0 + 512, ZS), R["kerb"], top=R["walk"], vis=wv)      # the north pavement, from the owner's last house
    wall_like(1184, Y0 + 512, 1200, Y0 + 576, 7)                                                   # the north side: a wall either side of the tunnel house
    wall_like(1424, Y0 + 512, X0, Y0 + 576, 7)

    # --- the tunnel house and the tunnel ---------------------------------------------------------------------------
    TX1, TX2 = 1216, 1408                      # the tunnel, inside
    FLOOR, CEIL = 304, 448
    ys, ya = Y0 + 512, Y0 + 640                # the house's front (y -2101); the head of the stairs (y -1973)
    STEPS = (ZS - FLOOR) // 8                  # 45
    yb = ya + 12 * STEPS                       # the stairs' foot (y -1433)
    slot_y, wall_y = 265, 393                  # where the narrow last passage begins; the sewer wall's south face
    tw, tf = R["tunnel_wall"], R["tunnel_floor"]
    top_h = ZS + 168                           # the house's walls' top

    def WB(box, m, **k):
        vmf.world_box(box, m, vis=tv, **k)
    # the front wall with its doorway (48 wide, 108 high), carried down to the tunnel's floor
    WB((TX1 - 16, ys, 240, 1288, ys + 16, top_h), tw)
    WB((1336, ys, 240, TX2 + 16, ys + 16, top_h), tw)
    WB((1288, ys, 240, 1336, ys + 16, ZS), tw, top=tf)
    WB((1288, ys, ZS + 108, 1336, ys + 16, top_h), tw)
    # the side walls: the stair hall's (to its highest roof), then the tunnel's
    WB((TX1 - 16, ys + 16, 240, TX1, yb, top_h), tw)
    WB((TX2, ys + 16, 240, TX2 + 16, yb, top_h), tw)
    WB((TX1 - 16, yb, 240, TX1, wall_y + 8, CEIL + 16), tw)
    WB((TX2, yb, 240, TX2 + 16, slot_y, CEIL + 16), tw)
    # floors: the landing inside the door, and one slab under the stairs and the tunnel
    WB((TX1, ys + 16, base, TX2, ya, ZS), tw, top=tf)
    WB((TX1, ys + 16, 240, TX2, slot_y, FLOOR), tw, top=tf)
    vmf.detail([(TX1, ya + 12 * i, FLOOR, TX2, ya + 12 * (i + 1), ZS - 8 * (i + 1)) for i in range(STEPS - 1)], tw, vis=tv, top=MAT["stairs"])
    # roofs over the stairs: four lengths, each 88 lower than the last, with a wall down from each to the next
    tops = [ZS + 144 - 88 * k for k in range(4)]
    for k in range(4):
        y1, y2 = (ys + 16 if k == 0 else ya + 132 * k + 16), (ya + 132 * (k + 1) if k < 3 else yb)
        WB((TX1, y1, tops[k], TX2, y2, tops[k] + 16), tw, bottom=MAT["ceiling"])
        WB((TX1, y2, tops[k + 1] if k < 3 else CEIL, TX2, y2 + 16, tops[k] + 16), tw)
    WB((TX1, yb + 16, CEIL, TX2, slot_y, CEIL + 16), tw, bottom=MAT["ceiling"])
    # the last 128: the owner's vent duct crosses from x 1256 east just behind the sewer wall, so a passage 36 wide along
    # the west side, shut off from the duct's side
    WB((1252, slot_y, 240, TX2 + 16, slot_y + 16, CEIL + 16), tw)
    WB((1252, slot_y + 16, 240, 1256, wall_y, CEIL + 16), tw)
    WB((TX1, slot_y, 240, 1252, wall_y, FLOOR), tw, top=tf)
    WB((TX1, slot_y, CEIL, 1252, wall_y + 8, CEIL + 16), tw, bottom=MAT["ceiling"])
    # the sewer wall again (the owner's brush 28290), with the hatch's opening in its west end
    WB((1252, wall_y, 239, 1536, wall_y + 8, CEIL), R["sewer_wall"])
    WB((TX1, wall_y, 239, 1252, wall_y + 8, 307), R["sewer_wall"], top=tf)
    # The owner: "I was hoping the connection to the existing sewer would have a purely hatch to climb through as you did, but
    # also a combine door that can be triggered". So two things. THE HATCH, in the sewer wall: a steel door anyone opens by
    # hand (a func_door as the owner's own: Use opens and shuts it). THE COMBINE DOOR, across the tunnel 145 before the narrow
    # passage: two leaves of the Combine's metal that only the wiring parts (lc_raven_door_open); it is what seals the tunnel.
    # When it opens it also opens the hatch, so what comes down the tunnel can get out.
    vmf.brush_entity("func_door", {
        "targetname": "lc_raven_hatch", "movedir": "-90 0 0", "speed": "60", "lip": "8", "wait": "-1", "spawnflags": "288", "spawnpos": "0", "dmg": "0", "forceclosed": "0",
        "health": "0", "ignoredebris": "0", "loopmovesound": "0", "noise1": "doors/doormove1.wav", "noise2": "doors/doormove2.wav", "locked_sentence": "0",
        "unlocked_sentence": "0", "renderamt": "255", "rendercolor": "255 255 255", "renderfx": "0", "rendermode": "0", "disableshadows": "1"},
        [((TX1, wall_y + 2, 307, 1252, wall_y + 6, CEIL), R["steel"])], R["steel"], gv)
    DY, DX = 120, (TX1 + TX2) // 2
    for name, x1, x2, way, edge in (("lc_raven_tdoor_w", TX1, DX, "0 180 0", (DX - 2, DY + 3, FLOOR, DX + 14, DY + 13, CEIL)),
                                    ("lc_raven_tdoor_e", DX, TX2, "0 0 0", (DX - 14, DY + 3, FLOOR, DX + 2, DY + 13, CEIL))):
        vmf.brush_entity("func_button", {"targetname": name, "movedir": way, "speed": "24", "lip": "8", "wait": "-1", "spawnflags": "0", "sounds": "0", "health": "0",
                                         "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"}, [((x1, DY + 2, FLOOR, x2, DY + 14, CEIL), R["gate"])], R["gate"], gv)
        crusher(vmf, name, edge, gv, "lc_raven_door_crush")
    vmf.detail([(TX1, DY - 4, FLOOR, TX1 + 8, DY + 20, CEIL), (TX2 - 8, DY - 4, FLOOR, TX2, DY + 20, CEIL), (TX1 + 8, DY - 4, CEIL - 12, TX2 - 8, DY + 20, CEIL)],
               "metal/metalcombine002", vis=gv)

    def city_door(pos, yaw, vis):
        """The city's own door, as the owner's map has it 134 times (hinged at pos; yaw 0 it runs north from there, 270 east)."""
        vmf.point("prop_door_rotating", pos, {
            "model": "models/props_c17/door01_left.mdl", "angles": "0 %d 0" % yaw, "ajarangles": "0 0 0", "axis": "%d %d %d, %d %d %d" % (pos + pos), "distance": "90", "dmg": "0",
            "fademindist": "-1", "fadescale": "1", "forceclosed": "0", "hardware": "1", "health": "0", "opendir": "0", "rendercolor": "255 255 255", "returndelay": "-1",
            "skin": "7", "spawnflags": "8192", "spawnpos": "0", "speed": "100"}, vis)

    def lamp(pos, colour):
        vmf.point("light", pos, {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_quadratic_attn": "1", "style": "0"}, lv)
    city_door((1288, ys + 8, ZS + 54), 270, tv)
    lamp((1312, ys + 70, ZS + 120), "255 200 150 90")
    for y in range(yb + 120, slot_y - 100, 320):
        if (y // 320) % 3:
            lamp((1312, y, CEIL - 16), "255 190 130 60")       # (a dim one every 320 of tunnel, a third of it left dark)

    # --- the gate. The owner: "I was hoping the wall I had could be converted into a functioning gate made of the brushes",
    # then, of a first try that split the slab in two and slid everything sideways: "there are smaller brushes in the wall,
    # those I would like to recede and move into their respective sides, as if they are reinforcing the main wall brush, and
    # once they have moved then the main wall can open by lowering itself straight down into the ground".
    # Their wall part is four brushes: the slab (65929), two rails on its city face (51870 low on the south half, 62363 high
    # on the north half) and a thin sheet above it that draws a black outline (33530). Here they are again, every face's
    # texture laid exactly as theirs. Opening: the two rails draw back along the wall, each into the pillar on its own side
    # (161, in under three seconds); then the slab, whole, goes straight down 290 into the ground (there is nothing under
    # that street), its top ending 2 under the road's surface; the outline goes down with it and on into it. Shutting is
    # the same backwards: the wall rises, then the rails come out across it. The frame (the pillars) is the owner's and
    # stays. (Never in the test file: it stands a thousand units outside this piece.) ------------------------------------
    if not test:
        nd, pipe, MID = MAT["nodraw"], "metal/metalpipe001a", -2357
        slab = ({"west": R["gate"], "east": R["gate"], "top": R["gate"], "north": pipe, "south": pipe, "bottom": nd},
                {"west": ("[0 1 0 243.481] 0.375", "[0 0 -1 -370] 0.8097"), "east": ("[0 1 0 243.481] 0.375", "[0 0 -1 -370] 0.8097"),
                 "top": ("[0 1 0 109.222] 0.25", "[1 0 0 141.222] 0.25")})
        line = {"west": "/BLACK_OUTLINE", "east": nd, "top": nd, "bottom": nd, "north": nd, "south": nd}
        rail = {"west": R["gate_rail"], "east": pipe, "top": R["gate_rail"], "bottom": R["gate_rail"], "north": R["gate_rail"], "south": R["gate_rail"]}

        def mover(name, way, lip, speed, piece):
            vmf.brush_entity("func_button", {"targetname": name, "movedir": way, "speed": speed, "lip": lip, "wait": "-1", "spawnflags": "0", "sounds": "0", "health": "0",
                                             "rendermode": "0", "renderamt": "255", "rendercolor": "255 255 255"}, [piece], R["gate"], gv)
        SOUTH, NORTH, DOWN = "0 270 0", "0 90 0", "90 0 0"
        mover("lc_raven_rail_s", SOUTH, 8, 60, ((77, -2526, 708, 93, MID, 740), rail, {
            "west": ("[0 1 0 243.481] 0.375", "[0 0 -1 -441] 0.0625"), "top": ("[0 1 0 109.222] 0.25", "[1 0 0 137.222] 0.25"),
            "bottom": ("[0 1 0 109.222] 0.25", "[1 0 0 137.222] 0.25"), "north": ("[-1 0 0 -137.222] 0.25", "[0 0 -1 -494] 0.25")}))
        mover("lc_raven_rail_n", NORTH, 8, 60, ((77, MID, 840, 93, -2188, 856), rail, {
            "west": ("[0 1 0 287.277] 0.38", "[0 0 -1 -438.999] 0.06"), "top": ("[0 1 0 287.277] 0.38", "[1 0 0 -275.907] 0.06"),
            "bottom": ("[0 1 0 287.277] 0.38", "[1 0 0 -275.907] 0.06"), "south": ("[-1 0 0 -225.857] 0.38", "[0 0 -1 -438.999] 0.06")}))
        # (a mover goes its own length less its "lip": the slab is 296 high, so lip 6 takes it down 290. The outline is 184
        #  high and must go 474 to be out of sight, inside the lowered slab: a lip of -290.)
        mover("lc_raven_wall", DOWN, 6, 36, ((93, -2526, 648, 107, -2188, 944),) + slab)
        mover("lc_raven_wall_top", DOWN, -290, 36, ((98, -2558, 944, 102, -2150, 1128), line, {"west": ("[0 -1 0 2.77832] 0.25", "[0 0 -1 0] 0.25")}))
        # (rising again, the wall kills whoever stands on it and deletes what lies on it, as the other great doors do)
        crusher(vmf, "lc_raven_wall", (94, -2525, 944, 106, -2189, 958), gv, "lc_raven_gate_crush")
        # the unseen wall the owner has round it (so nobody gets over): there while the gate is shut, gone while it is open
        vmf.brush_entity("func_brush", {"targetname": "lc_raven_gate_clip", "Solidity": "0", "StartDisabled": "0", "solidbsp": "0", "spawnflags": "2", "rendermode": "0",
                                        "renderamt": "255", "rendercolor": "255 255 255", "vrad_brush_cast_shadows": "0", "disableshadows": "1", "invert_exclusion": "0"},
                         [(65, -2639, 648, 197, -2075, 1280)], "tools/toolsinvisible", gv)
        vmf.boxes.pop()      # (not held to the fit check: it is the owner's own unseen wall again, which stands in their pillars and houses as theirs does)
        # where what is made here walks to: the city's side of the gate; the sewer beyond the hatch
        vmf.point("info_target", (-300, -2421, Z + 16), {"targetname": "lc_raven_rally"}, mv, outside=True)
        vmf.point("info_target", (1376, 760, 323), {"targetname": "lc_raven_door_rally"}, mv, outside=True)

    # --- the wiring. The relays and sounds stand inside the quarter (a sound can be told what to play from). ---------------
    def sound(name, message, source, pos, loops=False):
        vmf.point("ambient_generic", pos, {"targetname": name, "message": message, "SourceEntityName": source, "health": "10", "pitch": "100", "pitchstart": "100",
                                           "radius": "3000", "spawnflags": "16" if loops else "48", "cspinup": "0", "fadeinsecs": "0", "fadeoutsecs": "0", "lfomodpitch": "0",
                                           "lfomodvol": "0", "lforate": "0", "lfotype": "0", "preset": "0", "spindown": "0", "spinup": "0", "volstart": "0"}, gv)

    def relays(name, moves, took, at, makers, source, crush=None, clip=None, also=()):
        """name_open and name_shut (one live at a time), name_opened and name_closed for the gamemode to hear.
        moves: (what moves, how long into the opening, how long into the shutting); also: more to fire as it opens."""
        sound(name + "_move", "Streetwar.d3_c17_11_garage_move1", source, at, loops=True)
        sound(name + "_stop", "Streetwar.d3_c17_11_garage_stop1", source, (at[0], at[1] + 16, at[2]))
        opening = [("OnTrigger", name + "_open", "Disable", "", 0), ("OnTrigger", name + "_move", "PlaySound", "", 0.5),
                   ("OnTrigger", name + "_opened", "Trigger", "", 0.5), ("OnTrigger", name + "_move", "StopSound", "", 0.5 + took),
                   ("OnTrigger", name + "_stop", "PlaySound", "", 0.5 + took), ("OnTrigger", makers, "Enable", "", 0.5 + took), ("OnTrigger", name + "_shut", "Enable", "", took + 2)]
        shutting = [("OnTrigger", name + "_shut", "Disable", "", 0), ("OnTrigger", makers, "Disable", "", 0),
                    ("OnTrigger", name + "_move", "PlaySound", "", 0.5), ("OnTrigger", name + "_move", "StopSound", "", 0.5 + took),
                    ("OnTrigger", name + "_stop", "PlaySound", "", 0.5 + took), ("OnTrigger", name + "_closed", "Trigger", "", 0.5 + took),
                    ("OnTrigger", name + "_open", "Enable", "", took + 2)]
        for what, wait_open, wait_shut in moves:
            opening.append(("OnTrigger", what, "PressIn", "", 0.5 + wait_open))
            shutting.append(("OnTrigger", what, "PressOut", "", 0.5 + wait_shut))
        opening += [("OnTrigger", what, action, "", 0.5) for what, action in also]
        if crush:
            shutting += [("OnTrigger", crush, "Enable", "", 0.5), ("OnTrigger", crush, "Disable", "", 0.9 + took)]
        if clip:
            opening.append(("OnTrigger", clip, "Disable", "", 0.5))
            shutting.append(("OnTrigger", clip, "Enable", "", 0.5 + took))
        vmf.point("logic_relay", (at[0], at[1], at[2] + 16), {"targetname": name + "_open", "StartDisabled": "0", "spawnflags": "0"}, gv, connections=opening)
        vmf.point("logic_relay", (at[0], at[1], at[2] + 32), {"targetname": name + "_shut", "StartDisabled": "1", "spawnflags": "0"}, gv, connections=shutting)
        vmf.point("logic_relay", (at[0], at[1], at[2] + 48), {"targetname": name + "_opened", "StartDisabled": "0", "spawnflags": "0"}, gv)
        vmf.point("logic_relay", (at[0], at[1], at[2] + 64), {"targetname": name + "_closed", "StartDisabled": "0", "spawnflags": "0"}, gv)
    relays("lc_raven_gate", [("lc_raven_rail_*", 0, 8.6), ("lc_raven_wall*", 3.0, 0)], 11.4, W(40, 190, Z + 96), "lc_raven_maker", "lc_raven_wall",
           crush="lc_raven_gate_crush", clip="lc_raven_gate_clip")
    relays("lc_raven_door", [("lc_raven_tdoor_*", 0, 0)], 3.7, (1312, ys + 60, ZS + 60), "lc_raven_door_maker", "lc_raven_tdoor_w", crush="lc_raven_door_crush",
           also=[("lc_raven_hatch", "Open")])

    # --- what is made while a way is open: zombies and headcrabs, sent walking to that way's far side ----------------------
    def makers(name, child, march, goal, spots):
        for (pos, cls) in spots:
            vmf.point("npc_maker", pos, {"targetname": name, "NPCType": cls, "NPCTargetname": child, "StartDisabled": "1", "spawnflags": "32", "MaxNPCCount": "1",
                                         "SpawnFrequency": "14", "MaxLiveChildren": "2", "angles": "0 180 0"}, mv,
                      connections=[("OnSpawnNPC", march, "StartSchedule", "", 1)])
        vmf.point("aiscripted_schedule", (spots[0][0][0], spots[0][0][1], spots[0][0][2] + 64), {
            "targetname": march, "m_iszEntity": child, "m_flRadius": "0", "graball": "1", "forcestate": "0", "schedule": "1", "interruptability": "0", "goalent": goal,
            "spawnflags": "4"}, mv)
    makers("lc_raven_maker", "lc_raven_zombie", "lc_raven_march", "lc_raven_rally",
           [(W(990, 200, Z + 8), "npc_zombie"), (W(930, -600, Z + 8), "npc_zombie"), (W(860, -990, Z + 8), "npc_fastzombie"), (W(500, 896, Z + 8), "npc_headcrab"),
            (W(400, -576, Z + 8), "npc_headcrab")])
    makers("lc_raven_door_maker", "lc_raven_door_zombie", "lc_raven_door_march", "lc_raven_door_rally",
           [((1312, yb + 200, FLOOR + 8), "npc_zombie"), ((1312, yb + 420, FLOOR + 8), "npc_headcrab")])

    # --- the four buildings to go into (the owner: "little abandoned in-buildings and old shops and such along the street").
    # Each is a hollow in the plan right up to the pavement; its front and back are walls 16 thick with a door and windows,
    # what divides it inside is 8 thick. ----------------------------------------------------------------------------------
    rw = R["room_wall"]

    def thin(way, line, a, b, holes, z1, z2, mat, world=False, inner=None, thick=16):
        """A thin wall: way "u" it runs east-west, standing on v = line..line+thick; way "v" north-south on u. holes: (from, to, sill, head)."""
        def piece(p, q, za, zb):
            return B(p, line, za, q, line + thick, zb) if way == "u" else B(line, p, za, line + thick, q, zb)
        pieces, at = [], a
        for (h1, h2, sill, head) in sorted(holes):
            if h1 > at:
                pieces.append(piece(at, h1, z1, z2))
            if sill > z1:
                pieces.append(piece(h1, h2, z1, sill))
            if head < z2:
                pieces.append(piece(h1, h2, head, z2))
            at = h2
        if at < b:
            pieces.append(piece(at, b, z1, z2))
        if world:
            for box in pieces:
                vmf.world_box(box, mat, vis=uv, faces=inner)
        else:
            vmf.detail(pieces, mat, vis=uv)
    DOOR = (ZS, ZS + 108)
    extra, boards, signs = [], [], []

    def shop_window(u1, u2, line, out, sill, head, zc):
        """Round a shop's window, outside: a sill, two boards nailed across, a name board over it."""
        lo, hi = (line, line + 6) if out > 0 else (line - 6, line)
        extra.append(B(u1 - 8, lo, sill - 8, u2 + 8, hi, sill))
        for z in (sill + 22, sill + 58):
            boards.append(B(u1 - 6, min(line, line + 3 * out), z, u2 + 6, max(line, line + 3 * out), z + 12))
        signs.append(B(u1, min(line, line + 4 * out), zc + 14, u2, max(line, line + 4 * out), zc + 46))

    def static(model, u, v, yaw, z=None, vis=pv):
        vmf.point("prop_static", W(u, v, Z if z is None else z), {"model": model, "angles": "0 %d 0" % yaw, "skin": "0", "solid": "6", "disableshadows": "0",
                                                                  "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, vis)

    def loose(model, u, v, yaw, z=None):
        vmf.point("prop_physics", W(u, v, (Z if z is None else z) + 24), {"model": model, "angles": "0 %d 0" % yaw, "skin": "0", "spawnflags": "0"}, pv)
    # 1. the shop, south of the street: a door and a wide window, a counter, a back room, a back door onto the alley
    thin("u", -144, 64, 384, [(96, 144) + DOOR, (192, 352, ZS + 40, ZS + 128)], ZS, HIGH, STYLES[0][0], world=True, inner={"south": rw})
    thin("u", -512, 64, 384, [(288, 336) + DOOR], ZS, HIGH, STYLES[0][0], world=True, inner={"north": rw})
    thin("u", -336, 64, 384, [(208, 256) + DOOR], ZS, HIGH, rw, thick=8)
    city_door(W(96, -136, ZS + 54), 270, uv)
    city_door(W(288, -504, ZS + 54), 270, uv)
    shop_window(192, 352, -128, 1, ZS + 40, ZS + 128, HIGH)
    vmf.detail([B(176, -248, ZS, 336, -216, ZS + 40)], R["board"], vis=uv)
    for model, u, v, yaw in (("models/props_c17/shelfunit01a.mdl", 90, -230, 0), ("models/props_c17/shelfunit01a.mdl", 90, -300, 0), ("models/props_c17/display_cooler01a.mdl", 356, -290, 180),
                             ("models/props_interiors/furniture_shelf01a.mdl", 350, -430, 180), ("models/props_junk/wood_crate001a.mdl", 110, -450, 20),
                             ("models/props_c17/furnituredresser001a.mdl", 160, -360, 90)):
        static(model, u, v, yaw, ZS, uv)
    # 2. the cafe, next to it: tables at the front, a kitchen behind
    thin("u", -144, 448, 704, [(464, 512) + DOOR, (544, 672, ZS + 40, ZS + 128)], ZS, HIGH, STYLES[1][0], world=True, inner={"south": rw})
    thin("u", -512, 448, 704, [(624, 672) + DOOR], ZS, HIGH, STYLES[1][0], world=True, inner={"north": rw})
    thin("u", -320, 448, 704, [(480, 528) + DOOR], ZS, HIGH, rw, thick=8)
    city_door(W(464, -136, ZS + 54), 270, uv)
    city_door(W(624, -504, ZS + 54), 270, uv)
    shop_window(544, 672, -128, 1, ZS + 40, ZS + 128, HIGH)
    vmf.detail([B(560, -300, ZS, 688, -272, ZS + 40)], R["board"], vis=uv)
    for model, u, v, yaw in (("models/props_wasteland/cafeteria_table001a.mdl", 590, -200, 0), ("models/props_wasteland/cafeteria_bench001a.mdl", 590, -165, 0),
                             ("models/props_wasteland/cafeteria_bench001a.mdl", 590, -235, 0), ("models/props_c17/furniturestove001a.mdl", 480, -480, 0),
                             ("models/props_interiors/refrigerator01a.mdl", 680, -350, 180), ("models/props_interiors/sinkkitchen01a.mdl", 560, -486, 90)):
        static(model, u, v, yaw, ZS, uv)
    # 3. the second shop, north of the street
    thin("u", 512, 384, 704, [(416, 464) + DOOR, (512, 672, ZS + 40, ZS + 128)], ZS, HIGH, STYLES[3][0], world=True, inner={"north": rw})
    thin("u", 816, 384, 704, [(592, 640) + DOOR], ZS, HIGH, STYLES[3][0], world=True, inner={"south": rw})
    thin("u", 680, 384, 704, [(432, 480) + DOOR], ZS, HIGH, rw, thick=8)
    city_door(W(416, 520, ZS + 54), 270, uv)
    city_door(W(592, 824, ZS + 54), 270, uv)
    shop_window(512, 672, 512, -1, ZS + 40, ZS + 128, HIGH)
    vmf.detail([B(520, 600, ZS, 680, 632, ZS + 40)], R["board"], vis=uv)
    for model, u, v, yaw in (("models/props_c17/shelfunit01a.mdl", 410, 600, 0), ("models/props_c17/shelfunit01a.mdl", 678, 560, 180), ("models/props_c17/furniturebed001a.mdl", 450, 760, 0),
                             ("models/props_c17/furnitureradiator001a.mdl", 560, 800, 180), ("models/props_junk/wood_crate001a.mdl", 660, 770, 50)):
        static(model, u, v, yaw, ZS, uv)
    # 4. the tenement: a room below, a stair up the west wall (20 steps), a room above whose two windows look onto the street
    UP = HIGH + 16                                  # the upper floor
    TOP = ZS + 296
    thin("u", 512, 64, 320, [(96, 144) + DOOR, (192, 288, ZS + 40, ZS + 112)], ZS, HIGH, STYLES[2][0], world=True, inner={"north": rw})
    thin("u", 512, 64, 320, [(96, 176, UP + 40, UP + 104), (208, 288, UP + 40, UP + 104)], HIGH, TOP, STYLES[2][0], world=True, inner={"north": rw})
    thin("u", 816, 64, 320, [(240, 288) + DOOR], ZS, TOP, STYLES[2][0], world=True, inner={"south": rw})
    city_door(W(96, 520, ZS + 54), 270, uv)
    city_door(W(240, 824, ZS + 54), 270, uv)
    vmf.detail([B(128, 528, HIGH, 320, 816, UP), B(64, 528, HIGH, 128, 544, UP), B(64, 784, HIGH, 128, 816, UP)], rw, vis=uv, top=R["room_floor"])
    vmf.detail([B(64, 544 + 12 * i, ZS, 128, 556 + 12 * i, ZS + 8 * (i + 1)) for i in range(20)], R["board"], vis=uv, top=R["room_floor"])
    vmf.detail([B(128, 544, UP, 132, 784, UP + 36), B(64, 540, UP, 132, 544, UP + 36)], R["board"], vis=uv)
    for model, u, v, yaw, z in (("models/props_c17/furniturecouch002a.mdl", 280, 640, 180, ZS), ("models/props_c17/furnituretable001a.mdl", 200, 700, 0, ZS),
                                ("models/props_c17/furnitureradiator001a.mdl", 240, 536, 0, ZS), ("models/props_c17/furniturebed001a.mdl", 270, 760, 0, UP),
                                ("models/props_c17/furnituredresser001a.mdl", 300, 600, 180, UP), ("models/props_c17/furniturechair001a.mdl", 190, 560, 90, UP)):
        static(model, u, v, yaw, z, uv)
    vmf.detail(extra, R["trim"], vis=uv)
    vmf.detail(boards + signs, R["board"], vis=uv)
    for (u, v, z, colour) in ((220, -230, HIGH - 14, "255 210 160 60"), (220, -430, HIGH - 14, "255 200 150 30"), (590, -230, HIGH - 14, "255 215 170 60"),
                              (560, -420, HIGH - 14, "220 235 255 40"), (540, 680, HIGH - 14, "255 205 150 50"), (200, 680, HIGH - 14, "255 200 140 45"),
                              (220, 660, TOP - 14, "255 205 160 55")):
        lamp(W(u, v, z), colour)

    # --- the facades, to the owner's recipe: a plinth, a ledge, a band of strip windows (glass on black), a cornice, two rows
    # of windows above. On a wall with nothing behind it the ground floor also has boarded doorways. --------------------------
    found = {}
    for (i, j), spec in cells.items():
        if spec[0] != "open":
            continue
        x, y = i * CELL, j * CELL
        for (di, dj, axis, line, side, a) in ((0, -1, "x", y, 1, x), (0, 1, "x", y + CELL, -1, x), (-1, 0, "y", x, 1, y), (1, 0, "y", x + CELL, -1, y)):
            nb = cells.get((i + di, j + dj))
            if nb is None or nb[0] == "open":
                continue
            found.setdefault((axis, line, side, nb[1] if nb[0] == "solid" else nb[4], None if nb[0] == "solid" else nb[3], spec[1]), []).append(a)
    plinths, trims, blacks, glass, planks = [], [], [], [], []

    def along(axis, a, b, lo, hi, z1, z2):
        return B(a, lo, z1, b, hi, z2) if axis == "x" else B(lo, a, z1, hi, b, z2)
    windows = doorways = 0
    for (axis, line, side, k, room_top, fz), parts in sorted(found.items(), key=lambda kv: tuple(str(v) for v in kv[0])):
        parts.sort()
        start = prev = None
        for a0 in parts + [None]:
            if a0 is not None and start is not None and a0 == prev + CELL:
                prev = a0
                continue
            if start is not None:
                a, b = start, prev + CELL

                def out(p, q, d1, d2, z1, z2):
                    return along(axis, p, q, min(line + d1 * side, line + d2 * side), max(line + d1 * side, line + d2 * side), z1, z2)
                if room_top is None:
                    plinths.append(out(a, b, 0, 8, fz, Z + 128))
                    trims.append(out(a, b, 0, 12, Z + 128, Z + 144))
                    for n, p in enumerate(range(a + 88, b - 152, 224)):
                        if n % 2:
                            blacks.append(out(p, p + 48, 8, 10, fz, fz + 108))                       # a doorway, boarded up
                            trims.append(out(p - 8, p + 56, 8, 14, fz + 108, fz + 120))
                            planks.extend(out(p - 6, p + 54, 10, 13, fz + z, fz + z + 10) for z in (22, 56, 88))
                            doorways += 1
                        else:
                            blacks.append(out(p, p + 144, 0, 2, Z + 160, Z + 224))                   # a strip window, as the owner's (z 816..880)
                            glass.append(out(p, p + 144, 2, 4, Z + 160, Z + 224))
                            windows += 1
                if room_top is None or room_top < Z + 232:
                    trims.append(out(a, b, 0, 10, Z + 232, Z + 248))
                for z0 in (Z + 312, Z + 504):
                    if room_top is not None and z0 < room_top + 24:
                        continue
                    count = (b - a - 16) // 112                  # (as many as the wall takes, spaced evenly along it)
                    gap = (b - a - 96 * count) // (count + 1) if count else 0
                    for n in range(count):
                        p = a + gap + n * (96 + gap)
                        blacks.append(out(p, p + 96, 0, 2, z0, z0 + 96))
                        glass.append(out(p, p + 96, 2, 4, z0, z0 + 96))
                        trims.append(out(p - 8, p + 104, 0, 10, z0 - 8, z0))
                        windows += 1
            start = prev = a0
    vmf.detail(plinths, R["plinth"], vis=dv)
    vmf.detail(trims, R["trim"], vis=dv)
    vmf.detail(blacks, MAT["black"], vis=dv)
    vmf.detail(glass, R["glass"], vis=dv)
    vmf.detail(planks, R["board"], vis=dv)

    # --- the street's own things, as the owner's streets have them: lamp posts (two still lit), benches, a payphone, bins,
    # marks on the road, posters and stains on the walls; and what Ravenholm adds ---------------------------------------------
    for (u, v, lit) in ((160, -20, False), (560, -20, True), (352, 404, False), (700, 404, False), (800, 540, True), (1180, -160, False)):
        static("models/props_c17/lamppost03a_%s.mdl" % ("on" if lit else "off"), u, v, 0, ZS if -128 <= v < 0 or 384 <= v < 512 and u < 768 else Z)
        if lit:
            vmf.point("light_spot", W(u, v + (40 if v < 0 else -40), Z + 330), {
                "_light": "255 214 170 900", "_lightHDR": "-1 -1 -1 1", "_lightscaleHDR": "1", "_cone": "55", "_inner_cone": "30", "_exponent": "1", "_distance": "0",
                "_constant_attn": "0", "_linear_attn": "0", "_quadratic_attn": "1", "angles": "-90 0 0", "pitch": "-90", "style": "0"}, lv)
    for model, u, v, yaw, z in (("models/props_trainstation/benchoutdoor01a.mdl", 440, -100, 0, ZS), ("models/props_trainstation/benchoutdoor01a.mdl", 1000, 540, 180, Z),
                                ("models/props_trainstation/payphone001a.mdl", 730, 490, 180, ZS + 44), ("models/props_trainstation/trashcan_indoor001b.mdl", 610, -100, 0, ZS),
                                ("models/props_trainstation/trashcan_indoor001b.mdl", 250, 480, 0, ZS)):
        static(model, u, v, yaw, z)
    for model, u, v, yaw in (("models/props_vehicles/car002a_physics.mdl", 300, 250, 20), ("models/props_vehicles/car004a_physics.mdl", 600, 130, 200),
                             ("models/props_debris/barricade_tall01a.mdl", 700, 300, 100), ("models/props_foliage/tree_dead01.mdl", 992, 200, 0),
                             ("models/props_junk/trashdumpster02.mdl", 760, -576, 90), ("models/props_wasteland/barricade001a.mdl", 928, -330, 90),
                             ("models/props_vehicles/truck001a.mdl", 760, -990, 35), ("models/props_wasteland/cargo_container01.mdl", 1060, -1000, 80),
                             ("models/props_debris/broken_pile001a.mdl", 300, -580, 40), ("models/props_debris/concrete_chunk01a.mdl", 1120, 80, 0),
                             ("models/props_vehicles/car005a_physics.mdl", 880, 900, 300), ("models/props_debris/barricade_short01a.mdl", 896, 700, 90),
                             ("models/props_junk/trashdumpster02.mdl", 400, 900, 0)):
        static(model, u, v, yaw)
    for model, u, v in (("models/props_junk/sawblade001a.mdl", 860, 60), ("models/props_junk/sawblade001a.mdl", 1010, -700), ("models/props_junk/sawblade001a.mdl", 180, -580),
                        ("models/props_c17/oildrum001_explosive.mdl", 1100, 420), ("models/props_c17/oildrum001_explosive.mdl", 1150, 380),
                        ("models/props_c17/oildrum001_explosive.mdl", 600, -980), ("models/props_junk/wood_pallet001a.mdl", 200, 900), ("models/props_c17/oildrum001.mdl", 780, 240)):
        loose(model, u, v, random.Random(u + v).randrange(0, 360, 15))
    for (texture, u, v, z) in (("decals/decalstreet008a", 200, 190, Z + 1), ("decals/decalstreet008b", 520, 200, Z + 1), ("decals/decalstreet008a", 960, 380, Z + 1),
                               ("decals/decalstreet008b", 930, -500, Z + 1), ("decals/trashdecal01a", 330, -90, ZS + 1), ("decals/trashdecal02a", 620, 450, ZS + 1),
                               ("decals/trashdecal01a", 500, -580, Z + 1), ("decals/decalstain002a", 880, 120, Z + 1),
                               ("decals/decal_posters005a", 30, -127, ZS + 100), ("decals/decalposter014a", 420, -127, ZS + 96), ("decals/decal_posterbreen", 350, 511, ZS + 100),
                               ("decals/decalposter014a", 767, -160, Z + 110), ("decals/decal_posters005a", 1215, 200, Z + 110), ("decals/decal_posterbreen", 1215, 60, Z + 110)):
        vmf.point("infodecal", W(u, v, z), {"texture": texture}, dv)
    for (u, v, colour) in ((992, 200, "255 150 80 140"), (896, 720, "255 170 100 70"), (930, -500, "255 160 90 90"), (860, -990, "255 150 80 110"), (400, -576, "200 220 255 40")):
        lamp(W(u, v, Z + 150), colour)
    for (u, v) in ((352, 192), (992, 200), (928, -480), (860, -990), (500, 896), (400, -576)):
        vmf.point("env_cubemap", W(u, v, Z + 72), {"cubemapsize": "0"}, dv)
    for (u, v, z) in ((220, -250, ZS), (590, -220, ZS), (540, 680, ZS), (200, 680, ZS), (220, 660, UP)):
        vmf.point("env_cubemap", W(u, v, z + 72), {"cubemapsize": "0"}, uv)

    # --- where the city's people (and what is made here) can walk ------------------------------------------------------------
    node_id = [args.first_node]

    def node(x, y, z):
        vmf.point("info_node", (x, y, z + 16), {"nodeid": node_id[0]}, "LC ravenholm: path nodes")
        node_id[0] += 1
    for (i, j), spec in sorted(cells.items()):
        if spec[0] == "open" and i % 2 == 1 and j % 2 == 1:
            node(X0 + i * CELL + 32, Y0 + j * CELL + 32, spec[1])
    for (u, v, z) in ((120, -136, ZS), (120, -230, ZS), (300, -280, ZS), (232, -332, ZS), (200, -430, ZS), (312, -504, ZS), (312, -560, Z),
                      (488, -136, ZS), (488, -230, ZS), (640, -230, ZS), (504, -316, ZS), (600, -420, ZS), (648, -504, ZS), (648, -560, Z),
                      (440, 520, ZS), (460, 680, ZS), (600, 720, ZS), (616, 824, ZS), (616, 880, Z),
                      (120, 520, ZS), (200, 620, ZS), (264, 760, ZS), (264, 824, ZS), (264, 880, Z),
                      (160, 600, ZS), (96, 646, ZS + 72), (96, 742, ZS + 136), (96, 800, UP), (220, 700, UP), (250, 580, UP)):
        node(X0 + u, Y0 + v, z)
    for x in range(1088, X0, 128):
        node(x, Y0 + 192, Z)                                 # along the owner's own last stretch of street
    node(1312, ys - 40, ZS)
    node(1312, ys + 60, ZS)
    for i in range(3, STEPS, 5):
        node(1312, ya + 12 * i + 6, ZS - 8 * (i + 1))
    for y in range(yb + 40, slot_y, 128):
        node(1312, y, FLOOR)
    for y in (slot_y + 40, wall_y - 30):
        node(1234, y, FLOOR)
    if not test:
        vmf.point("info_node", (1234, wall_y + 40, 307 + 16), {"nodeid": node_id[0]}, "LC ravenholm: path nodes", outside=True)   # on the sewer's own ledge
        node_id[0] += 1

    # --- the checks: sealed, with the owner's own street (which is not in this file) stopped round ----------------------------
    lobby = [(1008, Y0 - 192, base - 16, 1024, Y0 + 576, SKY + 32), (1024, Y0 - 192, base - 16, X0, Y0 + 576, base), (1024, Y0 - 192, SKY + 16, X0, Y0 + 576, SKY + 32),
             (1024, Y0 + 512, base, 1184, Y0 + 576, SKY + 16), (1200, ys, top_h, 1424, ys + 16, SKY + 16)]
    behind = (TX1, wall_y + 8, 239, 1252, wall_y + 24, CEIL + 16)
    if test:
        xv = "LC ravenholm: for testing alone (never in the real map)"
        for box in lobby + [behind]:
            vmf.world_box(box, sky, sky, sky, vis=xv)
        for box, top, z in (((1024, Y0 + 64, base, X0, Y0 + 320), R["road"], Z), ((1024, Y0, base, 1216, Y0 + 64), R["strip_s"], Z), ((1024, Y0 + 384, base, 1152, Y0 + 512), R["walk"], ZS)):
            vmf.world_box(box + (z,), R["kerb"], top=top, vis=xv)                                             # the owner's roadway and its edges, stood in for
        test_extras(vmf, (1120, Y0 + 192, Z + 16), 0, xv)
    problems, air = check(vmf, W(352, 192, Z + 64), [] if test else lobby + [behind])
    args.expect_overlap = set(DELETE) | set(STANDS_IN)
    seals = sum(1 for _, s in vmf.boxes if s)
    xs = [b[0] for b, _ in vmf.boxes] + [b[3] for b, _ in vmf.boxes]
    ys_ = [b[1] for b, _ in vmf.boxes] + [b[4] for b, _ in vmf.boxes]
    print("ravenholm: %d sealing brushes, %d entities (%d path nodes, ids %d to %d)" % (seals, len(vmf.ents), node_id[0] - args.first_node, args.first_node, node_id[0] - 1))
    print("  it fills x %d to %d, y %d to %d, z %d to %d; the roadway is z %d, the pavements %d" % (min(xs), max(xs), min(ys_), max(ys_), 239, SKY + 16, Z, ZS))
    print("  facades: %d plinths, %d windows (glass on black), %d boarded doorways; 4 buildings to go into (a shop, a cafe, a second shop, a tenement of two floors), 9 doors" % (
        len(plinths), windows, doorways))
    print("  the gate: the owner's own four brushes: the two rails draw back into their pillars, then the slab lowers 290 straight into the ground, the outline with it "
          "(lc_raven_gate_open, _shut)")
    print("  the tunnel: from a house at (1312 %d), %d steps down, then %d north at z %d to the sewer wall at y %d; a Combine door across it at y %d (lc_raven_door_open, _shut); "
          "a hatch opened by hand in the sewer wall, x %d..1252" % (ys, STEPS, slot_y - yb, FLOOR, wall_y, DY, TX1))
    print("  the owner deletes brushes 65929, 51870, 62363 (the wall and its rails), 15623 (the unseen wall round it), 33530 (a black sheet in it), 28290 (the sewer wall) "
          "and 34874 (the bare strip of road)")
    if problems:
        for p in problems:
            print("  PROBLEM: " + p)
    else:
        print("  checked: every corner on the grid; sealed (%s)" % ("by itself: this is the test version" if test else
                                                                 "with the owner's street, which it opens onto, stopped round: by itself this file is OPEN there and will leak"))
    return vmf, problems
