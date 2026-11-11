#!/bin/bash
# Living City: make recorded voice lines a little deeper (or higher), without changing their speed.
# Use (Linux Mint: sudo apt install ffmpeg):
#     bash voice_deeper.sh FOLDER_IN FOLDER_OUT
# Every .mp3, .wav or .ogg in the first folder is written to the second under the same name.
#
# Settings, put in front of the command:
#   SEMITONES   how far to move the pitch. -1.5 by default (a bit deeper). -1 is subtle, -2 clearly deeper,
#               -3 is about as far as it stays natural. A positive number goes higher.
#   BODY        yes (the default): the whole voice moves, as if the speaker were a bigger person. The most natural
#               way to make a voice deeper, by a little.
#               no: only the note moves and the character of the voice is kept (needs an ffmpeg with "rubberband";
#               if yours has none, the script says so and uses the other way).
#   FORMAT      mp3 (the default) or wav (44100 Hz, mono, 16-bit).
# Examples:
#     SEMITONES=-2 bash voice_deeper.sh voice_out/sound/livingcity/citizens deeper
#     SEMITONES=-1 BODY=no FORMAT=wav bash voice_deeper.sh in out
SEMITONES=${SEMITONES:--1.5}
BODY=${BODY:-yes}
FORMAT=${FORMAT:-mp3}
IN="$1"; OUT="$2"
if [ -z "$IN" ] || [ -z "$OUT" ]; then echo "use: bash voice_deeper.sh FOLDER_IN FOLDER_OUT"; exit 1; fi
if ! command -v ffmpeg >/dev/null; then echo "ffmpeg is not installed: sudo apt install ffmpeg"; exit 1; fi
if [ "$(cd "$IN" && pwd)" = "$(mkdir -p "$OUT" && cd "$OUT" && pwd)" ]; then echo "the two folders must be different (the originals are never overwritten)"; exit 1; fi
RATIO=$(awk "BEGIN{printf \"%.5f\", 2^($SEMITONES/12)}")
TEMPO=$(awk "BEGIN{printf \"%.5f\", 1/(2^($SEMITONES/12))}")
if [ "$BODY" = "no" ] && ! ffmpeg -hide_banner -filters 2>/dev/null | grep -q rubberband; then
    echo "this ffmpeg has no rubberband: moving the whole voice instead (BODY=yes)"
    BODY=yes
fi
if [ "$BODY" = "no" ]; then
    FILTER="aresample=44100,rubberband=pitch=${RATIO}:formant=preserved:pitchq=quality"
else
    FILTER="aresample=44100,asetrate=44100*${RATIO},aresample=44100,atempo=${TEMPO}"
fi
n=0
for f in "$IN"/*.mp3 "$IN"/*.wav "$IN"/*.ogg; do
    [ -e "$f" ] || continue
    name=$(basename "${f%.*}")
    if [ "$FORMAT" = "wav" ]; then
        ffmpeg -loglevel error -y -i "$f" -af "$FILTER" -ar 44100 -ac 1 -c:a pcm_s16le "$OUT/$name.wav" && n=$((n+1))
    else
        ffmpeg -loglevel error -y -i "$f" -af "$FILTER" -ar 44100 -ac 1 -c:a libmp3lame -b:a 128k "$OUT/$name.mp3" && n=$((n+1))
    fi
done
echo "made $n file(s) in $OUT, $SEMITONES semitones (BODY=$BODY)"
