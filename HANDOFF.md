# Living City: handoff to a new session

Read this first, then README.md (what the gamemode does, every setting) and PLAYTEST.md (the owner's in-game checklist).

## The project

Living City is a Garry's Mod Half-Life 2 roleplay gamemode.

- Repo: `asbappe/LivingCity-RP`. Work on branch `claude/youthful-rubin-j6lyfk` unless told otherwise. Push with `git push -u origin <branch>`. Do not open pull requests unless asked.
- Layout:
  - `gamemodes/livingcity/`: the gamemode. Modules are in `gamemode/modules/server` (about 96 files) and `gamemode/modules/client` (about 42). `gamemode/cl_init.lua` holds the in-game guide text.
  - `livingcity_sound/`: a separate addon for the sound files (READMEs only in git; the owner supplies the audio).
  - `lua/`: a small shared addon part.
  - `_dev/`: the offline test harness (not shipped).
- Last commit at handoff: `5db2d2e` (Bloom hips-only sway; no inspections, crimes or lost standing during endings).

## The owner and their server

- Plays on Linux Mint, so give Linux commands.
- Dedicated server on a Hexane host, map `rp_c18_ug`.
- FastDL at `http://a29ka.hexane.co/9124749/garrysmod/`, which mirrors `garrysmod/`. The host panel has a "FastDL sync" button, and it has to be pressed after every upload, or clients don't get new files.
- Sounds: clients must download them to hear them. Ending songs go flat in `sound/livingcity/endings/` (for example `endings/bloom.mp3`), never in subfolders. Many of the owner's files were mp3s renamed to .wav; `lc_sound_check` (client) and `lc_endings` (server) report problems.

## House rules (the owner insists on these)

1. **Never use em dashes,** anywhere: code, comments, docs, commit messages, chat. This command must print nothing: ``grep -rl $'\xe2\x80\x94' . --exclude-dir=.git``
2. **Everything works through the in-game UI.** Console commands are fine as extras for admins, but not as the only way. Important messages go through `LC.Notice`.
3. **Every change keeps these up to date:**
   - README.md
   - PLAYTEST.md
   - the guide in `cl_init.lua` when players would notice the change
   - `_dev/tests.lua`
   - `_dev/client_smoke.py`
4. **Commit messages** describe the change in plain words. End them with the session's attribution trailers. No model names or IDs in commits or code.
5. **Work lean.** The owner has limited usage, so keep the chat short and don't re-read large files you don't need.
6. **After each change, deliver a zip:**
   - `git archive HEAD` into a temp folder `livingcity/`
   - remove `livingcity/livingcity_sound`
   - zip it as `livingcity.zip`
   - send it to the owner as a file attachment.

   Also build `livingcity_sound.zip` when anything under `livingcity_sound/` changes.

## Testing

- Client smoke test: from the repo root, `python3 _dev/client_smoke.py`. It must end with `CLIENT SMOKE PASS`.
- Full tests: from `_dev`, `timeout 1200 python3 run_tests.py tests.lua`. This uses lupa/LuaJIT with `gmod_stub.lua` and is slow. For only the ending tests, make a trimmed copy of tests.lua with these parts, in order:
  - lines 1 to 404
  - lines 427 to 434
  - the `function EndingTests` block through the `EndingTests()` call
  - the file's last 3 lines

  The last trimmed run gave 237 passed. That was before the last two commits; the full suite hasn't been run since.
- Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs. There's no HSVToColor. `Entity()` returns nil in the smoke test, and OBBMaxs defaults to (2,24,96). LerpAngle and MOVETYPE_NONE were added. Add whatever else is missing to `gmod_stub.lua`.

## Recent focus: the secret endings

The main file is `modules/server/sv_livingcity_endings.lua`, with its client side in `modules/client/cl_livingcity_endings.lua`. The G-Man offers a vote; the endings are:

- harpies, bus, plane, standup, hard, base, marrow, bloom, water (the flood)

Each ending has a song and its own `lc_ending_<name>_*` cvars, all documented in the README's endings table.

Things worth knowing:

- **Archived server cvars keep their old values,** so changing a default doesn't reach existing servers. `LC.EndingRetune()` and its `RETUNED` table move exact old defaults to new ones. Add to that table whenever a default changes.
- **Song timing comes from a clock started when the song began playing** (`songAt` / SongClock on the client), because a BASS VBR mp3's GetTime drifts.
- **Things that fly are kept under the sky** with `LC.EndingCeilingAt` / `LC.EndingSky` (the bus, the plane, and Base's fleet). On the ground, the bus may drive through buildings; the owner likes that.
- **Placement uses `Ground()` and `RingSpot`,** which fall back to `LC.NavNodesNear`, because the map's landing zone is up on a roof.
- **Spectators (the dead):** `EndKey` and `LC.EndingPollKeys()` poll keys, because KeyPress doesn't always fire for spectators. Jump toggles free flight (OBS_MODE_ROAM).
- **ClientsideModels don't animate by themselves** (the G-Man), so their cycle is driven by hand.
- **Dances are bone manipulation on ValveBiped:** for Pelvis, Spine and Head, yaw (y) is side to side and roll (r) is front to back. Thigh y is forward and back.
- **An ending in progress:** `LC.EndingSession()` returns its state (nil when none). It now gates:
  - the city events
  - the announcer and voice clips
  - the ambient music
  - the breencast
  - Civil Protection inspections (underground stops)
  - `LC.ReportCrime`
  - negative `LC.AddStanding`

## Waiting on the owner's playtest (unverified in game)

- **Bloom:** do the feet stay planted with only the hips swaying? If they splay, `lc_bloom_leg_sign -1` (a client setting) flips the thigh counter-turn; then make the default match. Do the raised hands look right (higher for Combine models)?
- Dances' hand and leg axes in general (Marrow kicks, club and rave kicks).
- **Standup:** can the hanged look around? Do the heads stay put? Are the white cones visible on everyone? Do the hanged go limp 3 seconds before the end?
- **G-Man:** the tiefidget sequence name, the jaw moving while he talks, and whether he only appears for the one player he's talking to.
- **Base:** the bomb count is no longer zero (the server log line says how many). Are the captions in time?
- **Spectators:** does Jump toggle free flight?
- **Flood:** Grigori visible and headbanging, the crowd on the raft, the ichthyosaurs biting NPCs, Jump at the edge climbing back on.
- **No inspections, wanted notices or lost standing during an ending** (just fixed after the owner lost 25 standing mid-Bloom).

## Later ideas

See TODO.md: screens drawn on terminals in the world, tuning the kick, long-term progression, more faces.
