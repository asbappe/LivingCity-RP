#!/usr/bin/env python3
"""Run one section (or one unit) of _dev/tests.lua, and print only the result.

    python3 _dev/run_section.py "Prison"             one top-level section
    python3 _dev/run_section.py "Radios"             a section inside a unit: runs the whole unit
    python3 _dev/run_section.py --unit UndergroundTests
    python3 _dev/run_section.py --list [text]        list sections and units (live, from tests.lua)
    python3 _dev/run_section.py --index              write _dev/tests_index.txt (the same list)

How it works. tests.lua is one long Lua chunk whose sections share local variables, so
a section cannot simply be cut out. This script writes a MASKED COPY: every line the run
does not need is blanked, so the copy has exactly the same line numbers as tests.lua
(an error at line 3120 of the copy is line 3120 of tests.lua). It keeps:

  1. the prelude (line 1 up to just before the first helper, newPlayer): the stub setup,
     the layout and the zones every later test builds on;
  2. the top-level _setcvar(...) lines between the prelude and the target;
  3. the target: a top-level section (up to the next section), or a whole unit (a
     "XTests()" wrapper function or ";(function() ... end)()" block, since a section
     inside one cannot be separated from it);
  4. helpers the target borrows from earlier in the file (a "local function" or a plain
     local such as FAR), found by reading the target's identifiers. A borrowed local that
     is built by running real code (a player, a quest) is NOT borrowed: it is listed as
     "needs state" with its line, because it depends on earlier sections having run.
     Add what it needs with --also A-B, or --from "earlier section", or --borrow-all.
  5. the last line (the return) and an error check.

The full output goes to a file under /tmp/livingcity_sections/; the screen gets only the
target's pass/fail count, its FAIL lines and the path of the output.
"""
import argparse, os, re, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
TESTS = os.path.join(HERE, "tests.lua")
INDEX = os.path.join(HERE, "tests_index.txt")
OUTDIR = "/tmp/livingcity_sections"
PRELUDE_BEFORE = r"^local function newPlayer\("   # the prelude ends on the line before this one
FALLBACK_PRELUDE = 437
# a plain "local x = ..." counts as safe to borrow when it only calls these
PURE_CALLS = ("Vector", "Angle", "Color", "math.", "string.", "table.", "tostring", "tonumber",
              "ipairs", "pairs", "select", "type")
KEYWORDS = set("and break do else elseif end false for function goto if in local nil not or repeat "
               "return then true until while continue".split())


def strip_lua(src):
    """The source with comments removed and strings blanked, keeping every newline."""
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith("--", i):
            m = re.match(r"--\[(=*)\[", src[i:i + 40])
            if m:
                end = src.find("]" + m.group(1) + "]", i)
                end = n if end < 0 else end + len(m.group(1)) + 2
                out.append("\n" * src.count("\n", i, end))
                i = end
            else:
                end = src.find("\n", i)
                i = n if end < 0 else end
            continue
        if c == "[":
            m = re.match(r"\[(=*)\[", src[i:i + 40])
            if m:
                end = src.find("]" + m.group(1) + "]", i)
                end = n if end < 0 else end + len(m.group(1)) + 2
                out.append('""' + "\n" * src.count("\n", i, end))
                i = end
                continue
        if c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                j += 2 if src[j] == "\\" else 1
            out.append('""' + "\n" * src.count("\n", i, j + 1))
            i = j + 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


TOKEN = re.compile(r"\b(function|if|do|repeat|end|until)\b|([(\[{])|([)\]}])")


