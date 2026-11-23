#!/usr/bin/env python3
"""Living City: real lip sync for the recorded voices (the owner, 23 November: "I REALLY need you to
engineer a solution to NPCs not lip syncing to our custom voice lines").

Half-Life 2's own lines move a face because each .wav carries a hidden phoneme track (a "VDAT" chunk that
Valve's Faceposer writes): which mouth shape, from when to when. The game reads it and works the face
itself, on every player's screen. A recording has no such track, and an .mp3 cannot hold one at all.

This writes that track into every recording in a folder, the way Faceposer would:
  - an .mp3 or .ogg is turned into a .wav beside it first (needs ffmpeg: sudo apt install ffmpeg);
    the gamemode plays the .wav instead of an .mp3 of the same name, so nothing has to be deleted;
  - a .wav gets the track written in; its sound is left exactly as it was;
  - the words come from the scripts (voice_batch.tsv, lipsync_lines.tsv, hl2_lines.txt, or a .txt of the
    same name beside the recording), each word's sounds from lipsync_dict.txt, and when each sound falls
    from the recording itself (where it is loud, quiet, hissing or silent). A recording with no words
    known still gets a track worked out from the sound alone.

    python3 _dev/tools/lipsync_bake.py ~/voice_out/sound/livingcity      (every face's folder in it)
    python3 _dev/tools/lipsync_bake.py ~/voice_out/sound/livingcity --check   (which have a track)

Then upload the folder's new .wav files to the server's garrysmod/sound/livingcity/ as before (the same
folders), press FastDL sync, and change the map. Run it again after making new lines: a file that already
has a track is left alone (--redo writes them all again).

Only the folders of people with faces are baked unless --all is given (the Administrator's PA, Overwatch,
the radio and the machines have no mouth to move, and a .wav is bigger to download than an .mp3).
Needs only Python 3 (numpy makes it faster if it is there).

For a chat: python3 _dev/tools/lipsync_bake.py --update-lines rewrites lipsync_lines.tsv from
VOICE_SCRIPTS.md, and --update-dict CMUDICT adds the words of every script to lipsync_dict.txt from a
copy of the CMU pronouncing dictionary. --selftest checks the tool on a made-up recording.
"""
import argparse, array, math, os, re, shutil, struct, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
DICT = os.path.join(HERE, "lipsync_dict.txt")
LINES = os.path.join(HERE, "lipsync_lines.tsv")
AUDIO = (".wav", ".mp3", ".ogg", ".flac")
# folders (under sound/livingcity/) whose lines are said by someone with a face
FACES = ("citizens", "clerk", "oldtimer", "colonel", "cubbage", "resistance", "hl2/vo/npc", "gman", "endings/gman",
         "dreams/voice")  # (not units: a metrocop's mask has no mouth)
HOP = 0.01  # seconds between looks at the sound

# ---------------------------------------------------------------------------------------------------------
# Source's phonemes: name -> the code the game looks its mouth shape up by (public/phonemeconverter.cpp)
# ---------------------------------------------------------------------------------------------------------
CODE = {"b": 98, "m": 109, "p": 112, "w": 119, "f": 102, "v": 118, "r": 0x279, "er": 0x25A, "dh": 0xF0,
        "th": 0x3B8, "sh": 0x283, "jh": 0x2A4, "ch": 0x2A7, "s": 115, "z": 122, "d": 100, "l": 108, "n": 110,
        "t": 116, "ow": 111, "uw": 117, "ey": 101, "ae": 0xE6, "aa": 0x251, "iy": 105, "y": 106, "ah": 0x28C,
        "ao": 0x254, "ax": 0x259, "eh": 0x25B, "ih": 0x26A, "uh": 0x28A, "g": 103, "hh": 104, "c": 107,
        "nx": 0x14B, "zh": 0x292}
# the CMU dictionary's sounds (ARPAbet) as Source's; the gliding vowels as two shapes, the way the mouth goes
ARPA = {"AA": ["aa"], "AE": ["ae"], "AH": ["ah"], "AO": ["ao"], "AW": ["aa", "uh"], "AY": ["aa", "iy"],
        "EH": ["eh"], "ER": ["er"], "EY": ["ey"], "IH": ["ih"], "IY": ["iy"], "OW": ["ow"], "OY": ["ao", "iy"],
        "UH": ["uh"], "UW": ["uw"], "B": ["b"], "CH": ["ch"], "D": ["d"], "DH": ["dh"], "F": ["f"], "G": ["g"],
        "HH": ["hh"], "JH": ["jh"], "K": ["c"], "L": ["l"], "M": ["m"], "N": ["n"], "NG": ["nx"], "P": ["p"],
        "R": ["r"], "S": ["s"], "SH": ["sh"], "T": ["t"], "TH": ["th"], "V": ["v"], "W": ["w"], "Y": ["y"],
        "Z": ["z"], "ZH": ["zh"]}
