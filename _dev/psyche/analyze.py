"""Reads the server's minds logs (data/livingcity/minds/*.txt) and says what they show.

    python3 _dev/psyche/analyze.py PATH [PATH ...]

PATH is a log file, the minds folder, or a .zip of it (as the owner brings it back).
It prints: how long it ran, what the minds were told, what they would have done,
how the city's mood moved, what it cost the server, and anything that looks wrong.
"""
import collections, io, os, re, sys, zipfile

LINE = re.compile(r"^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d) city (\d\d:\d\d)  (\w+)  (.*)$")
KV = re.compile(r"(\w+)=([-\d.]+)")


def texts(paths):
    for p in paths:
        if os.path.isdir(p):
            for name in sorted(os.listdir(p)):
                if name.endswith(".txt"):
                    yield name, open(os.path.join(p, name), encoding="utf-8", errors="replace").read()
        elif p.endswith(".zip"):
            with zipfile.ZipFile(p) as z:
                for name in sorted(z.namelist()):
                    if name.endswith(".txt"):
                        yield name, io.TextIOWrapper(z.open(name), encoding="utf-8", errors="replace").read()
        else:
            yield os.path.basename(p), open(p, encoding="utf-8", errors="replace").read()


def main(paths):
    kinds = collections.Counter()
    would = collections.Counter()
    breakers = collections.Counter()
    hurtBy = collections.Counter()
    hurtWho = collections.Counter()
    snaps, files, first, last = [], [], None, None
    counts_last = {}
    examples = []
    for name, text in texts(paths):
        files.append(name)
        for raw in text.splitlines():
            m = LINE.match(raw)
            if not m:
                continue
            when, city, kind, rest = m.groups()
            first = first or when
            last = when
            kinds[kind] += 1
            if kind == "WOULD":
                who, _, what = rest.partition(": ")
                b = what.split(" ")[0]
                would[b] += 1
                breakers[who.replace(" (sympathizer)", "")] += 1
                if len(examples) < 12 or b in ("inform", "leak", "brutal") and len(examples) < 20:
                    examples.append(f"{when[5:16]} (city {city})  {rest[:260]}")
            elif kind == "HURT":
                mm = re.match(r"(.+?) (?:hurt|attacked) by (.+)$", rest)
                if mm:
                    hurtWho[mm.group(1)] += 1
                    hurtBy[mm.group(2)] += 1
            elif kind == "SNAP":
                if rest.startswith("unrest="):
                    d = {k: float(v) for k, v in KV.findall(rest)}
                    d["when"] = when
                    snaps.append(d)
                elif rest.startswith("counts "):
                    counts_last = dict(KV.findall(rest))
    if not files:
        print("no logs found")
        return
    print(f"logs: {len(files)} file(s), {first} to {last}")
    print("lines by kind:", ", ".join(f"{k} {v}" for k, v in kinds.most_common()))
    if counts_last:
        print("last counts seen (since that map started):", ", ".join(f"{k} {v}" for k, v in sorted(counts_last.items())))
    print("\nwhat they would have done:", ", ".join(f"{k} {v}" for k, v in would.most_common()) or "nothing yet")
    if breakers:
        print("who broke most:", ", ".join(f"{k} ({v})" for k, v in breakers.most_common(8)))
    if hurtBy:
        print("hurt most by:", ", ".join(f"{k} ({v})" for k, v in hurtBy.most_common(8)))
        print("hurt most:", ", ".join(f"{k} ({v})" for k, v in hurtWho.most_common(8)))
    if snaps:
        print("\nthe city over time (one snapshot every 10 minutes; sampled):")
        print("  when              unrest stress food  rest  company on_streets/minds  avg_us  max_us")
        step = max(1, len(snaps) // 24)
        for d in snaps[::step] + ([snaps[-1]] if (len(snaps) - 1) % step else []):
            print(f"  {d['when'][5:16]}   {d.get('unrest', 0):5.2f}  {d.get('stress', 0):5.1f}  {d.get('food', 0):4.2f}  {d.get('rest', 0):4.2f}"
                  f"  {d.get('company', 0):4.2f}    {int(d.get('on_streets', 0)):3d}/{int(d.get('minds', 0)):3d}"
                  f"      {d.get('avg_us', 0):6.1f}  {d.get('max_us', 0):7.1f}")
        avg = max(d.get("avg_us", 0) for d in snaps)
        worst = max(d.get("max_us", 0) for d in snaps)
        print(f"\ncost: average step up to {avg:.1f} us (about {avg / 0.5 / 1000:.4f} ms of server time a second), worst single step {worst:.0f} us")
    if examples:
        print("\nsome of what they would have done:")
        for e in examples:
            print("  " + e)
    # what looks wrong
    flags = []
    if not snaps:
        flags.append("no snapshots: it may not have run 10 minutes, or lc_minds is 0")
    else:
        if max(d.get("avg_us", 0) for d in snaps) > 50:
            flags.append("average step over 50 us: slower than expected")
        if max(d.get("max_us", 0) for d in snaps) > 5000:
            flags.append("a step took over 5 ms")
        if len(snaps) > 6 and sum(d.get("food", 1) for d in snaps[-6:]) / 6 < 0.3:
            flags.append("food stays low: are citizens being served (fed count)? the ration hook may not be reaching it")
        if len(snaps) > 6 and sum(d.get("unrest", 0) for d in snaps[-6:]) / 6 > 0.8:
            flags.append("unrest stays near the top: tuning needed before anything acts on it")
        if all(d.get("on_streets", 0) == 0 for d in snaps):
            flags.append("nobody ever on the streets: the minds may not be finding the roster's NPCs")
    if kinds.get("WOULD", 0) == 0 and len(snaps) > 12:
        flags.append("two hours and nobody would have broken: maybe too gentle")
    print("\nlooks wrong:" if flags else "\nnothing looks wrong")
    for f in flags:
        print("  - " + f)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    main(sys.argv[1:])
