# Secret endings: notes for whoever works on the code

The main file is `modules/server/sv_livingcity_endings.lua`, with its client side in `modules/client/cl_livingcity_endings.lua`. The G-Man offers a vote; the endings are:

- harpies, bus, plane, standup, hard, base, marrow, bloom, water (the flood), shalom (the hora), fire (behinds on fire, then flying on them)

Each ending has a song and its own `lc_ending_<name>_*` cvars, all documented in `docs/features/endings.md`.

Things worth knowing:

- **Archived server cvars keep their old values,** so changing a default doesn't reach existing servers. `LC.EndingRetune()` and its `RETUNED` table move exact old defaults to new ones. Add to that table whenever a default changes.
- **Song timing comes from a clock started when the song began playing** (`songAt` / SongClock on the client), because a BASS VBR mp3's GetTime drifts.
- **Things that fly are kept under the sky** with `LC.EndingCeilingAt` / `LC.EndingSky` (the bus, the plane, and Base's fleet). On the ground, the bus may drive through buildings; the owner likes that.
- **Placement uses `Ground()` and `RingSpot`,** which fall back to `LC.NavNodesNear`, because the map's landing zone is up on a roof.
- **Spectators (the dead):** `EndKey` and `LC.EndingPollKeys()` poll keys, because KeyPress doesn't always fire for spectators. Jump toggles free flight (OBS_MODE_ROAM).
- **ClientsideModels don't animate by themselves** (the G-Man), so their cycle is driven by hand.
- **Dances are bone manipulation on ValveBiped:** see "Bone poses" in `CORE.md`, section "How the code must be written" (roll on the head is a twist, not a nod).
- **An ending in progress:** `LC.EndingSession()` returns its state (nil when none). It now gates:
  - the city events
  - the announcer and voice clips
  - the ambient music
  - the breencast
  - Civil Protection inspections (underground stops)
  - `LC.ReportCrime`
  - negative `LC.AddStanding`
- **Dreams** (`sv_livingcity_dreams.lua`): with a dream point placed, an ending runs as a dream: `E.dream` is set, and then only the dreamers are in it. In ending code, never use `player.GetAll()` or `LC.NPCs` directly: use `LC.EndingPlayers()` and `LC.EndingNPCs()` (the dreamers and the dream's own NPCs in a dream), and put anything city-wide (`LC.TimeStopped`, `ai_disabled`, lights, weather, doors, Global2 vars awake players see, spots out in the city) behind `not E.dream`. Spots must pass `LC.DreamHolds(E.dream, pos)`. `LC.EndingSession()` is nil to the rest of the city during a dream; `LC.EndingAny()` is the ending either way. The admin's `lc_ending` stays the whole city's (`LC.EndingClassic`).

**Ideas for the future endings setup** (the owner, 7 November; not built, kept here so the next endings work starts from them). The G-Man, the sealed directives, his sleep visits and his talks with the Administrator are set aside (`lc_directives` 0) for that setup. When it comes: if the Administrator refuses a sealed directive, the G-Man could punish the city through its dreams: (1) **dreams that keep**: people wake with the weapons and stats they had in the dream, instead of everything being put back; (2) **dreams that leak into reality**: when everyone's dreams end, the dream spills over once, for example a swarm of the Harpies' mingebags pours through the city and attacks Civil Protection. Either could be an apocalyptic event of its own. The dream code already keeps every dreamer's snapshot and knows when a dream ends (`sv_livingcity_dreams.lua`, `LivingCityDreamStarted` and the wake-up), so both would hook in there.
