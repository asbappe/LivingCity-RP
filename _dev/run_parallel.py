#!/usr/bin/env python3
"""Run the whole of _dev/tests.lua across the CPU cores, and merge the results.

    python3 _dev/run_parallel.py                 the full suite, one worker per core
    python3 _dev/run_parallel.py --workers 3     fewer workers (the box is shared)
    python3 _dev/run_parallel.py --dry-run       show the shards, don't run
    python3 _dev/run_parallel.py --save-times    also keep this run's timings in _dev/test_times.json

It gives the same answer as `cd _dev && python3 run_tests.py tests.lua` (the reference, ~40
minutes in one process), in a fraction of the time: the last line is the same
"N passed, M failed", the core snapshot check runs once and writes _dev/core_snapshot.new.txt
exactly as run_tests.py does, and every FAIL line is printed with its section.

How it works. tests.lua is cut into ATOMS, in the order it runs: each top-level section, each
top-level unit, and each stretch of a wrapper unit's own lines (the "function XTests()" units
nest inside each other; their own lines run before and after the units inside them). Atoms in
a row make a SHARD, balanced by the time each atom took in a recorded run (_dev/test_times.json,
written by --save-times; an atom not in it is weighed by its length). Each shard is a masked copy of tests.lua with the same line numbers, built the way
run_section.py builds one (it uses run_section.py's reader): the prelude, the _setcvar lines
before the shard, the shard's atoms, the "function W() ... end W()" lines of every wrapper they
sit in, the locals they borrow from earlier (--borrow-all style: built by real code too), and
the "Stop" section. Each shard runs in its own `python3 run_tests.py` process.

Results are counted from markers put in front of each atom, so nothing is counted twice: the
prelude once (from the first shard), each atom once, and "Stop" passes only where it passes in
every shard. A run of atoms that cannot run apart from each other is listed in KEEP_TOGETHER:
no shard is cut inside it.
"""
import argparse, json, os, re, shutil, subprocess, sys, tempfile, time
from concurrent.futures import ThreadPoolExecutor, as_completed

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import run_section as rs  # noqa: E402

SEED_TIMES = os.path.join(HERE, "test_times.json")        # committed: timings from a full run
OUTROOT = "/tmp/livingcity_parallel"
OVERHEAD = 8.0          # seconds a shard spends loading the gamemode and running the prelude
MARK = "_LCMARK"
# Shards, whatever the CPU count: the same cut on every machine gives the same results. Small
# shards are also quicker overall: tests slow down as a run piles up players and NPCs (the reason
# the serial run takes ~40 minutes while its atoms, run in short shards, add up to a few).
SHARDS = 16

# Atoms (by name, as --dry-run prints them) that must be in the same shard as the atom just
# before them, because they rely on state it leaves behind. Each entry: (first, last) atom
# names; no shard boundary falls between the atom before `first` and `last`.
KEEP_TOGETHER = [
]

# Lines that change the whole run for everything after them (the gamemode itself is loaded by a
# test, in CityFixTests). A shard that starts after one of these runs it too, in its place (with
# the "function W() ... end W()" lines of the unit it sits in). Each entry: (regex of the first
# line, regex of the last line or None for one line).
SETUP = [
    (r"^local oldGM = GAMEMODE\s*$", r"^GAMEMODE = GMt\s*$"),     # load gamemode/shared.lua and init.lua
    (r"^GM = nil\s*$", None),
    (r"^GAMEMODE = oldGM\s*$", None),
]


class Atom:
    def __init__(self, idx, lines, owner, name):
        self.idx, self.lines, self.owner, self.name = idx, lines, owner, name
        self.sections = []
        self.weight = None

    @property
    def start(self):
        return self.lines[0]


def wrapper_end_line(t, u):
    e = u["end"] - 1
    while e > u["start"] and not t.lines[e - 1].strip():
        e -= 1
    return e


def find_stop(t):
    tops = [s for s in t.sections if not s["unit"]]
    if not tops or tops[-1]["name"] != "Stop":
        sys.exit("tests.lua no longer ends with a top-level section(\"Stop\"): fix run_parallel.py")
    return tops[-1]["line"]


