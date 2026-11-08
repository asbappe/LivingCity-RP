# Living City: to do later

**Waiting on the owner:**

- **From the 7 November lists (part 2), waiting on the owner's answer:**
  - **A "Black" sociostability level?** Soldiers now leave their Combine zones only when deployed or at red. Not added; the owner floated it with a question mark.
  - **Which voice says what:** `lc_announce_admin_share` is still a coin toss between the Administrator and the Overwatch voice for each announcement (`docs/dev/pacing-audit.md`).
  - **Streetlights and loudspeakers inside Combine zones** stay broken now that no citizen goes in: let the stalker mend them too?
  - **The economy audit** (`docs/dev/economy-audit.md`): what to change is the owner's call.
  - **Stimulants** (cigarettes, beer, drugs): brainstorm only so far. **G-Man events pushing the Administrator** now the endings are dreams: brainstorm later, as the owner said.
  - **The future endings setup:** the G-Man is set aside (`lc_directives` 0). Ideas to start from, in `docs/features/endings.md` ("Ideas for the future endings setup"): a refused directive makes dreams keep (waking with the dream's weapons and stats) or leak into reality (a one-time mingebag swarm on Civil Protection as the dreams end).
  - **The Workshop dance animations** (3830765710, 2538387266): only as a required Workshop download, with the owner's say.
  - **Unconfirmed in game:** everything in PLAYTEST.md's "7 November, part 2" section, above all the dreams (the per-NPC hold, out-of-map ground) and the arrest struggle.

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
- [ ] **Combine sleep (the owner, 8 November, an idea for later):** the Half-Life: Alyx prop of a Combine soldier asleep upright in a head-clamp rig (needs the model from Half-Life: Alyx, ported or from the Workshop, since Garry's Mod doesn't ship it); Combine soldiers sleep only once every few days, in it. Overwatch Elites never need to sleep.
- [ ] **Propaganda dream idea: The Battle Line** (the owner, 8 November: "glowing red and evil looking rebels are swarming a combine battle line with an APC and barricades, and the dreamers are expected to help shoot and kill the rebels; shooting at the combine unleashes a huge swarm of man hacks that target only the player that shot the combine"). Design: dreamers get a dream-only gun; rebels are real NPCs tinted red with a red glow, Combine soldiers, an APC prop and barricades hold a line; dreamer damage to dreamers is zero; a shot at the Combine (EntityTakeDamage, attacker a dreamer) is cancelled, counts as an offence (loyalty) and spawns 8 to 12 manhacks liking everyone but that player; a dreamer "killed" is out (no real death). Needs: relationships set per dreamer (Combine like them, rebels hate them), and checking NPC movement at the dream point (no nodegraph there).
- [ ] **Vortigaunt dream warfare idea** (the owner, 8 November: freed vortigaunts "can appear in their purple skinned form ... and alter the dream to make the combine and administrator look bad ... a sort of psychosis dream warfare thing"; "The more vortigaunts freed and still alive, the more influence they have on dreams"). Design: influence = freed vortigaunts alive (players and NPCs), shown to the Administrator on the tablet. Each propaganda dream rolls a chance (say 10% per freed vortigaunt, capped) that they break in: purple vortigaunts (the healing-glow skin) appear, the colours turn, her figure flickers into something unflattering, her lines are answered by theirs, Combine soldiers in the dream falter; dreamers who side with the vortigaunts (a choice or a mechanic per dream) gain the opposite of the loyalty loss, those who stay loyal get a bonus against them. A tug-of-war meter between her and the vortigaunts decides how the dream ends and the morning line. Needs the owner to say how vortigaunts are "freed" today (sv_livingcity_vort.lua) and what siding with them should cost or earn.

**From 7 November, part 3 (left for later):**
- **Performance, would change timing (`docs/dev/performance-audit.md`):** cache each NPC's "is anyone looking" answer for about a second, cache "seen by security" for a fraction of a second, cache the client job-game halo lists, move HUD colours out of per-frame code. Each needs the owner's OK.
- **Network, engine side (`docs/dev/network-audit.md`):** NPC name/job/doing strings add about 20 KB to a joining player's first update at 100 NPCs; cutting them would change what players see.
- **Older code treats grown territory as a circle** (scavenge bins, rebel life, decorating the ground, the "wet ground" spot check): approximate for ground grown along path nodes.
- **`LC.IsNight` is defined twice** (atmos: night only; rest: night or dusk; the rest one wins). Check which is meant.
- **DreamTests "the awake aren't touched"** is flaky (the awake test citizen may get a random Union job's tools).
- **NPC sight cache: measured, not merged** (branch `worktree-agent-a27078de119d0e273`): at 1 second it never hits (far NPCs only think every 2 s), and the sleep check makes only about 6 sight traces a second at 83 NPCs, so the "thousands a second" estimate was wrong. Nothing to do.
- **Done (8 November): the snapshot now matches the game and is sorted.** Was: **Core snapshot copy (owner OK'd, 8 November):** the approved changes (NPC cap 100, six food settings, `lc_burn_evidence`, `/letslip`) still need copying into the core snapshot; this session's permission rules wouldn't let the copy run. The owner (or a session allowed to) copies the `.new` snapshot over the old one after one `python3 _dev/run_parallel.py`.
- **Random tests:** "a headcrab near: it runs, no vortessence (the collar)" (1 November playtest unit) and the collared vortigaunt sweeper move: each fails now and then, before this session too.
- **Pose Recorder 2, second update:** the timeline strip (jump, reorder, duplicate, delete, scrub) and putting a saved pose back onto a ragdoll.
- **Random test:** "shifts appear on the board" (Occupations) can crash when no spot is found in 6 tries (seen once in a full run).
- [ ] **Questions for the owner (vortigaunt dream warfare):** (1) How does a vortigaunt count as "freed" today? (2) What should siding with them in a dream cost or earn?
