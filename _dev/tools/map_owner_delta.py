"""Carry what changed between two generator builds into the owner's Hammer-saved VMF, touching nothing else.

    python3 map_owner_delta.py BEFORE.vmf AFTER.vmf OWNER.vmf OUT.vmf [--loose] [--near N] [--ground-base OLD.vmf]

BEFORE is the build the owner's file was last brought up to, AFTER the build now (both made the same way, say --test).
Each entity or world brush only in BEFORE is found in the owner's file by its shape (classname, name, its brushes'
planes and materials; point entities also by origin and model) and removed; each only in AFTER is added with fresh ids,
in the owner's visgroups by name. It stops if a piece to remove is not in the owner's file exactly once; with --loose
that piece is left as it is and reported, and its new version is not added when the owner has the same shape already
(they retextured it: theirs wins).

Then the ground. A displacement keeps its planes when the generator raises or lowers it, so it is merged point by point,
three ways (the base, AFTER, the owner's): a point the owner never moved that the generator moved takes the new place;
every point they sculpted, and all their alphas, stay theirs. The base is BEFORE and every --ground-base OLD.vmf given
(any number: a point of theirs that matches any of these builds is one they never moved), for when their ground is older
than BEFORE (the owner, 24 November: a dip left from the old bunker's ground cut through the new hallway,
since the carry-over compared brushes by their planes only and never saw the ground move).

--near N (28 November: the owner had set right by hand what the generator then also set right): a piece to add is not
added when the owner's file already holds it, the same class, name, place, model and brushes (their world brush moved
there, their lamp's model swapped); nor a point entity when theirs of the same class, name and model stands within N
units of it (they nudged it: theirs stays). What the build takes away at the same time does not count as theirs.

The owner's line ends (CRLF) are kept. Afterwards: map_hidden_faces.py OUT.vmf FINAL.vmf --brushes, then FINAL --holes.
"""
import re
import sys


def read(p):
    return open(p, encoding='utf-8', errors='surrogateescape', newline='').read()


def nums(s):
    return tuple(round(float(x), 2) for x in s.replace('(', ' ').replace(')', ' ').split())


def solid_sig(txt):
    planes, mats = re.findall(r'"plane" "([^"]+)"', txt), re.findall(r'"material" "([^"]+)"', txt)
    assert len(planes) == len(mats), txt[:200]
    sides = list(zip(planes, mats))      # (one of each per side, in order; Hammer++ puts vertices_plus between them)
    return tuple(sorted((nums(p), m.lower()) for p, m in sides))


def key(txt, k):
    m = re.search(r'^\t"%s" "([^"]*)"' % re.escape(k), txt, re.M)
    return m.group(1) if m else ''


def split_top(text, eol):
    """[(kind, start, end)] of the top-level blocks."""
    out = []
    pat = re.compile(r'(^|%s)([a-z_]+)%s\{%s' % (re.escape(eol), re.escape(eol), re.escape(eol)))
    pos = 0
    while True:
        m = pat.search(text, pos)
        if not m:
            break
        s = m.start(2)
        e = text.find(eol + '}' + eol, m.end() - len(eol)) + len(eol) + 1      # (an empty block's brace follows its opening line at once)
        out.append((m.group(2), s, e))
        pos = e
    return out


def world_solids(text, eol, ws, we):
    out, pos = [], ws
    tag = eol + '\tsolid' + eol + '\t{' + eol
    while True:
        i = text.find(tag, pos, we)
        if i < 0:
            break
        s = i + len(eol)
        e = text.find(eol + '\t}' + eol, s) + len(eol) + 2
        out.append((s, e))
        pos = e
    return out


def ent_sig(txt):
    sols = re.findall(r'\tsolid\s*\{(.*?)\n\t\}', txt, re.S)
    base = (key(txt, 'classname'), key(txt, 'targetname'), key(txt, 'parentname'))
    if sols:
        return base + (tuple(sorted(solid_sig(s) for s in sols)),)
    ang = nums(key(txt, 'angles')) if key(txt, 'angles') else (0.0, 0.0, 0.0)      # (Hammer writes "0 0 0" where the generator writes none)
    return base + (nums(key(txt, 'origin')) if key(txt, 'origin') else (), key(txt, 'model').lower(), ang)


def shape_sig(txt):
    """A brush entity's class, name and brushes' planes, without materials."""
    sols = re.findall(r'\tsolid\s*\{(.*?)\n\t\}', txt, re.S)
    return (key(txt, 'classname'), key(txt, 'targetname'),
            tuple(sorted(tuple(sorted(nums(p) for p in re.findall(r'"plane" "([^"]+)"', s))) for s in sols)))


