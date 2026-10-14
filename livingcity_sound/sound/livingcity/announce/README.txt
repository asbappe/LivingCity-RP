Custom announcements for Living City.

This is its own addon (garrysmod/addons/livingcity_sound/), separate from the gamemode,
so updating the gamemode never touches your recordings. Install it once and keep it.

Three flat folders. Drop the files straight in; the name says when it plays:

  overwatch/       curfew1.wav, ambient2.wav ...        the Combine PA (always cold)
  administrator/   curfew1.wav (warm), curfew_firm1.wav, the Administrator; the tone
                   curfew_stern1.wav, curfew_furious1.wav  is in the name
  radio/           static1.wav, union1.wav, freq7_1.wav  the radios and repair bench

THE FORMAT MATTERS. A file's extension must match what it really is:
  - An MP3 renamed to .wav is SILENT for everyone. Keep MP3s as .mp3
    (curfew1.mp3 is fine: the name rule is the same).
  - A real .wav must be 16-bit, at 44100, 22050 or 11025 Hz. 48000 Hz,
    24-bit and 32-bit float WAVs are silent.
  - MP3s are the easy choice, and far smaller for players to download.
lc_announce_clips lists every file the game can't play, and how to fix each.

Each folder's README.txt lists the triggers (what a name starts with) and when
they play. Every draft line is in ANNOUNCEMENT_SCRIPTS.md at the top of this addon.
In the game: lc_announce_rescan picks up new files, lc_announce_clips lists what
it found, lc_announce_say <overwatch|administrator> <trigger> [tone] plays one,
lc_announce_tier <trigger> says what tone she would use now (superadmin).
