#!/usr/bin/env python3
"""Set pieces worth lifting from Valve's maps (the owner, 23 November: "is there a way to find other unique assets in
HL2, EP1, and EP2 that can be lifted for future use? I'm sure there are tons I'm just forgetting").

Reads every game map of HL2, Episode One and Episode Two (straight from the owner's VMF zip, or from a folder) as text
(Valve's files are untrusted data: nothing in them is run) and finds the places where Valve built something: a group of
entities wired to each other (outputs, parents, templates, any key naming another), with the rare props standing round
it. Each group is scored by what makes a set piece: models found in only one or two maps, entity kinds few maps use,
effects (beams, lasers, sprites, particles, sparks, shakes), machinery (moving brushes, tanks, buttons, physics
constraints), and its size; a group that is mostly story (choreographed scenes, scripted sequences, Alyx and friends)
scores less. Valve's own visgroup names on the group's entities are kept: they often say what it is ("new cannon",
"cannon gennie"). A group inside a piece we have already lifted is marked with the piece's name.

    python3 map_setpieces.py ZIP_OR_FOLDER [--top 150]    writes _dev/reference/valve_setpieces.json and prints the top
    python3 map_setpieces.py --show                        prints the top again from the JSON
    python3 map_setpieces.py --map d2_prison_05            one map's groups from the JSON
    python3 map_setpieces.py --find WORD                   groups whose models, kinds, names or visgroups hold WORD

The curated list built from it is docs/dev/valve-setpieces.md.
"""

import argparse
import json
import math
import os
import re
import sys
import zipfile
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "reference", "valve_setpieces.json")
PREFABS = os.path.join(HERE, "..", "reference", "prefabs")
GAME = re.compile(r"(^|/)(d1_(canals|eli|town|trainstation)_\d+a?|d2_(coast|prison)_\d+|d3_(c17|citadel)_\d+[ab]?|d3_breen_01|ep1_(c17|citadel)_\d+[ab]?|ep1_intro|ep2_intro|ep2_outland_\d+[ab]?)\.vmf$", re.I)      # (the shipped maps: no drafts, tests or demos)
SKIP = re.compile(r"_fix\.vmf$|_ps3\.vmf$|ep1_intro_00", re.I)
KV = re.compile(r'^\s*"([^"]+)"\s+"([^"]*)"\s*$')
FX = ("env_laser", "env_beam", "env_sprite", "env_spark", "info_particle_system", "env_smokestack", "env_steam", "point_spotlight",
      "env_shake", "env_explosion", "env_physexplosion", "env_fire", "env_lightglow", "env_citadel_energy_core", "env_alyxemp",
      "env_entity_dissolver", "env_splash", "env_smoketrail", "env_embers", "env_screenoverlay", "env_fade", "env_shooter",
      "env_gunfire", "env_rotorwash_emitter", "env_portal_path_track", "point_tesla", "env_starfield", "func_dustmotes", "env_dustpuff")
MECH = ("func_door", "func_door_rotating", "func_movelinear", "func_tracktrain", "func_rotating", "func_physbox", "func_breakable",
        "momentary_rot_button", "func_button", "func_rot_button", "func_tank", "func_tank_combine_cannon", "func_tankairboatgun",
        "func_tankmortar", "func_tankrocket", "func_tanklaser", "func_tankpulselaser", "func_tankphyscannister", "func_platrot",
        "phys_hinge", "phys_ballsocket", "phys_constraint", "phys_lengthconstraint", "phys_pulleyconstraint", "phys_slideconstraint",
        "phys_spring", "phys_thruster", "phys_torque", "phys_motor", "phys_keepupright", "keyframe_rope", "move_rope", "prop_vehicle_crane",
        "prop_thumper", "func_monitor", "point_camera", "func_conveyor", "func_water_analog", "func_breakable_surf", "item_ammo_crate")