def build_atoms(t, stop_line):
    """The lines from the end of the prelude to the Stop section, cut into atoms in run order."""
    wrappers = [u for u in t.units if u.get("wrapper")]
    others = [u for u in t.units if not u.get("wrapper")]

    def owner(k):
        best = None
        for u in wrappers:
            if u["start"] <= k <= u["end"] and (best is None or u["end"] - u["start"] < best["end"] - best["start"]):
                best = u
        return best["name"] if best else None

    owners = [None] * (t.n + 2)
    for k in range(t.prelude_end + 1, stop_line):
        owners[k] = owner(k)
    main_unit_starts = {u["start"] for u in others if owners[u["start"]] is None}
    top_sections = {s["line"] for s in t.sections if not s["unit"]}
    pieces, cur = [], []
    for k in range(t.prelude_end + 1, stop_line):
        cut = bool(cur) and (owners[k] != owners[cur[-1]] or
                             (owners[k] is None and (k in top_sections or k in main_unit_starts)))
        if cut:
            pieces.append(cur)
            cur = []
        cur.append(k)
    if cur:
        pieces.append(cur)
    # a piece holding nothing but section(...) lines and blanks goes with the piece after it
    merged, carry = [], []
    for p in pieces:
        body = [t.clean[k - 1].strip() for k in p]
        if all(not b or re.match(r"^section\(\s*\"\"\s*\)\s*;?$", b) for b in body) and p[-1] < stop_line - 1:
            carry += p
            continue
        merged.append((carry + p, p[0]))
        carry = []
    if carry:
        merged.append((carry, carry[0]))
    atoms, seen = [], {}
    for p, first in merged:
        own = owners[first]
        if own:
            base = "UNIT " + own
        else:
            u = next((u for u in others if u["start"] in p), None)
            secs = [s for s in t.sections if s["line"] in p and not s["unit"]]
            if secs:
                base = "TOP " + secs[0]["name"]
            elif u:
                base = "UNIT " + u["name"]
            else:
                before = [s for s in t.sections if s["line"] < p[0] and not s["unit"]]
                base = "TOP " + (before[-1]["name"] if before else "start")
        seen[base] = seen.get(base, 0) + 1
        name = base if seen[base] == 1 else "%s #%d" % (base, seen[base])
        a = Atom(len(atoms), p, own, name)
        a.sections = [s["name"] for s in t.sections if s["line"] in set(p)]
        atoms.append(a)
    return atoms


def load_times():
    """The committed timings only, so the shards stay the same from run to run (a test that leans on
    what ran before it then gives the same answer each time)."""
    try:
        with open(SEED_TIMES) as f:
            return json.load(f)
    except Exception:
        return {}


def weigh(atoms, times):
    known = [(times[a.name], len(a.lines)) for a in atoms if a.name in times]
    per_line = (sum(x for x, _ in known) / max(1, sum(n for _, n in known))) if known else 0.15
    for a in atoms:
        a.weight = times.get(a.name, per_line * len(a.lines))
        a.estimated = a.name not in times


def partition(atoms, k, overhead):
    """Cut the atoms, in order, into about k runs."""
    names = [a.name for a in atoms]
    nocut = set()                                  # no cut just before these indices
    for first, last in KEEP_TOGETHER:
        if first not in names or last not in names:
            print("note: KEEP_TOGETHER names an atom that no longer exists: %r..%r" % (first, last))
            continue
        i, j = names.index(first), names.index(last)
        nocut.update(range(max(1, i), j + 1))
    w = [a.weight for a in atoms]

    def greedy(cap):
        groups, cur, load = [], [], overhead
        for i, x in enumerate(w):
            if cur and load + x > cap and i not in nocut:
                groups.append(cur)
                cur, load = [], overhead
            cur.append(i)
            load += x
        groups.append(cur)
        return groups

    # about k runs of about equal weight (an atom heavier than that is a run by itself): short runs
    # rather than few, since a run gets slower the longer it goes
    cap = sum(w) / k + overhead
    return [[atoms[i] for i in g] for g in greedy(cap)]


