#!/usr/bin/env bash
# Outputs a play or pause icon as a Waybar JSON module based on YTMDesktop's
# current playback state. Polled every few seconds by Waybar.

# YTMDesktop (flatpak) registers as an MPRIS player with an unstable name like
# "chromium.instance13". We identify it by looking for its flatpak app ID in the
# album art URL path, which is always rooted under the flatpak's runtime directory.
player=$(playerctl --list-all 2>/dev/null | while IFS= read -r p; do
  if playerctl -p "$p" metadata mpris:artUrl 2>/dev/null | grep -q "app.ytmdesktop.ytmdesktop"; then
    echo "$p"
    break
  fi
done)


# Output nothing if YTMDesktop is not running or has no track loaded
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
