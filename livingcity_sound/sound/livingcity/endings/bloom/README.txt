ENDING: bloom (Bloom)
WHAT HAPPENS: Everyone dances (every NPC in the city too) and nobody can
stop; the camera circles you so you watch yourself. The city dims, coloured
light pulses on the beat, props hop, sparkles rise. At 2:01 the song starts
speeding up; at the top of it the dancers spin up into the sky one at a time
and burst into sparkles, and the dead watch the rest.
SONG: your file. "bloom" is a codeword: players download whatever is in this
folder, so give the file a name that gives nothing away (bloom.ogg).

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

Drop the song here: .wav, .mp3 or .ogg. Test it with: lc_ending bloom now
(lc_ending_cancel stops it)
