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
- 2026-11-15 late: **the owner's card notes** (22 new, on the 15 November card) worked through. Merged and pushed to `main`: Combine scanner console (renamed); a power bank fills the vest in one press; purified water (2 at the CP Commissary, 4 at the quartermaster and dealer) and weapons by rank at the unit counter (its own things listed first); the victory sting (`music/hl1_song11.mp3`) only when the Administrator falls or flees; her glass grounded and 240 units tall; the old timer's head (bone-merge copied the shrunk head) and a white man's body; up to three live monitors; the stalker leans in once then works or holds; her guards shoot hostiles unasked (her order first, leash 450); units walk over to right turrets; the bus levels off under the sky; the Harpies dreamt (black fog for dreamers, `lc_dream_harpies_combine` 24 armed units, forest 72/cover 24, players carried off from 15 s into the leap).
- **Custody side job (merged):** bare-handed punches lead to the struggle (`LC.BareHandedHit`, `LC.TakenUnarmed`); no trespass countdown while held (`LC.HeldByCombine`); the situation menu widens and wraps; non-rebels questioned about their charge, the old sympathy score no longer counts as knowing the Resistance (tell the owner); Find work draws chevrons; waking clears screen fades (`LC.DreamClearScreen`).
- **City events side job (merged):** "Address the citizens" marks the speech stand nearest the crowd point and gathers up to six citizens there (`LC.SpeechGatherFew`); the review calls three units into a line, E on each to commend, reprimand or reassign (arrival type "fallin"); the drill brings `lc_exercise_npcs` of the city's own whatever they are doing (never from bed at night), the instructor calls and does each move. **The parade is not built** (strider, APC, column, march music after a third, everyone cheering in the middle third): next. The music is most likely `music/HL2_song22_CombineTheme3.mp3`; the short column is probably the manpower check refusing soldiers with no fallback in `Post`.
- **Waiting on the owner:** OK to update `_dev/core_snapshot.txt` (items `water_purified`, `tainted_water_purified`; setting `lc_dream_harpies_combine` 24; `lc_ending_minge_forest` 72, `lc_ending_minge_cover` 24), then a `CORE.md` bullet and a `CORE_CHANGELOG.md` line.
- **Not started: the pose tool** the owner asked for (a Miscount tool below the editor: spawn a stand-in in any custom pose, cuffed, the vortigaunt's broom, pick bones with an orange circle, sliders per bone and position). It is in `TODO.md`.
- Earlier, still true: `run_parallel.py` is the run to trust; the robots (`_dev/robots.py`); house rules (`_dev/house_rules.py`); side jobs two at a time at most (the owner's usage limit); don't raise the vanishing unit.
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
