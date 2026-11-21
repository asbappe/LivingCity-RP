"""Living City map ingestion: sentences from measure.json, and the draft pictures.json for a reviewer.

    numbers(meas) -> list of sentences (the "numbers" of a picture set)
    draft(name, meas, pictures, folder) -> the dict written as pictures.json (or pictures.draft.json)

The sentences only say what was counted. What a picture teaches, and the lessons, stay for the reviewer:
every picture's "teaches" is "TODO" and the set carries "draft": true until someone has looked.
"""
import datetime


def _top(lst, n, fmt="%s %d"):
    return ", ".join(fmt % (a, b) for a, b in (lst or [])[:n])


def _mode(d):
    h = (d or {}).get("hist") or {}
    return max(h.items(), key=lambda kv: kv[1])[0] if h else None


def _modes(d, n=3):
    h = (d or {}).get("hist") or {}
    return [k for k, _ in sorted(h.items(), key=lambda kv: -kv[1])[:n]]


def _q(d, i=2):
    return (d or {}).get("q", [None] * 5)[i]


def pct(x):
    return "%d%%" % round(100 * x) if x is not None else "?"


def numbers(M):
    S = []
    c, se, pr, lo, cr = M.get("census", {}), M.get("sections", {}), M.get("props", {}), M.get("logic", {}), M.get("craft", {})
    if c:
        g, f = c["groups"], c["file"]
        sky = c.get("skybox", {})
        S.append("Things: %d prop_static, %d prop_physics, %d prop_dynamic, %d prop_door_rotating, %d prop_ragdoll, %d infodecal, %d info_overlay, "
                 "%d keyframe_rope and %d move_rope, %d func_detail, %d npc entities (makers included); left out: %d hidden objects and %s." % (
                     g["prop_static"], g["prop_physics"], g["prop_dynamic"], g["prop_door_rotating"], g["prop_ragdoll"], g["infodecal"], g["info_overlay"],
                     g["keyframe_rope"], g["move_rope"], g["func_detail"], g["npc"], f["hidden_entities"] + f["hidden_brushes"],
                     ("the 3D skybox room (%d props, scale %s)" % (sky["props"], sky.get("scale")) if sky.get("found") else "no 3D skybox room")))
        sun = c["sun"][0] if c.get("sun") else None
        fog = c["fog"][0] if c.get("fog") else None
        lb = c["light_brightness"]
        S.append("Lights: %d light (median brightness %s), %d light_spot (median %s), %d point_spotlight, %d env_sprite; %s; %s; sky %s." % (
            g["light"], _q(lb.get("light")), g["light_spot"], _q(lb.get("light_spot")), g["point_spotlight"], g["env_sprite"],
            ('sun "%s" at pitch %s, ambient "%s"' % (sun.get("_light"), sun.get("pitch"), sun.get("_ambient"))) if sun else "no light_environment",
            ('fog "%s" from %s to %s' % (fog.get("fogcolor"), fog.get("fogstart"), fog.get("fogend"))) if fog else "no fog controller", c.get("sky")))
        if c.get("soundscapes_top"):
            S.append("Sound: %d env_soundscape (%s), median radius %s; %d ambient_generic (%s)." % (
                g["env_soundscape"], _top(c["soundscapes_top"], 6), _q(c.get("soundscape_radius")), g["ambient_generic"], ", ".join(a for a, _ in c["ambient_top"][:4])))
        S.append("Commonest models: %s." % _top(c["models_top"], 15))
        S.append("Commonest materials (faces): %s." % _top(c["materials_top"], 20))
    nd = se.get("nodes") or {}
    if nd.get("indoor_ceiling", {}).get("n", 0) >= 10:
        m3 = _modes(nd["indoor_ceiling"])
        S.append("Ceilings: floor to ceiling indoors (cast up from %d AI nodes) is most often %s, then %s; %s of the nodes are outdoors; corridors %s wide under %s, "
                 "rooms %s by %s (medians, wall to wall)." % (nd["indoor_ceiling"]["n"], m3[0], " and ".join(m3[1:]), pct(nd["outdoor_share"]),
                                                             _q(nd.get("corridor_width")), nd.get("corridor_ceiling"), _q(nd.get("room_width")), _q(nd.get("room_length"))))
    st = se.get("stairs") or {}
    if st.get("flights"):
        S.append("Stairs: %d flights of 3 or more steps; steps (rise x tread) %s; median %s steps a flight." % (st["flights"], _top(st["rise_tread_top"], 3), _q(st["steps_per_flight"])))
    sts = se.get("streets") or {}
    if sts.get("with_kerbs", 0) >= 4:
        kh = sts["kerb_height"]["hist"]
        S.append("Streets (cuts through %d outdoor AI nodes, %d with a kerb each side): roadway most often %s wide; kerbs %s high; pavements most often %s wide; crown 0 in %d of %d; "
                 "road %s, pavement %s; wall to wall most often %s; street walls median %s tall (height over width %s)." % (
                     sts["sections"], sts["with_kerbs"], _mode(sts["road_width"]), " or ".join("%s (%d)" % kv for kv in sorted(kh.items(), key=lambda kv: -kv[1])[:2]),
                     ", ".join(x for x in _modes(sts["pavement_width"]) if x != "0"), sts["crown"]["hist"].get("0", 0), sts["with_kerbs"],
                     (sts["road_mats_top"] or [["?"]])[0][0], (sts["pavement_mats_top"] or [["?"]])[0][0], _mode(sts["wall_to_wall"]), _q(sts["wall_height"]), sts["height_over_width"]))
    elif sts.get("sections"):
        S.append("Streets: no kerbed roadway in %d cuts through outdoor AI nodes; wall to wall most often %s; walls median %s tall (height over width %s)." % (
            sts["sections"], _mode(sts["wall_to_wall"]), _q(sts["wall_height"]), sts["height_over_width"]))
    ch = se.get("channels") or {}
    k = ch.get("kinds", {})
    if k.get("open", 0) >= 3:
        o, t = ch["open"], ch["tunnel"]
        S.append("Channels (%d cuts across the shortest way, %d at water: %d open, %d tunnels): open width 64 up most often %s, 128 up %s; rims (where a side opens out) %s; "
                 "water %s deep%s; tunnels most often %s wide, roof %s up." % (
                     ch["cuts"], ch["from_water"], k.get("open", 0), k.get("tunnel", 0), _mode(o["w64"]), _mode(o["w128"]), _q(o["rim_lo"]),
                     _q(o["water"]) if o["water"].get("n") else 0, ("; ledges %s wide at %s up" % (_q(o["ledge_w"]), _q(o["ledge_h"]))) if o["ledge_h"].get("n") else "",
                     _mode(t["max"]), _mode(t["crown"])))
    dw = se.get("doorways") or {}
    if dw.get("doors"):
        S.append("Doors: %s; openings at them (wide x high): %s." % (_top(dw["models_top"], 3), _top([x for x in dw["openings_top"] if "?" not in x[0]], 3)))
    if c:
        r = c.get("ropes", {})
        if r.get("spans", {}).get("n"):
            S.append("Cables: %d rope spans, median %s long, slack %s, width %s." % (r["spans"]["n"], _q(r["spans"]), r["slack"], r["width"]))
        if c.get("spacing"):
            S.append("Spacing (nearest of the same model): %s." % ", ".join("%s %s apart (n %d)" % (k2, v[1], v[0]) for k2, v in list(c["spacing"].items())[:6]))
    if cr:
        wb, sl = cr.get("wall_bands", {}), cr.get("slopes", {})
        if wb.get("columns_256"):
            S.append("Walls in bands: %s of wall columns over 256 tall change material at least once; the first change most often %s over the foot; pairs (below > above): %s." % (
                pct(wb["banded_share"]), " or ".join(_modes(wb["first_change"], 2)), ", ".join(a for a, _ in wb["pairs_top"][:3])))
        if cr.get("fronts", {}).get("template_share", 0) > 0.05:
            S.append("Fronts: %s of vertical wall area is painted building fronts (%s)." % (pct(cr["fronts"]["template_share"]), ", ".join(a for a, _ in cr["fronts"]["templates_top"][:3])))
        if sl.get("n", 0) >= 10:
            S.append("Slopes: %d sloped faces over 2000 square units, most often %s degrees; %s." % (sl["n"], ", ".join(_modes(sl["pitch"])), ", ".join(a for a, _ in sl["materials_top"][:3])))
    if pr.get("n"):
        y = pr.get("yaw", {})
        wg = pr.get("wall_gap", {})
        de = pr.get("density", {})
        S.append("Props: %d in play; on exact 90s: static %s, physics %s; physics tilted %s (lying most often %s); statics touching a wall %s, physics within 16 of one %s; "
                 "%s props per 1000 square units of play (%s physics)." % (
                     pr["n"], pct(y.get("prop_static", {}).get("grid")), pct(y.get("prop_physics", {}).get("grid")), pct(pr.get("tilted", {}).get("prop_physics")),
                     ", ".join(a for a, _ in pr.get("lying_by_kind", [])[:3]) or "nothing", pct(wg.get("prop_static", {}).get("touch")),
                     pct(sum(v for kk, v in wg.get("prop_physics", {}).items() if kk in ("touch", "<=4", "4-16"))) if wg.get("prop_physics") else "?",
                     de.get("per_1000"), de.get("physics_per_1000")))
    if lo.get("outputs"):
        S.append("Wiring: %d output lines from %d entities; commonest %s; %d relays (longest chain %d), %d counters, %d timers, %d makers, %d buttons working doors; %d lines name nothing." % (
            lo["outputs"], lo["with_outputs"], _top(lo["pairs_top"], 3), lo["relays"]["n"], lo["relays"]["chain_longest"], lo["counters"]["n"], lo["timers"]["n"],
            lo["makers"]["n"], lo["button_door"], lo["targets"].get("missing", 0)))
    if cr.get("texture"):
        tx, lm, br = cr["texture"], cr["lightmapscale"], cr["brushes"]
        S.append("Craft: texture scale %s on %s of faces; lightmapscale 16 on %s (near the nodes %s, far %s); func_detail %s of brushes; %d trim strips (%s); %d chamfers; %d displacements." % (
            *(list(tx["scale"].items())[0] if tx["scale"] else ("?", 0))[:1], pct(list(tx["scale"].values())[0] if tx["scale"] else None),
            pct(lm["faces"].get("16")), pct(lm["by_distance"].get("near", {}).get("16")), pct(lm["by_distance"].get("far", {}).get("16")),
            pct(br["detail_share"]), cr["trims"]["n"], _top(cr["trims"]["sections_top"], 2), cr["chamfers"]["n"], cr["displacements"]["n"]))
        rec = cr["lights"].get("recipes", [])
        named = [r for r in rec if r["fixture"] != "(none)"][:4]
        if named:
            S.append("Light by fixture: %s." % "; ".join("%s: %s %s %s%s" % (r["fixture"], r["class"], r["light"], r["bright"], (", cone %s, pitch %s" % (r["cone"], r["pitch"])) if r["class"] == "light_spot" else "") for r in named))
        dc = cr.get("decals", {})
        if dc.get("decals", 0) + dc.get("overlays", 0):
            S.append("Grime: %d infodecal and %d info_overlay; on walls %s; wall decals median %s over the floor." % (
                dc["decals"], dc["overlays"], _top(dc["decal_kinds"].get("wall", []), 4), _q(dc["wall_height"]["decals"])))
    return S


