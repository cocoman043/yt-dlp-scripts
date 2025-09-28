#!/usr/bin/env bash
# Fix metadata for Aviencloud songs
set -euo pipefail

playlist_dir="$1"

for mp3 in "$playlist_dir"/*.mp3; do
  [ -e "$mp3" ] || continue

  current_artist=$(id3v2 -l "$mp3" | grep "TPE1" | sed 's/^.*: //')

  # Only process Aviencloud uploads
  if [[ "$current_artist" != "Aviencloud" ]]; then
    continue
  fi

  filename=$(basename "$mp3" .mp3)

  # Remove leading index (NNN - )
  filename="${filename#[0-9][0-9][0-9] - }"

  # Remove trailing unwanted tags
  filename=$(echo "$filename" | sed -E 's/\s*\((Lyrics|Official Video|Lyric Video|Official Music Video|Musicvideo|original demo)\)//gi' | sed -E 's/\s*\[CC\]//gi')

  artist=""
  title=""

  # Check for "Artist - Title" or "Artist – Title"
  if [[ "$filename" =~ ^(.+)[[:space:]][-–][[:space:]](.+)$ ]]; then
    artist="${BASH_REMATCH[1]}"
    title="${BASH_REMATCH[2]}"
  # Check for "Title by Artist"
  elif [[ "$filename" =~ ^(.+)[[:space:]]by[[:space:]](.+)$ ]]; then
    title="${BASH_REMATCH[1]}"
    artist="${BASH_REMATCH[2]}"
  else
    echo "Could not parse: $filename"
    continue
  fi

  # Remove leading/trailing spaces
  artist="$(echo "$artist" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  title="$(echo "$title" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

  # Update ID3 tags
  id3v2 --artist "$artist" --song "$title" "$mp3"

  echo "Updated: $mp3 → Artist: $artist, Title: $title"
done
