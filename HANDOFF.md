# Living City: handoff to a new session

`CLAUDE.md` (loaded into every session) and **`CORE.md`** (the core: what must not change without the owner's OK, and the owner's real server setup) come first. Then this, then README.md (what the gamemode does, every setting) and PLAYTEST.md (the owner's in-game checklist).

## The project

Living City is a Garry's Mod Half-Life 2 roleplay gamemode.

- Repo: `asbappe/LivingCity-RP`. Work on branch `claude/youthful-rubin-j6lyfk` unless told otherwise. Push with `git push -u origin <branch>`. Do not open pull requests unless asked.
- Layout:
  - `gamemodes/livingcity/`: the gamemode. Modules are in `gamemode/modules/server` (about 96 files) and `gamemode/modules/client` (about 42). `gamemode/cl_init.lua` holds the in-game guide text.
  - `livingcity_sound/`: notes only (the triggers' READMEs and ANNOUNCEMENT_SCRIPTS.md). The owner's recordings and songs live in the server's `garrysmod/sound/livingcity/`, the official folder; never ship this folder.
  - `pose_recorder/`: Pose Recorder, a separate tool addon (also meant for the Workshop): pose a ragdoll, snap keyframes, get ManipulateBoneAngles angles relative to the idle, as JSON. The owner poses dances with it and pastes the JSON; turn that into the endings' dances. Its maths is `pose_recorder/lua/pose_recorder/core.lua` (plain Lua, tested in the client smoke test).
  - `lua/`: a small shared addon part.
  - `_dev/`: the offline test harness (not shipped).
- Last commit at handoff: `5db2d2e` (Bloom hips-only sway; no inspections, crimes or lost standing during endings).

## The owner and their server

- Plays on Linux Mint, so give Linux commands.
- Dedicated server on a Hexane host, map `rp_c18_ug`.
- FastDL at `http://a29ka.hexane.co/9124749/garrysmod/`, which mirrors `garrysmod/`. The host panel has a "FastDL sync" button, and it has to be pressed after every upload, or clients don't get new files.
- **Where the owner's recordings are on their server: `garrysmod/sound/livingcity/overwatch/`, `.../administrator/` and `.../endings/`** (straight under `sound/livingcity/`, no `announce/` folder, not in the addon). The announcer reads both that and `sound/livingcity/announce/<voice>/`. Never hand over a `livingcity_sound.zip` that could replace their folders (it holds only READMEs); send a single new file on its own, saying exactly where it goes. A recording that "stopped working" means: run `lc_announce_clips` on the server first, it lists what the server found.
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
   - remove `livingcity/livingcity_sound` and `livingcity/pose_recorder`
   - zip it as `livingcity.zip`
   - send it to the owner as a file attachment.

   Never build a `livingcity_sound.zip` (the official folder is the server's `garrysmod/sound/livingcity/`). Build `pose_recorder.zip` (the `pose_recorder/` folder) when that does.

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

- harpies, bus, plane, standup, hard, base, marrow, bloom, water (the flood), shalom (the hora), fire (behinds on fire, then flying on them)

Each ending has a song and its own `lc_ending_<name>_*` cvars, all documented in the README's endings table.

Things worth knowing:

- **Archived server cvars keep their old values,** so changing a default doesn't reach existing servers. `LC.EndingRetune()` and its `RETUNED` table move exact old defaults to new ones. Add to that table whenever a default changes.
- **Song timing comes from a clock started when the song began playing** (`songAt` / SongClock on the client), because a BASS VBR mp3's GetTime drifts.
- **Things that fly are kept under the sky** with `LC.EndingCeilingAt` / `LC.EndingSky` (the bus, the plane, and Base's fleet). On the ground, the bus may drive through buildings; the owner likes that.
- **Placement uses `Ground()` and `RingSpot`,** which fall back to `LC.NavNodesNear`, because the map's landing zone is up on a roof.
- **Spectators (the dead):** `EndKey` and `LC.EndingPollKeys()` poll keys, because KeyPress doesn't always fire for spectators. Jump toggles free flight (OBS_MODE_ROAM).
- **ClientsideModels don't animate by themselves** (the G-Man), so their cycle is driven by hand.
- **Dances are bone manipulation on ValveBiped:** see "Bone axes" below (roll on the head is a twist, not a nod).
- **An ending in progress:** `LC.EndingSession()` returns its state (nil when none). It now gates:
  - the city events
  - the announcer and voice clips
  - the ambient music
  - the breencast
  - Civil Protection inspections (underground stops)
  - `LC.ReportCrime`
  - negative `LC.AddStanding`

## Waiting on the owner's playtest (unverified in game)

- **Bloom:** the sway is now a curve up the spine (the pelvis isn't turned: that lifted the feet); palms forward by a forearm twist (`lc_bloom_palm`, -90 if backwards).
- **Bone axes (confirmed by screenshots):** on the arms, yaw raises an arm forward (minus is up), pitch takes it out to the side (minus for the right arm, plus for the left), roll twists it; a forearm bends at the elbow on yaw. On the head and spine, yaw tilts side to side, roll twists, pitch nods. Thighs: yaw is forward and back. **Never bend the knee of a leg that's standing, or tip the pelvis** (yaw or pitch): either lifts the feet off the floor and the character floats. Twist the pelvis (roll) instead, sway the spine, and only bend the knee of a leg that's kicking. Everyone an ending holds in place goes exactly on the floor (no +1 or +4).
- Dances' hand and leg axes in general (Marrow kicks, club and rave kicks).
- **Standup:** can the hanged look around? Do the heads stay put? Are the white cones visible on everyone? Do the hanged go limp 3 seconds before the end?
- **G-Man:** the tiefidget sequence name, the jaw moving while he talks, and whether he only appears for the one player he's talking to.
- **Base:** the bomb count is no longer zero (the server log line says how many). Are the captions in time?
- **Spectators:** does Jump toggle free flight?
- **Flood:** Grigori visible and headbanging, the crowd on the raft, the ichthyosaurs biting NPCs, Jump at the edge climbing back on.
- **Shalom (new):** the kippah's spot on the head (`lc_shalom_kippah`), the hora's arms on the shoulders (`lc_shalom_pose`), the grapevine legs, the chair under the lifted person, Hebrew readable and right to left (fonts are `extended`; letters reversed by `LC_CL.Hebrew`), the flags and the hanukkiah. The rings are moved every frame by a server Think hook (`LC.ShalomStep`, also called from the tick so the tests reach it).
- **No inspections, wanted notices or lost standing during an ending** (just fixed after the owner lost 25 standing mid-Bloom).

## Later ideas

See TODO.md: screens drawn on terminals in the world, tuning the kick, long-term progression, more faces.
