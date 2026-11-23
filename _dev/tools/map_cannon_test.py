#!/usr/bin/env python3
"""The Combine autogun's test map (the owner, 23 November: "can we build all of these out now?"): Episode Two's
three-way autogun (the piece valve_ep2_cannon, docs/dev/prefabs.md, "the Combine autogun") placed with everything it
carries, in a yard with the garage it guards, to compile and play by itself.

What is in it, from the piece: the turret bay (Valve's world brushes as world, so its two areaportal windows work), the
three guns and their finders aiming at every player, the clips over the guns, the generator with its grenade intake,
the blow-up and the wall it opens, the safe zone in the bay, the demonstration fire kit, and its own path nodes with
the link through the blown wall. Round it, for the test only: a sealed yard under the sky, the garage north of the bay
(its door on the west, an areaportal in it), three frag grenades by the door, and three buttons on the garage's back
wall (left to right: demonstration fire, kill it outright, zombies into the yard). The spawn is west of the garage,
out of the guns' sight.

    python3 map_cannon_test.py              # writes lc_cannon_test.vmf, after its checks

The checks: the yard is sealed and every entity is in it; the garage's areaportal is filled; the bay and garage are one
area and the yard another, with only the piece's two areaportals and the garage's between them (or the compile fails);
a player can walk from the spawn to every path node (map_walk.py); every model and material exists (map_assets.py).
"""

import argparse
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import map_prefab
from map_build import MAT, check, test_extras
from map_modules import Build, Frame, Mod

GROUND = "nature/blendgravelmud02"      # (the yard round the bay in Valve's map)
METAL, ROOF = "metal/metalwall014a", "metal/metalroof005a"
SPAWN = (-400, 320, 8)
YARD = (0, -600, 64)       # (the air the checks start from)


def build(out):
    b = Build("cannon_test", 784, 1)
    b.test = True
    m = Mod(b, Frame(0, 0, 0, 64), "cannon")
    vmf, vis = b.vmf, b.vis + ": test yard"
    pf = map_prefab.load("valve_ep2_cannon")
    tag = map_prefab.place(m, pf, 0, 0, 0, 0, world=True, portals=True)["placed_as"]

    nd, sky = MAT["nodraw"], MAT["sky"]
    # The yard: ground round the piece's floor (x -140 to 496, y -120 to 114) and the garage's, a slab under it all, sky round.
    vmf.world_box((-1616, -1816, -144, 1616, 1016, -128), nd, vis=vis)
    for box in ((-1600, -1800, -128, 1600, -120, 0), (-1600, 538, -128, 1600, 1000, 0), (-1600, -120, -128, -140, 114, 0),
                (-1600, 114, -128, -96, 538, 0), (496, -120, -128, 1600, 114, 0), (512, 114, -128, 1600, 538, 0)):
        vmf.world_box(box, nd, top=GROUND, vis=vis)
    for box in ((-1616, -1816, -128, -1600, 1016, 1040), (1600, -1816, -128, 1616, 1016, 1040), (-1600, -1816, -128, 1600, -1800, 1040),
                (-1600, 1000, -128, 1600, 1016, 1040), (-1600, -1800, 1024, 1600, 1000, 1040)):
        vmf.world_box(box, sky, top=sky, bottom=sky, vis=vis)
    # The garage north of the bay (Valve's stood there, its floor 4 over the bay's): inside x -80 to 496, y 122 to 522.
    vmf.world_box((-96, 114, -128, 512, 538, 4), nd, top="concrete/concretefloor_bunker02a", vis=vis)
    for box in ((-96, 114, 4, -80, 250, 144), (-96, 378, 4, -80, 538, 144), (-96, 250, 112, -80, 378, 144),
                (496, 114, 4, 512, 538, 144), (-80, 522, 4, 496, 538, 144)):
        vmf.world_box(box, METAL, vis=vis)
    vmf.world_box((-80, 114, 128, 496, 522, 144), METAL, top=ROOF, bottom=ROOF, vis=vis)
    door = (-96, 250, 4, -80, 378, 112)
    vmf.areaportal(door, vis, name="portal.garage.door")
    vmf.point("light", (200, 320, 112), {"_light": "255 236 214 160", "_lightHDR": "-1 -1 -1 1", "_lightscaleHDR": "1", "_quadratic_attn": "1"}, vis)
    vmf.point("light", (60, 60, 100), {"_light": "214 230 255 60", "_lightHDR": "-1 -1 -1 1", "_lightscaleHDR": "1", "_quadratic_attn": "1"}, vis)
    for y in (280, 304, 328):
        vmf.point("weapon_frag", (-40, y, 16), {"angles": "0 0 0"}, vis)
    # Three buttons on the back wall, tinted: red demonstration fire, amber kill it outright, green zombies into the yard.
    for x, colour, target, inp in ((100, "255 64 64", "relay.cannon.show" + tag, "Trigger"), (160, "255 176 32", "relay.shortcut.kill.cannon" + tag, "Trigger"),
                                   (220, "64 255 96", "ptemplate.test.zombies", "ForceSpawn")):
        vmf.brush_entity("func_button", {"spawnflags": "1025", "wait": "3", "rendercolor": colour, "sounds": "14"},
                         [(x, 514, 48, x + 24, 522, 72)], "metal/metalwall014a", vis, connections=[("OnPressed", target, inp, "", 0)])
    vmf.point("point_template", (0, -1100, 64), {"targetname": "ptemplate.test.zombies", "spawnflags": "2",
                                                  "Template01": "test.zombie"}, vis)
    for x, y in ((-300, -1200), (0, -1300), (300, -1200)):
        vmf.point("npc_zombie", (x, y, 8), {"targetname": "test.zombie", "angles": "0 90 0"}, vis)
    test_extras(vmf, SPAWN, 0, vis)

    # The checks see what seals in the compiler: our brushes, the piece's world brushes, and its areaportals shut.
    world = [s["sides"] for s in pf["solids"] if s["from"] == "worldspawn" and not all("tools/" in x["material"].lower() for x in s["sides"])]
    portals = [b for w in pf["wiring"] if w["classname"] in ("func_areaportal", "func_areaportalwindow") for b in w["brushes"]]
    vmf.boxes += [(bx, True) for bx in boxes_of(world)]
    problems, _ = check(vmf, YARD, boxes_of(portals))
    with open(out, "w") as f:
        f.write(vmf.text())
    return problems


def boxes_of(brushes):
    return [map_prefab.corner_box([c for s in sides for c in (s["verts"] or s["corners"] or s["plane"])]) for sides in brushes]


def main():
    ap = argparse.ArgumentParser(description="Build the Combine autogun's test map.")
    ap.add_argument("--out", default="lc_cannon_test.vmf")
    args = ap.parse_args()
    out = os.path.join(HERE, args.out) if not os.path.isabs(args.out) else args.out
    problems = build(out)
    for tool in (["map_walk.py", out], ["map_assets.py", out]):
        res = subprocess.run([sys.executable, os.path.join(HERE, tool[0])] + tool[1:], cwd=HERE, capture_output=True, text=True)
        text = res.stdout + res.stderr
        problems += [l.strip() for l in text.splitlines() if "PROBLEM" in l or "ERROR" in l or "Traceback" in l]
        print("  %s: %s" % (tool[0], (text.strip().splitlines() or ["(nothing)"])[-1]))
    for p in problems:
        print("  PROBLEM: " + p)
    print("written: %s%s" % (out, "" if not problems else " (with %d problems)" % len(problems)))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
