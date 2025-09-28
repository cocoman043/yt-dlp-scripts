#!/usr/bin/env bash
set -euo pipefail

URL="$1"

# Download playlist: audio + thumbnail
yt-dlp \
  --format "bestaudio/best" \
  --extract-audio \
  --audio-format mp3 \
  --audio-quality 0 \
  --yes-playlist \
  --add-metadata \
  --write-thumbnail \
  --no-embed-thumbnail \
  --ignore-errors \
  --output "%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s" \
  "$URL"

# Get playlist directory
playlist_dir=$(yt-dlp --get-title --flat-playlist "$URL" | sed -n 1p)
playlist_dir="./$playlist_dir"

if [ ! -d "$playlist_dir" ]; then
  echo "Error: Playlist directory '$playlist_dir' not found."
  exit 1
fi

# Process each MP3 + thumbnail
for mp3 in "$playlist_dir"/*.mp3; do
  [ -e "$mp3" ] || continue

  dir="$(dirname "$mp3")"
  filename="$(basename "$mp3" .mp3)"

  # Extract playlist index as track number
  if [[ "$filename" =~ ^([0-9]{3}) ]]; then
    tracknum="${BASH_REMATCH[1]}"
  else
    tracknum="0"
  fi

  # Find thumbnail
  thumb="$(ls "$dir/$filename".jpg "$dir/$filename".webp 2>/dev/null | head -n1 || true)"
  [ -z "$thumb" ] && continue

  # Convert WebP to JPG if needed
  if [[ "$thumb" == *.webp ]]; then
    converted="$dir/${filename}.jpg"
    ffmpeg -y -i "$thumb" "$converted"
    rm -f "$thumb" # remove original WebP
    thumb="$converted"
  fi

  # Make square 500x500 cover
  cover="$dir/${filename}-cover.jpg"
  ffmpeg -y -i "$thumb" -vf "crop='min(iw,ih)':'min(iw,ih)',scale=500:500" "$cover"

  # Embed cover + track number (basic metadata)
  tmp="$dir/${filename}-tmp.mp3"
  ffmpeg -y -i "$mp3" -i "$cover" \
    -map 0:a -map 1:v \
    -id3v2_version 3 \
    -metadata track="$tracknum" \
    -metadata:s:v title="Album cover" \
    -metadata:s:v comment="Cover (front)" \
    "$tmp"

  mv "$tmp" "$mp3"
  rm -f "$cover" "$thumb"
done
