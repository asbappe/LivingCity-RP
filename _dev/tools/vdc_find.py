"""The index side of vdc.py: ranked search, entity cards, gotchas, the entity list.

A card joins three sources at read time (nothing copied, so nothing goes stale): the wiki page, how often
Valve's own HL2/EP1/EP2 maps use the entity (_dev/reference/valve_*/measure.json, from map_ingest.py), and the
map lessons that name it (_dev/reference/lessons.json).
"""
import glob
import json
import math
import os
import re

REF = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'reference'))
NOTE_KINDS = ('bug', 'warning', 'workaround', 'fix', 'important', 'tip', 'note', 'confirm')
GOTCHA_KINDS = ('bug', 'warning', 'workaround', 'fix', 'important')
# Categories that say nothing about the subject (wiki upkeep).
DULL_CAT = re.compile(r'^(CONFIRM|English|Translation|TODO|Pages |Articles |Stub|Cleanup|CD |Screenshot|Orphan|Underlinked|Dead end|Multiple issues)', re.I)
# Game templates ({{hl2}}, {{tf2|4}}...): their names. Others short and argument-free are left out.
GAME = {'hl': 'Half-Life', 'hl2': 'Half-Life 2', 'ep1': 'Episode One', 'ep2': 'Episode Two', 'hl2ep1': 'Episode One',
        'hl2ep2': 'Episode Two', 'lc': 'Lost Coast', 'gmod': "Garry's Mod", 'src': 'Source', 'source': 'Source',
        'src13': 'Source 2013', 'src13mp': 'Source 2013 MP', 'src07': 'Source 2007', 'hl2dm': 'HL2 Deathmatch',
        'quake': 'Quake', 'goldsrc': 'GoldSrc', 'gldsrc': 'GoldSrc', 'tf2': 'TF2', 'tf2branch': 'TF2 branch',
        'l4d': 'Left 4 Dead', 'l4d2': 'Left 4 Dead 2', 'l4ds': 'Left 4 Dead', 'portal': 'Portal', 'portal2': 'Portal 2',
        'csgo': 'CS:GO', 'css': 'CS:S', 'cs2': 'CS2', 'hls': 'Half-Life: Source', 'hldms': 'HLDM: Source',
        'as': 'Alien Swarm', 'asw': 'Alien Swarm', 'bms': 'Black Mesa', 'mapbase': 'Mapbase', 'dods': 'DoD: Source',
        'source2': 'Source 2', 'src2': 'Source 2', 'hla': 'Half-Life: Alyx', 'strata': 'Strata Source', 'sfm': 'SFM'}


def only_label(v):
    """only={{hls}}{{hldms}} -> 'Half-Life: Source, HLDM: Source'."""
    names = [GAME.get(n.lower(), n) for n in re.findall(r'\{\{\s*([\w-]+)\s*(?:\|[^{}]*)?\}\}', v)]
    return ', '.join(names) or plain(v)


def plain(text, limit=None):
    """Wikitext to a readable line."""
    t = re.sub(r'\[\[(?:[^\]|{}]*\|)?([^\]{}]*)\]\]', r'\1', text)  # links first: their | is not a template's
    for _ in range(12):
        new = re.sub(r'\{\{([^{}]*)\}\}', _tpl, t)
        if new == t:
            break
        t = new
    t = re.sub(r'\[\[(?:[^\]|]*\|)?([^\]]*)\]\]', r'\1', t)
    t = re.sub(r'\[https?://\S+\s+([^\]]*)\]', r'\1', t)
    t = re.sub(r"'''?|<[^>]+>", '', t).replace('&nbsp;', ' ')
    t = re.sub(r'\s+([.,;:!?)])', r'\1', re.sub(r'\s+', ' ', t)).strip(' :;')
    if limit and len(t) > limit:
        t = t[:limit - 3].rsplit(' ', 1)[0] + '...'
    return t


def _tpl(m):
    parts = [p.strip() for p in m.group(1).split('|')]
    name = parts[0].lower()
    pos = [p for p in parts[1:] if '=' not in p]
    named = dict(p.split('=', 1) for p in parts[1:] if '=' in p)
    if name == 'this is a' and pos:
        return '%s is a %s%s.' % (named.get('name', 'This').strip(), pos[0], (' (' + named['game'].strip() + ')') if named.get('game') else '')
    if name in GAME and (not pos or (len(pos) == 1 and pos[0].isdigit())):
        return GAME[name] + ' '
    if len(pos) == 1 and len(parts) - 1 == 1:
        return pos[0]
    if name in NOTE_KINDS and pos:
        return pos[0]
    return ''


