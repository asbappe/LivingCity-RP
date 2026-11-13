# Half-Life 2's ammo limits

The owner, 13 November: "the gamemode is using the Garry's mod max ammo count ... Can we set the ammo limits for all characters/classes/jobs/ranks/NPCs/players to the HL2 ammo limits instead and have this apply to those instead of the Gmod ammo limits?", and "please make sure this is persistent across deaths, respawns, close calls (near deaths) and waking up from dreams".

- **The limits** (sv_livingcity_ammo.lua, `LC.HL2_AMMO`, `LC.AmmoMax`): pistol 150, SMG 225, .357 12, pulse rifle 60, shotgun 30, crossbow 10, grenades 5, SMG grenades 3, pulse rifle balls 3, rockets 3. The same for everyone: every side, rank and job. Garry's Mod's own is 9999 of everything (`gmod_maxammo`).
- **How**: the server's `gmod_maxammo` is set to 0 (each kind's own limit) and the skill settings `sk_max_*` to Half-Life 2's. Picking up or being given rounds stops at the limit. `lc_hl2_ammo` (1); 0 puts Garry's Mod's 9999 back.
- **Kept that way**: set again at every map start and checked every five seconds (a map's skill settings can change them). Anyone's rounds are cut down to the limit when they spawn or respawn, after a close call (revived), and on waking from a dream (their rounds are put back capped: sv_livingcity_dreams.lua), and the same after a story scene gives their gear back (sv_livingcity_stories.lua); the five-second check catches anything else (`LC.ClampAmmo`, `LC.AmmoCapped`).
- **NPCs**: in Half-Life 2 they never run out (they reload forever), so there is nothing to limit for them.
- **The resupply scanner** counts "under 30%" of these limits (`docs/features/radio-hq-and-resupply.md`).

Tests: `RadioHQTests` ("Half-Life 2's ammo limits"), `DreamTests`.
