#!/usr/bin/env bash
# Living City: record every named citizen line (man and woman) with ElevenLabs, the simple way.
#
#   bash record_citizens.sh        makes 3 test lines only, then stops
#   bash record_citizens.sh all    makes all the rest (158 in all)
#
# Keep these three files together in one folder: record_citizens.sh, elevenlabs_batch.py, voice_batch.tsv.
#
# It asks for your ElevenLabs key (typed hidden, never saved) and makes the lines louder. Lines already made
# are skipped, so "all" never redoes the test lines. To redo the test, delete voice_out and run it again. To use other voices, change the two ids below (ElevenLabs shows the id beside each voice).

MAN="zSPSnKB3yoR0pAl7oln6"
WOMAN="6ybFVMFdNOweF3NRmXj7"

HERE="$(cd "$(dirname "$0")" && pwd)"   # everything it needs sits in this same folder
OUT="$HERE/voice_out"
DIR="$OUT/sound/livingcity/citizens"
BATCH=(python3 -u "$HERE/elevenlabs_batch.py" --man "$MAN" --woman "$WOMAN" --out "$OUT")

ask() { read -r -p "$1 [y/n] " a; [[ "$a" == [yY]* ]]; }

if [ -z "$ELEVENLABS_API_KEY" ]; then
    read -r -s -p "Paste your ElevenLabs key (it will not show) and press Enter: " ELEVENLABS_API_KEY
    echo
    export ELEVENLABS_API_KEY
fi
[ -n "$ELEVENLABS_API_KEY" ] || { echo "No key given: nothing done."; exit 1; }

set -o pipefail
mkdir -p "$DIR"

if [ "$1" = "all" ]; then
    echo
    echo "== Making ALL the citizen lines =="
    "${BATCH[@]}" --dry-run 2>&1 | grep -v '^no --'
    ask "Go ahead?" || exit 0
    "${BATCH[@]}" 2>&1 | { grep -v '^no --' || true; } || exit 1
else
    echo
    echo "== TEST: making 3 lines only =="
    "${BATCH[@]}" --limit 3 2>&1 | { grep -v '^no --\|files to make\|stopped at --limit' || true; } || exit 1
fi

# Louder: each file is boosted once (the list of boosted ones is kept beside the sound folder, not in it).
DONE="$OUT/citizens_made_louder.txt"
touch "$DONE"
if command -v ffmpeg >/dev/null; then
    echo
    echo "== Making them louder =="
    n=0
    while IFS= read -r f; do
        grep -qxF "$f" "$DONE" && continue
        if ffmpeg -nostdin -loglevel error -y -i "$f" -af loudnorm=I=-14:TP=-1.5 -ar 44100 -b:a 128k "$f.tmp.mp3"; then
            mv "$f.tmp.mp3" "$f"
            echo "$f" >> "$DONE"
            n=$((n + 1))
        else
            rm -f "$f.tmp.mp3"
        fi
    done < <(find "$DIR" -name '*.mp3' ! -name '*.tmp.mp3')
    echo "made $n louder"
else
    echo "(ffmpeg is not installed, so they were not made louder: sudo apt install ffmpeg, then run this again)"
fi

echo
if [ "$1" = "all" ]; then
    echo "Done. Upload every file in"
    echo "  $DIR"
    echo "to the server's garrysmod/sound/livingcity/citizens/"
else
    echo "Listen to the 3 test lines in:"
    echo "  $DIR"
    echo "Happy? Make the rest with:   bash record_citizens.sh all"
fi
