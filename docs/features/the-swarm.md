# The Swarm: the city falls to the antlions (`sv_livingcity_swarm.lua`, `cl_livingcity_swarm.lua`, `entities/lc_swarm_extract.lua`)

The owner, 27 November, on a second way into the chapter [the city falls to the Resistance](chapter-city-falls.md), the Half-Life 2 way: "we'll want the highest ranking player on the server to get the pheropods, and if they leave or disconnect, then the next highest ranking player gets them, and they function just like in HL2: you can control antlions and the mission becomes 'disable the thumpers' and then once the player with the pheropods is inside the city, antlions function just like in Nova Prospekt and spawn near the pheropod equipped player and attack the combine/metrocops automatically and just like in HL2: throwing a pheropod on an NPC or player spawns extra antlions that then swarm the target and any other enemies nearby. And have it on by default ... then they can turn purple like in HL2 and start chanting ... also the antlion nest needs to have the EP2 antlion guardian spawn and come straight out of the gate when it is opened and another when the extract/honeycomb prop thing where the essence is is reached and harvested." And later that day: the pheropods destroyed once the city is taken, "so that they don't eternally have access to infinite antlion armies ... they would need a quest to re-enable the combine thumpers"; the Combine get rid of the extract simply ("they just confiscate it ... destroy it if it's in their pockets, if it's on the ground and they shoot it, or if they kick/stomp/hit it"); the ritual's five conditions; and "killing the glowing antlion guardian" as what ends the hive's hunt.

The lore: the Resistance's freed vortigaunts make pheropods (bugbait, as at Nova Prospekt) from the nest's larval extract (Episode Two); with the city's thumpers stopped, the antlions overrun the Combine. **The rocket's way stays as it is.**

