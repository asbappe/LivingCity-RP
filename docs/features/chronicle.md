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

## The Resistance's interrogation chair (12 November)

The owner: "resistance interrogations force people into a chair entity and the resistance members use their fists to beat them", "please spawn a harsh bright spotlight above the chair that shines down onto the chair to borderline blind the person or NPC being interrogated", and on the risk: "the resistance can then also be morally gray and push good people towards CP and loyalism". **This first part is a Resistance player questioning a citizen** (`sv_livingcity_chair.lua`, entity `lc_interrochair`; setting `lc_chair`, 1).

- **The chair** (editor: "Fixture: Resistance interrogation chair"): a wooden chair with a lamp hung 112 units over it, pointing straight down. Dark while empty. When someone is sat in it the lamp comes on: a visible beam, a tight and very bright cone of light on the chair, and the bulb's glare.
- **Taking someone to it.** With a free chair within 1200 units of a citizen, a Resistance player's talk window (E on the citizen) has **"Take them to the chair (interrogate)"**. The citizen thinks less of you for it, walks to the chair (90 seconds at most, or they slip away), is pushed down into it and held there. People within 600 units see a line of the scene.
- **Asking** (E on the chair): **Ask what they've done**, **Ask what they've seen**, **Hit them**, **Let them go**. Nobody talks at first. Each blow is with the fists: 6 health, never under 10 health, six blows at most. Each wears down their resolve, 1 to 5 blows' worth, from who they are (the brave, the proud and the tough hold out longest).
- **What comes out is from the chronicle:** something they really did, secrets included (this is how an informer is found), or something they really saw or had done to them. Nothing is told twice.
- **The risk.** Beat someone twice or more who has nothing to tell and has told nothing, and ask what they've done: it was for nothing. They and their friends turn on you (the grudge is the kind the minds inform over), a sympathizer stops being one, and "beat NAME in the chair for nothing" goes in the chronicle for the street to tell.
- Every beating in the chair is in the chronicle. If the one asking stays more than 320 units away for 20 seconds, or after four minutes, they get up and go.
- **Players in the chair:** the game of anyone sat in it (once that exists) is all but whited out by the lamp; the screen effect is in already (`cl_livingcity_chair.lua`).
- **Not checked in the game:** how the lamp, beam and light look, and how the citizen sits on this chair model.

## The plan this belongs to

1. **The chronicle** (done): what happens is kept with what led to it.
2. **Show it to players, in the world** (done: citizens' rumours, the two boards). Next: **radio news** (the owner: "if others want to hear it, they can tune into a radio"): the Union band reads the Combine's version between its lines, Freq 7 the Resistance's, at the stations' own slow pace; behind a setting, since it changes what the stations play.
3. **Interrogation that draws on the chronicle** (the owner said yes, 12 November):
   - **done:** the Resistance's chair, with its lamp, for a Resistance player questioning a citizen (above)
   - **next:** the Resistance's own people doing it by themselves to those they suspect; players in the chair, which needs a way for the Resistance to cuff someone and escort them back to rebel ground
   - **next, changes an existing feature (behind a setting):** Civil Protection's interrogation in the cells draws on the chronicle too, and the units are seen beating the prisoner with the stun baton while they ask
4. **Revenge jobs**: a wrong in the chronicle plus a grudge in the minds makes a job (a friend beaten, an informer who named you, a unit attacked). Best after interrogation can reveal names.
5. **Events become consequences** (each behind a setting): a block raid hits the block an informant named, a sweep follows real sabotage, curfew follows unrest.
6. **A storyteller for pacing**: rules that decide which simmering thread boils over when the city is quiet, and hold back when it is busy.

Stays scripted: the endings, arrival and intake, the tutorial quests.