def build_shard(t, shard, stop_line, path):
    """Write the masked copy for one shard; -> (borrowed names)."""
    pre = t.prelude_end
    start = shard[0].start
    last = rs.last_code_line(t)
    keep = set(range(1, pre + 1))
    for k in range(pre + 1, start):
        if t.depth[k] == 0 and re.match(r"^_setcvar\(.*\)\s*(--.*)?$", t.lines[k - 1]):
            keep.add(k)
    anchors = []                                   # lines whose wrappers must be kept
    for first, last_re in SETUP:
        for k in range(pre + 1, start):
            if re.match(first, t.lines[k - 1]):
                e = k
                if last_re:
                    e = next((j for j in range(k, start) if re.match(last_re, t.lines[j - 1])), None)
                    if e is None:
                        continue
                keep.update(range(k, e + 1))
                anchors += [k, e]
    for a in shard:
        keep.update(a.lines)
        anchors += [a.lines[0], a.lines[-1]]
    # the wrapper skeleton: every wrapper a kept line sits in keeps its function, end and call lines
    wrappers = [u for u in t.units if u.get("wrapper")]
    for u in wrappers:
        if any(u["start"] <= k <= u["end"] for k in anchors):
            keep.update((u["start"], wrapper_end_line(t, u), u["end"]))
    # borrowed locals (built by real code too, as run_section.py --borrow-all)
    borrowed, seen = [], set()
    for a in shard:
        visible = set(t.wrapper_chain(a.lines[0])) | set(t.wrapper_chain(a.lines[-1]))
        todo = [(n, a.start) for n in t.used_names(a.lines)]
        while todo:
            name, before = todo.pop()
            cands = [d for d in t.defs.get(name, []) if pre < d[0] < before and (d[3] is None or d[3] in visible)]
            if not cands:
                continue
            line, e, _, _ = cands[-1]
            if line >= start or (name, line) in seen:   # in the shard itself, or borrowed already
                continue
            seen.add((name, line))
            keep.update(range(line, e + 1))
            borrowed.append((line, name))
            todo.extend((n, line) for n in t.used_names(range(line, e + 1)))
    keep.update(range(stop_line, last + 1))
    out = [""] * t.n
    for k in keep:
        out[k - 1] = t.lines[k - 1]
    if not t.lines[last - 1].startswith("return results.pass"):
        sys.exit("tests.lua no longer ends with 'return results.pass, ...': fix run_parallel.py")
    sec = next((k for k in range(1, pre + 1) if t.lines[k - 1].startswith("local function section(")), None)
    if sec is None:
        sys.exit("tests.lua has no 'local function section(' in its prelude: fix run_parallel.py")
    out[sec - 1] += (" function %s(s) results.lines[#results.lines + 1] = \"@@\" .. s .. \" \" .. "
                     "string.format(\"%%.3f\", os.clock()) end" % MARK)

    def mark(k, text):
        line = out[k - 1]
        out[k - 1] = '%s("%s")%s%s' % (MARK, text, "" if line.lstrip().startswith(";") else "; ", line)
    for line, _ in borrowed:
        mark(line, "S")
    for a in shard:
        mark(a.start, "A %d" % a.idx)
    mark(stop_line, "STOP")
    with open(path, "w") as f:
        f.write("\n".join(out))
    return sorted(set(n for _, n in borrowed))