STORY = ("logic_choreographed_scene", "scripted_sequence", "ai_goal_follow", "ai_goal_lead", "trigger_changelevel", "info_landmark",
         "npc_alyx", "npc_barney", "npc_eli", "npc_kleiner", "npc_mossman", "npc_magnusson", "npc_gman", "npc_breen", "npc_monk",
         "npc_dog", "npc_citizen", "env_message", "game_text", "logic_autosave", "point_viewcontrol")
PROPS = ("prop_static", "prop_dynamic", "prop_dynamic_override", "prop_physics", "prop_physics_override", "prop_physics_multiplayer", "prop_ragdoll")
NOT_LOGIC = ("worldspawn", "info_node", "info_node_hint", "info_node_air", "info_node_air_hint", "env_cubemap", "info_overlay",
             "light", "light_spot", "light_environment", "func_detail", "func_viscluster", "info_player_start", "env_soundscape",
             "env_soundscape_proxy", "env_soundscape_triggerable", "func_areaportal", "func_areaportalwindow", "func_occluder", "info_lighting")
NOT_NAME_KEYS = ("classname", "model", "origin", "angles", "id", "message", "spawnflags", "targetname", "skin", "rendercolor", "_light")


def maps_in(src):
    """(map name, text) for every game map in a zip or a folder."""
    if os.path.isdir(src):
        for root, _, files in os.walk(src):
            for f in sorted(files):
                p = os.path.join(root, f)
                if GAME.search(p) and not SKIP.search(p):
                    yield f[:-4], open(p, encoding="latin-1").read()
        return
    with zipfile.ZipFile(src) as z:
        for n in sorted(z.namelist()):
            if GAME.search(n) and not SKIP.search(n) and "/instances/" not in n and "/dev/" not in n:
                yield os.path.basename(n)[:-4], z.read(n).decode("latin-1")


