#!/usr/bin/env python3
"""Living City: make every generated voice line with ElevenLabs in one go.

Reads _dev/tools/voice_batch.tsv (made by python3 _dev/voice_lines.py: which voice, which file, what to say)
and asks ElevenLabs' text to speech for each line, saving it under its right name in a folder laid out like
the server's garrysmod/sound/. Nothing but Python 3 is needed (ffmpeg only for the G-Man's .wav files).

    export ELEVENLABS_API_KEY='your key'
    python3 _dev/tools/elevenlabs_batch.py --man ID --woman ID --dry-run
    python3 _dev/tools/elevenlabs_batch.py --man ID --woman ID --limit 3
    python3 _dev/tools/elevenlabs_batch.py --man ID --woman ID --unit ID --administrator ID --gman ID

The key is read from the ELEVENLABS_API_KEY setting of the terminal, never from a file, and is not printed.
A file that is already there is skipped, so it can be stopped and run again.
"""
import argparse, json, os, re, shutil, subprocess, sys, time, urllib.error, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
URL = "https://api.elevenlabs.io/v1/text-to-speech/%s?output_format=%s"
VOICES = ["man", "woman", "unit", "administrator", "gman", "soldier", "overwatch"]
RADIO = ("unit", "soldier")  # recorded clean, then given their radio sound by unit_radio.sh


def rows():
    out = []
    with open(os.path.join(HERE, "voice_batch.tsv"), encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) == 3:
                out.append(parts)
    return out


HL2_VOICE = {"vo/npc/male01/": "man", "vo/npc/female01/": "woman", "npc/metropolice/vo/": "unit",
             "npc/combine_soldier/vo/": "soldier", "npc/overwatch/cityvoice/": "overwatch", "npc/overwatch/radiovoice/": "overwatch"}


def hl2_rows(path):
    """data/livingcity/hl2_lines.txt (the server's lc_hl2_lines): every Half-Life 2 clip and its words.
    Each becomes a file at livingcity/hl2/<the clip's own path>, which the game plays in the clip's place."""
    out, nowords, folder = [], [], None
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.rstrip("\r\n")
            if line.startswith("## "):
                folder = line[line.rfind("(sound/") + 7:].rstrip(")") if "(sound/" in line else None
                continue
            if not line or folder not in HL2_VOICE:
                continue
            name, _, words = line.partition("\t")
            base = name.rsplit(".", 1)[0]
            words = words.strip()
            if not words:
                nowords.append(folder + name)
                continue
            out.append([HL2_VOICE[folder], "livingcity/hl2/" + folder + base, words])
    return out, nowords


def stem(name):
    """A file's line: its name without the take number or the Administrator's tone word."""
    return re.sub(r"(_(firm|stern|furious))?\d*$", "", name.lower())


def missing_set(path):
    """data/livingcity/voice_missing.txt (the server's lc_voice_missing): folder/name, one to a line."""
    out = set()
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip().lower()
            if "/" in line:
                folder, _, name = line.rpartition("/")
                out.add("livingcity/" + folder + "/" + stem(name))
    return out


