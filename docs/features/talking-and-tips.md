# Talking, knowing people, going down, and tips

**Chat is in character and spoken out loud.** Ordinary chat only reaches people within `lc_chat_range` (350 units).
- `/y` yells further; `/w` whispers to whoever is right next to you.
- `/me` describes an action (`/me leans against the wall.`); `/it` describes the scene (`/it A siren starts up somewhere.`).
- `/roll` rolls 1-100 for everyone near.
- `//` or `/ooc` is out of character, server-wide, with a cooldown (`lc_ooc_cooldown`, admins exempt; `lc_ooc 0` turns it off). `/looc` is out of character, nearby only.
- `!` commands still go to the game as before. A mistyped `/` command is swallowed, not said out loud.
- **Voice** is proximity too: `lc_voice_range` (900 units, 0 for everyone hears everyone).
- `lc_ic_chat 0` turns all of this off.

**Recognition.** Strangers don't know your name: they hear and see your description instead ("A man in Union blue").
- `/chardesc <text>` sets your description (8 to 120 characters).
- `/recognize` introduces you to the person you're looking at; `/recognize all` to everyone in earshot. They hear you by name from then on, and nametags follow the same rules.
- Who knows whom is remembered across sessions. A new character (after a permanent death) starts with nobody known.
- Units are known by their designation while masked.

**Acts.** Poses you hold: `/sit`, `/kneel`, `/lie`, `/lean`, `/cower`, `/pose 1-4` (`/stand`, or just move, to get up), and `!handsup`. Gestures: `/wave`, `/salute`, `/bow`, `/nod`, `/shake`, `/point`, `/beckon`, `/halt`, `/cheer`, `/laugh`. All work with `!` too. While you hold a pose the camera pulls back so you can see yourself (`lc_act_thirdperson 0` keeps it first person). Each pose tries a list of animations, the GMod player ones first, then Half-Life 2's; a model with none of them still holds you still and says so. `lc_acts 0` turns them off.

**Going down instead of dying.** A killing blow puts a player on the ground, bleeding out, for `lc_downed_secs` (90 seconds).
- Downed players can only whisper.
- Press E on a downed body to help them up: 8 seconds bare-handed (back at 10 health), 4 with a bandage (back at 30).
- A unit pressing E on a wanted person cuffs them where they lie.
- Shooting or hitting a downed body finishes them. Damage of 300 or more (explosions and the like) kills outright.
- `!drag` while looking at a downed body drags it along; `!drag` again lets go.
- `!giveup` lets go if nobody is coming: your body stays where it lies (no second ragdoll), and the screen goes to the death view.
- Zombies and build mode skip all this. `lc_downed 0` turns it off.

## Tips as you play

So nobody has to read all this first, the game explains itself as it happens. The first time you run into something, a small card slides in on the right of the screen saying what it is and what you can do with it, using your own key bindings. Each stays up 14 to 28 seconds, depending on its length. The getting-started tips come half a minute apart; tips about what's around you come as you meet things. Each tip shows once per player and is remembered across sessions; a few (hungry, thirsty, hurt) come back now and then. One shows at a time, and anything urgent (you've gone down, you're wanted, a unit is stopping you) goes straight to the front.

- **What happens to you:** going down, getting back up, wanted, the escalation levels, stop and search, being told to stop running, custody, release, escape, curfew warnings, putting on a disguise, a blown cover, a conduct strike, a new character, promotions, your first ration, making a gun.
- **What happens around you:** rations, inspection sweeps, block raids, curfew, lockdown, rebel raids and CP sweeps, an outbreak, the city tipping into unrest or full compliance. Units and citizens are told different things.
- **What's near you:** someone down (if you can see them), a body, bins, water, sinks, stoves, vending machines, ration dispensers, the Commissary, the black market dealer, the quartermaster and his fighters, rebel supply crates and pots, power banks and turrets, graffiti, citizens, units, someone wanted (for units), strangers, birds, headcrabs, rebel ground, the infestation, your own block, a Combine-only zone, a gun out while in plain clothes, the Grenades weapon in your hand.
- **What's in your pockets:** seeds, a fishing line, a spray can, a lockpick, a bypass charge, a keycard, raw meat, empty or untreated water, clothes, a uniform, Resistance gear, papers, a blank form, a forged ration card, a radio, a permit, materials, a bandage, guns and ammo, a smuggled crate, grenades, tablets, a wedding ring.
- **How you're doing:** hungry, thirsty, parasites, hurt, standing below zero, or high enough to join Civil Protection.

`!hints` shows the last few again in chat, `!hints off` and `!hints on` turn them off and on for you, and `!hints reset` starts them over. `lc_hints 0` turns them off for the whole server. The tips themselves are a table at the top of `gamemodes/livingcity/gamemode/modules/server/sv_livingcity_hints.lua`, easy to reword or add to.
