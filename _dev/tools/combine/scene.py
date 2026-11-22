"""The Combine scene, a test map to compile and walk: a stretch of old city street (plain blocks, a road, pavements,
warm light), the Combine's wall chain across it with a gate on the road, the Combine building behind it, and a Combine
mass driven into one of the old blocks; Valve's Combine props (barricades in rows, a booth, wall lights with their
beams, creeping walls, pipes); a sky, a sun, a player start at the street's south end; sealed (checked as the bunker's
builder does: the air from the start must not reach the outside)."""
import random

from map_build import Vmf, test_extras, check as seal_check
from . import tops as TP
from .building import building
from .chain import wall_chain, intrusion
from .geom import SKY, NODRAW, FLOOR
from .piece import Sink

X1, X2, Y1, Y2, ZT = -2560, 2560, -2816, 4352, 2304
ROAD, WALK, KERB = "stone/stonefloor006d_c17", "concrete/concretefloor016a", "concrete/concretefloor039b"
BAND, PLINTH, GLASS = "stone/stonewall050f", "concrete/concretewall002c", "glass/glasswindow010a"
STYLES = (("brick/brickwall053e", "concrete/concretewall074c"), ("plaster/plasterwall047b", "plaster/plasterwall042c"),
          ("brick/brickwall037a", "brick/brickwall037c"), ("concrete/concretewall059e", "concrete/concretewall055b"))
CHAIN_Y, GATE = 1216, (-512, 512)
BLOCKS = (("w1", (X1, Y1, 0, -448, -1536, 512)), ("w2", (X1, -1216, 0, -448, 448, 640)),
          ("e1", (448, Y1, 0, X2, -1792, 448)), ("e2", (448, -1472, 0, X2, 448, 576)))
START = (0, -2496, 16)


def tex_scale(text):
    """Texture scale by the face's longest side, as Valve's (under 512: 0.25; to 1024: 1; over: 2)."""
    parts = text.split("\t\tside\n")
    for i in range(1, len(parts)):
        vs = [[int(c) for c in m.split('"')[0].split()] for m in parts[i].split('"v" "')[1:]]
        e = max(max(v[k] for v in vs) - min(v[k] for v in vs) for k in range(3))
        parts[i] = parts[i].replace('0] 0.25"', '0] %s"' % ("0.25" if e < 512 else "1" if e <= 1024 else "2"))
    return "\t\tside\n".join(parts)


