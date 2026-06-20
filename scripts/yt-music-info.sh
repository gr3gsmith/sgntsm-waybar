#!/usr/bin/env bash
# Outputs the current YTMDesktop track and artist as a Waybar JSON module.
# Polled every few seconds by Waybar; outputs an empty string when nothing is playing.

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