def parse(text):
    """-> dict: regions {key: {'pass','fail','lines','clock'}}, done (bool), summary"""
    regions, order, cur, section = {}, [], "prelude", None
    regions[cur] = {"pass": 0, "fail": 0, "lines": [], "fails": [], "clock": None, "results": []}
    order.append(cur)
    done = re.search(r"^(\d+) passed, (\d+) failed\s*$", text, re.M)
    for line in text.split("\n"):
        if line.startswith("@@"):
            parts = line[2:].split()
            key = "A %s" % parts[1] if parts[0] == "A" else parts[0]
            if key == "S":
                cur = "S"
                regions.setdefault("S", {"pass": 0, "fail": 0, "lines": [], "fails": [], "clock": None, "results": []})
                continue
            cur = key
            regions[cur] = {"pass": 0, "fail": 0, "lines": [], "fails": [], "clock": float(parts[-1]), "results": []}
            order.append(cur)
            continue
        r = regions[cur]
        if line.startswith("== "):
            section = line[3:]
        if line.startswith("  PASS"):
            r["pass"] += 1
            r["results"].append(True)
        elif line.startswith("  FAIL"):
            r["fail"] += 1
            r["results"].append(False)
            r["fails"].append((section, line.strip()))
        if line.startswith(("== ", "  PASS", "  FAIL")):
            r["lines"].append(line)
    return regions, order, bool(done)


SHARD_ENV = dict(os.environ, LC_HOUSE_RULES_DONE="1")   # (the house rules are checked once, here, not in every shard)


def house_rules_problems():
    import house_rules
    if not os.path.exists(house_rules.BASE):
        return []
    return house_rules.check(house_rules.count()[0], json.load(open(house_rules.BASE)))


