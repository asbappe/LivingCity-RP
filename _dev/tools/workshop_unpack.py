#!/usr/bin/env python3
"""Living City: read Workshop items without gmad (for the owner's PC, never the server).

    python3 workshop_unpack.py                 the three animation items
    python3 workshop_unpack.py 123456 234567   any other items, by number

For each item Steam has downloaded it writes, in ~/lc_workshop/NUMBER/:
    files.txt       every file in the item
    sequences.txt   every animation name in each of its models
    text/           its Lua and other small text files
and puts all of that in ~/lc_workshop/lc_workshop_lists.zip, the one file to send.
Models, sounds and pictures are never copied out: only their names are listed.
"""
import lzma
import os
import struct
import subprocess
import sys
import zipfile

DEFAULT_IDS = ["3830765710", "2538387266", "2615656036"]
OUT = os.path.expanduser("~/lc_workshop")
TEXT_EXT = (".lua", ".txt", ".json", ".properties", ".vmt", ".qc", ".qci")
TEXT_MAX = 2 * 1024 * 1024
SEQDESC = 212


def workshop_roots():
    """Every steamapps/workshop/content/4000 folder on this PC."""
    places = [os.path.expanduser("~")] + [p for p in ("/media", "/mnt", "/run/media") if os.path.isdir(p)]
    try:
        out = subprocess.run(["find"] + places + ["-type", "d", "-path", "*/workshop/content/4000"],
                             capture_output=True, text=True, timeout=300).stdout
    except (OSError, subprocess.SubprocessError):
        out = ""
    return [line for line in out.splitlines() if line]


def open_gma(folder, work):
    """The item's addon file, opened for reading (a .bin is unpacked into WORK first)."""
    names = sorted(os.listdir(folder), key=lambda n: -os.path.getsize(os.path.join(folder, n)))
    for name in names:
        path = os.path.join(folder, name)
        if not os.path.isfile(path):
            continue
        with open(path, "rb") as f:
            if f.read(4) == b"GMAD":
                return open(path, "rb")
        plain = os.path.join(work, "addon.gma")
        try:
            with lzma.open(path) as src, open(plain, "wb") as dst:
                while True:
                    chunk = src.read(1 << 20)
                    if not chunk:
                        break
                    dst.write(chunk)
        except (lzma.LZMAError, EOFError, OSError):
            continue
        with open(plain, "rb") as f:
            if f.read(4) == b"GMAD":
                return open(plain, "rb")
    return None


def cstring(f):
    out = bytearray()
    while True:
        c = f.read(1)
        if not c or c == b"\0":
            return out.decode("utf-8", "replace")
        out += c


def read_index(f):
    """[(name, offset, size)] for every file in an open addon."""
    f.seek(4)
    version = f.read(1)[0]
    f.read(16)
    if version > 1:
        while cstring(f):
            pass
    cstring(f), cstring(f), cstring(f)
    f.read(4)
    entries = []
    while True:
        num = struct.unpack("<I", f.read(4))[0]
        if num == 0:
            break
        name = cstring(f)
        size = struct.unpack("<q", f.read(8))[0]
        f.read(4)
        entries.append((name, size))
    start, out = f.tell(), []
    for name, size in entries:
        out.append((name, start, size))
        start += size
    return out


def label(data, at):
    end = data.find(b"\0", at, at + 200)
    if at <= 0 or end < 0:
        return None
    text = data[at:end].decode("ascii", "replace")
    return text if text and all(32 <= ord(c) < 127 for c in text) else None


def sequences(data):
    """The animation names in a .mdl, or None when it is not laid out as expected."""
    if len(data) < 408 or data[:4] != b"IDST":
        return None
    version = struct.unpack_from("<i", data, 4)[0]
    count, index = struct.unpack_from("<ii", data, 188)
    if not 44 <= version <= 49 or not 0 <= count < 50000:
        return None
    if count and not 0 < index <= len(data) - count * SEQDESC:
        return None
    out = []
    for i in range(count):
        base = index + i * SEQDESC
        name_at, act_at = struct.unpack_from("<ii", data, base + 4)
        name = label(data, base + name_at)
        if name is None:
            return None
        act = label(data, base + act_at) or ""
        out.append(name + ("\t" + act if act else ""))
    return out


def loose_strings(data):
    """Every readable word in a model: the fallback when its layout is unknown."""
    out, word = [], bytearray()
    for b in data:
        if 32 <= b < 127:
            word.append(b)
        else:
            if len(word) >= 4:
                out.append(word.decode("ascii"))
            word = bytearray()
    return out


def safe(name):
    parts = [p for p in name.replace("\\", "/").split("/") if p not in ("", ".", "..")]
    return os.path.join(*parts) if parts else None


def unpack(item, roots):
    folder = next((os.path.join(r, item) for r in roots if os.path.isdir(os.path.join(r, item))), None)
    if not folder:
        print(f"{item}: NOT DOWNLOADED. Subscribe to it, start Garry's Mod to the main menu, quit, run this again.")
        return False
    work = os.path.join(OUT, item)
    os.makedirs(work, exist_ok=True)
    f = open_gma(folder, work)
    if not f:
        print(f"{item}: no addon file found in {folder}")
        return False
    with f:
        index = read_index(f)
        with open(os.path.join(work, "files.txt"), "w") as out:
            out.write("\n".join(sorted(n for n, _, _ in index)) + "\n")
        models = total = texts = 0
        with open(os.path.join(work, "sequences.txt"), "w") as out:
            for name, at, size in index:
                low = name.lower()
                if low.endswith(".mdl"):
                    f.seek(at)
                    data = f.read(size)
                    names = sequences(data)
                    models += 1
                    if names is None:
                        out.write(f"== {name} (layout not read: every word in it)\n")
                        names = loose_strings(data)
                    else:
                        out.write(f"== {name} ({len(names)} animations)\n")
                        total += len(names)
                    out.write("\n".join(names) + "\n\n")
                elif low.endswith(TEXT_EXT) and size <= TEXT_MAX:
                    rel = safe(name)
                    if not rel:
                        continue
                    path = os.path.join(work, "text", rel)
                    os.makedirs(os.path.dirname(path), exist_ok=True)
                    f.seek(at)
                    with open(path, "wb") as dst:
                        dst.write(f.read(size))
                    texts += 1
    plain = os.path.join(work, "addon.gma")
    if os.path.exists(plain):
        os.remove(plain)
    print(f"{item}: {len(index)} files, {models} models, {total} animations, {texts} text files")
    return True


def main():
    items = [a for a in sys.argv[1:] if a.isdigit()] or DEFAULT_IDS
    os.makedirs(OUT, exist_ok=True)
    roots = workshop_roots()
    if not roots:
        print("No Steam Workshop folder for Garry's Mod was found on this PC.")
        return 1
    done = [item for item in items if unpack(item, roots)]
    if not done:
        return 1
    target = os.path.join(OUT, "lc_workshop_lists.zip")
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as z:
        for item in done:
            for base, _, names in os.walk(os.path.join(OUT, item)):
                for name in names:
                    path = os.path.join(base, name)
                    z.write(path, os.path.relpath(path, OUT))
    print(f"Send this file: {target} ({os.path.getsize(target) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
