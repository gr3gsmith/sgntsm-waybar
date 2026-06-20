#!/usr/bin/env bash
# Sends a playerctl command to YTMDesktop. Used by Waybar on-click handlers,
# which are static strings and cannot compute the player name themselves.
# Usage: yt-music-cmd.sh <playerctl-command> [args...]
# Example: yt-music-cmd.sh play-pause

# YTMDesktop (flatpak) registers as an MPRIS player with an unstable name like
# "chromium.instance13". We identify it by looking for its flatpak app ID in the
# album art URL path, which is always rooted under the flatpak's runtime directory.
player=$(playerctl --list-all 2>/dev/null | while IFS= read -r p; do
  if playerctl -p "$p" metadata mpris:artUrl 2>/dev/null | grep -q "app.ytmdesktop.ytmdesktop"; then
    echo "$p"
    break
  fi
done)

[[ -n "$player" ]] && playerctl -p "$player" "$@"