def code(name):
    for a, b in (("d1_trainstation_", "ts"), ("d1_canals_", "c"), ("d1_town_", "town"), ("d3_c17_", "c17_"), ("d3_citadel_", "cit"), ("d2_coast_", "coast"),
                 ("d2_prison_", "prison"), ("d3_breen_", "breen"), ("ep1_", "e1_"), ("ep2_", "e2_"), ("d1_eli_", "eli"), ("d2_", ""), ("d3_", ""), ("d1_", "")):
        if name.startswith(a):
            return b + name[len(a):]
    return name


def draft(name, M, pictures, folder):
    today = datetime.date.today().isoformat()
    about = ("Valve's own %s, measured by map_ingest.py on %s (play space only: hidden objects and the 3D skybox room left out) and drawn by map_view.py "
             "(flat colours; props are boxes of their true size, orange static, yellow physics, cyan dynamic, green NPCs; trees drawn as trunk and canopy, poles thin). "
             "Reference only: the VMF is not in the repo. DRAFT: a reviewer fills in what each picture teaches, picks the lessons, and removes \"draft\"." % (name, today))
    c = code(name)
    pics = [{"n": "%s.%d" % (c, k + 1), "file": p["file"], "where": p["where"], "teaches": "TODO", "lessons": [], **({"view": p["view"]} if p.get("view") else {})}
            for k, p in enumerate(pictures)]
    return {"title": "Valve's %s (draft)" % name, "draft": True, "about": about, "numbers": numbers(M), "pictures": pics,
            "pictures_folder": folder}
