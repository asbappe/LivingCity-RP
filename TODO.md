# Living City: to do later

**Waiting on the owner:**

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
