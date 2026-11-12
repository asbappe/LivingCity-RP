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

The owner: "resistance interrogations force people into a chair entity and the resistance members use their fists to beat them", "please spawn a harsh bright spotlight above the chair that shines down onto the chair to borderline blind the person or NPC being interrogated", and on the risk: "the resistance can then also be morally gray and push good people towards CP and loyalism". **This first part is a Resistance Fighter or above (the owner: "Resistance fighters and above") questioning a citizen** (`sv_livingcity_chair.lua`, entity `lc_interrochair`; setting `lc_chair`, 1).

- **The chair** (editor: "Fixture: Resistance interrogation chair"): a wooden chair with a lamp hung 112 units over it, pointing straight down. Dark while empty. When someone is sat in it the lamp comes on: a visible beam, a tight and very bright cone of light on the chair, and the bulb's glare.
- **Taking someone to it.** With a free chair within 1200 units of a citizen, the talk window of a Resistance Fighter or above (E on the citizen) has **"Take them to interrogation chair"**. The citizen thinks less of you for it, walks to the chair (90 seconds at most, or they slip away), is pushed down into it and held there. People within 600 units see a line of the scene.
- **Asking** (E on the chair): **Ask what they've done**, **Ask what they've seen**, **Hit them**, **Let them go**. Nobody talks at first. Each blow is with the fists: 6 health, never under 10 health, six blows at most. Each wears down their resolve, 1 to 5 blows' worth, from who they are (the brave, the proud and the tough hold out longest).
- **What comes out is from the chronicle:** something they really did, secrets included (this is how an informer is found), or something they really saw or had done to them. Nothing is told twice.
- **The risk.** Beat someone twice or more who has nothing to tell and has told nothing, and ask what they've done: it was for nothing. They and their friends turn on you (the grudge is the kind the minds inform over), a sympathizer stops being one, and "beat NAME in the chair for nothing" goes in the chronicle for the street to tell.
- Every beating in the chair is in the chronicle. If the one asking stays more than 320 units away for 20 seconds, or after four minutes, they get up and go.
- **Players in the chair:** the game of anyone sat in it (once that exists) is all but whited out by the lamp; the screen effect is in already (`cl_livingcity_chair.lua`).
- **Not checked in the game:** how the lamp, beam and light look, and how the citizen sits on this chair model.

## The Resistance's holding cage (12 November)

The owner: "They should have a holding cell that is a cage (the chain link fences in a tight square) and with the chain link door/gate that is on the side closest/facing the admin that places the entity, and it functions as a door that can opened/closed by the resistance but is permanently locked to anyone in custody. it should more or less mirror the CP prison/jail system but using an entity with the spawned props." (`sv_livingcity_rebelhold.lua`, entity `lc_rebelcage`; settings `lc_rebel_cage` 1, `lc_rebel_hold` 300, `lc_rebel_cage_room` 8, `lc_rebel_auto` 1, `lc_rebel_visitor` 1.)

- **The cage** (editor: "Fixture: Resistance holding cage"): four chain link panels in a tight square, one a side, made by the entity and removed with it. **The gate is the side facing whoever placed it.** It swings out on its left-hand corner.
- **Who may use it:** a Resistance **Fighter or above** (the same for the chair). E on any side of the cage opens its window: **Open/Shut the gate**, and for each of those held, **To the interrogation chair** and **Let them go**. Anyone else pressing E is told it's locked; so is anyone held in it.
- **Taking a prisoner.** With a cage with room within 1500 units of a citizen, the talk window has **"Take them prisoner (to the holding cage)"**. Any citizen: a sympathizer, a loyalist, an informant. They think less of you, walk to the cage (two minutes at most) and are locked in. **Eight to a cage** (`lc_rebel_cage_room`, 4 to 8; the owner: "let's try 8 as a max for now"); past six they stand in each other a little, and **whenever one leaves the cage, for the chair or for good, everyone still held is stood in their own place again**, so nobody stays stuck in anybody.
- **Not kept.** The owner: the rebels "wouldn't have any interest in keeping prisoners". After `lc_rebel_hold` seconds (**300: five minutes**) a prisoner is let out. One the cell hasn't questioned yet is kept up to twice that, so everyone gets their turn.
- **The cell questions everyone by itself** (`lc_rebel_auto`, 1; the owner: "script an interrogation for anyone in the prison"). With a free chair within 1200 units of the cage, those held are taken to it one at a time (not before 15 seconds in the cage, never twice). About forty seconds under the lamp: a voice from behind it asks, blows until their resolve is gone (four at most, never under 10 health), then what comes out, and back to the cage. People within 600 units see it as lines of the scene.
  - Someone who breaks gives up what the chronicle says they did. **It goes on the Resistance notice board at once** ("NAME admitted it in the chair: ..."): this is how the cell, and its players, learn who informs.
  - Someone the four blows don't break says nothing they can use.
  - Someone broken who has nothing to tell was beaten for nothing: a sympathizer stops being one, and it is in the chronicle for the street to tell.
  - A Fighter or above who presses E on the chair takes the questioning over.
