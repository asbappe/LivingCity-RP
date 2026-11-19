#!/usr/bin/env python3
"""
Living City: the map builder (for the owner's PC, never the server)

The owner, 19 November: "It is SO labor intensive to do all the menial map building ... I wanted
to add more of an 'edge of city' or even outside of city area to the map for the resistance to
hide in the woods outside the city, or in the canals."

This writes a NEW, separate VMF for one piece of map (it never opens or changes the owner's own
VMF). The owner brings the piece in with a func_instance at 0 0 0, or with Paste Special at no
offset, looks at it in Hammer++, and compiles. Everything is in visgroups of its own, so it can
be hidden or deleted in one click.

    python3 map_build.py canal            writes lc_canal.vmf here
    python3 map_build.py canal --out FILE

A piece is drawn on a 64-unit grid seen from above: every square is open (a floor at some
height, under the sky or under a ceiling) or solid. From that it makes: a floor block under every
open square, a sky lid over it, and a solid block in every square that touches an open one, so
the piece is sealed by the way it is made. Squares that are alike are joined into big brushes.
Then it checks itself: every corner on the grid, and a flood from outside that must not reach
the air inside (the one opening, onto the city, is stopped up for the check). Only the owner's
compile is the proof.

The first piece, "canal" (the owner: at the skybox brush that ends the road at 3648 1864, "a
standard HL2 Route Kanal size ... not filled with water, that runs for a bit then turns and
maybe even forks and maybe dumps out to a forest"): a quay at the road's end, stairs down, a dry
canal 512 wide and 256 deep running east, a turn north, a fork (one arm ends at a barred tunnel
mouth, the other is capped where the forest will join), a low bay to hide in, two beams across.
"""

import argparse
import bisect
import random
import sys

CELL = 64

# what things are made of: all of these are already used in the owner's own VMF, so they exist
MAT = {
    "canal_wall": "concrete/concretewall064a",
    "canal_floor": "concrete/concretefloor026a",
    "quay_floor": "concrete/concretefloor013a",
    "upper_wall": "brick/brickwall045d",
    "ceiling": "concrete/concreteceiling004a",
    "stairs": "concrete/concretestair005a",
    "beam": "concrete/concretewall036a",
    "bars": "metal/metalpipe001a",
    "sky": "tools/toolsskybox",
    "nodraw": "tools/toolsnodraw",
    "black": "tools/toolsblack",
}


# ---------------------------------------------------------------------------
# Writing a VMF
# ---------------------------------------------------------------------------

