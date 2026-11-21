# The Valve Developer Community wiki, saved (`_dev/reference/vdc/`)

The owner saved the Valve Developer Community wiki (developer.valvesoftware.com) on 21 November with VDC Saver
(`_dev/tools/vdc_saver/`, a Chrome extension; `docs/dev/map-ingestion.md`, "The tools"): **10,220 pages** of
Half-Life 2, the Episodes, Garry's Mod and Source 1 (other games and translations left out), as wikitext, with each
page's categories. It is one file, `_dev/reference/vdc/vdc_wiki.zip` (16 MB; 57 MB of text), so it stays out of
repo-wide searches. Em dashes in it were changed to " - " (house rule 1).

**Read it with `python3 _dev/tools/vdc.py`, one page or one search at a time, never whole** (reading budget):

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
`python3 _dev/tools/vdc.py --import PATH/vdc_wiki.zip` replaces the saved one (same em dash rule) and it is committed.
