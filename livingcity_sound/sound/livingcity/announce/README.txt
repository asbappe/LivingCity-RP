Custom announcements for Living City.

This is its own addon (garrysmod/addons/livingcity_sound/), separate from the gamemode,
so updating the gamemode never touches your recordings. Install it once and keep it.

  overwatch/<trigger>/                       the Combine PA (always cold)
  administrator/<trigger>/                   the Administrator: the tone is in the
                                             file name (firm, stern or furious in
                                             it; anything else is warm)
  radio/static/, radio/union/, radio/freq7/  the radio repair bench: static, the
                                             Union band, and the Resistance's
                                             pirate broadcast (see radio/README.txt)

Put sound files (.wav, .mp3, .ogg) in a trigger's folder and the city plays one
when that thing happens. The Administrator picks her tone herself: each trigger
has a usual one, it goes up a step while the city is on red, and up again after
a run of violence. If a tone has no recordings she uses the nearest one.
Every folder has a README.txt saying when it fires and giving draft lines to
record. An optional .txt with the same name as a sound is its subtitle.
In the game: lc_announce_clips lists what it found, lc_announce_rescan picks up
new files, lc_announce_say <overwatch|administrator> <trigger> [tone] plays one
now, lc_announce_tier <trigger> says what tone she would use (superadmin).
Full details: README.md, "Custom announcements".
