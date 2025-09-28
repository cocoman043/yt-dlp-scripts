#!/usr/bin/env bash
set -euo pipefail

URL="$1"

# Download playlist: audio + thumbnail (no embed yet)
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

# Get the playlist directory
playlist_dir=$(yt-dlp --get-title --flat-playlist "$URL" | head -n1)
playlist_dir="./$playlist_dir"

if [ ! -d "$playlist_dir" ]; then
  echo "Error: Playlist directory '$playlist_dir' not found."
  exit 1
fi

# Process each MP3 + its thumbnail
for mp3 in "$playlist_dir"/*.mp3; do
  [ -e "$mp3" ] || continue

  dir="$(dirname "$mp3")"
  base="$(basename "$mp3" .mp3)"

  # Find thumbnail
  thumb="$(ls "$dir/$base".jpg "$dir/$base".webp 2>/dev/null | head -n1 || true)"
  [ -z "$thumb" ] && continue

  # Make square 500x500 cover
  cover="$dir/${base}-cover.jpg"
  ffmpeg -y -i "$thumb" -vf "crop='min(iw,ih)':'min(iw,ih)',scale=500:500" "$cover"

  # Remove old cover if exists
  id3v2 --delete-frames=APIC "$mp3" 2>/dev/null || true

  # Embed square cover using id3v2
  id3v2 --attach "$cover":FRONT_COVER "$mp3"

  # Cleanup
  rm -f "$cover" "$thumb"
done
