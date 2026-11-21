"""Living City map ingestion, part "census": what is in the map, counted (play space only: no hidden objects, no
3D skybox room, which is described on its own).

    run(m) -> dict for measure.json["census"]
"""
import collections
import re

import numpy as np

from .common import C, dist, top, med, short, kind, light_value, tone, shares, rnd

GROUPS = (("prop_static", "prop_static"), ("prop_physics", "prop_physics*"), ("prop_dynamic", "prop_dynamic*"),
          ("prop_door_rotating", "prop_door_rotating"), ("prop_ragdoll", "prop_ragdoll"), ("light", "light"), ("light_spot", "light_spot"),
          ("point_spotlight", "point_spotlight"), ("env_sprite", "env_sprite"), ("infodecal", "infodecal"), ("info_overlay", "info_overlay"),
          ("env_soundscape", "env_soundscape*"), ("ambient_generic", "ambient_generic"), ("keyframe_rope", "keyframe_rope"),
          ("move_rope", "move_rope"), ("func_detail", "func_detail"), ("func_brush", "func_brush"), ("func_breakable", "func_breakable*"),
          ("func_door", "func_door*"), ("npc", "npc_*"), ("info_node", "info_node"), ("info_node_air", "info_node_air"),
          ("info_node_hint", "info_node_hint"), ("trigger", "trigger_*"), ("logic", "logic_*"), ("env_fire", "env_fire"),
          ("item", "item_*"), ("weapon", "weapon_*"), ("env_cubemap", "env_cubemap"))
SPACED = r"lamp|light_?post|streetlight|pole|column|pillar|bollard|post|telephone|utility|powerline|pylon|tree|bench|trashcan|hydrant|fence|cagelight|lampfixture"


def count_group(cls, pat):
    return sum(n for c, n in cls.items() if (c.startswith(pat[:-1]) if pat.endswith("*") else c == pat))


def run(m, solid=None):
    play = [e for e in m.ents if m.play_ent(e)]
    cls = C(e.cls for e in play)
    R = collections.OrderedDict()
    R["file"] = dict(name=m.name, editorversion=m.editorversion, vertices_plus=m.vertices_plus, entities=len(m.ents),
                     hidden_entities=sum(e.hidden for e in m.ents), skybox_entities=sum(e.sky and not e.hidden for e in m.ents),
                     brushes=int(len(m.b_owner)), hidden_brushes=int(m.b_hidden.sum()), skybox_brushes=int((m.b_sky & ~m.b_hidden).sum()),
                     faces=int(len(m.f_mat)), displacements=len(m.disps), unreadable_brushes=m.bad_brushes,
                     visgroups=len(m.visgroups))
    R["classes_top"] = top(cls, 60)
    R["groups"] = {k: count_group(cls, pat) for k, pat in GROUPS}
    mods = [(e.cls, e.model) for e in play if e.model.endswith(".mdl")]
    R["models_top"] = top(C(short(md) for _, md in mods), 25)
    R["models_by_class"] = {k: top(C(short(md) for c, md in mods if c.startswith(k)), 10)
                            for k in ("prop_static", "prop_physics", "prop_dynamic", "prop_ragdoll")}
    R["model_kinds"] = dict(C(kind(md, c) for c, md in mods if c.startswith("prop_")).most_common())
    R["model_folders_top"] = top(C(md.split("/")[1] if md.count("/") >= 2 else "?" for _, md in mods), 12)
    R["skybox"] = sky_room(m)
    R.update(materials(m))
    R.update(sound(play))
    R.update(lights(m, play))
    R["decals_top"] = top(C(e.kv.get("texture", "").lower() for e in play if e.cls == "infodecal"), 15, short=True)
    R["overlays_top"] = top(C(e.kv.get("material", "").lower() for e in play if e.cls == "info_overlay"), 12, short=True)
    R["ropes"] = ropes(play)
    R["npcs_top"] = top(C(e.cls for e in play if e.cls.startswith("npc_")), 15)
    R["items_top"] = top(C(e.cls for e in play if e.cls.startswith(("item_", "weapon_"))), 12)
    R["spacing"] = spacing(play)
    return R


def sky_room(m):
    if m.sky_box is None:
        return {"found": False, "how": m.sky_how}
    sk = [e for e in m.ents if e.sky and not e.hidden]
    cam = [e for e in sk if e.cls == "sky_camera"]
    size = m.sky_box[1] - m.sky_box[0]
    b = np.where(m.b_sky & ~m.b_hidden)[0]
    mats = C(m.mat(f) for i in b for f in m.faces_of(i) if not m.mat(f).startswith("tools/"))
    return {"found": True, "how": m.sky_how, "scale": cam[0].kv.get("scale") if cam else None,
            "size": [rnd(x) for x in size], "brushes": int(len(b)), "props": sum(e.cls.startswith("prop_") for e in sk),
            "models_top": top(C(short(e.model) for e in sk if e.model.endswith(".mdl")), 10),
            "materials_top": top(mats, 6, short=True)}


