Secret endings: the songs go straight in this folder, no subfolders.

Name each song for its ending (the codeword), so the name gives nothing away
(players download these files when they join):

  harpies.mp3  bus.mp3  plane.mp3  standup.mp3  water.mp3
  bloom.mp3    marrow.mp3  base.mp3  hard.mp3  shalom.mp3

.mp3, .ogg or .wav. Keep the extension true to the file: an MP3 renamed .wav is
silent (lc_announce_clips points out any file the game can't play). MP3 or OGG
for songs: a song as WAV is ten times the download.
Several songs for one ending: bus1.mp3, bus2.mp3 (one is picked each time).
lc_endings lists what's found; lc_ending <codeword> now plays one
(lc_ending_cancel stops it). Full details: README.md, "Secret endings".
(An older layout, a folder per ending, endings/bus/anything.mp3, still works.)

========================================================================
ENDING: harpies (The Harpies)
WHAT HAPPENS: The lights go out and everyone is put at the dropship landing
zone. Mingebags (Dr. Kleiner in the reference pose, physgun at the crotch) gather in the dark for a minute, keeping their distance;
when the song swells they rush in, surround everyone, and 9 seconds later
leap. The Combine's units (in a ring, with the city's people between them
and the players) chatter on their radios out loud, and open fire the moment
the mingebags leap. Everyone is dead by 2:00 and watches the rest.
SONG: Son of the Harpy (your file, named harpies.mp3). It should swell at 1:00 and run about
two minutes. If yours swells somewhere else, set lc_ending_minge_swell to
that second (and lc_ending_minge_end to when it should all be over).

Test it with: lc_ending harpies now   (lc_ending_cancel stops it)

========================================================================
ENDING: bus (The Bus)
WHAT HAPPENS: The party bus. It drives about through the song's intro; on the drop everyone (and some of the Combine) is seated in it, and it flies through walls with a rainbow behind it, speed surging on the beat, through rings that pop. It comes down to drive again at 2:29 and takes off faster at 2:56; over at 3:40. Line it up with your file: lc_ending_bus_sections "27:fly,149:drive,176:fast,220:end", lc_ending_bus_bpm 138.
SONG: your file, named bus.mp3 (or .ogg), so its name gives nothing away.

Test it with: lc_ending bus now   (lc_ending_cancel stops it)

========================================================================
ENDING: plane (Plane)
WHAT HAPPENS: Numa numa. Like the band in the video, everyone dances on the
wings of an airplane over the city. It circles low through the intro; at the
first hook (0:17) everyone, and some of the Combine's units, are up on the
wings doing the webcam dance, arms rolling in front of their faces, every jaw
mouthing the words, and a grainy little webcam of your own face in the
corner. The sing-along captions come up on the calls and the choruses. The
verses cruise, the choruses swoop and barrel-roll, the breakdown glides with
the lights down, the last chorus is fastest with fireworks round the plane,
and on the final note it climbs into the clouds and everything goes white.
SONG: your file. "plane" is a codeword: name the file plane.mp3
(or .ogg), so its name gives nothing away.

The timeline was worked out from the song itself (3:35, about 130 BPM):
  lc_ending_plane_sections "17:board,26:verse,63:chorus,89:verse,122:chorus,148:break,167:final,210:climb,215:end"
  lc_ending_plane_captions "15.1=MA-IA-HII|16.3=MA-IA-HUU|17.5=MA-IA-HOO|18.7=MA-IA-HAHA"
    (the vocals start about 0:15; nudge the captions if they're off)
  lc_ending_plane_bpm 130, lc_ending_plane_combine 8

Test it with: lc_ending plane now   (lc_ending_cancel stops it)

========================================================================
ENDING: standup (Standup)
WHAT HAPPENS: The rope: the Klan, strung up. From 0:11, every other beat,
someone else is strung up, painted white with a white cone hat over their
head, while a crowd of the city's people gathers round and cheers each one
(lc_ending_standup_crowd, 14). The rope goes to whatever is above them (a ledge, a balcony, a ceiling), or the
nearest wall of a building, or failing both, the sky. The players are spread
through the song; the city's people (the Combine's units too) fill the beats
between, and when there's nobody left, new people turn up near you to be next.
The hanged swing and struggle while their health drains, then go limp and stay
there, looking on (nobody really dies: no close call, no new character). By
1:44 everyone is up; at 1:50 the city resets.
SONG: your file. "standup" is a codeword: name the file standup.mp3
(or .ogg), so its name gives nothing away.