def put(v, sink, vis):
    """A structure's sink into the map: Combine solids as one func_detail, old walls into the world, lights and props."""
    if sink.solids:
        v.detail_shapes(sink.solids, vis)
        v.ents[-1] = tex_scale(v.ents[-1])
    for o in sink.old:
        v.world.append(v.convex_text(o, vis))
    for box, sides, top, bottom in sink.boxes:
        v.world_box(box, sides, top, bottom, vis)
    for pos, colour in sink.lights:
        v.point("light", tuple(int(c) for c in pos), {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_lightscaleHDR": "1"}, vis)
    for model, pos, (p, y, rl) in sink.props:
        v.point("prop_static", tuple(int(c) for c in pos), {"model": model, "angles": "%d %d %d" % (p, y, rl), "skin": "0", "solid": "6",
                                                            "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "disableshadows": "0"}, vis)
    for pos, yaw, pitch in sink.lamps:
        lamp(v, pos, yaw, pitch, vis)


def lamp(v, pos, yaw, pitch, vis):
    """combine_light002a with its back on the wall, turned to aim (yaw on 15s), lit as Valve's: a light_spot 147 226 240
    at 2000, cone 35 inner 12, pitched down, 22 under the lamp; a point_spotlight 768 long and 96 wide aimed with it."""
    import math
    yaw = int(round(yaw / 15.0)) * 15 % 360
    dx, dy = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    x, y, z = (int(c) for c in pos)
    v.point("prop_static", (x + int(round(4 * dx)), y + int(round(4 * dy)), z), {
        "model": "models/props_combine/combine_light002a.mdl", "angles": "0 %d 0" % ((yaw + 180) % 360), "skin": "0", "solid": "6",
        "fademindist": "-1", "fademaxdist": "0", "fadescale": "1", "disableshadows": "1"}, vis)
    sx, sy = x + int(round(18 * dx)), y + int(round(18 * dy))
    v.point("light_spot", (sx, sy, z - 22 + 44), {"_light": "147 226 240 2000", "_lightHDR": "-1 -1 -1 1", "_lightscaleHDR": "1", "_cone": "35",
                                                  "_inner_cone": "12", "_exponent": "1", "_quadratic_attn": "1", "angles": "0 %d 0" % yaw,
                                                  "pitch": str(-pitch), "style": "0"}, vis)
    v.point("point_spotlight", (sx, sy, z + 30), {"angles": "%d %d 0" % (pitch, yaw), "spawnflags": "1", "spotlightlength": "768",
                                                  "spotlightwidth": "96", "rendercolor": "147 226 240", "renderamt": "160", "HDRColorScale": "1.0"}, vis)


def old_block(v, name, box, style, door=None, vis="LC combine scene: old street"):
    """A plain stand-in old block: walls in two materials (ground floor and above), a plinth and a band at each floor
    and a cornice (lesson valve-wall-bands), a row of windows on each floor of its street face."""
    x1, y1, _, x2, y2, h = box
    low, up = STYLES[style]
    street = x2 if x2 <= 0 else x1
    if door is None:
        v.world_box((x1, y1, 0, x2, y2, 192), low, up, NODRAW, vis)
        v.world_box((x1, y1, 192, x2, y2, h), up, "concrete/concreteceiling004a", NODRAW, vis)
    for z, hh in ((192, 16), (h - 24, 40)) + tuple((z, 12) for z in range(384, h - 120, 192)):
        strips = [(max(X1, x1 - 8), y2 - 8, min(X2, x2 + 8), y2 + 8)]
        if y1 > Y1:
            strips.append((max(X1, x1 - 8), y1 - 8, min(X2, x2 + 8), y1 + 8))
        for xe in (x1, x2):
            if X1 < xe < X2:
                strips.append((xe - 8, max(Y1, y1 + 8), xe + 8, y2 - 8))
        for a, b, c, d in strips:
            v.world_box((a, b, z, c, d, z + hh), BAND, BAND, BAND, vis)
    out = -1 if street == x1 else 1
    sx0, sx1 = sorted((street, street + 8 * out))
    y = max(Y1, y1)
    for g0, g1 in ([(door[0], door[1])] if door else []) + [(y2, y2)]:
        if g0 - y >= 16:
            v.world_box((sx0, y, 0, sx1, g0, 48), PLINTH, PLINTH, PLINTH, vis)
        y = g1
    v.world_box((max(X1, x1 - 8), y2, 0, min(X2, x2 + 8), y2 + 8, 48), PLINTH, PLINTH, PLINTH, vis)
    if y1 > Y1:
        v.world_box((max(X1, x1 - 8), y1 - 8, 0, min(X2, x2 + 8), y1, 48), PLINTH, PLINTH, PLINTH, vis)
    wins = []
    for z in range(256, h - 120, 192):
        for wy in range(y1 + 96, y2 - 160, 192):
            wx0, wx1 = sorted((street, street + 2 * out))
            wins.append((wx0, wy, z, wx1, wy + 64, z + 96))
    if wins:
        v.detail(wins, GLASS, vis)


def street_lights(v, vis="LC combine scene: old street"):
    for y in range(-2560, 448, 512):
        for x in (-424, 424):
            v.point("light", (x, y + (128 if x > 0 else 0), 288), {"_light": "255 224 144 180", "_lightHDR": "-1 -1 -1 1", "_lightscaleHDR": "1"}, vis)


def props(v, chain, r, vis="LC combine scene: props"):
    """Valve's Combine dressing on the street side: tall barricades in a row at 128 with their backs to the gate, a row
    of medium ones at 64 across the plaza (one yaw, sunk 2), a booth by the way through."""
    g0, g1 = chain["gate"]
    keys = {"skin": "0", "solid": "6", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}
    for i in range(4):
        v.point("prop_static", (g0 - 136 - 128 * i, CHAIN_Y - 240, -2), dict(keys, model="models/props_combine/combine_barricade_tall02b.mdl", angles="0 270 0"), vis)
    for i in range(9):
        v.point("prop_static", (-1344 + 64 * i, CHAIN_Y - 512, -2), dict(keys, model="models/props_combine/combine_barricade_med01a.mdl", angles="0 270 0"), vis)
    v.point("prop_static", (g1 + 96, CHAIN_Y - 200, 0), dict(keys, model="models/props_combine/combine_booth_short01a.mdl", angles="0 0 0"), vis)


def scene(out, seed=1, tries=6):
    """The scene, drawn up to tries times; the draw whose Combine is nearest Valve's numbers (measure.distance) is kept."""
    import os
    from .measure import check, distance
    best = None
    for n in range(tries):
        tmp = "%s.draw%d" % (out, n)
        info, problems = draw(tmp, seed, n)
        nums = check(tmp, quiet=True)
        dist = distance(nums)
        if best is None or dist < best[0]:
            if best:
                os.remove(best[3])
            best = (dist, info, problems, tmp, n, nums)
        else:
            os.remove(tmp)
    dist, info, problems, tmp, n, nums = best
    os.replace(tmp, out)
    info["draw"], info["distance"] = n + 1, dist
    return info, problems


def draw(out, seed, n):
    r = random.Random("scene %d %d" % (seed, n))
    v = Vmf()
    sk = "LC combine scene: ground and sky"
    # the ground: the road, the pavements and plaza, the Combine's yard
    for box, top in (((-256, Y1, -32, 256, 640, 0), ROAD), ((X1, Y1, -32, -256, 640, 0), WALK), ((256, Y1, -32, X2, 640, 0), WALK),
                     ((X1, 640, -32, X2, Y2, 0), FLOOR)):
        v.world_box(box, NODRAW, top, NODRAW, sk)
    for x0, x1 in ((-448, -256), (256, 448)):
        v.world_box((x0, Y1, 0, x1, 448, 8), KERB, WALK, NODRAW, "LC combine scene: old street")
    for b in ((X1 - 16, Y1, -32, X1, Y2, ZT), (X2, Y1, -32, X2 + 16, Y2, ZT), (X1 - 16, Y1 - 16, -32, X2 + 16, Y1, ZT),
              (X1 - 16, Y2, -32, X2 + 16, Y2 + 16, ZT), (X1 - 16, Y1 - 16, ZT, X2 + 16, Y2 + 16, ZT + 16)):
        v.world_box(b, SKY, SKY, SKY, sk)
    # the old street; one block with the Combine driven into it
    ins = Sink()
    info = {}
    for i, (name, box) in enumerate(BLOCKS):
        style = (i + seed) % len(STYLES)
        if name == "e2":
            info["intrusion"] = intrusion(box, ins, r, STYLES[style][0])
            old_block(v, name, box, style, door=info["intrusion"]["door"])
        else:
            old_block(v, name, box, style)
    put(v, ins, "LC combine scene: intrusion")
    street_lights(v)
    # the wall chain across the street, the building behind it
    ch = Sink()
    info["chain"] = wall_chain(ch, r, X1 + 576, X2 - 576, CHAIN_Y, GATE)
    put(v, ch, "LC combine scene: wall chain")
    info["building"] = building((-1024, 1792, 0, 1024, 3200, 1536), seed * 10 + n)
    put(v, info["building"]["sink"], "LC combine scene: building")
    props(v, info["chain"], r)
    # a Combine tower standing on the yard's ground beside the building, as Valve stands all sixteen of theirs
    v.point("prop_static", (1600 if info["building"]["wing"] == "w" else -1600, 2560, 274), {
        "model": "models/props_combine/combinetower001.mdl", "angles": "0 %d 0" % TP.own(r, "tower").choice((0, 15, 30, 300)), "skin": "0", "solid": "6",
        "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}, "LC combine scene: props")
    test_extras(v, START, 90, sk)
    problems, air = seal_check(v, (START[0], START[1], 64), [])
    with open(out, "w") as fh:
        fh.write(v.text())
    return info, problems
