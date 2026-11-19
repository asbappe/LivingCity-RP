# Firing squads

Asked for by the owner, 10 November ("firing squads and public punishments and executions YES"). Settled 19 November: "The Administrator only"; a player shot is "real death please, but I also want it to automatically pop up as a job for ALL resistance members so there is an increased chance of a rescue". Built 19 November (`sv_livingcity_firingsquad.lua`, `cl_livingcity_firingsquad.lua`).

**The wall.** The editor's **"Point: execution wall"** (kind `execwall`): the condemned stands there, back to the wall, facing the way the point faces; the squad lines up 300 units in front. With none placed there are no firing squads.

**Who may be shot.** Someone in the Combine's cells who is of the Resistance, tried to kill the Administrator, or is in for murder; or one of the city's own held there for the Resistance. Never a citizen in for something petty.

**Who orders it.** Only the Administrator: a player from **F2 > City orders > Firing squad...** (a list of who may be shot, with what for), or the city's own as a reprisal for a killing by the Resistance (`docs/features/resistance-prisoners.md`). One at a time.

**What happens.**
- The PA (new trigger `execution`, recordable in her and Overwatch's folders like any other): "<name>, enemy of the city, will be executed at the wall in two minutes. Citizens, attend."
- **Every member of the Resistance online is given the job "Stop the execution"** (one urgent posting all of them can work on together, the usual "New job" line): get to the wall, then uncuff the condemned or bring the squad down.
- Four Overwatch soldiers come in out of sight and line up; up to six citizens nearby walk over to watch.
- Thirty seconds in, the condemned is taken from the cell to the wall (a fade for a player), cuffed and held still. It is not counted as an escape.

**A rescue.** The condemned uncuffed (F1 > Uncuff, as for anyone cuffed), the whole squad brought down, or (one of the city's own) a member of the Resistance pressing E on them, before the volley. The condemned is free: for a player, an escape from custody as any other (wanted for it). Everyone on the job is done.

**The volley.** At two minutes. A player's character is **dead for good** (as a proper execution by the Resistance is). One of the city's own is dead. The chronicle has it at its heaviest; authority +3, morale -4; a member of the Resistance shot is a martyr to the people (`docs/features/resistance-prisoners.md`).

Setting: `lc_firingsquad` (1). Tests: `Nov19_FiringSquadTests`.