class Tests:
    """tests.lua, read once: block depth per line, units, sections, main-chunk locals.

    Two kinds of unit. A "wrapper" is a global "function XTests()" ... "end" + "XTests()":
    tests.lua nests dozens of them inside each other, so their function/end lines are
    depth-neutral here, and a wrapper owns its own lines minus the wrappers inside it.
    The other kind is a "local function XTests()" or ";(function() ... end)()" block.
    """

    def __init__(self, path=TESTS):
        self.src = open(path).read()
        self.lines = self.src.split("\n")            # lines[k] is line k + 1
        self.n = len(self.lines)
        self.clean = strip_lua(self.src).split("\n")
        assert len(self.clean) == self.n, "strip_lua changed the line count"
        wrappers, neutral = self._wrappers()
        self.depth = [0] * (self.n + 2)              # depth[k] = block depth before line k (1-based)
        d = 0
        for k in range(1, self.n + 1):
            self.depth[k] = d
            if k in neutral:
                continue
            for m in TOKEN.finditer(self.clean[k - 1]):
                if m.group(1) in ("end", "until") or m.group(3):
                    d -= 1
                else:
                    d += 1
        self.depth[self.n + 1] = d
        self.final_depth = d
        self.units = sorted(wrappers + self._other_units(neutral), key=lambda u: u["start"])
        self.sections = self._sections()
        self.prelude_end = self._prelude_end()
        self.defs = self._defs()

    def _wrappers(self):
        units, neutral = [], set()
        for k, line in enumerate(self.lines, 1):
            m = re.match(r"^function\s+(\w+Tests)\s*\(\s*\)", line)
            if not m:
                continue
            call = re.compile(r"^" + m.group(1) + r"\(\)\s*$")
            c = next((j for j in range(k + 1, self.n + 1) if call.match(self.lines[j - 1])), None)
            if c is None:
                continue
            e = c - 1
            while e > k and not self.lines[e - 1].strip():
                e -= 1
            if re.match(r"^end\b", self.lines[e - 1]):
                neutral.update((k, e))
                units.append({"name": m.group(1), "start": k, "end": c, "wrapper": True})
        return units, neutral

    def stmt_end(self, s):
        j = s
        while j < self.n and self.depth[j + 1] != 0:
            j += 1
        return j

    def _other_units(self, neutral):
        units, k = [], 1
        while k <= self.n:
            line = self.lines[k - 1]
            if self.depth[k] == 0 and k not in neutral:
                m = re.match(r"^local\s+function\s+(\w+)\s*\(", line)
                anon = line.startswith(";(function()")
                if (m and m.group(1).endswith("Tests")) or anon:
                    e = self.stmt_end(k)
                    name = m.group(1) if m else "anon@%d" % k
                    call = e
                    if m:
                        nxt = e + 1
                        while nxt <= self.n and not self.lines[nxt - 1].strip():
                            nxt += 1
                        if nxt <= self.n and self.lines[nxt - 1].strip() == name + "()":
                            call = nxt
                    units.append({"name": name, "start": k, "end": call, "wrapper": False})
                    k = call
            k += 1
        return units

    def unit_at(self, line):
        best = None
        for u in self.units:
            if u["start"] <= line <= u["end"] and (best is None or u["end"] - u["start"] < best["end"] - best["start"]):
                best = u
        return best

    def own_lines(self, u):
        """The unit's lines, without the units nested inside it."""
        skip = set()
        for v in self.units:
            if v is not u and u["start"] <= v["start"] and v["end"] <= u["end"]:
                skip.update(range(v["start"], v["end"] + 1))
        return [k for k in range(u["start"], u["end"] + 1) if k not in skip]

    def _sections(self):
        out = []
        for k, line in enumerate(self.lines, 1):
            m = re.match(r'^\s*section\("((?:[^"\\]|\\.)*)"\)', line)
            if m:
                u = self.unit_at(k)
                out.append({"line": k, "name": m.group(1), "unit": u["name"] if u else None})
        return out

    def _prelude_end(self):
        for k, line in enumerate(self.lines, 1):
            if re.match(PRELUDE_BEFORE, line) and self.depth[k] == 0:
                return k - 1
        return FALLBACK_PRELUDE

    def wrapper_chain(self, line):
        """Names of the wrapper functions that enclose this line, innermost first."""
        ws = [u for u in self.units if u.get("wrapper") and u["start"] < line < u["end"]]
        return [u["name"] for u in sorted(ws, key=lambda u: u["end"] - u["start"])]

    def _declared(self, text):
        names = set()
        for m in re.finditer(r"\blocal\s+function\s+(\w+)", text):
            names.add(m.group(1))
        for m in re.finditer(r"\blocal\s+([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)", text):
            names.update(x.strip() for x in m.group(1).split(","))
        for m in re.finditer(r"\bfor\s+([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*(?:in\b|=)", text):
            names.update(x.strip() for x in m.group(1).split(","))
        for m in re.finditer(r"\bfunction\s*[\w.:]*\s*\(([^)]*)\)", text):
            names.update(x.strip() for x in m.group(1).split(",") if x.strip() and x.strip() != "...")
        return names

    def _defs(self):
        """Locals declared in the main chunk or directly in a wrapper, after the prelude:
        name -> [(line, end, pure)]. (A wrapper's own locals are shared with the units
        nested inside it, so they count; a plain block's locals do not.)"""
        defs = {}
        for k in range(self.prelude_end + 1, self.n + 1):
            if self.depth[k] != 0:
                continue
            line = self.lines[k - 1]
            w = self.wrapper_chain(k)
            w = w[0] if w else None                 # the innermost wrapper the local lives in
            m = re.match(r"^local\s+function\s+(\w+)", line)
            if m:
                e = self.stmt_end(k)
                defs.setdefault(m.group(1), []).append((k, e, True, w))
                continue
            m = re.match(r"^local\s+([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*(=|$)", line)
            if m:
                e = self.stmt_end(k)
                text = "\n".join(self.clean[k - 1:e])
                rhs = text.split("=", 1)[1] if "=" in text else ""
                pure = bool(re.match(r"\s*function\b", rhs))
                if not pure:
                    calls = [c for c in re.findall(r"([A-Za-z_][\w.:]*)\s*\(", rhs) if c not in KEYWORDS]
                    pure = all(c.startswith(PURE_CALLS) for c in calls)
                for name in (x.strip() for x in m.group(1).split(",")):
                    defs.setdefault(name, []).append((k, e, pure, w))
        return defs

    def used_names(self, lines):
        text = "\n".join(self.clean[k - 1] for k in lines)
        used = set(re.findall(r"(?<![\w.:])([A-Za-z_]\w*)", text)) - KEYWORDS
        return used - self._declared(text)



