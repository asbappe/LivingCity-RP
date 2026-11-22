#!/usr/bin/env python3
"""
Living City: the keep, park or cut table (TODO.md, "Simpler and better", idea 5: "One page listing every feature in
docs/features/ with its code size, its settings, its unticked playtest items and whether the play study shows the
owner using it. The owner marks each one. 'Park' is one switch off, nothing deleted.")

    python3 _dev/feature_table.py      writes docs/dev/keep-park-cut.md (regenerate it; never hand-edit)

Per feature: the code files its page names (and their size), the settings its page names that the code creates, and
the unticked lines of the playtest card and its backlog that name one of its files, settings or its page. The play
study's recordings are on the owner's server, not here: that column is for the owner.
"""
import os, re, glob

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GM = os.path.join(ROOT, "gamemodes", "livingcity")

def main():
    lua = {}
    for p in glob.glob(os.path.join(GM, "**", "*.lua"), recursive=True):
        lua.setdefault(os.path.basename(p), p)
    code = "\n".join(open(p, encoding="utf-8", errors="replace").read() for p in lua.values())
    convars = set(re.findall(r'CreateConVar\(\s*"(lc_[a-z0-9_]+)"', code)) | set(re.findall(r'CreateClientConVar\(\s*"(lc_[a-z0-9_]+)"', code))
    play = []
    for f in ("PLAYTEST.md", "PLAYTEST_ARCHIVE.md"):
        p = os.path.join(ROOT, f)
        if os.path.exists(p):
            play += [l for l in open(p, encoding="utf-8").read().split("\n") if l.lstrip().startswith("- [ ]")]
    rows = []
    for doc in sorted(glob.glob(os.path.join(ROOT, "docs", "features", "*.md"))):
        s = open(doc, encoding="utf-8").read()
        m = re.search(r"^#\s+(.+)$", s, re.M)
        title = re.sub(r"\s*\(`[^)]*`\)\s*$", "", m.group(1)).strip() if m else os.path.basename(doc)
        files = sorted(set(f for f in re.findall(r"([a-z0-9_]+\.lua)", s) if f in lua))
        size = sum(os.path.getsize(lua[f]) for f in files)
        sets = sorted(set(re.findall(r"\b(lc_[a-z0-9_]+)\b", s)) & convars)
        stem = os.path.basename(doc)
        keys = [f for f in files] + sets + [stem]
        items = [l for l in play if any(k in l for k in keys)]
        rows.append((title, stem, files, size, sets, len(items)))
    out = ["# Keep, park or cut: every feature, for the owner to mark", "",
           "Made by `python3 _dev/feature_table.py` (TODO.md, \"Simpler and better\", idea 5). **Mark the last column** keep, park "
           "(one switch off, nothing deleted) or cut; nothing changes until you have. Code: the files the feature's page names and "
           "their size (a file shared by several features counts for each). Settings: those its page names. Playtest: unticked "
           "lines of `PLAYTEST.md` and its backlog naming its files, settings or page. The play study's recordings are on your "
           "server, so whether you use it is yours to fill in.", "",
           f"{len(rows)} features, {len(convars)} settings in the code.", "",
           "| Feature | Page | Code | KB | Settings | Playtest | Play study | Keep / park / cut |",
           "|---|---|---|---:|---:|---:|---|---|"]
    for title, stem, files, size, sets, n in sorted(rows, key=lambda r: -r[3]):
        shown = ", ".join("`" + f + "`" for f in files[:3]) + (f" +{len(files) - 3}" if len(files) > 3 else "")
        out.append(f"| {title.replace('|', '/')} | [{stem}](../features/{stem}) | {shown or 'none named'} | {size // 1024} | {len(sets)} | {n} |  |  |")
    path = os.path.join(ROOT, "docs", "dev", "keep-park-cut.md")
    open(path, "w").write("\n".join(out) + "\n")
    print(f"wrote {os.path.relpath(path, ROOT)}: {len(rows)} features")

if __name__ == "__main__":
    main()
