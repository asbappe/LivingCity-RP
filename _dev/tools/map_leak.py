#!/usr/bin/env python3
"""Where does a map leak? (the owner's compile of City 18 with the suppression core, 28 November: "**** leaked ****
Entity prop_static (1589.89 -4314.11 664.11) leaked!". The entity vbsp names is only the first one in the file that
stands in leaked air: it says nothing of where the hole is, and the pointfile needs the game to read.)

    python3 map_leak.py FILE.vmf --from X Y Z --box X1 Y1 Z1 X2 Y2 Z2 [--cell 4] [--void bottom]

Lays the box on a grid of cubes as vbsp seals a map: only the world's brushes shut space (never an entity's, never
func_detail), and of those not a displaced one, nor one with a face you can see through or a tool face that seals
nothing (clip, trigger, hint, skip, areaportal, origin...); a cube is shut if such a brush TOUCHES it (so a wall thinner
than a cube still shuts: City 18 closes a doorway with a plate 2 thick, which a test of the cubes' middles took for a
hole; the price is that a gap narrower than a cube is not seen). The air is then labelled. If the air at --from is one piece with the air on the box's --void face (bottom by default:
choose a face of the box that lies wholly outside the map), the map leaks there, and the hole is found by thickening
every wall a cube at a time until the two come apart: the cubes that then part them are the hole. Prints each hole's
box. A hole thinner than a cube is not seen (--cell 2 for a hairline, on a small box).
Needs numpy and scipy."""
import argparse
import re
import sys

import numpy as np
from scipy import ndimage

NOSEAL_TOOLS = ("toolsclip", "toolsplayerclip", "toolsnpcclip", "toolstrigger", "toolshint", "toolsskip", "toolsareaportal", "toolsoccluder", "toolsfog",
                "toolsorigin", "toolsblocklight", "toolsinvisibleladder", "toolsblock_los", "toolsblockbullets")
SEE_THROUGH = ("glass", "fence", "grate", "chainlink", "water", "window", "wire", "grill", "slime", "vent", "cage", "lattice", "mesh")
# (materials with such a word in their name that are solid all the same: read from Valve's own .vmt files, 28 November.
#  The rest of City 18's 23 are $translucent or $alphatest, which vbsp takes for glass: such a brush seals nothing)
OPAQUE_ANYWAY = ("glass/glasswindow005b", "glass/glasswindow011a", "building_template/building_trainstation_window002d")


def seals(mats):
    for m in mats:
        m = m.lower()
        if m.startswith("tools/"):
            if any(t in m for t in NOSEAL_TOOLS):
                return False
        elif any(w in m for w in SEE_THROUGH) and m not in OPAQUE_ANYWAY:
            return False
    return True


