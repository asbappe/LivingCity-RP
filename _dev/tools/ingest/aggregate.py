"""Living City map ingestion: statistics across every ingested map.

    run(ref_dir) -> writes ref_dir/valve_stats.json and returns the headline lines

Reads every _dev/reference/valve_*/measure.json. Each distribution ({"n", "q", "hist"}) is added up over the maps
(its quantiles worked out again from the summed histogram, an approximation where a map dropped rare buckets),
each number is given across maps (min, median, max, how many maps), each [name, count] list is summed, and each
dict of shares gets the median share across maps. Paths are flattened ("sections.streets.road_width"), one a
line in the file, so grep finds one.
"""
import collections
import datetime
import glob
import json
import os

import numpy as np

SKIP = ("examples", "recipes", "missing_targets_top", "unsized_models", "file", "checks", "sun", "fog", "spotlights_top")
HEADLINES = [
    ("sections.streets.road_width", "Street roadway width"), ("sections.streets.kerb_height", "Kerb height"),
    ("sections.streets.pavement_width", "Pavement width"), ("sections.streets.wall_to_wall", "Street wall to wall"),
    ("sections.streets.wall_height", "Street wall height"), ("sections.nodes.indoor_ceiling", "Indoor floor to ceiling"),
    ("sections.nodes.corridor_width", "Corridor width"), ("sections.stairs.rise", "Stair rise"),
    ("sections.stairs.steps_per_flight", "Steps a flight"), ("sections.channels.open.w64", "Open channel width 64 up"),
    ("sections.channels.open.rim_lo", "Channel wall top"), ("craft.lights.spacing", "Light spacing (joined within 64)"),
    ("craft.wall_bands.first_change", "First material change up a wall"), ("craft.slopes.pitch", "Roof pitch"),
    ("census.ropes.spans", "Cable span"), ("props.density.per_cell", "Props per 256 square of play"),
]
SHARES = [("props.yaw.prop_static", "grid", "Static props on exact 90s"), ("props.yaw.prop_physics", "grid", "Physics props on exact 90s"),
          ("craft.lightmapscale.faces", "16", "Faces at lightmapscale 16"), ("craft.texture.scale", "0.25", "Faces at texture scale 0.25"),
          ("props.wall_gap.prop_static", "touch", "Static props touching a wall"), ("sections.nodes.outdoor_share", None, "AI nodes outdoors")]


def is_dist(v):
    return isinstance(v, dict) and "n" in v and set(v) <= {"n", "q", "hist", "rest"}


def is_top(v):
    return isinstance(v, list) and v and all(isinstance(x, list) and len(x) == 2 and isinstance(x[1], (int, float)) and not isinstance(x[1], bool) for x in v)


def is_shares(v):
    return isinstance(v, dict) and v and all(isinstance(x, float) and 0 <= x <= 1 for x in v.values())


def kind(v):
    return "dist" if is_dist(v) else "top" if is_top(v) else "shares" if is_shares(v) else "number" if isinstance(v, (int, float)) else "other"


def walk(d, path=""):
    for k, v in d.items():
        p = path + "." + k if path else k
        if k in SKIP:
            continue
        if is_dist(v) or is_top(v) or is_shares(v) or isinstance(v, (int, float)) and not isinstance(v, bool):
            yield p, v
        elif isinstance(v, dict):
            yield from walk(v, p)


def quantiles(hist, qs=(10, 25, 50, 75, 90)):
    items = sorted((float(k), n) for k, n in hist.items())
    if not items:
        return []
    vals = np.array([a for a, _ in items])
    cum = np.cumsum([n for _, n in items])
    tot = cum[-1]
    return [round(float(vals[np.searchsorted(cum, tot * q / 100.0)]), 1) for q in qs]


