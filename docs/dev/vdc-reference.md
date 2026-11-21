# The Valve Developer Community wiki, saved (`_dev/reference/vdc/`)

The owner saved the Valve Developer Community wiki (developer.valvesoftware.com) on 21 November with VDC Saver
(`_dev/tools/vdc_saver/`, a Chrome extension; `docs/dev/map-ingestion.md`, "The tools"): **10,220 pages** of
Half-Life 2, the Episodes, Garry's Mod and Source 1 (other games, translations and Source 2 SteamVR pages left out:
9,984 pages kept), as wikitext, with each page's categories. It is one file, `_dev/reference/vdc/vdc_wiki.zip`
(15 MB; 57 MB of text), so it stays out of repo-wide searches. Em dashes in it were changed to " - " (house rule 1).
**Where to look for a topic: `docs/dev/vdc-topics.md`** (the table of contents, 4 KB).

**Read it with `python3 _dev/tools/vdc.py`, one page or one search at a time, never whole** (reading budget):

- **`vdc.py --card func_door`: start here for an entity.** What it is; every keyvalue, flag, input and output in a
  line each (`[only GAME]` marks those another game has and Garry's Mod does not); its bugs, warnings and tips; how
  many times Valve's HL2/EP1/EP2 maps place it (from `_dev/reference/valve_*/measure.json`); the map lessons
  (`_dev/reference/lessons.json`) that name it. Three sources joined when asked, so none goes stale.
- `vdc.py --search door areaportal`: the best pages for a question, a line on each (about a second).
- `vdc.py --gotchas areaportal`: every bug, warning, workaround and "important" on a topic, wiki-wide.
- `vdc.py --entities light`: entity pages, the ones Valve's maps use most first, a line on each.
- `vdc.py func_door`: the page, with its keyvalue, input, output and flag templates (`{{KV Door}}`, `{{I Door}}`...)
  filled in, so every keyvalue and I/O is on one page. 200 lines at a time (`--from N`, `--lines N`); `--raw` as saved.
- `vdc.py --find door rotating`: page names holding all the words. A wrong name prints the close ones.
- `vdc.py --grep 'areaportal'`: matching lines in every page (regex, any case; `--max N`, at most 3 a page).
- `vdc.py --cat "Brush entities"`: the pages in a category. `vdc.py --info NAME`: categories, revision, size.

**Use it when** building or checking a map piece or module: what an entity's keyvalues, spawnflags, inputs and
outputs are and do (and its bugs, which the pages note), how Valve says to do a thing (areaportals, optimization,
lighting, displacements, cubemaps, nav meshes, soundscapes, particles), what a texture tool or compile option does.
The game's real maps and the owner's corrections still come first (`map_lessons.py`, `docs/dev/city18-reference.md`);
the wiki says what the engine allows, not what Living City looks like. Entity pages cover several games: check
the page says Half-Life 2 or Source base before relying on a keyvalue (a keyvalue tagged only for another game,
like `only={{hls}}`, does not exist in Garry's Mod).

**A newer copy:** the owner saves one with VDC Saver ("Download zip") and sends it; then
`python3 _dev/tools/vdc.py --import PATH/vdc_wiki.zip` replaces the saved one (same em dash rule; translations and
SteamVR/helper pages left out) and it is committed. The index side is `_dev/tools/vdc_find.py`.