class Vmf:
    def __init__(self, skyname="painted"):
        self.next = 1
        self.world, self.ents, self.groups = [], [], []
        self.visgroups = {} # name -> id
        self.skyname = skyname
        self.boxes = [] # (box, is_world) for the checks

    def new_id(self):
        self.next += 1
        return self.next

    def vis(self, name):
        if name not in self.visgroups:
            self.visgroups[name] = len(self.visgroups) + 1
        return self.visgroups[name]

    def editor(self, vis, colour="0 180 220", indent="\t"):
        return ('%seditor\n%s{\n%s\t"color" "%s"\n%s\t"visgroupid" "%d"\n%s\t"visgroupshown" "1"\n%s\t"visgroupautoshown" "1"\n%s}\n'
                % (indent, indent, indent, colour, indent, self.vis(vis), indent, indent, indent))

    def box_text(self, box, sides, top, bottom, vis, indent="\t"):
        """A box brush. sides, top, bottom: materials. Faces are written the way Hammer writes a box."""
        x1, y1, z1, x2, y2, z2 = box
        if not (x1 < x2 and y1 < y2 and z1 < z2):
            raise ValueError("a box with no size: %r" % (box,))
        faces = (
            (((x1, y2, z2), (x2, y2, z2), (x2, y1, z2)), top, "[1 0 0 0] 0.25", "[0 -1 0 0] 0.25"),
            (((x1, y1, z1), (x2, y1, z1), (x2, y2, z1)), bottom, "[1 0 0 0] 0.25", "[0 -1 0 0] 0.25"),
            (((x1, y2, z2), (x1, y1, z2), (x1, y1, z1)), sides, "[0 1 0 0] 0.25", "[0 0 -1 0] 0.25"),
            (((x2, y2, z1), (x2, y1, z1), (x2, y1, z2)), sides, "[0 1 0 0] 0.25", "[0 0 -1 0] 0.25"),
            (((x2, y2, z2), (x1, y2, z2), (x1, y2, z1)), sides, "[1 0 0 0] 0.25", "[0 0 -1 0] 0.25"),
            (((x2, y1, z1), (x1, y1, z1), (x1, y1, z2)), sides, "[1 0 0 0] 0.25", "[0 0 -1 0] 0.25"),
        )
        t = indent
        s = '%ssolid\n%s{\n%s\t"id" "%d"\n' % (t, t, t, self.new_id())
        for pts, mat, u, v in faces:
            s += ('%s\tside\n%s\t{\n%s\t\t"id" "%d"\n%s\t\t"plane" "%s"\n%s\t\t"material" "%s"\n%s\t\t"uaxis" "%s"\n%s\t\t"vaxis" "%s"\n'
                  '%s\t\t"rotation" "0"\n%s\t\t"lightmapscale" "16"\n%s\t\t"smoothing_groups" "0"\n%s\t}\n'
                  % (t, t, t, self.new_id(), t, " ".join("(%d %d %d)" % p for p in pts), t, mat.upper(), t, u, t, v, t, t, t, t))
        s += self.editor(vis, indent=t + "\t") + "%s}\n" % t
        return s

    def world_box(self, box, sides, top=None, bottom=None, vis="LC canal: walls and floors"):
        nd = MAT["nodraw"]
        self.world.append(self.box_text(box, sides, top or nd, bottom or nd, vis))
        self.boxes.append((box, True))

    def detail(self, boxes, mat, vis="LC canal: details", top=None):
        """Brushes that don't seal or cut up the map (func_detail): stairs, beams, bars, low walls."""
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "func_detail"\n' % self.new_id()
        for b in boxes:
            s += self.box_text(b, mat, top or mat, mat, vis)
            self.boxes.append((b, False))
        s += self.editor(vis, "0 180 0") + "}\n"
        self.ents.append(s)

    def point(self, cls, pos, keys=None, vis="LC canal: details"):
        s = 'entity\n{\n\t"id" "%d"\n\t"classname" "%s"\n' % (self.new_id(), cls)
        for k, v in (keys or {}).items():
            s += '\t"%s" "%s"\n' % (k, v)
        s += '\t"origin" "%d %d %d"\n' % tuple(pos)
        s += self.editor(vis, "220 30 220") + "}\n"
        self.ents.append(s)

    def text(self):
        s = 'versioninfo\n{\n\t"editorversion" "400"\n\t"editorbuild" "8873"\n\t"mapversion" "1"\n\t"formatversion" "100"\n\t"prefab" "0"\n}\n'
        s += "visgroups\n{\n"
        for name, i in self.visgroups.items():
            s += '\tvisgroup\n\t{\n\t\t"name" "%s"\n\t\t"visgroupid" "%d"\n\t\t"color" "%d %d %d"\n\t}\n' % (name, i, 80 + 40 * i, 200 - 20 * i, 255 - 30 * i)
        s += "}\n"
        s += 'viewsettings\n{\n\t"bSnapToGrid" "1"\n\t"bShowGrid" "1"\n\t"bShowLogicalGrid" "0"\n\t"nGridSpacing" "64"\n\t"bShow3DGrid" "0"\n}\n'
        s += ('world\n{\n\t"id" "1"\n\t"mapversion" "1"\n\t"classname" "worldspawn"\n\t"skyname" "%s"\n\t"maxpropscreenwidth" "-1"\n'
              '\t"detailvbsp" "detail.vbsp"\n\t"detailmaterial" "detail/detailsprites"\n' % self.skyname)
        s += "".join(self.world) + "}\n"
        s += "".join(self.ents)
        s += 'cameras\n{\n\t"activecamera" "-1"\n}\ncordons\n{\n\t"active" "0"\n}\n'
        return s


# ---------------------------------------------------------------------------
# A piece of map drawn on squares
# ---------------------------------------------------------------------------

