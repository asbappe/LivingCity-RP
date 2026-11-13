# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's in-game checklist), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes).

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
- Full suite, from `_dev`, in the background: `timeout 6900 python3 run_tests.py tests.lua` (about 10.5 minutes since 9 November; includes the core snapshot check). Last run (2026-11-09): 4711 passed, 21 failed, all serial-order only (`TODO.md`). Stop a run with ``kill $(pgrep -f "^python3 -u run_tests.py tests.lua")``.
- Full suite on every core: `python3 _dev/run_parallel.py` (a few minutes; same last line as `run_tests.py`; see `CLAUDE.md`, Testing).
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).
- `python3 _dev/voice_lines.py` writes `VOICE_LINES.md` and `VOICE_SCRIPTS.md` from the code; what the owner has recorded is kept in `_dev/voice_done.txt` (rows ticked [x] in either file are added to it first), so ticks survive. `elevenlabs_batch.py` skips what's listed there. `_dev/voice_missing.txt` is the server's last `lc_voice_missing` list: when present it decides the ticks for every folder it checks (replace it with a newer one from the owner and rerun).

## Where things stand
- 2026-11-13, latest (owner: "please work on todo items"; core, in `CORE_CHANGELOG.md`, snapshot: 5 setting lines added): the six approved TODO items, built.
- **Cuffs felt, not a bar:** `cl_livingcity_arrest.lua` (resisting arrest: `LC_CL.FeltTug`, `LC_CL.ClosingEdges`, `LC_CL.StruggleFeel`) and `cl_livingcity_cuffed.lua` (working at or picking the cuffs: `LC_CL.CuffsFelt`); `lc_struggle_bar` client setting. Door and padlock picking keeps its bar.
- **Quick menus:** the talk window, a unit's search (`UnitQuick`), the interrogation (`QuestionQuick`, `CPQuick`) on `LC_CL.OpenSituation`, which now shuts F1 to F4 (`LC_CL.CloseFMenus`), takes `onClose`, `keep` and a function `note`; `lc_situation_windows` 1 brings the old windows.
- **Save with the gamemode:** `lua/weapons/gmod_tool/stools/livingcity_keep.lua` (uses `LC.PersistProp`; green halo while held).
- **Dream posters:** `sv_livingcity_dreamposters.lua` (`LC.DreamPosterFor`, `LC.DreamPosterHints`), poster kind `dream` in `lc_civposter.lua`; the pictures are a TODO item reserved for a particular chat (owner's request).
- **The Fitness Test** (`course`, Happy): `sv_livingcity_dreamcourse.lua` (`LC.CourseLay`, `LC.CourseSwept`).
- **Cubbage answers her speeches:** `sv_livingcity_speechanswer.lua` (`LC.SpeechAnswer`, `LC.SpeechAnswerLines`, `LC.Freq7CutIn`); ghost face `lc_colonel_model` (male_07, a guess at an old man: check in game); `VOICE_LINES.md` section 12.
- Unseen in game: all of the above (PLAYTEST.md, "13 November, later"); the baton and hurdle models, stone spacing.
- Other chat, same day: HQ calls only over the radio, the resupply scanner, gas masks, Half-Life 2 ammo limits, and Freq 7 sent only with a transmitter in hand (`LC.SendsOnFreq7`; Fighters and up issued one, `LC.IssueRebelRadio`).
- Next from TODO.md: job boards at terminals to settle with the owner; the dream posters' pictures.
- Earlier, still open: arm pose and baton glow; Careless Talk's vortigaunt delay; the chronicle file after a week; voice cue chattiness; the cuffed pose; the loading screen not hosted.
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
