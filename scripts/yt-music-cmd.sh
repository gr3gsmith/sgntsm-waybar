#!/usr/bin/env bash
# Sends a playerctl command to YouTube Music (YTMDesktop or web app). Used by
# Waybar on-click handlers, which are static strings and cannot compute the
# player name themselves.
# Usage: yt-music-cmd.sh <playerctl-command> [args...]
# Example: yt-music-cmd.sh play-pause

source "$(dirname "$0")/yt-music-player.sh"

[[ -n "$player" ]] && playerctl -p "$player" "$@"
