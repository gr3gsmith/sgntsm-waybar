#!/usr/bin/env bash

# Get playback status for YoutubeMusic
status=$(playerctl -p YoutubeMusic status 2>/dev/null)

# Output play/pause icon as JSON
if [[ "$status" == "Playing" ]]; then
  icon=""  # pause
else
  icon=""  # play
fi

printf '{"text": "%s", "class": "playpause"}\n' "$icon"
