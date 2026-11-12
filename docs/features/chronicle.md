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

**How players meet it: in the world only** (the owner, 12 November: "we don't need to add in psychic lore breaking roleplay breaking concepts", and on noise: "this game mode has a tendency to spit ALL the data ... at the player and we've worked hard to minimize useless noise").
- **Chat with a citizen** (E on a citizen, then Chat). Once the city's older rumours have run out, the citizen passes on a story from the last six hours: "They say ...", or "I saw it myself. ..." from one who was there. Each story once to each player. Nobody tells a story they are in, and nobody tells you a story you are in.
- **The Civil Protection incident feed** (editor: "Fixture: Civil Protection incident feed"; a Combine monitor, entity `lc_newsfeed`). **Only what was formally reported**, in Overwatch's words, from the last six hours, eight items at most, five on the glass at a time and rolling every six seconds:
  - `DETAINED: NAME.` (someone taken to the cells)
  - `REPORT RECEIVED. SUBJECT: NAME.` (an informant reported or named someone; the informant is never named)
  - `ASSAULT ON UNIT 30.` with `SUSPECT: NAME` under it, in red
  - `UNIT LOST: NAME.` with the suspect, in red
  - `AMPUTATED: NAME.` with `BY: UNIT` (a unit killed someone)
  - never on it: a unit's own beatings, posters, sabotage, anything nobody reported. Empty: "NO INCIDENTS LOGGED. SECTOR STABLE."
- **The Resistance notice board** (editor: "Fixture: Resistance notice board"; a corkboard, the same entity). "What we know", in the rebel hand: what the street could see (beatings, killings, arrests, an informer beaten, an accusation shouted, a tantrum, sabotage, a poster painted over) **that one of their own saw or was part of** (a sympathizer among the named citizens, or a Resistance player). Word takes five minutes to reach the board. It can be wrong: an accusation goes up as it was shouted. Empty: "Nothing new. Keep your eyes open."
- Both go dark with the district's power, and are read from within 900 units. The lists go to players' games every 20 seconds when they have changed.

**Staff only, for testing:**
- **F1 > What now? > The city's stories** (or `!news`): the last day's stories, secrets included. Anyone else is told the stories are for staff.
- **"While you were away"**: about 25 seconds after a staff member joins, a card with up to three stories from since they left (three days back at most; not after less than ten minutes away).

**For the owner and staff:**
- `data/livingcity/chronicle/<map>_stories.txt`: the last week's stories in plain words, the weightiest first, **secrets included**. Rewritten at every save (every five minutes when something has happened, and when the map ends). This is the file to read, or bring back, to see whether good stories are happening.
- `data/livingcity/chronicle/<map>.json`: the entries themselves and when each player was last here; read back when the map starts.
- The debug report has a section "The chronicle": how many entries, how many of the day's stories have a cause, and the top three.

**Not checked in the game:** the corkboard model's front. The board's words are drawn on both of its broad faces so one is always away from the wall; if they sit oddly on the model, say so.

**Setting:** `lc_chronicle` (1: on; 0: nothing is written or told).

**One thing to know:** a sympathizer who likes you used to give the safe-house hint whenever the city had no rumour to tell; now they tell a chronicle story first if there is one you haven't heard, and the hint after.

## The plan this belongs to

1. **The chronicle** (done): what happens is kept with what led to it.
2. **Show it to players, in the world** (done: citizens' rumours, the two boards). Next: **radio news** (the owner: "if others want to hear it, they can tune into a radio"): the Union band reads the Combine's version between its lines, Freq 7 the Resistance's, at the stations' own slow pace; behind a setting, since it changes what the stations play.
3. **Interrogation that draws on the chronicle** (the owner said yes, 12 November; changes an existing feature, so behind a setting):
   - a questioned person can give up what the chronicle says they did or saw; whether they talk depends on their traits
   - **Civil Protection's:** the units beat the prisoner with the stun baton while they ask
   - **the Resistance's:** the prisoner is put in a chair (an entity) and beaten with fists; it carries a risk: a wrongly accused citizen turns against the Resistance, towards Civil Protection and loyalism ("the resistance can then also be morally gray")
   - both run by NPCs on their own, and both playable: a player can interrogate and be interrogated
   - later: the Resistance can cuff someone and escort them back to rebel ground for it
4. **Revenge jobs**: a wrong in the chronicle plus a grudge in the minds makes a job (a friend beaten, an informer who named you, a unit attacked). Best after interrogation can reveal names.
5. **Events become consequences** (each behind a setting): a block raid hits the block an informant named, a sweep follows real sabotage, curfew follows unrest.
6. **A storyteller for pacing**: rules that decide which simmering thread boils over when the city is quiet, and hold back when it is busy.

Stays scripted: the endings, arrival and intake, the tutorial quests.