- **Someone at the cage** (`lc_rebel_visitor`, 1). While anyone is held, someone comes and talks at them, **one line every 30 to 60 seconds** (heard within 600 units):
  - **Father Grigori**, if he is alive and nobody is talking to him elsewhere: he is simply there, preaching, in his own voice, and stays until the cage is empty
  - else **a settled vortigaunt** within 4000 units walks over and speaks to them
  - else **one of the Resistance's own** within 3000 units walks over and taunts them
- **To the chair and back, by hand.** From the cage's window one of those held is sent to the nearest free interrogation chair within 1200 units of the cage. The chair's window then also has **"Back to the cage with them"**; a prisoner left alone in the chair is marched back to the cage rather than walking free. The time held carries on from when they were first locked up.
- **It is known.** "locked NAME in the Resistance's cage" goes in the chronicle (once), the prisoner thinks of it as an arrest and holds it against whoever took them, and their friends know who took them.
- **Civil Protection needs no cage** (the owner): their interrogation pulls from whoever is already in the cells.
- **Not checked in the game:** the fence model and its size (so how tight the square is, and whether eight fit), how the gate swings, where those held stand, and whether the vortigaunt and the rebel walk over as told.

## The plan this belongs to

1. **The chronicle** (done): what happens is kept with what led to it.
2. **Show it to players, in the world** (done: citizens' rumours, the two boards). Next: **radio news** (the owner: "if others want to hear it, they can tune into a radio"): the Union band reads the Combine's version between its lines, Freq 7 the Resistance's, at the stations' own slow pace; behind a setting, since it changes what the stations play.
3. **Interrogation that draws on the chronicle** (the owner said yes, 12 November):
   - **done:** the Resistance's chair with its lamp, and their holding cage, for a Fighter or above and citizen prisoners (above)
   - **next:** Civil Protection units and players as the Resistance's prisoners (a way to cuff and escort them), and players in the chair
   - **next:** the Resistance's own people taking suspects by themselves: whoever was publicly accused of informing, or was seen going to a unit, most suspected first; one at a time to the chair, the others watching
   - **next, replaces the existing interrogation** (the owner: "Please replace the existing interrogation with the new chair interrogation"): Civil Protection get a chair with a lamp in the prison; it pulls from whoever is already in the cells (no holding spot for them); the units beat the prisoner with the stun baton while they ask. **To settle with the owner first:** what becomes of a player prisoner's choices in today's interrogation (tell the truth, lie, say nothing, bargain).
4. **Revenge jobs**: a wrong in the chronicle plus a grudge in the minds makes a job (a friend beaten, an informer who named you, a unit attacked). Best after interrogation can reveal names.
5. **Events become consequences** (each behind a setting): a block raid hits the block an informant named, a sweep follows real sabotage, curfew follows unrest.
6. **A storyteller for pacing**: rules that decide which simmering thread boils over when the city is quiet, and hold back when it is busy.

Stays scripted: the endings, arrival and intake, the tutorial quests.
