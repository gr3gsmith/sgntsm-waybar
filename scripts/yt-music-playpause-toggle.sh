#!/usr/bin/env bash
# Outputs a play or pause icon as a Waybar JSON module based on YouTube Music's
# current playback state. Polled every few seconds by Waybar.

source "$(dirname "$0")/yt-music-player.sh"


# Output nothing if YouTube Music is not running or has no track loaded
if [[ -z "$player" ]]; then
  echo ""
  exit 0
fi

status=$(playerctl -p "$player" status 2>/dev/null)

if [[ $? -ne 0 || -z "$status" ]]; then
  echo ""
  exit 0
fi
if [[ "$status" == "Playing" ]]; then
  icon=""  # pause
else
  icon=""  # play
fi

printf '{"text": "%s", "class": "playpause"}\n' "$icon"
