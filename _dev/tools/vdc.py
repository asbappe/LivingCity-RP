#!/usr/bin/env python3
"""Read the saved Valve Developer Community wiki (_dev/reference/vdc/vdc_wiki.zip).

10,220 pages saved by the owner on 21 November with VDC Saver (_dev/tools/vdc_saver/): HL2, the Episodes,
Garry's Mod and Source 1 only (other games and translations left out), as wikitext, with each page's
categories. Read narrowly: one page or a search at a time, never the whole thing.

  python3 _dev/tools/vdc.py --card func_door     START HERE for an entity: what it is, every keyvalue, flag,
                                                 input and output in short, its bugs and warnings, how often
                                                 Valve's HL2/EP1/EP2 maps use it, the map lessons naming it
  python3 _dev/tools/vdc.py --search door areaportal   the best pages for a question, a line on each
  python3 _dev/tools/vdc.py --gotchas areaportal every bug, warning and workaround on a topic, wiki-wide
  python3 _dev/tools/vdc.py --entities light     entity pages, most used by Valve first, a line on each
  python3 _dev/tools/vdc.py func_door            the whole page, with its KV/I/O/Fl templates filled in
  python3 _dev/tools/vdc.py func_door --raw      the page as saved
  python3 _dev/tools/vdc.py func_door --from 200 long pages come 200 lines at a time (--lines N)
  python3 _dev/tools/vdc.py --find door rotating page names holding all the words
  python3 _dev/tools/vdc.py --grep 'areaportal'  matching lines in every page (regex, any case; --max N)
  python3 _dev/tools/vdc.py --cat "Brush Entities"  the pages in a category
  python3 _dev/tools/vdc.py --info func_door     categories, revision, size
  python3 _dev/tools/vdc.py --import ~/vdc_wiki.zip   replace the saved wiki with a newer VDC Saver zip
"""
import argparse
import difflib
import io
import os
import re
import sys
import zipfile

sys.dont_write_bytecode = True  # no __pycache__ beside the tools
EM = chr(0x2014)  # the em dash, built here so no file of ours holds its bytes (house rule 1's repo-wide check)

ZIP = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'reference', 'vdc', 'vdc_wiki.zip'))
# Templates that hold an entity's keyvalues, inputs, outputs and flags ({{KV Door}}, {{I BaseEntity}}...).
EXPAND = re.compile(r'^(KV|I|O|Fl|IO)\s+\S', re.I)
PARAM = re.compile(r'\{\{\{([^{}|]+)(?:\|([^{}]*))?\}\}\}')


def key(title):
    t = title.replace('_', ' ').replace(EM, '-').strip().lower()
    return re.sub(r'\s+', ' ', t)


def calls(text):
    """Top-level {{...}} in text: (start, end, inside)."""
    i, n = 0, len(text)
    while True:
        s = text.find('{{', i)
        if s < 0:
            return
        depth, j = 0, s
        while j < n:
            if text.startswith('{{', j):
                depth += 1
                j += 2
            elif text.startswith('}}', j):
                depth -= 1
                j += 2
                if depth == 0:
                    break
            else:
                j += 1
        yield s, j, text[s + 2:j - 2]
        i = j


def split_args(inside):
    parts, depth, cur = [], 0, []
    i = 0
    while i < len(inside):
        two = inside[i:i + 2]
        if two in ('{{', '[['):
            depth += 1
            cur.append(two)
            i += 2
            continue
        if two in ('}}', ']]'):
            depth -= 1
            cur.append(two)
            i += 2
            continue
        if inside[i] == '|' and depth == 0:
            parts.append(''.join(cur))
            cur = []
        else:
            cur.append(inside[i])
        i += 1
    parts.append(''.join(cur))
    name, args, pos = parts[0].strip(), {}, 0
    for p in parts[1:]:
        m = re.match(r'\s*([^=|{}\[\]]+?)\s*=(.*)$', p, re.S)
        if m:
            args[m.group(1)] = m.group(2).strip()
        else:
            pos += 1
            args[str(pos)] = p.strip()
    return name, args


def template_body(t):
    if '<onlyinclude>' in t:
        return '\n'.join(re.findall(r'<onlyinclude>(.*?)</onlyinclude>', t, re.S))
    t = re.sub(r'<noinclude>.*?(</noinclude>|$)', '', t, flags=re.S)
    return t.replace('<includeonly>', '').replace('</includeonly>', '')


def subst(body, args):
    for _ in range(10):
        new = PARAM.sub(lambda m: args.get(m.group(1).strip(), m.group(2) if m.group(2) is not None else ''), body)
        if new == body:
            break
        body = new
    return body


