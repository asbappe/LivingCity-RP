#!/usr/bin/env python3
"""The house rules as numbers that may fall but not rise (CLAUDE.md, rules 2, 9 and 10).

    python3 _dev/house_rules.py            check the code against _dev/house_rules.json
    python3 _dev/house_rules.py --update   write today's numbers as the new baseline (say why in the commit)
    python3 _dev/house_rules.py --list     print what was counted, line by line

Three things are counted in the gamemode's code:

  stand-still steps (rule 9)   a job step that is "be at this spot for N seconds": Hold(...), or a stage of
                               kind "hold" or "survive". The owner's exceptions (holding ground against attacks,
                               a unit's checkpoint or post, a zone you raided) and the old shifts kept under
                               lc_jobgames 0 are the baseline. A new one fails the check.
  places that put text on a    ChatPrint, PrintMessage, chat.AddText, LC.Notice, LC.Hint. Rule 10: before adding
  player's screen (rule 10)    one, ask whether the world can show it instead, or change a line that is there.
  console-only commands        a console command the menus' code never names. Rule 2: everything works through
  (rule 2)                     the in-game menus; a console command is an extra for admins, never the only way.

The check is also the first thing run_tests.py does, so every test run makes it.
"""
import glob, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
GM = os.path.join(ROOT, "gamemodes", "livingcity")
BASE = os.path.join(HERE, "house_rules.json")

ARG = r"(?:[^,()]|\([^()]*(?:\([^()]*\)[^()]*)*\))+"
STAND = [
    re.compile(r"(?<![\w.:])(?:Q\.)?Hold\(\s*" + ARG + r",\s*" + ARG + r",\s*(?:string\.format\(\s*)?\""),
    re.compile(r"kind\s*=\s*\"(hold|survive)\""),
]
TEXT = re.compile(r"(?:[:.]ChatPrint|[:.]PrintMessage|chat\.AddText|LC\.Notice\w*|LC_CL\.AddNotice|LC\.Hint\w*)\(")
COMMAND = re.compile(r"concommand\.Add\(\s*\"([^\"]+)\"")


LUA_TOKEN = re.compile(r"--\[(=*)\[.*?\]\1\]|--[^\n]*|\[(=*)\[.*?\]\2\]|\"(?:\\.|[^\"\\\n])*\"|'(?:\\.|[^'\\\n])*'", re.S)


def strip_lua(src, keep_strings=False):
    """comments out; strings kept or emptied; the line count stays"""
    def repl(m):
        t = m.group(0)
        if t.startswith("--"):
            return "\n" * t.count("\n")
        if keep_strings:
            if t.startswith("["):
                return t
            return '"' + t[1:-1].replace('"', "'") + '"'
        return '""' + "\n" * t.count("\n")
    return LUA_TOKEN.sub(repl, src)


def count():
    stand, text, commands, used, where = {}, 0, set(), "", {"stand": [], "text": {}}
    files = sorted(glob.glob(GM + "/**/*.lua", recursive=True))
    client_src = []
    for path in files:
        rel = os.path.relpath(path, ROOT)
        name = os.path.basename(path)
        raw = open(path, encoding="utf-8", errors="replace").read()
        with_str = strip_lua(raw, keep_strings=True)
        code = strip_lua(raw)
        for rx in STAND:
            for m in rx.finditer(with_str):
                line = with_str.count("\n", 0, m.start()) + 1
                if re.match(r"\s*local function Hold\b", with_str.split("\n")[line - 1]):
                    continue                        # (the building block itself)
                stand[name] = stand.get(name, 0) + 1
                where["stand"].append("%s:%d  %s" % (rel, line, with_str.split("\n")[line - 1].strip()[:150]))
        n = len(TEXT.findall(code))
        if n:
            text += n
            where["text"][name] = n
        for m in COMMAND.finditer(with_str):
            commands.add(m.group(1))
        if "/client/" in path.replace("\\", "/") or name in ("cl_init.lua",) or name.startswith("sh_") or "/entities/" in path.replace("\\", "/"):
            client_src.append(with_str)
    menus = "\n".join(client_src)
    console_only = sorted(c for c in commands if not re.search(r"[\"' ]" + re.escape(c) + r"[\"' ]", menus))
    return {"stand_still_steps": dict(sorted(stand.items())), "text_places": text, "console_only_commands": console_only}, where


def check(now, base):
    problems = []
    for f, n in now["stand_still_steps"].items():
        was = base["stand_still_steps"].get(f, 0)
        if n > was:
            problems.append("%s has %d stand-still job steps, %d more than allowed (house rule 9: no 'stay here for N seconds' steps; "
                            "use a job game, hand work, a search, an interrogation or something scripted. If it is one of the owner's "
                            "exceptions, run python3 _dev/house_rules.py --update and say which in the commit)" % (f, n, n - was))
    if now["text_places"] > base["text_places"]:
        problems.append("the gamemode now puts text on a player's screen from %d places, %d more than before (house rule 10: can the world "
                        "show it instead, or an existing line change? If the line is needed, python3 _dev/house_rules.py --update)"
                        % (now["text_places"], now["text_places"] - base["text_places"]))
    new = [c for c in now["console_only_commands"] if c not in base["console_only_commands"]]
    if new:
        problems.append("console commands no menu runs: %s (house rule 2: every action goes on F1, F2 or F4 first. If it is an "
                        "extra for admins, python3 _dev/house_rules.py --update)" % ", ".join(new))
    return problems


def main():
    now, where = count()
    if "--list" in sys.argv:
        print("STAND-STILL STEPS (%d)" % sum(now["stand_still_steps"].values()))
        for l in where["stand"]:
            print("  " + l)
        print("\nTEXT PLACES (%d), the most first" % now["text_places"])
        for f, n in sorted(where["text"].items(), key=lambda kv: -kv[1])[:25]:
            print("  %4d  %s" % (n, f))
        print("\nCONSOLE-ONLY COMMANDS (%d)" % len(now["console_only_commands"]))
        print("  " + " ".join(now["console_only_commands"]))
        return
    if "--update" in sys.argv or not os.path.exists(BASE):
        with open(BASE, "w") as f:
            json.dump(now, f, indent=1, sort_keys=True)
            f.write("\n")
        print("wrote %s: %d stand-still steps, %d text places, %d console-only commands"
              % (os.path.relpath(BASE, ROOT), sum(now["stand_still_steps"].values()), now["text_places"], len(now["console_only_commands"])))
        return
    base = json.load(open(BASE))
    problems = check(now, base)
    lower = []
    if now["text_places"] < base["text_places"]:
        lower.append("text places %d -> %d" % (base["text_places"], now["text_places"]))
    s0, s1 = sum(base["stand_still_steps"].values()), sum(now["stand_still_steps"].values())
    if s1 < s0:
        lower.append("stand-still steps %d -> %d" % (s0, s1))
    if problems:
        print("HOUSE RULES CHECK FAILED")
        for p in problems:
            print("  " + p)
        sys.exit(1)
    print("house rules: %d stand-still steps, %d text places, %d console-only commands%s"
          % (s1, now["text_places"], len(now["console_only_commands"]),
             (" (lower than the baseline: " + ", ".join(lower) + "; --update keeps the gain)") if lower else ""))


if __name__ == "__main__":
    main()
