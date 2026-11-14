# Tests

Runs the server logic against a fake Garry's Mod (`gmod_stub.lua`). Not loaded by the game.

    pip install lupa

| Command (from the repo root) | What it does |
| --- | --- |
| `python3 _dev/run_section.py "part of a section name"` | one section or unit of `tests.lua` (`--unit NameTests`, `--list TEXT`) |
| `python3 _dev/run_parallel.py` | the whole of `tests.lua` on every core, the core snapshot check, the house rules |
| `cd _dev && python3 run_tests.py tests.lua` | the whole of `tests.lua` in one go, in order (the reference; about ten minutes) |
| `python3 _dev/client_smoke.py` | the player's side loads and draws (must end `CLIENT SMOKE PASS`) |
| `python3 _dev/robots.py` | the robot players: every job done the way a player would, both ways round (`docs/dev/robot-players.md`) |
| `python3 _dev/house_rules.py` | stand-still job steps, places that put text on screen, console-only commands: may fall, not rise |

Things to know:

- `tests.lua` is one long script. Its main level is one Lua function, and Lua allows 200 local variables in one: put a new test in its own scope (`function NameTests() ... end NameTests()`, or `;(function() ... end)()`). The runners say `TESTS.LUA DOES NOT LOAD WHOLE` when the full file no longer loads.
- Hooks and timers run in the order they were made, the same on every run. `_HOOK_REVERSE = true` runs hooks last-made first (the robots use it).
- `LC_ERRDUMP=/some/path` writes what the gamemode's own errors file would hold after a run (`/some/path.<pid>.txt`): errors a protected call swallowed show there and nowhere else.
- Some tests are still unreliable from run to run (Lua's table order): the list is in `TODO.md`.
