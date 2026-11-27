"""Put back (the owner, 27 November: rockwall015a applied to the whole big room by accident, an hour of work after it) the materials a texture was applied over by accident, in one visgroup only, from an older VMF (matched by solid
and side id). Alignment is put back too where the face's plane has not moved and only the shifts differ; otherwise
the owner's alignment is kept. Everything else in OWNER is kept byte for byte.
    python3 map_restore_material.py OWNER.vmf OLD.vmf VISGROUP_ID MATERIAL OUT.vmf"""
import re, sys
if len(sys.argv) != 6:
    raise SystemExit(__doc__)
own_p, old_p, vgid, acc, out_p = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4].upper(), sys.argv[5]
SIDE = re.compile(r'(\n(\t*)side\r?\n\2\{\r?\n\2\t"id" "(\d+)"(.*?)\n\2\})', re.S)

def side_map(t, only_vg=None):
    """side id -> (material, uaxis, vaxis, plane numbers) for sides of solids (in visgroup only_vg if given)"""
    out = {}
    w1 = t.find('\nentity')
    for m in re.finditer(r'\n(\t*)solid\r?\n\1\{\r?\n\1\t"id" "(\d+)"(.*?)\n\1\}', t, re.S):
        body = m.group(3)
        if only_vg is not None:
            ed = body[body.rfind('editor'):]
            vg = [int(x) for x in re.findall(r'"visgroupid" "(\d+)"', ed)]
            if m.start() > w1:
                s = t.rfind('\nentity', 0, m.start()); e = t.find('\nentity', m.end())
                blk = t[s:len(t) if e < 0 else e]
                vg += [int(x) for x in re.findall(r'"visgroupid" "(\d+)"', blk[blk.rfind('editor'):])]
            if only_vg not in vg:
                continue
        for sm in SIDE.finditer(body):
            sb = sm.group(4)
            out[int(sm.group(3))] = (re.search(r'"material" "([^"]*)"', sb).group(1), re.search(r'"uaxis" "([^"]*)"', sb).group(1),
                                     re.search(r'"vaxis" "([^"]*)"', sb).group(1),
                                     [float(x) for x in re.findall(r'[-\d.e]+', re.search(r'"plane" "([^"]*)"', sb).group(1))])
    return out

own = open(own_p, encoding='utf-8', errors='replace', newline='').read()
old = open(old_p, encoding='utf-8', errors='replace', newline='').read()
mine, theirs = side_map(own, vgid), side_map(old)
fix, n_mat, n_axes, n_kept = {}, 0, 0, 0
for sid, (m, u, v, pl) in mine.items():
    if m.upper() != acc or sid not in theirs:
        continue
    om, ou, ov, opl = theirs[sid]
    if om.upper() == acc:
        continue
    f = {"material": om}
    n_mat += 1
    if (ou, ov) != (u, v):
        if len(pl) == len(opl) and all(abs(a - b) < 0.01 for a, b in zip(pl, opl)):
            f["uaxis"], f["vaxis"] = ou, ov
            n_axes += 1
        else:
            n_kept += 1
    fix[sid] = f

def repl(m):
    sid = int(m.group(3))
    if sid not in fix:
        return m.group(1)
    s = m.group(1)
    for k, val in fix[sid].items():
        s = re.sub(r'("%s" ")[^"]*(")' % k, lambda mm: mm.group(1) + val + mm.group(2), s, count=1)
    return s
out = SIDE.sub(repl, own)
open(out_p, 'w', encoding='utf-8', newline='').write(out)
print("%d faces given their old material back; %d of them their old alignment too; %d kept the owner's alignment (their brush moved)" % (n_mat, n_axes, n_kept))
