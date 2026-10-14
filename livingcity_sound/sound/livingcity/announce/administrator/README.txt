The Administrator: a kindly parent with a dash of the cheerful host, who
turns domineering as things get worse.

Put every recording straight in this folder. The file's name starts with its
trigger; firm, stern or furious anywhere in the name is that tone, and no
tone word is her warm one:
  curfew1.wav, curfew2.wav     warm
  curfew_firm1.wav            firm (losing patience)
  curfew_stern1.wav           stern (displeased)
  curfew_furious1.wav         furious (domineering)
.wav, .mp3 or .ogg. Optional subtitle: a .txt with the same name.

HOW SHE PICKS HER TONE: each trigger has a usual tone (below). It goes up a
step while the city is on red sociostability, and up again after a run of
violence (three raids, skirmishes, breakouts, outbreaks or rebel gains in ten
minutes is a step, six is two; warm triggers only escalate on red). If the
tone she wants has no recordings she uses the nearest calmer one, then the
nearest angrier one, so one warm take covers a trigger on its own.
In game, lc_announce_clips lists what was found and any file that never plays.
Draft lines for every trigger and tone: ANNOUNCEMENT_SCRIPTS.md, at the top of this addon.

TRIGGERS, HER USUAL TONE, AND WHEN THEY PLAY:
(Only rations and curfew are warned ahead. Sweeps, raids and supply convoys
are surprises, and a lockdown only ever answers violence.)
  rations         warm     Ration distribution begins at the queue lines.
  rations_soon    warm     About two minutes before rations.
  sweep           firm     An inspection sweep starts: units stop people and check papers.
  curfew          firm     Curfew begins; everyone must reach their housing block.
  curfew_soon     firm     About two minutes before curfew.
  lockdown        stern    Full lockdown after violence: more units, strict curfew, perimeter held.
  raid            stern    A housing block inspection (block raid) begins.
  supply          warm     A Combine supply convoy or dropship arrives with stores.
  ended           warm     A curfew or lockdown is over.
  jog             warm     The morning jog begins (every second dawn, in turn).
  drill           warm     The morning drill begins.
  parade          warm     The morning parade begins.
  socio_green     warm     The city drops back to green (nominal).
  socio_yellow    firm     The city moves to yellow (marginal): more stops.
  socio_red       stern    The city moves to red (judgment waiver).
  dawn            warm     Dawn: the light comes up.
  day             warm     Full day begins.
  dusk            warm     Dusk: evening falls.
  night           warm     Night falls: dark streets, curfew likelier.
  outbreak        firm     A parasite or infestation outbreak begins.
  blackout        firm     Power fails across the city.
  power_restored  warm     The power comes back on.
  skirmish_raid   stern    Rebels raid a checkpoint or patrol.
  skirmish_sweep  stern    Civil Protection sweeps into rebel territory.
  response        stern    An Overwatch response squad is dispatched.
  breakout        furious  A prisoner is broken out by the Resistance.
  overwatch_drop  stern    An Overwatch dropship deploys soldiers.
  block_raided    firm     A block raid finishes.
  territory_grew  firm     The Resistance take more ground.
  train_arrival   warm     A train brings new arrivals.
  welcome         warm     Someone who still has to register at Civil Intake joins (or
                           starts a new character): only they hear it. Not for anyone
                           already registered. She speaks first, then Overwatch.
  ambient         warm     Random city announcements, and what Dr. Breen's periodic addresses are made of.
