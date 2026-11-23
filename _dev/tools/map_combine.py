#!/usr/bin/env python3
"""
Living City: Combine architecture by the study's recipe (for the owner's PC, never the server)

The owner, 21 November: reproduce the Combine's odd, unnerving, unsymmetrical architecture; and, of the first test map,
"3 little wall sections ... not like it generated a building or scene". The recipe and its numbers come from Valve's
Citadel maps (_dev/reference/valve_citadel/notes/architecture_notes.md, lessons valve-combine-*): masses on a 256
bay in 128 courses; plates 2, 4, 8 or 16 thick in 3 to 6 relief levels (first step 48 to 64, then 4 or 8); leans of
1 in 4, 5 in 16, 1 in 8; plan turns of 45, 1 in 2, 1 in 4, 22.5 as whole-number frames; ribs on a 256 rhythm broken by
pairs; fins against walls and few small plates (the owner, 22 November: beside doors only); cold light panels flush in the plates; no wall's relief and no passage's
two sides each other's mirror (the study's walls.py test, a draw that fails it drawn again).

    python3 map_combine.py scene --out lc_combine_scene.vmf [--seed N]  the scene: an old street, the wall chain across
                                                                       it with a gate, the building behind, an intrusion
    python3 map_combine.py test --out lc_combine_test.vmf [--seed N]    one of each small piece (wall, gate, tower, skin)
    python3 map_combine.py check FILE.vmf                               the study's numbers for the Combine in any VMF
    python3 map_combine.py perimeter --out lc_combine_perimeter.vmf [--length 3072] [--height 768] [--seed N]
                                                                       the city's perimeter wall, a template to repeat

Structures (combine/): building (building.py: a centred mass 1536 to 2048 across with an off-centre skin, a turned
wing, a gate with unequal sides, a tall hall with walkways), wall_chain and intrusion (chain.py), the pieces
(piece.py), their tops (tops.py: the owner, 22 November, "curved, like the combine bunkers, or pointed or some weird
needless slope": lopsided vaults, ridges, sheds, steps, and Valve's own fins and parapets on flat ones; no points), the
shapes and turned frames (geom.py), the study's numbers (measure.py), the scene (scene.py).
No module of the game's maps uses any of it yet: the owner looks at the scene first.
"""
import argparse
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from map_build import Vmf, test_extras  # noqa: E402
from combine.geom import COLD, FLOOR, SKY, NODRAW  # noqa: E402
from combine.measure import check, score  # noqa: E402
from combine.piece import Piece  # noqa: E402
from combine.scene import scene, tex_scale  # noqa: E402
from combine.seat import seated  # noqa: E402


def combine_piece(kind, box, seed=1, tries=60):
    """A Combine piece of kind (wall, gate, tower, skin) in box (x1 y1 z1 x2 y2 z2): {'solids', 'old', 'lights', ...}.
    By the study's test a draw is kept when its biggest wall of 3+ relief levels matches its mirror below 0.9, one
    such wall is below 0.6, and the two sides of every passage match below 0.5; else it is drawn again (up to tries
    times, then the least mirrored draw is kept: 'mirrored' says what it still misses)."""
    best = None
    for n in range(tries):
        p = Piece.from_box(box, random.Random("%s %d %d" % (kind, seed, n)))
        getattr(p, kind)()
        bad, walls, pas = score(p.solids, p.old)
        if best is None or bad < best[0]:
            best = (bad, n + 1, p, walls, pas)
        if not bad:
            break
    bad, n, p, walls, pas = best
    return {"solids": p.solids, "old": p.old, "lights": p.lights, "draw": n, "mirrored": bad, "walls": walls, "passages": pas, "turns": p.turns, "thick": p.thick}


LAYOUT = (("skin", (0, 1792, 0, 768, 2432, 384)), ("wall", (640, 1152, 0, 2176, 1664, 512)),
          ("gate", (2048, 384, 0, 3072, 896, 512)), ("tower", (3200, -320, 0, 3840, 320, 1280)))


def test_map(out, seed):
    v = Vmf()
    for kind, box in LAYOUT:
        p = combine_piece(kind, box, seed)
        vis = "LC combine: " + kind
        v.detail_shapes(p["solids"], vis)
        v.ents[-1] = tex_scale(v.ents[-1])
        for o in p["old"]:
            v.world.append(v.convex_text(o, "LC combine: old room"))
        for pos, colour in p["lights"]:
            v.point("light", pos, {"_light": colour, "_lightHDR": "-1 -1 -1 1", "_lightscaleHDR": "1"}, vis)
        print("%-6s %3d solids, turns %s, plates %s, draw %d%s; walls %s; passages %s" % (
            kind, len(p["solids"]), "/".join("%g" % t for t in p["turns"]), "/".join(map(str, p["thick"])), p["draw"],
            ("", " (no wall below 0.6)", " (still mirrored)")[min(2, p["mirrored"])],
            " ".join("%.2f" % s for s, lv, a in p["walls"] if lv >= 3) or "-", " ".join("%.2f" % m for m in p["passages"]) or "-"))
    x1, y1, x2, y2, z2 = -256, -576, 4096, 2688, 1664
    sk = "LC combine: floor and sky (for testing alone)"
    v.world_box((x1, y1, -16, x2, y2, 0), NODRAW, FLOOR, NODRAW, sk)
    for b in ((x1 - 16, y1, -16, x1, y2, z2), (x2, y1, -16, x2 + 16, y2, z2), (x1 - 16, y1 - 16, -16, x2 + 16, y1, z2),
              (x1 - 16, y2, -16, x2 + 16, y2 + 16, z2), (x1 - 16, y1 - 16, z2, x2 + 16, y2 + 16, z2 + 16)):
        v.world_box(b, SKY, SKY, SKY, sk)
    test_extras(v, (1216, 256, 16), 90, sk)
    with open(out, "w") as fh:
        fh.write(v.text())
    print("wrote %s" % out)


