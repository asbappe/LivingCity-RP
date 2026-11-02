# Living City: handoff to a new session

`CLAUDE.md` (loaded into every session) and **`CORE.md`** (the core: what must not change without the owner's OK, and the owner's real server setup) come first. Then this, then README.md (what the gamemode does, every setting) and PLAYTEST.md (the owner's in-game checklist).

## The project

Living City is a Garry's Mod Half-Life 2 roleplay gamemode.

- Repo: `asbappe/LivingCity-RP`. **`main` is the official branch** (the owner, 2026-10-16). Start from `main`, work on the session's branch, push it with `git push -u origin <branch>`, and when a change is finished and tested also fast-forward `main` (`git push origin HEAD:main`; merge first if `main` moved, never force). Do not open pull requests unless asked.
- Layout:
  - `gamemodes/livingcity/`: the gamemode. Modules are in `gamemode/modules/server` (about 96 files) and `gamemode/modules/client` (about 42). `gamemode/cl_init.lua` holds the in-game guide text.
  - `livingcity_sound/`: notes only (the triggers' READMEs and ANNOUNCEMENT_SCRIPTS.md). The owner's recordings and songs live in the server's `garrysmod/sound/livingcity/`, the official folder; never ship this folder.
  - `pose_recorder/`: Pose Recorder, a separate tool addon (also meant for the Workshop): pose a ragdoll, snap keyframes, get ManipulateBoneAngles angles relative to the idle, as JSON. The owner poses dances with it and pastes the JSON; turn that into the endings' dances. Its maths is `pose_recorder/lua/pose_recorder/core.lua` (plain Lua, tested in the client smoke test).
  - `lua/`: a small shared addon part.
  - `_dev/`: the offline test harness (not shipped).
- Last commit at handoff: `ba243cd` on `main` (2026-10-31: the apartment TV's picture). The last session's branch was `claude/intelligent-curie-p02qp4`, same commit.

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
- **The owner asked (2026-10-31) to stop testing every single thing: it eats their usage.** Compile-check changed files and run only the test section you touched; run the full suite only when they ask (or before a big merge they ask for). Compile check: `python3 -c` with `from lupa import luajit21 as lupa` and `loadstring` on the file (the default lupa runtime has no loadstring).
- One section only: copy the prelude of tests.lua (its first ~440 lines and the `withRoll` helper) plus the section, and run that file with `run_tests.py`. Watch for locals a section borrows from an earlier one (for example `FAR`).
- Full tests: from `_dev`, `timeout 6900 python3 run_tests.py tests.lua` in the background (about 40 minutes). It includes the core snapshot check. **Not run since rewording batch 2 (commit `3cb0064`);** only the client smoke test and single sections since. To stop a run: ``kill $(pgrep -f "^python3 -u run_tests.py tests.lua")`` (a `pkill -f` with that pattern kills your own shell). For only the ending tests, make a trimmed copy of tests.lua with these parts, in order:
  - lines 1 to 404
  - lines 427 to 434
  - the `function EndingTests` block through the `EndingTests()` call
  - the file's last 3 lines

- Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs. There's no HSVToColor. `Entity()` returns nil in the smoke test, and OBBMaxs defaults to (2,24,96). LerpAngle and MOVETYPE_NONE were added. Add whatever else is missing to `gmod_stub.lua`.

## The last session (2026-10-29 to 10-31): getting ready to open the server

Every commit says what it did; TIMELINE.md has the summary. The big pieces:

- **PLAYER_TEXT.md**: every line of text a player sees, for the owner to correct and send back. Regenerate with `python3 _dev/player_text.py` whenever player text changes. When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md` (matches each changed line by its old text near its file and line; strings built from several pieces or ending in a placeholder may need doing by hand). Lines starting "> Note for you (not shown in game):" are the code's notes, not game text.
- **Rewording into plain words** (the owner loved it: "can't you go through and reword everything in the game this way?"): batches 1 to 3 are in the code (the in-game guide, pop-up tips, the job board's quests and story chains, job text). Drafts and originals are in `_dev/rewording/`. **Batches 4 and up are waiting for the owner to ask** (largest left: underground ~170 lines, CP tools ~91, Resistance ops ~95, events ~78, intake ~75, side jobs ~95, shop ~217).
- **Public server safeguards** (`sv_livingcity_guard.lua`: net message and chat flood limits), capped drops, one pickup per item, issued items can't be sold or passed on, cooldowns on BOLOs, tickets and character submits.
- **Radio transmitter** (`weapon_lc_radio.lua`, contraband): held in the hands (no gun at the same time), tuned to the CP net or Freq 7, soft static while held. Plain radios only listen. No more music on Freq 7.
- **Couriers** meet the sender (take, refuse, report or open the parcel); the Resistance has Smugglers.
- Rent 15, cuffs (were zip ties), hacked machines pay out 5 to 8 items, healing only from food, sleep and medicine, a locked apartment door stays locked for its owner too, the ration line's front walks up to the dispenser, rain washes decals (never graffiti), the stove's crackle stops, the stash only opens from furniture at home, the editor shows only the held tool's markers when markers are hidden, people walk round turrets.
- **Raids really happen now** (2026-10-31): a block raid spawns its own team just out of sight near the block (never the city's patrols, the owner's call), and is not announced at all if nobody can be sent. Sweeps into rebel territory start from a spot with a way in, use the city's routes, and their clock starts when they arrive.
- **Admins holding the editor tool**: no hunger or thirst, and the units leave them alone (`LC.EditorHeld`).

## This session (2026-11-01), cut short (out of usage)

- Ration cards come only from finished Union shifts (`lc_shift_ration_cards` 1); each ration takes one; no credits with a ration; Civil Intake no longer issues or replaces cards (`lc_card_fee` removed). Snapshot updated with the owner's request.
- Citizens sleep on beds in habitation blocks at curfew, lockdown and night (`lc_citizens_sleep`, `lc_bed_head_flip`; sv_livingcity_rest.lua, GoHome in sv_livingcity.lua); players lie on the bed with the camera on the pillow (cl_livingcity_rest.lua, sh_livingcity_acts.lua).
- **Not verified:** the full test suite was started but not finished (no failures in the part that ran); the new tests (PapersHousingTests, NextStepTests, HygieneTests) never completed a run. Client smoke test passes. Run the full suite first next time.
- **Rewording batch 4** (Civil Intake and Housing Allocation) is in the code; originals in `_dev/rewording/batch4_intake.md`. Kept the phrases the tests look for. Batch 5 (Civil Protection's tools; the cuffs no longer say "ties" or "plastic") too.

## Later the same session (2026-11-01)

- The owner's playtest notes, all fixed (README, "The 1 November playtest"): infestations no-go for NPCs, rebels on the editor's beds, sweep teams doing the job (scientist, pots, crates), rebel health and weapons, Combine weapons, triage injuries, credits and traits on the HUD, job tools taken back, bins you stand by, the jog's barks, reward and reprimand.
- Rewording finished (batch 5: Civil Protection's tools, cuffs; "primary fire" is "left click"; the rest was already plain).
- The Resistance Insider built (`sv_livingcity_insider.lua`): the Inside menu, the leaders told, caught means Resistance for good.
- Terminals on their own screens (`cl_livingcity_screens.lua`): Civil Intake, Housing Allocation, the CP Commissary. Where the screen stands is a guess (in front, 54 units up): adjust `Frame` if the owner says.
- The "Move it" bark file names are from memory: if a unit goes silent on the jog, a file name is wrong.
- Weedkiller against the infestation (`sv_livingcity_cleanup.lua`, `entities/entities/lc_nest.lua`): growths in infestations, Infestation Cleanup (15th job) with guards (NPC state `cleanguard`), barnacles, the firebomb, poison gas for units only, fouled filters and spiked food for the Insider, sweeps opening with gas. The growths' built-in model paths are from memory (antlionhill, antlion_grub, charple01, then a rubbish bag): check what shows. The owner's workshop pack (id 2043900984) is Half-Life: Alyx's Combine hazard props (`models/hlvr/combine_hazardprops/combinehazardprops_*`: barrel, barrel_lock, clothe, container, crate, detector, forcefield_left/right, hoover, lamp, trashbag, warningsign) and Xen gunk (`models/hlvr/distillery_gunk/distillerygunk_gunk.mdl`). The growths use the gunk when it's there; the warning posts and bags use the props. The hazmat suits come from a second pack (id 3185145650): `models/player/` and `models/npc/` `worker_male`, `worker_female`, `engineer_male`, `engineer_female` (hands `models/weapons/c_hands/c_worker_arms.mdl`, `c_engineer_hands.mdl`, registered by the pack's own autorun). They're the cleanup job's automatic outfit (Job outfits entry marked `lcAuto`, replaced as soon as the owner saves their own), `lc_cleanup_suit` worker/engineer. The owner confirmed: worker = the hazmat suit (cleanup), engineer = overalls without filter or tank, worn by Mortician, Sanitation and Reclamation (DIRTY in `sv_livingcity_cleanup.lua`). Male or female comes from `LC.PlayerSex` (the creator's face, `lc_model`) and NPCs' own `gender`, never from FaceOf alone. The suits are worn only for the work (the owner): outfits marked `onDuty` (the automatic ones) are worn by players only on a shift (`LC.PlayerOnDuty`), by NPCs only while `st.npcWork` is set, with 90 seconds' grace between tasks, off at once going to bed, curfew, lockdown or leaving (`LivingCityDutyClothes` timer in `sv_livingcity_outfits.lua`).
- The cleanup is three steps now (the owner): spray kills a growth (`LC.KillNest`, NW `lc_dead`), the hoover (`entities/weapons/weapon_lc_hoover.lua`, a job tool) vacuums dead ones (`LC.VacuumNest`, NW `lc_hoover_load`), E on the warning post's barrel empties it (`LC.DumpHoover`), right click bags it only where no barrel is within 3000 (`LC.BagHoover`). Dead growths rot after `lc_nest_rot_minutes`. The hoover has no viewmodel: the prop is drawn at EyePos plus `lc_hoover_view` (a guess; the owner may send better numbers) and on the right hand bone in third person.
- The Black Mesa citizens pack (534130993; the owner sent its model list): with it on the server and no looks set for Everyone else (no job), about half the jobless NPCs wear its citizen or refugee NPC models (`lc_bms_people` 50, new; `LC.BlackMesaLook` in sv_livingcity_outfits.lua), and the character creator lists its citizen and refugee player models; players download it on joining. A look that keeps faces (`{face}`) on someone with no numbered face now picks a face of their sex (was always male_01).
- The owner's Marrow crash (1 November): with 100+ NPCs, the ring endings (Harpies, Bloom, Marrow, Hard) put everyone on one small ring, inside each other; the engine pushed some through the floor (endless "Ignoring unreasonable position" in the console), CPU hit 100%, and the owner's game was dropped in a loop with `SendData reliable data too big (744335 > 262107)`. Now: `LC.EndingRingSpots` gives each their own spot and spills onto more rings; `LC.FreeSpawnPos` keeps the city's spawns off each other; `LC.RescueFallen` (timer LivingCityFallen) puts an NPC out of the map back where it last stood after two seconds, or removes it. The 744 KB send is thought to be the pile-up's entity update (not confirmed: ask for the console if it happens again). NPCs were also falling out of the map before Marrow (lc_npc_725), probably from the same crowding at spawns.
- 2026-11-02 (the owner asked: "yes please do these"): the lost v2.7 pieces: stamina (sh_livingcity_stamina.lua, `LCS`; `lc_stamina*`), guns (the owner refined it: contraband on the streets, wanted at once when seen; carried lowered only on rebel ground and for metrocops on the Combine's ground, `lc_carry_lowered` set by `LC.BrandishTick`, `LCL.MustLower`; warnings then fire from rebels (`LC.RebelSetFoe`) or the Overwatch's soldiers), obituaries (sv_livingcity_streetlife.lua; `lc_brandish*`, `lc_cp_raise_xp`, `lc_obituary`), longer street detentions (`lc_street_detention_per_minute` 10, `lc_street_detention_max` 60; `ply.lcWantedSince` set in LC.SetWanted), LC.FindPlayer by citizen number or character name, breathing view sway and colour grading (cl_livingcity_view.lua; `lc_color_grade`, client `lc_my_color_grade`). The Administration path: Records Clerk shifts count `lc_admin_clerk_minutes` (20) each towards `lc_admin_hours` (`LC.AdminHours`). `/stand` is the acts command again (the election had taken it). The ending triggers: a draft for the owner, ENDING_TRIGGERS_DRAFT.md (Administrator-unlocked endings with riddles, and in-play triggers); build once they pick.
- The owner's playtest of it (1 November, late): ERROR growths (stand-ins drawn client-side now, and `resource.AddWorkshop` for both packs: `lc_workshop_packs`), no warning posts (they needed the pack; now always placed, with cones and an oil drum as stand-ins, and the barrel is its own entity `lc_hazbarrel`, also an editor fixture), the vacuum count stuck at 1 (the event fired after the entity was removed: fixed, events before Remove), no weedkiller (now given first, topped up at shifts and when out: `LC.IssueWeedkiller`), guards lost (questLock while guarding, teleport back after 4 s beyond 700, a spawned cop when none free, fights don't drop them), hoover invisible (PreDrawViewModel returning true stopped PostDrawViewModel; an empty WorldModel stopped DrawWorldModel), suit hands too far (`cl_livingcity_suit.lua`, CalcViewModelView), geiger 40% calmer. Also from that playtest: F4 rebuilt as collapsible headers (cards were measured before wrapped text grew), Stalker hidden on F4, Fighter needs trust jobs (`res_jobs` counter), rain filling removed, boiling by particle fires. Then: filing explains itself (register status, why right or wrong), sleeping NPCs as a frozen prop_ragdoll double (`LieDouble` in sv_livingcity_rebellife.lua; the NPC hidden and non-solid under it), career paths (`path` on jobs, `LCJ.Paths`, CP counts `cp_shifts` from Intake and cleanup), Block Warden at 100 and hidden below, units spawn in a Combine zone, `lc_cp_hands`, the radio raised (`lc_radio_view`).

## Testing state (2026-11-01)

- **The owner asked: no full test suite for a while.** Use the client smoke test and single sections only.
- The last full run that finished (2026-10-31 night): 2869 passed, 9 failed. All 9 were fixed and the touched sections re-run (UndergroundTests, the Mole Hunt, the 1 November section: all pass). Not run since: the vortigaunt additions, the loyalty test's real prisoner, Proof, the faction progress bars (each has its own passing tests in "The 1 November playtest" section).

## Waiting on the owner (from the last session)

- **The map's lights twinkle.** Not the day and night dimming (`lc_daynight_light` doesn't exist as a command; turning it off didn't help). Asked the owner to load `rp_c18_ug` in plain Sandbox: if it twinkles there too, it's the map or their graphics, not the gamemode.
- In game: raids and sweeps visible, the editor-tool calm, the Radio transmitter in the hands (how it looks), the apartment TV's picture (moved back about 2 units and stretched to the glass's height; adjust `GLASS` in `entities/entities/lc_screen.lua` if needed), cuffs, machine hacking, the parcel sender.
- Their corrected PLAYER_TEXT.md, whenever they send it.

## The secret endings (reference)

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