**It is on: `lc_swarm` is 1** (the owner's choice). With 0 nobody can harvest the extract, no ritual starts and the city does not fall to the swarm by itself; the door's guardians and the map's own wiring still run, and staff's lines (below) still work.

It works only on a map with the forest cave's nest (`_dev/tools/map_forest.py`, `docs/dev/map-building.md`) and, for the mission, the canal ring's thumpers; on a map without these names nothing of it happens.

## What happens, step by step

1. **The emergency door's guardian.** When the nest's emergency door opens (the map's relay `lc_nest_opened`), an Episode Two cavern guardian (`npc_antlionguard`, the cavern breed as Garry's Mod's own "Antlion Guardian") stands on Valve's planks just behind the shutter, at the door's own floor (never down in the cleft), and as soon as the shutter is high enough (4 seconds) it charges out through the doorway at whoever opened it (whoever pressed one of the two buttons last). The shutter's opening, 192 wide and 152 high when up, takes the guardian (80 by 100). This one may charge: Garry's Mod's "Antlion Guardian" is also "in cavern", which stops it charging, so this one is not. Never two from the door at once, and none for 10 minutes after one dies. It comes whatever `lc_swarm` says.
2. **The harvest.** Anyone but the Combine holds E on the larval extract (the map's `lc_nest_extract`, the essence floating over Valve's honeycomb) for 5 seconds, looking at it from within 300 units (the essence has no collision of its own: E on it is a look). No bar: the essence brightens as it is drawn out and a sound rises with it. The nest wakes: the grubs squeal, the ground stirs, and two antlions dig up round the harvester. Let go or look away and it stops. At 5 seconds the essence is gone from the honeycomb, the harvester carries it (glowing), and **a second guardian bursts up out of the chamber's floor** (this one Episode Two's own way: poison, no charge) and goes for them. Once for each harvest.
3. **The hunt.** For as long as that guardian lives, the hive hunts the essence wherever it is (carried, dropped, or in a vortigaunt's hands, even at the headquarters): antlions dig up near it, behind the carrier, every 15 to 20 seconds, 4 out at most, and go for whoever has it first. Kill the glowing guardian and the hive's claim is broken: no more come, and those left dig away half a minute later.
4. **Fragile.** The carrier dies or leaves the server: the extract lies glowing where they fell (`lc_swarm_extract`). Anyone not Combine picks it up with E. It is destroyed, with a wet burst and no words, when:
   - **it is in a Combine player's pockets:** a Combine player's E on it on the ground; a unit's search, pat-down or cuffs on the carrier; a carrier who joins the Combine;
   - **the Combine hurt it on the ground:** shot, struck, blown up (damage from Combine players or Combine NPCs), or a unit's boot on it. Anyone else's damage does nothing to it, so a rebel's stray shot does not throw the run away.
   - **Combine NPCs who see it go for it:** units and soldiers within 1500 units who can see it drop what they are doing, shoot it where they have a clear shot (an invisible `npc_bullseye` on it, which only they are told to hate) and run to it otherwise; whichever reaches it first ends it.
   Destroyed, or left untouched for 10 minutes, it is back in the nest (the essence shows again).
5. **The keeper.** The carrier hands it to a freed vortigaunt with E. The vortigaunt holds it as Episode Two's does (ep2_outland_02: the sequences `nectar_recieve`, then `idle_nectar`, the little essence on its `nectar` attachment) and stays put until the ritual. If it dies, the extract falls where it stood, with the rules above.
6. **The ritual.** A Resistance player's E on that vortigaunt starts it once **all of these** are true; otherwise one short line says what is still missing ("Still needed: ..."), and nothing else happens:
   - the Resistance's headquarters is live at the mine (its territory is that of the cave map's `lc_hq_setup_cave`, Ravenholm's big room);
   - at least 3 freed vortigaunts, alive (the city's freed ones and Free Vortigaunt players together, as the hive mind counts them);
   - the ledger's Resistance strength at 70 or more;
   - the Resistance holds at least 2 districts;
   - the mine's flag has flown 2 hours of server time (a ransack, a strike or a move starts the count again; overrun at half mast, it stands; kept over restarts);
   - and the city can fall: not locked, not cooling down, not the Resistance's already, no rocket on its way.
   The freed vortigaunts within 1500 units (up to six) gather round the keeper, turn blue-purple (their own `TurnBlue`, and Valve's `turn_blue` and `surgery_sustain_idle` animations where the model has them; without them they walk into the ring) and chant (Half-Life 2's `vortigese` lines) for 15 seconds; Free Vortigaunt players near glow with them. Then the extract is used up and **the pheropods go to the highest-ranking Resistance player online**, not necessarily whoever brought it: a tie goes to whoever brought it, then to the one longest online. **One a map.**
7. **The pheropods** are Half-Life 2's own `weapon_bugbait`, in the holder's hands only: nobody else can pick them up and none is left lying about. Death keeps them (they are in hand again on coming back); leaving the server or the Resistance hands them to the next highest. Thrown, where the pod bursts up to 3 more antlions dig up and the swarm goes for the person or NPC it hit (never one of the Resistance's own), then for any enemy near; thrown at nothing, the swarm goes there and fights what it finds. Squeezed (right click), the swarm comes to the holder. The swarm's antlions are the allies of Resistance players, fighters and vortigaunts, and the enemies of Combine NPCs, units and the Administrator; citizens they leave alone. (Each antlion is told so itself: Half-Life 2's own `antlion_allied` would make every antlion love every player, units too.) While the pheropods are out, the trickle of antlions at a stopped thumper (`wildlife.md`) is the swarm's too, and never comes for the Resistance's own.
8. **The thumpers, then the swarm.** One notice when the pheropods are given (to the holder: "The pheropods are yours. Stop the city's thumpers."; to the rest of the Resistance: who has them). The thumpers are stopped with their own buttons. When every thumper on the map is stopped (one more notice to the Resistance: "The thumpers are down. Take the swarm to the Nexus."), or the map has none, and the holder is in the city (in or within 2500 units of a housing block, a Combine-only zone, the prison or the infestation; a map with none of them: anywhere), antlions come as at Nova Prospekt: they dig up near the holder, up to three at a time every 20 seconds, 6 at most (10 with what thrown pods bring), follow the holder and go for the Combine near them on their own. A thumper started again drives them off near it (the game does that itself) and none come within its reach.
9. **The fall.** The holder in the Nexus (the chapter's: the Combine-only zone with the Administrator's desk) with the swarm near, every thumper down, and the city able to fall: antlions burst up on the Combine's NPCs and units across the city (16 at most) with dust and the ground shaking for everyone, no words; two and a half seconds later the chapter begins with why `"swarm"`, whatever `lc_chapter` says (that is the rocket's switch). From there the chapter is as it is: units die and come back as before, no character ends, doors open, machines go dead, the districts and the ledger swing; one line in the City Bulletin ("Antlions overran the Combine. The city has fallen to the Resistance."). The Combine NPCs die of claws, not light.
10. **After the fall.** The pheropods are **destroyed for good**: taken from the holder, nobody gets them after that, and none can be made again this map. The antlions are **nobody's now**: the Resistance are their enemies too; those out carry on as wild ones, and the thumper module keeps bringing them at stopped thumpers. Every thumper left stopped is **broken**: its button only fizzles until it is mended. (The same if the rocket's wave takes the city while the pheropods are out.)

## Restart the thumpers (the Resistance's job)

On the Resistance's board (F4) at once when the city falls to the swarm, and for as long as the city is the Resistance's after it and any thumper is stopped. For each stopped thumper, nearest first: get to it (its button, marked), mend its wiring (the wiring game), start it with its own button. When every thumper runs, the job pays (40 plus 20 a thumper). Nothing is stood through: antlions may come while you mend, as they do. The robot players do it (`res_thumpers`). When the Combine take the city back, they see to their own thumpers (nothing stays broken).

## Settings

| Setting | Default | What it does |
|---|---|---|
| `lc_swarm` | 1 | 0: no harvest, no ritual, no fall to the swarm by itself; the guardians and the map's wiring still run, and staff's lines still work. |

The numbers (5 seconds, 15 to 20, 4, 10 minutes, 15 seconds, 6 and 10, 20, 2500, 16, the ritual's five) are constants in `sv_livingcity_swarm.lua`, first guesses except the ritual's, which the owner chose.

## What the map gives it (found by name)

- **The nest** (the forest cave): `lc_nest_door` (the shutter), `lc_nest_opened` (the relay the gamemode hears), `lc_nest_count` (the two buttons' counter: who pressed), `lc_nest_rally` (the holdout's side of the door), `lc_nest_extract` (the essence), the grubs (`npc_antlion_grub`) near it; the mine's `lc_hq_setup_cave`.
- **The thumpers** (the canal ring's four): every copy of the thumper module, `lc_thumper_<part>` for the first and `lc_thumper<N>_<part>` for the others (`^lc_thumper(%d*)_(%w+)$`), each copy's head, button, start relay and burrow kept together by its number (`docs/dev/canal-modules.md`).

## Staff

**F4 > Factions > Admin: testing tools > The city** (superadmins), under the chapter's lines:

- **Swarm: give me the extract**: you carry it (the essence leaves the nest).
- **Swarm: the vortigaunts' ritual now (pheropods to the highest rank)**: at the freed vortigaunt nearest you (straight to the pheropods with none), whatever the conditions.
- **Swarm: the city falls to the swarm now**: the burst and the fall, whatever the lock or the cooldown (not when the city is the Resistance's already).
- **Swarm: end it (pheropods back, antlions away)**: everything back: the pheropods taken, the antlions dig down, the extract in the nest, nothing broken.
- A line under them says how it stands (where the extract is, what the ritual still needs, the holder and the thumpers, the guardians, the mine's flag).

There is no console command.

## Saved

`data/livingcity/<map>_swarm.json` (through the safe file helpers): the mine's flag clock only, written every minute while it runs, when it starts again and at shutdown. Everything else starts afresh with the map (a restart brings the extract back to the nest; the map's thumpers run again).

## For other code

- `LC.Swarm.S` (the state: `stage` is "nest", "carried", "dropped", "held", "ritual", "pheropods" or "gone"), `LC.Swarm.Status()`, `.Missing()`, `.PickHolder(prefer)`, `.Fall(by, staff)`, `.End()`, `.UseVort(ply, vort)`, `.Broken(thumper)`.
- The chapter's hooks carry why `"swarm"`: `LivingCityChapterBegan("swarm", holder)`.
- `LC.Antlions.Parse(name)`, `.Heads()`, `.PartOf(ent, part)`: every thumper copy.
- The client knows through `lc_swarm_glow` (the essence), `lc_swarm_carry`, `lc_swarm_chant`, `lc_swarm_holder`, the globals `lc_swarm_essence` and `lc_swarm_inhand`, and the net message `lc_swarm_fall`.

## Tests

`python3 _dev/run_section.py --unit Nov27_SwarmTests` (134 checks): the thumper copies by pattern, two trickles at once, each in its own stretch, and the swarm's hold on them; the door's guardian (where, the charge, never two, ten minutes); the harvest (lc_swarm, the Combine, looking, letting go, the glow, the guardian); the hunt and its end; dropping, picking up, pockets, searches, cuffs, damage by whom, Combine NPCs going for it, ten minutes; the keeper and Valve's sequences; each of the ritual's conditions and its line; the mine's clock; the ritual, its chant and who gets the pheropods; death, leaving, ties; the swarm's sides; throwing and squeezing; thumpers stopped and started; the fall and the chapter's why; destroyed, wild, broken; the job end to end; staff. `python3 _dev/client_smoke.py` draws the glows and the fall. `python3 _dev/robots.py --only res_thumpers`.

## Guessed, or not seen in the real game

Nothing here has run in Garry's Mod: it is tested in the offline stub only. To check in the game:

- **The guardians:** that `cavernbreed` alone gives the glowing cavern look, that one with `incavern` 0 charges when told (`SetChargeTarget "!activator !activator"`, and a chase), and that it fits out through the shutter as the numbers say. Whether the chamber's one digs up (`startburrowed`, `Unburrow`) and finds room near the harvester.
- **The essence:** that E on it (a look within 300 units) feels right with the honeycomb round it; the rising sound is the vortigaunt's charge (`npc/vort/health_charge.wav`) at rising pitches; the grubs' squeal is a guess by name (`NPC_Antlion_Grub.Alert`).
- **Antlions digging up:** Valve's own `startburrowed` and `Unburrow`, as the thumper module uses; the spots are found by traces near whoever has the essence.
- **The dropped extract:** Episode Two's essence three times its size in a box that shots and E find; whether a kick or a baton swing reaches such a box (a unit walking onto it bursts it anyway); the wet burst (`BloodImpact` in the antlion's colour, `physics/flesh/flesh_squishy_impact_hard`).
- **Combine NPCs going for it:** that an `npc_bullseye` that is not solid and takes no damage draws their fire into the extract (Valve's card: "an NPC attacking the bullseye will do so with perfect accuracy").
- **The keeper's animations:** the sequence names come from Valve's ep2_outland_02 and ep2_outland_04 (`nectar_recieve`, `idle_nectar`, `turn_blue`, `turn_blue_vort1` to `3`, `surgery_sustain_idle`, the `nectar` attachment); Garry's Mod's vortigaunt model may be Half-Life 2's, without them, and then the vortigaunt only stands (they are looked for, never assumed). The drip particle (`larval_extract_drip`) and Valve's sound `outland_04.vort_remove_extract_fx` are guesses by name; the glow in its hands is ours (a light).
- **`TurnBlue`:** the vortigaunt's Episode Two input for its blue-purple skin; whether Garry's Mod's vortigaunt has it.
- **The pheropods:** `weapon_bugbait` thrown makes `npc_grenade_bugbait`, which takes itself away where it lands (that is where the swarm comes); whether Half-Life 2's own response to it (antlions running to where it lands) also happens without `antlion_allied`. From memory of Valve's code, `antlion_allied` makes each antlion like every player online when it starts, which is why it is not used.
- **The fall:** the dust (`ThumperDust`) and the shake; the rumble is Half-Life 2's thunder.
- **The numbers** are first guesses for the owner to change (the ritual's five are the owner's).

## Left as they are

- **The rocket's way:** unchanged. Its wave, its rank check and `lc_chapter` are the rocket's alone.
- **The nest's own wiring:** the door, its buttons, the alarm and the map's antlion makers run as the map has them, whatever `lc_swarm` says.
- **The thumper module** without the swarm: each copy's trickle (one antlion every 15 seconds near someone in its stretch of the canal, two alive at most: `wildlife.md`), for everyone.
- **The vest charge:** E on a freed vortigaunt still charges a vest; only the carrier's E (handing the extract over) and a Resistance player's E on the keeper go to the swarm first.
- **The chapter's retake, lock and cooldown:** as they are; the swarm only asks them.
- **The guide** (F1) has one line.
