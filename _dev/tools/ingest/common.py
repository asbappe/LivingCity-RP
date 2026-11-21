"""Living City map ingestion: small helpers every part shares (distributions, model kinds, angles, model sizes).

A distribution is stored as {"n": count, "q": [p10, p25, p50, p75, p90], "hist": {bucket: count}} so that the
aggregate can add the histograms of every map together; only the commonest buckets are kept ("rest" counts the
others). A "top" list is [[name, count], ...].
"""
import collections
import math
import os
import re
import sys

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

C = collections.Counter


def rnd(x, nd=1):
    if x is None:
        return None
    r = round(float(x), 0 if abs(float(x)) >= 100 else nd)
    return int(r) if r == int(r) else r


def dist(values, step=1.0, keep=24):
    v = np.asarray([x for x in values if x is not None and not (isinstance(x, float) and math.isnan(x))], dtype=float)
    if not len(v):
        return {"n": 0}
    b = np.round(v / step) * step
    h = C(rnd(x) for x in b)
    out = {"n": int(len(v)), "q": [rnd(np.percentile(v, p)) for p in (10, 25, 50, 75, 90)]}
    common = sorted(h.items(), key=lambda kv: -kv[1])[:keep]
    out["hist"] = {str(k): n for k, n in sorted(common, key=lambda kv: kv[0])}
    rest = len(v) - sum(n for _, n in common)
    if rest:
        out["rest"] = rest
    return out


def top(counter, n=20, short=False):
    return [[(k.split("/")[-1] if short and isinstance(k, str) else k), int(c)] for k, c in C(counter).most_common(n)]


def shares(counter, nd=3, n=None):
    tot = float(sum(counter.values()))
    items = C(counter).most_common(n)
    return {str(k): round(c / tot, nd) for k, c in items} if tot else {}


def med(v):
    v = [x for x in v if x is not None]
    return rnd(np.median(v)) if v else None


def short(model):
    return model.lower().replace("\\", "/").split("/")[-1].replace(".mdl", "")


# ---- what a model is, from its name (the props helper's rules, first match wins)
KIND_RULES = [
    ("corpse", r"humans/|charple|corpse|gibs/|^police|zombie|skeleton"),
    ("skybox", r"skybox|props_skybox/|_card_|props_buildings/|-lod"),
    ("tire", r"tire"),
    ("vehicle", r"vehicles?/|car00|truck|van0|tanker|train0|traincar|boat|airboat|apc|bus0|tractor|forklift|carparts_(?!tire)"),
    ("door", r"(?<!in)(?<!out)door"),
    ("mattress", r"mattress|furniturebed|bedframe|(?<!river)bed0|cot0"),
    ("couch", r"couch|sofa|armchair"), ("bench", r"bench"), ("chair", r"chair|stool|seat"), ("table", r"table|desk"),
    ("shelf", r"shelf|cupboard|cabinet|filecabinet|locker|dresser|drawer|bookcase|kitchen_counter|counter"),
    ("stove", r"stove|oven"), ("fridge", r"fridge|refrigerator"), ("washer", r"washingmachine|washer|dryer"),
    ("sink", r"sink|toilet|bathtub|urinal|shower"), ("radiator", r"radiator|boiler|furnace|heater"),
    ("tv", r"tv_|television|monitor(?!_)|computer|terminal"), ("radio", r"radio"), ("phone", r"phone"),
    ("lamppost", r"lamppost|streetlight"), ("light", r"light|lamp|lantern|bulb|chandelier|sconce"),
    ("bin", r"trashcan|trashbin|dumpster|wastebasket|garbagecan|bin0"), ("trash", r"garbage|trash|takeout|milkcarton|carboard"),
    ("paper", r"paper|newspaper|book|binder|clipboard|notepad|folder|file0"), ("bottle", r"bottle|jug|glass0|cup0|mug"),
    ("can", r"popcan|metalcan|tin_can|can0|soda"), ("food", r"food|watermelon|orange|banana|bread|meat|melon|cabbage|carrot|lettuce|potato"),
    ("pot", r"kettle|/pot0|metalpot|/pan0|frying|cookingpot|teapot|/plate"), ("crate", r"crate"),
    ("elecbox", r"powerbox|switchbox|stripebox|fusebox|breaker"), ("box", r"cardboard|box0|boxes"),
    ("barrel", r"oildrum|barrel|drum"), ("pallet", r"pallet"), ("propane", r"propane|gascan|canister0|gas_tank"),
    ("bucket", r"bucket|paintcan"), ("cinder", r"cinderblock|brick"), ("board", r"wood_board|plank|wood_beam|woodpanel"),
    ("cart", r"pushcart|cart0|wheelbarrow|shoppingcart"),
    ("personal", r"suitcase|shoe|doll|baby|teddy|hat0|briefcase|bag0|backpack|clothes|glasses|camera|clock|picture|/frame0|vase|flowerpot|harpoon|binocular"),
    ("tool", r"tools_|toolbox|wrench|hammer|shovel|sawblade|axe|crowbar|pickaxe|shears|sledge|workbench|vise|lathe"),
    ("sawhorse", r"sawhorse|trafficcone|cone0|barrier|sandbag|barricade(?!_tall|_short)"), ("barricade", r"barricade"),
    ("fence", r"fence|railing|handrail|_bars|bars0|grate|gate"), ("ladder", r"ladder"), ("pipe", r"pipe|gutter|vent|duct|valve"),
    ("pole", r"utilitypole|powertower|antenna|pole|wire|connecter|connector"), ("sign", r"sign|poster|billboard|banner|flag"),
    ("plant", r"foliage|tree|shrub|ivy|bush|plant|cattail|bramble|grass|fern|flower|leaves|hedge|driftwood"),
    ("container", r"container"),
    ("debris", r"debris|rebar|concrete_|walldestroyed|rubble|rock|ibeam|beam|metal_panel|wreck|brokenexterior|destroyed"),
    ("combine", r"props_combine/"), ("dock", r"props_docks/|dock|mooring|channelmarker|bollard|cleat"),
    ("machine", r"machine|generator|engine|motor|pump|turbine|powerbox|substation|transformer|circuit|switchbox|meter|panel|console|interface|lab/"),
]
_KRE = [(k, re.compile(r)) for k, r in KIND_RULES]
_kind_cache = {}
DRESS = {"elecbox", "mattress", "couch", "bench", "chair", "table", "shelf", "stove", "fridge", "washer", "sink", "radiator", "tv",
         "radio", "phone", "lamppost", "light", "bin", "trash", "paper", "bottle", "can", "food", "pot", "crate", "box", "barrel",
         "pallet", "propane", "bucket", "cinder", "board", "cart", "personal", "tool", "sawhorse", "tire", "corpse", "barricade", "machine"}
