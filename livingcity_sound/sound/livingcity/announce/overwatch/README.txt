The Combine PA (Overwatch): always the same cold voice.

Put every recording straight in this folder. The file's name starts with its
trigger, then anything you like: curfew1.wav, curfew2.wav, ambient_3.wav.
(curfew_soon1.wav is curfew_soon, not curfew: the longest trigger that fits wins.)
.wav, .mp3 or .ogg. One is picked each time, never the same one twice running.
Optional subtitle: a .txt with the same name (curfew1.wav + curfew1.txt).
In game, lc_announce_clips lists what was found and any file that never plays.
Draft lines for every trigger: ANNOUNCEMENT_SCRIPTS.md, at the top of this addon.

TRIGGERS (what a file's name starts with) AND WHEN THEY PLAY:
(Only rations and curfew are warned ahead. Sweeps, raids and supply convoys
are surprises, and a lockdown only ever answers violence.)
  rations         Ration distribution begins at the queue lines.
  rations_soon    About two minutes before rations.
  sweep           An inspection sweep starts: units stop people and check papers.
  curfew          Curfew begins; everyone must reach their housing block.
  curfew_soon     About two minutes before curfew.
  lockdown        Full lockdown after violence: more units, strict curfew, perimeter held.
  raid            A housing block inspection (block raid) begins.
  supply          A Combine supply convoy or dropship arrives with stores.
  ended           A curfew or lockdown is over.
  socio_green     The city drops back to green (nominal).
  socio_yellow    The city moves to yellow (marginal): more stops.
  socio_red       The city moves to red (judgment waiver).
  dawn            Dawn: the light comes up.
  day             Full day begins.
  dusk            Dusk: evening falls.
  night           Night falls: dark streets, curfew likelier.
  outbreak        A parasite or infestation outbreak begins.
  blackout        Power fails across the city.
  power_restored  The power comes back on.
  skirmish_raid   Rebels raid a checkpoint or patrol.
  skirmish_sweep  Civil Protection sweeps into rebel territory.
  response        An Overwatch response squad is dispatched.
  breakout        A prisoner is broken out by the Resistance.
  overwatch_drop  An Overwatch dropship deploys soldiers.
  block_raided    A block raid finishes.
  territory_grew  The Resistance take more ground.
  train_arrival   A train brings new arrivals.
  welcome         A player joins (or starts a new character): only they hear it,
                  always. Right after the Administrator's welcome.
  ambient         Random city announcements, and what Dr. Breen's periodic addresses are made of.