def whole_file_error(t):
    """tests.lua as one piece. Lua allows 200 local variables in a function, and the file's main
    level is one function. A masked copy (one section, one shard) has fewer and still loads, so
    nothing else notices when the whole file stops loading: it had, for a day, on 14 November,
    and run_tests.py (the reference) could not run at all. -> the error, or None."""
    try:
        from lupa import luajit21 as lj
    except Exception:
        return None
    L = lj.LuaRuntime()
    L.globals()._S = t.src
    return L.eval('(function() local f, e = loadstring(_S, "tests.lua") return e end)()')


WHOLE_FIX = "put the new test in its own scope: function NameTests() ... end NameTests(), or ;(function() ... end)()"


def last_code_line(t):
    last = t.n
    while last > 0 and not t.lines[last - 1].strip():
        last -= 1
    return last


def find_target(t, args):
    """-> (label, lines, unit_or_None, section_names): lines is the sorted list of target lines"""
    def whole(u):
        names = [s["name"] for s in t.sections if s["unit"] == u["name"]]
        return u["name"], t.own_lines(u), u, names
    if args.unit:
        us = [u for u in t.units if u["name"].lower() == args.unit.lower()]
        if not us:
            us = [u for u in t.units if args.unit.lower() in u["name"].lower()]
        if len(us) != 1:
            sys.exit("unit %r: %s" % (args.unit, "no match (try --list)" if not us else
                                      "several: " + ", ".join(u["name"] for u in us)))
        return whole(us[0])
    if args.line:
        ms = [s for s in t.sections if s["line"] == args.line]
    else:
        want = args.section.lower()
        ms = [s for s in t.sections if s["name"].lower() == want] or \
             [s for s in t.sections if want in s["name"].lower()]
    if len(ms) != 1:
        if not ms:
            sys.exit("no section matches %r (try --list)" % (args.section or args.line))
        print("several sections match, pick one with --line N:")
        for s in ms:
            print("  %5d  %s%s" % (s["line"], ("[%s] " % s["unit"]) if s["unit"] else "", s["name"]))
        sys.exit(2)
    s = ms[0]
    if s["unit"]:
        u = next(x for x in t.units if x["name"] == s["unit"])
        print("note: section %r is inside unit %s: running the whole unit" % (s["name"], u["name"]))
        return whole(u)
    nxt = [x["line"] for x in t.sections if x["line"] > s["line"] and not x["unit"]]
    nxt += [u["start"] for u in t.units if u["start"] > s["line"]]
    end = (min(nxt) - 1) if nxt else t.n
    end = min(end, last_code_line(t) - 1)          # never the final return line
    return s["name"], list(range(s["line"], end + 1)), None, [s["name"]]


