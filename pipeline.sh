#!/bin/bash
set -e
CHANNEL="https://www.youtube.com/channel/UCOZn-ZlYKGodH4t17-oovIA"
WORKDIR="$HOME/maurice-transcribe"
MODEL="large-v3"
LANGUAGE="de"
YTDLP="$HOME/.local/bin/yt-dlp"
command -v yt-dlp &>/dev/null && YTDLP="yt-dlp"

mkdir -p "$WORKDIR"/{mp3,transcription}
cd "$WORKDIR"

echo "=== Hämtar videolista ==="
$YTDLP --flat-playlist --print "%(id)s|%(title)s" "$CHANNEL" 2>/dev/null > video_list.txt
echo "Hittade $(wc -l < video_list.txt) videos"

echo "=== Laddar ner ljud ==="
while IFS='|' read -r VID TITLE; do
    SAFE=$(echo "$TITLE" | sed 's/[^a-zA-Z0-9äöüÄÖÜß _-]//g;s/  */ /g;s/^ //;s/ $//')
    [ -f "mp3/${SAFE}.mp3" ] && echo "[SKIP] $TITLE" && continue
    echo "[DL] $TITLE"
    $YTDLP -x --audio-format mp3 --audio-quality 0 -o "mp3/${SAFE}.mp3" "https://www.youtube.com/watch?v=$VID" 2>/dev/null || echo "[FEL] $TITLE"
done < video_list.txt

echo "=== Transkriberar med Whisper ($MODEL) ==="
for f in mp3/*.mp3; do
    [ -f "$f" ] || continue
    NAME=$(basename "$f" .mp3)
    [ -f "transcription/${NAME}.txt" ] && echo "[SKIP] $NAME" && continue
    echo "[WHISPER] $NAME ..."
    whisper "$f" --language "$LANGUAGE" --model "$MODEL" --output_dir transcription --output_format all 2>&1 | tail -3
    echo "[KLAR] $NAME"
done

echo "=== Klart! Filer i transcription/: ==="
ls -1 transcription/*.txt 2>/dev/null
