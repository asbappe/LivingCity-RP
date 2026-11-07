# Rebel activity audit (7 November)

The owner: "are NPC rebel raids, attacks, ops, etc even active? I see announcements for them and see sociostability changing and such, but I have never actually seen rebel NPCs doing anything."

Checked by running the code in the test harness on a city set up like theirs (`lc_npc_budget` 10, default population settings), not by reading alone. The probe's numbers: after 90 seconds the cap's 10 places were all citizens, **0 Civil Protection units on the street, 0 to 1 fighters at home in rebel territory** (lc_rebels 4 plus the Commissary's extras were wanted, none could come: rebels spawn last, after citizens and units).

## Headline findings (in plain words)

1. **Raids did have fighters** (they were spawned past the cap), but **nobody to fight**: with the cap full of citizens there were no units anywhere to answer them. The fighters walked to the checkpoint, stood there, and went home. The city still announced "Armed Resistance fighters are attacking..." and docked rations.
2. **Raids often never got there.** The raid's 150 seconds started when the fighters left home, and the target is picked at random from the three nearest checkpoints: in the harness one was 84,000 units away and the raid ended with the fighters still 77,000 units out. They also walked with the engine's pathfinding only (no city routes): behind a wall they stood still until the raid timed out.
3. **The ration dock "near a Resistance attack" came 20 seconds after the raid set out**, wherever the fighters were (77,000 units away in the probe). The PA line, the rumours ("Did you hear the shooting?") and the "rebel raid" tip also came at the start, before anything happened.
4. **Sociostability goes yellow ("fighting in the streets") for the whole of any raid or sweep**, including the walk.
5. **Everything happened somewhere you weren't**: fighters spawn only where no player can see, and nothing on screen said where the fight was (the Combine got a job, the Resistance a job; no live marker).
6. **The Commissary's extra fighters never showed up on this setup**: they add to rebel territory's target, but the cap was already full, so the restrictions changed nothing you could see.
7. **NPC operations are rare by design** (`lc_rebel_ops_minutes` 60, then a 6% or 4% chance a minute, and only if the map has data terminals or city screens; supply drops and Overwatch landings get a team half the time). When they happen they are real (fighters must stand at the target), but nobody opposed them either.

## Every happening, before

| Happening | What announces it | Embodied or abstract | On their setup (cap 10) | Why they never saw it |
|---|---|---|---|---|
| Rebel raid (skirmish) | Resistance radio, PA `skirmish_raid` + "Armed fighters attacking", CP job, tip, rumour | embodied: 4 fighters walk to a checkpoint | fighters yes (spawned past the cap); units to fight: none | no opponents; 150 s from leaving home, so long walks ran out; engine-only pathing; no marker; spawned out of sight |
| Planned raid | Resistance radio + notice 90 s ahead, "Back up the raid" job | embodied (becomes a raid) | as above | as above; if it couldn't start, nobody was told |
| Combine sweep | CP and Resistance radio, PA `skirmish_sweep`, jobs | embodied: 4 units spawned at a hidden staging spot (city routes) | yes, spawned past the cap | worked; but home had 0 to 1 fighters to fight back (topped up to 2) |
| Resistance op: heist, breakout, screen | Resistance radio, CP net "DATA BREACH" + marker | embodied (a raid with an objective) | fighters yes, opposition none | rare by design; needs terminals or screens on the map |
| Resistance op: supply drop, landing ambush | Resistance radio, CP net | embodied | yes, unopposed | half the time, once per drop |
| Ration dock "near a Resistance attack" | chat + PA | abstract: 20 s after a raid starts, around the target | yes | claimed a fight before (or without) one |
| Rumours of raids | citizens' gossip | abstract, at raid start | yes | before anything happened |
| Sociostability yellow "fighting in the streets" | Overwatch | abstract, tied to the skirmish being on | yes | yellow while the fighters were still walking |
| Territory spread | PA `territory_grew`, radio, "[City]" line | abstract by design (a timer grows a patch; more fighters are wanted there) | spread yes, fighters no (cap full) | being looked at by another worker (territory growth); not changed here |
| City state "civil unrest" | "[City]" line, HUD | abstract (who holds how much ground) | yes | by design |
| Commissary restrictions | the Administrator's market notes | embodied in theory (+1 fighter at home each) | no: the cap was full | the cap |
| Missing Unit retaliation, lookout posts, quartermaster, scavenging runs | various | embodied (spawned past the cap) | yes | not part of the complaint |
| Overwatch drop | PA, radio | embodied soldiers | yes | not a rebel event |

## What was done (sv_livingcity_rebelevents.lua)

- **The owner's way: move, don't add.** A raid or operation takes the idle fighters at home first, as many as it needs (never the quartermaster, a posted lookout, one out scavenging, or anyone a player is with) and walks them out. Still short: room left under the cap; then a spare NPC nobody can see (an idle fighter in another zone, then a citizen) is taken out and a fighter comes in at the raid's hidden spot. The Combine side the same: an idle unit within 6000 units is sent as he is; else one is swapped in out of sight near the fight. Sweep teams are swapped in the same way. Everyone a raid or sweep brought counts against `lc_npc_budget` until home or gone, so the cap holds. `lc_event_npc_allowance` (0) is a last resort above the cap when nothing can be swapped.
- **Getting there:** raiders follow the city's routes; one stuck gets past it out of sight; the raid's clock starts when they arrive; one not there in six minutes is called off ("Our fighters couldn't get through", no fight claimed). A planned raid that can't start tells the Resistance.
- **Someone to fight:** a raid that arrives with fewer than two units near gets two or three sent.
- **Findable:** the Resistance see "Our fighters" on screen, following them, from the moment they set out; the Combine see "10-20: ANTICITIZEN ATTACK" once the fight starts.
- **Honest:** the ration dock, the PA's `skirmish_raid` line, the rumours and the raid tip now wait for the fighters to reach the target.
- **Scale:** parties are 4, plus one from 3 restrictions, two from 5 and one more each past that (`lc_market_raid_max` 6), plus the restrictions' fighters the zones can't take in. Pacing unchanged: no new raids, `LC.MarketOpsMul` still shortens the operations' wait.

Not changed: how often raids, sweeps and operations come; territory growth (another worker); the Overwatch drop and `LC.ReinforceRebels` still spawn past the cap.
