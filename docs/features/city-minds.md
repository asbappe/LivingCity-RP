# The city's minds

Asked for by the owner, 10 November: "is it possible to add an extremely low-overhead, optimized, low-impact (to performance) but high impact to gameplay: dwarf fortress style behavioural system?", then "save it under _dev and wire in phase 1", and "would it be possible to add it as a parallel system (at least temporarily) like a module or add-on, that can run on the server and can collect logs I can bring back to you for analysis? ... I can just sit idle and let it run in the server".

**What it is.** Every named person in the roster (the 30 citizens and 10 units of `data/livingcity/<map>_people.json`) has a mind (`sv_livingcity_psyche.lua`, `LC.Psy`):
- eleven traits from -1 to 1, worked out from their id, so nothing new is saved in the roster and they never change; each is independent of the others (the first version's dice made them move together: fixed 10 November); units are always loyal, sympathizers never are:
  - **brave** (or timid), **temper** (hot-headed or even-tempered), **loyal** (to the Combine, or quietly not), **social** (or a loner), **hope** (or despairing)
  - added 10 November, asked for by the owner ("yes please add those traits and new reactions, and add weakness for drinks and smokes as well"): **greed** (or generous), **compassion** (kind-hearted or cold), **suspicion** (or trusting), **resilience** (tough or fragile), **pride** (or humble), **vice** (fond of a drink and a smoke, or sober)
- needs from 0 to 1: food, rest, company, and for anyone with vice above 0 a **craving** that builds and weighs on their mood until they have a drink or a smoke
- at most 8 timed thoughts ("was beaten (Unit 30)", "had a meal"); the same thought from the same person refreshes instead of stacking, and several of the same kind count less each time; traits make thoughts stronger or weaker (being searched stings the proud, a beating seen hurts the kind-hearted more, the Administrator on the PA lifts the loyal and sours the rest)
- mood (the thoughts plus the needs) and stress, which builds while mood is low (up to 40) and eases while it is good; the tough build it more slowly and lose it sooner
- at most 8 ties (-10 to 10) to people they feel something about, fading a point a city day without fresh cause; the suspicious warm to people slowly
- at most 4 pieces of news (who beat, killed, burned or named whom, who was called an informer), passed on when they talk, weaker each time and dropped after 3 tellings; the trusting believe anyone who isn't an enemy, the suspicious only a friend

Past 28 stress (at most once an hour) a person **breaks**, in a way that fits their traits:
- a citizen: a **tantrum** at a unit (temper), **despair** (no hope, fragile), **defiance** (brave, disloyal, proud, a grudge against a unit: a poster, a wall, the Resistance), **informing** on someone for a meal (timid, loyal, hungry, greedy), **looking for a friend** (social), **hoarding** food (greedy, hungry), **accusing** someone of being an informer (suspicious), **sabotaging** their Union work (proud and disloyal), or a **binge** on drink and smokes (a strong craving)
- a unit: **brutality** (temper, pride, cold), **drinking on duty** (vice) or quietly **leaking** to the Resistance (disloyal, hungry, kind-hearted)

Someone very content (the kind-hearted more often) is now and then **inspired**: **shares** their food with a hungry friend (kind, not greedy), would **shelter** a friend the Combine wants (kind, brave, disloyal), or **steadies** the frightened around them (tough, sociable).

Checked offline over 40 simulated weeks (`python3 _dev/psyche/analyze_traits.py`): every trait moves what people do the way it should (temper the tantrums, greed the hoarding and informing, hope against despair, loyalty against joining the Resistance, pride the sabotage, resilience against stress, sociability looking for friends, suspicion the accusations, vice the binges, compassion the sharing).

**The minds act** (`sv_livingcity_mindsact.lua`; the owner, 10 November: "Let's get the minds fully operational"). `lc_minds_act` (1) turns it on; 0 puts the minds back to watching only.

- **Ordinary choices bend** (asked by `ChooseCitizenTask`, for named citizens only): the hungry are 1.8 times as likely to join the ration line; the worn down (stress past 4, rising to the breaking point) sit more and work less; the timid among them sometimes go home and pick spots away from units; the lonely strike up a chat sooner.
- **A break happens in the street.** Players within 600 units see a line of the scene ("** Olga Volkov screams in Unit 30's face."). Someone at home, or busy with something else, does the quiet version. The log gets a `DID` line after the `WOULD` line.
  - **tantrum:** walks up to the nearest unit (within 1500) and screams at him; stopped for 30 seconds, and one time in four taken in.
  - **despair:** sits down (or goes home), and for 15 minutes won't work and hardly queues.
  - **defy:** becomes a Resistance sympathizer (never more than 40% of the roster's citizens), and paints over the nearest Combine poster within 1500.
  - **inform:** becomes an informant; with a grudge of -2 or worse against a player who is online, walks to a unit and names them: Civil Protection sees them outlined for 60 seconds ("A citizen names a troublemaker"). No crime is written on their record.
  - **seek:** walks to their closest friend who is out, and they talk.
  - **hoard:** goes back to the ration line though already served.
  - **accuse:** says out loud that the citizen they like least talks to Civil Protection; the accused hears it, the people near pass it on.
  - **sabotage:** breaks the nearest working streetlight or loudspeaker within 1500 (which the city's crews, or a player, then fix).
  - **binge:** drinks in the street for two and a half minutes.
  - **a unit, brutal:** beats the nearest citizen within 400 (12 damage at most, never to death); everyone near sees it and feels it.
  - **a unit, drink:** drinks on duty and stops nobody for five minutes.
  - **a unit, leak:** Freq 7 hears the name of a citizen informant who is out, or that the patrols are slack (no unit stops anyone for three minutes).
  - **share:** their hungriest friend is fed from their ration. **shelter:** becomes a sympathizer, and Freq 7 hears they can be trusted. **steady:** the citizens near them lose 3 stress.
- **Informants come from who people are.** A named citizen is an informant when they are among the most timid, loyal, greedy and cold of the roster: the same share as `lc_snitch_chance` (12%), and never a sympathizer. Unnamed citizens keep the old roll.
- **Unrest reaches sociostability.** From `lc_minds_unrest` (0.4; 0: never) the city goes yellow, "the mood of the city", and stays so until unrest has fallen 0.08 below the line. In the offline city unrest ran from 0.04 on a calm first day to about 0.44 after a hard week.
- A person the director moves (`director-and-free-talk.md`) goes through the same code.

**The watching** (`sv_livingcity_minds.lua`). The roster file is unchanged. A break is written down as what they **would** do (and, when the minds act, a `DID` line says what was done). What it is told comes from things the game already does: a named person hurt (by a unit, a player or anything else; named people within 700 units see it and learn who did it), killed (friends grieve, those near saw it), taken to the cells (friends feel it), served a ration, given something by a player from the talk window's Give menu (food, a drink or a smoke, which eases a craving, medicine, a gun, a Resistance leaflet), asleep in bed, stopped and searched by a unit, and the rest of what the log lists below.

**What it writes** (in `data/livingcity/minds/`):
- `<map>_<date>_<time>.txt`, one per map start: `HURT`, `KILLED`, `ARREST`, `KIND`, `RUMOUR` (a killing or an informer passed on), `WOULD` (a break, with their mood, stress, the thoughts behind it, who they are angriest at or closest to, and their strongest traits in words), and every 10 minutes a `SNAP`: the city's unrest (0 to 1), the average needs and stress, how many are on the streets, the counts so far, and the cost (`avg_us`, `max_us` per step). Written every minute; at most 3 MB each; the newest 40 are kept.
- `<map>_state.json`: the minds, saved every 5 minutes and when the map ends, put back on the next start.

To read them: copy the `minds` folder off the server (the host panel's file manager, or zip it) and give it back; `python3 _dev/psyche/analyze.py FOLDER_OR_ZIP` sums it up.

**For staff:** the debug report has a section "The city's minds" (the snapshot and the six most strained people) while it is on.

**Settings** (editor panel, NPC budget section): `lc_minds` (1: on; 0: off, nothing at all), `lc_minds_act` (1: the minds act; 0: watched and written down only), `lc_minds_unrest` (0.4: unrest from which sociostability goes yellow; 0: never), `lc_npc_vices` (1, above), `lc_minds_show` (0; 1: the talk window adds a line under how they feel about you, "They seem on edge: was beaten, saw a friend beaten.").

**Offline:** `python3 _dev/psyche/run.py [seed] [days]` runs the same minds in a pretend city for a week (`BRUT=2.5 KIND=0` for harsher units and no kind players); it prints every break, the totals, the unrest by day and the cost.

**Drinks and smokes in the street** (`sv_livingcity_npcvices.lua`; the owner, 10 November: "NPCs should smoke and drink too"). A named citizen with vice above 0 now and then lights a cigarette (a puff of smoke from them every 5 to 8 seconds, the same smoke a player's cigarette makes, for 30 to 50 seconds) or takes out a bottle (a bottle in the right hand and a swig every 8 to 12 seconds, for 25 to 40 seconds), while standing about, queueing, sitting or keeping watch, without stopping; it ends as soon as they go somewhere. Only within 2500 units of a player, at most 6 at once; the stronger the vice, the more often (about every 4 minutes at the strongest), and sooner with a craving. Never a unit (the mask). With the minds on, it eases the craving. `lc_npc_vices` (1), editor panel, NPC budget section. This is the one thing on this page players see.

**Not yet:** public punishments and executions fed in (once they exist: `TODO.md`); a citizen who shelters actually hiding a wanted player.
