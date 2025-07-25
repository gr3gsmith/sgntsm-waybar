#!/usr/bin/env bash

# Try to get info from youtube music.
player="YoutubeMusic"
info=$(playerctl -p "$player" metadata --format '{{status}}|{{xesam:title}}|{{xesam:artist}}|{{xesam:album}}' 2>/dev/null)

# If player is inactive or not running, exit quietly
if [[ $? -ne 0 || -z "$info" ]]; then
  echo ""
  exit 0
fi

status=$(cut -d'|' -f1 <<< "$info")
title=$(cut -d'|' -f2 <<< "$info")
artist=$(cut -d'|' -f3 <<< "$info")
album=$(cut -d'|' -f4 <<< "$info")

# Determine control icon
case "$status" in
  Playing)
    icon=""  # pause symbol
    ;;
  Paused)
    icon=""  # play symbol
    ;;
  *)
    icon=""  # stop
    ;;
esac

# Output JSON for Waybar
jq -c -n \
  --arg text "$icon $title - $artist" \
  --arg tooltip "Album: $album" \
  --arg class "mpris" \
  '{text: $text, tooltip: $tooltip, class: $class}'

