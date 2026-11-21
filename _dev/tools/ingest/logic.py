"""Living City map ingestion, part "logic": how the map is wired (the logic helpers' la.py and recipes, counted).

    run(m) -> dict for measure.json["logic"]

Every entity outside the 3D skybox room counts, hidden ones too (they are flagged: the earlier logic pass counted
them). Output lines are (output, target, input, value, delay, times). Patterns found: a button that works a door,
an alarm, a counter, a timer, relay chains, makers; targets that name nothing; named things nothing fires.
"""
import collections
import fnmatch
import re

from .common import C, dist, top, med, rnd
from .vmf import SPECIAL

LOGIC = re.compile(r"^(trigger_|logic_|math_|filter_|env_|ambient_generic|npc_maker|npc_template_maker|func_button|func_rot_button|"
                   r"momentary_rot_button|func_door|func_movelinear|func_tracktrain|path_|point_|game_|scripted_|aiscripted_|ai_|"
                   r"info_target|func_breakable|func_physbox|prop_door_rotating|phys_|func_areaportal|func_rotating|func_brush)")
BUTTONS = ("func_button", "func_rot_button", "momentary_rot_button")
DOORS = ("func_door", "func_door_rotating", "prop_door_rotating", "func_movelinear", "func_tracktrain", "func_areaportal")
ALARM = re.compile(r"alarm|siren|klaxon|bell")


def run(m):
    E = [e for e in m.ents if not e.sky]
    names = collections.defaultdict(list)
    for e in E:
        if e.name:
            names[e.name.lower()].append(e)
    classes = set(e.cls for e in E)
    lines = [(e, o) for e in E for o in e.outputs]
    R = collections.OrderedDict()
    R["entities"], R["hidden"] = len(E), sum(e.hidden for e in E)
    R["classes_top"] = top(C(e.cls for e in E if LOGIC.match(e.cls)), 50)
    R["outputs"] = len(lines)
    R["with_outputs"] = sum(1 for e in E if e.outputs)
    R["outputs_top"] = top(C(o[0] for _, o in lines), 20)
    R["inputs_top"] = top(C(o[2] for _, o in lines), 25)
    R["pairs_top"] = top(C("%s>%s" % (o[0], o[2]) for _, o in lines), 20)
    R["fan_out"] = dist([len(e.outputs) for e in E if e.outputs], 1, 12)
    R["delay"] = dist([o[4] for _, o in lines], 0.5, 14)
    R["max_delay"] = rnd(max([o[4] for _, o in lines] or [0]))
    R["times"] = {"once": sum(1 for _, o in lines if o[5] == 1), "always": sum(1 for _, o in lines if o[5] < 0),
                  "other": sum(1 for _, o in lines if o[5] > 1)}
    kinds, missing = C(), C()
    for e, o in lines:
        t = o[1].lower()
        k = target_kind(t, names, classes)
        kinds[k] += 1
        if k == "missing":
            missing[o[1]] += 1
    R["targets"] = dict(kinds)
    R["missing_targets_top"] = top(missing, 10)
    R.update(patterns(E, names, lines))
    R["checks"] = checks(E, names, lines)
    return R


def target_kind(t, names, classes):
    if not t:
        return "empty"
    if t in SPECIAL or t.startswith("!"):
        return "special"
    if "*" in t:
        return "wildcard" if any(fnmatch.fnmatch(n, t) for n in names) else "missing"
    if t in names:
        return "named"
    if t in classes:
        return "classname"
    return "missing"


def resolve(t, names):
    t = t.lower()
    if "*" in t:
        return [e for n, es in names.items() if fnmatch.fnmatch(n, t) for e in es]
    return names.get(t, [])


