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
SONG: your file. "base" is a codeword: players download whatever is in this
folder, so give the file a name that gives nothing away (base.ogg).

The timeline was worked out from the song itself (3:44; the lines for the
first 33 seconds, then the remix at about 150 BPM):
  lc_ending_base_sections "3.5:bomb,14.7:screen,34:zig,126:move,174:justice,212:boom,224:end"
  lc_ending_base_lines    the subtitles, second=WHO: line, separated by |.
                          Which spoken bit is which line is my best guess from
                          the audio: listen once and move them if they're off.
  lc_ending_base_bpm 150, lc_ending_base_bombs 30

Test it with: lc_ending base now   (lc_ending_cancel stops it)
