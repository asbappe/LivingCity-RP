# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's in-game checklist), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes). One task per chat: when you finish, rewrite "Where things stand" below in 15 lines or fewer.

## The project

- Living City is a Garry's Mod Half-Life 2 roleplay gamemode. Repo `asbappe/LivingCity-RP`. **`main` is the official branch.** Start from `main`, push the session's branch and also fast-forward `main` (`git push origin HEAD:main`; merge first if it moved, never force). No pull requests unless asked.
- Layout: `gamemodes/livingcity/` (the gamemode; modules in `gamemode/modules/server` and `client`; the in-game guide text is in `gamemode/cl_init.lua`), `livingcity_sound/` (READMEs only, never ship it), `pose_recorder/` (separate tool addon), `lua/` (editor tool), `_dev/` (offline tests, not shipped), `docs/features/` (spec), `docs/dev/` (notes for code workers, e.g. `endings-notes.md`).
- The latest work is in `git log` on `main`.

## The owner and their server

- Linux Mint (give Linux commands). Dedicated server on a Hexane host, map `rp_c18_ug`. FastDL mirrors `garrysmod/`; the host panel's "FastDL sync" must be pressed after every upload.
- Recordings and songs are in the server's `garrysmod/sound/livingcity/` (`overwatch/`, `administrator/`, `endings/`). Full details: `CORE.md`. A recording that "stopped working": run `lc_announce_clips` first.

## Testing

- Client smoke test, repo root: `python3 _dev/client_smoke.py` (must end `CLIENT SMOKE PASS`).
- **The owner asked (2026-10-31) to test less:** compile-check changed files and run only the test section you touched; run the full suite only when they ask. Compile check: `from lupa import luajit21 as lupa`, then `loadstring` on the file.
- Full suite, from `_dev`, in the background: `timeout 6900 python3 run_tests.py tests.lua` (about 40 minutes; includes the core snapshot check). Last full run (2026-11-02): 2994 passed, 6 failed (flaky, see `TODO.md`). Stop a run with ``kill $(pgrep -f "^python3 -u run_tests.py tests.lua")``.
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).

## Where things stand

- 2026-11-08 (part 3): **Propaganda dreams** (renamed from "the Administrator's dreams" at the owner's word), `sv_livingcity_propagandadreams.lua`: Kneel Before Her (`adore`), Roses for Her (`roses`), Mirror, Mirror (`mirror`), The Saviour (`saviour`: monsters, she descends glowing, "Stop!", Combine soldiers kill them all; times in `LC.SaviourTimes`), The Loyalty Quiz (`quiz`: `LC.QuizQuestions`, thoughtcrime words). All Happy; listed on the tablet as "Propaganda: ...".
- Starring: the Administrator asleep with someone else plays herself (`LC.DreamStarOf`, PData `lc_dream_star`, tablet toggle via `LC.AdminDo(ply, "dreamstar", "on"/"off")`). Generic support in `sv_livingcity_dreamgames.lua` (`g.star`, `def.starring`, `def.starGone`, state sent to her too); `LC.DreamStarDone` undoes her size on waking.
- Music: `sound/livingcity/dreams/<codeword>N.ext` (admire, saviour_horde, saviour, quiz; old `dreams/administrator/` = admire). Voice: `sound/livingcity/dreams/voice/<cue>N.wav` + `.txt` subtitle (`LC.PropagandaCues`). The owner will record lines and import songs.
- Chat in the mirror and quiz (and the star's) stays in the dream: `LC.PropagandaSay`, called first by the IC chat hook in `sv_livingcity_rp.lua`.
- Earlier today: nightmare rewards (`sv_livingcity_vices.lua`); the six vice items are in the core snapshot (owner approved).
- Tests: `PropagandaDreamTests` (58), `DreamGameTests` (38), `DreamTests` (60), `DreamMoodTests` (26) pass; client smoke passes. Nothing checked in game: PLAYTEST.md, last section (sizes, angles and the glow are guesses).
- More propaganda dream ideas offered to the owner (not built): see the end of this chat or ask.
- `TODO.md`: Combine sleep in the head-clamp prop (later). Full suite last run 2026-11-02.