The timeline was worked out from the song itself (1:51, about 133 BPM):
  lc_ending_standup_sections "11:hang,104:last,110:end"
  lc_ending_standup_bpm 133      someone new every other beat
  lc_ending_standup_drain 4      health a second on the rope
  lc_ending_standup_max 60       the most strung up in all

Test it with: lc_ending standup now   (lc_ending_cancel stops it)

========================================================================
ENDING: water (The Flood)
WHAT HAPPENS: A stage floats at the dropship landing zone with everyone on it,
in the worst storm the city has seen. The water rises over the city; waves
knock people off the stage; ichthyosaurs hunt the water and leap at the edge;
swim (hold Jump) or drown. Father Grigori is on the mic the whole time, his jaw
following the song: headbanging the heavy parts, dancing the rest. He's
untouchable, and goes last on the final note.
Triggered by Father Grigori eating a master data core: Eat it, on the core in
his pockets (F2), or /eatchip.
SONG: your file. "water" is a codeword: name the file water.mp3
(or .ogg), so its name gives nothing away.

The timeline was worked out from the song itself (4:45, about 150 BPM):
  lc_ending_flood_sections "15:heavy,79:calm,102:heavy,134:calm,169:heavy,183:climax,212:calm,235:heavy,249:climax,264:outro,276:last,285:end"
  kinds: calm, heavy, climax (how violent the storm, the waves and the
  ichthyosaurs are), outro (it calms), last (the final note: everyone goes,
  Father Grigori last), end (the reset). Before the first: it builds.

Test it with: lc_ending water now
(lc_ending_cancel stops it)

========================================================================
ENDING: bloom (Bloom)
WHAT HAPPENS: Everyone dances (every NPC in the city too) and nobody can
stop; the camera circles you so you watch yourself. The city dims, coloured
light pulses on the beat, props hop, sparkles rise. At 2:01 the song starts
speeding up; at the top of it the dancers spin up into the sky one at a time
and burst into sparkles, and the dead watch the rest.
SONG: your file. "bloom" is a codeword: name the file bloom.mp3
(or .ogg), so its name gives nothing away.

Tuning (console, superadmin):
  lc_ending_bloom_bpm 165          the song's beats per minute
  lc_ending_bloom_offset 0         seconds into the song of the first beat
  lc_ending_bloom_speedup 121      when it starts speeding up (2:01)
  lc_ending_bloom_ramp 20          seconds to reach top speed
  lc_ending_bloom_peak 1.6         top speed (pitch rises with it)
  lc_ending_bloom_launch_secs 16   how long the launches take, one at a time
The dance itself (anyone, only on their own screen): lc_bloom_preview dances
on the spot; lc_bloom_pose <bone> <pitch> <yaw> <roll> changes a bone;
lc_bloom_pose_print prints the pose to send back.

Test it with: lc_ending bloom now
(lc_ending_cancel stops it)

========================================================================
ENDING: marrow (Marrow)
WHAT HAPPENS: Everyone, the Combine's units too, is put at the dropship
landing zone; every door is locked open, the map goes dark, and purple
and orange light pulses everywhere on the beat. Skeletons appear
dancing all over the map and work their way in. On the heavy parts everyone
is made to dance with them, club lights strobing (the rave part faster); in
between, the skeletons attack, and whoever they get becomes one of them,
dancing for good. The outro (the xylophone) claims everyone left, and
everyone dances it out at double time; then the city resets.
SONG: your file. "marrow" is a codeword: name the file marrow.mp3
(or .ogg), so its name gives nothing away.

The song's sections (console, superadmin), seconds:kind, in order:
  lc_ending_marrow_sections "45:dance,75:attack,82:rave,112:attack,150:dance,180:attack,188:dance,217:outro,232:end"
  kinds: dance (the heavy parts), rave (faster dancing), attack (the
  skeletons go for people), outro (they claim everyone; double-time dancing), end (the reset).
  Before the first one, the skeletons gather.
  lc_ending_marrow_bpm 128     the beat the dancing and lights keep to
  lc_ending_marrow_max 40      how many skeletons

