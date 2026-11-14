#!/usr/bin/env python3
"""The robot players: every job taken and done the way a player would, start to payout.

    python3 _dev/robots.py            the table, and what stuck, failed or errored
    python3 _dev/robots.py --quiet    only the summary and the problems

A robot is a fake player (robots.lua). It takes each job for each side it is offered to and
does it: walks there, uses the thing, makes the arrest, searches by hand, answers the choice.
A job passes when it finishes and pays. Each job is done twice, the second time with the
game's hooks answering in the other order: a job that goes differently depends on which
piece of code hears a key press first, which the game does not promise. The run starts from
the city the first 505 lines of tests.lua build. Exit code 1 when a job did not finish or
went differently the other way round.
"""
import os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
RESULTS = ("done", "FAILED", "STUCK", "TIMED OUT", "ERROR", "KNOWN", "robot can't", "not offered", "not built")
BAD = ("FAILED", "STUCK", "TIMED OUT", "ERROR")


def run():
    fd, path = tempfile.mkstemp(prefix="lc_robots_", suffix=".txt")
    os.close(fd)
    env = dict(os.environ, LC_ROBOTS=path)
    r = subprocess.run([sys.executable, os.path.join(HERE, "run_section.py"), "--unit", "RobotTests"],
                       cwd=os.path.join(HERE, ".."), env=env, capture_output=True, text=True)
    text = open(path).read() if os.path.exists(path) else ""
    os.unlink(path)
    return r, text


def result_of(line):
    """the result column of a table row (side 11 wide, job 34 wide, then the result), or None"""
    if len(line) < 48 or line[:1].isspace():
        return None
    rest = line[47:]
    for res in RESULTS:
        if rest.startswith(res):
            return res
    return None


def main():
    quiet = "--quiet" in sys.argv
    r, text = run()
    if not text.strip():
        print("THE ROBOTS DID NOT RUN:")
        print(r.stdout[-2000:])
        sys.exit(1)
    lines = text.split("\n")
    head = []
    for l in lines:
        if l.startswith("side "):
            break
        head.append(l)
    rows = [l for l in lines if result_of(l)]
    bad = [l for l in rows if result_of(l) in BAD]
    cant = [l for l in rows if result_of(l) == "robot can't"]
    order = []
    for i, l in enumerate(lines):
        if l.strip().startswith("ORDER") and l[:1].isspace() and i > 0 and "the other way round" in l:
            order.append([lines[i - 1][:11].strip(), lines[i - 1][12:46].strip(), l.strip()])
    print("\n".join(head).rstrip() if quiet else text)
    if bad:
        print("\nDID NOT FINISH (%d):" % len(bad))
        for l in bad:
            print("  " + l[:400])
    if order:
        print("\nGOES DIFFERENTLY WITH THE HOOKS IN THE OTHER ORDER (%d):" % len(order))
        for side, job, what in order:
            print("  %-11s %-34s %s" % (side, job, what[:300]))
    known = [l for l in rows if result_of(l) == "KNOWN"]
    if known:
        print("\nKNOWN, WAITING ON THE OWNER (%d): see TODO.md" % len(known))
        for l in known:
            print("  " + l[:300])
    if cant:
        print("\nTHE ROBOT CAN'T YET (%d):" % len(cant))
        for l in cant:
            print("  " + l[:400])
    m = re.search(r"RESULT RobotTests: (\d+) passed, (\d+) failed", r.stdout)
    if m and int(m.group(2)):
        print("\n" + m.group(0))
    fail = bool(bad or order)
    print("\nROBOTS %s" % ("FAIL" if fail else "PASS"))
    sys.exit(1 if fail else 0)


if __name__ == "__main__":
    main()