def perimeter_map(out, seed, length=3072, H=768):
    """The perimeter wall's template on a test map: the wall along y 0 from x 0 to length, its ribbed outer face to
    the south, a floor and a sky, the player standing out on the south looking at it."""
    from combine.chain import perimeter
    from combine.piece import Sink
    from combine.scene import put
    r = random.Random("perimeter %d" % seed)
    sink = Sink()
    info = perimeter(sink, r, 0, length, 0, H, outer=-1)
    v = Vmf()
    put(v, sink, "LC combine: the perimeter wall")
    x1, y1, x2, y2, z2 = -512, -2048, length + 512, 768, H + 1024
    sk = "LC combine: floor and sky (for testing alone)"
    v.world_box((x1, y1, -16, x2, y2, 0), NODRAW, FLOOR, NODRAW, sk)
    for b in ((x1 - 16, y1, -16, x1, y2, z2), (x2, y1, -16, x2 + 16, y2, z2), (x1 - 16, y1 - 16, -16, x2 + 16, y1, z2),
              (x1 - 16, y2, -16, x2 + 16, y2 + 16, z2), (x1 - 16, y1 - 16, z2, x2 + 16, y2 + 16, z2 + 16)):
        v.world_box(b, SKY, SKY, SKY, sk)
    test_extras(v, (length // 2, -1400, 16), 90, sk)
    with open(out, "w") as fh:
        fh.write(v.text())
    print("perimeter: %d runs (%s), tops %s" % (len(info["runs"]), " ".join(str(k) for _, k in info["runs"]), ", ".join(info["tops"])))
    print("wrote %s" % out)


def scene_map(out, seed):
    info, problems = scene(out, seed)
    b, c, i = info["building"], info["chain"], info["intrusion"]
    print("building  %dx%dx%d, wing on the %s side, draw %d%s; walls %s; passages %s" % (
        b["size"] + (b["wing"], b["draw"], ("", " (no wall below 0.6)", " (still mirrored)")[min(2, b["mirrored"])],
                     " ".join("%.2f" % s for s, lv, a in b["walls"] if lv >= 3) or "-", " ".join("%.2f" % m for m in b["passages"]) or "-")))
    print("chain     %d runs, turns %s; gate %d..%d" % (len(c["runs"]), " ".join("%d/%d" % d for _, d, _ in c["runs"]), *c["gate"]))
    print("intrusion turned %s, door at y %d..%d" % (i["turn"], i["door"][0], i["door"][1]))
    print("tops     building %s; intrusion %s; chain %s" % (b["top"], i["top"], ", ".join(c["tops"])))
    print("draw %d of the scene kept (nearest Valve's numbers: %.2f off)" % (info["draw"], info["distance"]))
    print("sealed" if not problems else "\n".join("PROBLEM: " + p for p in problems))
    walls = seated(out)          # the owner, 22 November: creeping walls never floating or tilted
    bad = ["PROBLEM: %s at %s: %s" % (m.split("/")[-1], " ".join("%g" % c for c in o), f) for m, o, a, f in walls if f]
    print("\n".join(bad) or "creeping walls: %d, each upright, its back on a wall and its foot on a floor" % len(walls))
    print("wrote %s" % out)


def main():
    ap = argparse.ArgumentParser(description="Combine architecture by the study's recipe, and the study's numbers on any VMF.")
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name, helptext, default in (("scene", "the scene: old street, wall chain with a gate, the building, an intrusion", "lc_combine_scene.vmf"),
                                    ("test", "a test map: a floor, a sky box, a player start, one of each small piece", "lc_combine_test.vmf")):
        t = sub.add_parser(name, help=helptext)
        t.add_argument("--out", default=os.path.join(HERE, default))
        t.add_argument("--seed", type=int, default=1)
    sub.add_parser("check", help="the study's numbers for the Combine in a VMF (read as text only)").add_argument("vmf")
    t = sub.add_parser("perimeter", help="the city's perimeter wall as a template: a straight run of it on a test map")
    t.add_argument("--out", default=os.path.join(HERE, "lc_combine_perimeter.vmf"))
    t.add_argument("--seed", type=int, default=1)
    t.add_argument("--length", type=int, default=3072)
    t.add_argument("--height", type=int, default=768)
    a = ap.parse_args()
    {"scene": lambda: scene_map(a.out, a.seed), "test": lambda: test_map(a.out, a.seed), "check": lambda: check(a.vmf),
     "perimeter": lambda: perimeter_map(a.out, a.seed, a.length, a.height)}[a.cmd]()


if __name__ == "__main__":
    main()
