#!/usr/bin/env python3
"""
Living City: are the models and materials a VMF names real, and of the right kind?

    python3 map_assets.py lc_showroom_test.vmf            every model and material in it, against Valve's own sources
    python3 map_assets.py *.vmf --lists ~/somewhere       ...keeping the lists there (default: a folder "dl" beside this file)

A model that does not exist is a big red ERROR in the game; a prop_static whose model was not built to be
static is silently left out of the map by the compiler; a prop_physics without physics data deletes itself.
None of that can be seen without a compile, so this reads it from the models' build files instead:
github.com/Pinsplash/ValveQCs (the decompiled build file of every model) and github.com/Pinsplash/ValveVMTs
(every material). The first run fetches the two lists of file names (about 10 MB, no file contents), then one
small build file for each model it has not met before; what it learns is kept in asset_facts.json beside this
file, so later runs need no network for models already known.

Sounds are NOT checked (there is no list of them). Our own models (models/lc/kit/..., the Propper++ kit that
map_propkit.py writes into _dev/propkit/) are not Valve's: they exist only once the owner has compiled them in
Hammer++, so they are named as ours, with their sizes from the kit's kit.json, and only one the kit does not have fails.
"""

import argparse
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FACTS = os.path.join(HERE, "asset_facts.json")
GAMES = ("hl2", "episodic", "lostcoast", "ep2", "hl2mp")     # what Garry's Mod has by itself, and Episode Two last
# Half-Life 2's own materials that the owner's Garry's Mod does not have on disk all the same (their vbsp said "Failed
# to find material on disk", 22 November): the lists say hl2, the game does not. Add to it from any compile log.
NOT_IN_GMOD = {"nature/blendsandmud001a", "nature/blendrubbleash001a"}
REPOS = {"ValveQCs": "https://github.com/Pinsplash/ValveQCs", "ValveVMTs": "https://github.com/Pinsplash/ValveVMTs"}
KIT = os.path.normpath(os.path.join(HERE, "..", "propkit"))      # (our own models: map_propkit.py's Propper++ kit)
KIT_MODELS = "models/lc/kit/"
_kit = None


def kit_piece(model):
    """One of our own models (the Propper++ kit): its entry in the kit's kit.json ({} if the kit has no such piece), or
    None for any other model."""
    global _kit
    model = model.lower().replace("\\", "/")
    if not model.startswith(KIT_MODELS):
        return None
    if _kit is None:
        try:
            with open(os.path.join(KIT, "kit.json")) as f:
                _kit = json.load(f)["pieces"]
        except (OSError, ValueError, KeyError):
            _kit = {}
    name = model[len(KIT_MODELS):]
    return _kit.get(name[:-4] if name.endswith(".mdl") else name) or {}


def lists(folder, offline):
    out = {}
    for name, url in REPOS.items():
        repo, txt = os.path.join(folder, name), os.path.join(folder, name + ".txt")
        if not os.path.exists(txt):
            if offline:
                return None
            os.makedirs(folder, exist_ok=True)
            if not os.path.isdir(repo):
                print("fetching the list of %s (names only) ..." % name)
                r = subprocess.run(["git", "clone", "-q", "--depth", "1", "--filter=blob:none", "--no-checkout", url, repo], capture_output=True, text=True)
                if r.returncode:
                    print("  could not: " + r.stderr.strip()[-200:])
                    return None
            names = subprocess.run(["git", "-C", repo, "ls-tree", "-r", "HEAD", "--name-only"], capture_output=True, text=True).stdout
            with open(txt, "w") as f:
                f.write(names)
        index = {}
        for line in open(txt, encoding="utf-8", errors="replace"):
            p = line.strip().strip('"')
            parts = p.split("/")
            if len(parts) > 2 and parts[0] == "source":
                game = parts[1].split(" ")[0]
                index.setdefault("/".join(parts[2:]).lower(), {})[game] = p
        out[name] = (repo, index)
    return out


