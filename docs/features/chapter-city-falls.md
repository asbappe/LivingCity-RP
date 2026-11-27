# A chapter: the city falls to the Resistance (`sv_livingcity_chapter.lua`, `cl_livingcity_chapter.lua`)

The owner, 25 November, about the rocket in the Resistance's silo: "not necessarily a secret ending, but an ending of sorts; maybe a 'chapter' would be the better answer. I was thinking some sort of targetted explosion over the city that explodes in a massive energy effect/wave (maybe we can use the EP2 portal storm effects?) that kills all the combine and disables all their equipment, turrets, shields/forcefields, etc. which would allow the resistance to just walk in and take over. then we have a slight problem: the combine would need somewhere to respawn where they could setup base and act as a role reversal for a roleplay server story chapter ... maybe their arrest batons stop working or something? Their vests won't charge and their masks are glitchy and they can't see through them and they have to take them off? it's like a targetted EMP towards combine technology ... and all combine doors forceably open and stay open until the role reversal is reversed and the combine regain control".

It is **not** one of the secret endings: no vote, no time stop, no map reload. It is a lasting state of the city, kept over restarts, until the Combine take the city back.

**A second way in: [the Swarm](the-swarm.md)** (27 November): the vortigaunts' pheropods, the city's thumpers stopped, and their holder at the Nexus with the antlions bring the same chapter, with why `"swarm"`, whatever `lc_chapter` says.

**It is off until the owner turns it on: `lc_chapter` is 0.** With 0 the rocket's launch is only a launch. Staff can start and end the chapter whatever the setting (below), to see it.

## What happens, step by step

1. **The launch.** The map's launch is the map's own (`_dev/tools/map_launch.py`): the red button in the silo's launch room triggers the relay `lc_rocket_launch`, the countdown runs 30 seconds, then the rocket rises. The gamemode hears the relay (the `AcceptInput` hook). With `lc_chapter 1`, and **a Resistance Lieutenant or Commander at the button** (the same check as raising the headquarters' flag, `LC.BaseMayLead`), the wave is set for 30 + 25 seconds later: the countdown, then the climb. Anyone else at the button, the setting off, the lock on or the cooldown running: only a launch. The map allows one launch a map, so a second chapter needs a restart or a map change (or staff).
2. **The wave.** A burst high over the city (over the Nexus; with no Nexus on the map, over the players) and a wave rolling out over the whole map for about 6 seconds: a white-blue flash on every screen, a shell of light and a ring racing outward in the sky, a second paler flash as it passes over you, a long shake, thunder. **No words at all.** It is drawn with the game's own render calls. Episode Two's portal storm particles and sound are added when the game has them (looked for, never assumed).
3. **At once:**
   - **Every Combine NPC dies:** units, soldiers and scanners (by role), and by class manhacks, rollermines, hunters, striders, gunships, helicopters, dropship NPCs and snipers; the Cremators too. Whatever does not die of it is gone four seconds later.
   - **Every Civil Protection and Overwatch player dies.** No character ends with it (permanent death does not count this death): they come back as the units they were. The Administrator is a human and lives; her guards die, none come back, and her vest's charge is gone.
   - **The Combine's machines go dead:** forcefields and power banks (so every checkpoint's turrets too), any other `npc_turret_floor`, `npc_turret_ceiling`, `npc_turret_ground` and `npc_combine_camera` on the map (switched off, switched on again at the end), Combine monitors, city screens and loudspeakers, the scanner consoles (nobody flies a scanner), the mounted guns (nobody mans one), the suppression device, the scouting scanner a unit calls from HQ. Thumpers are left alone.
   - **Every Combine door opens and stays open:** doors tagged Civil Protection only, prison or the Administrator's office, and untagged doors in a Combine-only zone or by the cells. Unlocked, opened, locked in the open position, and looked at again every 20 seconds so one the map shuts opens again.
   - **The districts are the Resistance's**, crackdowns end, and the ledger swings hard: the Combine's strength and the Administrator's authority to 3, the Resistance's strength up 40. One line goes in the next City Bulletin.