class Wiki:
    def __init__(self, path=ZIP):
        if not os.path.exists(path):
            sys.exit('No saved wiki at ' + path)
        self.z = zipfile.ZipFile(path)
        self.rows, self.by_key = [], {}
        for line in self.z.read('vdc/index.tsv').decode('utf-8').splitlines()[1:]:
            f = (line.split('\t') + [''] * 7)[:7]
            r = dict(path=f[0], title=f[1], ns=f[2], kind=f[3], rev=f[4], ts=f[5], cats=[c for c in f[6].split('; ') if c])
            self.rows.append(r)
            k = key(r['title'])
            if r['kind'] == 'wikitext' or k not in self.by_key:
                self.by_key[k] = r

    def read(self, r):
        return self.z.read('vdc/' + r['path']).decode('utf-8', errors='replace')

    def find_page(self, name):
        for k in (key(name), key('Template:' + name), key('Category:' + name)):
            if k in self.by_key:
                return self.by_key[k]
        k = key(name)
        near = [t for t in self.by_key if k in t][:15] or difflib.get_close_matches(k, list(self.by_key), 15, 0.6)
        print('No page "%s". Close: %s' % (name, ', '.join(self.by_key[t]['title'] for t in near) or 'none'))
        sys.exit(1)

    def expand(self, text, depth=0):
        out, last = [], 0
        for s, e, inside in calls(text):
            name, args = split_args(inside)
            name = name.replace('{{langprefix}}', '').strip()
            r = None
            if depth < 4 and EXPAND.match(name):
                r = self.by_key.get(key('Template:' + name))
            elif 0 < depth < 4 and name.startswith(':'):  # a page a template pulls in ({{KV Targetname}})
                r = self.by_key.get(key(name[1:]))
            if r:
                body = self.expand(subst(template_body(self.read(r)), args), depth + 1).strip('\n')
                out.append(text[last:s])
                out.append('<!-- from %s -->\n%s' % (r['title'], body))
                last = e
        out.append(text[last:])
        return ''.join(out)


def show(w, name, raw, start, count):
    r = w.find_page(name)
    text = w.read(r)
    if not raw:
        text = re.sub(r'^\{\{LanguageBar[^}]*\}\}\n?', '', text, flags=re.M)
        text = w.expand(text)
    lines = text.splitlines()
    a = max(1, start)
    b = min(len(lines), a + count - 1)
    print('# %s  (%d lines; categories: %s)' % (r['title'], len(lines), '; '.join(r['cats']) or 'none'))
    print('\n'.join(lines[a - 1:b]))
    if b < len(lines):
        print('... %d more lines: --from %d' % (len(lines) - b, b + 1))


LANGS = set(('ar bg ca cs da de el eo es et fa fi fr he hi hr hu id it ja ka ko lt lv ms nl no pl pt pt-br pt-pt ro ru '
             'sk sl sr sv th tr uk vi zh zh-cn zh-hans zh-hant zh-hk zh-tw').split())
HELPER = re.compile(r'^(Template:TranslationMark/|SteamVR|Destinations/)', re.I)


def left_out(title):
    """Pages an import leaves out: translations (Func_door/de, Ru/Dimensions) and Source 2 SteamVR/helper pages."""
    if HELPER.match(title):
        return True
    if '/' not in title:
        return False
    name = title.split(':', 1)[1] if ':' in title.split('/', 1)[0] else title
    return title.rsplit('/', 1)[1] in LANGS or name.split('/', 1)[0].lower() in LANGS


def import_zip(src, dst=ZIP):
    """A VDC Saver zip into the reference: em dashes become " - " (house rule), and the packed file must not
    hold the em dash's bytes by chance either (the repo-wide check would find them)."""
    em = EM
    zin = zipfile.ZipFile(src)
    if 'vdc/index.tsv' not in zin.namelist():
        sys.exit(src + ' is not a VDC Saver zip (no vdc/index.tsv)')
    index = zin.read('vdc/index.tsv').decode('utf-8', errors='replace').splitlines()
    drop = {'vdc/' + ln.split('\t')[0] for ln in index[1:] if left_out((ln.split('\t') + ['', ''])[1])}
    entries = []
    for info in zin.infolist():
        if info.is_dir() or info.filename in drop:
            continue
        data = zin.read(info).decode('utf-8', errors='replace').replace(em, ' - ')
        if info.filename == 'vdc/index.tsv':
            data = '\n'.join([index[0]] + [ln for ln in index[1:] if 'vdc/' + ln.split('\t')[0] not in drop]).replace(em, ' - ') + '\n'
        if info.filename == 'vdc/README.txt':
            data = data.rstrip('\n') + ('\nEm dashes were changed to " - " (the project\'s house rule); %d translations and SteamVR/helper '
                                         'pages were left out. Read it with python3 _dev/tools/vdc.py.\n' % len(drop))
        entries.append((info.filename.replace(em, '-'), data.encode('utf-8')))
    entries.sort()
    for level in range(9, 0, -1):
        buf = io.BytesIO()
        with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED, compresslevel=level) as z:
            for name, data in entries:
                zi = zipfile.ZipInfo(name, date_time=(2026, 11, 21, 0, 0, 0))
                zi.compress_type = zipfile.ZIP_DEFLATED
                z.writestr(zi, data, compresslevel=level)
        if b'\xe2\x80\x94' not in buf.getvalue():
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            with open(dst, 'wb') as f:
                f.write(buf.getvalue())
            print('Saved %d files (%.1f MB) to %s' % (len(entries), len(buf.getvalue()) / 1e6, dst))
            return
    sys.exit('Could not pack it without the em dash bytes at any level; nothing changed')


