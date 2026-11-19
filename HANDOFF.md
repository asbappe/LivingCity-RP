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
- `python3 _dev/voice_lines.py` writes **`VOICE_SCRIPTS.md`, the one file with every voice line** (the owner, 16 November: "We previously were using VOICE_SCRIPTS ... please consolidate"; the second file, `VOICE_LINES.md`, is gone: never bring it back or name it to the owner). What the owner has recorded is kept in `_dev/voice_done.txt` (rows ticked [x] in the file are added to it first), so ticks survive. `elevenlabs_batch.py` skips what's listed there. `_dev/voice_missing.txt` is the server's last `lc_voice_missing` list: when present it decides the ticks for every folder it checks (replace it with a newer one from the owner and rerun). `_dev/voice_seen.txt` is what existed when that list came in: a line added since is left unticked (it used to be ticked as if the server had it) and counted under "added since the server's list was made".

## Where things stand
- **19 November, this chat:** **headcrab shelling** (the long-term list, item 2; `sv_livingcity_shelling.lua`, `docs/features/infestation-cleanup.md`): three headcrab canisters on a Resistance-held district, each a patch of the nearest placed infestation and three headcrabs; her F2 > City orders, else the city's own about hourly; F4 > Admin testing tools > Testing alone > Shell a district now. **Waiting for the owner's yes:** `setting lc_shelling = 1` in the core snapshot (then CORE.md and CORE_CHANGELOG.md). Not run in the real game (backlog item at the end of `PLAYTEST_ARCHIVE.md`). Also: the test stub has `Matrix`, `WorldToLocal`, `LocalToWorld`; the lab test that failed after the stalker tests no longer does.
- **A parallel chat is working on the Resistance's fund** (19 November): the money jobs A (the still, the dealer's rent, the paymaster, the card table, the sidelines' share) and B (a second gun into the pockets, the armory, the quartermaster's barter and Goodwill). Their specs are the last items in `TODO.md`; leave them to that chat.
- **19 November, on `main`:** nothing only in the C menu or a chat command (`CLAUDE.md` rule 2); about 60 older player texts still name C menu paths (`TODO.md`: reword when the owner says). Every job shows its credits and fund share; the fund buys the fighters' gear (`lc_resistance_issue_rate`), its screen, donating, the Colonel's pleas (`docs/features/resistance-fund.md`).
- **18 November:** infestation per district (`sv_livingcity_districtinfest.lua`), the menus tidied (`docs/dev/menu-audit.md`), testing alone (`AdminSoloTests`), the Administrator's helicopter and the leader's kill order (`docs/features/city.md`). Open questions for the owner: `TODO.md`, last items.
- **Next on the long-term list:** 3, the hive boss (blind, hunts by sound); decide with the owner how it sits beside the collapse and the endings first. Antlions: NPCs only.
- `PLAYTEST.md` is the 18 November card (19 items, nothing run yet in the real game); new things for a person go to the end of `PLAYTEST_ARCHIVE.md`.
- **Rules learnt the hard way:** a default that changes goes in `RETUNED` (sv_livingcity_endings.lua); hook order is not promised (listen in two places where it matters); two side jobs at a time at most (the usage limit); the test runner needs `pip install lupa` in a fresh container.
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
