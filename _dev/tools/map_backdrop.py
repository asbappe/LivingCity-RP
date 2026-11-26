#!/usr/bin/env python3
"""
Living City: the scenery beyond the canal ring's outer wall (`backdrop` lines in a street chain's layout)

The owner, 23 November: the ring runs, from the city outward, city, Combine wall, road, railway, canal, then the
edge of the playable map. Players on the road look across the canal at that edge and can never reach it. "I think
the ruins and rooftops makes sense for most areas; however around the forest bunker and forest cave areas, it should
transition from the ruins and rooftops to the mountainous pine forest look from EP2, then blend back to ruins and
rooftops elsewhere."

So a band of squares runs along the canal's outer side, from the outer wall out to DEPTH (less where a side room, a
branch or another piece is), its ground at the rim (the wall's top and the ground beyond are one), closed by the
plan's own walls and a sky of its own high enough for what stands on it. The ruins are the old city the Combine
walled off, as Valve's Route Kanal maps show it over their canals' walls (d1_canals: brush buildings with Valve's
building_template fronts, tile and tar roofs, chimneys, aerials, collapsed blocks, a few dead trees; no interiors,
cheap to draw). Where a layout names a forest rectangle, Episode Two's pine forest stands instead (ep2_outland: pines
and rock on ground climbing away from the canal), the two blending over BLEND at its edges (the ruins thinning out,
the ground starting to climb, pines and rocks coming in).

Layout lines (map_modules.read_layout keeps them for this file):
    backdrop ruins                      the default kind (also turns the backdrop on)
    backdrop forest X1 Y1 X2 Y2         a rectangle where it is Episode Two's pine forest instead
    backdrop clear X1 Y1 X2 Y2          a rectangle kept free for another piece (the town, a forest, the owner's map)
    backdrop brushes                    the ruins' buildings as brushes, as they were before the Propper++ kit

The buildings are the Propper++ kit's models (map_propkit.py, _dev/propkit/; the owner, 23 November, chose models for
the heaviest brushwork: "we need it to not be nodrawn but to be deleted/non existent"), prop_statics with no collision
and only the faces seen from the street and the canal; Valve's own props (roof things, rubble, poles, trees, rocks)
stay as they are.

How it is seen decides what stands where: players stand on the street (eyes at STREET + 64) under the chain's sky
(b.sky), and look over the outer wall's top (the rim). A thing beyond the wall is seen only above the line from their
eyes over the wall's top, and only below the line from their eyes under the canal's sky lid (above it the sky would
cut it off): cone() gives that height at each distance from the canal, from the farthest place on the street (the
frontage). Nothing here is walkable: the band is wall to the canal's dressing and to the path nodes (views()), and
a player clip fills its air. Side rooms on the outer side keep their rooms; over their roofs the band's own sky is put in place of the chain's
sky block, so the scenery behind them is not hidden (their squares as the dressing sees them are left as they were).
"""

import math
import random

from map_build import CELL, MAT, prism
from map_forest import noise, smooth

DEPTH = 1536          # how far the scenery reaches beyond the canal's edge
BLEND = 1024          # how far ruins and forest blend into each other at a forest rectangle's edges
LID_UP = 2816         # the band's sky over the rim: what stands on it needs about 1800 (cone()); this high, its top lies more than
                      # 2048 over the chain's sky and over the band's floor, the farthest map_walk.py lets a player drop, so the
                      # walk check takes each stretch of it alone instead of walking the whole chain again from every one
THIN = 6              # a stretch of band less deep than this many squares is left out (the wall stays as it was)
RISE = 768            # how far the forest's ground climbs by the band's far edge
RISE_FROM = 384       # the forest's ground starts climbing this far from the canal or a side room (flat before it)
GRID = 256            # the forest ground's triangles: corners every GRID
FADE = (4096, 5120)   # where trees and the smaller things fade out (from the street they stand 1100 to 2700 off)

GROUND = "nature/dirtfloor005c"              # (in the owner's map)
FOREST_GROUND = "nature/blendgrassdirt01"    # ep2: the forests' own
# Fronts as Route Kanal does its far buildings (Valve's building_template faces), from the owner's own palette
# (_dev/reference/city18/palette.json: their building templates, bricks and plasters; map_lessons.py --find palette)
# with Route Kanal's commonest template; tar and tin flat roofs, tiled and corrugated pitched ones
FRONTS = ("building_template/building_trainstation_template002o", "building_template/building_template001i", "building_template/building_trainstation_template001c",
          "building_template/building_template003h", "building_template/building_template003d", "building_template/building_template007a",
          "brick/brickwall014l", "brick/brickwall045d", "brick/brickwall040b", "plaster/plasterwall041a", "plaster/plasterwall047b")
FLAT_ROOFS = ("props/rubberroof002a", "metal/metalroof008a")
TILE_ROOFS = ("tile/tileroof004a", "tile/tileroof004a", "metal/metalroof004a")
CHIMNEY = "brick/brickwall037a"
NODRAW = MAT["nodraw"]

M = "models/"
ROOF_THINGS = [(M + "props_rooftop/chimneypipe01a.mdl", 3), (M + "props_rooftop/chimneypipe01b.mdl", 2), (M + "props_rooftop/chimneypipe_cluster02a.mdl", 3),
               (M + "props_rooftop/antenna01a.mdl", 2), (M + "props_rooftop/antenna02a.mdl", 1), (M + "props_rooftop/antenna03a.mdl", 1),
               (M + "props_rooftop/antenna04a.mdl", 2), (M + "props_rooftop/antennaclusters01a.mdl", 1), (M + "props_rooftop/roof_dish001.mdl", 1),
               (M + "props_wasteland/chimneypipe01a.mdl", 1), (M + "props_wasteland/chimneypipe02b.mdl", 1)]
BIG_ROOF_THINGS = [(M + "props_buildings/watertower_001c.mdl", 2), (M + "props_rooftop/rooftopcluser07a.mdl", 2), (M + "props_rooftop/rooftopcluser06a.mdl", 1),
                   (M + "props_rooftop/scaffolding01a.mdl", 1)]
COLLAPSED = [(M + "props_buildings/collapsedbuilding02a.mdl", 3), (M + "props_buildings/collapsedbuilding01a.mdl", 2), (M + "props_buildings/collapsedbuilding02c.mdl", 2),
             (M + "props_buildings/collapsedbuilding02b.mdl", 1), (M + "props_debris/walldestroyed09a.mdl", 2)]
BROKEN_WALLS = [(M + "props_debris/walldestroyed02a.mdl", 2), (M + "props_debris/walldestroyed01a.mdl", 2), (M + "props_debris/walldestroyed03a.mdl", 2),
                (M + "props_debris/building_brokenexterior002a.mdl", 1), (M + "props_debris/building_brokenexterior002c.mdl", 1)]
