"""Does each trait change what people do? Runs the pretend city for many weeks and correlates.

    python3 _dev/psyche/analyze_traits.py [weeks]

For every citizen who lived through a run: their traits, and how often they broke each way,
their average stress, arrests, informing, joining the Resistance. Prints, for each trait, the
outcomes it moves most (Pearson r; |r| under 0.1 is noise). A trait that moves nothing is dead weight.
"""
import math, os, sys
from lupa import luajit21 as lupa

HERE = os.path.dirname(os.path.abspath(__file__))
GM = os.path.abspath(os.path.join(HERE, "..", "..", "gamemodes", "livingcity", "gamemode", "modules", "server", "sv_livingcity_psyche.lua"))
weeks = int(sys.argv[1]) if len(sys.argv) > 1 else 40

rows = []
for seed in range(1, weeks + 1):
    L = lupa.LuaRuntime()
    L.execute(f"PSY_PATH = [[{GM}]]; BRUT = 1; KIND = 1")
    city = L.eval(f"loadfile([[{HERE}/city.lua]])")(seed, 7, 30, 10, 0.5, 1)
    for r in city.recs.values():
        d = dict(r.items())
        d["avg_stress"] = d["stress_sum"] / d["steps"] if d.get("steps") else 0
        rows.append(d)

traits = sorted(k for k in rows[0] if k.startswith("t_"))
outs = sorted({k for r in rows for k in r if k.startswith("b_")}) + ["avg_stress", "arrests", "informed", "rebel"]

def r_of(xs, ys):
    n = len(xs)
    mx, my = sum(xs) / n, sum(ys) / n
    sx = math.sqrt(sum((x - mx) ** 2 for x in xs))
    sy = math.sqrt(sum((y - my) ** 2 for y in ys))
    return 0 if sx == 0 or sy == 0 else sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / (sx * sy)

print(f"{len(rows)} citizens over {weeks} simulated weeks\n")
for t in traits:
    xs = [r[t] for r in rows]
    rs = sorted(((r_of(xs, [r.get(o, 0) for r in rows]), o) for o in outs), key=lambda x: -abs(x[0]))
    strong = [f"{o.replace('b_', '')} {v:+.2f}" for v, o in rs if abs(v) >= 0.1][:5]
    print(f"{t[2:]:11s} " + (", ".join(strong) if strong else "MOVES NOTHING"))
