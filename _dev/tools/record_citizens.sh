#!/usr/bin/env bash
# Living City: record every named citizen line (man and woman) with ElevenLabs, the simple way.
#
#   bash _dev/tools/record_citizens.sh
#
# It asks for your ElevenLabs key (typed hidden, never saved), tells you what it will cost, makes 3 lines
# for you to listen to, then the rest, and makes them all louder. Run it again any time: lines already made
# are skipped. To use other voices, change the two ids below (ElevenLabs shows the id beside each voice).

MAN="zSPSnKB3yoR0pAl7oln6"
WOMAN="6ybFVMFdNOweF3NRmXj7"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/voice_out"
DIR="$OUT/sound/livingcity/citizens"
BATCH=(python3 "$ROOT/_dev/tools/elevenlabs_batch.py" --man "$MAN" --woman "$WOMAN" --out "$OUT")

ask() { read -r -p "$1 [y/n] " a; [[ "$a" == [yY]* ]]; }

if [ -z "$ELEVENLABS_API_KEY" ]; then
    read -r -s -p "Paste your ElevenLabs key (it will not show) and press Enter: " ELEVENLABS_API_KEY
    echo
    export ELEVENLABS_API_KEY
fi
[ -n "$ELEVENLABS_API_KEY" ] || { echo "No key given: nothing done."; exit 1; }

echo
echo "== What it will make =="
"${BATCH[@]}" --dry-run 2>&1 | grep -v '^no --'
ask "Go ahead?" || exit 0

mkdir -p "$DIR"

if [ -z "$(ls -A "$DIR" 2>/dev/null)" ]; then
    echo
    echo "== Making 3 to listen to first =="
    "${BATCH[@]}" --limit 3 || exit 1
    echo
    echo "Listen to them in: $DIR"
    ask "Happy with them? Make the rest?" || { echo "Stopped. Delete the ones you dislike, change the voice, and run it again."; exit 0; }
fi

echo
echo "== Making the rest (this takes a while; Ctrl+C stops it, running it again carries on) =="
"${BATCH[@]}" || exit 1

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
echo "Done. Upload every file in"
echo "  $DIR"
echo "to the server's garrysmod/sound/livingcity/citizens/"
