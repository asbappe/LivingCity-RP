# The city's minds (watching only, for now)

Asked for by the owner, 10 November: "is it possible to add an extremely low-overhead, optimized, low-impact (to performance) but high impact to gameplay: dwarf fortress style behavioural system?", then "save it under _dev and wire in phase 1", and "would it be possible to add it as a parallel system (at least temporarily) like a module or add-on, that can run on the server and can collect logs I can bring back to you for analysis? ... I can just sit idle and let it run in the server".

**What it is.** Every named person in the roster (the 30 citizens and 10 units of `data/livingcity/<map>_people.json`) has a mind (`sv_livingcity_psyche.lua`, `LC.Psy`):
- five traits from -1 to 1 (brave, temper, loyal, social, hope), worked out from their id, so nothing new is saved in the roster and they never change; units are always loyal, sympathizers never are
- three needs from 0 to 1: food, rest, company
- at most 8 timed thoughts ("was beaten (Unit 30)", "had a meal"); the same thought from the same person refreshes instead of stacking, and several of the same kind count less each time
- mood (the thoughts plus the needs) and stress, which builds while mood is low (up to 40) and eases while it is good
- at most 8 ties (-10 to 10) to people they feel something about, fading a point a city day without fresh cause
- at most 4 pieces of news (who beat, killed or named whom), passed on when they talk, weaker each time and dropped after 3 tellings

Past 28 stress (at most once an hour) a person **breaks**, in a way that fits their traits: a tantrum at a unit, despair, defiance (a poster, the Resistance), informing on someone for a meal, or looking for a friend; a unit's break is brutality, drinking on duty or quietly leaking to the Resistance. Someone very content now and then is **inspired** (shares food with a hungry friend).

**For now it only watches** (`sv_livingcity_minds.lua`). No NPC behaves differently, nothing is sent to players (unless `lc_minds_show` is on), and the roster file is unchanged. A break is written down as what they **would** have done. What it is told comes from things the game already does: a named person hurt (by a unit, a player or anything else; named people within 700 units see it and learn who did it), killed (friends grieve, those near saw it), taken to the cells (friends feel it), served a ration, given food by a player, asleep in bed. Off the streets they are at home, getting by and sleeping at night. One mind is stepped every half second, round robin.

**What it writes** (in `data/livingcity/minds/`):
- `<map>_<date>_<time>.txt`, one per map start: `HURT`, `KILLED`, `ARREST`, `KIND`, `RUMOUR` (a killing or an informer passed on), `WOULD` (a break, with their mood, stress, the thoughts behind it and who they are angriest at or closest to), and every 10 minutes a `SNAP`: the city's unrest (0 to 1), the average needs and stress, how many are on the streets, the counts so far, and the cost (`avg_us`, `max_us` per step). Written every minute; at most 3 MB each; the newest 40 are kept.
- `<map>_state.json`: the minds, saved every 5 minutes and when the map ends, put back on the next start.

To read them: copy the `minds` folder off the server (the host panel's file manager, or zip it) and give it back; `python3 _dev/psyche/analyze.py FOLDER_OR_ZIP` sums it up.

**For staff:** the debug report has a section "The city's minds" (the snapshot and the six most strained people) while it is on.

**Settings** (editor panel, NPC budget section): `lc_minds` (1: watch and write down; 0: off, nothing at all), `lc_minds_show` (0; 1: the talk window adds a line under how they feel about you, "They seem on edge: was beaten, saw a friend beaten.").

**Offline:** `python3 _dev/psyche/run.py [seed] [days]` runs the same minds in a pretend city for a week (`BRUT=2.5 KIND=0` for harsher units and no kind players); it prints every break, the totals, the unrest by day and the cost.

**Not yet (each waits on the owner's OK, because it changes how the city behaves):** their choices bending (the hungry to the ration line, the worn down to benches, the timid home), breaks happening for real, informants and recruits coming from the minds instead of the fixed chances, unrest feeding sociostability. Propaganda on the screens is not fed in yet.