def build_mask(t, args, lines):
    start, end = lines[0], lines[-1]
    pre = args.prelude if args.prelude is not None else t.prelude_end
    keep = set(range(1, min(pre, t.n) + 1))
    for k in range(pre + 1, start):                # config defaults set between the sections
        if t.depth[k] == 0 and re.match(r"^_setcvar\(.*\)\s*(--.*)?$", t.lines[k - 1]):
            keep.add(k)
    borrowed, needs, seen = [], [], set()
    visible = set(t.wrapper_chain(start)) if t.unit_at(start) is None or not t.unit_at(start).get("wrapper") \
        else set(t.wrapper_chain(start)) | {t.unit_at(start)["name"]}
    todo = [(n, start) for n in t.used_names(lines)]
    while todo:
        name, before = todo.pop()
        cands = [d for d in t.defs.get(name, []) if pre < d[0] < before and (d[3] is None or d[3] in visible)]
        if not cands or (name, cands[-1][0]) in seen:
            continue
        line, e, pure, _ = cands[-1]
        seen.add((name, line))
        if pure and not args.borrow_all:
            # a local that only reads other locals is safe only if those are safe too
            for dep in t.used_names(range(line, e + 1)):
                dc = [d for d in t.defs.get(dep, []) if pre < d[0] < line and (d[3] is None or d[3] in visible)]
                if dc and not dc[-1][2]:
                    pure = False
                    break
        if pure or args.borrow_all:
            keep.update(range(line, e + 1))
            borrowed.append("%s@%d" % (name, line))
            todo.extend((n, line) for n in t.used_names(range(line, e + 1)))
        else:
            needs.append("%s@%d" % (name, line))
    for a, b in args.also or []:
        keep.update(range(a, b + 1))
    if args.from_section:
        ms = [s for s in t.sections if args.from_section.lower() in s["name"].lower() and not s["unit"]]
        if not ms:
            sys.exit("--from: no top-level section matches %r" % args.from_section)
        keep.update(range(ms[0]["line"], start))
    keep.update(lines)
    return keep, sorted(set(borrowed)), sorted(set(needs))


def write_masked(t, keep, lines, path):
    out = [""] * t.n
    for k in keep:
        out[k - 1] = t.lines[k - 1]
    last = last_code_line(t)
    if not t.lines[last - 1].startswith("return results.pass"):
        sys.exit("tests.lua no longer ends with 'return results.pass, ...': fix run_section.py")
    # statements put IN FRONT of a line (never after it: a line may end in a comment)
    def mark(text, line=""):
        stmt = 'results.lines[#results.lines + 1] = "%s"' % text
        return stmt + ("" if line.startswith(";") else "; ")
    out[last - 1] = 'ok(#_errors == 0, "no errors logged during the run", _errors[1]); ' + t.lines[last - 1]
    out[lines[0] - 1] = mark("@@BEGIN", out[lines[0] - 1]) + out[lines[0] - 1]
    after = min(lines[-1] + 1, last)               # the line just after the target: END goes in front of it
    out[after - 1] = mark("@@END", out[after - 1]) + out[after - 1]
    with open(path, "w") as f:
        f.write("\n".join(out))