VOWEL = {"aa", "ae", "ah", "ao", "ax", "eh", "er", "ey", "ih", "iy", "ow", "uh", "uw"}
KIND = {}
for _p in VOWEL: KIND[_p] = "vowel"
for _p in ("w", "r", "l", "y"): KIND[_p] = "glide"
for _p in ("m", "n", "nx"): KIND[_p] = "nasal"
for _p in ("v", "z", "zh", "dh", "jh"): KIND[_p] = "vfric"
for _p in ("f", "s", "sh", "th", "ch"): KIND[_p] = "fric"
for _p in ("p", "t", "c", "b", "d", "g"): KIND[_p] = "stop"
KIND["hh"] = "breath"
# what each kind sounds like: (loudness 0..1, its spread), (hiss 0..3, its spread), shortest frames, frames beyond that
LOOKS = {"vowel": (0.80, 0.25, 0.25, 0.45, 4, 6), "glide": (0.62, 0.25, 0.3, 0.5, 3, 3),
         "nasal": (0.50, 0.25, 0.2, 0.45, 3, 3), "vfric": (0.48, 0.28, 0.9, 0.7, 3, 3),
         "fric": (0.32, 0.28, 1.6, 0.8, 4, 4), "stop": (0.25, 0.30, 0.8, 0.9, 2, 2),
         "breath": (0.35, 0.28, 1.0, 0.9, 2, 3), "sil": (0.0, 0.12, 0.6, 2.0, 1, 10)}


# ---------------------------------------------------------------------------------------------------------
# Words to sounds
# ---------------------------------------------------------------------------------------------------------
def load_dict(path=DICT):
    out = {}
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            if line.startswith(";;") or not line.strip():
                continue
            w, _, ph = line.strip().partition(" ")
            out.setdefault(w.lower(), ph.split())
    return out


SMALL = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen " \
        "seventeen eighteen nineteen".split()
TENS = "_ _ twenty thirty forty fifty sixty seventy eighty ninety".split()