def speak(key, voice_id, model, fmt, text):
    body = json.dumps({"text": text, "model_id": model}).encode("utf-8")
    req = urllib.request.Request(URL % (voice_id, fmt), data=body, method="POST",
                                 headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()


def main():
    ap = argparse.ArgumentParser(description="Make Living City's generated voice lines with ElevenLabs.")
    for v in VOICES:
        ap.add_argument("--" + v, metavar="VOICE_ID", help="the ElevenLabs voice id for the %s (left out: those lines are skipped)" % v)
    ap.add_argument("--hl2", metavar="FILE", help="make Half-Life 2's own lines instead: the hl2_lines.txt that lc_hl2_lines wrote on the server")
    ap.add_argument("--missing", metavar="FILE", help="make only what the server lacks: the voice_missing.txt that lc_voice_missing wrote on the server")
    ap.add_argument("--out", default="voice_out", help="where to put the files (default: voice_out)")
    ap.add_argument("--model", default="eleven_v4", help="the ElevenLabs model (default: eleven_v4)")
    ap.add_argument("--format", default="mp3_44100_128", help="the sound format asked for (default: mp3_44100_128)")
    ap.add_argument("--takes", type=int, default=1, help="how many takes of each line (2 also makes ...2)")
    ap.add_argument("--limit", type=int, default=0, help="make only this many new files, then stop (to listen first)")
    ap.add_argument("--extras", action="store_true", help="also the G-Man lines that are not in the game yet (needs --gman)")
    ap.add_argument("--dry-run", action="store_true", help="make nothing: say how many lines and characters would be sent")
    ap.add_argument("--pause", type=float, default=0.6, help="seconds to wait between lines (default 0.6)")
    a = ap.parse_args()

    ids = {v: getattr(a, v) for v in VOICES}
    ids["gman_extra"] = a.gman if a.extras else None
    todo, chars, skipped_voice = [], 0, {}
    source = rows()
    if a.hl2:
        source, nowords = hl2_rows(a.hl2)
        if nowords:
            print("%d clips have no words in the list (grunts, noises, or lines the caption file does not give): left out. First few: %s"
                  % (len(nowords), ", ".join(nowords[:5])))
    if a.missing and not a.hl2:
        want = missing_set(a.missing)
        before = len(source)
        source = [row for row in source if row[0] in ("gman", "gman_extra")
                  or (os.path.dirname(row[1]) + "/" + stem(os.path.basename(row[1]))) in want]
        print("the server already has %d of these lines: left out" % (before - len(source)))
    for voice, path, text in source:
        if not ids.get(voice):
            skipped_voice[voice] = skipped_voice.get(voice, 0) + 1
            continue
        for take in range(1, max(1, a.takes) + 1):
            p = path
            if take > 1:
                p = path[:-1] + str(take) if path[-1] == "1" else path + str(take)
            if voice in RADIO:  # clean recordings: unit_radio.sh makes the ones the game uses
                sub = "units_clean" if not a.hl2 else os.path.join("radio_clean", os.path.dirname(p))
                dest = os.path.join(a.out, sub, os.path.basename(p) + ".mp3")
            else:
                dest = os.path.join(a.out, "sound", p + ".mp3")
            wav = voice in ("gman", "gman_extra")
            final = dest[:-4] + ".wav" if wav else dest
            if os.path.exists(final) or os.path.exists(dest):
                continue
            todo.append((voice, dest, final if wav else None, text))
            chars += len(text)

    for v, n in sorted(skipped_voice.items()):
        if v != "gman_extra":
            print("no --%s given: %d lines left out" % (v, n))
    print("%d files to make, %d characters (%s)" % (len(todo), chars, a.model))
    if a.dry_run or not todo:
        return 0
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key:
        print("Set the key first:  export ELEVENLABS_API_KEY='your key'")
        return 1
    have_ffmpeg = shutil.which("ffmpeg") is not None
    made = 0
    for voice, dest, wav, text in todo:
        if a.limit and made >= a.limit:
            print("stopped at --limit %d: listen to them, then run it again for the rest" % a.limit)
            break
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        ident = ids[voice]
        for attempt in range(3):
            try:
                data = speak(key, ident, a.model, a.format, text)
                break
            except urllib.error.HTTPError as e:
                msg = e.read().decode("utf-8", "replace")[:400]
                if e.code == 429 and attempt < 2:
                    print("  ElevenLabs asks to slow down: waiting 20 seconds")
                    time.sleep(20)
                    continue
                print("ElevenLabs said %d for %s:\n  %s" % (e.code, dest, msg))
                print("Nothing more was sent. Fix that (the key, the voice id, the model's name, or your plan's allowance) and run it again.")
                return 1
            except (urllib.error.URLError, TimeoutError) as e:
                if attempt < 2:
                    time.sleep(5)
                    continue
                print("could not reach ElevenLabs: %s" % e)
                return 1
        if len(data) < 500:
            print("ElevenLabs sent almost nothing for %s: not saved" % dest)
            continue
        with open(dest, "wb") as f:
            f.write(data)
        if wav:
            if have_ffmpeg:
                subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", dest, "-ar", "44100", "-ac", "1", "-c:a", "pcm_s16le", wav], check=False)
                if os.path.exists(wav):
                    os.remove(dest)
            else:
                print("  (%s is an .mp3: the G-Man's files must be .wav. Install ffmpeg and run this again, or convert it in Audacity.)" % dest)
        made += 1
        print("%4d  %s" % (made, wav if (wav and os.path.exists(wav)) else dest))
        time.sleep(max(0.0, a.pause))
    print("made %d files in %s" % (made, a.out))
    if a.hl2:
        for d in sorted({os.path.dirname(dest) for v, dest, _, _ in todo if v in RADIO}):
            rel = os.path.relpath(d, os.path.join(a.out, "radio_clean"))
            print("radio voices are clean in %s: now run\n  bash _dev/tools/unit_radio.sh %s %s" % (d, d, os.path.join(a.out, "sound", rel)))
    elif any(v == "unit" for v, _, _, _ in todo):
        print("unit lines are in %s/units_clean: now run\n  bash _dev/tools/unit_radio.sh %s/units_clean %s/sound/livingcity/units" % (a.out, a.out, a.out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