def read_vmf(path):
    """(models: {name: set of entity classes}, materials: set)"""
    models, materials = {}, set()
    cls = None
    kv = re.compile(r'^\s*"([^"]+)"\s+"([^"]*)"')
    for line in open(path, encoding="utf-8", errors="replace"):
        m = kv.match(line)
        if not m:
            continue
        k, v = m.group(1).lower(), m.group(2).strip().lower().replace("\\", "/")
        if k == "classname":
            cls = v
        elif k == "model" and v.endswith(".mdl"):
            models.setdefault(v, set()).add(cls)
        elif k in ("material", "texture", "ropematerial", "smokematerial") or (k == "model" and v.endswith((".vmt", ".spr"))):
            v = re.sub(r"\.(vmt|spr)$", "", v)
            if v.startswith("materials/"):      # (a sprite may name its material with the folder in front: the game reads both)
                v = v[len("materials/"):]
            if v and not v.isdigit():      # (a breakable's "material" is a number: what it breaks like)
                materials.add(v)
    return models, materials


def facts_of(model, qcs, known, offline):
    if model in known and (("bbox" in known[model] and ((known[model].get("v") == 2 and "ragdoll" in known[model]) or offline)) or known[model].get("game") is None):
        return known[model]      # (a note missing a key, as 172 once were, is read again when the lists are here)
    repo, index = qcs
    key = re.sub(r"^models/", "", model)[:-4] + ".qc"
    where = index.get(key, {})
    game = next((g for g in GAMES if g in where), None)
    if not game:
        fact = {"game": None, "elsewhere": sorted(where)}
    elif offline:
        return {"game": game, "unread": True}
    else:
        text = subprocess.run(["git", "-C", repo, "show", "HEAD:" + where[game]], capture_output=True, text=True, errors="replace").stdout.lower()
        if not text:
            return {"game": game, "unread": True}
        bb = re.search(r"\$bbox\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)", text)
        # A model with prop_data is a physics prop: the compiler DELETES it as a prop_static ("must be used on a dynamic
        # entity") unless its prop_data says allowstatic (the owner's compile of the town, 20 November: every table, shelf,
        # counter and board was gone). So "static" is: built with $staticprop AND not a physics prop.
        data = "prop_data" in text
        allow = bool(re.search(r'"?allowstatic"?\s+"?1', text))
        fact = {"game": game, "v": 2, "built_static": "$staticprop" in text, "static": "$staticprop" in text and (not data or allow), "prop_data": data,
                "physics": "prop_data" in text or "physics_prop" in text,
                "ragdoll": "$collisionjoints" in text, "collides": "$collisionmodel" in text or "$collisionjoints" in text,
                "bbox": [round(float(x), 1) for x in bb.groups()] if bb else None}      # (the model's own box: x forward, y left, z up, from its origin)
    known[model] = fact
    return fact


def save(known):
    """Keep what was learnt (with whatever another run learnt meanwhile)."""
    old = json.load(open(FACTS)) if os.path.exists(FACTS) else {}
    old.update(known)
    tmp = FACTS + ".%d.tmp" % os.getpid()
    with open(tmp, "w") as f:
        json.dump(old, f, indent=0, sort_keys=True)
    os.replace(tmp, FACTS)


_known, _lists = None, False


def size(model):
    """A model's own box (x1, y1, z1, x2, y2, z2 from its origin: x forward, y left, z up), or None if it is not known.
    Read from asset_facts.json; a model not met before is looked up if the lists are here (the folder "dl")."""
    global _known, _lists
    model = model.lower().replace("\\", "/")
    piece = kit_piece(model)
    if piece is not None:      # (ours: its box from the kit, x along the piece, y to its back, z up from its foot)
        return piece.get("box")
    if _known is None:
        _known = json.load(open(FACTS)) if os.path.exists(FACTS) else {}
    fact = _known.get(model)
    if (fact is None or (fact.get("game") and ("bbox" not in fact or fact.get("v") != 2))) and _lists is not None and not os.environ.get("LC_ASSETS_OFFLINE"):
        if _lists is False:
            _lists = lists(os.path.join(HERE, "dl"), True)       # (only if they are already here: a build never starts a download)
        if _lists:
            fact = facts_of(model, _lists["ValveQCs"], _known, False)
            save(_known)
    return (fact or {}).get("bbox")


def is_static(model):
    """Was this model built to be a prop_static? True, False, or None if it is not known."""
    if kit_piece(model) is not None:
        return True      # (the kit's models are made for prop_static, with no collision)
    size(model)
    fact = (_known or {}).get(model.lower().replace("\\", "/")) or {}
    if fact.get("v") != 2 and fact.get("physics"):
        return False        # (an older note that could not be read again: a physics prop is never trusted as a prop_static)
    return fact.get("static")