def number_words(n):
    n = int(n)
    if n < 20: return [SMALL[n]]
    if n < 100: return [TENS[n // 10]] + ([SMALL[n % 10]] if n % 10 else [])
    if n < 1000: return [SMALL[n // 100], "hundred"] + (number_words(n % 100) if n % 100 else [])
    return [SMALL[int(c)] for c in str(n)]


def clean_text(text):
    text = re.sub(r"\[[^\]]*\]", " ", text or "")  # ElevenLabs' tone tags
    text = re.sub(r"<[^>]*>", " ", text)
    return " ".join(text.replace("{", " ").replace("}", " ").split())


def words_of(text):
    out = []
    for tok in re.findall(r"[A-Za-z][A-Za-z'\-]*|\d+", clean_text(text)):
        if tok.isdigit():
            out += number_words(tok)
        else:
            out += [t for t in tok.lower().split("-") if t.strip("'")]
    return out


# letters to sounds, for a word the dictionary lacks (longest spelling first)
RULES = [("tion", "sh ah n"), ("sion", "zh ah n"), ("ough", "ao"), ("augh", "ao"), ("eigh", "ey"), ("igh", "aa iy"),
         ("tch", "ch"), ("sch", "s c"), ("dge", "jh"), ("ph", "f"), ("sh", "sh"), ("ch", "ch"), ("th", "th"),
         ("wh", "w"), ("ck", "c"), ("ng", "nx"), ("qu", "c w"), ("gh", ""), ("ee", "iy"), ("ea", "iy"),
         ("oo", "uw"), ("ou", "aa uh"), ("ow", "ow"), ("oi", "ao iy"), ("oy", "ao iy"), ("ai", "ey"), ("ay", "ey"),
         ("au", "ao"), ("aw", "ao"), ("ie", "iy"), ("ei", "ey"), ("er", "er"), ("ir", "er"), ("ur", "er"),
         ("ar", "aa r"), ("or", "ao r"), ("a", "ae"), ("e", "eh"), ("i", "ih"), ("o", "aa"), ("u", "ah"),
         ("y", "iy"), ("b", "b"), ("c", "c"), ("d", "d"), ("f", "f"), ("g", "g"), ("h", "hh"), ("j", "jh"),
         ("k", "c"), ("l", "l"), ("m", "m"), ("n", "n"), ("p", "p"), ("q", "c"), ("r", "r"), ("s", "s"),
         ("t", "t"), ("v", "v"), ("w", "w"), ("x", "c s"), ("z", "z")]


def guess_sounds(word):
    w = re.sub(r"[^a-z]", "", word.lower())
    if w.startswith("kn") or w.startswith("wr"): w = w[1:]
    if len(w) > 3 and w.endswith("e") and not w.endswith("ee"): w = w[:-1]  # (a silent e)
    out, i = [], 0
    while i < len(w):
        if w[i] == "c" and i + 1 < len(w) and w[i + 1] in "eiy":
            out.append("s"); i += 1; continue
        if w[i] == "y" and i == 0:
            out.append("y"); i += 1; continue
        for spell, snd in RULES:
            if w.startswith(spell, i):
                out += snd.split(); i += len(spell); break
        else:
            i += 1
    return out or ["ah"]


def sounds_of(word, lex):
    ph = lex.get(word) or lex.get(word.strip("'"))
    if not ph and word.endswith("'s") and word[:-2] in lex:  # (Breen's)
        ph = lex[word[:-2]] + ["Z"]
    if not ph and word.endswith("s") and word[:-1] in lex:  # (crowbars)
        ph = lex[word[:-1]] + ["Z"]
    if not ph:  # (headcrab, windowsill: two words the dictionary has)
        for i in range(len(word) - 2, 2, -1):
            if word[:i] in lex and (word[i:] in lex or word[i:].rstrip("s") in lex):
                rest = lex.get(word[i:]) or lex[word[i:].rstrip("s")] + ["Z"]
                ph = lex[word[:i]] + rest
                break
    if not ph:
        return guess_sounds(word)
    out = []
    for p in ph:
        base = re.sub(r"\d", "", p)
        if base == "AH" and p.endswith("0"):
            out.append("ax")
        else:
            out += ARPA.get(base, [])
    return out


# ---------------------------------------------------------------------------------------------------------
# .wav files: their chunks, their samples, the track
# ---------------------------------------------------------------------------------------------------------
def read_chunks(data):
    if data[:4] != b"RIFF" or data[8:12] != b"WAVE":
        raise ValueError("not a .wav (RIFF/WAVE) file")
    out, pos = [], 12
    while pos + 8 <= len(data):
        cid = data[pos:pos + 4]
        size = struct.unpack("<I", data[pos + 4:pos + 8])[0]
        out.append((cid, data[pos + 8:pos + 8 + size]))
        pos += 8 + size + (size & 1)
    return out


def write_chunks(chunks):
    body = b"WAVE"
    for cid, payload in chunks:
        body += cid + struct.pack("<I", len(payload)) + payload + (b"\0" if len(payload) & 1 else b"")
    return b"RIFF" + struct.pack("<I", len(body)) + body


def wav_samples(chunks):
    fmt = next((p for c, p in chunks if c == b"fmt "), None)
    pcm = next((p for c, p in chunks if c == b"data"), None)
    if not fmt or pcm is None:
        raise ValueError("no fmt or data chunk")
    tag, chans, rate, _, align, bits = struct.unpack("<HHIIHH", fmt[:16])
    if tag == 0xFFFE and len(fmt) >= 26:
        tag = struct.unpack("<H", fmt[24:26])[0]
    if tag != 1 or bits not in (8, 16):
        raise ValueError("not 8 or 16-bit PCM (Source plays only those): convert it with ffmpeg first")
    if bits == 16:
        a = array.array("h"); a.frombytes(pcm[:len(pcm) - len(pcm) % 2])
        if sys.byteorder == "big": a.byteswap()
        vals = a
    else:
        vals = [b - 128 for b in pcm]
    if chans > 1:
        vals = vals[::chans]
    return list(vals) if not isinstance(vals, list) else vals, rate, bits


def has_track(chunks):
    return any(c == b"VDAT" for c, _ in chunks)


def features(samples, rate):
    """Every HOP seconds: how loud (0..1 within this recording) and how hissing (0 low .. 3 hiss)."""
    hop = max(1, int(rate * HOP))
    win = hop * 2
    n = max(1, (len(samples) - win) // hop + 1)
    loud, hiss = [], []
    try:
        import numpy as np
        x = np.asarray(samples, dtype=np.float64)
        if len(x) < win: x = np.pad(x, (0, win - len(x)))
        d = np.diff(x, prepend=x[:1])
        cs, cd = np.concatenate([[0], np.cumsum(x * x)]), np.concatenate([[0], np.cumsum(d * d)])
        starts = np.arange(n) * hop
        e = (cs[starts + win] - cs[starts]) / win
        h = (cd[starts + win] - cd[starts]) / win
        loud = list(10 * np.log10(e + 1e-3))
        hiss = list(np.minimum(3.0, h / (e + 1e-3)))
    except ImportError:
        for i in range(n):
            seg = samples[i * hop:i * hop + win] or [0]
            e = sum(v * v for v in seg) / len(seg)
            h = sum((seg[k] - seg[k - 1]) ** 2 for k in range(1, len(seg))) / len(seg)
            loud.append(10 * math.log10(e + 1e-3))
            hiss.append(min(3.0, h / (e + 1e-3)))
    srt = sorted(loud)
    peak = srt[min(len(srt) - 1, int(len(srt) * 0.99))]
    floor = max(srt[int(len(srt) * 0.08)], peak - 45)
    floor = min(floor, peak - 20)
    loud = [min(1.0, max(0.0, (v - floor) / (peak - floor))) for v in loud]
    return loud, hiss


# ---------------------------------------------------------------------------------------------------------
# When each sound falls: a forced alignment (Viterbi) of the words' sounds against the recording
# ---------------------------------------------------------------------------------------------------------
def emit(kind, l, h):
    lm, ls, hm, hs = LOOKS[kind][:4]
    return -0.5 * ((l - lm) / ls) ** 2 - 0.25 * ((h - hm) / hs) ** 2


def align(words, loud, hiss):
    """words: [(word, [sounds])]. Returns [(word, start, end, [(sound, start, end)])] in seconds."""
    n = len(loud)
    units = []  # (kind, sound or None, word index, shortest, extra, skippable)
    units.append(("sil", None, -1, 1, 10, True))
    for wi, (_, snds) in enumerate(words):
        for s in snds:
            k = KIND.get(s, "vowel")
            units.append((k, s, wi, LOOKS[k][4], LOOKS[k][5], False))
        units.append(("sil", None, -1, 1, 10, True))
    # fast speech: shorten what each sound must last so the whole fits
    need = sum(u[3] for u in units if not u[5])
    speech = sum(1 for v in loud if v > 0.2) or n
    scale = min(1.0, speech / max(1, need) * 0.9)
    states = []  # (unit index, place in its chain, last in chain)
    for ui, u in enumerate(units):
        m = max(1, int(round(u[3] * scale))) if not u[5] else 1
        for j in range(m):
            states.append((ui, j, j == m - 1))
    S = len(states)
    first_of = {}
    for si, (ui, j, _) in enumerate(states):
        if j == 0: first_of[ui] = si
    NEG = -1e18
    stay = [math.log(1 - 1.0 / (1 + units[ui][4])) if last else NEG for ui, _, last in states]
    go = [math.log(1.0 / (1 + units[ui][4])) if last else 0.0 for ui, _, last in states]
    # where each state may go next: its chain's next place, else the next unit (past skippable silences)
    nxt = []
    for si, (ui, j, last) in enumerate(states):
        if not last:
            nxt.append([si + 1]); continue
        t, k = [], ui + 1
        while k < len(units):
            t.append(first_of[k])
            if not units[k][5]: break
            k += 1
        nxt.append(t)
    prev = [[] for _ in range(S)]
    for si in range(S):
        for t in nxt[si]: prev[t].append(si)
    em = {}
    score = [NEG] * S
    starts = [first_of[0], first_of[1]] if len(units) > 1 else [0]
    for s0 in starts:
        k = units[states[s0][0]][0]
        score[s0] = emit(k, loud[0], hiss[0])
    back = []
    for f in range(1, n):
        l, h = loud[f], hiss[f]
        for k in LOOKS: em[k] = emit(k, l, h)
        new, bp = [NEG] * S, [0] * S
        for si in range(S):
            best, arg = score[si] + stay[si], si
            for p in prev[si]:
                v = score[p] + go[p]
                if v > best: best, arg = v, p
            if best > NEG / 2:
                new[si] = best + em[units[states[si][0]][0]]
                bp[si] = arg
        back.append(bp)
        score = new
    ends = [S - 1] + [si for si, (ui, _, last) in enumerate(states) if last and ui == len(units) - 2]
    si = max(ends, key=lambda s: score[s])
    path = [si]
    for bp in reversed(back):
        si = bp[si]
        path.append(si)
    path.reverse()
    # frames to sounds
    segs = []  # [unit index, first frame, last frame]
    for f, si in enumerate(path):
        ui = states[si][0]
        if segs and segs[-1][0] == ui:
            segs[-1][2] = f
        else:
            segs.append([ui, f, f])
    out = {}
    for ui, a, b in segs:
        kind, snd, wi, _, _, _ = units[ui]
        if snd is None: continue
        out.setdefault(wi, []).append((snd, a * HOP, (b + 1) * HOP))
    res = []
    for wi, (w, _) in enumerate(words):
        ph = out.get(wi)
        if ph:
            res.append((w, ph[0][1], ph[-1][2], ph))
    return res


def sound_only(loud, hiss):
    """No words known: syllables from the loudness (a vowel at each swell, lips closing between them)."""
    n, res, f = len(loud), [], 0
    sm = [sum(loud[max(0, i - 2):i + 3]) / len(loud[max(0, i - 2):i + 3]) for i in range(n)]
    shapes = ["aa", "eh", "ah", "iy", "ao", "ae", "ow", "ih"]
    while f < n:
        if sm[f] < 0.25:
            f += 1; continue
        a = f
        while f < n and sm[f] >= 0.25: f += 1
        b = f  # a stretch of sound, a..b: split at its dips
        ph, i, k = [], a, 0
        while i < b:
            j = i + 1
            while j < b and not (j - i >= 12 and sm[j] < sm[j - 1] and sm[j] <= sm[min(b - 1, j + 1)] and sm[j] < 0.6):
                j += 1
            mid = max(range(i, j), key=lambda q: sm[q])
            close = "m" if k % 3 == 0 else ("s" if sum(hiss[i:j]) / max(1, j - i) > 1.0 else "d")
            if mid - i >= 3:
                ph.append((close, i * HOP, (i + 3) * HOP))
                ph.append((shapes[(a + k) % len(shapes)], (i + 3) * HOP, j * HOP))
            else:
                ph.append((shapes[(a + k) % len(shapes)], i * HOP, j * HOP))
            i, k = j, k + 1
        res.append(("speech", a * HOP, b * HOP, ph))
    return res


def track_text(text, timed, loud):
    lines = ["VERSION 1.0", "PLAINTEXT", "{", clean_text(text) or "...", "}", "WORDS", "{"]
    for w, a, b, ph in timed:
        lines.append("WORD %s %.3f %.3f" % (re.sub(r"[^a-z0-9']", "", w.lower()) or "x", a, b))
        lines.append("{")
        for s, pa, pb in ph:
            lines.append("%d %s %.3f %.3f 1" % (CODE[s], s, pa, pb))
        lines.append("}")
    lines += ["}", "EMPHASIS", "{"]
    step = max(1, int(0.1 / HOP))  # louder stretches open the mouth wider (the game's strong shapes)
    for i in range(0, len(loud), step):
        seg = loud[i:i + step]
        lines.append("%.4f %.4f" % (i * HOP, 0.35 + 0.35 * (sum(seg) / len(seg))))
    lines += ["}", "OPTIONS", "{", "voice_duck 0", "}", ""]
    return "\n".join(lines)


def bake_wav_bytes(data, text, lex):
    """A .wav's bytes with its phoneme track (any old one replaced). Returns (bytes, words timed)."""
    chunks = read_chunks(data)
    samples, rate, _ = wav_samples(chunks)
    loud, hiss = features(samples, rate)
    words = [(w, sounds_of(w, lex)) for w in words_of(text)]
    timed = align(words, loud, hiss) if words else sound_only(loud, hiss)
    if not timed:
        timed = sound_only(loud, hiss)
    vdat = track_text(text, timed, loud).encode("ascii", "replace")
    kept = [(c, p) for c, p in chunks if c != b"VDAT"]
    return write_chunks(kept + [(b"VDAT", vdat)]), timed


# ---------------------------------------------------------------------------------------------------------
# Which words a recording says
# ---------------------------------------------------------------------------------------------------------
def stem(name):
    return re.sub(r"\d+$", "", os.path.splitext(os.path.basename(name))[0].lower()).rstrip("_")


def load_lines():
    by_path, by_stem = {}, {}

    def add(path, text):
        path = path.lower().replace("\\", "/")
        if path.startswith("livingcity/"): path = path[len("livingcity/"):]
        folder = os.path.dirname(path)
        by_path.setdefault(folder + "/" + stem(path), text)
        by_stem.setdefault(stem(path), text)
    for name in ("voice_batch.tsv", "lipsync_lines.tsv"):
        p = os.path.join(HERE, name)
        if os.path.exists(p):
            for line in open(p, encoding="utf-8"):
                parts = line.rstrip("\n").split("\t")
                if line.startswith("#") or len(parts) < 2: continue
                add(parts[-2], parts[-1])
    hl2 = os.path.join(HERE, "hl2_lines.txt")
    if os.path.exists(hl2):
        folder = None
        for line in open(hl2, encoding="utf-8", errors="replace"):
            line = line.rstrip("\r\n")
            if line.startswith("## "):
                folder = line[line.rfind("(sound/") + 7:].rstrip(")") if "(sound/" in line else None
                continue
            name, _, words = line.partition("\t")
            if folder and name and words.strip():
                by_path.setdefault("hl2/" + folder.rstrip("/") + "/" + os.path.splitext(name.lower())[0], words.strip())
    return by_path, by_stem


def text_for(path, root, lines):
    beside = os.path.splitext(path)[0] + ".txt"
    if os.path.exists(beside):
        return open(beside, encoding="utf-8", errors="replace").read().strip(), "its .txt"
    by_path, by_stem = lines
    rel = os.path.relpath(path, root).replace("\\", "/").lower()
    if rel.startswith("livingcity/"): rel = rel[len("livingcity/"):]
    folder = os.path.dirname(rel)
    exact = folder + "/" + os.path.splitext(os.path.basename(rel))[0]
    if exact in by_path: return by_path[exact], "the scripts"
    if folder + "/" + stem(rel) in by_path: return by_path[folder + "/" + stem(rel)], "the scripts"
    if stem(rel) in by_stem: return by_stem[stem(rel)], "the scripts (by name)"
    return "", None


def sound_root(folder):
    """The folder that plays the part of garrysmod/sound/livingcity/ (or of sound/)."""
    p = os.path.abspath(folder)
    parts = p.replace("\\", "/").split("/")
    if "livingcity" in parts:
        i = len(parts) - 1 - parts[::-1].index("livingcity")
        return "/".join(parts[:i + 1])
    return p


def is_face_folder(path, root):
    rel = os.path.relpath(os.path.dirname(path), root).replace("\\", "/").lower()
    return any(rel == f or rel.startswith(f + "/") for f in FACES)


# ---------------------------------------------------------------------------------------------------------
def to_wav(src, dest, rate):
    if not shutil.which("ffmpeg"):
        return False
    tmp = dest + ".part.wav"
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", src, "-ac", "1", "-ar", str(rate), "-c:a", "pcm_s16le",
                    "-map_metadata", "-1", "-fflags", "+bitexact", tmp], check=False)
    if os.path.exists(tmp) and os.path.getsize(tmp) > 44:
        os.replace(tmp, dest)
        return True
    if os.path.exists(tmp): os.remove(tmp)
    return False


def main():
    ap = argparse.ArgumentParser(description="Write Source's phoneme track (lip sync) into Living City's recordings.")
    ap.add_argument("folder", nargs="?", help="a folder laid out like garrysmod/sound/livingcity/ (or one of its folders)")
    ap.add_argument("--check", action="store_true", help="only say which recordings have a track")
    ap.add_argument("--redo", action="store_true", help="write the track again where there is one")
    ap.add_argument("--all", action="store_true", help="every folder, not only those of people with faces")
    ap.add_argument("--rate", type=int, default=22050, choices=(11025, 22050, 44100),
                    help="sample rate for an .mp3 made into a .wav (default 22050: half the download of 44100)")
    ap.add_argument("--update-lines", action="store_true", help="(a chat) rewrite lipsync_lines.tsv from VOICE_SCRIPTS.md")
    ap.add_argument("--update-dict", metavar="CMUDICT", help="(a chat) add every script's words to lipsync_dict.txt")
    ap.add_argument("--selftest", action="store_true", help="check the tool on a made-up recording")
    a = ap.parse_args()
    if a.selftest: return selftest()
    if a.update_lines: return update_lines()
    if a.update_dict: return update_dict(a.update_dict)
    if not a.folder or not os.path.isdir(a.folder):
        ap.error("give the folder your recordings are in (laid out like garrysmod/sound/livingcity/)")
    root = sound_root(a.folder)
    lex, lines = load_dict(), load_lines()
    found = []
    for d, _, files in os.walk(a.folder):
        for f in sorted(files):
            if os.path.splitext(f)[1].lower() in AUDIO:
                found.append(os.path.join(d, f))
    have = {os.path.splitext(p)[0] + os.path.splitext(p)[1].lower() for p in found}
    done = skipped = failed = made = 0
    words_from = {"its .txt": 0, "the scripts": 0, "the scripts (by name)": 0, None: 0}
    no_ffmpeg = []
    for path in found:
        ext = os.path.splitext(path)[1].lower()
        if not a.all and not is_face_folder(path, root):
            continue
        wav = os.path.splitext(path)[0] + ".wav"
        if ext != ".wav" and (wav in have or os.path.exists(wav)):
            continue  # (its .wav is already there: that is the one baked)
        if a.check:
            if ext == ".wav":
                try:
                    ok = has_track(read_chunks(open(path, "rb").read()))
                except ValueError as e:
                    ok = "unreadable (%s)" % e
                print("%-60s %s" % (os.path.relpath(path, root), "track" if ok is True else (ok or "no track")))
            else:
                print("%-60s %s" % (os.path.relpath(path, root), "no track (an %s: made into a .wav when baked)" % ext))
            continue
        if ext != ".wav":
            if not to_wav(path, wav, a.rate):
                no_ffmpeg.append(path)
                continue
            made += 1
        data = open(wav, "rb").read()
        try:
            chunks = read_chunks(data)
            if has_track(chunks) and not a.redo:
                skipped += 1
                continue
            text, src = text_for(path, root, lines)
            words_from[src] += 1
            out, timed = bake_wav_bytes(data, text, lex)
            # the sound itself must be untouched
            if [p for c, p in read_chunks(out) if c == b"data"] != [p for c, p in chunks if c == b"data"]:
                raise ValueError("the sound changed while writing (left as it was)")
            tmp = wav + ".part"
            open(tmp, "wb").write(out)
            os.replace(tmp, wav)
            done += 1
            print("%4d  %-56s %s" % (done, os.path.relpath(wav, root), " ".join(w for w, *_ in timed)[:60] if text else "(no words known: from the sound alone)"))
        except ValueError as e:
            failed += 1
            print("  could not bake %s: %s" % (os.path.relpath(wav, root), e))
    if a.check:
        return 0
    print("\n%d baked (%d .mp3/.ogg made into .wav), %d already had a track, %d failed." % (done, made, skipped, failed))
    print("Words from the scripts: %d, from a .txt beside: %d, none known (sound alone): %d" % (
        words_from["the scripts"] + words_from["the scripts (by name)"], words_from["its .txt"], words_from[None]))
    if no_ffmpeg:
        print("%d .mp3/.ogg files were left: ffmpeg is needed to make them .wav (sudo apt install ffmpeg), then run this again." % len(no_ffmpeg))
    if done:
        print("Upload the .wav files to the server's garrysmod/sound/livingcity/ (the same folders), press FastDL sync, change the map.")
    return 0


# ---------------------------------------------------------------------------------------------------------
# For a chat: the generated lists, and a check
# ---------------------------------------------------------------------------------------------------------
def update_lines():
    sys.path.insert(0, os.path.dirname(HERE))
    import voice_lines
    doc = open(os.path.join(ROOT, "VOICE_SCRIPTS.md"), encoding="utf-8").read().splitlines()
    rows, folder = {}, None
    for line in doc:
        if line.startswith("## "):
            folder = voice_lines.scripts_folder(line)
            continue
        if not folder or not line.startswith("| ["):
            continue
        cells = [c.strip() for c in line.split("|")]
        if len(cells) < 5:
            continue
        text = clean_text(cells[-2])
        names = re.findall(r"`([^`]+)`", cells[2])  # (the file; a second column may hold a woman's take)
        names += [n for n in re.findall(r"`([^`]+)`", "|".join(cells[3:-2])) if n.lower().endswith(AUDIO)]
        for name in names:
            if "/" in name or "<" in name or not text:
                continue
            key = "livingcity/" + folder + os.path.splitext(name.lower())[0]
            rows.setdefault(key, text)
    with open(LINES, "w", encoding="utf-8") as f:
        f.write("# made by python3 _dev/tools/lipsync_bake.py --update-lines from VOICE_SCRIPTS.md: file, words\n")
        for k in sorted(rows):
            f.write("%s\t%s\n" % (k, rows[k]))
    print("%d lines written to %s" % (len(rows), LINES))
    return 0


def update_dict(cmudict):
    texts = []
    for p in (LINES, os.path.join(HERE, "voice_batch.tsv")):
        if os.path.exists(p):
            texts += [l.rstrip("\n").split("\t")[-1] for l in open(p, encoding="utf-8") if not l.startswith("#")]
    hl2 = os.path.join(HERE, "hl2_lines.txt")
    if os.path.exists(hl2):
        texts += [l.partition("\t")[2] for l in open(hl2, encoding="utf-8", errors="replace")]
    want = {w for t in texts for w in words_of(t)} | set(SMALL) | set(TENS[2:]) | {"hundred"}
    full = load_dict(cmudict)
    old = load_dict()
    keep = {w: old[w] for w in old}
    for w in want:
        if w in full: keep.setdefault(w, full[w])
    with open(DICT, "w", encoding="utf-8") as f:
        f.write(";; The words of Living City's voice lines, from the CMU Pronouncing Dictionary (cmudict 1.1.3).\n")
        f.write(";; Made by python3 _dev/tools/lipsync_bake.py --update-dict. The dictionary's licence:\n")
        f.write(";; Copyright (C) 1993-2015 Carnegie Mellon University. All rights reserved. Redistribution and use in\n")
        f.write(";; source and binary forms, with or without modification, are permitted provided that the copyright\n")
        f.write(";; notice, this list of conditions and the disclaimer are retained. THIS SOFTWARE IS PROVIDED BY\n")
        f.write(";; CARNEGIE MELLON UNIVERSITY ''AS IS'' AND ANY EXPRESSED OR IMPLIED WARRANTIES ARE DISCLAIMED.\n")
        for w in sorted(keep):
            f.write("%s %s\n" % (w, " ".join(keep[w])))
    print("%d words in %s (%d of the scripts' words the dictionary lacks: guessed from their letters)" % (
        len(keep), DICT, len(want - set(keep))))
    return 0


def selftest():
    rate = 22050
    # two "words": a loud vowel-like hum, silence, then a hiss and a hum
    def tone(sec, f, amp):
        return [int(amp * math.sin(2 * math.pi * f * i / rate)) for i in range(int(sec * rate))]
    import random
    random.seed(1)
    hiss = [int(random.uniform(-2500, 2500)) for _ in range(int(0.15 * rate))]
    pcm = tone(0.2, 0, 0) + tone(0.35, 180, 12000) + tone(0.25, 0, 0) + hiss + tone(0.3, 200, 11000) + tone(0.2, 0, 0)
    raw = array.array("h", pcm)
    if sys.byteorder == "big": raw.byteswap()
    fmt = struct.pack("<HHIIHH", 1, 1, rate, rate * 2, 2, 16)
    wav = write_chunks([(b"fmt ", fmt), (b"LIST", b"INFOISFT\x04\x00\x00\x00test"), (b"data", raw.tobytes())])
    out, timed = bake_wav_bytes(wav, "[calm] Ah. So!", {"ah": ["AA1"], "so": ["S", "OW1"]})
    chunks = read_chunks(out)
    probs = []
    if [c for c, _ in chunks] != [b"fmt ", b"LIST", b"data", b"VDAT"]: probs.append("chunks: %r" % [c for c, _ in chunks])
    if next(p for c, p in chunks if c == b"data") != raw.tobytes(): probs.append("the sound changed")
    vdat = next(p for c, p in chunks if c == b"VDAT").decode()
    if not vdat.startswith("VERSION 1.0\nPLAINTEXT\n{\nAh. So!\n}\nWORDS\n{\nWORD ah "): probs.append("track: " + vdat[:80])
    words = {w: (a, b) for w, a, b, _ in timed}
    if not (0.15 <= words.get("ah", (0, 0))[0] <= 0.3): probs.append("'ah' starts at %.2f, not about 0.2" % words.get("ah", (0, 0))[0])
    if not (0.75 <= words.get("so", (0, 0))[0] <= 0.9): probs.append("'so' starts at %.2f, not about 0.8" % words.get("so", (0, 0))[0])
    so = dict((s, (a, b)) for s, a, b in timed[-1][3])
    if "s" not in so or not (so["s"][0] < so["ow"][0]): probs.append("'so': the hiss is not before the vowel: %r" % timed[-1][3])
    if "%d s " % 115 not in vdat or "%d ow " % 111 not in vdat: probs.append("codes")
    again, _ = bake_wav_bytes(out, "Ah. So!", {"ah": ["AA1"], "so": ["S", "OW1"]})
    if [c for c, _ in read_chunks(again)].count(b"VDAT") != 1: probs.append("baking twice made two tracks")
    alone = sound_only(*features(pcm, rate))
    if len(alone) < 2: probs.append("from the sound alone: %d stretches, not 2" % len(alone))
    if guess_sounds("Kleiner")[:2] != ["c", "l"] or sounds_of("hello", {"hello": ["HH", "AH0", "L", "OW1"]}) != ["hh", "ax", "l", "ow"]:
        probs.append("words to sounds")
    if words_of("[sad] I'm 25, Mrs-Smith.") != ["i'm", "twenty", "five", "mrs", "smith"]: probs.append("words: %r" % words_of("[sad] I'm 25, Mrs-Smith."))
    print("LIPSYNC SELFTEST " + ("PASS" if not probs else "FAIL\n  " + "\n  ".join(probs)))
    return 1 if probs else 0


if __name__ == "__main__":
    sys.exit(main() or 0)