def summarize(text):
    """-> (target_pass, target_fail, target_fail_lines, other_pass, other_fail, other_fail_lines)"""
    inside, tp, tf, tl, op, of, ol = False, 0, 0, [], 0, 0, []
    for line in text.split("\n"):
        if line.strip() == "@@BEGIN":
            inside = True
        elif line.strip() == "@@END":
            inside = False
        elif line.startswith("  PASS"):
            if inside:
                tp += 1
            else:
                op += 1
        elif line.startswith("  FAIL"):
            if inside:
                tf += 1
                tl.append(line)
            else:
                of += 1
                ol.append(line)
    return tp, tf, tl, op, of, ol


def listing(t):
    rows = ["# _dev/tests_index.txt: generated by `python3 _dev/run_section.py --index` from _dev/tests.lua (%d lines)." % t.n,
            "# Do not hand-edit; regenerate after adding sections. Do not read it whole (15K): `grep -n TEXT _dev/tests_index.txt` or `python3 _dev/run_section.py --list TEXT` (always live).",
            "# TOP = a section in the main chunk (runs alone). UNIT = a test function (XTests): its sections run only as the whole unit.",
            "# Run: python3 _dev/run_section.py \"part of a section name\"   or   --unit UnitName   (add --line N when two share a name)",
            "# prelude = lines 1-%d (always run first)" % t.prelude_end]
    items = [(s["line"], "top", s) for s in t.sections if not s["unit"]] + [(u["start"], "unit", u) for u in t.units]
    for _, kind, x in sorted(items, key=lambda i: i[0]):
        if kind == "top":
            nxt = [y["line"] for y in t.sections if y["line"] > x["line"] and not y["unit"]]
            nxt += [u["start"] for u in t.units if u["start"] > x["line"]]
            rows.append("%d-%d TOP %s" % (x["line"], (min(nxt) - 1) if nxt else t.n, x["name"]))
        else:
            rows.append("%d-%d UNIT %s" % (x["start"], x["end"], x["name"]))
            for s in t.sections:
                if s["unit"] == x["name"]:
                    rows.append("    %d %s" % (s["line"], s["name"]))
    return rows



