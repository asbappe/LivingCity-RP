# Network audit (2026-11-07)

Why: the owner was once dropped into a reconnect loop with `SendData reliable data too big (744335)` with about 100 NPCs on the map. A player's game holds only about 256 KB of reliable data waiting to be read. Past that it is dropped. One net message also can't be over 64 KB (65,533 bytes). Anything that goes over either limit while a player is joining drops them again on every reconnect.

Nothing here changes what players see, a setting, a default or a command.

## What can grow (worst cases are estimates for a big, busy map)

| Message | Who gets it, and when | Worst case | Risk before |
|---|---|---|---|
| `lc_data` (the editor's whole layout: points, path nodes with links, zones with their grown ground, doors, props) | every superadmin, on **every** `LC.SaveData`: territory growing or shrinking, a path-map flush (every 4 s while mapping, and then **sent twice**), props, editor clicks, and on `lc_request` | 1,500 nodes + 800 points + 200 zones is about 250-300 KB of JSON (positions are full-precision floats), so 80-110 KB compressed | **High.** Over the 64 KB cap on a big map, and several in a row during a fight over territory pile up past 256 KB, including while the owner is loading in. The likeliest cause of the 744 KB. |
| `lc_public` (habitation blocks, rebel ground, infestation and Combine zones, each with its ground rectangles) | **every player**, on every `LC.SaveData` (same triggers as above) and 2 s after joining | 500 ground rectangles: about 20-40 KB JSON, 5-10 KB compressed | **High when frequent:** a burst of territory changes is one send per change, to everyone, loading players included. |
| `lc_staff` (tickets, players, 200 warnings, the last 1,500 staff log lines) | an admin opening the staff panel | 200-300 KB JSON, 40-80 KB compressed | Medium: can pass 64 KB, and then the panel never opens. |
| `lc_report` (the debug report text) | a superadmin copying the report | grows with NPCs and entities: 100-500 KB text, 20-100 KB compressed | Medium: same as above. |
| `lc_records`, `lc_admin_office`, `lcq_board`, `lc_slots`, `lcf_menu`, `lci_inv` and the other `LC.SendCompressed` panels | one player, when a panel opens | usually 1-20 KB compressed | Low. |
| `lc_tune_all` (the endings' tuned dances, `net.WriteTable`, uncompressed) | **everyone**, on every bone change in the Endings menu (a dragged slider sends many a second), and 5 s after joining | about 40 bytes per tuned bone: 1,000 tuned bones is about 40 KB | Medium: a fast stream of whole-table broadcasts. |
| `lc_tune_info` (the Endings menu: every ending's settings with their help, plus the tuning) | a superadmin opening the menu | about 25 KB + the tuning | Low (under 64 KB unless the tuning gets huge). |
| `lc_laws` (global string, the law boards) | everyone, through the engine | the 8 default laws are 508 characters of JSON; one more law passes the engine's **511-character** limit for a networked string | **Broken past one more law:** the board gets cut-off JSON and shows nothing. |
| `lc_broadcast` (global string, the city screens) | everyone | up to 600 characters (the broadcast limit) | Same 511 limit. |
| `lc_settings`, `lc_dream`, `lc_directives`, `lc_ending`, `lc_manpower`, the radio and job-game JSON strings, notices, waypoints | one player or a few | under a few KB (`lc_settings` caps at 200 names) | Low. |

Engine side (not changed, listed for the owner):

- **NPC networked variables.** NPCs used to carry their name, job and what they are doing as NW2 strings (`lc_pname`, `lc_pjob`, `lc_doing`) in every joining player's first full update. These three now come on demand instead (see "NPC name tags, on demand" below). What is left on NPCs is short: `lc_role` and `lc_state` (a word each), the rare `lc_injury` and `lc_jg_mark` in the job games, and NW2 bools and ints.
- **Entity count.** Every NPC, prop and city entity is in the joining player's full update. `lc_npc_budget` (default 60) is the owner's control for that.
- **String tables** sent on joining: precached models and sounds, and every `resource.AddFile` recording and song (the downloads list). These grow with the owner's sound folders, not with the code.
- No old-style `SetNW*` (NW1) or `SetGlobal*` (non-2) networking is used anywhere.

## What changed

1. **`sh_livingcity_net.lua` (new, shared).** Everything `LC.SendCompressed` sends now goes through `LC.Net`:
   - a send of 60 KB or less (compressed) that finds nothing waiting for that player goes **at once, as one message, in the same format as before** (length, then data). Nearly every send is this.
   - a bigger one goes as `lc_big` pieces of 30 KB. The player's game puts them back together and hands the whole to the message's own receiver, which reads it with `net.ReadUInt(32)` and `net.ReadData` as always. No receiver was changed.
   - each player is sent at most about 128 KB at once, then 64 KB a second; the rest waits its turn, in order.
   - while a player is loading in (their game reads nothing yet), sends of 16 KB and more, and anything past 64 KB in all, wait until their game says it is ready (`lc_net_ready`, sent from the client's `InitPostEntity`), or 90 seconds.
   - whole-state messages (`lc_data`, `lc_public`) go to each player at most once a second. A newer one replaces one still waiting, and the very same state they were just sent is not sent again. The path mapper's second `lc_data` per flush and a burst of territory changes collapse into one send.
   - `LC.SetGlobalLong` / `LC.GetGlobalLong`: a networked global string in parts of 500 characters (`key`, `key_2`, ..., with the count in `key_parts`). A short string is one part under its own name, exactly as before.
2. **`sv_livingcity_data.lua`:** `LC.SendCompressed` calls `LC.Net.SendCompressed` (same name, same arguments, every caller unchanged).
3. **`sv_livingcity_writing.lua` / `cl_livingcity_writing.lua`:** the law boards' `lc_laws` and the screens' `lc_broadcast` use the long global string, so more laws and a 600-character broadcast reach every board and screen whole.
4. **`sv_livingcity_endingtune.lua`:** `lc_tune_all` broadcasts after a change go at once, then at most every half second while a slider is dragged (the last one always goes, so everyone ends on the same tuning).

Tests: `NetSafetyTests` in `_dev/tests.lua` (pieces, pace, loading in, once a second, long globals, the laws, the tuning share). `_dev/tests.lua`'s prelude sets `LC.Net.READY_WAIT = 0` (the test's players have no game loading in); the unit turns it on for its own checks. The client smoke test puts a send in pieces back together through a receiver and reads a long global string.

## What's left

- `lc_tune_all`, `lc_tune_info`, `lc_dream`, `lc_directives`, `lc_settings`, `lc_ending` still use `net.WriteTable` (uncompressed, one message). All stay well under 64 KB in practice; moving them to `LC.SendCompressed` needs both sides and their tests changed together.
- `LC.SaveData` still writes the whole layout file on every territory change (disk work, not network: for the performance pass).
- The pacing uses a fixed 64 KB a second per player. A player whose `rate` is set lower than that is still protected by the 256 KB limit only through the queue; if it ever shows up, lower `LC.Net.RATE`.
- Direct `net.Start` messages (notices, waypoints, announcements) don't go through the queue. Each is small, so it would take thousands in one moment to matter.

## NPC name tags, on demand (2026-11-07, approved by the owner)

`sh_livingcity_npcstr.lua` (shared, new). The server keeps `lc_pname`, `lc_pjob` and `lc_doing` in a Lua table (`LC.NPCStrNet.vals`) instead of NW2 strings. Every writer calls `LC.SetNPCStr(ent, key, value)` and every reader, server or client, calls `LC.NPCStr(ent, key, default)`, which reads like `GetNW2String` did (the default only when never set, `""` stays `""`). Any other key passed to them goes to the engine's string as before.

- Each player's game asks (`lc_npcstr_ask`) about once a second, once it has loaded. The server answers (`lc_npcstr`) with the values of everyone within 1,500 units, nearest first, and only what changed since it last told that player (about 16 KB at most per answer, the rest next time). It also tells the game which entities were removed so a reused entity index never shows an old name.
- Far ones: when a label reads an NPC that is out of range or not answered yet (the look-at name tag on someone across the square, the Administrator on air on the city screens), the game puts its index in the next ask (asked within a quarter of a second for a new one) and keeps asking after it while it is being read.
- Readers covered: the look-at name tag, job and doing (`cl_livingcity_factions.lua`), the sympathizer check, the on-air name on the city screens (`cl_livingcity_resistance.lua`), the editor's NPC labels (`cl_livingcity.lua`), and every server reader (talk window header, chat lines, radio notices, the war and work code, the sleeping rebel's ragdoll). The records terminal, staff panels and talk window already get names in their own messages from the server, so nothing changed there.
- Estimated saving on joining, at 100 NPCs: a name is about 12 characters, a job 15 to 40, a doing line 10 to 35, plus a few bytes each for the engine, so about 60 to 120 bytes per NPC: **6 to 12 KB less** in the first full update (more on a map full of long job lines). The same values now arrive a second or so after loading, a few KB, only for the people near the player. Changes of what someone is doing (28 places set it) also stop going to every player and go only to those near.
- What players might notice: right after joining, or when looking at someone far away for the first time, the name tag can take up to about a second to appear.

Tests: `NPCStrTests` in `_dev/tests.lua` (the table, defaults, the ask and answer, only changes, far ones on request, removal, the pace, a crowd split over answers). The client smoke test feeds an answer through the receiver, reads it back, checks a far NPC is asked after and a removed one forgotten.
