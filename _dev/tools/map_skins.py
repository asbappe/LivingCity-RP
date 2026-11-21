#!/usr/bin/env python3
"""
Living City: how many skins a model has (for the map tools, never the server).

Valve gives a model with several skins a mix of them (21 November, docs/dev/valve-prop-notes.md: 9% of props are not
skin 0; oil drums 45%, cargo containers 69%, wood crates 33%), so the modules pick a skin for a prop whose model has
more than one (map_modules.Mod.prop). The counts come from the models' build files in Valve's decompiled QCs, saved
in model_skins.json beside this file so a build never needs the download.

    python3 map_skins.py              rebuild model_skins.json from dl/ValveQCs (map_assets.py fetches it)
    python3 map_skins.py MODEL ...    print how many skins each model has
"""
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FILE = os.path.join(HERE, "model_skins.json")
GAMES = ("hl2", "episodic", "lostcoast", "ep2", "hl2mp")      # (what Garry's Mod has, as map_assets.GAMES; the first found wins)
_known = None


def count(model):
    """How many skins the model has (1 when it is not in the list: one skin, or not known)."""
    global _known
    if _known is None:
        try:
            _known = json.load(open(FILE))
        except (OSError, ValueError):
            _known = {}
    return int(_known.get(model.lower().replace("\\", "/"), 1))


def families(qc):
    """The number of skin families a QC's $texturegroup "skinfamilies" lists (1 if it has none)."""
    m = re.search(r'\$texturegroup\s+"?skinfamilies"?\s*\{', qc, re.I)
    if not m:
        return 1
    depth, n, i = 1, 0, m.end()
    while i < len(qc) and depth:
        c = qc[i]
        if c == "{":
            depth += 1
            if depth == 2:
                n += 1
        elif c == "}":
            depth -= 1
        i += 1
    return max(n, 1)


def rebuild():
    """Read every QC of GAMES. The QCs' clone keeps no files (blob:none), so fetch them in one go first:
    git -C dl/ValveQCs sparse-checkout set --no-cone '/source/hl2/**/*.qc' (and the other games), then checkout HEAD;
    a QC not checked out is read with git show, one at a time (slow)."""
    repo = os.path.join(HERE, "dl", "ValveQCs")
    names = subprocess.run(["git", "-C", repo, "ls-tree", "-r", "--name-only", "HEAD"], capture_output=True, text=True).stdout.split("\n")
    out = {}
    for game in reversed(GAMES):      # (the first game in GAMES is read last, so its count stands)
        for n in names:
            parts = n.split("/")
            if len(parts) < 3 or parts[1] != game or not n.endswith(".qc"):
                continue
            path = os.path.join(repo, n)
            if os.path.exists(path):
                qc = open(path, errors="replace").read()
            else:
                qc = subprocess.run(["git", "-C", repo, "show", "HEAD:" + n], capture_output=True, text=True, errors="replace").stdout
            mn = re.search(r'\$modelname\s+"([^"]+)"', qc, re.I)
            if not mn:
                continue
            model = "models/" + mn.group(1).lower().replace("\\", "/")
            if not model.endswith(".mdl"):
                model += ".mdl"
            k = families(qc)
            if k > 1:
                out[model] = k
            else:
                out.pop(model, None)
    json.dump(dict(sorted(out.items())), open(FILE, "w"), indent=0, sort_keys=True)
    print("%d models with more than one skin: %s" % (len(out), FILE))


if __name__ == "__main__":
    if len(sys.argv) > 1:
        for a in sys.argv[1:]:
            print(a, count(a))
    else:
        rebuild()
