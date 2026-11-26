# What three NPC addons do, and what is worth recreating (25 November)

The owner asked for these to be read for ideas. Ideas only: VJ Base's code is all rights reserved, Background NPCs is Apache 2.0, the Jeff bot has no licence. Nothing of theirs is in the repo.

## Built from them

- **One noise rule** (`sv_livingcity_noise.lua`, `docs/features/contraband.md`): range from the engine's loudness (Jeff, VJ), the heard spot up to 60 units off (Jeff), go and look then give up (Jeff), a unit who can see the source does not walk to it (VJ), sneaking is silent (all three).

## Worth recreating, best first (not built: ask the owner before each, they change how people behave)

1. **Heavy work staggered** (VJ, Background NPCs): each NPC's costly pass once a second at its own random offset, and a shared few-milliseconds budget for all background loops, so nothing spikes.
2. **Losing someone, as a ladder** (VJ): unseen 15 s (7.5 s when far) -> take a nearby ally's target -> walk to where they were last seen -> stay alert 14 to 16 s -> back to rounds.
3. **Danger only interrupts calm** (Background NPCs): states in groups (calm, danger, guarded); a fright cannot interrupt a fight or an arrest. Stops people flapping between reactions.
4. **Crowd dampers** (Background NPCs): at most 2 bystanders join a fight, 2 call it in per area, a 60 s cooldown per area, fear is not passed on. No chain panic.
5. **After an incident** (Background NPCs): up to 4 calm citizens gather in a ring 150 to 280 units off for 12 to 25 s; a unit within 2000 comes to inspect the body.
6. **Talk paced by the line's length** (VJ): both speakers' idle talk and wandering wait for the line plus half a second, and the answer starts 0.3 s after it ends. No talking over each other.
7. **"Am I covered?" in one trace** (VJ): body to the enemy's eyes, world hit within 200 units; covered -> crouch and reload, not covered -> run to cover first.
8. **Help with a cap** (VJ): hurt with no target calls up to 4 allies within 800, every 9 to 12 s; they come to the caller, 50 units off, not onto the same spot.
9. **Unseen means three traces** (Background NPCs): at 10, 40 and 64 units up the body, all blocked, before someone is spawned or moved out of a player's sight.

## Not to copy

- Jeff: timers 50 times a second per bot; the player's own game telling the server what was heard (a cheat could steer it).
- Background NPCs: switching the engine's thinking off on a sleeping NPC (one killed asleep never finishes dying); a "field of view" test that is really the whole front half; scans of every entity each second.
- VJ: only the newest sound is kept per source, so a quiet one hides a loud one; "alerted by a noise" never times out.
- The talking heard in the owner's game (25 November) is Background NPCs: recorded lines made offline, a 15 in 100 chance every 10 s per person. No speech service is called while playing.