def main():
    ap = argparse.ArgumentParser(description="Run _dev/tests.lua across the CPU cores and merge the results.")
    ap.add_argument("--workers", type=int, default=os.cpu_count() or 2, help="processes at once (default: the CPU count)")
    ap.add_argument("--shards", type=int, default=SHARDS,
                    help="how many shards (default %d, whatever the CPU count, so every machine cuts them the same)" % SHARDS)
    ap.add_argument("--dry-run", action="store_true", help="show the atoms and shards, don't run")
    ap.add_argument("--save-times", action="store_true", help="also write this run's timings to _dev/test_times.json")
    ap.add_argument("--timeout", type=int, default=3600, help="seconds before a shard is given up (default 3600)")
    ap.add_argument("--atoms", metavar="I-J", help="run only atoms I to J (numbers from --dry-run) in one shard, to look into one")
    ap.add_argument("tests", nargs="?", default=os.path.join(HERE, "tests.lua"), help=argparse.SUPPRESS)
    args = ap.parse_args()
    t0 = time.time()

    t = rs.Tests(args.tests)
    if t.final_depth != 0:
        sys.exit("block depth does not return to 0 (%d): run_section.py cannot read tests.lua" % t.final_depth)
    whole = rs.whole_file_error(t)                 # (the shards load when the whole file no longer does)
    stop_line = find_stop(t)
    atoms = build_atoms(t, stop_line)
    weigh(atoms, load_times())
    k = max(1, args.shards)
    if args.atoms:
        i, _, j = args.atoms.partition("-")
        shards = [atoms[int(i):int(j or i) + 1]]
    else:
        shards = [s for s in partition(atoms, k, OVERHEAD) if s]

    os.makedirs(OUTROOT, exist_ok=True)
    for d in os.listdir(OUTROOT):                  # runs older than a day go
        p = os.path.join(OUTROOT, d)
        if d.startswith("run_") and os.path.isdir(p) and time.time() - os.path.getmtime(p) > 86400:
            shutil.rmtree(p, ignore_errors=True)
    run_dir = tempfile.mkdtemp(prefix="run_", dir=OUTROOT)
    plan = []
    counter = [0]

    def make_job(atom_list, note=""):
        i = counter[0]
        counter[0] += 1
        path = os.path.join(run_dir, "shard_%02d.lua" % i)
        borrowed = build_shard(t, atom_list, stop_line, path)
        job = {"i": i, "atoms": atom_list, "lua": path, "out": os.path.join(run_dir, "shard_%02d.out.txt" % i),
               "weight": OVERHEAD + sum(a.weight for a in atom_list), "borrowed": borrowed, "note": note}
        plan.append(job)
        return job

    first = [make_job(s) for s in shards]
    est = sum(1 for a in atoms if a.estimated)
    print("%d atoms in %d shards on %d workers%s; files in %s"
          % (len(atoms), len(first), args.workers,
             (" (%d atoms timed by length: no timings yet)" % est) if est else "", run_dir), flush=True)
    if args.dry_run:
        for p in first:
            print("shard %02d  ~%4.0fs  lines %d-%d  %s .. %s  (%d atoms; borrows %d)"
                  % (p["i"], p["weight"], p["atoms"][0].start, p["atoms"][-1].lines[-1],
                     p["atoms"][0].name[:40], p["atoms"][-1].name[:40], len(p["atoms"]), len(p["borrowed"])))
        print("atoms:")
        for a in atoms:
            print("  %3d  %5d-%-5d %6.1fs%s  %s" % (a.idx, a.start, a.lines[-1], a.weight, "~" if a.estimated else " ", a.name[:90]))
        return

    def run(p):
        s0 = time.time()
        try:
            with open(p["out"], "w") as fh:
                r = subprocess.run([sys.executable, "run_tests.py", p["lua"]], cwd=HERE, stdout=fh, env=SHARD_ENV,
                                   stderr=subprocess.STDOUT, timeout=args.timeout)
            p["code"] = r.returncode
        except subprocess.TimeoutExpired:
            p["code"] = 124
        p["secs"] = time.time() - s0
        return p

    def crashed_atom(p, text):
        """The atom of this shard a Lua error came from (its traceback's lines), or None."""
        by_line = {k: a for a in p["atoms"] for k in a.lines}
        for m in re.finditer(r'tests\.lua"\]:(\d+):', text):
            a = by_line.get(int(m.group(1)))
            if a is not None:
                return a
        return None

    # run; a shard that crashes (a Lua error ends its process, and its report with it) counts the
    # atom that crashed as one failure, and the atoms before and after it are run again without it
    done_jobs, crashes, problems = [], [], []
    with ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
        pending = {pool.submit(run, p) for p in sorted(first, key=lambda p: -p["weight"])}
        while pending:
            fut = next(iter(as_completed(pending)))
            pending.discard(fut)
            p = fut.result()
            text = open(p["out"]).read()
            for bad in ("GMOD LUA CHECK FAILED", "MANIFEST MISMATCH", "LOAD FAILED"):
                if bad in text:
                    print(text[text.index(bad):][:2000])
                    print("\n0 passed, 1 failed")
                    os._exit(1)
            p["text"] = text
            ok_run = re.search(r"^(\d+) passed, (\d+) failed\s*$", text, re.M) is not None
            print("  shard %02d %s in %4.0fs%s" % (p["i"], "done" if ok_run else "CRASHED", p["secs"],
                                                 (" (" + p["note"] + ")") if p["note"] else ""), flush=True)
            if ok_run:
                done_jobs.append(p)
                continue
            errs = [l.strip() for l in text.split("\n") if "LuaError" in l]
            why = errs[0][:300] if errs else ("timed out" if p["code"] == 124 else "no result line")
            bad_atom = crashed_atom(p, text)
            if bad_atom is None:
                problems.append("shard %02d (%s .. %s) crashed and the atom could not be found: %s; output: %s"
                                % (p["i"], p["atoms"][0].name, p["atoms"][-1].name, why, p["out"]))
                crashes.append((None, p))
                continue
            crashes.append((bad_atom, p))
            problems.append("%s CRASHED (shard %02d): %s; output: %s" % (bad_atom.name, p["i"], why, p["out"]))
            k = p["atoms"].index(bad_atom)
            for part, note in ((p["atoms"][:k], "rerun before a crash"), (p["atoms"][k + 1:], "rerun after a crash")):
                if part:
                    pending.add(pool.submit(run, make_job(part, note)))

    # merge
    passed = failed = 0
    fails, report = [], []
    stop_results = None
    stop_lines = []
    stop_fails = []
    times = {}
    atom_regions = {}
    core_msg = None
    prelude = None
    for p in sorted(done_jobs, key=lambda p: p["atoms"][0].idx):
        text = p["text"]
        regions, order, _ = parse(text)
        if "The core has changed" in text:
            core_msg = text[text.index("The core has changed"):].split("\n")[0]
        r = regions["prelude"]
        if prelude is None:                        # every shard runs the same prelude: counted once
            prelude = r
            passed += r["pass"]
            failed += r["fail"]
            fails += [("prelude", s, l) for s, l in r["fails"]]
            report += r["lines"]
        elif (r["pass"], r["fail"]) != (prelude["pass"], prelude["fail"]):
            problems.append("shard %02d: its prelude gave %d passed, %d failed (the first: %d, %d)"
                            % (p["i"], r["pass"], r["fail"], prelude["pass"], prelude["fail"]))
        if regions.get("S", {}).get("fail"):
            problems.append("shard %02d: %d FAIL in its borrowed lines (not counted): %s"
                            % (p["i"], regions["S"]["fail"], regions["S"]["fails"][0][1][:160]))
        clocks = [(key, regions[key]["clock"]) for key in order if regions[key]["clock"] is not None]
        for j, (key, c) in enumerate(clocks):
            if key.startswith("A "):
                atom_regions[int(key[2:])] = regions[key]
                if j + 1 < len(clocks):
                    times[atoms[int(key[2:])].name] = round(clocks[j + 1][1] - c, 2)
        st = regions.get("STOP")
        if st is None:
            problems.append("shard %02d never reached Stop" % p["i"])
            continue
        if stop_results is None:
            stop_results = list(st["results"])
            stop_lines = st["lines"]
        elif len(st["results"]) != len(stop_results):
            problems.append("shard %02d: Stop gave %d results, not %d" % (p["i"], len(st["results"]), len(stop_results)))
        else:
            stop_results = [x and y for x, y in zip(stop_results, st["results"])]
        stop_fails += [("Stop", s, "%s  (shard %02d)" % (l, p["i"])) for s, l in st["fails"]]
    run_atoms = [a for p in first for a in p["atoms"]]
    crashed = {a.idx for a, _ in crashes if a is not None}
    for a in run_atoms:
        r = atom_regions.get(a.idx)
        if r is None:
            continue
        passed += r["pass"]
        failed += r["fail"]
        fails += [(a.name, s, l) for s, l in r["fails"]]
        report += r["lines"]
    failed += len(crashes)                         # each crash: one failure
    missing = [a.name for a in run_atoms if a.idx not in atom_regions and a.idx not in crashed]
    if missing:
        problems.append("%d atoms gave no results: %s" % (len(missing), ", ".join(missing[:8])))
    if stop_results is not None:
        passed += sum(1 for x in stop_results if x)
        failed += sum(1 for x in stop_results if not x)
        report += stop_lines
        fails += stop_fails
    with open(os.path.join(run_dir, "report.txt"), "w") as f:
        f.write("\n".join(report) + "\n")

    # timings: this run's in its folder; with --save-times, also the committed ones the shards are cut by
    if times:
        with open(os.path.join(run_dir, "times.json"), "w") as f:
            json.dump(times, f, indent=0, sort_keys=True)
        if args.save_times:
            with open(SEED_TIMES, "w") as f:
                json.dump({a.name: times[a.name] for a in atoms if a.name in times}, f, indent=0, sort_keys=True)
                f.write("\n")

    print("merged report: %s" % os.path.join(run_dir, "report.txt"))
    print("wall %.0fs, %d shards run, %.0fs of shard time (longest shard %.0fs)"
          % (time.time() - t0, len(plan), sum(p.get("secs", 0) for p in plan), max(p.get("secs", 0) for p in plan)))
    for name, sec, line in fails:
        print("%s   [%s]" % (line[:300], sec or name))
    problems += ["house rules: " + x for x in house_rules_problems()]
    if whole:
        problems.append("tests.lua does not load whole, so run_tests.py cannot run it: %s (%s)" % (whole, rs.WHOLE_FIX))
    for msg in problems:
        print("PROBLEM: " + msg)
    if core_msg:
        print("\n" + core_msg)
    print(f"\n{passed} passed, {failed} failed")
    sys.exit(1 if failed or problems else 0)

if __name__ == "__main__":
    main()
