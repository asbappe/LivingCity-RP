#!/usr/bin/env python3
"""The map lessons (_dev/reference/lessons.json) against Valve's wiki (_dev/reference/vdc/, read with vdc.py).

Two parts. The exact one: every input, output and keyvalue a lesson names is looked up on the wiki pages of the
entities it names (found / on another entity's page / nowhere on the wiki / marked as another game's only), and
every entity it names is checked for being another game's. The judged one: a worksheet pairing each lesson with
the wiki's bugs, warnings and notes on its entities that share its subject, for a person or a chat to read for
contradictions and catches. Nothing here changes a lesson (the owner decides: docs/dev/vdc-lessons-check.md).

  python3 _dev/tools/vdc_lessons.py --names              the exact check, every lesson (--all: also names that
                                                         exist on an entity the lesson only describes in words)
  python3 _dev/tools/vdc_lessons.py --worksheet DIR      worksheet files of about 40 lessons each into DIR
  python3 _dev/tools/vdc_lessons.py ... --skip-checked   only lessons not yet in docs/dev/vdc-lessons-check.md
  python3 _dev/tools/vdc_lessons.py ... --ids a,b        only these lessons
"""
import json
import os
import re
import sys

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import vdc  # noqa: E402
import vdc_find  # noqa: E402

ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
LESSONS = os.path.join(ROOT, '_dev', 'reference', 'lessons.json')
REPORT = os.path.join(ROOT, 'docs', 'dev', 'vdc-lessons-check.md')
FIELDS = ('title', 'rule', 'why', 'how', 'check')
ENT = re.compile(r'\b[a-z][a-z0-9]*_[a-z0-9_]*[a-z0-9]\b')
IO = re.compile(r'\b(On[A-Z][A-Za-z0-9]+|(?:Set|Turn|Enable|Disable|Start|Stop|Fire|Kill|Toggle|Begin|Cancel|Add|Remove|'
                r'Show|Hide|Play|Lock|Unlock|Activate|Deactivate|Trigger|Break|Wake|Sleep|Open|Close)[A-Z][A-Za-z0-9]*)\b')
TICK = re.compile(r'`([A-Za-z_][A-Za-z0-9_]{2,40})`')
# Keyvalues every entity has (the wiki lists them on its generic page, not on each entity's).
BASE = {'spawnflags', 'targetname', 'parentname', 'origin', 'angles', 'classname', 'model', 'skin', 'rendermode',
        'rendercolor', 'renderamt', 'renderfx', 'disableshadows', 'globalname', 'hammerid', 'kill', 'killhierarchy',
        'addoutput', 'fireuser1', 'fireuser2', 'fireuser3', 'fireuser4', 'onuser1', 'onuser2', 'onuser3', 'onuser4'}
STOP = set('that this with from into when then they them their there what which while would could should about '
           'after before every other only also more most than like just some each such once over under make made '
           'used uses using much many does done have been were will your here where never always keep keeps '
           'entity entities map maps valve valves wiki page one two three set sets'.split())


def load_lessons():
    data = json.load(open(LESSONS, encoding='utf-8'))
    return data['lessons'] if isinstance(data, dict) else data


def checked_ids():
    if not os.path.exists(REPORT):
        return set()
    m = re.search(r'<!-- checked: (.*?) -->', open(REPORT, encoding='utf-8').read(), re.S)
    return set(m.group(1).split()) if m else set()


def blob(les):
    return ' '.join(str(les.get(k, '')) for k in FIELDS)


class Pages:
    """Each entity page's keyvalue, input, output and flag names (with the game an [only] tag names)."""

    def __init__(self, w):
        self.w, self.cache, self._all = w, {}, None

    def page(self, name):
        return self.w.by_key.get(vdc.key(name))

    def names(self, name):
        if name in self.cache:
            return self.cache[name]
        r = self.page(name)
        out = {'kv': {}, 'i': {}, 'o': {}, 'fl': {}, 'game': ''}
        if r:
            raw = self.w.read(r)
            text = self.w.expand(raw)
            for t in ('kv', 'i', 'o', 'fl'):
                for a in vdc_find._rows_of(self.w, text, t):
                    pos = [a[k] for k in sorted((k for k in a if k.isdigit()), key=int)]
                    if t == 'kv':
                        nm = a.get('intn') or (pos[0] if pos else '')
                    elif t == 'fl':
                        nm = pos[1] if len(pos) > 1 else ''
                    else:
                        nm = pos[0] if pos else ''
                    nm = vdc_find.plain(nm).strip()
                    if nm:
                        out[t][nm.lower()] = vdc_find.only_label(a['only']) if a.get('only') else ''
            m = re.search(r'\{\{\s*this is a\s*\|([^{}]*)\}\}', raw, re.I)
            g = re.search(r'\|\s*game\s*=\s*([^|}]*)', m.group(0)) if m else None
            out['game'] = g.group(1).strip() if g else ''
        self.cache[name] = out
        return out

    def everywhere(self):
        """{lowercase name: [entities whose page lists it]} over every entity page."""
        if self._all is None:
            self._all = {}
            for r in self.w.rows:
                if r['kind'] != 'wikitext' or r['ns'] not in ('0', ''):
                    continue
                cls = r['title'].replace(' ', '_').lower()
                if '_' not in cls:
                    continue
                n = self.names(cls)
                for t in ('kv', 'i', 'o'):
                    for nm in n[t]:
                        self._all.setdefault(nm, set()).add(cls)
        return self._all