def main():
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        import signal
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # piping into head is fine
    except Exception:
        pass
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('name', nargs='*', help='a page name (any case, spaces or underscores)')
    ap.add_argument('--raw', action='store_true', help='the page as saved, templates not filled in')
    ap.add_argument('--from', dest='start', type=int, default=1, help='first line to show')
    ap.add_argument('--lines', type=int, default=200, help='how many lines to show')
    ap.add_argument('--find', action='store_true', help='list page names holding all the words given')
    ap.add_argument('--grep', metavar='REGEX', help='matching lines in every page')
    ap.add_argument('--cat', metavar='CATEGORY', help='the pages in a category')
    ap.add_argument('--info', action='store_true', help='a page\'s categories, revision and size')
    ap.add_argument('--card', action='store_true', help='an entity or page in short, with Valve\'s use and the lessons')
    ap.add_argument('--search', action='store_true', help='the best pages for the words given')
    ap.add_argument('--gotchas', action='store_true', help='bugs, warnings and workarounds about the words given')
    ap.add_argument('--entities', action='store_true', help='entity pages (filtered by the words given)')
    ap.add_argument('--max', type=int, default=40, help='most results to list')
    ap.add_argument('--import', dest='import_zip', metavar='ZIP', help='replace the saved wiki with this VDC Saver zip')
    a = ap.parse_args()
    if a.import_zip:
        return import_zip(a.import_zip)
    w = Wiki()
    name = ' '.join(a.name)

    if a.card or a.search or a.gotchas or a.entities:
        import vdc_find
        if a.card:
            vdc_find.card(w, name)
        elif a.search:
            vdc_find.search(w, a.name, a.max if a.max != 40 else 12)
        elif a.gotchas:
            vdc_find.gotchas(w, a.name, a.max)
        else:
            vdc_find.entities(w, a.name, a.max)
    elif a.find:
        words = [x.lower() for x in a.name]
        hits = sorted({r['title'] for r in w.rows if all(x in r['title'].lower() for x in words)}, key=len)
        print('%d pages' % len(hits) + (', first %d:' % a.max if len(hits) > a.max else ':'))
        print('\n'.join(hits[:a.max]))
    elif a.grep:
        rx = re.compile(a.grep, re.I)
        shown = total = pages = 0
        for r in w.rows:
            if r['kind'] != 'wikitext':
                continue
            found = [ln for ln in w.read(r).splitlines() if rx.search(ln)]
            if not found:
                continue
            pages += 1
            total += len(found)
            for ln in found[:3]:
                if shown < a.max:
                    print('%s: %s' % (r['title'], ln.strip()[:220]))
                    shown += 1
        print('-- %d lines in %d pages%s' % (total, pages, ' (first %d shown, at most 3 a page)' % shown if total > shown else ''))
    elif a.cat:
        k = key(a.cat.split(':', 1)[1] if a.cat.lower().startswith('category:') else a.cat)
        hits = sorted({r['title'] for r in w.rows if any(key(c) == k for c in r['cats'])})
        if not hits:
            cats = sorted({c for r in w.rows for c in r['cats'] if k in key(c)})
            print('No category "%s". Categories holding that: %s' % (a.cat, ', '.join(cats[:30]) or 'none'))
            sys.exit(1)
        print('%d pages' % len(hits) + (', first %d:' % a.max if len(hits) > a.max else ':'))
        print('\n'.join(hits[:a.max]))
    elif a.info:
        r = w.find_page(name)
        print('%s\n  file: %s\n  revision %s of %s\n  %d characters\n  categories: %s' % (
            r['title'], r['path'], r['rev'] or '?', r['ts'] or '?', len(w.read(r)), '; '.join(r['cats']) or 'none'))
    elif name:
        show(w, name, a.raw, a.start, a.lines)
    else:
        ap.print_help()


if __name__ == '__main__':
    main()