def world_brushes(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    w = text.index("\nworld")
    end = text.index("\nentity", w)
    out = []
    for m in re.finditer(r'\tsolid\r?\n\t*\{(.*?)\n\t\}', text[w:end], re.S):
        body = m.group(1)
        if "dispinfo" in body:
            continue
        mats = re.findall(r'"material" "([^"]+)"', body)
        if not seals(mats):
            continue
        pls = [np.array([float(x) for x in re.findall(r"-?\d+(?:\.\d+)?(?:e-?\d+)?", p)][:9]).reshape(3, 3) for p in re.findall(r'"plane" "([^"]+)"', body)]
        sid = re.search(r'"id" "(\d+)"', body)
        out.append((pls, sid.group(1) if sid else "?"))
    return out


def main():
    ap = argparse.ArgumentParser(description="Find the hole a map leaks through, in a box of it.")
    ap.add_argument("vmf")
    ap.add_argument("--from", dest="start", nargs=3, type=float, required=True, metavar=("X", "Y", "Z"), help="a point in the air inside the map")
    ap.add_argument("--box", nargs=6, type=float, required=True, metavar=("X1", "Y1", "Z1", "X2", "Y2", "Z2"))
    ap.add_argument("--cell", type=int, default=4)
    ap.add_argument("--void", default="bottom", choices=("bottom", "top", "west", "east", "south", "north"), help="the box's face that lies outside the map")
    a = ap.parse_args()
    C = a.cell
    lo = np.array(a.box[:3])
    hi = np.array(a.box[3:])
    n = np.ceil((hi - lo) / C).astype(int)
    solid = np.zeros(n, dtype=bool)
    used = 0
    for pls, _sid in world_brushes(a.vmf):
        P = np.array([p for pl in pls for p in pl])
        blo, bhi = P.min(axis=0), P.max(axis=0)
        if (bhi <= lo).any() or (blo >= hi).any():
            continue
        cen = P.mean(axis=0)
        i0 = np.maximum(np.floor((blo - lo) / C).astype(int), 0)
        i1 = np.minimum(np.ceil((bhi - lo) / C).astype(int), n)
        if (i1 <= i0).any():
            continue
        gx = lo[0] + (np.arange(i0[0], i1[0]) + 0.5) * C
        gy = lo[1] + (np.arange(i0[1], i1[1]) + 0.5) * C
        gz = lo[2] + (np.arange(i0[2], i1[2]) + 0.5) * C
        X, Y, Z = np.meshgrid(gx, gy, gz, indexing="ij")
        inside = np.ones(X.shape, dtype=bool)
        for pl in pls:
            nn = np.cross(pl[1] - pl[0], pl[2] - pl[0])
            L = np.linalg.norm(nn)
            if L == 0:
                continue
            nn = nn / L
            d = nn.dot(pl[0])
            if nn.dot(cen) - d > 0:
                nn, d = -nn, -d
            inside &= (nn[0] * X + nn[1] * Y + nn[2] * Z - d) <= (abs(nn[0]) + abs(nn[1]) + abs(nn[2])) * C / 2.0 - 0.01
        solid[i0[0]:i1[0], i0[1]:i1[1], i0[2]:i1[2]] |= inside
        used += 1
    print("grid %d x %d x %d (%.0f M cubes of %d), %d sealing world brushes in the box" % (n[0], n[1], n[2], solid.size / 1e6, C, used))
    s = tuple(np.floor((np.array(a.start) - lo) / C).astype(int))
    if solid[s]:
        sys.exit("--from is inside a brush")
    face = {"bottom": (slice(None), slice(None), 0), "top": (slice(None), slice(None), n[2] - 1), "west": (0, slice(None), slice(None)),
            "east": (n[0] - 1, slice(None), slice(None)), "south": (slice(None), 0, slice(None)), "north": (slice(None), n[1] - 1, slice(None))}[a.void]

    def joined(sol):
        lab, _k = ndimage.label(~sol)
        mine = lab[s]
        return mine != 0 and bool((lab[face] == mine).any()), lab, mine
    leak, lab, mine = joined(solid)
    if not leak:
        print("NO LEAK in this box: the air at %s is shut off from the box's %s face" % (" ".join("%g" % v for v in a.start), a.void))
        return
    print("LEAK: the air at %s is one piece with the void at the box's %s face" % (" ".join("%g" % v for v in a.start), a.void))
    thick = solid
    for k in range(1, 9):
        thick = ndimage.binary_dilation(thick)
        still, lab2, mine2 = joined(thick)
        if not still:
            # the hole: air of the real grid, shut by the thickening, that touches both the inside piece and the rest
            void_lab = set(np.unique(lab2[face])) - {0}
            inside_k = lab2 == mine2
            outside_k = np.isin(lab2, list(void_lab))
            plug = (~solid) & thick
            near_in = ndimage.binary_dilation(inside_k, iterations=k + 1)
            near_out = ndimage.binary_dilation(outside_k, iterations=k + 1)
            hole = plug & near_in & near_out
            hl, hn = ndimage.label(hole)
            print("the walls %d cube(s) thicker shut it: a hole about %d wide or less. %d place(s):" % (k, 2 * k * C, hn))
            for j, sl in enumerate(ndimage.find_objects(hl)[:12], start=1):
                a0 = lo + np.array([sl[0].start, sl[1].start, sl[2].start]) * C
                a1 = lo + np.array([sl[0].stop, sl[1].stop, sl[2].stop]) * C
                print("  HOLE %d: x %d..%d  y %d..%d  z %d..%d  (%d cubes)" % (j, a0[0], a1[0], a0[1], a1[1], a0[2], a1[2], int((hl == j).sum())))
            return
    print("not shut by walls 8 cubes thicker: the opening is wide (over %d). Narrow the box round where the map should be shut." % (16 * C))


if __name__ == "__main__":
    main()