def materials(m):
    vis = [f for f in range(len(m.f_mat)) if m.play_brush(m.f_brush[f]) and not m.mat(f).startswith("tools/")]
    plain = [f for f in vis if m.f_disp[f] < 0]
    area = collections.defaultdict(float)
    for f in vis:
        area[m.mat(f)] += m.f_area[f]
    folders = collections.defaultdict(float)
    for k, a in area.items():
        folders[k.split("/")[0]] += a
    allv = m.f_cen[vis] if vis else np.zeros((1, 3))
    det = [f for f in plain if m.b_cls[m.f_brush[f]] == "func_detail"]
    up = [f for f in vis if m.f_n[f][2] > 0.7]
    return {"materials_top": top(C(m.mat(f) for f in plain), 25, short=True),
            "materials_area_top": [[k.split("/")[-1], rnd(a / 1e4)] for k, a in sorted(area.items(), key=lambda kv: -kv[1])[:15]],
            "material_folders_by_area": shares(C({k: v for k, v in folders.items()}), 3, 10),
            "material_count": len(area),
            "visible_faces": len(vis), "detail_share_of_faces": round(len(det) / max(1, len(plain)), 2),
            "disp_share_of_floor_area": round(sum(m.f_area[f] for f in up if m.f_disp[f] >= 0) / max(1.0, sum(m.f_area[f] for f in up)), 2),
            "extent": [rnd(x) for x in list(allv.min(axis=0)) + list(allv.max(axis=0))]}


def sound(play):
    sc = [(e.kv.get("soundscape", ""), float(e.kv.get("radius", "0") or 0)) for e in play if e.cls.startswith("env_soundscape")]
    amb = [e for e in play if e.cls == "ambient_generic"]
    return {"soundscapes_top": top(C(s for s, _ in sc), 20), "soundscape_radius": dist([r for _, r in sc], 64, 8),
            "ambient_top": top(C(e.kv.get("message", "").lower() for e in amb), 12),
            "ambient_flags": dict(C(int(e.kv.get("spawnflags", "0") or 0) for e in amb).most_common(6))}


def lights(m, play):
    L = [e for e in play if e.cls in ("light", "light_spot")]
    vals = [(e.cls, light_value(e.kv.get("_light"))) for e in L]
    env = [e for e in play if e.cls == "light_environment"]
    fog = [e for e in play if e.cls == "env_fog_controller"]
    out = {"light_brightness": {k: dist([v[3] for c, v in vals if c == k], 25, 10) for k in ("light", "light_spot")},
           "light_tones": dict(C(tone(v) for _, v in vals)),
           "light_colours_top": top(C(" ".join(str(int(round(x / 16) * 16)) for x in v[:3]) for _, v in vals), 6),
           "sun": [{k: e.kv.get(k) for k in ("_light", "_ambient", "pitch", "angles")} for e in env][:2],
           "fog": [{k: e.kv.get(k) for k in ("fogcolor", "fogstart", "fogend", "farz", "fogenable")} for e in fog][:2],
           "sky": m.world.get("skyname"),
           "spotlights_top": top(C((e.kv.get("rendercolor", ""), e.kv.get("spotlightlength", ""), e.kv.get("spotlightwidth", ""))
                                   for e in play if e.cls == "point_spotlight"), 5)}
    out["spotlights_top"] = [[" / ".join(k), n] for k, n in out["spotlights_top"]]
    return out


def ropes(play):
    R = {}
    for e in play:
        if e.cls in ("keyframe_rope", "move_rope") and e.origin is not None:
            R[e.name] = (e.origin, e.kv.get("nextkey", ""), float(e.kv.get("slack", "0") or 0), float(e.kv.get("width", "0") or 0))
    spans = [float(np.linalg.norm(o - R[n][0])) for o, n, _, _ in R.values() if n and n in R]
    return {"spans": dist(spans, 32, 10), "slack": med([s for _, _, s, _ in R.values()]), "width": med([w for *_, w in R.values()])}


def spacing(play):
    by = collections.defaultdict(list)
    for e in play:
        mdl = short(e.model)
        if e.origin is not None and e.cls.startswith("prop_") and re.search(SPACED, mdl):
            by[mdl].append(e.origin)
    out = {}
    for mdl, ps in sorted(by.items(), key=lambda kv: -len(kv[1])):
        if len(ps) < 3:
            continue
        A = np.array(ps)
        d = np.linalg.norm(A[:, None, :2] - A[None, :, :2], axis=2)
        np.fill_diagonal(d, 1e9)
        d[np.abs(A[:, None, 2] - A[None, :, 2]) > 96] = 1e9
        nn = d.min(axis=1)
        nn = nn[nn < 3000]
        if len(nn):
            out[mdl] = [len(ps), rnd(np.median(nn)), rnd(nn.min()), rnd(nn.max())]
        if len(out) >= 14:
            break
    return out