GMOD_FGDS = ("Base.fgd/Garry's Mod", "Half-Life 2.fgd/Garry's Mod", 'Garrys Mod.fgd')


def gmod_fgd(w):
    """(entity classes, keyvalue/input/output names) in Garry's Mod's own FGD files, as the wiki keeps them."""
    classes, names = set(), set()
    for title in GMOD_FGDS:
        r = w.by_key.get(vdc.key(title))
        if not r:
            continue
        t = w.read(r)
        classes.update(c.lower() for c in re.findall(r'^\s*@\w+Class\b[^=\n]*=\s*([A-Za-z_][\w]*)', t, re.M))
        names.update(n.lower() for n in re.findall(r'^\s*(?:input|output)\s+([A-Za-z_]\w*)\s*\(', t, re.M))
        names.update(n.lower() for n in re.findall(r'^\s*([A-Za-z_]\w*)\s*\(\s*\w+\s*\)\s*(?:readonly\s*)?:', t, re.M))
    return classes, names


def family(k):
    """OnTrigger2 and OnScriptEvent02 are of the numbered families the wiki lists once."""
    return re.sub(r'\d+$', '', k)


def name_check(w, lessons, everything=False):
    """Rows: (lesson id, what, verdict). Without everything, only what may be wrong: names on no page and in no
    Garry's Mod FGD, names marked another game's only, entities from another game or missing from Garry's Mod."""
    pages = Pages(w)
    gm_classes, gm_names = gmod_fgd(w)
    gm_families = {family(n) for n in gm_names if n[-1:].isdigit()}
    other = re.compile(r'(Portal|Left 4 Dead|L4D|Team Fortress|TF2|Counter-Strike|CS:GO|Alien Swarm|Source 2|Alyx|Black Mesa|'
                       r'Half-Life: Source|GoldSrc|Mapbase|Day of Defeat|INFRA)', re.I)
    keep = re.compile(r'(Half-Life 2|HL2|Episode|Garry)', re.I)
    rows = []
    for les in lessons:
        text = blob(les)
        ents = sorted({t for t in ENT.findall(text) if pages.page(t)})
        for e in ents:
            g = pages.names(e)['game']
            if g and other.search(g) and not keep.search(g):
                rows.append((les['id'], e, 'the wiki says this entity is from: ' + g))
            if gm_classes and e not in gm_classes and re.search(r'\{\{\s*this is a\s*\|[^{}]*entity', w.read(pages.page(e)), re.I):
                rows.append((les['id'], e, "not in Garry's Mod's FGD (Hammer for Garry's Mod does not list it; it may not exist there)"))
        if not ents:
            continue
        own = {}
        for e in ents:
            n = pages.names(e)
            for t in ('kv', 'i', 'o', 'fl'):
                for nm, only in n[t].items():
                    own.setdefault(nm, []).append((e, t, only))
        lua = {m.group(1) for m in re.finditer(r'(?<=\w):([A-Za-z_]\w*)', text)}  # npc:AddEntityRelationship is Lua
        words = (set(IO.findall(text)) | {t for t in TICK.findall(text) if not ENT.fullmatch(t) or not pages.page(t)}) - lua
        everywhere = pages.everywhere()
        for word in sorted(words):
            k = word.lower()
            if k not in own and k not in everywhere and k.endswith('s') and (k[:-1] in own or k[:-1] in everywhere):
                k = k[:-1]  # "TurnOns" is TurnOn
            if k in BASE:
                continue
            if k not in own and k[-1:].isdigit() and any(family(n) == family(k) for n in own):
                continue
            if k in own:
                onlys = [(e, only) for e, t, only in own[k] if only]
                if onlys and len(onlys) == len(own[k]) and not keep.search(onlys[0][1]):
                    rows.append((les['id'], word, 'on %s, but marked only %s' % (onlys[0][0], onlys[0][1])))
                continue
            in_gmod = k in gm_names or (k[-1:].isdigit() and family(k) in gm_families)
            elsewhere = sorted(everywhere.get(k, ()))
            if not everything and (elsewhere or in_gmod):
                continue  # it exists: on another entity the lesson describes in words, or in Garry's Mod's FGD
            if len(elsewhere) >= 10:
                continue  # shared by many entities (OnDeath, TurnOn): the lesson means one it does not name
            if not elsewhere and not IO.fullmatch(word) and '_' not in word:
                continue  # a plain word in backticks (`lift`), not a keyvalue
            if elsewhere:
                rows.append((les['id'], word, 'not on the page of %s; listed on %s' % (', '.join(ents), ', '.join(elsewhere[:4]) + (' and %d more' % (len(elsewhere) - 4) if len(elsewhere) > 4 else ''))))
            else:
                rows.append((les['id'], word, 'not on the page of %s, nor on any entity page' % ', '.join(ents)))
    return rows


