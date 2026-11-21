import sys, time
sys.path.insert(0, '/tmp/claude-0/-home-user-LivingCity-RP/0fda6aa0-e3c1-5a1c-a472-171bd1a8ac5d/scratchpad/arch')
import arch_lib as A
for name in sys.argv[1:]:
    t = time.time()
    d = A.load(name, A.path_of(name))
    print(name, len(d['brushes']), len(d['ents']), d['sky_removed'], round(time.time() - t, 1), flush=True)