class Plan:
    """Squares seen from above, in the piece's own coordinates (x east, y north, from its origin).
    A square is ("open", floor z, floor material) under the sky, ("low", floor z, floor material,
    ceiling z) under a ceiling, or nothing; the walls come by themselves."""

    def __init__(self, origin, base, rim, wall_top, sky):
        self.origin = origin
        self.base, self.rim, self.wall_top, self.sky = base, rim, wall_top, sky # z: under everything, canal wall's top, upper wall's top, the sky lid
        self.top = sky + 16
        self.cells = {}
        self.keep_out = [] # (x1, y1, x2, y2): what's already there in the owner's map, never built on

    def paint(self, rect, spec):
        x1, y1, x2, y2 = rect
        for v in rect:
            if v % CELL:
                raise ValueError("off the %d grid: %r" % (CELL, rect))
        for i in range(x1 // CELL, x2 // CELL):
            for j in range(y1 // CELL, y2 // CELL):
                self.cells[(i, j)] = spec

    def walls(self):
        """A solid square wherever an empty square touches an open one (corners too)."""
        solid = set()
        for (i, j) in self.cells:
            for di in (-1, 0, 1):
                for dj in (-1, 0, 1):
                    c = (i + di, j + dj)
                    if c not in self.cells:
                        x, y = c[0] * CELL, c[1] * CELL
                        if not any(x < k[2] and x + CELL > k[0] and y < k[3] and y + CELL > k[1] for k in self.keep_out):
                            solid.add(c)
        for c in solid:
            self.cells[c] = ("solid",)

    def rectangles(self):
        """Squares that are alike, joined into the biggest rectangles (fewest brushes)."""
        left = dict(self.cells)
        out = []
        for (i, j) in sorted(left):
            if (i, j) not in left:
                continue
            spec = left[(i, j)]
            w = 1
            while left.get((i + w, j)) == spec:
                w += 1
            h = 1
            while all(left.get((i + k, j + h)) == spec for k in range(w)):
                h += 1
            for a in range(w):
                for b in range(h):
                    del left[(i + a, j + b)]
            out.append((i * CELL, j * CELL, (i + w) * CELL, (j + h) * CELL, spec))
        return out

    def world(self, x, y, z):
        return (self.origin[0] + x, self.origin[1] + y, z)

    def box(self, x1, y1, z1, x2, y2, z2):
        ox, oy = self.origin[0], self.origin[1]
        return (ox + x1, oy + y1, z1, ox + x2, oy + y2, z2)

    def bands(self, z_from):
        """A wall from z_from up to the top, in its three looks: canal concrete, upper wall, sky."""
        out = []
        for lo, hi, mat in ((self.base, self.rim, MAT["canal_wall"]), (self.rim, self.wall_top, MAT["upper_wall"]), (self.wall_top, self.top, MAT["sky"])):
            a, b = max(lo, z_from), hi
            if a < b:
                out.append((a, b, mat))
        return out

    def build(self, vmf):
        self.walls()
        for x1, y1, x2, y2, spec in self.rectangles():
            if spec[0] == "solid":
                for a, b, mat in self.bands(self.base):
                    vmf.world_box(self.box(x1, y1, a, x2, y2, b), mat)
                continue
            floor, floor_mat = spec[1], spec[2]
            vmf.world_box(self.box(x1, y1, self.base, x2, y2, floor), MAT["canal_wall"], top=floor_mat)
            if spec[0] == "open":
                vmf.world_box(self.box(x1, y1, self.sky, x2, y2, self.top), MAT["sky"], MAT["sky"], MAT["sky"])
            else:
                first = True
                for a, b, mat in self.bands(spec[3]):
                    vmf.world_box(self.box(x1, y1, a, x2, y2, b), mat, bottom=MAT["ceiling"] if first else None)
                    first = False


# ---------------------------------------------------------------------------
# Checking a piece before the owner sees it
# ---------------------------------------------------------------------------

def check(vmf, seed, stoppers):
    """Corners on the grid, no brush inside another of the world's, and no way from the air inside
    (seed) to the outside once the piece's one opening is stopped up (stoppers: boxes)."""
    problems = []
    world = [b for b, is_world in vmf.boxes if is_world]
    for b, _ in vmf.boxes:
        if any(v != int(v) for v in b):
            problems.append("a corner off the 1-unit grid: %r" % (b,))
    solid = world + list(stoppers)
    axes = []
    for a in range(3):
        cuts = sorted(set([b[a] for b in solid] + [b[a + 3] for b in solid]))
        axes.append([cuts[0] - 64] + cuts + [cuts[-1] + 64])
    n = [len(ax) - 1 for ax in axes]
    full = set()
    for b in solid:
        r = [(bisect.bisect_left(axes[a], b[a]), bisect.bisect_left(axes[a], b[a + 3])) for a in range(3)]
        for i in range(*r[0]):
            for j in range(*r[1]):
                for k in range(*r[2]):
                    full.add((i, j, k))
    start = tuple(bisect.bisect_right(axes[a], seed[a]) - 1 for a in range(3))
    if start in full:
        return problems + ["the check's starting point is inside a brush"], 0
    seen, todo, leak = {start}, [start], None
    while todo:
        c = todo.pop()
        if c[0] in (0, n[0] - 1) or c[1] in (0, n[1] - 1) or c[2] in (0, n[2] - 1):
            leak = c
            break
        for a in range(3):
            for d in (-1, 1):
                m = list(c)
                m[a] += d
                m = tuple(m)
                if m not in seen and m not in full:
                    seen.add(m)
                    todo.append(m)
    if leak:
        problems.append("NOT SEALED: the air inside reaches the outside near (%d %d %d)" % tuple(axes[a][leak[a]] for a in range(3)))
    return problems, len(seen)


# ---------------------------------------------------------------------------
# The canal at the road's end
# ---------------------------------------------------------------------------

def canal(args):
    # the road ends at the owner's brush 15074 (x 3328..3968, y 1856..1872): its city side is this piece's south edge
    ox, oy = args.origin
    road_z, floor_z = 656, 400
    plan = Plan((ox, oy), base=floor_z - 64, rim=road_z, wall_top=road_z + 256, sky=road_z + 512)
    plan.keep_out.append((-100000, -100000, 100000, 0)) # the city: everything south of the road's end is the owner's
    canal_floor = ("open", floor_z, MAT["canal_floor"])
    plan.paint((0, 0, 640, 256), ("open", road_z, MAT["quay_floor"]))  # the quay: the road carries on to the canal's edge
    plan.paint((0, 256, 3072, 768), canal_floor)                       # A: east, away from the city
    plan.paint((2560, 768, 3072, 2816), canal_floor)                   # B: the turn north
    plan.paint((3072, 2304, 4608, 2816), canal_floor)                  # C: the fork's east arm (the forest will join its end)
    plan.paint((2560, 2816, 3072, 3584), canal_floor)                  # D: the fork's north arm
    plan.paint((2560, 3584, 3072, 3840), ("low", floor_z, MAT["canal_floor"], floor_z + 192)) # D's end: a tunnel mouth
    plan.paint((3072, 1280, 3328, 1664), ("low", floor_z, MAT["canal_floor"], floor_z + 192)) # a low bay off B: somewhere to hide

    vmf = Vmf()
    plan.build(vmf)
    B = plan.box

    # the sky the road sees above this piece's own (lower) sky: what the owner's brush 15074 did, from the lid up
    vmf.world_box(B(0, 0, plan.top, 640, 16, args.road_sky), MAT["sky"], MAT["sky"], MAT["sky"])

    # stairs from the quay down into the canal, along its south wall: a landing, then 31 steps east
    steps = [B(512, 256, floor_z, 640, 384, road_z)]
    for i in range(31):
        steps.append(B(640 + 12 * i, 256, floor_z, 652 + 12 * i, 384, road_z - 8 * (i + 1)))
    vmf.detail(steps, MAT["canal_wall"], top=MAT["stairs"])
    # a low wall along the quay's edge and round the landing (40 high: seen over, not fallen over)
    vmf.detail([B(0, 240, road_z, 512, 256, road_z + 40), B(512, 368, road_z, 640, 384, road_z + 40), B(512, 256, road_z, 528, 368, road_z + 40)], MAT["canal_wall"])
    # two beams across, at the canal wall's top: cover from above, and something to break the long view
    vmf.detail([B(1536, 256, road_z - 64, 1664, 768, road_z), B(2560, 1856, road_z - 64, 3072, 1984, road_z)], MAT["beam"])
    # the tunnel mouth at D's end: bars across it, and black at its back so it reads as going on
    bars = [B(2560 + 24 + 48 * i, 3600, floor_z, 2560 + 32 + 48 * i, 3608, floor_z + 192) for i in range(10)]
    vmf.detail(bars, MAT["bars"])
    vmf.detail([B(2560, 3832, floor_z, 3072, 3840, floor_z + 192)], MAT["black"])

    # where the city's people can walk: a path node every 192 units on every open floor, and on the stairs' ends
    blocked = [(512, 256, 1024, 384)] # (the landing and the stairs: their own nodes below)
    node_id = args.first_node
    for (i, j), spec in sorted(plan.cells.items()):
        if spec[0] == "solid" or i % 3 != 1 or j % 3 != 1:
            continue
        x, y = i * CELL + 32, j * CELL + 32
        if any(b[0] <= x < b[2] and b[1] <= y < b[3] for b in blocked):
            continue
        if spec[0] == "low" and y > 3584:
            continue # (behind the bars)
        vmf.point("info_node", plan.world(x, y, spec[1] + 16), {"nodeid": node_id}, "LC canal: path nodes")
        node_id += 1
    for x, y, z in ((576, 320, road_z), (736, 320, road_z - 64), (832, 320, road_z - 128), (928, 320, road_z - 208), (1056, 320, floor_z)):
        vmf.point("info_node", plan.world(x, y, z + 16), {"nodeid": node_id}, "LC canal: path nodes")
        node_id += 1

    # reflections: one cubemap for each stretch, at eye height
    for x, y, z in ((320, 128, road_z), (800, 512, floor_z), (2000, 512, floor_z), (2816, 1500, floor_z), (3200, 1472, floor_z), (2816, 2560, floor_z), (3900, 2560, floor_z), (2816, 3300, floor_z)):
        vmf.point("env_cubemap", plan.world(x, y, z + 72), {"cubemapsize": "0"})

    # a little left lying about (few, and in a visgroup of their own: delete it and they're gone)
    rnd = random.Random(18)
    junk = (
        ("models/props_c17/oildrum001.mdl", 1700, 700, 0), ("models/props_c17/oildrum001.mdl", 1750, 720, 0), ("models/props_junk/wood_pallet001a.mdl", 1620, 690, 8),
        ("models/props_junk/wood_crate001a.mdl", 3200, 1340, 20), ("models/props_junk/wood_crate002a.mdl", 3250, 1420, 20), ("models/props_junk/wood_pallet001a.mdl", 3180, 1600, 8),
        ("models/props_vehicles/tire001c_car.mdl", 2700, 2300, 12), ("models/props_canal/boat001a.mdl", 2000, 420, 24), ("models/props_canal/boat002b.mdl", 4200, 2700, 24),
    )
    for model, x, y, up in junk:
        vmf.point("prop_physics", plan.world(x, y, floor_z + up), {"model": model, "angles": "0 %d 0" % rnd.randrange(0, 360, 15), "skin": "0", "spawnflags": "0"}, "LC canal: props")

    # the checks: the opening onto the road is stopped up, then a flood from the air over the canal floor
    stopper = B(0, -64, road_z - 64, 640, 0, plan.top)
    problems, air = check(vmf, plan.world(1280, 512, floor_z + 32), [stopper])
    world_n = sum(1 for _, w in vmf.boxes if w)
    xs = [b[0] for b, _ in vmf.boxes] + [b[3] for b, _ in vmf.boxes]
    ys = [b[1] for b, _ in vmf.boxes] + [b[4] for b, _ in vmf.boxes]
    print("canal: %d world brushes, %d detail brushes, %d entities (%d path nodes, ids %d to %d)" % (
        world_n, len(vmf.boxes) - world_n, len(vmf.ents), node_id - args.first_node, args.first_node, node_id - 1))
    print("  it fills x %d to %d, y %d to %d, z %d to %d (the road's sky plug to %d)" % (min(xs), max(xs), min(ys), max(ys), plan.base, plan.top, args.road_sky))
    if problems:
        for p in problems:
            print("  PROBLEM: " + p)
    else:
        print("  checked: every corner on the grid; sealed (a flood from the air inside stays inside, with the road's opening stopped up)")
    return vmf, problems


PIECES = {"canal": canal}


def main():
    ap = argparse.ArgumentParser(description="Write a new piece of map as its own VMF (never touches the owner's VMF).")
    ap.add_argument("piece", choices=sorted(PIECES))
    ap.add_argument("--out", help="the VMF to write (default: lc_PIECE.vmf)")
    ap.add_argument("--origin", type=int, nargs=2, default=(3328, 1856), metavar=("X", "Y"), help="where the piece joins the map (default: the road's end, 3328 1856)")
    ap.add_argument("--road-sky", type=int, default=2784, help="the height of the sky over the road it joins (default 2784)")
    ap.add_argument("--first-node", type=int, default=4000, help="the first path node id to use (default 4000: the map's own stop at 3043)")
    args = ap.parse_args()
    vmf, problems = PIECES[args.piece](args)
    out = args.out or "lc_%s.vmf" % args.piece
    with open(out, "w") as f:
        f.write(vmf.text())
    print("  written: " + out)
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
