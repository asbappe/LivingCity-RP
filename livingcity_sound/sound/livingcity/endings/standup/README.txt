ENDING: standup (Standup)
WHAT HAPPENS: The rope. From 0:11, every other beat, someone else is strung
up: a rope from whatever is above them (a ledge, a balcony, a ceiling), or the
nearest wall of a building, or failing both, the sky. The players are spread
through the song; the city's people (the Combine's units too) fill the beats
between, and when there's nobody left, new people turn up near you to be next.
The hanged swing and struggle while their health drains, then go limp and stay
there, looking on (nobody really dies: no close call, no new character). By
1:44 everyone is up; at 1:50 the city resets.
SONG: your file. "standup" is a codeword: players download whatever is in this
folder, so give the file a name that gives nothing away (standup.ogg).

The timeline was worked out from the song itself (1:51, about 133 BPM):
  lc_ending_standup_sections "11:hang,104:last,110:end"
  lc_ending_standup_bpm 133      someone new every other beat
  lc_ending_standup_drain 4      health a second on the rope
  lc_ending_standup_max 60       the most strung up in all

Test it with: lc_ending standup now   (lc_ending_cancel stops it)
