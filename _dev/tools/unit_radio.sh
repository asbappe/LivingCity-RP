#!/bin/bash
# Living City: make a clean voice recording sound like a Civil Protection unit's mask radio.
# Use (Linux Mint: sudo apt install ffmpeg):
#     bash unit_radio.sh FOLDER_OF_CLEAN_RECORDINGS FOLDER_FOR_RESULTS
# Every .mp3, .wav or .ogg in the first folder is written to the second as a .wav
# (44100 Hz, mono, 16-bit: what the game wants), with:
#   the pitch dropped a little (deeper), the lows and highs cut (a small speaker),
#   hard compression (flat, loud, close), a little digital crush and a fast buzz (the vocoder's gargle),
#   and a short burst of static before and after (the radio keying on and off).
# Change DEPTH (0.90 deeper .. 1.00 as recorded), BUZZ (0 none .. 0.6 heavy) and CRUSH (0 clean .. 0.6 gritty) to taste.
DEPTH=${DEPTH:-0.93}
BUZZ=${BUZZ:-0.35}
CRUSH=${CRUSH:-0.30}
IN="$1"; OUT="$2"
if [ -z "$IN" ] || [ -z "$OUT" ]; then echo "use: bash unit_radio.sh FOLDER_IN FOLDER_OUT"; exit 1; fi
mkdir -p "$OUT"
TEMPO=$(awk "BEGIN{printf \"%.4f\", 1/$DEPTH}")
n=0
for f in "$IN"/*.mp3 "$IN"/*.wav "$IN"/*.ogg; do
    [ -e "$f" ] || continue
    name=$(basename "${f%.*}")
    ffmpeg -loglevel error -y -i "$f" \
        -f lavfi -t 0.09 -i "anoisesrc=color=white:amplitude=0.25:sample_rate=44100" \
        -f lavfi -t 0.12 -i "anoisesrc=color=white:amplitude=0.25:sample_rate=44100" \
        -filter_complex "[0:a]aresample=44100,aformat=channel_layouts=mono,asetrate=44100*${DEPTH},aresample=44100,atempo=${TEMPO},highpass=f=320,lowpass=f=2900,acompressor=threshold=-24dB:ratio=8:attack=3:release=60:makeup=8,acrusher=bits=8:samples=6:mix=${CRUSH}:mode=log,tremolo=f=85:d=${BUZZ},highpass=f=320,lowpass=f=3200,alimiter=limit=0.9[v];[1:a]highpass=f=900,lowpass=f=3500,aformat=channel_layouts=mono[a];[2:a]highpass=f=900,lowpass=f=3500,aformat=channel_layouts=mono[b];[a][v][b]concat=n=3:v=0:a=1,alimiter=limit=0.9[o]" \
        -map "[o]" -ar 44100 -ac 1 -c:a pcm_s16le "$OUT/$name.wav" && n=$((n+1))
done
echo "made $n file(s) in $OUT"
