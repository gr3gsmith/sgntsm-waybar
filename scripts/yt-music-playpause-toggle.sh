#!/usr/bin/env bash

# Get playback status for YoutubeMusic
status=$(playerctl -p YoutubeMusic metadata --format '{{status}}' 2>/dev/null)

# If player is inactive or not running, exit quietly
if [[ $? -ne 0 || -z "$status" ]]; then
  echo ""
  exit 0
fi

# Output play/pause icon as JSON
if [[ "$status" == "Playing" ]]; then
  icon=""  # pause
else
  icon=""  # play
fi

printf '{"text": "%s", "class": "playpause"}\n' "$icon"