def run(ref):
    files = sorted(glob.glob(os.path.join(ref, "valve_*", "measure.json")))
    maps, acc = [], collections.defaultdict(list)
    for f in files:
        M = json.load(open(f))
        name = M.get("name") or os.path.basename(os.path.dirname(f))[6:]
        maps.append(name)
        for p, v in walk({k: M[k] for k in ("census", "sections", "props", "logic", "craft") if k in M}):
            acc[p].append((name, v))
    out = {}
    for p, items in sorted(acc.items()):
        shape = collections.Counter(kind(v) for _, v in items).most_common(1)[0][0]
        vs = [v for _, v in items if kind(v) == shape]
        if all(is_dist(v) for v in vs):
            h, n = collections.Counter(), 0
            for v in vs:
                n += v.get("n", 0)
                for k, c in (v.get("hist") or {}).items():
                    h[k] += c
            meds = [v["q"][2] for v in vs if v.get("q")]
            if not n:
                continue
            out[p] = {"kind": "distribution", "n": n, "maps": len(meds), "q": quantiles(h), "mode": max(h.items(), key=lambda kv: kv[1])[0] if h else None,
                      "hist": dict(sorted(h.items(), key=lambda kv: -kv[1])[:20]),
                      "map_medians": [round(float(np.min(meds)), 1), round(float(np.median(meds)), 1), round(float(np.max(meds)), 1)] if meds else None}
        elif all(is_top(v) for v in vs):
            c, seen = collections.Counter(), collections.Counter()
            for v in vs:
                for k, x in v:
                    c[str(k)] += x
                    seen[str(k)] += 1
            out[p] = {"kind": "counts", "maps": len(vs), "top": [[k, n, seen[k]] for k, n in c.most_common(25)]}
        elif all(is_shares(v) for v in vs):
            keys = collections.Counter(k for v in vs for k in v)
            out[p] = {"kind": "shares", "maps": len(vs), "median_share": {k: round(float(np.median([v.get(k, 0.0) for v in vs])), 3) for k, _ in keys.most_common(12)}}
        elif all(isinstance(v, (int, float)) for v in vs):
            a = np.array(vs, dtype=float)
            out[p] = {"kind": "number", "maps": len(vs), "min": round(float(a.min()), 3), "median": round(float(np.median(a)), 3), "max": round(float(a.max()), 3),
                      "sum": round(float(a.sum()), 3)}
    res = {"made": datetime.date.today().isoformat(), "maps": maps, "how": __doc__.strip().split("\n\n")[1].replace("\n", " "), "stats": out}
    text = "{\n" + ",\n".join('"%s": %s' % (k, json.dumps(v, ensure_ascii=False)) for k, v in res.items() if k != "stats")
    text += ',\n"stats": {\n' + ",\n".join("%s: %s" % (json.dumps(k), json.dumps(v, separators=(",", ":"), ensure_ascii=False)) for k, v in out.items()) + "\n}\n}\n"
    if chr(0x2014) in text:
        raise SystemExit("an em dash in the statistics: take it out")
    with open(os.path.join(ref, "valve_stats.json"), "w") as f:
        f.write(text)
    return headlines(out, maps)


def headlines(out, maps):
    lines = ["%d maps: %s" % (len(maps), ", ".join(maps))]
    for p, label in HEADLINES:
        d = out.get(p)
        if d and d.get("q"):
            lines.append("%s: median %s (p25 %s, p75 %s), commonest %s; %d measured in %d maps; map medians %s to %s." % (
                label, d["q"][2], d["q"][1], d["q"][3], d["mode"], d["n"], d["maps"], d["map_medians"][0], d["map_medians"][2]))
    for p, key, label in SHARES:
        d = out.get(p)
        if d and d["kind"] == "shares" and key in d["median_share"]:
            lines.append("%s: median %d%% across %d maps." % (label, round(100 * d["median_share"][key]), d["maps"]))
        elif d and d["kind"] == "number":
            lines.append("%s: median %d%% across %d maps (%d%% to %d%%)." % (label, round(100 * d["median"]), d["maps"], round(100 * d["min"]), round(100 * d["max"])))
    return lines
