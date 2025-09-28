#!/usr/bin/env bash
set -euo pipefail

# Usage: ./fix_nine_degrees_north.sh <playlist_directory>
if [ $# -ne 1 ]; then
  echo "Usage: $0 <playlist_directory>"
  exit 1
fi

playlist_dir="$1"

for mp3 in "$playlist_dir"/*.mp3; do
  [ -e "$mp3" ] || continue

  # Read current artist from ID3
  current_artist=$(id3v2 -l "$mp3" | grep "TPE1" | sed 's/^.*: //')

  # Only process files where artist is "Nine Degrees North"
  if [[ "$current_artist" != "Nine Degrees North" ]]; then
    continue
  fi

  filename=$(basename "$mp3" .mp3)

  # Extract track number (first 3 digits)
  if [[ "$filename" =~ ^([0-9]{3}) ]]; then
    tracknum="${BASH_REMATCH[1]}"
  else
    tracknum="0"
  fi

  # Extract Title and Artist from "001 - Title - Artist"
  if [[ "$filename" =~ ^[0-9]{3}[[:space:]]*-[[:space:]]*(.+)[[:space:]]*-[[:space:]]*(.+)$ ]]; then
    title="${BASH_REMATCH[1]}"
    artist="${BASH_REMATCH[2]}"
  else
    echo "Could not parse: $filename"
    continue
  fi

  # Trim leading/trailing spaces
  title="$(echo "$title" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  artist="$(echo "$artist" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

  # Update ID3 tags
  id3v2 --artist "$artist" --song "$title" --track "$tracknum" "$mp3"

  echo "Updated: $mp3 → Artist: $artist, Title: $title, Track: $tracknum"
done