4. **While the city is the Resistance's** (`LC.ChapterReversed()`):
   - **No Combine NPC comes out:** the street's units, soldiers and scanners, response forces, sweeps, raids on the headquarters, counter-forces, dropships, the Cremator, the Administrator's guards.
   - **The PA is silent** (Overwatch's voice and the Administrator's recordings), and **no city event starts** (curfew, lockdown, sweep, raid, ration call, exercise, parade); one running when the wave comes ends.
   - **A Combine-only zone is nobody's to trespass in**, and sociostability reads green.
   - **A unit's Arrest Baton does nothing:** a dry click and a fizzle for the blow and for the arrest, no glow at its tip, no words. (Searching and releasing with it, and cuffing by hand from F2, still work.)
   - **A unit's vest holds no charge:** forced to 0, the Commissary charges nothing, a suit battery is not picked up.
   - **A unit's mask glitches:** static, torn bands and the whole view dropping out every few seconds, strong on purpose. **F2 > Take off the uniform** ends it for the rest of the chapter (the owner, 26 November: "unmasked cops means they take off their CP uniforms"): they wear a citizen's clothes, with the face they chose for their character if it is a citizen's, and breathe gas like anyone else. They are still Civil Protection or Overwatch to the game (their side, their rank, who shoots at them). When the Combine take the city back they are in uniform again.
   - **Where they come back:** Civil Protection and Overwatch players spawn at a **Combine holdout** point (below). With none placed they come back at the Resistance's old spawn points (`rspawn`), and Resistance players at the units' own ground (a Combine-only zone, or by a Commissary). With a holdout placed the Resistance spawns where it always did.
5. **The Combine take it back.** Not before `lc_chapter_hold_minutes` (60) of server time have passed since the wave. Then Combine players standing in **the Nexus** start the hold: at least 2 of them, or 1 when 4 or fewer players are online. The Nexus is the Combine-only zone with the Administrator's desk in it (the `desk` point; with none, her office by its door or studio; with neither, any Combine-only zone).
   - The hold is 8 minutes on a clock that **runs only while a living unit stands in the Nexus** and stands still otherwise. This is holding ground against attackers, which house rule 9 allows.
   - **Waves of Resistance fighters come for it** (`LC.RebelWave`): the first 8 seconds in, then 70, 50, 40 and 25 seconds apart on the hold's own clock, 25 after that; each wave 2 plus its number plus the units inside, 8 at most.
   - **Shown in the world, not as a bar:** the Nexus's klaxon, slow and low at first, quicker and higher as the hold nears its end. One notice to each side when it starts ("Hold the Nexus. The city comes back with it." / "The Combine are in the Nexus. Drive them out.") and one when it ends. Nothing else is said.
   - **When it ends:** the doors shut and lock as their tags say, the machines come back, units spawn where they did, the PA returns, the districts go to contested, the Combine's strength goes to 40 and the Administrator's authority to 30, and the chapter cannot start again for `lc_chapter_cooldown_minutes` (120).

## Settings

| Setting | Default | What it does |
|---|---|---|
| `lc_chapter` | 0 | 1: the rocket launched by a Resistance Lieutenant or Commander brings the chapter. Staff start and end it whatever this says. |
| `lc_chapter_hold_minutes` | 60 | Minutes the city stays the Resistance's before the Combine can take the Nexus back. |
| `lc_chapter_cooldown_minutes` | 120 | Minutes after the Combine take the city back before the chapter can start again. |

Both clocks count the server's running time, not the calendar: a night with the server off does not use them up.

## The editor