def entities(text):
    """Every top-level entity: its keys, outputs (target names), visgroups, and where it is (origin, or its brushes' middle)."""
    lines = text.split("\n")
    vis, ents, i, n = {}, [], 0, len(lines)
    while i < n:
        head = lines[i].strip()
        if head in ("entity", "visgroups") and i + 1 < n and lines[i + 1].strip() == "{":
            depth, j, kv, outs, vids, stack, nums = 0, i + 1, {}, [], [], [], []
            vname = None
            while j < n:
                t = lines[j].strip()
                if t == "{":
                    depth += 1
                    stack.append(lines[j - 1].strip())
                elif t == "}":
                    depth -= 1
                    stack.pop() if stack else None
                    if depth == 0:
                        break
                else:
                    m = KV.match(lines[j])
                    if m:
                        k, v = m.groups()
                        top = stack[-1] if stack else ""
                        if head == "visgroups":
                            if k == "name":
                                vname = v
                            elif k == "visgroupid" and vname is not None:
                                vis[v] = vname
                        elif depth == 1:
                            kv.setdefault(k.lower(), v)
                        elif top == "connections":
                            outs.append(v.replace("\x1b", ",").split(",")[0].strip())
                        elif top == "editor" and k == "visgroupid":
                            vids.append(v)
                        elif k == "plane" and len(nums) < 600:
                            nums += [float(x) for x in re.findall(r"-?\d+(?:\.\d+)?", v)]
                j += 1
            if head == "entity":
                o = kv.get("origin")
                if o:
                    try:
                        pos = [float(x) for x in o.split()[:3]]
                    except ValueError:
                        pos = None
                elif nums:
                    xs, ys, zs = nums[0::3], nums[1::3], nums[2::3]
                    pos = [(min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2]
                else:
                    pos = None
                ents.append({"kv": kv, "outs": outs, "vis": vids, "pos": pos})
            i = j + 1
        else:
            i += 1
    return ents, vis


def short(model):
    return model.lower().replace("\\", "/").split("/")[-1].replace(".mdl", "")


def scan(src):
    per_map, model_maps, class_maps = {}, defaultdict(set), defaultdict(set)
    for name, text in maps_in(src):
        ents, vis = entities(text)
        per_map[name] = (ents, vis)
        for e in ents:
            cls = e["kv"].get("classname", "").lower()
            class_maps[cls].add(name)
            if e["kv"].get("model", "").lower().endswith(".mdl"):
                model_maps[short(e["kv"]["model"])].add(name)
        print("  %-24s %6d entities" % (name, len(ents)), file=sys.stderr)
    lifted = []
    for f in sorted(os.listdir(PREFABS)) if os.path.isdir(PREFABS) else []:
        if f.startswith("valve_") and f.endswith(".json"):
            with open(os.path.join(PREFABS, f)) as h:
                head = h.read(4000)
            frm = re.search(r'"from":\s*"([^"]+)"', head)
            box = re.search(r'"box":\s*\[([^\]]+)\]', head)
            if frm and box:
                lifted.append((frm.group(1).replace(".vmf", ""), [float(x) for x in box.group(1).split(",")], f[:-5]))
    groups = []
    for name, (ents, vis) in per_map.items():
        groups += islands(name, ents, vis, model_maps, class_maps, lifted)
    groups.sort(key=lambda g: -g["score"])
    return groups, len(per_map)


def islands(mapname, ents, vis, model_maps, class_maps, lifted):
    names = defaultdict(list)
    for i, e in enumerate(ents):
        t = e["kv"].get("targetname", "").lower()
        if t:
            names[t].append(i)
    parent = list(range(len(ents)))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    def join(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    def reach(t):
        t = t.lower()
        if t.endswith("*"):
            return [i for k, ix in names.items() if k.startswith(t[:-1]) for i in ix]
        return names.get(t, [])
    linked = set()
    for i, e in enumerate(ents):
        cls = e["kv"].get("classname", "").lower()
        if cls in NOT_LOGIC:
            continue
        refs = list(e["outs"]) + [v for k, v in e["kv"].items() if k not in NOT_NAME_KEYS and v and not v[0].isdigit() and v.lower() in names]
        for t in refs:
            if t.startswith("!"):
                continue
            for j in reach(t):
                if ents[j]["kv"].get("classname", "").lower() in NOT_LOGIC or len(names.get(t.lower(), ())) > 12:
                    continue      # (a name a dozen things share, a class-wide name: not one set piece)
                join(i, j)
                linked.update((i, j))
    comps = defaultdict(list)
    for i in linked:
        comps[find(i)].append(i)
    # Rare props standing near a group join it (the chair, the ragdoll, the machine nobody wires).
    rare_props = [i for i, e in enumerate(ents) if e["kv"].get("classname", "").lower() in PROPS and e["pos"]
                  and e["kv"].get("model", "").lower().endswith(".mdl") and len(model_maps[short(e["kv"]["model"])]) <= 2 and i not in linked]
    out = []
    for root, members in comps.items():
        pts = [ents[i]["pos"] for i in members if ents[i]["pos"]]
        if len(members) < 3 or not pts:
            continue
        c = [sorted(p[k] for p in pts)[len(pts) // 2] for k in range(3)]      # (the median: one far relay does not move it)
        near = [i for i in rare_props if math.dist(ents[i]["pos"], c) < 384]
        allm = members + near
        close = [ents[i]["pos"] for i in allm if ents[i]["pos"] and math.dist(ents[i]["pos"], c) < 1024] or pts
        cls = Counter(ents[i]["kv"].get("classname", "").lower() for i in allm)
        models = Counter(short(ents[i]["kv"]["model"]) for i in allm if ents[i]["kv"].get("model", "").lower().endswith(".mdl"))
        rare_m = sorted(m for m in models if len(model_maps[m]) <= 2)
        rare_c = sorted(k for k in cls if len(class_maps[k]) <= 6 and k not in STORY)
        fx = sum(v for k, v in cls.items() if k in FX)
        mech = sum(v for k, v in cls.items() if k in MECH or k.startswith("func_tank"))
        story = sum(v for k, v in cls.items() if k in STORY)
        npcs = sum(v for k, v in cls.items() if k.startswith("npc_") and k not in STORY)
        score = 3 * len(rare_m) + 2 * len(rare_c) + min(fx, 10) + min(mech, 10) + 0.3 * min(npcs, 10) + 0.15 * min(len(allm), 60) - 0.6 * min(story, 15)
        vnames = Counter(vis.get(v, "") for i in allm for v in ents[i]["vis"] if vis.get(v))
        tnames = Counter(ents[i]["kv"].get("targetname", "") for i in allm if ents[i]["kv"].get("targetname"))
        box = [round(min(p[k] for p in close)) for k in range(3)] + [round(max(p[k] for p in close)) for k in range(3)]
        held = [ents[i]["pos"] for i in allm if ents[i]["pos"]]
        done = [nm for m, b, nm in lifted if m == mapname and sum(1 for p in held if all(b[k] - 64 <= p[k] <= b[k + 3] + 64 for k in range(3))) >= 0.2 * len(held)]
        # (lifted: a fifth of the group stands in a piece we hold; a group spilling out of it into Valve's story still counts)
        out.append({"map": mapname, "score": round(score, 1), "at": [round(x) for x in c], "box": box, "n": len(allm),
                    "rare_models": rare_m[:12], "rare_kinds": rare_c[:10], "fx": fx, "mech": mech, "story": story, "npcs": npcs,
                    "kinds": [k for k, _ in cls.most_common(8)], "models": [m for m, _ in models.most_common(8)],
                    "visgroups": [v for v, _ in vnames.most_common(5)], "names": [t for t, _ in tnames.most_common(6)], "lifted": done[:2]})
    return out


def line(g):
    tag = (" [lifted: %s]" % ", ".join(g["lifted"])) if g["lifted"] else ""
    bits = []
    if g["visgroups"]:
        bits.append("vis: " + ", ".join(g["visgroups"][:3]))
    if g["rare_models"]:
        bits.append("rare: " + " ".join(g["rare_models"][:6]))
    if g["rare_kinds"]:
        bits.append("kinds: " + " ".join(g["rare_kinds"][:5]))
    bits.append("names: " + " ".join(g["names"][:4]))
    return "%5.1f %-18s %6d %6d %5d n%-3d fx%-2d mech%-2d story%-2d %s%s" % (g["score"], g["map"], g["at"][0], g["at"][1], g["at"][2], g["n"], g["fx"], g["mech"], g["story"], " | ".join(bits), tag)


def main():
    ap = argparse.ArgumentParser(description="Find set pieces worth lifting in Valve's maps.")
    ap.add_argument("src", nargs="?", help="the owner's VMF zip (HL2Leak-VMFs-master.zip) or a folder of VMFs")
    ap.add_argument("--top", type=int, default=150)
    ap.add_argument("--show", action="store_true")
    ap.add_argument("--map")
    ap.add_argument("--find")
    a = ap.parse_args()
    if a.src:
        groups, nmaps = scan(a.src)
        with open(OUT, "w") as f:
            json.dump({"what": "set pieces in Valve's maps, best first (map_setpieces.py)", "maps": nmaps, "groups": [g for g in groups if g["score"] >= 8]}, f, indent=0)
        print("%d maps, %d groups (%d scored 8 or more, kept) -> %s" % (nmaps, len(groups), sum(1 for g in groups if g["score"] >= 8), os.path.relpath(OUT)))
    with open(OUT) as f:
        groups = json.load(f)["groups"]
    if a.map:
        groups = [g for g in groups if g["map"] == a.map]
    if a.find:
        w = a.find.lower()
        groups = [g for g in groups if w in json.dumps(g).lower()]
    for g in groups[:a.top]:
        print(line(g)[:330])


if __name__ == "__main__":
    main()