POLES = ("lamppost", "utilitypole", "signpole", "streetlight", "light_post", "powertower", "telephonepole", "trafficlight", "pole0")
TREES = ("tree", "bush", "shrub", "foliage", "hedge")


def kind(model, cls=""):
    if cls == "prop_ragdoll":
        return "corpse"
    m = model.lower().replace("\\", "/").replace("models/", "")
    if m not in _kind_cache:
        _kind_cache[m] = next((k for k, rx in _KRE if rx.search(m)), "other")
    return _kind_cache[m]


# ---- angles and boxes (Source: pitch, yaw, roll; a model's box is x forward, y left, z up)
def axes(ang):
    p, y, r = [math.radians(a) for a in (list(ang) + [0, 0, 0])[:3]]
    cp, sp, cy, sy, cr, sr = math.cos(p), math.sin(p), math.cos(y), math.sin(y), math.cos(r), math.sin(r)
    fwd = (cp * cy, cp * sy, -sp)
    left = (-(sr * sp * cy - cr * sy), -(sr * sp * sy + cr * cy), -(sr * cp))
    up = (cr * sp * cy + sr * sy, cr * sp * sy - sr * cy, cr * cp)
    return fwd, left, up


def world_box(o, ang, bb):
    if not bb:
        return None
    f, l, u = axes(ang)
    pts = [[o[i] + f[i] * x + l[i] * y + u[i] * z for i in range(3)] for x in (bb[0], bb[3]) for y in (bb[1], bb[4]) for z in (bb[2], bb[5])]
    a = np.array(pts)
    return np.concatenate([a.min(axis=0), a.max(axis=0)])


def yaw_class(y):
    y = y % 360
    d90 = min(y % 90, 90 - y % 90)
    d45 = min(y % 45, 45 - y % 45)
    if d90 < 0.5:
        return "grid"
    if d45 < 0.5:
        return "45"
    if d90 <= 3:
        return "1-3"
    if d90 <= 20:
        return "3-20"
    return "free"


def tilt(ang):
    return max(abs(((ang[0] + 180) % 360) - 180), abs(((ang[2] + 180) % 360) - 180))


def tone(rgb):
    r, g, b = rgb[:3]
    if r > b * 1.15:
        return "warm"
    if b > r * 1.05:
        return "cool"
    return "neutral"


def light_value(text):
    t = [float(x) for x in (text or "255 255 255 200").split()[:4]] if text else [255, 255, 255, 200]
    if len(t) == 3:
        t.append(200.0)
    return (t + [255, 255, 255, 200][len(t):])[:4]


# ---- model sizes: asset_facts.json, learning new models the way map_assets.py does
_sizes = {}


def model_box(model):
    model = model.lower().replace("\\", "/")
    if model not in _sizes:
        try:
            import map_assets
            _sizes[model] = map_assets.size(model) if model.endswith(".mdl") else None
        except Exception:
            _sizes[model] = None
    return _sizes[model]


def model_facts(model):
    import map_assets
    model_box(model)
    return (map_assets._known or {}).get(model.lower().replace("\\", "/")) or {}


def node_points(m, classes=("info_node",)):
    P = [e.origin for e in m.ents if e.cls in classes and m.play_ent(e) and e.origin is not None]
    return np.array(P).reshape(-1, 3)


def near_dist(P, X, cap=8192.0):
    """Distance from each of X to the nearest of P (in chunks)."""
    P, X = np.asarray(P, float), np.asarray(X, float)
    out = np.full(len(X), cap)
    if not len(P) or not len(X):
        return out
    for s in range(0, len(X), 2000):
        d = np.sqrt(((X[s:s + 2000, None, :] - P[None]) ** 2).sum(axis=2)).min(axis=1)
        out[s:s + 2000] = np.minimum(d, cap)
    return out


def visible(mat):
    return not mat.startswith("tools/")


def band(d):
    return "near" if d < 256 else ("mid" if d < 1024 else "far")
