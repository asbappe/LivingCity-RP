# The chronicle: what happened, and what led to it

Asked for by the owner, 12 November: "how do we move to leave our scripted events, at least most of them, but start building an emergent narrative engine/system". This is step one of four (the plan is at the end): **nothing that already happens in the city changes.** The chronicle only watches, as the minds' log does, but it keeps each thing with what led to it, and tells players.

**What it keeps** (`sv_livingcity_chronicle.lua`, `LC.ChronicleAdd`). One entry for each thing that happens to a named person or a player:
- a beating or an attack, a killing, a named person's death
- someone taken to the cells
- a pickpocket caught, an informer beaten by the Resistance, a player painting over a poster
- every break of a mind (`city-minds.md`): the scream at a unit, the poster, the accusation, the sabotage, a unit's brutality, despair, drinking, sharing food
- kept, but never told to players: who informs, who leaks to the Resistance, who shelters, and whatever was done quietly at home

Each entry has who did it, what, to whom, and which named people were within sight (700 units, the same as the minds). The same thing again within two minutes is one entry (a fight is many blows). The newest 400 are kept.

**What led to it.** When something is written down, the chronicle looks back three hours for the latest thing of weight that happened to, was done by, or was seen by the one who acted, and links the two. So a story is a chain, three links at most, told from its start:

> Unit 30 beat Pavel Orlov. Olga Volkov saw it, and later went to paint over a poster. Then, Olga Volkov was taken to the cells by Unit 30.

It says "later" and "then", never "because": the link is the likeliest cause, not a proven one.

**How players meet it:**
- **Chat with a citizen** (E on a citizen, then Chat). Once the city's older rumours have run out, the citizen passes on a story from the last six hours: "They say ...", or "I saw it myself. ..." from one who was there. Each story once to each player. Nobody tells a story they are in, and nobody tells you a story you are in.
- **On joining: "While you were away".** About 25 seconds after you join, a card with up to three stories (400 characters at most) from since you left, three days back at most. Not on a first visit, and not after less than ten minutes away.
- **F1 > What now? > What's been happening** (or `!news`): the last day's stories, the newest first.

**For the owner and staff:**
- `data/livingcity/chronicle/<map>_stories.txt`: the last week's stories in plain words, the weightiest first, **secrets included**. Rewritten at every save (every five minutes when something has happened, and when the map ends). This is the file to read, or bring back, to see whether good stories are happening.
- `data/livingcity/chronicle/<map>.json`: the entries themselves and when each player was last here; read back when the map starts.
- The debug report has a section "The chronicle": how many entries, how many of the day's stories have a cause, and the top three.

**Setting:** `lc_chronicle` (1: on; 0: nothing is written or told).

**One thing to know:** a sympathizer who likes you used to give the safe-house hint whenever the city had no rumour to tell; now they tell a chronicle story first if there is one you haven't heard, and the hint after.

## The plan this belongs to (the owner said yes to step 1 and a first piece of step 2)

1. **The chronicle** (done): what happens is kept with what led to it.
2. **Show it to players** (started: rumours, the joining card, the F1 list). Still to do: a dossier for Civil Protection, a daily bulletin.
3. **Events become consequences** (not started; each behind a setting, since it changes how existing events behave): a block raid hits the block an informant named, a sweep follows real sabotage, curfew follows unrest, F4 jobs come from what is truly happening.
4. **A storyteller for pacing** (not started): rules that decide which simmering thread boils over when the city is quiet, and hold back when it is busy.

Stays scripted: the endings, arrival and intake, the tutorial quests.