def point_sig(txt):
    """A point entity's class, name, model and place: the same thing in two builds even when its other keys changed."""
    return (key(txt, 'classname'), key(txt, 'targetname'), key(txt, 'model').lower(), nums(key(txt, 'origin')) if key(txt, 'origin') else ())


def full_sig(txt):
    """Everything about an entity as the generator writes it: every key but the ids, its outputs, its brushes (to tell
    whether it changed between two builds; the owner's copy is found by ent_sig, which Hammer's own keys do not upset)."""
    body = re.sub(r'"id" "\d+"', '', txt)
    body = re.sub(r'\teditor\s*\{.*?\}', '', body, flags=re.S)
    return re.sub(r'\s+', ' ', body)


def index(text):
    eol = '\r\n' if '\r\n' in text[:2000] else '\n'
    tops = split_top(text, eol)
    ents = [(s, e) for k, s, e in tops if k == 'entity']
    world = [(s, e) for k, s, e in tops if k == 'world'][0]
    sols = world_solids(text, eol, world[0], world[1])
    return eol, ents, world, sols


def sigs(text, full=False):
    eol, ents, world, sols = index(text)
    es = {}
    for s, e in ents:
        es.setdefault(full_sig(text[s:e]) if full else ent_sig(text[s:e]), []).append((s, e))
    ws = {}
    for s, e in sols:
        ws.setdefault(solid_sig(text[s:e]), []).append((s, e))
    return eol, es, ws, world


def only(x, y):
    out = []
    for k, v in x.items():
        out += [(k, se) for se in v[:max(0, len(v) - len(y.get(k, [])))]]
    return out


# the ground

FIELDS = ('normals', 'distances', 'offsets')
ROWS = {f: re.compile(r'(\n\t*' + f + r'\r?\n\t*\{)(.*?)(\n\t*\})', re.S) for f in FIELDS}


def disp_blocks(t):
    """[(key, start, end)] of every dispinfo block; key: (its startposition, its side's plane), rounded."""
    out = []
    for m in re.finditer(r'"plane" "([^"]+)"', t):
        nxt = t.find('"plane" "', m.end())
        nxt = len(t) if nxt < 0 else nxt
        i = t.find('dispinfo', m.end(), nxt)
        if i < 0:
            continue
        s = t.rfind('\n', 0, i) + 1
        end_pat = '\n' + t[s:i] + '}'
        e = t.find(end_pat, i) + len(end_pat)
        sp = tuple(round(float(x), 1) for x in re.search(r'"startposition" "\[([^\]]+)\]"', t[s:e]).group(1).split())
        pl = tuple(round(float(x), 1) for x in m.group(1).replace('(', ' ').replace(')', ' ').split())
        out.append(((sp, pl), s, e))
    return out


def rows(blk, f):
    rr = dict(re.findall(r'"row(\d+)" "([^"]*)"', ROWS[f].search(blk).group(2)))
    return {int(k): v.split() for k, v in rr.items()}


def moved(rs, r, c):
    """Where a vertex is moved from its flat spot: its normal times its distance, plus its offset."""
    n = [float(x) for x in rs['normals'][r][3 * c:3 * c + 3]]
    d = float(rs['distances'][r][c])
    o = [float(x) for x in rs['offsets'][r][3 * c:3 * c + 3]]
    return tuple(n[q] * d + o[q] for q in range(3))


def close(a, b, tol=0.02):
    return all(abs(x - y) <= tol for x, y in zip(a, b))


def merge_ground(base_ts, new_t, own_t):
    """base_ts: one or more earlier builds; a point of the owner's that matches any of them, and not AFTER, takes AFTER's."""
    bds = [{k: (s, e) for k, s, e in disp_blocks(b)} for b in base_ts]
    nd = {k: (s, e) for k, s, e in disp_blocks(new_t)}
    edits = []
    for k, s, e in disp_blocks(own_t):
        if k not in nd:
            continue
        nb, ob = new_t[slice(*nd[k])], own_t[s:e]
        nr, orr = ({f: rows(x, f) for f in FIELDS} for x in (nb, ob))
        size = len(nr['distances'])
        brs = [r for r in ({f: rows(b[slice(*bd[k])], f) for f in FIELDS} for b, bd in zip(base_ts, bds) if k in bd) if len(r['distances']) == size]
        if not brs:
            continue
        if len(orr['distances']) != size:
            print('  ground at %s: a different power, left as it is' % (k[0],))
            continue
        took = kept = 0
        for r in range(size):
            for c in range(size):
                nv, ov = moved(nr, r, c), moved(orr, r, c)
                bvs = [moved(br, r, c) for br in brs]
                if close(ov, nv) or all(close(bv, nv) for bv in bvs):
                    continue      # (the owner has it there already, or the generator never moved it)
                if any(close(ov, bv) for bv in bvs):
                    for f, w in (('normals', 3), ('distances', 1), ('offsets', 3)):
                        orr[f][r][w * c:w * c + w] = nr[f][r][w * c:w * c + w]
                    took += 1
                else:
                    kept += 1
        if took or kept:
            print('  ground at %s: %d points moved as the generator has them now, %d the owner sculpted kept' % (k[0], took, kept))
        if took:
            blk = ob
            for f in FIELDS:
                m = ROWS[f].search(blk)
                inner = m.group(2)
                for r in range(size):
                    inner = re.sub(r'"row%d" "[^"]*"' % r, '"row%d" "%s"' % (r, ' '.join(orr[f][r])), inner, count=1)
                blk = blk[:m.start(2)] + inner + blk[m.end(2):]
            edits.append((s, e, blk))
    for s, e, txt in sorted(edits, reverse=True):
        own_t = own_t[:s] + txt + own_t[e:]
    return own_t, len(edits)


