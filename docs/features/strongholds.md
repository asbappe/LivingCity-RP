# Combine strongholds: tripwires and turrets (`sv_livingcity_strongholds.lua`)

The owner, 21 November, approving Valve's d3_c17_10b recipe (lesson `valve-tripwire-turrets`): red laser tripwires in Combine strongholds (Combine pass through) wake turrets that rise from the floor and re-arm when clear; shutting the control rooms ends the defences.

- **The map side** is the map modules' (`_dev/tools/map_security.py`): the wires, the floor lifts with their turrets, the counters that re-arm a room when every turret has sunk and turn it off for good when every turret is dead. Each room gives the gamemode two `logic_relay`s: `lc_<room>_alarm` (a wire broken) and `lc_<room>_off` (the room's defences shut for good). On a map without them nothing here happens (the live map has none yet).
- **A wire broken:** every Civil Protection and Overwatch player hears it on the CP net, with where. Whoever broke it, if a player who isn't Combine, is wanted for trespass (2 minutes) and the units near turn on them.
- **Cut the defences** (Resistance, F4, while any room's defences are up): get to the room's control point (where its `_off` relay stands, marked), wire the turret circuit out (the wiring game), and the room's turrets sink for good. 45 XP; up to 4 together. Arrested on the way, the job fails.
- A room shut by the map itself (a stronghold's own switches) counts as shut too. A shut room raises no alarm.
- No new settings, items or commands. Tests `Nov21_StrongholdTests`.