def main():
    ap = argparse.ArgumentParser(description="Run one section or unit of _dev/tests.lua and print only the result.")
    ap.add_argument("section", nargs="?", help="part of a section name (case-insensitive)")
    ap.add_argument("--unit", help="run a unit by name, e.g. UndergroundTests")
    ap.add_argument("--line", type=int, help="the section that starts on this line of tests.lua")
    ap.add_argument("--list", nargs="?", const="", metavar="TEXT", help="list sections and units (matching TEXT)")
    ap.add_argument("--index", action="store_true", help="write _dev/tests_index.txt")
    ap.add_argument("--also", action="append", type=lambda s: tuple(int(x) for x in s.split("-")), metavar="A-B",
                    help="also keep lines A-B of tests.lua (repeatable)")
    ap.add_argument("--from", dest="from_section", metavar="SECTION",
                    help="also run every line from this earlier top-level section up to the target")
    ap.add_argument("--borrow-all", action="store_true", help="borrow locals built by real code too")
    ap.add_argument("--prelude", type=int, help="keep lines 1..N as the prelude instead of the default")
    ap.add_argument("--timeout", type=int, default=1800, help="seconds before giving up (default 1800)")
    ap.add_argument("--dry-run", action="store_true", help="write the masked copy and show the plan, don't run")
    args = ap.parse_args()

    t = Tests()
    if t.final_depth != 0:
        sys.exit("block depth does not return to 0 (%d): run_section.py cannot read tests.lua" % t.final_depth)
    whole = whole_file_error(t)
    if whole:
        print("TESTS.LUA DOES NOT LOAD WHOLE (run_tests.py cannot run it): %s" % whole)
        print("  " + WHOLE_FIX)
    if args.index:
        rows = listing(t)
        with open(INDEX, "w") as f:
            f.write("\n".join(rows) + "\n")
        print("wrote %s (%d lines, %d sections, %d units)" % (INDEX, len(rows), len(t.sections), len(t.units)))
        return
    if args.list is not None:
        want = args.list.lower()
        for row in listing(t)[5:]:
            if not want or want in row.lower():
                print(row[:160])
        return
    if not (args.section or args.unit or args.line):
        ap.error("give a section name, --unit, --line, --list or --index")

    label, lines, unit, names = find_target(t, args)
    keep, borrowed, needs = build_mask(t, args, lines)
    os.makedirs(OUTDIR, exist_ok=True)
    slug = re.sub(r"[^A-Za-z0-9]+", "_", label).strip("_")[:50] or "section"
    masked = os.path.join(OUTDIR, slug + ".lua")
    outp = os.path.join(OUTDIR, slug + ".out.txt")
    write_masked(t, keep, lines, masked)
    print("target: %s (lines %d-%d, %d lines)%s" % (label, lines[0], lines[-1], len(lines),
                                                  (" unit, %d sections" % len(names)) if unit else ""))
    print("prelude: lines 1-%d; masked copy (same line numbers as tests.lua): %s"
          % (args.prelude if args.prelude is not None else t.prelude_end, masked))
    print("borrowed helpers: %s" % (", ".join(borrowed) or "none"))
    if needs:
        print("NEEDS STATE (used by the target, built by real code earlier, NOT included): %s" % ", ".join(needs))
        print("  if the run fails on these: --also A-B, --from \"earlier section\", or --borrow-all")
    if args.dry_run:
        return

    t0 = time.time()
    try:
        with open(outp, "w") as fh:
            r = subprocess.run([sys.executable, "run_tests.py", masked], cwd=HERE, stdout=fh,
                               stderr=subprocess.STDOUT, timeout=args.timeout)
        code = r.returncode
    except subprocess.TimeoutExpired:
        print("TIMEOUT after %ds; partial output: %s" % (args.timeout, outp))
        sys.exit(124)
    text = open(outp).read()
    tp, tf, tl, op, of, ol = summarize(text)
    print("output: %s (%.0fs)" % (outp, time.time() - t0))
    if tp + tf == 0:
        print("NO RESULTS from the target: the run crashed or never reached it.")
        errs = [l for l in text.split("\n") if "LuaError" in l or "LOAD FAILED" in l or "GMOD LUA CHECK FAILED" in l]
        for line in errs[:3]:
            print("  " + line.strip()[:300])
        for line in [l for l in text.split("\n") if "in function '" in l or "in main chunk" in l and "tests.lua" in l][:6]:
            print("    " + line.strip()[:200])
        if not errs:
            for line in text.rstrip().split("\n")[-8:]:
                print("  " + line[:200])
        print("  full output: " + outp)
        sys.exit(1)
    for line in tl[:25]:
        print(line[:220])
    if len(tl) > 25:
        print("  ... %d more FAIL lines in the output file" % (len(tl) - 25))
    print("elsewhere in the run (prelude and borrowed lines): %d passed, %d failed%s"
          % (op, of, ("; first: " + ol[0].strip()[:160]) if ol else ""))
    print("RESULT %s: %d passed, %d failed" % (label, tp, tf))
    if "Traceback" in text or "LOAD FAILED" in text or "GMOD LUA CHECK FAILED" in text:
        print("(the output also holds an error: grep -n 'Traceback\\|FAILED' %s)" % outp)
    sys.exit(1 if tf or of or code not in (0, 1) else 0)


if __name__ == "__main__":
    main()

