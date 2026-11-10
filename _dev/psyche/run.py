"""The city's minds, offline: a pretend city run for a week in LuaJIT 2.1 (what Garry's Mod uses).

    python3 _dev/psyche/run.py [seed] [days] [citizens] [units] [seconds between minds] [--quiet]
    BRUT=2.5 KIND=0 python3 _dev/psyche/run.py 7 7 --quiet     (harsher units, no kind players)

It runs the gamemode's own sv_livingcity_psyche.lua, so what it shows is what the server would think.
"""
import os, sys
from lupa import luajit21 as lupa

HERE = os.path.dirname(os.path.abspath(__file__))
quiet = "--quiet" in sys.argv
sys.argv = [a for a in sys.argv if a != "--quiet"]
seed = int(sys.argv[1]) if len(sys.argv) > 1 else 7
days = int(sys.argv[2]) if len(sys.argv) > 2 else 7
cit = int(sys.argv[3]) if len(sys.argv) > 3 else 30
cops = int(sys.argv[4]) if len(sys.argv) > 4 else 10
every = float(sys.argv[5]) if len(sys.argv) > 5 else 0.5

L = lupa.LuaRuntime()
L.execute(f'BRUT = {os.environ.get("BRUT","1")}; KIND = {os.environ.get("KIND","1")}')
GM = os.path.join(HERE, '..', '..', 'gamemodes', 'livingcity', 'gamemode', 'modules', 'server', 'sv_livingcity_psyche.lua')
L.execute(f'PSY_PATH = [[{os.path.abspath(GM)}]]')
chunk = L.eval(f'loadfile([[{HERE}/city.lua]])')
mem0 = L.eval('collectgarbage("count")')
city = chunk(seed, days, cit, cops, every, 1)
L.execute('collectgarbage()')
mem1 = L.eval('collectgarbage("count")')

log = list(city.log.values())
counts = dict(city.counts.items())
cost = city.cost
if not quiet:
    print("\n".join(log))
    print()
print(f"== {days} days, {city.people} people ever (roster {cit} citizens + {cops} units), one mind stepped every {every}s ==")
print("what happened:", ", ".join(f"{k} {v}" for k, v in sorted(counts.items())))
print("unrest by day (0 calm .. 1 boiling):", " ".join(f"{u:.2f}" for u in city.unrest.values()))
print(f"cost: {cost.calls} steps, average {cost.avg_us:.1f} us, worst {cost.max_us:.1f} us;"
      f" at one step per {every}s that is {cost.avg_us / every / 1000:.4f} ms of server time per second")
print(f"memory for the whole city's minds and the test city: about {mem1 - mem0:.0f} KB")
print("\nthe most strained people at the end:")
print("\n".join(city.snap.values()))