def summary(text, limit=200):
    """The page's first sentence or two."""
    m = re.search(r'\{\{\s*this is a\s*\|[^{}]*\}\}', text, re.I)
    lead = plain(m.group(0)) + ' ' if m else ''
    body = text[m.end():] if m else text
    for para in re.split(r'\n\s*\n', body):
        p = re.sub(r'^(\s*\{\{[^{}]*\}\}\s*)+', '', para).strip()  # banners and tabs before the text
        if not p or p.startswith(('{{', '==', '{|', '[[Category', '[[File', '[[Image', '__', '<!--', '|', '!', ':')):
            continue
        s = plain(p)
        if len(s) > 20:
            return plain(lead + s, limit)
    return plain(lead, limit) or '(no summary)'


def notes(w, text):
    """Bugs, warnings, tips... on a page, with the templates it pulls in filled in."""
    from vdc import calls, split_args
    out = []

    def walk(t):
        for s, e, inside in calls(t):
            name, args = split_args(inside)
            kind = name.lower()
            if kind in NOTE_KINDS:
                txt = plain(' '.join(v for k, v in args.items() if k.isdigit()), 260)
                if txt:
                    out.append((kind, txt))
            walk(inside)
    walk(w.expand(text))
    return out


def valve_usage():
    """({class: (times, maps)}, maps measured, classes counted exactly). Each map keeps its 60 most used classes,
    and exact counts for the groups map_ingest.py tracks (doors, lights, props...)."""
    tot, maps, n, exact = {}, {}, 0, set()
    for f in glob.glob(os.path.join(REF, 'valve_*', 'measure.json')):
        try:
            census = json.load(open(f, encoding='utf-8')).get('census', {})
        except (OSError, ValueError):
            continue
        n += 1
        counts = dict((c, k) for c, k in census.get('classes_top') or [])
        groups = census.get('groups') or {}
        counts.update(groups)
        exact.update(groups)
        for cls, cnt in counts.items():
            if cnt:
                tot[cls] = tot.get(cls, 0) + cnt
                maps[cls] = maps.get(cls, 0) + 1
    return {c: (tot[c], maps[c]) for c in tot}, n, exact


def lessons_naming(word):
    try:
        data = json.load(open(os.path.join(REF, 'lessons.json'), encoding='utf-8'))
    except (OSError, ValueError):
        return []
    if isinstance(data, dict):
        items = data['lessons'] if isinstance(data.get('lessons'), list) else [v for v in data.values() if isinstance(v, dict)]
    else:
        items = data
    rx = re.compile(r'(^|[^a-z0-9_])' + re.escape(word.lower()) + r'($|[^a-z0-9_])')
    hits = []
    for les in items:
        blob = ' '.join(str(les.get(k, '')) for k in ('title', 'rule', 'why', 'how', 'check')).lower()
        if rx.search(blob):
            hits.append('%s: %s' % (les.get('id'), les.get('title')))
    return hits


def _rows_of(w, text, tname):
    from vdc import calls, split_args
    out = []

    def walk(t):
        for s, e, inside in calls(t):
            name, args = split_args(inside)
            if name.lower() == tname:
                out.append(args)
            else:
                walk(inside)
    walk(text)
    return out


def card(w, name):
    r = w.find_page(name)
    raw = w.read(r)
    text = w.expand(raw)
    cls = r['title'].replace(' ', '_').lower()
    cats = [c for c in r['cats'] if not DULL_CAT.match(c)]
    print('# %s' % r['title'])
    print(summary(raw, 300))
    if cats:
        print('Categories: ' + '; '.join(cats[:12]))
    use, nmaps, exact = valve_usage()
    if cls in use:
        print("In Valve's maps: %d placed, in %d of %d HL2/EP1/EP2 maps%s." % (use[cls][0], use[cls][1], nmaps,
              '' if cls in exact else " (at least: counting each map's 60 most used kinds)"))
    elif nmaps and '_' in cls:
        print("In Valve's maps: not among any map's 60 most used kinds.")
    sections = (('Keyvalues', 'kv'), ('Flags', 'fl'), ('Inputs', 'i'), ('Outputs', 'o'))
    for label, t in sections:
        rows = _rows_of(w, text, t)
        if not rows:
            continue
        print('%s (%d):' % (label, len(rows)))
        for a in rows[:40]:
            pos = [a[k] for k in sorted((k for k in a if k.isdigit()), key=int)]
            only = (' [only ' + only_label(a['only']) + ']') if a.get('only') else ''
            if t == 'kv':
                disp = plain(pos[0]) if pos else ''
                typ = plain(pos[1]) if len(pos) > 2 else ''
                desc = plain(pos[-1], 110) if len(pos) > 1 else ''
                print('  %s%s: %s. %s%s' % (a.get('intn', disp).strip(), ' (' + typ + ')' if typ else '', disp, desc, only))
            elif t == 'fl':
                print('  %s %s: %s%s' % (plain(pos[0]) if pos else '?', plain(pos[1]) if len(pos) > 1 else '', plain(pos[2], 90) if len(pos) > 2 else '', only))
            else:
                param = (' (' + plain(a['param']) + ')') if a.get('param') else ''
                print('  %s%s: %s%s' % (plain(pos[0]) if pos else '?', param, plain(pos[-1], 90) if len(pos) > 1 else '', only))
        if len(rows) > 40:
            print('  ... %d more: vdc.py %s' % (len(rows) - 40, name))
    ns = notes(w, raw)
    if ns:
        order = {k: i for i, k in enumerate(NOTE_KINDS)}
        ns.sort(key=lambda x: order[x[0]])
        print('Watch out (%d notes; bugs and warnings first):' % len(ns))
        for kind, txt in ns[:14]:
            print('  %s: %s' % (kind, txt))
    les = lessons_naming(cls if '_' in cls else r['title'])
    if les:
        print('Map lessons that name it (python3 _dev/tools/map_lessons.py --find %s):' % cls)
        for x in les[:8]:
            print('  ' + x)
    print('Whole page: python3 _dev/tools/vdc.py %s' % name)


