#!/usr/bin/env bash
# Sourced by the yt-music-* scripts. Sets $player to the MPRIS name of the
# YouTube Music player, or leaves it empty if none is found. Matches either:
#
#   - YTMDesktop (flatpak), which registers with an unstable name like
#     "chromium.instance13". We identify it by its flatpak app ID in the album
#     art URL path, which is always rooted under the flatpak's runtime directory.
#   - The music.youtube.com web app in a browser (e.g. "firefox.instance_1_22"),
#     identified by the page URL the browser exposes as xesam:url.
player=$(playerctl --list-all 2>/dev/null | while IFS= read -r p; do
  meta=$(playerctl -p "$p" metadata --format '{{mpris:artUrl}}|{{xesam:url}}' 2>/dev/null)
  if [[ "$meta" == *app.ytmdesktop.ytmdesktop* || "$meta" == *://music.youtube.com/* ]]; then
    echo "$p"
    break
  fi
done)
