# Save files (asked for by the owner, later on 7 November)

Every save file lives in `garrysmod/data/livingcity/`. Garry's Mod's `file.Write` isn't atomic: a crash, a host restart or a full disk in the middle of a write leaves a cut-off file. Before this, most modules read a cut-off file as "nothing", started from an empty default and saved that over the real file on the next save, wiping it.

## The helper (`sv_livingcity_safefile.lua`, loaded second of the server modules)

- `LC.SafeWrite(path, text, opts)`: writes `<path>.tmp.txt`, reads it back and checks it (same length; JSON that decodes for a `.json` file). Only then the good file that was there becomes `<path>.bak.txt` and the new one takes its place (moved with `file.Rename` where the game has it, copied and read back where it doesn't). A failed check changes nothing. `opts.force` is for an admin's own save (restoring a layout backup) and the endings cooldown (a single time stamp, nothing to lose).
- `LC.SafeReadJSON(path)`: returns the table and `"ok"`, `"missing"` (no file: start fresh), `"backup"` (unreadable: `.tmp.txt`, then `.bak.txt` was used; a warning in the log, once) or `"failed"`. A file that's gone uses only its `.tmp.txt` (a save cut short in the middle of the swap): one deleted by hand to start it over stays deleted, its old `.bak.txt` isn't brought back.
- **The guard:** on `"failed"` (the file is there but neither it nor its backups read) the path is marked and `LC.SafeWrite` refuses to save over it, so the module's empty default never replaces the real data. The mark goes when the file reads again, or when a superadmin presses "Let the city save over them" in the admin tools (The city section; superadmins are told on joining, and the debug report lists it under setup notes). The first save after that keeps the unreadable file as `<path>.unreadable.txt`.
- `LC.SafeDelete(path)`: removes the file with its `.tmp.txt` and `.bak.txt` (a dream snapshot put back must not come back from its backup).

The extra files end in `.txt` (the data folder only takes certain extensions) and never in `.json`, so nothing that lists `*.json` (dream snapshots, layout backups) sees them. The main file names and formats are unchanged.

## Every data file

| File (`data/livingcity/...`) | Written by | Now |
|---|---|---|
| `<map>.json` (the layout) | sv_livingcity_data.lua | safe write and read; it also keeps its own timed backups in `backups/<map>/` and its `_unreadable_` copy, as before (a broken layout is copied aside, then may be saved again) |
| `<map>_territory.json` | sv_livingcity_territory.lua | safe write and read, guarded |
| `known.json`, `word.json` | sv_livingcity_life.lua | safe, guarded |
| `<map>_storage.json` | sv_livingcity_storage.lua | safe, guarded |
| `endings.json` | sv_livingcity_endings.lua | safe write (forced) and read |
| `ending_tuning.json` | sv_livingcity_endingtune.lua | safe, guarded |
| `<map>_camp.json` | sv_livingcity_campmove.lua | safe, guarded |
| `<map>_people.json` | sv_livingcity_people.lua | safe, guarded |
| `pending_raid.json` | sv_livingcity_raids.lua | safe, guarded |
| `dreams/<steamid64>.json` | sv_livingcity_dreams.lua | safe, guarded (a new dream can't overwrite an unreadable snapshot); deleted with its backups |
| `<map>_market.json` | sv_livingcity_market.lua | safe, guarded |
| `<map>_manpower.json` | sv_livingcity_manpower.lua | safe, guarded |
| `<map>_stock.json` | sv_livingcity_stockpile.lua | safe, guarded |
| `warnings.json`, `charbans.json` | sv_livingcity_staff.lua | safe, guarded |
| `records.json`, `bolos.json` | sv_livingcity_cp.lua | safe, guarded; BOLOs are only written once they've been read this run (before, the records timer could write an empty BOLO list over them) |
| `mail.json` | sv_livingcity_mail.lua | safe, guarded |
| `<map>_rentals.json` | sv_livingcity_business.lua | safe, guarded |
| `<map>_notes.json`, `laws.json` | sv_livingcity_writing.lua | safe, guarded |
| `outfits.json` | sv_livingcity_outfits.lua | safe, guarded |
| `logs/<date>.txt` (staff log), `conduct_log.txt` | sv_livingcity_staff.lua, sv_livingcity_conduct.lua | unchanged: appended a line at a time, a crash loses at most the last lines |
| `reports/report_<time>.txt`, `backups/<map>/*.json` | sv_livingcity_debug.lua, sv_livingcity_data.lua | unchanged: each a new file, never overwritten |
| Player records (PData, `sv.db`) | many | unchanged: SQLite is already safe |

Tests: `SafeFileTests` in `_dev/tests.lua` (`python3 _dev/run_section.py --unit SafeFileTests`).
