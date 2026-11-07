# Living City: to do later

**Waiting on the owner:**

- **From the 7 November playtest, saved for the owner's decision** (not built; each changes how something works today):
  - **A Labor Assignment terminal.** Every new player registered at intake is assigned a Union job (the one with most openings, or at random) and is tied to it for 30 minutes or 4 shifts; housing can't be assigned before it; jobs change only by walking back to the terminal, where Infestation Cleanup (standing 25+) and the intake processor's desk (standing 50+) open up after the first stint. This replaces changing Union jobs from the board.
  - **Shared dreams in place of the endings** at a set time of night (a minute after the Administrator's good night), from a "dream" spawn point in an out-of-map area the owner places. Needs layers of safeguards so everything comes back on waking: pockets, weapons, SWEPs, tools, ammo, stats, hunger and thirst, credits, rank, job, clothes.
  - **Rebel food that scales with the player count** (about half the time something to eat, else fish, hunt headcrabs or birds, or trade with citizens and the quartermaster), so a few rebels aren't feasting while 32 would starve.
  - **The credits and standing audit** is written: `docs/dev/economy-audit.md`. Infestation Cleanup pays the flat shift wage (15 credits, +5 standing), the same as a litter sweep; what to change (a hazard rate per job, or credits from a quest's reward) is the owner's call.
  - **Stimulants** (cigarettes, beer, drugs) to skip a night's sleep or for stamina: brainstorm only so far.
  - **The Workshop dance animations** (3830765710, and the original 2538387266): taking another creator's animations into the gamemode isn't something to do without their permission. Listing the addon as a required Workshop download and playing its animations from there would work, if the owner wants that.

**Pending from the 1 November playtest (late)**:
- **Marrow with 100+ NPCs:** the crowding is fixed (rings spill outward, spawns avoid people, fallen NPCs come back). Unconfirmed: whether the `SendData reliable data too big (744335)` that dropped the owner in a loop came from the pile-up. If it happens again: the console log and the debug report.
- **Metrocop first-person hands:** done as the unit's own body with all but the arms shrunk (`lc_cp_hands own`); unconfirmed in game.
- **Unconfirmed in game:** sleeping NPCs as a ragdoll copy (head end: `lc_bed_head_flip`, height `lc_bed_npc_lift`), the hoover/sprayer/radio view placement (`lc_hoover_view`, `lc_sprayer_view`, `lc_radio_view`), suit hands (`lc_suit_hands`), Grigori's death (engine "vital ally"), boiling at the owner's fire barrels (if still failing: is it a map prop or the editor's fire?), the warning post placement, guards' teleporting, NPCs stepping aside.

- **From the owner's long list (1 November, late):** done: fight or comply on contraband, morticians and vortigaunt bodies, the editor's number ticks, "This person" (ask a name, recruit, send away), the multitool (NPC vortigaunts, the CP Commissary, its text placement), street vortigaunts (shackled, left alone, sweeping: the sweep animation's name is a guess, check in game), cleanup markers. Still open:
  - Quest markers vanishing when exhausted: likely the "Get some sleep" step taking over the marker; check in game.
- **Sleeping rebels waking:** done (1 November, late).

**Open right now** (2026-10-31):
- **Map lights twinkle** on `rp_c18_ug`: waiting on the owner's Sandbox test of the same map.
- **Rewording:** finished (2026-11-01). Batches 1 to 5 reworded; the rest (side jobs, Resistance ops, the underground, the shop) were already plain; "primary fire" now reads "left click".
- **The owner's corrected PLAYER_TEXT.md**: apply with `_dev/apply_player_text.py` when it comes.
- **Full test run** (2026-11-02): 2994 passed, 6 failed; all 6 passed in the run before (flaky: "Stop and search", where the unit is sometimes pulled into a fight with a rebel NPC first, and "R on a good part" on the factory line, waiting on parts). Worth making those two tests steady.
- **A local out-of-character text chat** (the owner's list of 2026-10-29): it already exists (checked 2026-11-01): `/looc` (since 2026-10-17), also C > Talk > Out of character, nearby, and F1's quick menu. Asked the owner whether they meant something more (for example its own chat box); remove this line if not.


- **Terminals with their UI on their own screens:** built (2026-11-01; cl_livingcity_screens.lua): Civil Intake, Housing Allocation, the CP Commissary's counter. Waiting on the owner to see where the screen stands (in front of the terminal, 54 units up; `Frame` in that file).
- **The kick, tuning.** The leg animation is bent in code (cl_livingcity_kick.lua, LC_CL.KickPose and LC_CL.KickAxes), so it may want adjusting by eye in game; likewise how far an Elite's door flies and how hard a Soldier's tips over (lc_kick_door_power).
- **Faces.** Enhanced Citizen v5 Faces only sharpens the existing 15; its Playermodels add-on is about 590 MB, so skipped. (The Black Mesa citizens pack is in: `lc_bms_people`.)
- **Pose Recorder 2: make it self-serve for the whole community** (pose_recorder/, before publishing it to the Workshop), so nobody needs a coder in the middle. First, in one update: (1) playback built in: `pose_play <name>` on yourself and a context-menu "Play animation" on NPCs, seen by everyone, loop, once, speed or hold the last pose; the server only sends "this entity plays this from now", each client eases the bones itself; (2) smoothing as buttons: easing per keyframe (smooth, snappy, bouncy, linear), mirror left and right, each keyframe's length, wrap the loop or stop; (5) sharing: animations as small files, packs bundled in other addons' `data_static/pose_recorder/` and picked up automatically, and `PoseRecorder.Play(ent, "wave")` for Lua coders. Then a second update: (3) a timeline strip (click a keyframe to jump back to it, reorder, duplicate, delete, scrub), and (4) putting a saved pose back onto a ragdoll (a pose library for screenshots and comics). The limit to say on the Workshop page: these are bone turns on top of the model's idle, not compiled animations, so they can't change walking or running; exporting real animation files (SMD) for modelers is a separate, later project.
- **The lost "v2.7" pieces:** all rebuilt (2026-11-02): stamina, lowered guns, brandishing, obituaries, longer detentions, finding by citizen number, breathing sway and colour grading. (Citizen numbers themselves already existed.)
- **Sealed directives** (built 2026-11-02): check in game; the G-Man's Episode One lines may not be on the server (the owner's list from the sound search). Still open: the city's own way into All your base (the master data core to a lab scientist); more Administrator powers later.
- **Resistance Insider:** built (2026-11-01; README, "The Resistance Insider"). Waiting on the owner's playtest. Not built from the design: letting a prisoner slip on the march (Inside Work's "A quiet release" covers the cells).

## Moved from HANDOFF.md (2026-11-02)

### Waiting on the owner (from the last session)

- **The map's lights twinkle.** Not the day and night dimming (`lc_daynight_light` doesn't exist as a command; turning it off didn't help). Asked the owner to load `rp_c18_ug` in plain Sandbox: if it twinkles there too, it's the map or their graphics, not the gamemode.
- In game: raids and sweeps visible, the editor-tool calm, the Radio transmitter in the hands (how it looks), the apartment TV's picture (moved back about 2 units and stretched to the glass's height; adjust `GLASS` in `entities/entities/lc_screen.lua` if needed), cuffs, machine hacking, the parcel sender.
- Their corrected PLAYER_TEXT.md, whenever they send it.

### Waiting on the owner's playtest (unverified in game)

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
