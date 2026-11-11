# Building a map with the editor

While an admin holds the editor tool, hunger and thirst don't go down, and Civil Protection leaves them alone: no stops, no frisks, no "move along", no crimes booked.

Left click places or tags, right click removes, R cycles modes, Z undoes. With "Show the editor's markers" unticked, holding the editor still shows the markers of the tool in hand (that kind of zone or point, or the path nodes) and nothing else. The list of things to place can be arranged **by type** (points, fixtures, zones, doors) or **by what it's for** (citizens' daily life, each Union job with its workplace and what goes with it, Civil Protection, the prison, the Resistance and rebel bases, infestation, exercise, dreams (the dream point and zone, added 11 November), power and the street, paths and doors): building a rebel base, its zone, lab, bunks, lookouts and the rest are in one folder. "Show the editor's markers" (untick to hide them all) and "See markers through walls" (untick: only what's in sight) keep a busy map readable. A ration line's front is the end nearest its dispenser, whichever end was placed first. Holding the tool shows the points, paths, zones and doors near you. Text labels appear only for what's close, a zone's name only while you're standing in it, and an NPC's state and destination only for the one you're looking at (tick "Show every nearby NPC" in the panel for the old everything-at-once view).

- **Zones** are shaded on the ground in their color. The zone you're aiming at fills in strongly with a bold edge, and the others dim. Its name and radius show under your crosshair. Aim at a zone's center marker to pick it out from overlapping zones; that's also the one a right click removes. While you're placing a zone, its size is shaded where it will go. Points and path nodes you're aiming at are highlighted the same way. Untick **Shade zones on the ground** in the panel to only shade the one you're aiming at.

### Saving

Every change saves straight away to `garrysmod/data/livingcity/<map>.json`, **settings included**: every slider and checkbox in the editor panel (population, territory, events, all of it), and any `lc_` setting changed from the console or rcon, is kept with that map's layout and put back when the map loads, so a server restart doesn't reset them (a dedicated server doesn't keep them by itself). There's no save button to forget, and the layout loads whenever that map loads, whichever gamemode you're in. Before each save, the previous version is backed up to `garrysmod/data/livingcity/backups/<map>/` (at most every 5 minutes, newest 30 kept). Backups can also be made by hand.

| Command | Does |
|---|---|
| `lc_backup` | Back up the layout now |
| `lc_backups` | List the backups, newest first |
| `lc_restore <number>` | Bring one back (what's there now is backed up first) |

If the layout file is ever damaged, it's copied aside as `<map>_unreadable_<time>.txt` before anything can overwrite it.

**Moving to a server:** install it on the server, and copy `garrysmod/data/livingcity/<map>.json` into the server's `garrysmod/data/livingcity/` folder.

**Dreams: test one** (the owner, 8 November): at the bottom of the panel, pick any dream and press *Test it now (just me)* to play it yourself, awake and alone, at the dream point; *Stop the test (wake up)* ends it. Nothing in a test counts and nobody asleep is pulled in (`docs/features/endings.md`, "Testing a dream from the editor").