RUBBLE = [(M + "props_debris/concrete_debris256pile001a.mdl", 3), (M + "props_debris/concrete_debris128pile001a.mdl", 2), (M + "props_debris/concrete_debris256barricade001a.mdl", 1)]
POLES = [(M + "props_c17/utilitypole01a.mdl", 1), (M + "props_c17/utilitypole01d.mdl", 1), (M + "props_c17/utilitypole03a.mdl", 1)]
# The far trees since 26 November (the owner: "about 5% the same number of buildings and remove the tree props and instead use the EP2
# skybox trees and maybe any HL2 trees ... we are wasting resources at something people won't look at"; and "valve seems to use
# tree_deciduous_card_01 as a static prop on the canal walls in HL2"): Valve's own far trees, each one model that is a whole clump of
# trees on flat cards (about 1000 deep, 2400 long, 700 to 1000 high), one every CARD_GAP along the band, its length along the wall.
CARDS = M + "props_foliage/tree_deciduous_card_01.mdl"            # hl2: on the ruins' ground
PINE_CARDS = (M + "props_foliage/tree_pine_card_cluster_01.mdl", M + "props_foliage/tree_pine_card_cluster_02.mdl")      # ep2: in the forest rectangles
CARD_GAP = (1200, 900)      # (between two clumps: on the ruins' ground, in the forest)
BUILDINGS = 1.0       # buildings to every 1000 of the band's squares outside the forest (about a twentieth of what stood there before)
ROCKS = [(M + "props_foliage/forestrock_cluster01.mdl", 2), (M + "props_foliage/forestrock_cluster02.mdl", 2), (M + "props_wasteland/rockcliff_cluster03a.mdl", 2),
         (M + "props_wasteland/rockcliff01f.mdl", 1), (M + "props_wasteland/rockcliff01j.mdl", 1), (M + "props_wasteland/rockcliff_cluster02a.mdl", 1)]


def pick(rnd, weighted):
    tot = sum(w for _, w in weighted)
    r = rnd.random() * tot
    for item, w in weighted:
        r -= w
        if r <= 0:
            return item
    return weighted[-1][0]


def parse(lines):
    """The layout's backdrop lines: {"forests": [rect], "clear": [rect], "brushes": bool}."""
    out = {"forests": [], "clear": [], "problems": [], "brushes": False}
    for words in lines:
        kind = words[0].lower() if words else "ruins"
        if kind == "ruins":
            continue
        if kind == "brushes" and len(words) == 1:
            out["brushes"] = True
            continue
        if kind in ("forest", "clear") and len(words) == 5:
            x1, y1, x2, y2 = (int(w) for w in words[1:])
            out["forests" if kind == "forest" else "clear"].append((min(x1, x2), min(y1, y2), max(x1, x2), max(y1, y2)))
        else:
            out["problems"].append("a backdrop line the builder does not know: backdrop %s" % " ".join(words))
    return out


