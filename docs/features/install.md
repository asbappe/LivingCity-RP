# Install and first run, and what is left of Sandbox

1. Unzip `livingcity.zip` into `garrysmod/addons/` so you have `garrysmod/addons/livingcity/gamemodes/livingcity/...` (and `.../lua/weapons/gmod_tool/stools/`, the editor). Everything else is the gamemode's: none of it loads in any other gamemode.
   `garrysmod/addons/livingcity/` is the one official place for the gamemode: keep no other copy (an old `addons/livingcity-rp-main`, say) beside it, or both load. Your own recordings and songs go in the server's **`garrysmod/sound/livingcity/`**, the official place for them: `overwatch/`, `administrator/`, `radio/` and `endings/` (create the folders). They're outside the gamemode's folder, so updating it (deleting `addons/livingcity` and unzipping the new one) never touches them, and FastDL mirrors them to players: press the host's **FastDL sync** after adding one, then change the map.
2. In the main menu, click the gamemode button in the bottom right corner and pick **Living City**. Start a game on a city map.
3. The city starts by itself. You're a citizen. Press **F1** for your quick menu (nine things on the number keys), **C** for the full menu (the guide is the first thing in it), **F4** to pick a faction.
4. To build the city as an admin, type `!build`. Build mode gives you the spawn menu, the physgun, the toolgun and noclip. Then go to Q menu > Tools > **Living City > Living City Editor**. Type `!build` again to go back to playing.

### The gamemode, and what's left of Sandbox

Living City is built on Sandbox only so admins keep the building tools. Regular players can't spawn props, NPCs, weapons or vehicles. They also can't noclip, use the physgun or toolgun, or open the spawn and context menus. Factions and ranks are always on. Falls hurt the way they did in Half-Life 2, and the death card stays up for a few seconds before you can go on (`lc_respawn_secs`, 12). Admins outside build mode play by the same rules as everyone else.

| Key | Opens |
|---|---|
| F1 | The quick menu: nine things on the number keys, for who you are and what's in front of you (9 is the full menu). F1 works whatever it's bound to; F1 again closes it, the full menu or the guide |
| C (outside build mode) | The full menu: everything you can do right now, plus **Guide / manual**, your pockets, your board, factions and tips at the top |
| `!help` or `lc_help` | The guide on its own: topics down the side and a search box (and the admin commands, if you're an admin) |
| F2 or `!inv` | Your pockets (and your stash, when you're home) |
| F3 or `!jobs` | Your board: jobs, story chains, and your Union employment |
| F4 or `!faction` | Factions |
| `!shop` | Union Commissary (or use a commissary terminal) |
| `!market` | Black market (at a dealer, or in rebel territory) |
| `!r <msg>` | Talk on your transmitter's frequency (the CP net for units; Freq 7 with a Freq 7 radio and a radio transmitter). Nobody talks on the Union band. |
| `!search` | Units: search the person you're looking at |
| `!stash` | Your hidden stash at home (and the weapons in your hands go in it too: "Stash it") |
| `!block`, `!credits`, `!report <msg>`, `!abandon` | Housing, money and standing, staff reports, drop a job |
| C > **Tips I've seen** | Every tip card you've had, to read again at your own pace (each card says so as it shows) |
| `!holster`, or R with your hands down | Put away what you're holding (nothing in view, nothing to swing), or raise your fists / draw it again. You spawn with your hands down. Bind a key: `bind h lc_holster` |