def main():
    args = sys.argv[1:]
    ground_base = []
    while '--ground-base' in args:
        i = args.index('--ground-base')
        ground_base.append(args[i + 1])
        del args[i:i + 2]
    loose = '--loose' in args
    near = None
    if '--near' in args:
        i = args.index('--near')
        near = float(args[i + 1])
        del args[i:i + 2]
    before_p, after_p, owner_p, out_p = [a for a in args if not a.startswith('--')][:4]
    B, A, O = read(before_p), read(after_p), read(owner_p)
    _, be, bw, _ = sigs(B, full=True)
    _, ae, aw, _ = sigs(A, full=True)
    oeol, oe, ow, oworld = sigs(O)

    rm_e, add_e = only(be, ae), only(ae, be)
    rm_w, add_w = only(bw, aw), only(aw, bw)
    cut, kept_shapes, kept_points = [], set(), set()
    for _k, (s0, e0) in rm_e:
        bt = B[s0:e0]
        k = ent_sig(bt)      # (the owner's copy, by its class, name, place and brushes)
        got = oe.get(k, [])
        if len(got) != 1 and loose:
            cls, tn = key(bt, 'classname'), key(bt, 'targetname')
            org = nums(key(bt, 'origin')) if key(bt, 'origin') else None
            cands = []
            for vv in oe.values():
                for (os_, oe_) in vv:
                    t = O[os_:oe_]
                    if key(t, 'classname') != cls or key(t, 'targetname') != tn or key(t, 'model').lower() != key(bt, 'model').lower():
                        continue
                    if org is not None and '\tsolid' not in bt:
                        oo = nums(key(t, 'origin')) if key(t, 'origin') else None
                        if not oo or max(abs(a - b) for a, b in zip(oo, org)) > 1.5:
                            continue
                    cands.append((os_, oe_))
            if len(cands) == 1 or (tn and len(cands) >= 1 and '\tsolid' in bt and len(set(cands)) == 1):
                got = cands
        if len(got) != 1:
            if loose:
                print('  not found (left as it is): entity %s' % (str(k)[:140],))
                if '\tsolid' in bt:
                    kept_shapes.add(shape_sig(bt))
                else:
                    kept_points.add(point_sig(bt))
                continue
            sys.exit('STOP: entity %s found %d times in the owner file' % (str(k)[:120], len(got)))
        cut.append(got[0])
    shape = {}
    for k, v in ow.items():
        shape.setdefault(tuple(p for p, m in k), []).extend(v)
    missing = []
    for k, _se in rm_w:
        got = ow.get(k, [])
        if len(got) != 1 and loose:
            got = shape.get(tuple(p for p, m in k), [])      # (retextured by the owner: found by its planes alone)
        if len(got) != 1:
            if loose:
                missing.append(k)
                continue
            sys.exit('STOP: world brush %s found %d times in the owner file' % (str(k)[:120], len(got)))
        cut.append(got[0])
    if missing:
        print('%d world brushes to delete were not in the owner file (changed by the owner, or gone already)' % len(missing))

    nxt = [max(int(x) for x in re.findall(r'"id" "(\d+)"', O)) + 1]

    def renum(t):
        def r(m):
            nxt[0] += 1
            return '"id" "%d"' % nxt[0]
        t = re.sub(r'"id" "\d+"', r, t)
        return t.replace('\r\n', '\n').replace('\n', oeol)

    def vgroups(text):      # (visgroups named in the added blocks must be the owner's same ids)
        return dict(re.findall(r'"name" "([^"]*)"\s*"visgroupid" "(\d+)"', text))
    va, vo = vgroups(A), vgroups(O)
    vmap, vnew = {}, []
    top_id = max([int(x) for x in vo.values()] or [0])
    for name, aid in va.items():
        if name in vo:
            vmap[aid] = vo[name]
        else:
            top_id += 1
            vmap[aid] = str(top_id)
            vnew.append((name, str(top_id)))

    def vis_ok(t):
        return re.sub(r'"visgroupid" "(\d+)"', lambda m: '"visgroupid" "%s"' % vmap.get(m.group(1), m.group(1)), t)

    moved = [(k, se) for k, se in add_e if '\tsolid' not in A[se[0]:se[1]] and point_sig(A[se[0]:se[1]]) in kept_points]
    if moved:
        print('%d changed point entities not added: the owner moved them, and their copies keep the old keys (set those by hand)' % len(moved))
        add_e = [x for x in add_e if x not in moved]
    same_shape = [(k, se) for k, se in add_e if '\tsolid' in A[se[0]:se[1]] and shape_sig(A[se[0]:se[1]]) in kept_shapes]
    if same_shape:
        print('%d new brush entities not added: the owner has the same shape, retextured' % len(same_shape))
        add_e = [x for x in add_e if x not in same_shape]
    if near is not None:      # (what the owner's file holds already, apart from what this build takes away)
        gone = set(cut)
        have_e = set(k for k, v in oe.items() if any(se not in gone for se in v))
        have_w = set(k for k, v in ow.items() if any(se not in gone for se in v))
        pts = {}
        for v in oe.values():
            for se in v:
                t = O[se[0]:se[1]]
                if se not in gone and '\tsolid' not in t and key(t, 'origin'):
                    pts.setdefault((key(t, 'classname'), key(t, 'targetname'), key(t, 'model').lower()), []).append(nums(key(t, 'origin')))
        keep_e, held = [], 0
        for k, se in add_e:
            t = A[se[0]:se[1]]
            theirs = ent_sig(t) in have_e
            if not theirs and near > 0 and '\tsolid' not in t and key(t, 'origin'):
                o = nums(key(t, 'origin'))
                theirs = any(max(abs(a - b) for a, b in zip(o, q)) <= near for q in pts.get((key(t, 'classname'), key(t, 'targetname'), key(t, 'model').lower()), []))
            if theirs:
                held += 1
                print('  the owner has it already (not added): %s %s %s at %s' % (key(t, 'classname'), key(t, 'targetname'), key(t, 'model').split('/')[-1], key(t, 'origin')))
            else:
                keep_e.append((k, se))
        add_e = keep_e
        keep_w = [(k, se) for k, se in add_w if solid_sig(A[se[0]:se[1]]) not in have_w]
        if len(keep_w) != len(add_w):
            print('  %d world brushes the owner has already (not added)' % (len(add_w) - len(keep_w)))
        add_w = keep_w
    new_ents = [vis_ok(renum(A[s:e])) for k, (s, e) in add_e]
    new_sols = [vis_ok(renum(A[s:e])) for k, (s, e) in add_w]
    # (only the visgroups the added pieces are in: a visgroup the owner deleted with what was in it stays deleted; the
    #  owner, 27 November, deleted the cave's gate, its fence and with them the "path links" visgroup)
    used = set(re.findall(r'"visgroupid" "(\d+)"', ''.join(new_ents + new_sols)))
    vnew = [(n, v) for n, v in vnew if v in used]

    out, eol = O, oeol
    w_end = oworld[1] - 1                       # (the world's closing brace)
    last_ent_end = max(e for v in oe.values() for s, e in v)
    inserts = [(last_ent_end, ''.join(eol + t for t in new_ents)), (w_end, ''.join(t + eol for t in new_sols))]
    edits = [(s, e + len(eol), '') for s, e in cut] + [(p, p, txt) for p, txt in inserts]
    for s, e, txt in sorted(edits, key=lambda x: (x[0], x[1]), reverse=True):
        out = out[:s] + txt + out[e:]
    if vnew:      # (the generator's visgroups the owner's file lacks, added to its list)
        i = out.find(eol + '}' + eol, out.find('visgroups' + eol))
        add = ''.join('\tvisgroup' + eol + '\t{' + eol + '\t\t"name" "%s"' % n + eol + '\t\t"visgroupid" "%s"' % v + eol
                      + '\t\t"color" "200 200 200"' + eol + '\t}' + eol for n, v in vnew)
        out = out[:i + len(eol)] + add + out[i + len(eol):]
        print('%d visgroups added' % len(vnew))
    out, n_ground = merge_ground([B] + [read(g) for g in ground_base], A, out)
    open(out_p, 'w', encoding='utf-8', errors='surrogateescape', newline='').write(out)
    print('removed %d entities and %d world brushes; added %d entities and %d world brushes; %d displacements of ground merged' % (
        len(rm_e), len(rm_w), len(new_ents), len(new_sols), n_ground))


if __name__ == '__main__':
    main()
