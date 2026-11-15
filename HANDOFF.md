# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's playtest card: about 15 things only a person can judge; what else waits for a person is the short backlog `PLAYTEST_ARCHIVE.md`), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes).

## The project

- Living City is a Garry's Mod Half-Life 2 roleplay gamemode. Repo `asbappe/LivingCity-RP`. **`main` is the official branch.** Start from `main`, push the session's branch and also fast-forward `main` (`git push origin HEAD:main`; merge first if it moved, never force). No pull requests unless asked.
- Layout: `gamemodes/livingcity/` (the gamemode; modules in `gamemode/modules/server` and `client`; the in-game guide text is in `gamemode/cl_init.lua`), `livingcity_sound/` (READMEs only, never ship it), `pose_recorder/` (separate tool addon), `lua/` (editor tool), `_dev/` (offline tests, not shipped), `docs/features/` (spec), `docs/dev/` (notes for code workers, e.g. `endings-notes.md`).
- The latest work is in `git log` on `main`.

## The owner and their server

- Linux Mint (give Linux commands). Dedicated server on a Hexane host, map `rp_c18_ug`. FastDL mirrors `garrysmod/`; the host panel's "FastDL sync" must be pressed after every upload. Pictures and the font live loose in `garrysmod/materials/livingcity/` and `garrysmod/resource/fonts/` (`livingcity_content.zip`), not in the gamemode zip.
- Recordings and songs are in the server's `garrysmod/sound/livingcity/` (`overwatch/`, `administrator/`, `endings/`). Full details: `CORE.md`. A recording that "stopped working": run `lc_announce_clips` first.

## Testing

- Client smoke test, repo root: `python3 _dev/client_smoke.py` (must end `CLIENT SMOKE PASS`).
- **The owner asked (2026-10-31) to test less:** compile-check changed files and run only the test section you touched; run the full suite only when they ask. Compile check: `from lupa import luajit21 as lupa`, then `loadstring` on the file.
- **The run to trust is `python3 _dev/run_parallel.py`** (two minutes; every shard starts from a fresh city). Last runs (2026-11-14): about 6,425 passed, 3 to 11 failed, all from the unreliable list in `TODO.md`. The one-piece run (`cd _dev && timeout 6900 python3 run_tests.py tests.lua`) loads again but stops in `DreamGameTests` (tests.lua line 19504, a dream with no game) because of what earlier tests leave behind: `TODO.md`.
- Full suite on every core: `python3 _dev/run_parallel.py` (a few minutes; same last line as `run_tests.py`; see `CLAUDE.md`, Testing).
- The robot players: `python3 _dev/robots.py` (a minute and a half; must end `ROBOTS PASS`). The house rules: `python3 _dev/house_rules.py`. Both in `CLAUDE.md`, Testing.
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).
- `python3 _dev/voice_lines.py` writes `VOICE_LINES.md` and `VOICE_SCRIPTS.md` from the code; what the owner has recorded is kept in `_dev/voice_done.txt` (rows ticked [x] in either file are added to it first), so ticks survive. `elevenlabs_batch.py` skips what's listed there. `_dev/voice_missing.txt` is the server's last `lc_voice_missing` list: when present it decides the ticks for every folder it checks (replace it with a newer one from the owner and rerun).

## Where things stand
- 2026-11-15: **the owner's 14 November night notes** (about 45, sent as an annotated copy of the old playtest list) were worked through in groups. Merged and tested: the list cut, people stay, arrests and the Administrator's immunity, the Resistance, dreams and rations, the screen and the editor's names, the Administrator's tools. `CORE.md` has one bullet for all of it; `CORE_CHANGELOG.md` four lines.
- **Not done yet (`TODO.md`, "15 November"):** group C (graffiti pictures, the scientist's eyes, pots, Ravenholm music on rebel ground, the Colonel, the old timer as the fisherman, mouths on recorded lines), group D (citizens and weapons, weapons in custody, infestation junk, the stalker terminal, loudspeakers, the unpowered forcefield, the convoy looted), lockers for each side (the owner's yes). Ten questions wait on the owner there too.
- **`PLAYTEST.md` is this round's card** (16 things to try); `PLAYTEST_ARCHIVE.md` is now a backlog of about 70 one-line items (was 964 items, 281 KB; the old list is in git only, 7fc8b61). Keep it that size.
- **People stay** (the owner: "they stay until they DIE"): never fewer named citizens than `lc_citizens`, no nameless extras, `lc_citizen_lifetime` retired, home for a while and back as themselves, the train only for someone in despair. Next steps in `TODO.md`.
- **Arrests:** never cuffed while armed and fighting, a struggle before a unit's cuffs, three checks (`LC.NPCTakesIn`, `LC.CustodyAllowed`). The Administrator (a player) is immune. F4 > Admin tools > Handy > Out of custody.
- **Dreams:** the nightly timer never counted the city's own pick, so no dream ever started by itself: fixed; the debug report has a `dreams:` line. **Rations:** handouts 07:00 to 18:00, never from empty stores, deliveries sized to the city.
- **Another chat, same day (merged in):** the city eats in proportion and never the last quarter of the stores (the owner chose it there); here deliveries are sized to the city (twenty minutes of its eating each), handouts are by day only and never from empty stores. Next: the owner's `lc_stock` lines after an hour. The kitchen shift "The counter" ends in the papers game (ration cards); a story that frees a prisoner brings its own (The Man Inside part 2).
- **Side jobs:** eight at once used up the owner's 5-hour usage limit in under half an hour, twice. Two at a time at most, each committing after every finished note.
- **The tests:** `python3 _dev/run_parallel.py` is the run to trust; about ten tests come and go (`TODO.md`). New tests go just before the "Core contract" section of `tests.lua`, never after its last line.
- **The runners keep only setting lines with the value written out** (`_setcvar("x", 0)`, not `_setcvar("x", saved)`): a put-back line blanked the setting for every later section or shard. In a test, put a setting back through a local alias (`local set = _setcvar`) or `RunConsoleCommand`.
- From 14 November, still true: every error in one file (F4 > Factions > Admin: errors; next: read the owner's `errors.txt`), the robot players (`_dev/robots.py`), the house rules as numbers (`_dev/house_rules.py`), a pause on new features beyond what the owner asks for.
- The owner asked (14 November) to stop the reminder about the vanishing unit: don't raise it again unless they bring it up.
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
