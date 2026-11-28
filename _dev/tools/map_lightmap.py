#!/usr/bin/env python3
"""Coarser shadows on big surfaces nobody stands near, to spend fewer vertices (the owner, 28 November: "we are still way
over vertices count"; the limit is 65,536 unique vertices for the whole map, MAX_MAP_VERTS).

Why it helps: the compiler cuts every drawn face wherever its lightmap would pass 31 luxels a side, and each cut adds
vertices. At the usual lightmap scale of 16 that is a cut every 496 units; at 32 every 992, at 64 every 1,984. So a big
face at 32 costs about a quarter of the cuts it costs at 16, and its shadows are a little softer. Nothing else changes.
Valve does the same (the lesson "Lightmaps fine near people, coarse far away": 16 on 86% of faces within 256 of where
people walk, 64 on 54% of faces over 3,000 away).

    python3 map_lightmap.py IN.vmf OUT.vmf            the pass
    python3 map_lightmap.py IN.vmf --dry              what it would do, writing nothing (add --list for every face)

Which faces: only faces of the world and of func_detail, drawn (no tool material, no sky), not displaced, whose
lightmap scale is still the default 16 (a scale the owner or Valve chose stays), and that the compiler cuts at 16 (over
496 a side: a smaller face would gain nothing). Of those:

  far         nothing people use within 1,024 of it: 32; within 3,072: 64 (--far, --very-far)
  ceiling     it faces down: 32
  high wall   a wall that starts 192 or more over the highest place people stand within 768 of it: 32
  rooftop     it faces up, 192 or more over the highest place people stand within 768 of it, nobody on it: 32
  under water it faces up under a water brush: 32

"Where people stand or go" is read from the map itself: AI nodes, player starts and spawns, ladders, doors, buttons,
triggers, items, weapons, loose props, NPCs, named marks (info_target). A map with none of these gets only the ceiling
and under water rules (far from nothing means nothing).

Only the "lightmapscale" lines of the faces it names change; every other byte of the file stays (line ends too).
Needs numpy."""
import argparse
import re
import sys

import numpy as np

import map_budget as mb

LUXELS = 31
STAND_POINT = ("info_node", "info_player", "info_ladder_dismount", "func_useableladder", "prop_door_rotating", "item_", "weapon_", "npc_", "info_target",
               "prop_physics", "info_teleport_destination", "info_hint")
STAND_BRUSH = ("func_door", "func_button", "func_rot_button", "trigger_", "func_movelinear", "func_tracktrain", "func_breakable", "func_ladder")
NOT_STAND = ("info_node_air", "info_node_air_hint")


def cuts(poly, uaxis, vaxis, scale):
    return mb.lightmap_cut_corners(poly, uaxis, vaxis, scale, LUXELS)


def read(path):
    """The file's lines (line ends kept), every candidate face, the places people stand, the water brushes' boxes."""
    lines = open(path, encoding="utf-8", errors="surrogateescape", newline="").read().split("\n")
    faces, stand, water = [], [], []
    stack, pending = [], None
    ent_cls, ent_origin, ent_pts = None, None, []
    sol, side = None, None
    for i, raw in enumerate(lines):
        line = raw.strip()
        if not line:
            continue
        if line == "{":
            name = pending or ""
            stack.append(name)
            if name in ("entity", "world") and len(stack) == 1:
                ent_cls, ent_origin, ent_pts = ("worldspawn" if name == "world" else ""), None, []
            elif name == "solid" and len(stack) == 2:
                sol = []
            elif name == "side" and sol is not None:
                side = {"mat": "", "plane": "", "u": "", "v": "", "scale": None, "line": None, "disp": False}
            elif name == "dispinfo" and side is not None:
                side["disp"] = True
            pending = None
            continue
        if line == "}":
            name = stack.pop() if stack else ""
            if name == "side" and side is not None and sol is not None:
                sol.append(side)
                side = None
            elif name == "solid" and sol is not None and len(stack) == 1:
                pls = [mb.plane3(s["plane"]) for s in sol]
                disp = any(s["disp"] for s in sol)
                polys = [mb.face_poly(pls, k) if pls[k] is not None else None for k in range(len(sol))]
                allp = [p for poly in polys if poly for p in poly]
                if allp:
                    ent_pts += allp
                    if any("water" in s["mat"] and mb.drawn(s["mat"]) for s in sol):
                        water.append(tuple(min(p[k] for p in allp) for k in range(3)) + tuple(max(p[k] for p in allp) for k in range(3)))
                if ent_cls in ("worldspawn", "func_detail") and not disp:
                    for k, s in enumerate(sol):
                        if polys[k] and len(polys[k]) >= 3 and s["line"] is not None and s["scale"] == 16.0 and mb.drawn(s["mat"]) and not mb.is_sky(s["mat"]):
                            n, _d = mb.plane_normal(s["plane"])
                            if n is None:
                                continue
                            c16 = cuts(polys[k], s["u"], s["v"], 16.0)
                            if c16 > 0:
                                # (plane_normal points INTO the brush for Hammer's winding or out of it: tell by the brush's middle)
                                mid = [sum(p[j] for p in allp) / len(allp) for j in range(3)]
                                fc = [sum(p[j] for p in polys[k]) / len(polys[k]) for j in range(3)]
                                if sum(n[j] * (fc[j] - mid[j]) for j in range(3)) < 0:
                                    n = (-n[0], -n[1], -n[2])
                                faces.append({"line": s["line"], "poly": polys[k], "n": n, "u": s["u"], "v": s["v"], "c16": c16, "mat": s["mat"]})
                sol = None
            elif name in ("entity", "world") and not stack:
                cls = ent_cls or ""
                if cls.startswith(STAND_POINT) and not cls.startswith(NOT_STAND) and ent_origin:
                    stand.append(ent_origin)
                elif cls.startswith(STAND_BRUSH) and ent_pts:
                    stand.append(tuple(sum(p[k] for p in ent_pts) / len(ent_pts) for k in range(3)))
                ent_cls = None
            continue
        if line[0] != '"':
            pending = line
            continue
        q = line.split('"')
        if len(q) < 4:
            continue
        key, val = q[1], q[3]
        top = stack[-1] if stack else ""
        if top == "side" and side is not None:
            if key == "material":
                side["mat"] = val.lower()
            elif key == "plane":
                side["plane"] = val
            elif key == "uaxis":
                side["u"] = val
            elif key == "vaxis":
                side["v"] = val
            elif key == "lightmapscale":
                side["line"] = i
                try:
                    side["scale"] = float(val)      # (a scale marked "@16" is the generator's own default: Vmf.text settles it)
                except ValueError:
                    side["scale"] = None
        elif top == "entity" and len(stack) == 1:
            if key == "classname":
                ent_cls = val
            elif key == "origin":
                try:
                    ent_origin = tuple(float(x) for x in val.split()[:3])
                except ValueError:
                    ent_origin = None
    return lines, faces, stand, water


