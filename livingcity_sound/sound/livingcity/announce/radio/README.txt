The radios and the radio repair bench. Put every recording straight in this
folder; the name starts with what it is:

  static1.wav, static2.wav      the hiss between stations
  union1.wav, union2.wav        an ordinary station on the Union band (none:
                                the Administrator's ambient recordings play there)

FREQ 7, the Resistance's pirate broadcast. One station: every radio on it
hears the same thing at once, a voice line, then a song, then a voice line.
  freq7_1.wav, freq7_2.wav ...  the voice lines between songs; a .txt with the
                                same name is the line shown on the repair
                                bench's dial panel
  freq7_song_<anything>.ogg     the songs (freq7_song_maple_leaf_rag.ogg).
                                Use .ogg or .wav, not .mp3: the server reads
                                how long they run. Public domain recordings
                                only (anything published before 1926 is safe).
  Warnings, cutting in at once (even mid-song), then a song:
  freq7_sweep1.wav              two minutes before a papers sweep
  freq7_raid1.wav               two minutes before a block raid
  freq7_curfew1.wav             two minutes before curfew
  freq7_supply1.wav             two minutes before a supply convoy
  freq7_incursion1.wav          Civil Protection sweeping into rebel territory
  freq7_lockdown1.wav           a lockdown declared
  freq7_dropship1.wav           an Overwatch dropship coming in
  jam1.wav                      the Combine's jamming whine, heard where Freq 7
                                was found (loops; a stock sound otherwise)

Static and the Union band loop: every track keeps playing while the dial moves
and only its volume changes. Freq 7 plays each thing once, then the next.
Anyone within about twenty feet of a set hears it, quieter further away.
In game, lc_announce_clips lists what was found; lc_freq7_status says where
Freq 7 is now. Draft lines: ANNOUNCEMENT_SCRIPTS.md.