def patterns(E, names, lines):
    R = {}
    incoming = collections.defaultdict(list)
    for e, o in lines:
        for t in resolve(o[1], names):
            incoming[t.i].append((e, o))
    # a button that works a door, straight or through one relay
    bd = 0
    for e in E:
        if e.cls in BUTTONS:
            hit = False
            for o in e.outputs:
                for t in resolve(o[1], names):
                    if t.cls in DOORS or (t.cls == "logic_relay" and any(u.cls in DOORS for o2 in t.outputs for u in resolve(o2[1], names))):
                        hit = True
            bd += hit
    R["button_door"] = bd
    R["buttons"] = {"n": sum(e.cls in BUTTONS for e in E), "flags_top": top(C(e.kv.get("spawnflags", "0") for e in E if e.cls in BUTTONS), 5),
                    "wait_top": top(C(e.kv.get("wait", "") for e in E if e.cls in BUTTONS), 4)}
    # alarms: something that plays an alarm-like sound, or lights a spotlight and starts a rotator together
    al = 0
    for e in E:
        snd = any(t.cls == "ambient_generic" and ALARM.search(t.kv.get("message", "").lower()) for o in e.outputs if o[2].lower() == "playsound"
                  for t in resolve(o[1], names))
        beacon = any(o[2].lower() == "lighton" for o in e.outputs) and any(o[2].lower() == "start" for o in e.outputs)
        al += bool(snd or beacon)
    R["alarms"] = al
    cnt = [e for e in E if e.cls == "math_counter"]
    R["counters"] = {"n": len(cnt), "max_top": top(C(e.kv.get("max", "") for e in cnt), 6),
                     "fed_by_top": top(C(src.cls for e in cnt for src, o in incoming[e.i] if o[2].lower() in ("add", "subtract")), 6),
                     "on_hit_max": sum(1 for e in cnt if any(o[0].lower() == "onhitmax" for o in e.outputs))}
    tm = [e for e in E if e.cls == "logic_timer"]
    R["timers"] = {"n": len(tm), "random": sum(e.kv.get("userandomtime", "0") == "1" for e in tm),
                   "start_disabled": sum(e.kv.get("startdisabled", "0") == "1" for e in tm),
                   "refire_top": top(C(e.kv.get("refiretime", "") for e in tm if e.kv.get("userandomtime", "0") != "1"), 5),
                   "bounds_top": top(C("%s-%s" % (e.kv.get("lowerrandombound", ""), e.kv.get("upperrandombound", "")) for e in tm if e.kv.get("userandomtime", "0") == "1"), 5),
                   "switched_by_touch": sum(1 for e in tm if any(o[0].lower().startswith(("onstarttouch", "onendtouch")) for _, o in incoming[e.i]))}
    relays = [e for e in E if e.cls == "logic_relay"]
    nxt = {e.i: [t.i for o in e.outputs for t in resolve(o[1], names) if t.cls == "logic_relay" and t.i != e.i] for e in relays}

    def depth(i, seen):
        if i in seen:
            return 0
        seen = seen | {i}
        return 1 + max([depth(j, seen) for j in nxt.get(i, [])] or [0])
    chains = [depth(e.i, frozenset()) for e in relays if not any(src.cls == "logic_relay" for src, _ in incoming[e.i])]
    R["relays"] = {"n": len(relays), "chain_longest": max(chains or [0]), "chains_3_or_more": sum(1 for c in chains if c >= 3),
                   "outputs_each": dist([len(e.outputs) for e in relays], 1, 10),
                   "fired_by_top": top(C(src.cls for e in relays for src, _ in incoming[e.i]), 6)}
    mk = [e for e in E if e.cls in ("npc_maker", "npc_template_maker", "npc_antlion_template_maker")]
    R["makers"] = {"n": len(mk), "classes": dict(C(e.cls for e in mk)), "max_npcs_top": top(C(e.kv.get("maxnpccount", "") for e in mk), 5),
                   "live_top": top(C(e.kv.get("maxlivechildren", "") for e in mk), 5), "frequency_top": top(C(e.kv.get("spawnfrequency", "") for e in mk), 5),
                   "start_disabled": sum(e.kv.get("startdisabled", "0") == "1" for e in mk),
                   "fired_with_top": top(C(o[2] for e in mk for _, o in incoming[e.i]), 5)}
    tr = [e for e in E if e.cls in ("trigger_once", "trigger_multiple")]
    R["triggers"] = {k: {"n": sum(e.cls == k for e in tr), "flags_top": top(C(e.kv.get("spawnflags", "") for e in tr if e.cls == k), 4),
                         "wait_top": top(C(e.kv.get("wait", "") for e in tr if e.cls == k), 4),
                         "start_disabled": sum(e.kv.get("startdisabled", "0") == "1" for e in tr if e.cls == k)}
                     for k in ("trigger_once", "trigger_multiple")}
    auto = [e for e in E if e.cls == "logic_auto"]
    R["logic_auto"] = {"n": len(auto), "lines": sum(len(e.outputs) for e in auto), "inputs_top": top(C(o[2] for e in auto for o in e.outputs), 8)}
    par = {e.i: e.kv.get("parentname", "").split(",")[0].lower() for e in E if e.kv.get("parentname")}

    def pdepth(e, k=0):
        p = names.get(par.get(e.i, ""), [])
        return k if not p or k > 8 else pdepth(p[0], k + 1)
    R["parented"] = {"n": len(par), "deepest": max([pdepth(e) for e in E if e.i in par] or [0]),
                     "children_top": top(C(e.cls for e in E if e.i in par), 6)}
    amb = [e for e in E if e.cls == "ambient_generic"]
    R["sounds"] = {"n": len(amb), "start_silent": sum(int(e.kv.get("spawnflags", "0") or 0) & 16 > 0 for e in amb),
                   "not_looped": sum(int(e.kv.get("spawnflags", "0") or 0) & 32 > 0 for e in amb),
                   "played_by_lines": sum(1 for e in amb for _, o in incoming[e.i] if o[2].lower() == "playsound")}
    return R


def checks(E, names, lines):
    """The proposed wiring checks, as counts with a few names each."""
    targeted = set()
    for _, o in lines:
        for t in resolve(o[1], names):
            targeted.add(t.i)
    unused = [e.name for e in E if e.name and e.i not in targeted and e.cls in ("logic_relay", "logic_timer", "math_counter", "ambient_generic", "logic_case", "logic_branch")]
    adds = C()
    for _, o in lines:
        if o[2].lower() == "add":
            for t in resolve(o[1], names):
                adds[t.i] += 1
    short_counters = [e.name for e in E if e.cls == "math_counter" and adds[e.i] and adds[e.i] < float(e.kv.get("max", "0") or 0)]
    dead_timers = [e.name for e in E if e.cls == "logic_timer" and float(e.kv.get("refiretime", "0") or 0) <= 0 and e.kv.get("userandomtime", "0") != "1"]
    no_use = [e.name or e.cls for e in E if e.cls == "func_button" and not int(e.kv.get("spawnflags", "0") or 0) & (256 | 512 | 1024)]
    player = sum(1 for _, o in lines if o[1].lower() == "!player")
    big = [e.name for e in E if e.cls == "logic_relay" and len(e.outputs) > 40]
    return {"unused_named": [len(unused), unused[:8]], "counters_short_of_max": [len(short_counters), short_counters[:5]],
            "timers_without_time": [len(dead_timers), dead_timers[:5]], "buttons_nobody_can_press": [len(no_use), no_use[:5]],
            "lines_to_player": player, "relays_over_40_lines": [len(big), big[:3]]}
