#!/usr/bin/env python3
"""Every line of text a player can see, pulled out of the gamemode's Lua, with where it
comes from and what makes it show. Writes PLAYER_TEXT.md at the repo root.

    python3 _dev/player_text.py

How it decides what a player sees: any string with words in it (two or more, or a
capitalised one), except where the code only talks to itself or to admins: log lines,
errors, settings' descriptions, console prints, hook and network names, file and model
paths. Joined-up text shows the parts the code fills in as {name}; a %d or %s in a
formatted line is also something filled in.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GM = os.path.join(ROOT, "gamemodes", "livingcity")
OUT = os.path.join(ROOT, "PLAYER_TEXT.md")

# calls whose strings never reach a player (or only reach an admin's console)
SKIP_CALLS = {"Log", "Error", "print", "error", "Msg", "MsgN", "MsgC", "CreateConVar", "CreateClientConVar",
    "AddNetworkString", "Start", "Receive", "Add", "Remove", "Create", "Run", "Call", "GetConVar", "SetModel",
    "EmitSound", "PlaySound", "Material", "include", "AddCSLuaFile", "LookupBone", "LookupSequence", "LookupAttachment",
    "Exists", "Find", "Read", "Write", "Append", "Delete", "CreateDir", "IsDir", "GetPData", "SetPData", "RemovePData",
    "GetNW2String", "SetNW2String", "GetNW2Int", "SetNW2Int", "GetNW2Bool", "SetNW2Bool", "GetNW2Float", "SetNW2Float",
    "GetNW2Entity", "SetNW2Entity", "GetNW2Vector", "SetNW2Vector", "SetGlobal2Float", "GetGlobal2Float", "SetGlobal2String",
    "GetGlobal2String", "SetGlobal2Int", "GetGlobal2Int", "SetGlobal2Bool", "GetGlobal2Bool", "Simple", "Exists", "Adjust",
    "CreateFont", "SetFont", "Fire", "SetKeyValue", "GetClass", "FindByClass", "SetSchedule", "SetSequence", "ResetSequence",
    "ReadString", "WriteString", "match", "find", "gsub", "gmatch", "sub", "Replace", "Explode", "Split", "StartWith",
    "EndsWith", "lower", "upper", "rep", "byte", "Effect", "Sound", "CreateSound", "SetMaterial", "SetSubMaterial",
    "PrecacheModel", "PrecacheSound", "IsValidModel", "AddFile", "AddSingleFile", "SendLua", "BroadcastLua", "Tick",
    "SetCollisionGroup", "TraceLine", "Assert", "assert", "Profile", "StuckLog", "Warn", "Debug", "PushModelMatrix",
    "LCError", "ChangeCallback", "AddChangeCallback", "Timer", "TimerCreate", "Exec", "ConCommand", "RunConsoleCommand",
    "SetNWString", "GetNWString", "PlayFile", "PlayURL", "DrawMaterial", "SetImage", "LookupPoseParameter", "SetPoseParameter",
    "SetBodygroup", "FindBodygroupByName", "GetBodygroupCount", "SetSkin", "SetDSP", "StopSound", "PrecacheParticleSystem",
    "ParticleEffect", "ParticleEffectAttach", "CreateParticleSystem", "SetLabel"}
# words that make a string look like code, a path or an id rather than prose
PATHY = re.compile(r"^[\w./\\%:-]*$")
PATH_EXT = re.compile(r"\.(mdl|wav|mp3|ogg|vmt|vtf|png|jpg|txt|json|lua|dat|vdf|pcf)\b", re.I)
WORD = re.compile(r"[A-Za-z][a-z']+")

def tokens(src):
    """Lua tokens: (kind, text, line). Kinds: str, name, sym, num. Comments dropped."""
    i, n, line, out = 0, len(src), 1, []
    while i < n:
        c = src[i]
        if c == "\n": line += 1; i += 1; continue
        if c in " \t\r": i += 1; continue
        if src.startswith("--", i):
            m = re.match(r"--\[(=*)\[", src[i:])
            if m:
                end = src.find("]" + m.group(1) + "]", i)
                end = n if end < 0 else end + len(m.group(1)) + 2
            else:
                end = src.find("\n", i); end = n if end < 0 else end
            line += src.count("\n", i, end); i = end; continue
        m = re.match(r"\[(=*)\[", src[i:])
        if m:
            end = src.find("]" + m.group(1) + "]", i)
            end = n if end < 0 else end
            body = src[i + len(m.group(0)):end]
            out.append(("str", body, line)); line += src.count("\n", i, end); i = end + len(m.group(1)) + 2; continue
        if c in "\"'":
            j, buf = i + 1, []
            while j < n and src[j] != c:
                if src[j] == "\\" and j + 1 < n:
                    e = src[j + 1]
                    buf.append({"n": "\n", "t": "\t", "\"": "\"", "'": "'", "\\": "\\"}.get(e, "\\" + e)); j += 2; continue
                if src[j] == "\n": break
                buf.append(src[j]); j += 1
            out.append(("str", "".join(buf), line)); i = j + 1; continue
        m = re.match(r"[A-Za-z_][A-Za-z0-9_]*", src[i:])
        if m: out.append(("name", m.group(0), line)); i += len(m.group(0)); continue
        m = re.match(r"0x[0-9a-fA-F]+|\d+\.?\d*(e[-+]?\d+)?", src[i:])
        if m: out.append(("num", m.group(0), line)); i += len(m.group(0)); continue
        if src.startswith("...", i): out.append(("sym", "...", line)); i += 3; continue
        if src[i:i + 2] in ("..", "==", "~=", "<=", ">=", "::"): out.append(("sym", src[i:i + 2], line)); i += 2; continue
        out.append(("sym", c, line)); i += 1
    return out

def prose(s):
    t = s.strip()
    if len(t) < 3 or PATHY.match(t) and " " not in t: return False
    if PATH_EXT.search(t) and " " not in t: return False
    if re.match(r"^(lc_|lcf_|lcj_|LivingCity|ACT_|SCHED_|npc_|weapon_|prop_|item_|models/|sound/|materials/)", t): return False
    words = WORD.findall(t)
    return len(words) >= 2 or (len(words) == 1 and t[:1].isupper() and len(t) > 3 and " " not in t and t.isalpha())

def comments_by_line(src):
    """The comment block right above each line (what the code says it's for)."""
    lines, notes, block = src.split("\n"), {}, []
    for k, l in enumerate(lines, 1):
        s = l.strip()
        if s.startswith("--") and not s.startswith("--[["):
            block.append(s.lstrip("-").strip())
        else:
            if block: notes[k] = " ".join(b for b in block if b)
            if s: block = [] if not s.startswith("--") else block
    return notes

def context(toks, k):
    """The call or table field a string sits in, and the function it's inside."""
    depth, call, field = 0, None, None
    j = k - 1
    while j >= 0:
        kind, t, _ = toks[j]
        if kind == "sym" and t in ")]}": depth += 1
        elif kind == "sym" and t in "([{":
            if depth == 0:
                if t == "(" and j > 0 and toks[j - 1][0] == "name": call = toks[j - 1][1]
                elif t == "{" and call is None: call = "{"
                break
            depth -= 1
        elif depth == 0 and kind == "sym" and t == "=" and field is None and j > 0 and toks[j - 1][0] == "name" and toks[j-1][1] not in ("local",):
            field = toks[j - 1][1]
        elif depth == 0 and kind == "sym" and t == "," and field is None:
            field = ""  # (a list item: no field of its own)
        j -= 1
    return call, (field or None)

def chain(toks, k):
    """A string joined with others by .. : the whole line, the code parts as {name}. Returns (text, last index)."""
    parts, j = [toks[k][1]], k + 1
    while j + 1 < len(toks) and toks[j] == ("sym", "..", toks[j][2]):
        j += 1
        if toks[j][0] == "str":
            parts.append(toks[j][1]); j += 1; continue
        # an expression up to the next .. at the same depth
        depth, start = 0, j
        while j < len(toks):
            kind, t, _ = toks[j]
            if kind == "sym" and t in "([{": depth += 1
            elif kind == "sym" and t in ")]}":
                if depth == 0: break
                depth -= 1
            elif depth == 0 and kind == "sym" and t in (",", "..", "then", "do"): break
            elif depth == 0 and kind == "name" and t in ("then", "do", "end", "else", "elseif", "and", "or", "local", "return"): break
            j += 1
        names = [x[1] for x in toks[start:j] if x[0] == "name" and x[1] not in ("math", "string", "tostring", "LC", "ply", "self")]
        parts.append("{" + (names[-1] if names else "...") + "}")
    return "".join(parts), j - 1

# what a hook means, in plain words
HOOKS = {"PlayerUse": "pressing E on something", "PlayerSay": "typing in chat", "PlayerSpawn": "spawning",
    "PlayerDeath": "someone dying", "PlayerInitialSpawn": "joining the server", "PlayerDisconnected": "someone leaving",
    "Think": "all the time", "Tick": "all the time", "HUDPaint": "on screen", "HUDPaintBackground": "on screen",
    "OnNPCKilled": "an NPC dying", "EntityTakeDamage": "something being hurt", "KeyPress": "pressing a key",
    "PlayerButtonDown": "pressing a key", "PlayerBindPress": "pressing a key", "PostDrawTranslucentRenderables": "drawn in the world",
    "PostDrawOpaqueRenderables": "drawn in the world", "PlayerCanPickupWeapon": "picking up a weapon",
    "PlayerNoClip": "noclipping", "CanPlayerSuicide": "using kill in the console", "ShowHelp": "F1", "ShowTeam": "F2",
    "ShowSpare1": "F3", "ShowSpare2": "F4", "OnContextMenuOpen": "holding C", "PlayerSwitchFlashlight": "the flashlight",
    "LivingCityEndingTriggered": "a secret ending starting", "LivingCityStalker": "being made a stalker"}

def words(name):
    """LC.StashStore -> stash store"""
    name = re.sub(r"^(LC_CL|LC|LCF|LCJ|LCS|LCZ|ENT|SWEP|GM|PANEL|TOOL|Q)[.:]", "", name)
    name = name.split(".")[-1].split(":")[-1]
    w = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", name).replace("_", " ").strip().lower()
    return w

def callback_of(toks, k):
    """An unnamed function: what it's handed to (a hook, a network message, a command, a timer)."""
    j, depth = k - 1, 0
    while j >= 0 and k - j < 40:
        kind, t, _ = toks[j]
        if kind == "sym" and t == ")": depth += 1
        elif kind == "sym" and t == "(":
            if depth == 0:
                call = toks[j - 1][1] if j > 0 else ""
                owner = toks[j - 3][1] if j > 2 and toks[j - 2][1] in (".", ":") else ""
                first = toks[j + 1][1] if toks[j + 1][0] == "str" else None
                if owner == "hook" and first: return "@" + HOOKS.get(first, "the game's " + words(first) + " moment")
                if owner == "net" and first: return "@the game answering something done in a window (" + first + ")"
                if owner == "concommand" and first: return "@the console command " + first
                if owner == "timer": return "@a timer (regularly)"
                return "@" + words(call) if call else None
            depth -= 1
        elif kind == "sym" and t == "=" and depth == 0 and j > 0 and toks[j - 1][0] == "name":
            if j > 2 and toks[j - 3][1] == "SlashCommands": return "@the chat command /" + toks[j - 1][1]
            return words(toks[j - 1][1])
        j -= 1
    return None

FEATURE_FILE = re.compile(r"Living City:\s*(.+)")

def feature_name(src, path):
    m = FEATURE_FILE.search(src[:600])
    if m: return m.group(1).strip().rstrip(".")
    return os.path.basename(path)

def scan(path):
    src = open(path, encoding="utf-8", errors="replace").read()
    toks = tokens(src)
    notes = comments_by_line(src)
    found, skip_to = [], -1
    fn_at, stack, elseif = {}, [], False  # (the blocks we're inside: a function's name, or None)
    for k, (kind, t, line) in enumerate(toks):
        if kind == "name":
            if t == "function":
                nm, q = [], k + 1
                while q < len(toks) and (toks[q][0] == "name" or toks[q][1] in (".", ":")):
                    nm.append(toks[q][1]); q += 1
                stack.append("".join(nm) or callback_of(toks, k))
            elif t == "elseif": elseif = True
            elif t == "then":
                if elseif: elseif = False
                else: stack.append(None)
            elif t in ("do", "repeat"): stack.append(None)
            elif t in ("end", "until") and stack: stack.pop()
        fns = [x for x in stack if x]
        fn_at[k] = fns[-1] if fns else None
        if kind != "str" or k <= skip_to: continue
        text, last = chain(toks, k)
        skip_to = last
        call, field = context(toks, k)
        if call in SKIP_CALLS or call in ("hook", "net", "util", "file", "timer"): continue
        if field in ("model", "mdl", "sound", "snd", "mat", "material", "icon", "id", "kind", "class", "cls", "font", "anim",
                     "act", "seq", "bone", "key", "flag", "cvar", "net", "path", "file", "dir", "folder", "hook", "role",
                     "state", "type", "event", "trig", "trigger", "item", "out", "job", "faction", "chain", "part", "zone", "tag",
                     "Author", "Category", "Purpose", "Instructions", "Contact", "Base", "Type"):
            continue
        if not prose(text.replace("{", "").replace("}", "")): continue
        # the comment nearest above it, within a few lines
        why = None
        for back in range(0, 8):
            if line - back in notes: why = notes[line - back]; break
        found.append({"line": line, "text": text, "call": call, "field": field, "fn": fn_at.get(k), "why": why})
    return feature_name(src, path), found

def describe(e):
    c, f = e["call"], e["field"]
    how = {"ChatPrint": "chat message", "Notice": "on-screen notice", "AddNotice": "on-screen notice", "Tell": "chat message",
           "Say": "chat message", "SimpleText": "drawn on screen", "DrawText": "drawn on screen", "SetText": "label or button",
           "SetTitle": "window title", "AddOption": "menu option", "Button": "button", "AddText": "chat message",
           "PrintMessage": "message", "Narrate": "quest narration", "Goto": "quest step", "Hold": "quest step", "Count": "quest step",
           "Choice": "quest choice", "StartTask": "progress bar", "Frame": "window title", "Item": "menu option", "Add": "menu option",
           "SetTooltip": "tooltip", "format": "message"}.get(c)
    if not how and f: how = {"name": "name", "desc": "description", "title": "title", "label": "label", "text": "text",
                             "doing": "what someone is doing", "useLabel": "pocket button", "hint": "hint", "short": "short name",
                             "say": "spoken line", "line": "spoken line", "PrintName": "name"}.get(f)
    return how or "text"

def version():
    import subprocess
    try:
        return subprocess.check_output(["git", "-C", ROOT, "rev-parse", "--short", "HEAD"], text=True).strip()
    except Exception:
        return "unknown"

def main():
    groups = []
    for base in ("gamemode", "entities"):
        for dp, _, fs in os.walk(os.path.join(GM, base)):
            for f in sorted(fs):
                if f.endswith(".lua"):
                    p = os.path.join(dp, f)
                    name, found = scan(p)
                    if found: groups.append((os.path.relpath(p, ROOT), name, found))
    groups.sort(key=lambda g: g[0])
    total = sum(len(g[2]) for g in groups)
    out = ["# Every line of text a player sees", "",
           "Made by `python3 _dev/player_text.py` from the code itself, so it can be made again after any change. "
           "Grouped by the part of the game it belongs to. Each line: the text (parts the game fills in look like {name}, "
           "and %d, %s or %.1f are numbers or words filled in), how it shows (a chat message, an on-screen notice, a button...), "
           "and when it appears. The lines starting with \"Note for you\" are never shown to players: they're the programmer's own note "
           "from the code, about what's going on in the game at that moment, so you know where the text below them comes up. "
           "Only the text in quotes is what players see. Where it says \"text\" instead of \"chat message\" or \"on-screen notice\", "
           "the script couldn't tell how it's shown: ask if it matters for a wording. The file and line are there so a correction can be found.", "",
           "**How to correct it:** change the words inside the quotes, then send the whole file back. "
           "Leave everything outside the quotes as it is (that's how each line is found in the code again). "
           "Keep any {name} or %d / %s parts: the game fills those in. "
           "A line you don't touch stays as it is. To drop a line altogether, write DELETE inside its quotes. "
           "A note for me about a line can go after it on the same line, starting with NOTE:.", "",
           f"Made from version {version()}. Admin-only console messages and log lines are left out.", "",
           f"{total} lines, from {len(groups)} files.", ""]
    out.append("## Contents\n")
    for path, name, found in groups:
        anchor = re.sub(r"[^a-z0-9 -]", "", (name + " " + os.path.basename(path)).lower()).replace(" ", "-")
        out.append(f"- [{name}](#{anchor}) ({len(found)})")
    out.append("")
    for path, name, found in groups:
        out.append(f"## {name} ({os.path.basename(path)})\n")
        out.append(f"`{path}`\n")
        last_why = None
        for e in found:
            fn = e["fn"]
            why = e["why"] or ((fn[1:] if fn.startswith("@") else ("part of: " + words(fn))) if fn else None)
            if why and why != last_why:
                out.append(f"\n> Note for you (not shown in game): {why}\n")
                last_why = why
            txt = e["text"].replace("\n", " / ").replace("|", "\\|").strip()
            out.append(f"- \"{txt}\"  ({describe(e)}, line {e['line']})")
        out.append("")
    open(OUT, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print(f"PLAYER_TEXT.md: {total} lines from {len(groups)} files")

if __name__ == "__main__":
    main()
