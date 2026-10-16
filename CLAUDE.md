# Living City: read me first (every session)

Living City is a Garry's Mod Half-Life 2 roleplay gamemode. The owner has put a great deal into it and runs it on a live server. **Before changing anything, read `CORE.md`** (the core: the owner's server, where their files are, what must not change without asking) and `HANDOFF.md` (the latest work). `TIMELINE.md` has every earlier chat's work in date order, what each told the owner, and where it disagrees with the code.

## The one rule above all

**Nothing the owner relies on changes unless they asked for it, or you asked them first and they said yes.** That means anything in `CORE.md` and any behaviour `README.md` describes: where files are read from, file names, settings and their defaults, factions and ranks, items, commands, how a feature behaves. A new feature is fine. A change to an existing one, even a "fix" or a tidy-up, is first described to the owner in plain words ("this would change X to Y: OK?"). The test "the core is as the owner knows it" fails when the core changes: tell the owner what it printed, and update `_dev/core_snapshot.txt` only with their OK (`CORE.md`, rule 4).

**When something isn't working on their server, find out what's there before touching the code**: ask for the debug report, `lc_announce_clips`, `lc_endings` or `lc_sound_check`, and compare it with `CORE.md`. Make the code fit their setup; never ask them to rename or move their files to fit a guess.

## House rules (the owner insists on these)

1. **Never use em dashes**, anywhere (code, comments, docs, commits, chat). `grep -rl $'\xe2\x80\x94' . --exclude-dir=.git` must print nothing.
2. **Everything works through the in-game UI.** Console commands are extras for admins, never the only way. Important messages go through `LC.Notice`.
3. **Every change keeps these up to date:** `README.md`, `PLAYTEST.md`, the guide in `gamemodes/livingcity/gamemode/cl_init.lua` (when players would notice), `_dev/tests.lua`, `_dev/client_smoke.py`, and `CORE.md` when it touches the core.
4. **Commit messages** say what changed in plain words, and end with the session's attribution lines. No model names or IDs in commits or code.
5. **Work lean.** The owner has a limited budget: keep chat short, don't re-read large files you don't need.
6. **Deliver a zip after each change:** `git archive HEAD` into a temp `livingcity/`, remove `livingcity/livingcity_sound` and `livingcity/pose_recorder`, zip it as `livingcity.zip`, send it as a file. Never send a sound zip that could replace the owner's sound folders.
7. The owner plays on **Linux Mint**: give Linux commands.

## Testing

- Client smoke test, from the repo root: `python3 _dev/client_smoke.py` (must end `CLIENT SMOKE PASS`).
- Full suite, from `_dev`: `timeout 6900 python3 run_tests.py tests.lua` (about 40 minutes; run it in the background). It includes the core snapshot check.
- The endings alone, quicker: see `HANDOFF.md`, "Testing".