Test it with: lc_ending marrow now   (lc_ending_cancel stops it)

========================================================================
ENDING: base (Base)
WHAT HAPPENS: Somebody set up us the bomb. The city stops and dims, and the
song's opening lines come up as arcade subtitles; bombs appear all over the
city, blinking and beeping; the main screen turns on and CATS fills the sky.
When the remix kicks in everyone (and some of the Combine) is on a ZIG, a
dropship, and the whole fleet circles the city on the beat while the bombs go
off below; "Move ZIG", faster; "For great justice", the fleet dives at CATS,
the bombs chain, and everything blows. The whole screen is blocky
and pixelated, like the old arcade game (lc_pixel_size, per player). Everyone's chat comes out in Engrish
the whole time.
SONG: your file. "base" is a codeword: name the file base.mp3
(or .ogg), so its name gives nothing away.

The timeline was worked out from the song itself (3:44; the lines for the
first 33 seconds, then the remix at about 150 BPM):
  lc_ending_base_sections "3.5:bomb,9.5:screen,34:zig,126:move,174:justice,212:boom,224:end"
  lc_ending_base_lines    the subtitles, second=WHO: line, separated by |.
                          Which spoken bit is which line is my best guess from
                          the audio: listen once and move them if they're off.
  lc_ending_base_bpm 150, lc_ending_base_bombs 30

Test it with: lc_ending base now   (lc_ending_cancel stops it)

========================================================================
ENDING: hard (Hard)
WHAT HAPPENS: Party hard. Everyone is gathered at the dropship landing zone,
the Combine's units with them, and every NPC in the city dances where they
stand: the cheap meme dance, a pose and its mirror image flipping every
half-beat. PARTY HARD flashes all over the screen and over every head, the
strobe never stops, the screen flashes colour on the beat. From 2:30 people
pass out one at a time, having partied too hard; when the music cuts out, the
rest go down too. Then the reset.
SONG: your file. "hard" is a codeword: name the file hard.mp3
(or .ogg), so its name gives nothing away.

The timeline was worked out from the song itself (3:08, about 150 BPM):
  lc_ending_hard_sections "6:hard,28:break,32:hard,150:passout,177:fade,188:end"
  kinds: hard (full on), break (everyone freezes mid-pose), passout (people
  drop, one at a time), fade (the rest go down), end (the reset).
  lc_ending_hard_bpm 150

Test it with: lc_ending hard now   (lc_ending_cancel stops it)

========================================================================
ENDING: shalom (Shalom)
WHAT HAPPENS: The hora. Israeli flags run up their poles round the dropship
landing zone, and everyone dances the hora in rings round a giant hanukkiah,
kippahs on every head, Yiddish and Hebrew sayings floating over them. The
Combine put their guns down and join in at 1:02, a candle is lit each phrase,
someone goes up on a chair every so often, everyone rushes into the middle on
the breakdowns, and at the key change (3:25) a giant flag unfurls across the
sky with Star of David fireworks. Everyone dances to the last note; then Am
Yisrael chai, Shalom, and the reset. No strobes.
SONG: your file. "shalom" is a codeword: name the file shalom.mp3 (or .ogg).

The timeline was worked out from the song itself (4:49, 136 BPM, first beat
at 0.36 s; E Phrygian dominant, up a half step to F at 3:25):
  lc_ending_shalom_sections "7.4:gather,35.7:walk,62.1:hora,111.5:lift,125.7:hora,153.9:in,157.4:hora,180.4:in,183.9:build,205.1:peak,219.2:hora,224.5:in,231.5:final,273.9:outro,288.5:end"
  kinds: gather (sway arm in arm, kippahs on), walk (round, half speed),
  hora (the dance), lift (chairs every 4 beats), in (rush into the middle and
  back), build (speeding up), peak (the key change: the sky flag, fireworks),
  final (fastest, fireworks), outro (slowing down, the last words), end.
  lc_ending_shalom_candles "35.7,62.1,86.8,111.5,125.7,153.9,183.9,205.1"
  lc_ending_shalom_bpm 136   lc_ending_shalom_offset 0.36

Test it with: lc_ending shalom now   (lc_ending_cancel stops it)
