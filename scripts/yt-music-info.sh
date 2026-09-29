#!/usr/bin/env bash
# Outputs the current YouTube Music track and artist as a Waybar JSON module.
# Polled every few seconds by Waybar; outputs an empty string when nothing is playing.

source "$(dirname "$0")/yt-music-player.sh"

# Output nothing if YouTube Music is not running or has no track loaded
if [[ -z "$player" ]]; then
  echo ""
  exit 0
fi

info=$(playerctl -p "$player" metadata --format '{{xesam:title}}|{{xesam:artist}}|{{xesam:album}}' 2>/dev/null)

if [[ $? -ne 0 || -z "$info" ]]; then
  echo ""
  exit 0
fi

title=$(cut -d'|' -f1 <<< "$info")
artist=$(cut -d'|' -f2 <<< "$info")
album=$(cut -d'|' -f3 <<< "$info")

jq -c -n \
  --arg text "$title - $artist" \
  --arg tooltip "Album: $album" \
  --arg class "mpris" \
  '{text: $text, tooltip: $tooltip, class: $class}'