def walk(lay):
    """Every step of the chain as build_chain lays it: (kind, name, frame, length), kind "leg" or "turn"; the frames
    are never flipped or lifted (the canal's own line). Gives them and where the chain comes out."""
    import map_corridor
    from map_modules import CANAL_W, HEADINGS, MODULES, Frame, jog_shift, widths
    x, y = lay["start"]
    rot = HEADINGS[lay["heading"]]
    steps = [["gate", "start"]] + lay["modules"] + ([] if lay.get("close") else [["gate", "end"]])
    width, out = CANAL_W, []
    for words in steps:
        name, opt = words[0], words[1:]
        if name in ("left", "right"):
            fr = Frame(x, y, rot, width)
            out.append(("turn", name, fr, width))
            x, y = fr.pt(width // 2, width // 2 if name == "left" else -width // 2)
            rot = (rot + (1 if name == "left" else -1)) % 4
            continue
        if name == "gate":
            fr = Frame(x, y, rot, 256)
            out.append(("leg", "gate " + opt[0], fr, 256))
            x, y = fr.pt(256, 0)
            continue
        if name not in MODULES:
            continue
        info = MODULES[name]
        length = info[0]
        if (name == "straight" or (len(info) > 3 and info[3].get("stretch"))) and opt and opt[0].isdigit():
            length = int(opt[0])
        if name == "shed" and not (opt and opt[0].isdigit()):
            length = (map_corridor.train_len(lay.get("cars", 2)) + 128 + 63) // 64 * 64
        width = widths(name)[1]
        fr = Frame(x, y, rot, length)
        out.append(("leg", name, fr, length))
        x, y = Frame(x, y, rot, length).pt(length, jog_shift(opt) if name == "jog" else 0)
    return out, (x, y, "ENWS"[rot])


def cells_of(rect):
    x1, y1, x2, y2 = rect
    for i in range(int(x1) // CELL, -(-int(x2) // CELL)):
        for j in range(int(y1) // CELL, -(-int(y2) // CELL)):
            yield (i, j)


def chamfer(sources, domain):
    """Distance (units, 64 a square straight on, 90 on the diagonal) from the middle of each square of `domain` to the
    middle of the nearest square of `sources`; 99999 where none is near."""
    big = 99999
    d = {c: (0 if c in sources else big) for c in domain}
    for c in sources:
        d.setdefault(c, 0)
    keys = sorted(d)
    fwd = ((-1, 0, 64), (0, -1, 64), (-1, -1, 90), (1, -1, 90))
    for _ in range(2):
        for (i, j) in keys:
            v = d[(i, j)]
            for di, dj, w in fwd:
                n = d.get((i + di, j + dj))
                if n is not None and n + w < v:
                    v = n + w
            d[(i, j)] = v
        for (i, j) in reversed(keys):
            v = d[(i, j)]
            for di, dj, w in fwd:
                n = d.get((i - di, j - dj))
                if n is not None and n + w < v:
                    v = n + w
            d[(i, j)] = v
    return d


def rect_dist(x, y, r):
    dx = max(r[0] - x, 0, x - r[2])
    dy = max(r[1] - y, 0, y - r[3])
    return math.hypot(dx, dy)


class Backdrop:
    """The band, what stands on it, and how the canal's dressing sees it (views)."""

    def __init__(self, b, lay):
        from map_modules import F, Frame, Mod
        self.b = b
        self.rim = b.rim
        self.lid = b.rim + LID_UP
        self.street = 1 if b.upper == "left" else -1
        opts = parse(lay.get("backdrop", []))
        b.problems.extend(opts["problems"])
        self.forests, self.clear = opts["forests"], opts["clear"]
        self.brushes = opts["brushes"]      # (the buildings as brushes, not the kit's models)
        self.legs, end = walk(lay)
        if lay.get("end") and tuple(lay["end"]) != end:      # (its walk of the layout must be build_chain's own)
            b.problems.append("the backdrop's walk of the layout comes out at (%d %d) heading %s, not where the chain does" % end)
        self.m = Mod(b, Frame(0, 0, 0, 64), "backdrop")
        self.m.pv, self.m.dv = b.vis + ": backdrop props", b.vis + ": backdrop buildings"
        self.rnd = random.Random(23111)
        self.F = F
        self.was = {}         # square -> its spec before the band's sky was put over it (side rooms' roofs and yards)
        self.band = {}        # square -> the way out from the canal (dx, dy) of the stretch it lies beside
        self.notes = []
        self.lay_band()
        if not self.band:
            return
        self.fields()
        self.paint()
        self.ground()
        self.ruins()
        self.forest()
        self.report()

    # --- where it lies -------------------------------------------------------------------------------------------
    def out_rects(self):
        """(rect in the map, the way out, the leg's frame) of every stretch's outer side, and the outside of every turn
        away from the street (its corner, which neither stretch beside it covers)."""
        s = self.street
        reach = 256 + CELL + DEPTH
        for kind, name, fr, L in self.legs:
            way = fr.way(270 if s > 0 else 90)
            if kind == "leg":
                yield fr.rect(0, -s * 256, L, -s * reach), way, fr, L
            elif (name == "left") == (s > 0):      # (the turn bends toward the street: its outside is the band's)
                h = L // 2
                yield fr.rect(0, -s * h, L + reach - 256, -s * (h + reach - 256)), way, fr, L
                yield fr.rect(L, -s * h, L + reach - 256, s * h), way, fr, L

    def lay_band(self):
        b = self.b
        painted = set(b.plan.cells)
        street = set(b.deck) | set(b.lifted) | set(b.sheds) | set(b.viaduct)
        clear = set()
        for r in self.clear:
            clear.update(cells_of(r))
        self.clear_cells = clear
        cand, deep = {}, set()
        for rect, way, fr, L in self.out_rects():
            for c in cells_of(rect):
                cand.setdefault(c, way)
        self.cand = cand
        # (each stretch's columns out from the canal: a column with less than THIN squares of band before a place kept
        #  for another piece is left out, as along the west run, where the cave forest's wall stands by the outer bank;
        #  a turn's corner is always kept)
        s = self.street
        for kind, name, fr, L in self.legs:
            if kind == "turn":
                if (name == "left") == (s > 0):
                    h = L // 2
                    for r in (fr.rect(0, -s * h, L + CELL + DEPTH, -s * (h + CELL + DEPTH)), fr.rect(L, -s * h, L + CELL + DEPTH, s * h)):
                        deep.update(cells_of(r))
                continue
            for u in range(0, L, CELL):
                run = []
                for k in range(1, (CELL + DEPTH) // CELL + 1):
                    x, y = fr.pt(u + CELL // 2, -s * (256 + k * CELL - CELL // 2))
                    c = (int(x) // CELL, int(y) // CELL)
                    if c in clear:
                        break
                    if c not in painted:
                        run.append(c)
                if len(run) >= THIN:
                    deep.update(run)
        keep = {}
        for c, way in cand.items():
            if c in painted or c in clear or c in street or c not in deep:
                continue
            keep[c] = way
        # side rooms and yards on the outer side: the band's sky over them (their squares as the dressing sees them stay)
        self.band = keep
        lid = self.lid
        for c, spec in list(b.plan.cells.items()):
            if c not in cand or c in street or c in clear:
                continue
            new = None
            if spec[0] == "low" and len(spec) == 4 and spec[3] <= self.rim - 16:
                new = ("cellar", spec[1], spec[2], spec[3], self.rim, GROUND, lid)
            elif spec[0] == "open" and len(spec) == 3 and spec[1] < self.rim and spec != ("open", self.F, MAT["canal_floor"]):
                new = ("open", spec[1], spec[2], lid)
            elif spec[0] == "cellar" and spec[4] <= self.rim and spec[6] <= b.sky:
                new = spec[:6] + (lid,)
            if new:
                self.was[c] = spec
                b.plan.cells[c] = new

    def fields(self):
        """Distances: from the chain's squares that keep the chain's sky (the canal, the street; what the cone is
        measured from), from any of the chain's squares (where the forest's ground may start to climb), and from the
        places kept for other pieces and the chain's two ends (where the ground must come down again)."""
        b = self.b
        domain = set(self.band)
        for c in list(self.band):
            for di in range(-6, 7):
                for dj in range(-6, 7):
                    domain.add((c[0] + di, c[1] + dj))
        lid_src = {c for c in domain if c in b.plan.cells and c not in self.was and c not in self.band}
        any_src = {c for c in domain if c in b.plan.cells and c not in self.band}
        self.d_lid = chamfer(lid_src, domain)
        self.d_any = chamfer(any_src, domain)
        hard = {c for c in domain if c in self.clear_cells}
        s = self.street
        for kind, name, fr, L in (self.legs[0], self.legs[-1]):
            u = (-CELL, 0) if name == "gate start" else (L, L + CELL)
            hard.update(cells_of(fr.rect(u[0], -s * 256, u[1], -s * (256 + CELL + DEPTH))))
        self.d_hard = chamfer(hard, domain) if hard else {}

    def d_at(self, field, x, y):
        """A field's distance at a point (from the square it lies in, less half a square: to its near edge)."""
        return max(0, field.get((int(math.floor(x / CELL)), int(math.floor(y / CELL))), 99999) - CELL // 2)

    def cone(self, x, y):
        """The highest a thing may reach here and still be seen whole from the street: under the line from the
        farthest place on the street (its frontage) under the canal's sky lid."""
        import map_corridor
        eye = map_corridor.STREET + 64
        lid = self.b.sky - 32
        far = (map_corridor.front_line(self.b) - 32) + 256
        d = max(0, self.d_at(self.d_lid, x, y) - CELL // 2)
        return min(self.lid - 32, lid + (lid - eye) * d / float(far))

    def seen(self, x, y):
        """The lowest a thing's top must reach here to be seen over the wall's top from the road's middle."""
        import map_corridor
        eye = map_corridor.STREET + 64
        d = self.d_at(self.d_lid, x, y)
        return self.rim + (self.rim - eye) * d / float(768 + 256)

    def forest_w(self, x, y):
        """How much forest it is here: 1 inside a forest rectangle, falling to 0 at BLEND outside it."""
        w = 0.0
        for r in self.forests:
            w = max(w, smooth(1.0 - rect_dist(x, y, r) / BLEND))
        return w

    def rise(self, x, y):
        """The forest's ground over the rim here (0 on the ruins' flat ground)."""
        w = self.forest_w(x, y)
        if w <= 0:
            return 0.0
        d = self.d_at(self.d_any, x, y)
        t = smooth((d - RISE_FROM) / float(DEPTH - RISE_FROM))
        if self.d_hard:
            t *= smooth((self.d_at(self.d_hard, x, y) - RISE_FROM) / 512.0)
        if t <= 0:
            return 0.0
        h = RISE * t + 110 * t * noise(x / 700.0, y / 700.0, 7) + 50 * t * noise(x / 230.0, y / 230.0, 8)
        return max(0.0, w * h)

    # --- the squares ---------------------------------------------------------------------------------------------
    def paint(self):
        b = self.b
        for c in self.band:      # (the city's dirt, as its own is laid; the forest's ground climbs over it, ground())
            b.plan.cells[c] = ("open", self.rim, GROUND, self.lid)
            b.owner[c] = "the backdrop"
        # (no path node out there: the band is wall to the canal's dressing, and so to its path nodes (views()); its
        #  squares are not added to b.blocked, which every node would be tested against, one rectangle at a time.) A
        # player clip fills its air, so nobody stands on it whatever gets them there (and map_walk.py walks none of it);
        # not over a module's own things standing above the rim
        busy = self.busy()
        under = set(c for c, spec in self.was.items() if spec[0] == "low" or (spec[0] == "open" and spec[1] <= self.rim - 128)
                    or (spec[0] == "cellar" and spec[4] <= self.rim - 128))      # (the side rooms' roofs and yards under the band's sky)
        for x1, y1, x2, y2 in rects((set(self.band) | under) - busy):
            b.vmf.world_box((x1, y1, self.rim, x2, y2, self.lid), MAT["clip"], top=MAT["clip"], bottom=MAT["clip"], vis=b.vis + ": backdrop player clip", seals=False)

    def views(self, canal, walled):
        """The canal's dressing and its fence see the band as the solid wall it stands on (the trim, ribs, outfalls,
        lamps and chain link along the outer wall as ever), and the side rooms under the band's sky as they were."""
        wall = ("solid", self.rim, False)
        for c in self.band:
            canal.cells[c] = wall
            walled.cells[c] = wall
        for c, spec in self.was.items():
            if c in canal.cells:
                canal.cells[c] = spec
            if c in walled.cells:
                walled.cells[c] = spec
        return canal, walled

    # --- the forest's ground -------------------------------------------------------------------------------------
    def ground(self):
        """Where the forest's ground climbs: triangles every GRID, each a sloped brush (its corners on the grid, so
        neighbours meet exactly), standing on the band's floor; a block of GRID is laid only where every square of it
        is band, and the ground is down at the rim wherever it meets anything but the band's far edge."""
        k = GRID // CELL
        blocks = {}
        for (i, j) in self.band:
            blocks.setdefault((i // k, j // k), 0)
            blocks[(i // k, j // k)] += 1
        self.blocks = {bk for bk, n in blocks.items() if n == k * k}
        self.hgt = {}

        def h(gx, gy):
            p = (gx, gy)
            if p not in self.hgt:
                self.hgt[p] = int(round(self.rise(gx * GRID, gy * GRID)))
            return self.hgt[p]
        shapes, n = [], 0
        for (bi, bj) in sorted(self.blocks):
            hs = [h(bi, bj), h(bi + 1, bj), h(bi + 1, bj + 1), h(bi, bj + 1)]
            if max(hs) <= 1:
                continue
            x0, y0, x1, y1 = bi * GRID, bj * GRID, (bi + 1) * GRID, (bj + 1) * GRID
            z = self.rim
            p = [(x0, y0, z + hs[0]), (x1, y0, z + hs[1]), (x1, y1, z + hs[2]), (x0, y1, z + hs[3])]
            for tri in ((p[0], p[1], p[2]), (p[0], p[2], p[3])):
                if max(q[2] for q in tri) <= z:
                    continue
                shapes.append(self.tri_prism(tri, z))
                n += 1
        if shapes:
            import re
            self.b.vmf.detail_shapes(shapes, self.b.vis + ": backdrop ground")
            # (a blend at half scale, as Valve lays theirs: map_lint.py's "scale"; the shapes are written at 0.25)
            self.b.vmf.ents[-1] = re.sub(r'("material" "%s"\n\s*"uaxis" "\[[^\]]*\]) 0\.25("\n\s*"vaxis" "\[[^\]]*\]) 0\.25"' % re.escape(FOREST_GROUND.upper()),
                                         r'\1 0.5\2 0.5"', self.b.vmf.ents[-1])
        self.notes.append("the forest's ground: %d sloped triangles, up to %d over the rim" % (n, max(self.hgt.values() or [0])))

    @staticmethod
    def tri_prism(tri, z):
        """A triangle of ground (its top through the three corners) standing on z: only its top is drawn."""
        top = [q for q in tri]
        bot = [(q[0], q[1], z - 8) for q in tri]
        faces = [(top, FOREST_GROUND), (list(reversed(bot)), NODRAW)]
        for a in range(3):
            q1, q2 = a, (a + 1) % 3
            faces.append(([top[q1], top[q2], bot[q2], bot[q1]], NODRAW))
        return faces

    def ground_z(self, x, y):
        """The ground's height at a point: the rim, or the forest's triangle there."""
        bi, bj = int(math.floor(x / GRID)), int(math.floor(y / GRID))
        if (bi, bj) not in self.blocks:
            return self.rim
        g = lambda gx, gy: self.hgt.get((gx, gy), 0)
        fx, fy = x / GRID - bi, y / GRID - bj
        h00, h10, h11, h01 = g(bi, bj), g(bi + 1, bj), g(bi + 1, bj + 1), g(bi, bj + 1)
        if fx >= fy:      # (the triangle p0 p1 p2)
            hh = h00 + (h10 - h00) * fx + (h11 - h10) * fy
        else:              # (p0 p2 p3)
            hh = h00 + (h11 - h01) * fx + (h01 - h00) * fy
        return self.rim + max(0.0, hh)

    def ground_low(self, box):
        """The lowest the ground is under a box (x1 y1 x2 y2): what a thing standing there must reach down to."""
        x1, y1, x2, y2 = box
        pts = [(x1, y1), (x2, y1), (x1, y2), (x2, y2), ((x1 + x2) / 2.0, (y1 + y2) / 2.0)]
        return min(self.ground_z(x, y) for x, y in pts)

    # --- what stands on it ---------------------------------------------------------------------------------------
    def free_squares(self):
        """Band squares things may stand on: not the first two beside the canal (hidden under the wall's top anyway,
        and the fence stands there), one square clear of anything not band, and clear of anything a module put up
        higher than the rim there."""
        busy = self.busy()
        free = set()
        for c in self.band:
            if c in busy or self.d_any.get(c, 0) < 2 * CELL:
                continue
            if all((c[0] + di, c[1] + dj) in self.band for di in (-1, 0, 1) for dj in (-1, 0, 1)):
                free.add(c)
        return free

    def busy(self):
        """Band squares (and side rooms' under its sky) near anything the modules or the street put up higher than the
        rim: kept as they are."""
        if getattr(self, "_busy", None) is None:
            b, busy = self.b, set()
            for box, _ in b.vmf.boxes:
                if box[5] > self.rim + 4 and box[2] < self.lid:
                    for c in cells_of((box[0] - CELL, box[1] - CELL, box[3] + CELL, box[4] + CELL)):
                        if c in self.band or c in self.was:
                            busy.add(c)
            for cls, model, at, yaw, tag in b.props:
                if at[2] > self.rim - 256:
                    for c in cells_of((at[0] - 2 * CELL, at[1] - 2 * CELL, at[0] + 2 * CELL, at[1] + 2 * CELL)):
                        if c in self.band or c in self.was:
                            busy.add(c)
            self._busy = busy
        return self._busy

    def put(self, model, x, y, yaw, z, pitch=0, roll=0, why=None, on=None):
        """A prop standing on z, if it is seen and not cut off by the sky (cone), its box stays on the band (on: the
        squares it may take, when fewer), and it takes no other prop's room (a tree's crown may spread over things;
        only its trunk is solid, as map_lint.py counts it). Never sunk under the band's floor (map_modules' check)."""
        from map_build import prop_box, stand_z
        z = max(z, self.rim - 4)
        zo = stand_z(model, int(math.floor(z)), pitch, roll)
        bx = prop_box(model, (int(round(x)), int(round(y)), zo), yaw)
        if bx is None:
            return False
        tree = "tree_" in model
        for c in cells_of((bx[0] + 4, bx[1] + 4, bx[3] - 4, bx[4] - 4)):
            if c not in self.band or (on is not None and not tree and c not in on):
                return False
        if tree and on is not None and (int(x) // CELL, int(y) // CELL) not in on:
            return False
        if bx[5] > min(self.cone(bx[0], bx[1]), self.cone(bx[3], bx[1]), self.cone(bx[0], bx[4]), self.cone(bx[3], bx[4])):
            return False
        mine = (x - 16, y - 16, bx[2], x + 16, y + 16, bx[5]) if tree else bx
        key = (int(x) // 512, int(y) // 512)
        near = [t for di in (-1, 0, 1) for dj in (-1, 0, 1) for t in self.taken.get((key[0] + di, key[1] + dj), ())]
        for other, other_tree, crown in near:
            if tree and other_tree:      # (crowns may meet, but neither stands over the other's trunk)
                if overlap3(bx, other) > 0 or overlap3(mine, crown) > 0:
                    return False
                continue
            a = mine if not other_tree else bx      # (under a tree's crown only its trunk counts)
            if overlap3(a, other) > 0:
                return False
        # (as the modules' m.static, but trees and the smaller things fade out far along the ring: they are many, and
        #  nobody walks out there to see them from near)
        keys = {"solid": "6", "disableshadows": "0", "screenspacefade": "0", "fadescale": "1", "fademindist": "-1", "fademaxdist": "0"}
        if tree or bx[5] - bx[2] < 320:
            keys.update({"fademindist": str(FADE[0]), "fademaxdist": str(FADE[1])})
        self.m.prop("prop_static", model, int(round(x)), int(round(y)), yaw, int(math.floor(z)), keys, pitch=pitch, roll=roll)
        self.taken.setdefault(key, []).append((mine, tree, bx))
        self.count[why or "props"] = self.count.get(why or "props", 0) + 1
        self.last = bx
        return True

    def ruins(self):
        """Buildings on lots along the band (oriented to the canal beside them), then broken walls, rubble, collapsed
        blocks, poles and a few dead trees on what is left. The buildings are the Propper++ kit's models (kit_lots),
        or brushes with "backdrop brushes" (brush_lots)."""
        self.count, self.taken = {}, {}
        free = self.free_squares()
        self.free = free
        if self.brushes:
            self.brush_lots(free)
        else:
            self.kit_lots(free)
        self.leftovers(free)

    def brush_lots(self, free):
        """Brush buildings (building()) on lots of 3 to 10 squares along by 3 to 7 out, as many as fit."""
        rnd = self.rnd
        order = sorted(free)
        rnd.shuffle(order)
        for c in order:
            if c not in free:
                continue
            x, y = c[0] * CELL + CELL // 2, c[1] * CELL + CELL // 2
            ruin = 1.0 - self.forest_w(x, y)
            if rnd.random() > 0.55 * ruin or self.rise(x, y) > 48:
                continue
            out = self.band[c]
            along = (-out[1], out[0])
            for _ in range(4):
                la, ld = rnd.choice((3, 4, 4, 5, 6, 6, 7, 8, 10)), rnd.choice((3, 4, 4, 5, 6, 7))
                fp = [(c[0] + a * along[0] + k * out[0], c[1] + a * along[1] + k * out[1]) for a in range(la) for k in range(ld)]
                if all(q in free for q in fp):
                    break
            else:
                continue
            self.take_lot(free, fp, rnd)
            xs, ys = [q[0] for q in fp], [q[1] for q in fp]
            rect = (min(xs) * CELL, min(ys) * CELL, (max(xs) + 1) * CELL, (max(ys) + 1) * CELL)
            self.building(rect, out, ruin)

    def take_lot(self, free, fp, rnd):
        """A lot's squares (and, more often than not, one square round it) are no longer free."""
        gap = 0 if rnd.random() < 0.45 else 1
        for q in fp:
            for di in range(-gap, gap + 1):
                for dj in range(-gap, gap + 1):
                    free.discard((q[0] + di, q[1] + dj))

    def kit_lots(self, free):
        """Buildings from the Propper++ kit (map_propkit.py: the owner, 23 November, chose models for the heaviest
        brushwork, which have no brushes and only the faces seen) on lots along the band: on each, the kind drawn as the
        brush buildings' were (blocks 3, houses 3, shells 4; and now and then a collapsed block), four pieces of that
        kind drawn (as the brush lots tried four sizes), and of those the one that fits on free squares there and whose
        roof comes nearest the height wanted (low in front, taller behind: as building()), never past the cone and always
        seen over the wall; its front to the canal. A kit building has no back (nobody on the street or in the canal can
        see it), so none stands where its back would be seen (back_seen: where the band bends round)."""
        import map_propkit as PK
        kit = PK.load()
        P = kit["pieces"]
        rnd = self.rnd
        order = sorted(free)
        rnd.shuffle(order)
        kinds = (("block", 3), ("house", 3), ("shell", 4), ("collapsed", 1))
        left = max(2, int(round(BUILDINGS * sum(1 for c in self.band if self.forest_w(c[0] * CELL + 32, c[1] * CELL + 32) < 0.5) / 1000.0)))
        for c in order:
            if left <= 0:      # (a handful along the whole band, where they fell in the shuffle: the owner, 26 November)
                break
            if c not in free:
                continue
            x, y = c[0] * CELL + CELL // 2, c[1] * CELL + CELL // 2
            ruin = 1.0 - self.forest_w(x, y)
            if rnd.random() > 0.55 * ruin or self.rise(x, y) > 48:
                continue
            out = self.band[c]
            along = (-out[1], out[0])
            want = self.rim + 192 + 0.42 * self.d_at(self.d_lid, x, y) + rnd.choice((-64, 0, 0, 64, 128, 192)) - 128 * (1 - ruin)
            kind = pick(rnd, kinds)
            names = kit["ruins"].get(kind, [])
            fits = []
            for name in rnd.sample(names, min(4, len(names))):      # (four of the kind drawn, as the brush lots tried four sizes)
                w, d = P[name]["size"][0] // CELL, P[name]["size"][1] // CELL
                fp = [(c[0] + a * along[0] + k * out[0], c[1] + a * along[1] + k * out[1]) for a in range(w) for k in range(d)]
                if not all(q in free for q in fp):
                    continue
                xs, ys = [q[0] for q in fp], [q[1] for q in fp]
                x1, y1, x2, y2 = min(xs) * CELL, min(ys) * CELL, (max(xs) + 1) * CELL, (max(ys) + 1) * CELL
                near = min(self.cone(x1, y1), self.cone(x2, y1), self.cone(x1, y2), self.cone(x2, y2))
                seen = max(self.seen(x1, y1), self.seen(x2, y1), self.seen(x1, y2), self.seen(x2, y2))
                if self.rim + P[name]["box"][5] > near - 16 or self.rim + P[name]["top"] < seen + 64:
                    continue
                fits.append((abs(self.rim + P[name]["top"] - want), name, fp, (x1, y1, x2, y2)))
            got = None
            for _, name, fp, rect in sorted(fits):      # (the one whose roof comes nearest the height wanted)
                if not self.back_seen((rect[0] + rect[2]) / 2.0, (rect[1] + rect[3]) / 2.0, P[name]["box"][4], out):
                    got = (name, fp, rect)
                    break
            if not got:
                continue
            name, fp, rect = got
            self.take_lot(free, fp, rnd)
            self.kit_building(name, rect, out)
            left -= 1

    def kit_building(self, name, rect, out):
        """A building of the kit on its lot, its front to the canal; on a block's roof chimney pipes and aerials (as on
        the brush blocks), in a shell now and then a heap of rubble fallen in."""
        import map_propkit as PK
        p = PK.load()["pieces"][name]
        x1, y1, x2, y2 = rect
        cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
        keys = {"solid": "0", "disableshadows": "0", "screenspacefade": "0", "fademindist": "-1", "fademaxdist": "0", "fadescale": "1"}
        self.m.prop("prop_static", PK.model(name), cx, cy, facing(out), self.rim, keys)
        what = {"block": "blocks", "house": "houses", "shell": "shells", "collapsed": "collapsed blocks"}.get(p["kind"], p["kind"])
        self.count[what] = self.count.get(what, 0) + 1
        top = self.rim + p["top"]
        if p["kind"] == "block":
            self.roof_things(rect, top)
        elif p["kind"] == "shell" and self.rnd.random() < 0.5:
            self.put(pick(self.rnd, RUBBLE), cx, cy, self.rnd.randint(0, 359), top, why="rubble")

    def back_seen(self, x, y, back, out):
        """Would the back of a kit piece standing at (x, y) with its front to the canal (its back `back` out from its
        middle, the way out) be seen? Only where the band bends round, as on the inside of a turn away from the street:
        a square of the street or of the canal's floor beyond the back's line, within 6000 of it and less than 75
        degrees off straight behind it, counts as seen (a glimpse along the band past the other ruins does not)."""
        import numpy as np
        if getattr(self, "_viewers", None) is None:
            b = self.b
            floor = ("open", self.F, MAT["canal_floor"])
            where = set(b.deck) | set(b.lifted) | set(b.viaduct) | {c for c, spec in b.plan.cells.items() if spec == floor}
            self._viewers = np.array([(i * CELL + CELL / 2.0, j * CELL + CELL / 2.0) for (i, j) in sorted(where) if (i, j) not in self.band]
                                     or [(1e9, 1e9)])
        px, py = x + out[0] * back, y + out[1] * back
        dx, dy = self._viewers[:, 0] - px, self._viewers[:, 1] - py
        s = dx * out[0] + dy * out[1]
        d2 = dx * dx + dy * dy
        return bool(np.any((s > 64) & (d2 < 6000.0 ** 2) & (s * s > 0.067 * d2)))

    def leftovers(self, free):
        """What is left: a broken wall standing alone, rubble, a collapsed block, a pole, a dead tree (with the kit, its
        collapsed blocks and broken walls among Valve's, their fronts to the canal)."""
        rnd = self.rnd
        collapsed, walls = COLLAPSED, BROKEN_WALLS
        if not self.brushes:
            import map_propkit as PK
            kit = PK.load()
            collapsed = COLLAPSED + [(PK.model(n), 2) for n in kit["ruins"].get("collapsed", [])]
            walls = BROKEN_WALLS + [(PK.model(n), 2) for n in kit["ruins"].get("broken wall", [])]
        left = sorted(free)
        rnd.shuffle(left)
        for c in left:
            if c not in free:
                continue
            x, y = c[0] * CELL + CELL // 2 + rnd.randint(-16, 16), c[1] * CELL + CELL // 2 + rnd.randint(-16, 16)
            ruin = 1.0 - self.forest_w(x, y)
            if ruin < 0.2 or self.rise(x, y) > 48:
                continue
            r = rnd.random()
            z = self.rim
            if r < 0.0004 * ruin:
                model = pick(rnd, collapsed)
                ok = self.put_ruin(model, x, y, rnd.choice((0, 90, 180, 270)) + rnd.randint(-12, 12), z, c, "collapsed blocks", free)
            elif r < 0.0014 * ruin:
                model = pick(rnd, walls)
                ok = self.put_ruin(model, x, y, rnd.choice((0, 90, 180, 270)), z, c, "broken walls", free)
            elif r < 0.0054 * ruin:
                ok = self.put(pick(rnd, RUBBLE), x, y, rnd.randint(0, 359), z, why="rubble", on=free)
            elif r < 0.0062:
                ok = self.put(pick(rnd, POLES), x, y, rnd.randint(0, 359), z, pitch=rnd.choice((0, 0, 4, 7, -6)), why="poles", on=free)
            else:      # (no dead trees since 26 November: tree_cards)
                continue
            if ok:      # (its room, and a little round it: the next thing stands apart)
                bx = self.last
                for q in cells_of((bx[0] - 2 * CELL, bx[1] - 2 * CELL, bx[3] + 2 * CELL, bx[4] + 2 * CELL)):
                    free.discard(q)

    def put_ruin(self, model, x, y, yaw, z, c, why, free):
        """A collapsed block or a broken wall: Valve's at the yaw drawn, or the kit's with its front to the canal (and not
        where its back would be seen)."""
        import map_propkit as PK
        if model.startswith(PK.MODELS):
            out = self.band[c]
            back = PK.load()["pieces"][model[len(PK.MODELS):-4]]["box"][4]
            if self.back_seen(x, y, back, out):
                return False
            yaw = facing(out)
        return self.put(model, x, y, yaw, z, why=why, on=free)

    def building(self, rect, out, ruin):
        """One building on its lot: a block with a flat roof and things on it, a house with a pitched roof and a
        chimney, or a shell broken down to its walls' jagged tops. Its front (the face to the canal) is the side
        `out` points away from."""
        rnd, m = self.rnd, self.m
        x1, y1, x2, y2 = rect
        cx, cy = (x1 + x2) / 2.0, (y1 + y2) / 2.0
        # its height by how far out it stands: low in front, taller behind, never past the cone, always seen
        near = min(self.cone(x1, y1), self.cone(x2, y1), self.cone(x1, y2), self.cone(x2, y2))
        seen = max(self.seen(x1, y1), self.seen(x2, y1), self.seen(x1, y2), self.seen(x2, y2))
        d = self.d_at(self.d_lid, cx, cy)
        want = self.rim + 192 + 0.42 * d + rnd.choice((-64, 0, 0, 64, 128, 192)) - 128 * (1 - ruin)
        z0 = self.rim
        kind = pick(rnd, [("block", 3), ("gable", 3), ("broken", 4)])
        roof_room = {"block": 260, "gable": 0, "broken": 200}[kind]
        top = int(min(want, near - roof_room - 8) // 64 * 64)
        if top < seen + 64:
            top = int((seen + 64 + 63) // 64 * 64)
        if top > near - 16 or top - z0 < 128:
            return
        front = rnd.choice(FRONTS)
        along_x = out[0] == 0          # (the canal runs along x beside it: its ridge too)
        width = (x2 - x1) if along_x else (y2 - y1)
        depth = (y2 - y1) if along_x else (x2 - x1)
        if kind == "gable":
            pitch = rnd.choice((0.5, 0.6, 0.75))
            rise = int(min(depth * pitch / 2, near - 16 - top) // 8 * 8)
            if rise < 48:
                kind = "block"
        if kind == "block":
            m.det([(x1, y1, z0, x2, y2, top)], front, top=rnd.choice(FLAT_ROOFS))
            self.count["blocks"] = self.count.get("blocks", 0) + 1
            # a parapet round the roof, broken here and there
            for (a1, b1, a2, b2) in self.parapet(rect, top):
                m.det([(a1, b1, top, a2, b2, top + 24)], front, faces={"bottom": NODRAW})
            self.roof_things(rect, top)
        elif kind == "gable":
            m.det([(x1, y1, z0, x2, y2, top)], front, top=NODRAW)
            roof = rnd.choice(TILE_ROOFS)
            if along_x:
                prof = [(y1 - 8, top), (y2 + 8, top), ((y1 + y2) // 2, top + rise)]
                m.shapes([prism(prof, "x", x1 - 8, x2 + 8, roof, front)])      # (its underside over the eaves is the tiles' back)
            else:
                prof = [(x1 - 8, top), (x2 + 8, top), ((x1 + x2) // 2, top + rise)]
                m.shapes([prism(prof, "y", y1 - 8, y2 + 8, roof, front)])
            self.count["houses"] = self.count.get("houses", 0) + 1
            # a brick chimney through the roof's slope, near one end
            if rnd.random() < 0.8 and width >= 192:
                a = rnd.choice((0.18, 0.3, 0.7, 0.82))
                if along_x:
                    px, py = int(x1 + (x2 - x1) * a) // 8 * 8, int(y1 + (y2 - y1) * rnd.choice((0.3, 0.7))) // 8 * 8
                else:
                    px, py = int(x1 + (x2 - x1) * rnd.choice((0.3, 0.7))) // 8 * 8, int(y1 + (y2 - y1) * a) // 8 * 8
                ch = min(top + rise + rnd.choice((32, 48, 64)), int(min(self.cone(px, py), near)) - 16) // 8 * 8
                if ch > top + rise // 2 + 24:
                    m.det([(px - 24, py - 16, top, px + 24, py + 16, ch)], CHIMNEY, faces={"bottom": NODRAW})
                    m.det([(px - 28, py - 20, ch, px + 28, py + 20, ch + 8)], "concrete/concretefloor016a")
                    self.count["chimneys"] = self.count.get("chimneys", 0) + 1
        else:
            self.shell(rect, top, front, along_x, out, near)
        return

    def parapet(self, rect, top):
        x1, y1, x2, y2 = rect
        rnd = self.rnd
        out = []
        for side in range(4):
            if rnd.random() < 0.2:
                continue
            if side == 0:
                seg = (x1, y1, x2, y1 + 16)
            elif side == 1:
                seg = (x1, y2 - 16, x2, y2)
            elif side == 2:
                seg = (x1, y1 + 16, x1 + 16, y2 - 16)
            else:
                seg = (x2 - 16, y1 + 16, x2, y2 - 16)
            out.append(seg)
        return out

    def roof_things(self, rect, top):
        """Chimney pipes, aerials and dishes on a flat roof (each by its real size, inside the parapet), now and then a
        water tower or a roof shed on a big one."""
        rnd = self.rnd
        x1, y1, x2, y2 = rect
        if (x2 - x1) >= 384 and (y2 - y1) >= 384 and rnd.random() < 0.35:
            model = pick(rnd, BIG_ROOF_THINGS)
            self.on_roof(model, rect, top, "on roofs")
        for _ in range(rnd.choice((1, 2, 2, 3, 3, 4))):
            self.on_roof(pick(rnd, ROOF_THINGS), rect, top, "on roofs")

    def on_roof(self, model, rect, top, why):
        from map_build import prop_box
        import map_assets
        bb = map_assets.size(model)
        if not bb:
            return False
        rnd = self.rnd
        x1, y1, x2, y2 = rect
        for _ in range(6):
            yaw = rnd.choice((0, 90, 180, 270))
            x = rnd.uniform(x1 + 40, x2 - 40)
            y = rnd.uniform(y1 + 40, y2 - 40)
            bx = prop_box(model, (x, y, 0), yaw)
            if bx[0] < x1 + 24 or bx[3] > x2 - 24 or bx[1] < y1 + 24 or bx[4] > y2 - 24:
                continue
            taken = getattr(self, "roof_taken", [])
            if any(bx[0] < t[2] and bx[3] > t[0] and bx[1] < t[3] and bx[4] > t[1] for t in taken):
                continue
            if self.put(model, x, y, yaw, top, why=why):
                taken.append((bx[0] - 8, bx[1] - 8, bx[3] + 8, bx[4] + 8))
                self.roof_taken = taken
                return True
        return False

    def shell(self, rect, top, front, along_x, out, near):
        """A building burnt out to its walls: a block to `top` (its floors fallen in behind), and on its front and one
        side its walls standing on, broken off at slanting heights (each piece a prism)."""
        rnd, m = self.rnd, self.m
        x1, y1, x2, y2 = rect
        z0 = self.rim
        m.det([(x1, y1, z0, x2, y2, top)], front, top="concrete/concretefloor013a")
        self.count["shells"] = self.count.get("shells", 0) + 1
        t = 24
        shapes = []
        room = int(near - 16 - top)
        if room < 48:
            return
        # the front faces the canal: the side opposite `out`
        walls = []
        # (the side wall starts behind the front wall: no two faces lie flush where they meet at the corner)
        if along_x:
            yf = y1 if out[1] > 0 else y2 - t
            walls.append(("x", x1, x2, yf, yf + t))
            xs = rnd.choice((x1, x2 - t))
            walls.append(("y", y1 + t if out[1] > 0 else y1, y2 if out[1] > 0 else y2 - t, xs, xs + t))
        else:
            xf = x1 if out[0] > 0 else x2 - t
            walls.append(("y", y1, y2, xf, xf + t))
            ys = rnd.choice((y1, y2 - t))
            walls.append(("x", x1 + t if out[0] > 0 else x1, x2 if out[0] > 0 else x2 - t, ys, ys + t))
        for axis, a, b2, c1, c2 in walls:
            # pieces along the wall: each from p to q, its top slanting from h1 to h2 (some low, some to the full height)
            p = a
            while p < b2 - 32:
                q = min(b2, p + rnd.choice((64, 96, 128, 160, 192)))
                if b2 - q < 48:
                    q = b2
                h1 = rnd.choice((0, 32, 64, 96, 128, 192, 256))
                h2 = rnd.choice((0, 32, 64, 96, 128, 192, 256))
                h1, h2 = min(h1, room), min(h2, room)
                if max(h1, h2) >= 24:
                    prof = [(p, top), (q, top), (q, top + max(h2, 8)), (p, top + max(h1, 8))]
                    # (the profile runs along the wall and up; pushed through the wall's thickness)
                    shapes.append(bottom_nodraw(prism(prof, "y" if axis == "x" else "x", c1, c2, front), top))
                p = q
        if shapes:
            m.shapes(shapes)
        # a rubble heap fallen inside, and a broken wall piece leaning against it now and then
        if rnd.random() < 0.5:
            cx, cy = (x1 + x2) / 2.0, (y1 + y2) / 2.0
            self.put(pick(rnd, RUBBLE), cx, cy, rnd.randint(0, 359), top, why="rubble")

    def forest(self):
        """A few rocks on the forest's climbing ground, and the far trees along the whole band (tree_cards). The pines
        that stood here one by one (270 of them, and 15 dead trees among the ruins) are gone: the owner, 26 November."""
        rnd = random.Random(23112)
        spots = [(c, self.forest_w(c[0] * CELL + CELL // 2, c[1] * CELL + CELL // 2)) for c in sorted(self.free)]
        spots = [(c, w) for c, w in spots if w > 0.05]
        rnd.shuffle(spots)
        placed = []
        for c, w in spots:
            if rnd.random() >= 0.02 * w:
                continue
            x, y = c[0] * CELL + rnd.randint(4, CELL - 4), c[1] * CELL + rnd.randint(4, CELL - 4)
            if any((x - px) ** 2 + (y - py) ** 2 < 220 ** 2 for px, py in placed):
                continue
            z = self.ground_low((x - 24, y - 24, x + 24, y + 24))
            if self.put(pick(rnd, ROCKS), x, y, rnd.randint(0, 359), z - (4 if z <= self.rim + 1 else 40), why="rocks", on=self.free):
                placed.append((x, y))
        self.tree_cards(rnd)

    def tree_cards(self, rnd):
        """Valve's far trees along the band: one clump model every CARD_GAP or so, its length along the wall and its depth
        on the band's middle (the one way it fits: the band is 1536 deep, a clump about 1000 by 2400), standing on the
        ground under it; Half-Life 2's leafy clump over the ruins, Episode Two's pine clumps in the forest rectangles.
        Whole and never faded (they are the skyline, and one model each); not solid (nobody walks there)."""
        from map_build import prop_box
        spots = sorted(c for c in self.band if 7 * CELL <= self.d_any.get(c, 0) <= 17 * CELL)
        rnd.shuffle(spots)
        placed = []
        for c in spots:
            x, y = c[0] * CELL + CELL // 2, c[1] * CELL + CELL // 2
            pine = self.forest_w(x, y) > 0.5
            gap = CARD_GAP[1 if pine else 0]
            if any((x - px) ** 2 + (y - py) ** 2 < gap ** 2 for px, py in placed):
                continue
            out = self.band[c]
            model = rnd.choice(PINE_CARDS) if pine else CARDS
            for yaw in rnd.sample((0, 180), 2):       # (the model's own x across the band, either way round)
                yaw = (yaw + int(round(math.degrees(math.atan2(out[1], out[0]))))) % 360
                bx = prop_box(model, (x, y, self.rim), yaw)
                if bx is None or any(q not in self.band for q in cells_of((bx[0] + 48, bx[1] + 48, bx[3] - 48, bx[4] - 48))):
                    continue
                z = int(math.floor(self.ground_low((bx[0] + 200, bx[1] + 200, bx[3] - 200, bx[4] - 200)))) - 6
                if z + (bx[5] - bx[2]) > self.lid - 32:
                    continue
                self.m.prop("prop_static", model, x, y, yaw, z, {"solid": "0", "disableshadows": "1", "screenspacefade": "0", "fadescale": "1",
                                                                  "fademindist": "-1", "fademaxdist": "0"})
                placed.append((x, y))
                why = "pine clumps" if pine else "tree clumps"
                self.count[why] = self.count.get(why, 0) + 1
                break

    def report(self):
        b = self.b
        n_forest = sum(1 for c in self.band if self.forest_w(c[0] * CELL + 32, c[1] * CELL + 32) > 0.5)
        b.notes.append("the backdrop: %d squares beyond the outer wall (%d of them forest), its sky at z %d; %d side rooms' squares under its sky; %s" % (
            len(self.band), n_forest, self.lid, len(self.was), ", ".join("%d %s" % (v, k) for k, v in sorted(self.count.items()))))
        for n in self.notes:
            b.notes.append("  " + n)


def facing(out):
    """The yaw that turns a kit piece (its front to -y) to look back against out (the way out from the canal)."""
    return int(round(math.degrees(math.atan2(-out[0], out[1])))) % 360


def overlap3(a, b):
    """How much two boxes (x1 y1 z1 x2 y2 z2) share."""
    d = [min(a[k + 3], b[k + 3]) - max(a[k], b[k]) for k in range(3)]
    return d[0] * d[1] * d[2] if min(d) > 0 else 0


def bottom_nodraw(faces, z):
    """A shape standing on something at z: its face lying on z is never seen."""
    return [(v, NODRAW if all(q[2] == z for q in v) else mat) for v, mat in faces]


def rects(cells):
    """Squares joined into rectangles (map units)."""
    left = set(cells)
    out = []
    for (i, j) in sorted(left):
        if (i, j) not in left:
            continue
        w = 1
        while (i + w, j) in left:
            w += 1
        h = 1
        while all((i + k, j + h) in left for k in range(w)):
            h += 1
        for a in range(w):
            for c in range(h):
                left.discard((i + a, j + c))
        out.append((i * CELL, j * CELL, (i + w) * CELL, (j + h) * CELL))
    return out


def build(b, lay):
    """The backdrop of a street chain whose layout has backdrop lines (map_modules.build_chain, after the street)."""
    if not b.upper:
        b.problems.append("a backdrop needs the street's side to know the outer side: add \"upper left\" or \"upper right\"")
        return
    bd = Backdrop(b, lay)
    if bd.band:
        b.backdrop = bd