def is_physics_prop(model):
    """Does this model carry prop_data (a physics prop)? Standing still it must be a prop_dynamic_override, never a
    prop_static (the compiler deletes it) and never a plain prop_dynamic (the game removes or warns of it)."""
    if kit_piece(model) is not None:
        return False
    size(model)
    fact = (_known or {}).get(model.lower().replace("\\", "/")) or {}
    return bool(fact.get("prop_data", fact.get("physics")))


def main():
    ap = argparse.ArgumentParser(description="Check the models and materials a VMF names against Valve's sources.")
    ap.add_argument("vmf", nargs="+")
    ap.add_argument("--lists", default=os.path.join(HERE, "dl"))
    ap.add_argument("--offline", action="store_true", help="use only what is already here")
    ap.add_argument("--quiet", action="store_true", help="only what is wrong")
    args = ap.parse_args()
    known = json.load(open(FACTS)) if os.path.exists(FACTS) else {}
    got = lists(args.lists, args.offline)
    models, materials = {}, set()
    for path in args.vmf:
        ms, mats = read_vmf(path)
        for k, v in ms.items():
            models.setdefault(k, set()).update(v)
        materials |= mats
    problems, notes, ours = [], [], []
    for model in sorted(models):
        classes = models[model]
        piece = kit_piece(model)
        if piece is not None:
            name = model[len(KIT_MODELS):-4]
            if not piece or not os.path.exists(os.path.join(KIT, name + ".vmf")):
                problems.append("%s is not in the Propper++ kit (_dev/propkit/: run map_propkit.py)" % model)
            else:
                ours.append(name)
            continue
        if got:
            fact = facts_of(model, got["ValveQCs"], known, args.offline)
        else:
            fact = known.get(model)
            if fact is None:
                notes.append("%s: not checked (no lists here, and not met before)" % model)
                continue
        if fact.get("game") is None:
            problems.append("%s does not exist in Half-Life 2 or its episodes%s" % (model, " (only in: %s)" % ", ".join(fact["elsewhere"]) if fact.get("elsewhere") else ""))
            continue
        if fact.get("unread"):
            notes.append("%s: exists (%s), its kind not read" % (model, fact["game"]))
            continue
        if fact["game"] == "ep2":
            notes.append("%s is Episode Two's: players without it see an error" % model)
        if "prop_static" in classes and not fact["static"]:
            problems.append("%s is used as a prop_static but %s: the compiler deletes it (use prop_dynamic_override or prop_physics)"
                            % (model, "is a physics prop (it has prop_data)" if fact.get("prop_data") else "was not built to be one"))
        if "prop_dynamic" in classes and fact.get("prop_data"):
            problems.append("%s is used as a prop_dynamic but is a physics prop (it has prop_data): use prop_dynamic_override or prop_physics" % model)
        if ("prop_physics" in classes or "prop_physics_multiplayer" in classes) and not fact["physics"]:
            problems.append("%s is used as a prop_physics but has no physics data: it deletes itself (use prop_dynamic or prop_static)" % model)
        if "prop_ragdoll" in classes and not fact.get("ragdoll", True):
            problems.append("%s is used as a prop_ragdoll but has no joints" % model)
    if got:
        index = got["ValveVMTs"][1]
        for mat in sorted(materials):
            where = index.get(mat + ".vmt", {})
            game = next((g for g in GAMES if g in where), None)
            if mat in NOT_IN_GMOD:
                problems.append("the material %s is Half-Life 2's but not in the owner's Garry's Mod (their compile could not find it)" % mat)
            elif not game:
                problems.append("the material %s does not exist in Half-Life 2 or its episodes%s" % (mat, " (only in: %s)" % ", ".join(sorted(where)) if where else ""))
            elif game == "ep2":
                notes.append("the material %s is Episode Two's" % mat)
    else:
        notes.append("materials not checked (no lists here)")
    save(known)
    if ours:      # (said even with --quiet: the map shows error models until these are compiled)
        notes.append("%d of the models are ours, the Propper++ kit (_dev/propkit/: %s): they exist only once the owner has compiled "
                     "them in Hammer++ (models/lc/kit/), until then the game shows an error model there" % (len(ours), ", ".join(ours)))
        if args.quiet:
            print("  note: " + notes[-1])
    if not args.quiet:
        print("%d models, %d materials in %d file(s)" % (len(models), len(materials), len(args.vmf)))
        for n in notes:
            print("  note: " + n)
    for p in problems:
        print("  PROBLEM: " + p)
    print("ASSETS %s" % ("PASS" if not problems else "FAIL (%d)" % len(problems)))
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