def content_words(text):
    return {x for x in re.findall(r'[a-z][a-z0-9]{3,}', text.lower()) if x not in STOP}


def worksheet(w, lessons, out_dir, per_file=40):
    pages = Pages(w)
    flags = {}
    for lid, what, verdict in name_check(w, lessons):
        flags.setdefault(lid, []).append('%s: %s' % (what, verdict))
    os.makedirs(out_dir, exist_ok=True)
    chunks, cur, n_files = [], [], 0
    for les in lessons:
        text = blob(les)
        ents = sorted({t for t in ENT.findall(text) if pages.page(t)})
        if not ents:
            continue
        mine = content_words(text)
        lines = ['## %s [%s]: %s' % (les['id'], ', '.join(les.get('tags', [])), les.get('title', ''))]
        for k, cap in (('rule', 900), ('how', 700), ('check', 300), ('why', 300)):
            v = re.sub(r'\s+', ' ', str(les.get(k, ''))).strip()
            if v:
                lines.append('%s: %s' % (k.upper(), v if len(v) <= cap else v[:cap - 3] + '...'))
        lines.append('WIKI:')
        for e in ents[:6]:
            r = pages.page(e)
            got = []
            for kind, txt in vdc_find.notes(w, w.read(r)):
                shared = len(mine & (content_words(txt) - content_words(e.replace('_', ' '))))
                if (kind in vdc_find.GOTCHA_KINDS and shared >= 1) or shared >= 2:
                    got.append((-shared, kind, txt))
            got.sort()
            lines.append('  %s: %s' % (r['title'], vdc_find.summary(w.read(r), 140)))
            for _, kind, txt in got[:7]:
                lines.append('    %s: %s' % (kind, txt))
        for f in flags.get(les['id'], []):
            lines.append('  NAME CHECK: ' + f)
        cur.append('\n'.join(lines))
        if len(cur) >= per_file:
            chunks.append(cur)
            cur = []
    if cur:
        chunks.append(cur)
    for i, c in enumerate(chunks, 1):
        path = os.path.join(out_dir, 'worksheet_%02d.md' % i)
        with open(path, 'w', encoding='utf-8') as f:
            f.write('\n\n'.join(c) + '\n')
        n_files += 1
        print('%s: %d lessons, %d KB' % (path, len(c), os.path.getsize(path) // 1024))
    return n_files


def main():
    args = sys.argv[1:]
    lessons = load_lessons()
    if '--ids' in args:
        ids = set(args[args.index('--ids') + 1].split(','))
        lessons = [x for x in lessons if x['id'] in ids]
    if '--skip-checked' in args:
        done = checked_ids()
        lessons = [x for x in lessons if x['id'] not in done]
    w = vdc.Wiki()
    if '--names' in args:
        rows = name_check(w, lessons, '--all' in args)
        for lid, what, verdict in rows:
            print('%s | %s | %s' % (lid, what, verdict))
        print('-- %d lessons, %d names to look at' % (len(lessons), len(rows)))
    elif '--worksheet' in args:
        worksheet(w, lessons, args[args.index('--worksheet') + 1])
    else:
        print(__doc__)


if __name__ == '__main__':
    main()
