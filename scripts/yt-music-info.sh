#!/usr/bin/env bash

# Try to get info from youtube music.
player="YoutubeMusic"
info=$(playerctl -p "$player" metadata --format '{{xesam:title}}|{{xesam:artist}}|{{xesam:album}}' 2>/dev/null)

# If player is inactive or not running, exit quietly
if [[ $? -ne 0 || -z "$info" ]]; then
  echo ""
  exit 0
fi

title=$(cut -d'|' -f1 <<< "$info")
artist=$(cut -d'|' -f2 <<< "$info")
album=$(cut -d'|' -f3 <<< "$info")

# Output JSON for Waybar
jq -c -n \
  --arg text "$title - $artist" \
  --arg tooltip "Album: $album" \
  --arg class "mpris" \
  '{text: $text, tooltip: $tooltip, class: $class}'