def search(w, words, top=12):
    terms = [t for t in re.findall(r'[a-z0-9_]+', ' '.join(words).lower()) if len(t) > 1]
    if not terms:
        return
    pages = [r for r in w.rows if r['kind'] == 'wikitext']
    docs, df = [], {t: 0 for t in terms}
    for r in pages:
        body = w.read(r).lower()
        title = r['title'].lower().replace('_', ' ')
        heads = ' '.join(re.findall(r'^=+[^=\n]+=+', body, re.M))
        tf = {t: body.count(t) for t in terms}
        for t in terms:
            if tf[t] or t in title:
                df[t] += 1
        docs.append((r, title, heads, tf, len(body)))
    n = len(pages)
    scored = []
    for r, title, heads, tf, size in docs:
        s, present = 0.0, 0
        for t in terms:
            idf = math.log(1 + n / (1 + df[t]))
            hit = (8 if t in title.replace(' ', '_') or t in title else 0) + 3 * min(heads.count(t), 3) + math.log(1 + tf[t]) / math.sqrt(1 + size / 40000)
            if hit:
                present += 1
            s += idf * hit
        if present:
            if r['title'].startswith('Template:'):
                s *= 0.5
            if 'Help Desk' in r['title'] or r['title'].startswith(('Talk:', 'User:')):
                s *= 0.3
            scored.append((s * (2 if present == len(terms) else 1), r))
    scored.sort(key=lambda x: -x[0])
    for s, r in scored[:top]:
        print('%s: %s' % (r['title'], summary(w.read(r), 150)))
    print('-- %d pages hold some of the words; the best %d shown (--max N). A card: vdc.py --card NAME' % (len(scored), min(top, len(scored))))


def gotchas(w, words, top=40):
    rx = [re.compile(re.escape(x), re.I) for x in words]
    shown = total = 0
    counts = {}
    for r in w.rows:
        if r['kind'] != 'wikitext' or r['title'].startswith(('Template:', 'Category:')):
            continue
        text = w.read(r)
        if not re.search(r'\{\{\s*(bug|warning|workaround|fix|important)\s*\|', text, re.I):
            continue
        for kind, txt in notes(w, text):
            if kind not in GOTCHA_KINDS:
                continue
            if rx and not all(x.search(txt) or x.search(r['title']) for x in rx):
                continue
            total += 1
            counts[kind] = counts.get(kind, 0) + 1
            if shown < top:
                print('%s: %s: %s' % (r['title'], kind, txt))
                shown += 1
    print('-- %d (%s)%s' % (total, ', '.join('%d %s' % (v, k) for k, v in sorted(counts.items(), key=lambda x: -x[1])),
                            '; first %d shown (--max N)' % shown if total > shown else ''))


def entities(w, words, top=40):
    use, nmaps, exact = valve_usage()
    found = []
    for r in w.rows:
        if r['kind'] != 'wikitext' or r['ns'] not in ('0', ''):
            continue
        text = w.read(r)
        m = re.search(r'\{\{\s*this is a\s*\|([^{}]*)\}\}', text, re.I)
        kinds = [p.strip() for p in m.group(1).split('|') if '=' not in p] if m else []
        if not kinds or not kinds[0].lower().endswith('entity'):
            continue
        cls = r['title'].replace(' ', '_').lower()
        line = summary(text, 140)
        if words and not all(x.lower() in (cls + ' ' + line.lower()) for x in words):
            continue
        found.append((use.get(cls, (0, 0)), cls, kinds[0].lower(), line))
    found.sort(key=lambda x: (-x[0][0], x[1]))
    for (times, maps), cls, kind, line in found[:top]:
        print('%-28s %-15s %s  %s' % (cls, kind, ('%d in %d maps' % (times, maps)) if times else 'not in Valve\'s top 60s', line))
    print('-- %d entity pages%s, most used in Valve\'s %d maps first' % (len(found), ' matching' if words else '', nmaps))