**Point: Combine holdout (where units come back while the city is the Resistance's)**, kind `choldout`, in the Miscount Editor's list straight after the Administrator's desk and in the layout browser's "Civil Protection and the Combine" folder. Place one or several somewhere the Combine can set up a base. It does nothing while the city is the Combine's.

## Staff

**F4 > Factions > Admin: testing tools > The city** (superadmins):

- **Chapter: launch the rocket's wave (the city falls)**: the wave now, whatever `lc_chapter`, the cooldown or the lock say.
- **Chapter: the Combine retake the city**: ends it now (the cooldown starts).
- **Chapter: lock (nobody can flip it)** / **Chapter: unlock**: locked, neither the launch starts it nor the Nexus held ends it; staff's own two lines still work. The lock is kept over restarts.
- A line under them says how it stands (whose the city is, how long until the Nexus can be taken, the hold's seconds, the cooldown).

There is no console command.

## Saved

`data/livingcity/<map>_chapter.json` (through the safe file helpers): whose the city is, the seconds since the wave, the cooldown left, the lock. Written when any of them changes, every minute while a clock runs, and at shutdown. After a restart or a map clean-up the doors are opened and the machines switched off again.

## For other code

- `LC.ChapterReversed()`: true while the city is the Resistance's. The gates in other modules are one line each and ask only this.
- Hooks: `LivingCityChapterBegan(why, by)` (`why`: `"launch"`, `"staff"` or `"swarm"`), `LivingCityChapterEnded(why)` (`"retaken"` or `"staff"`). With `"swarm"` the Combine NPCs die of claws, not light, and the bulletin's line names the antlions; nothing else differs.
- `LC.Chapter.S` (the state), `LC.ChapterWave(by, why)`, `LC.ChapterBegin`, `LC.ChapterEnd(why)`, `LC.ChapterStatus()`, `LC.ChapterNexus()`, `LC.ChapterIsUnit(ply)`, `LC.ChapterVestDead(ply)`, `LC.ChapterMaskOff(ply)`, `LC.ChapterSpawn(ply)`, `LC.ChapterDeadTech(ent)`.
- The client knows through the global `lc_chapter` (the baton) and a unit's `lc_chapter_mask` (the glitch and the F2 line).
- Where the gates are: `LC.ManpowerCan` (units and soldiers, everywhere they come from the reserves), `SpawnScanner`, `LC.FlyDropship`, `LC.SpawnCremator`, the Administrator's `SpawnGuard`, `LC.HQScan`'s scanner, `LC.Announce` and the announcer's `Say`, `LC.StartEvent`, the trespass check (`LC.MayEnterCombine`), `LC.SocioAuto`, `LC.PowerBankLive`, `LC.FieldOff`, `LC.RefreshPower`, `LC.SuppressorFire`, `LC.CanLinkScanner`, `LC.TurretMayUse`, `LC.VestCap`, the Commissary's armour, the gas check, the spawn placing in `sv_livingcity_factions.lua`, and the Arrest Baton itself.

## Tests

`python3 _dev/run_section.py --unit Nov25_ChapterTests` (70 checks): off by default; the launch needs the setting and the rank; the wave's timing; who dies and who does not, and that no unit's character ends; machines dead and doors open and kept open; no Combine NPC spawning; the PA, events, trespass and sociostability; the districts and the ledger; the baton, the vest, the battery, the mask and its F2 line; the spawns swapped, and the holdout; saved and read back; the retake (not before the hold time, 2 units needed, the clock standing with nobody in it, the waves, the end putting everything back); the cooldown; the lock and the staff's lines. `python3 _dev/client_smoke.py` draws the wave and the mask's glitch and checks neither draws when it should not.

## Guessed, or not seen in the real game

Nothing here has run in Garry's Mod: it is tested in the offline stub only. To check in the game:

- **How the wave looks:** the size and height of the burst, whether the shell and the ring show well under the map's sky and fog (far parts may be cut off by the map's far clip), the flash's strength, the shake.
- **Episode Two's effects are guesses by name:** particle systems `aurora_shockwave`, `aurora_shockwave_ring` and `aurora_shockwave_debris` from `particles/aurora_sphere2.pcf` or `particles/aurora.pcf`; a sound found by searching `sound/ambient/levels/outland/` and `.../citadel/` for a portal storm's. If the names are wrong nothing of them shows and the drawn wave is all there is (the console may print an unknown particle system once).
- **How the NPCs die:** with shock and dissolve damage from the world, so they should go as a Combine ball's victims do; striders, gunships, helicopters and rollermines are also told to destroy themselves by their own inputs (`Explode`, `SelfDestruct`, `InteractivePowerDown`). Not seen.
- **The mask's glitch:** how strong it really is on a screen; it uses Half-Life 2's `effects/tvscreen_noise002a` for the static when it is there.
- **The baton's sounds:** `weapons/pistol/pistol_empty.wav` and `ambient/energy/spark1-6.wav`, quiet and high.
- **The alarm:** `ambient/alarms/klaxon1.wav` at the Nexus, pitch 80 to 130, every 10 down to 2.5 seconds.
- **Doors:** the same open-and-lock the secret endings use; a map's sliding Combine door that will not say whether it is open is opened once and not looked at again.
- **The numbers** (25 seconds of climb, 6 of wave, 8 minutes of hold, the wave sizes, the ledger's 3, 3, +40 and 40, 30) are first guesses for the owner to change.
- **Out of uniform** a unit wears Half-Life 2's plain citizen clothes (`models/humans/group01/`): whether the face they chose carries over, and how the first person hands look, is not seen yet.

## Left as they are (not gated)

- **Lights out** (the night's sleep and its dreams): it is every player's, not only the Combine's law, and it is tied into the dreams.
- **Jobs' and stories' own Combine NPCs** (a job's target, a story's soldier, an interrogator, a technician): they come outside the reserves on purpose, and a job that could not bring them would break. So a job may still put a unit on the street.
- **The collapse** (BLACK, the Administrator's last stand) and **the secret endings**: untouched; they should not be run together with the chapter.
- **The Administrator setting sociostability by hand**, the directives and the radio's calls to HQ: the menus still answer, though the PA says nothing and nobody comes.
- **A unit's shift, its quota and the job boards:** they go on as before, in a city the unit no longer holds.
- **The death card** of a unit killed by the wave reads as it does where permanent death is off ("you come back as yourself").
- **Stalkers** (the zones' and the terminals'), **vortigaunts in chains**, the ration dispensers, vending machines, Union terminals, street lights, the Commissary itself (it still hands out rounds and cuffs), the data and master terminals, the records, the radio.
- **The map's own Combine doors that are neither tagged nor in a Combine-only zone**, and doors that are props with an animation.
- **Unit players' NPC squads and partners** come from the reserves, so they are gated with the rest; nothing was added to tell a unit so.
- **The guide** (F1) says nothing of the chapter yet: it is off by default.
