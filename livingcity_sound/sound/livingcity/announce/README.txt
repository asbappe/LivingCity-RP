Custom announcements for Living City.

This is its own addon (garrysmod/addons/livingcity_sound/), separate from the gamemode,
so updating the gamemode never touches your recordings. Install it once and keep it.

Three flat folders. Drop the files straight in; the name says when it plays:

  overwatch/       curfew1.wav, ambient2.wav ...        the Combine PA (always cold)
  administrator/   curfew1.wav (warm), curfew_firm1.wav, the Administrator; the tone
                   curfew_stern1.wav, curfew_furious1.wav  is in the name
  radio/           static1.wav, union1.wav, freq7_1.wav  the radios and repair bench

Each folder's README.txt lists the triggers (what a name starts with) and when
they play. Every draft line is in ANNOUNCEMENT_SCRIPTS.md at the top of this addon.
In the game: lc_announce_rescan picks up new files, lc_announce_clips lists what
it found, lc_announce_say <overwatch|administrator> <trigger> [tone] plays one,
lc_announce_tier <trigger> says what tone she would use now (superadmin).