def judge(faces, stand, water, far, very_far):
    """[(face, new scale, why)] for the faces to coarsen."""
    S = np.array(stand, dtype=np.float64) if stand else np.zeros((0, 3))
    out = []
    for f in faces:
        P = np.array(f["poly"], dtype=np.float64)
        lo, hi = P.min(axis=0), P.max(axis=0)
        n = f["n"]
        scale, why = None, None
        if len(S):
            d3 = np.maximum(np.maximum(lo - S, S - hi), 0.0)
            dist = np.sqrt((d3 ** 2).sum(axis=1))
            nearest = float(dist.min())
            hd = np.sqrt((d3[:, :2] ** 2).sum(axis=1))
            around = hd <= 768.0
            top_near = float(S[around, 2].max()) if around.any() else None
            if nearest > very_far:
                scale, why = 64, "far"
            elif nearest > far:
                scale, why = 32, "far"
            elif top_near is not None and abs(n[2]) < 0.3 and lo[2] >= top_near + 192.0:
                scale, why = 32, "high wall"
            elif top_near is not None and n[2] > 0.7 and lo[2] >= top_near + 192.0:
                on_it = (hd <= 64.0) & (S[:, 2] >= lo[2] - 32.0) & (S[:, 2] <= hi[2] + 128.0)
                if not on_it.any():
                    scale, why = 32, "rooftop"
        if scale is None and n[2] < -0.7:
            scale, why = 32, "ceiling"
        if scale is None and n[2] > 0.7:
            cx, cy = (lo[0] + hi[0]) / 2.0, (lo[1] + hi[1]) / 2.0
            if any(w[0] <= cx <= w[3] and w[1] <= cy <= w[4] and w[5] > hi[2] + 1.0 and w[2] <= hi[2] + 64.0 for w in water):
                scale, why = 32, "under water"
        if scale is not None:
            out.append((f, scale, why))
    return out


def main():
    ap = argparse.ArgumentParser(description="Coarser lightmaps on big faces nobody stands near: fewer vertices, softer shadows there.")
    ap.add_argument("vmf")
    ap.add_argument("out", nargs="?")
    ap.add_argument("--dry", action="store_true", help="write nothing: only say what it would do")
    ap.add_argument("--list", action="store_true", help="print every face it changes")
    ap.add_argument("--far", type=float, default=1024.0)
    ap.add_argument("--very-far", type=float, default=3072.0)
    a = ap.parse_args()
    if not a.out and not a.dry:
        sys.exit("give an OUT.vmf, or --dry")
    lines, faces, stand, water = read(a.vmf)
    picks = judge(faces, stand, water, a.far, a.very_far)
    by, saved = {}, 0.0
    for f, scale, why in picks:
        new = cuts(f["poly"], f["u"], f["v"], float(scale))
        g = by.setdefault(why, [0, 0])
        g[0] += 1
        g[1] += f["c16"] - new
        saved += mb.VERT_CUT_SHARE * (f["c16"] - new)
        if a.list:
            xs = [p[0] for p in f["poly"]]
            ys = [p[1] for p in f["poly"]]
            zs = [p[2] for p in f["poly"]]
            print("  %s -> %d: %s, x %d..%d y %d..%d z %d..%d" % (why, scale, f["mat"], min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
        raw = lines[f["line"]]
        lines[f["line"]] = re.sub(r'("lightmapscale"\s+")[^"]*(")', lambda m: m.group(1) + str(scale) + m.group(2), raw, count=1)
    print("%d faces the compiler cuts at lightmap scale 16 (of the world and func_detail); %d places people stand or go; %d water brushes" % (len(faces), len(stand), len(water)))
    if not stand:
        print("  no nodes, starts, doors or other marks of people in this map: only ceilings and floors under water are judged")
    for why in ("far", "ceiling", "high wall", "rooftop", "under water"):
        if why in by:
            print("  %-11s %5d faces, %6d cut corners fewer" % (why, by[why][0], by[why][1]))
    print("%d faces made coarser: about %d vertices fewer (the budget's own estimate: map_budget.py)" % (len(picks), int(saved)))
    if a.out and not a.dry:
        with open(a.out, "w", encoding="utf-8", errors="surrogateescape", newline="") as fh:
            fh.write("\n".join(lines))
        print("written: " + a.out)


if __name__ == "__main__":
    main()
