# Contraband, searches, the underground, and conduct

**Stop and search.** Civil Protection NPCs stop people and frisk them. It happens sometimes at checkpoints, rarely on the street, and constantly during inspection sweeps. Each person has a cooldown, so on a big server it doesn't keep landing on the same few people. When you're stopped, stand still. Walk off and you're wanted for evading inspection. They check your papers, then your pockets. Each illegal item has a chance to slip past (Guile improves it). Anything they find is confiscated, and you lose standing and become wanted. Units (players) search people with the Arrest Baton (reload) or `!search`, and get credits and XP for what they seize. That works on the city's NPC citizens too: press E to stop one, R to pat them down (sympathizers are much likelier to be carrying something), and right click to detain them. A detained citizen is cuffed for a moment and then put straight in a free cell, the same way an arrested player is, since cells are behind doors that lock; they're let out at the release point when their time is up. Getting arrested confiscates everything illegal you were carrying.

| Item | Where | What it does |
|---|---|---|
| Radio (Freq 7) | Black market, radio bench | Freq 7: private Resistance chat, sweep warnings, and garbled Civil Protection dispatch |
| Freq 7 sheet | Radio bench (Write it down) | Read it: the rule, and the seven frequencies. Contraband |
| Radio transmitter | Black market, Resistance lab | With a radio: talk on its band (hold it up like a weapon, or !r). A radio alone only listens. Contraband |
| Travel permit | Commissary (Trusted) | Gets you past one curfew stop, for the rest of that curfew |
| Spare citizen clothes | Commissary, black market | A hunted Resistance member passes as a citizen (and can hold a Union job) until someone checks their face. Units can wear them to go undercover |
| Civil Protection uniform | Black market, a dead unit, scavenging | Security NPCs take you for a unit, even if you're wanted. Combine doors usually open. Blown by any crime, by lingering near real units, by a door reading your biosignal, or by a real unit's search. Real units who look closely see "not on the roster" |
| Forged papers / a dead man's papers | Black market, morgue, or forge a blank form | A new identity: clears your wanted status if no unit is watching. Inspections can catch it (dead men's papers are better) |
| Blank identity form | Black market, luggage | Forge it in your own block or rebel territory (Guile check) |
| Forged ration card | Black market | One ration from any dispenser, whatever your standing or cooldown |
| Lockpick set | Black market | Locked doors (not Combine locks). Can snap. Being seen is breaking and entering |
| Combine bypass charge | Black market | Opens any door once, Combine doors included. Sometimes trips an alarm |

**Stash.** Eight hidden slots in your own housing block, kept in the furniture: press E on a stove, fridge, dresser, wardrobe or cupboard there and it opens in your pockets (F2) while you stand by it. Nowhere else. A street search doesn't reach it, but a raid on your block can. A Freq 7 radio warns you before a sweep.

**Keeping out of sight.** Crouch to sneak. Crouched, a Civil Protection unit or soldier sees you at half the distance, creeping slowly a little less, and in the dark less again (your own game measures how lit you are, and the server checks it: a flashlight on, or open sky over you in the daytime, is never the dark); and crouched, he doesn't see you behind his back. While you crouch, a bar at the bottom of your screen says how easily you're seen ("A UNIT CAN SEE YOU" when one does), and each unit near you has his sight painted on the ground (red if you're in it; `lc_stealth_cones 0` hides it, your own setting). It counts for everything units notice: thefts, looting a supply drop, a curfew. `lc_stealth 0` turns it off. The sight is shown in 3D: on the ground (up slopes and steps), with see-through walls about waist high and a lid, so it shows from below too.

**Running from the law.** Someone wanted who has hurt nobody is run down and cuffed: units (soldiers too) hold their fire and lay hands on you. The violent (you hurt someone in the last two minutes, are wanted for something violent, have a gun in hand, or are at a sector-wide search or above) get shot at. A curfew or lockdown called while you're wanted, or still hot from the trouble, is about you: the first unit who sees you knows you, and won't stop at a warning. A curfew in the daytime only comes as a punishment for unrest, and says so.

**Black market.** Place a dealer with the editor, or on maps without one, trade in rebel territory (`!market`). The dealer sells contraband and a crowbar, and the finished goods nobody but the Resistance lab makes (ammunition, homemade guns, armour vests, smoke bombs, jammers: everyone who isn't Resistance buys them here), and buys scrap, wedding rings, uniforms and spare papers. **Selling:** the dealer buys nearly everything in your pockets (40% of the cheapest shop price, so there's no profit in reselling; scrap, rings, radios and the like have their own prices) and the weapons you carry, unless your faction issued them to you. There's a "sell all" button for stacks.

**Lockpicks:** besides buying one from the dealer, you can **make one from four pieces of scrap** (F2, "Make pick"; scrap comes from the Reclamation job). Use it by looking at a locked door and typing `!pick`, or bind a key: `bind p lc_pick`. `!pick` also uses a keycard or bypass charge on a Combine door.

The dealer isn't a statue (the owner, 7 November): he shifts between the citizens' idles (another one every 8 to 16 seconds, so none can run out and freeze him), turns his head to whoever is nearest within 300 units, reaches to his rack when someone deals with him, and cowers when a unit takes him. A unit who walks up to the dealer busts it: it vanishes for 15 minutes, the unit gets paid, and Freq 7 hears about it. Edit `gamemodes/livingcity/gamemode/modules/shared/sh_livingcity_shop.lua` for prices and items.

Admin helpers: `lc_giveitem <name> <item> [count]`, `lc_search <name>`.

## Conduct

Every player kill is judged; unjustified ones earn strikes (2: prison, 4: kick), and leaving mid-fight (or wanted, or being chased) is remembered, but only if you chose to leave: a server restart or map change, a crash or dropped connection, or a kick isn't held against anyone. Admins clear someone's strikes from the admin tools (Handy > Clear conduct strikes) or with `lc_pardon <name>`. New spawns get 8 seconds of protection. Logged to `garrysmod/data/livingcity/conduct_log.txt`.

**Changes from the 7 November playtest.**
- **Shops** (black market, quartermaster, Union Commissary) always show the price; when you can't buy, a red note by the name says why ("Not enough credits, 25 short"). Buying or selling keeps the list where you scrolled.
- **The bypass charge** says what it does; for its first 10 seconds the door is checked every half second and opened again if it isn't open, then it stays passable for the rest of its 30 seconds.
- **Cuffs** say plainly who can be cuffed: anyone with cuffs can cuff someone whose hands are up, who is down, who a unit stopped, or from behind.
- **The call box** has a "Call for help" button in your pockets (F2); its tip points there.
- **Pockets:** a refusal now says which limit you hit, with the numbers (large items: 1, or 2 with a satchel; a uniform is a large item), not only "pockets full".
- **The CP disguise** wears the HL:Alyx metrocop playermodel when one is installed or named in `lc_pm_metrocop`; with none, nothing changes.
